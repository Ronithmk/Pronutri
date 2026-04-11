const express = require('express');
const router = express.Router();
const authMw = require('../middleware/auth');
const { db } = require('../config/firebase');

router.get('/status', authMw, async (req, res) => {
  try {
    const userDoc = await db.collection('users').doc(req.user.uid).get();
    if (!userDoc.exists) return res.status(404).json({ error: 'User not found' });

    const data = userDoc.data() || {};
    return res.json({
      subscription_active: !!data.subscription_active,
      subscription_end: data.subscription_end || null,
      trial_end: data.trial_end || null,
    });
  } catch (e) {
    console.error('Subscription status failed:', e && e.message);
    return res.status(500).json({ error: 'Unable to fetch subscription status' });
  }
});

router.post('/activate', authMw, async (req, res) => {
  return res.status(403).json({
    error: 'Direct activation is disabled. Use the verified payments flow.',
  });
});

router.post('/cancel', authMw, async (req, res) => {
  try {
    await db.collection('users').doc(req.user.uid).set({
      subscription_active: false,
      updated_at: new Date(),
    }, { merge: true });
    return res.json({ success: true, subscription_active: false });
  } catch (e) {
    console.error('Subscription cancel failed:', e && e.message);
    return res.status(500).json({ error: 'Unable to cancel subscription' });
  }
});

module.exports = router;
