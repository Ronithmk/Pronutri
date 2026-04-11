const express    = require('express');
const router     = express.Router();
const multer     = require('multer');
const path       = require('path');
const fs         = require('fs');
const nodemailer = require('nodemailer');
const { db, fcm } = require('../config/firebase');
const authMiddleware  = require('../middleware/auth');
const adminMiddleware = require('../middleware/adminAuth');

// ── File upload config ────────────────────────────────────────────────────────
const uploadDir = path.join(__dirname, '..', 'uploads', 'trainer-docs');
fs.mkdirSync(uploadDir, { recursive: true });
const resolvedUploadDir = path.resolve(uploadDir);

const allowedExt = new Set(['.jpg', '.jpeg', '.png', '.pdf', '.webp']);
const allowedMime = new Set([
  'image/jpeg',
  'image/png',
  'image/webp',
  'application/pdf',
]);
const allowedDocTypes = new Set(['certificate', 'experience_letter', 'linkedin']);

function _safeText(input, max = 500) {
  if (typeof input !== 'string') return '';
  return input.trim().slice(0, max);
}

function _safeJsonArray(input) {
  try {
    const parsed = JSON.parse(input || '[]');
    if (!Array.isArray(parsed)) return [];
    return parsed
      .map((x) => (typeof x === 'string' ? x.trim() : ''))
      .filter(Boolean)
      .slice(0, 20);
  } catch {
    return [];
  }
}

