const express      = require('express');
const router       = express.Router();
const bcrypt       = require('bcryptjs');
const jwt          = require('jsonwebtoken');
const nodemailer   = require('nodemailer');
const { db }       = require('../config/firebase');

// ── In-memory OTP store (keyed by lowercase email) ────────────────────────────
const _otpStore = new Map(); // email → { otp, expiresAt }

function _generateOtp() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

function _otpEmailHtml(otp) {
  return `
<!DOCTYPE html><html><body style="margin:0;padding:0;background:#f8f9fa;font-family:'Segoe UI',Arial,sans-serif;">
<table width="100%" cellpadding="0" cellspacing="0" style="padding:40px 0;">
  <tr><td align="center">
    <table width="480" cellpadding="0" cellspacing="0" style="background:#fff;border-radius:20px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.08);">
      <tr><td style="background:linear-gradient(135deg,#00C896,#1E6EBD);padding:40px;text-align:center;">
        <div style="font-size:48px;margin-bottom:12px;">🥗</div>
        <h1 style="color:#fff;font-size:28px;font-weight:800;margin:0;">ProNutri</h1>
        <p style="color:rgba(255,255,255,0.8);margin:8px 0 0;font-size:14px;">Your Personal Nutrition Coach</p>
      </td></tr>
      <tr><td style="padding:40px;">
        <h2 style="color:#0D1117;font-size:22px;margin:0 0 8px;">Verify your email 👋</h2>
        <p style="color:#6B7280;font-size:15px;line-height:1.6;margin:0 0 32px;">Enter this 6-digit code in the ProNutri app. Expires in <strong>10 minutes</strong>.</p>
        <div style="background:#F2F4F7;border-radius:16px;padding:28px;text-align:center;margin-bottom:32px;">
          <p style="color:#6B7280;font-size:12px;font-weight:600;text-transform:uppercase;letter-spacing:1px;margin:0 0 12px;">Verification Code</p>
          <div style="font-size:48px;font-weight:800;letter-spacing:12px;color:#00C896;font-family:monospace;">${otp}</div>
        </div>
        <p style="color:#B0B8C4;font-size:13px;margin:0;">If you didn't request this, you can safely ignore this email.</p>
      </td></tr>
      <tr><td style="background:#F8F9FA;padding:20px;text-align:center;border-top:1px solid #E8ECF0;">
        <p style="color:#B0B8C4;font-size:12px;margin:0;">© 2024 ProNutri. All rights reserved.</p>
      </td></tr>
    </table>
  </td></tr>
</table>
</body></html>`;
}

// ── POST /auth/send-otp ───────────────────────────────────────────────────────
router.post('/send-otp', async (req, res) => {
  const { email } = req.body;
  if (!email) return res.status(400).json({ error: 'Email required' });

  const otp = _generateOtp();
  _otpStore.set(email.toLowerCase(), {
    otp,
    expiresAt: Date.now() + 10 * 60 * 1000, // 10 min
  });

  // Generic SMTP — works with any provider (Hostinger, Zoho, GoDaddy, etc.)
  try {
    const transporter = nodemailer.createTransport({
      host:   process.env.SMTP_HOST,
      port:   parseInt(process.env.SMTP_PORT  || '587'),
      secure: process.env.SMTP_SECURE === 'true', // true for port 465, false for 587
      auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS,
      },
    });
    await transporter.sendMail({
      from: `"ProNutri" <${process.env.SMTP_USER}>`,
      to:      email,
      subject: 'ProNutri - Your Verification Code',
      html:    _otpEmailHtml(otp),
    });
    return res.json({ success: true });
  } catch (e) {
    console.warn('Email send failed:', e.message);
    // Dev mode — return OTP so Flutter shows it on screen
    return res.json({ success: true, otp });
  }
});

// ── POST /auth/verify-otp ─────────────────────────────────────────────────────
router.post('/verify-otp', (req, res) => {
  const { email, otp } = req.body;
  const entry = _otpStore.get(email?.toLowerCase());

  if (!entry)                          return res.json({ valid: false });
  if (Date.now() > entry.expiresAt) {
    _otpStore.delete(email.toLowerCase());
    return res.json({ valid: false, error: 'OTP expired' });
  }

  const valid = entry.otp === otp?.trim();
  if (valid) _otpStore.delete(email.toLowerCase());
  res.json({ valid });
});

router.post('/register', async (req, res) => {
  const { name, email, password } = req.body;
  try {
    // Check duplicate
    const snap = await db.collection('users')
      .where('email', '==', email).limit(1).get();
    if (!snap.empty) return res.status(409).json({ error: 'Email exists' });

    const hash = await bcrypt.hash(password, 12);
    const now  = new Date();

    const userRef = await db.collection('users').add({
      name,
      email,
      password: hash,
      credits: 100,                       // ₹100 free credits
      trial_start: now,
      trial_end: new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000), // 30 days
      subscription_active: false,
      subscription_end: null,
      fcm_token: null,
      created_at: now,
    });

    // Log initial credit grant
    await db.collection('transactions').add({
      user_id: userRef.id,
      type: 'credit',
      amount: 100,
      description: 'Welcome bonus credits',
      created_at: now,
    });

    const token = jwt.sign(
      { uid: userRef.id, email },
      process.env.JWT_SECRET,
      { expiresIn: '30d' }
    );
    res.json({ token, uid: userRef.id, credits: 100 });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.post('/login', async (req, res) => {
  const { email, password } = req.body;
  try {
    const snap = await db.collection('users')
      .where('email', '==', email).limit(1).get();
    if (snap.empty) return res.status(404).json({ error: 'Not found' });

    const doc  = snap.docs[0];
    const user = doc.data();
    const ok   = await bcrypt.compare(password, user.password);
    if (!ok) return res.status(401).json({ error: 'Wrong password' });

    const token = jwt.sign(
      { uid: doc.id, email },
      process.env.JWT_SECRET,
      { expiresIn: '30d' }
    );
    res.json({
      token,
      uid: doc.id,
      credits: user.credits,
      subscription_active: user.subscription_active,
      trial_end: user.trial_end,
    });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;