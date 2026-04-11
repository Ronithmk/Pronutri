const express      = require('express');
const router       = express.Router();
const bcrypt       = require('bcryptjs');
const jwt          = require('jsonwebtoken');
const nodemailer   = require('nodemailer');
const { db }       = require('../config/firebase');

// ── In-memory OTP store (keyed by lowercase email) ────────────────────────────
const _otpStore = new Map(); // email → { otp, expiresAt, attempts }
const _rateStore = new Map(); // key -> { count, resetAt }

const JWT_SECRET = process.env.JWT_SECRET || '';
const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const ALLOWED_ROLES = new Set(['learner', 'trainer']);
const EXPOSE_ADMIN_OTP = (process.env.EXPOSE_ADMIN_OTP || 'true').toLowerCase() === 'true';

function _normalizeEmail(input) {
  return (typeof input === 'string' ? input : '').trim().toLowerCase();
}

function _isStrongEnoughPassword(password) {
  return typeof password === 'string' && password.length >= 8 && password.length <= 128;
}

function _rateLimit(key, maxCount, windowMs) {
  const now = Date.now();
  const entry = _rateStore.get(key);

  if (!entry || now > entry.resetAt) {
    _rateStore.set(key, { count: 1, resetAt: now + windowMs });
    return false;
  }

  entry.count += 1;
  _rateStore.set(key, entry);
  return entry.count > maxCount;
}

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
  const email = _normalizeEmail(req.body?.email);
  if (!email || !EMAIL_REGEX.test(email)) {
    return res.status(400).json({ error: 'Valid email required' });
  }
  if (_rateLimit(`send-otp:${email}`, 5, 10 * 60 * 1000)) {
    return res.status(429).json({ error: 'Too many OTP requests. Try again later.' });
  }

  const otp = _generateOtp();
  _otpStore.set(email, {
    otp,
    attempts: 0,
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
  const email = _normalizeEmail(req.body?.email);
  const otp = String(req.body?.otp || '').trim();
  if (!email || !EMAIL_REGEX.test(email)) {
    return res.status(400).json({ valid: false, error: 'Valid email required' });
  }
  if (!/^\d{6}$/.test(otp)) {
    return res.status(400).json({ valid: false, error: 'Invalid OTP format' });
  }
  if (_rateLimit(`verify-otp:${email}`, 10, 10 * 60 * 1000)) {
    return res.status(429).json({ valid: false, error: 'Too many verification attempts' });
  }

  const entry = _otpStore.get(email);

  if (!entry)                          return res.json({ valid: false });
  if (Date.now() > entry.expiresAt) {
    _otpStore.delete(email);
    return res.json({ valid: false, error: 'OTP expired' });
  }

  const valid = entry.otp === otp;
  if (!valid) {
    entry.attempts = (entry.attempts || 0) + 1;
    if (entry.attempts >= 5) _otpStore.delete(email);
    else _otpStore.set(email, entry);
  } else {
    _otpStore.delete(email);
  }

  res.json({ valid });
});

router.post('/register', async (req, res) => {
  // role: 'learner' (default) | 'trainer'
  // Trainers start with 0 credits and trainer_status: 'pending'
  const name = typeof req.body?.name === 'string' ? req.body.name.trim() : '';
  const email = _normalizeEmail(req.body?.email);
  const password = req.body?.password;
  const role = req.body?.role || 'learner';

  if (!name || name.length > 80) {
    return res.status(400).json({ error: 'Valid name required' });
  }
  if (!email || !EMAIL_REGEX.test(email)) {
    return res.status(400).json({ error: 'Valid email required' });
  }
  if (!_isStrongEnoughPassword(password)) {
    return res.status(400).json({ error: 'Password must be 8-128 characters' });
  }
  if (!ALLOWED_ROLES.has(role)) {
    return res.status(400).json({ error: 'Invalid role' });
  }
  if (!JWT_SECRET) {
    return res.status(500).json({ error: 'Server configuration error' });
  }

  try {
    // Check duplicate
    const snap = await db.collection('users')
      .where('email', '==', email).limit(1).get();
    if (!snap.empty) return res.status(409).json({ error: 'Email exists' });

    const hash     = await bcrypt.hash(password, 12);
    const now      = new Date();
    const isTrainer = role === 'trainer';
    const credits  = isTrainer ? 0 : 100; // trainers earn after approval

    const userRef = await db.collection('users').add({
      name,
      email,
      password:     hash,
      role,
      trainer_status: isTrainer ? 'pending' : null,
      credits,
      trial_start:  now,
      trial_end:    new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000),
      subscription_active: false,
      subscription_end:    null,
      fcm_token:    null,
      created_at:   now,
    });

    // Log initial credit grant (learners only)
    if (!isTrainer) {
      await db.collection('transactions').add({
        user_id:     userRef.id,
        type:        'credit',
        amount:      100,
        description: 'Welcome bonus credits',
      created_at:  now,
    });
    }

    const token = jwt.sign(
      { uid: userRef.id, email },
      JWT_SECRET,
      { expiresIn: '30d' }
    );
    res.json({
      token,
      uid:            userRef.id,
      credits,
      role,
      trainer_status: isTrainer ? 'pending' : null,
    });
  } catch (e) {
    console.error('Register failed:', e && e.message);
    res.status(500).json({ error: 'Registration failed' });
  }
});

