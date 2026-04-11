const express = require('express');
const router = express.Router();
const authMw = require('../middleware/auth');
const { db } = require('../config/firebase');

function _isReasonableToken(token) {
  return typeof token === 'string' && token.length >= 20 && token.length <= 4096;
}

// Save/update the current user's FCM token.
router.post('/register-token', authMw, async (req, res) => {
  const { token } = req.body || {};
  if (!_isReasonableToken(token)) {
    return res.status(400).json({ error: 'Invalid token' });
  }

  try {
    await db.collection('users').doc(req.user.uid).set(
      { fcm_token: token.trim(), fcm_updated_at: new Date() },
      { merge: true },
    );
    return res.json({ success: true });
  } catch (e) {
    console.error('Failed to register FCM token:', e && e.message);
    return res.status(500).json({ error: 'Unable to save notification token' });
  }
});

router.post('/unregister-token', authMw, async (req, res) => {
  try {
    await db.collection('users').doc(req.user.uid).set(
      { fcm_token: null, fcm_updated_at: new Date() },
      { merge: true },
    );
    return res.json({ success: true });
  } catch (e) {
    console.error('Failed to unregister FCM token:', e && e.message);
    return res.status(500).json({ error: 'Unable to clear notification token' });
  }
});

module.exports = router;