const storage = multer.diskStorage({
  destination: (_, __, cb) => cb(null, uploadDir),
  filename:    (_, file, cb) => {
    const ext  = path.extname(file.originalname);
    const name = `${Date.now()}-${Math.random().toString(36).slice(2)}${ext}`;
    cb(null, name);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10 MB
  fileFilter: (_, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    const mime = String(file.mimetype || '').toLowerCase();
    if (allowedExt.has(ext) && allowedMime.has(mime)) cb(null, true);
    else cb(new Error('Only JPEG/PNG/WEBP/PDF files are allowed'));
  },
});

// ── Mailer helper ─────────────────────────────────────────────────────────────
async function _sendMail(to, subject, html) {
  try {
    const transporter = nodemailer.createTransport({
      host:   process.env.SMTP_HOST,
      port:   parseInt(process.env.SMTP_PORT || '587'),
      secure: process.env.SMTP_SECURE === 'true',
      auth:   { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS },
    });
    await transporter.sendMail({
      from: `"ProNutri Team" <${process.env.SMTP_USER}>`,
      to, subject, html,
    });
  } catch (e) {
    console.warn('Mail failed:', e.message);
  }
}

// ── FCM helper ────────────────────────────────────────────────────────────────
async function _sendPush(fcmToken, title, body, data = {}) {
  if (!fcmToken) return;
  try {
    await fcm.send({ token: fcmToken, notification: { title, body }, data });
  } catch (e) {
    console.warn('FCM push failed:', e.message);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// POST /trainer/apply
// Called by the Flutter app after OTP verification for trainer registration.
// Receives trainer profile fields + the document file upload.
// ─────────────────────────────────────────────────────────────────────────────
router.post('/apply', authMiddleware, upload.single('document'), async (req, res) => {
  const { uid, email } = req.user;

  if (!req.file) {
    return res.status(400).json({ error: 'Document file is required' });
  }

  const specializations = _safeJsonArray(req.body?.specializations);
  const yearsExperienceRaw = Number(req.body?.years_experience);
  const yearsExperience = Number.isFinite(yearsExperienceRaw)
    ? Math.max(0, Math.min(80, Math.floor(yearsExperienceRaw)))
    : 0;
  const bio = _safeText(req.body?.bio, 1200);
  const docType = allowedDocTypes.has(req.body?.doc_type) ? req.body.doc_type : 'certificate';

  try {
    const docUrl = `/api/trainer/document/${req.file.filename}`;

    const applicationData = {
      trainer_id:       uid,
      email,
      specializations,
      years_experience: yearsExperience,
      bio,
      doc_type:         docType,
      doc_filename:     req.file.filename,
      doc_url:          docUrl,
      doc_mime:         req.file.mimetype,
      status:           'pending',    // 'pending' | 'approved' | 'rejected'
      rejection_reason: null,
      submitted_at:     new Date(),
      reviewed_at:      null,
      reviewed_by:      null,
    };

    // Store in Firestore: trainer_applications collection
    await db.collection('trainer_applications').doc(uid).set(applicationData);

    // Update the user doc to mark as trainer pending
    await db.collection('users').doc(uid).update({
      role:           'trainer',
      trainer_status: 'pending',
    });

    // Notify all admin users via FCM
    const adminSnap = await db.collection('users')
      .where('role', '==', 'admin').get();

    const adminTokens = adminSnap.docs
      .map(d => d.data().fcm_token)
      .filter(Boolean);

    for (const token of adminTokens) {
      await _sendPush(
        token,
        '🏋️ New Trainer Application',
        `${email} submitted a trainer application. Tap to review.`,
        { type: 'trainer_application', trainer_id: uid },
      );
    }

    // Notify admin email
    if (process.env.ADMIN_EMAIL) {
      await _sendMail(
        process.env.ADMIN_EMAIL,
        '🏋️ New Trainer Application — ProNutri',
        _adminNotifHtml(email, bio, docUrl),
      );
    }

    res.json({ success: true, message: 'Application submitted successfully' });
  } catch (e) {
    console.error('Trainer apply failed:', e && e.message);
    try {
      if (req.file?.path && fs.existsSync(req.file.path)) fs.unlinkSync(req.file.path);
    } catch (cleanupErr) {
      console.warn('Trainer apply cleanup failed:', cleanupErr && cleanupErr.message);
    }
    res.status(500).json({ error: 'Failed to submit application' });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /trainer/document/:filename
// Serves the uploaded document file — protected: admin only.
// ─────────────────────────────────────────────────────────────────────────────
router.get('/document/:filename', adminMiddleware, (req, res) => {
  const safeFilename = path.basename(String(req.params.filename || ''));
  const filePath = path.join(uploadDir, safeFilename);
  const resolved = path.resolve(filePath);

  // Prevent path traversal
  if (!resolved.startsWith(resolvedUploadDir + path.sep) && resolved !== resolvedUploadDir) {
    return res.status(403).json({ error: 'Forbidden' });
  }
  if (!fs.existsSync(filePath)) {
    return res.status(404).json({ error: 'File not found' });
  }
  res.sendFile(resolved);
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /trainer/admin/applications
// Returns all trainer applications (admin only).
// Query: ?status=pending|approved|rejected (optional filter)
// ─────────────────────────────────────────────────────────────────────────────
router.get('/admin/applications', adminMiddleware, async (req, res) => {
  try {
    const status = typeof req.query?.status === 'string' ? req.query.status : '';
    let query = db.collection('trainer_applications');

    if (status && ['pending', 'approved', 'rejected'].includes(status)) {
      query = query.where('status', '==', status);
    }

    query = query.orderBy('submitted_at', 'desc');

    const snap = await query.get();

    // Enrich with basic user info
    const applications = await Promise.all(snap.docs.map(async (doc) => {
      const data = doc.data();
      let trainerName = '';
      try {
        const userDoc = await db.collection('users').doc(data.trainer_id).get();
        trainerName = userDoc.data()?.name || '';
      } catch (_) {}

      return {
        id:               doc.id,
        trainer_id:       data.trainer_id,
        trainer_name:     trainerName,
        email:            data.email,
        specializations:  data.specializations,
        years_experience: data.years_experience,
        bio:              data.bio,
        doc_type:         data.doc_type,
        doc_url:          data.doc_url,
        doc_mime:         data.doc_mime,
        status:           data.status,
        rejection_reason: data.rejection_reason,
        submitted_at:     data.submitted_at?.toDate?.()?.toISOString() || null,
        reviewed_at:      data.reviewed_at?.toDate?.()?.toISOString() || null,
        reviewed_by:      data.reviewed_by,
      };
    }));

    res.json({ applications, total: applications.length });
  } catch (e) {
    console.error('List trainer applications failed:', e && e.message);
    res.status(500).json({ error: 'Unable to fetch trainer applications' });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// POST /trainer/admin/approve/:trainerId
// Admin approves a trainer application.
// ─────────────────────────────────────────────────────────────────────────────
router.post('/admin/approve/:trainerId', adminMiddleware, async (req, res) => {
  const trainerId = String(req.params?.trainerId || '').trim();
  const adminUid      = req.user.uid;
  if (!trainerId) return res.status(400).json({ error: 'trainerId is required' });

  try {
    const appRef = db.collection('trainer_applications').doc(trainerId);
    const appDoc = await appRef.get();
    if (!appDoc.exists) return res.status(404).json({ error: 'Application not found' });

    const appData = appDoc.data();
    if (appData.status !== 'pending') {
      return res.status(400).json({ error: `Application is already ${appData.status}` });
    }

    const now = new Date();

    // Update application status
    await appRef.update({
      status:      'approved',
      reviewed_at: now,
      reviewed_by: adminUid,
    });

    // Update user document — unlock trainer access
    await db.collection('users').doc(trainerId).update({
      trainer_status: 'approved',
      approved_at:    now,
    });

    // Notify trainer via FCM
    const userDoc = await db.collection('users').doc(trainerId).get();
    const userData = userDoc.exists ? userDoc.data() : {};

    await _sendPush(
      userData?.fcm_token,
      '🎉 You\'re approved as a Trainer!',
      'Your ProNutri trainer account is now active. You can start hosting live sessions!',
      { type: 'trainer_approved' },
    );

    // Send approval email to trainer
    await _sendMail(
      appData.email,
      '🎉 Your ProNutri Trainer Account is Approved!',
      _approvalEmailHtml(userData?.name || 'Trainer'),
    );

    res.json({ success: true, message: `Trainer ${trainerId} approved` });
  } catch (e) {
    console.error('Approve trainer failed:', e && e.message);
    res.status(500).json({ error: 'Unable to approve trainer' });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// POST /trainer/admin/reject/:trainerId
// Admin rejects a trainer application with an optional reason.
// Body: { reason: string }
// ─────────────────────────────────────────────────────────────────────────────
router.post('/admin/reject/:trainerId', adminMiddleware, async (req, res) => {
  const trainerId = String(req.params?.trainerId || '').trim();
  const reason = _safeText(req.body?.reason, 500);
  const adminUid       = req.user.uid;

  if (!trainerId) return res.status(400).json({ error: 'trainerId is required' });
  if (!reason || reason.length < 5) {
    return res.status(400).json({ error: 'Please provide a rejection reason (min 5 chars)' });
  }

  try {
    const appRef = db.collection('trainer_applications').doc(trainerId);
    const appDoc = await appRef.get();
    if (!appDoc.exists) return res.status(404).json({ error: 'Application not found' });

    const appData = appDoc.data();
    if (appData.status !== 'pending') {
      return res.status(400).json({ error: `Application is already ${appData.status}` });
    }
    const now     = new Date();

    await appRef.update({
      status:           'rejected',
      rejection_reason: reason,
      reviewed_at:      now,
      reviewed_by:      adminUid,
    });

    await db.collection('users').doc(trainerId).update({
      trainer_status:   'rejected',
      rejection_reason: reason,
    });

    // Notify trainer via FCM
    const userDoc  = await db.collection('users').doc(trainerId).get();
    const userData = userDoc.data();

    await _sendPush(
      userData?.fcm_token,
      'ProNutri Trainer Application',
      'Your trainer application needs attention. Tap to see details.',
      { type: 'trainer_rejected', reason },
    );

    // Send rejection email
    await _sendMail(
      appData.email,
      'Your ProNutri Trainer Application',
      _rejectionEmailHtml(userData?.name || 'Trainer', reason),
    );

    res.json({ success: true, message: `Trainer ${trainerId} rejected` });
  } catch (e) {
    console.error('Reject trainer failed:', e && e.message);
    res.status(500).json({ error: 'Unable to reject trainer' });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /trainer/admin/stats
// Quick summary counts for admin dashboard.
// ─────────────────────────────────────────────────────────────────────────────
router.get('/admin/stats', adminMiddleware, async (req, res) => {
  try {
    const [pendingSnap, approvedSnap, rejectedSnap] = await Promise.all([
      db.collection('trainer_applications').where('status', '==', 'pending').count().get(),
      db.collection('trainer_applications').where('status', '==', 'approved').count().get(),
      db.collection('trainer_applications').where('status', '==', 'rejected').count().get(),
    ]);

    res.json({
      pending:  pendingSnap.data().count,
      approved: approvedSnap.data().count,
      rejected: rejectedSnap.data().count,
    });
  } catch (e) {
    console.error('Trainer stats failed:', e && e.message);
    res.status(500).json({ error: 'Unable to fetch trainer stats' });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// Email templates
// ─────────────────────────────────────────────────────────────────────────────
function _adminNotifHtml(email, bio, docUrl) {
  return `
<!DOCTYPE html><html><body style="font-family:'Segoe UI',Arial,sans-serif;background:#f4f7fc;padding:32px;">
<div style="max-width:560px;margin:auto;background:#fff;border-radius:16px;overflow:hidden;box-shadow:0 4px 20px rgba(0,0,0,0.08);">
  <div style="background:linear-gradient(135deg,#1E6EBD,#2ECC71);padding:28px;text-align:center;">
    <h1 style="color:#fff;margin:0;font-size:22px;">🏋️ New Trainer Application</h1>
  </div>
  <div style="padding:28px;">
    <p style="color:#374151;font-size:15px;">A new trainer application has been submitted:</p>
    <table style="width:100%;border-collapse:collapse;margin:16px 0;">
      <tr><td style="padding:8px 0;color:#6B7280;font-size:13px;width:140px;">Email</td><td style="padding:8px 0;color:#111827;font-size:13px;font-weight:600;">${email}</td></tr>
      <tr><td style="padding:8px 0;color:#6B7280;font-size:13px;">Bio excerpt</td><td style="padding:8px 0;color:#111827;font-size:13px;">${bio?.substring(0, 120) || '—'}…</td></tr>
    </table>
    <p style="color:#374151;font-size:14px;">Log in to the <strong>ProNutri Admin</strong> app to review the document and approve or reject.</p>
  </div>
  <div style="background:#F8FAFB;padding:16px;text-align:center;border-top:1px solid #E5E7EB;">
    <p style="color:#9CA3AF;font-size:12px;margin:0;">© 2024 ProNutri — Admin Notification</p>
  </div>
</div>
</body></html>`;
}

function _approvalEmailHtml(name) {
  return `
<!DOCTYPE html><html><body style="font-family:'Segoe UI',Arial,sans-serif;background:#f4f7fc;padding:32px;">
<div style="max-width:560px;margin:auto;background:#fff;border-radius:16px;overflow:hidden;box-shadow:0 4px 20px rgba(0,0,0,0.08);">
  <div style="background:linear-gradient(135deg,#2ECC71,#1B8A4D);padding:36px;text-align:center;">
    <div style="font-size:52px;">🎉</div>
    <h1 style="color:#fff;margin:8px 0 0;font-size:24px;">You're approved!</h1>
  </div>
  <div style="padding:32px;">
    <h2 style="color:#111827;margin:0 0 12px;">Hi ${name},</h2>
    <p style="color:#374151;font-size:15px;line-height:1.7;">
      Great news! Your ProNutri trainer account has been <strong style="color:#2ECC71;">approved</strong>.
      You can now log into the app and start hosting live sessions, building your audience, and monetizing your expertise.
    </p>
    <div style="background:#F0FFF4;border-radius:12px;padding:20px;margin:24px 0;border-left:4px solid #2ECC71;">
      <p style="margin:0;color:#1B8A4D;font-size:14px;font-weight:600;">What you can do now:</p>
      <ul style="color:#374151;font-size:14px;line-height:1.8;margin:8px 0 0;padding-left:20px;">
        <li>Host live video sessions for 1,000+ viewers</li>
        <li>Schedule upcoming sessions in advance</li>
        <li>Earn from your expertise</li>
        <li>Get your Verified Trainer badge</li>
      </ul>
    </div>
    <p style="color:#6B7280;font-size:13px;">Open the ProNutri app and log in to get started.</p>
  </div>
  <div style="background:#F8FAFB;padding:16px;text-align:center;border-top:1px solid #E5E7EB;">
    <p style="color:#9CA3AF;font-size:12px;margin:0;">© 2024 ProNutri · All rights reserved</p>
  </div>
</div>
</body></html>`;
}

function _rejectionEmailHtml(name, reason) {
  return `
<!DOCTYPE html><html><body style="font-family:'Segoe UI',Arial,sans-serif;background:#f4f7fc;padding:32px;">
<div style="max-width:560px;margin:auto;background:#fff;border-radius:16px;overflow:hidden;box-shadow:0 4px 20px rgba(0,0,0,0.08);">
  <div style="background:linear-gradient(135deg,#374151,#1F2937);padding:36px;text-align:center;">
    <div style="font-size:52px;">📋</div>
    <h1 style="color:#fff;margin:8px 0 0;font-size:24px;">Application Update</h1>
  </div>
  <div style="padding:32px;">
    <h2 style="color:#111827;margin:0 0 12px;">Hi ${name},</h2>
    <p style="color:#374151;font-size:15px;line-height:1.7;">
      Thank you for applying to become a ProNutri trainer. After reviewing your application, we are unable to approve it at this time.
    </p>
    <div style="background:#FFF7ED;border-radius:12px;padding:20px;margin:24px 0;border-left:4px solid #F59E0B;">
      <p style="margin:0 0 6px;color:#92400E;font-size:13px;font-weight:700;text-transform:uppercase;letter-spacing:0.5px;">Reason</p>
      <p style="margin:0;color:#374151;font-size:14px;line-height:1.6;">${reason}</p>
    </div>
    <p style="color:#374151;font-size:14px;line-height:1.7;">
      You're welcome to re-apply after addressing the above. If you have questions, please contact us at <a href="mailto:${process.env.SMTP_USER}" style="color:#1E6EBD;">${process.env.SMTP_USER}</a>.
    </p>
  </div>
  <div style="background:#F8FAFB;padding:16px;text-align:center;border-top:1px solid #E5E7EB;">
    <p style="color:#9CA3AF;font-size:12px;margin:0;">© 2024 ProNutri · All rights reserved</p>
  </div>
</div>
</body></html>`;
}

module.exports = router;