router.post('/login', async (req, res) => {
  const email = _normalizeEmail(req.body?.email);
  const password = req.body?.password;
  if (!email || !EMAIL_REGEX.test(email) || typeof password !== 'string') {
    return res.status(400).json({ error: 'Invalid credentials' });
  }
  if (!JWT_SECRET) {
    return res.status(500).json({ error: 'Server configuration error' });
  }
  if (_rateLimit(`login:${email}`, 10, 15 * 60 * 1000)) {
    return res.status(429).json({ error: 'Too many login attempts. Try again later.' });
  }

  try {
    const snap = await db.collection('users')
      .where('email', '==', email).limit(1).get();
    if (snap.empty) return res.status(401).json({ error: 'Invalid credentials' });

    const doc  = snap.docs[0];
    const user = doc.data();
    if (!user?.password || typeof user.password !== 'string') {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    const ok   = await bcrypt.compare(password, user.password);
    if (!ok) return res.status(401).json({ error: 'Invalid credentials' });

    const token = jwt.sign(
      { uid: doc.id, email },
      JWT_SECRET,
      { expiresIn: '30d' }
    );
    res.json({
      token,
      uid:                doc.id,
      name:               user.name,
      credits:            user.credits,
      subscription_active: user.subscription_active,
      trial_end:          user.trial_end,
      role:               user.role || 'learner',
      trainer_status:     user.trainer_status || null,
    });
  } catch (e) {
    console.error('Login failed:', e && e.message);
    res.status(500).json({ error: 'Login failed' });
  }
});

// ── GET /auth/trainer-status ──────────────────────────────────────────────────
// Trainer polls this after registration to detect admin approval/rejection.
const authMiddlewareLocal = require('../middleware/auth');
router.get('/trainer-status', authMiddlewareLocal, async (req, res) => {
  try {
    const doc = await db.collection('users').doc(req.user.uid).get();
    if (!doc.exists) return res.status(404).json({ error: 'User not found' });
    const { trainer_status } = doc.data();
    res.json({ trainer_status: trainer_status || null });
  } catch (e) {
    console.error('Trainer status fetch failed:', e && e.message);
    res.status(500).json({ error: 'Unable to fetch trainer status' });
  }
});

// ── POST /auth/admin-login ────────────────────────────────────────────────────
// OTP-based admin login. Email is fixed to ADMIN_EMAIL env var.
// Step 1: POST { email } → sends OTP  (reuses /auth/send-otp internally)
// Step 2: POST { email, otp } → verifies OTP → returns JWT
const ADMIN_EMAIL = _normalizeEmail(process.env.ADMIN_EMAIL || 'protoncodeai@gmail.com');

router.post('/admin-login', async (req, res) => {
  const normalised = _normalizeEmail(req.body?.email);
  const otp = String(req.body?.otp || '').trim();

  if (!normalised || !EMAIL_REGEX.test(normalised)) {
    return res.status(400).json({ error: 'Valid email required' });
  }
  if (!JWT_SECRET) {
    return res.status(500).json({ error: 'Server configuration error' });
  }
  if (normalised !== ADMIN_EMAIL) {
    return res.status(403).json({ error: 'Access denied.' });
  }

  // ── Step 1: no OTP provided → send one ──────────────────────────────────
  if (!otp) {
    if (_rateLimit(`admin-send:${normalised}`, 5, 15 * 60 * 1000)) {
      return res.status(429).json({ error: 'Too many OTP requests. Try again later.' });
    }

    // Reuse the existing OTP send logic
    const code = _generateOtp();
    _otpStore.set(normalised, {
      otp: code,
      attempts: 0,
      expiresAt: Date.now() + 10 * 60 * 1000,
    });

    const transporter = nodemailer.createTransport({
      host: process.env.SMTP_HOST, port: Number(process.env.SMTP_PORT),
      secure: process.env.SMTP_SECURE === 'true',
      auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS },
    });

    try {
      await transporter.sendMail({
        from: `"ProNutri Admin" <${process.env.SMTP_USER}>`,
        to:   normalised,
        subject: 'ProNutri Admin Login Code',
        html: _otpEmailHtml(code),
      });
      if (EXPOSE_ADMIN_OTP) return res.json({ sent: true, otp: code });
      return res.json({ sent: true });
    } catch (_) {
      if (EXPOSE_ADMIN_OTP) return res.json({ sent: true, otp: code });
      return res.status(503).json({ error: 'Unable to send OTP right now.' });
    }
  }

  // ── Step 2: OTP provided → verify ───────────────────────────────────────
  if (!/^\d{6}$/.test(otp)) {
    return res.status(400).json({ error: 'Invalid OTP format.' });
  }
  if (_rateLimit(`admin-verify:${normalised}`, 10, 15 * 60 * 1000)) {
    return res.status(429).json({ error: 'Too many verification attempts. Try again later.' });
  }

  const entry = _otpStore.get(normalised);
  if (!entry || Date.now() > entry.expiresAt) {
    _otpStore.delete(normalised);
    return res.status(401).json({ error: 'Invalid or expired code.' });
  }
  if (entry.otp !== otp) {
    entry.attempts = (entry.attempts || 0) + 1;
    if (entry.attempts >= 5) _otpStore.delete(normalised);
    else _otpStore.set(normalised, entry);
    return res.status(401).json({ error: 'Invalid or expired code.' });
  }
  _otpStore.delete(normalised);

  try {
    const snap = await db.collection('users')
      .where('email', '==', normalised)
      .where('role',  '==', 'admin')
      .limit(1).get();

    if (snap.empty) {
      return res.status(403).json({ error: 'No admin account found for this email.' });
    }

    const doc  = snap.docs[0];
    const user = doc.data();

    const token = jwt.sign(
      { uid: doc.id, email: user.email },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    return res.json({ token, uid: doc.id, name: user.name, email: user.email, role: 'admin' });
  } catch (e) {
    console.error('Admin login failed:', e && e.message);
    res.status(500).json({ error: 'Admin login failed' });
  }
});

module.exports = router;
