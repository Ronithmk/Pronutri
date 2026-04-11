const express = require('express');
const router  = express.Router();
const authMw  = require('../middleware/auth');
const { db }  = require('../config/firebase');

function _toNonNegativeNumber(v, max = Number.MAX_SAFE_INTEGER) {
  const n = Number(v);
  if (!Number.isFinite(n) || n < 0) return 0;
  return Math.min(n, max);
}

// Sync steps from device (called by Flutter Health Connect / HealthKit)
router.post('/sync', authMw, async (req, res) => {
  const { steps, distance_km, calories_burned, active_minutes, date } = req.body || {};
  const safeDate = typeof date === 'string' ? date.trim() : '';
  if (!/^\d{4}-\d{2}-\d{2}$/.test(safeDate)) {
    return res.status(400).json({ error: 'Invalid date format. Use YYYY-MM-DD' });
  }

  const docId = `${req.user.uid}_${safeDate}`;

  try {
    await db.collection('activity').doc(docId).set({
      user_id: req.user.uid,
      date: safeDate,
      steps: Math.floor(_toNonNegativeNumber(steps, 200000)),
      distance_km: _toNonNegativeNumber(distance_km, 200),
      calories_burned: _toNonNegativeNumber(calories_burned, 20000),
      active_minutes: Math.floor(_toNonNegativeNumber(active_minutes, 1440)),
      updated_at: new Date(),
    }, { merge: true });

    res.json({ synced: true });
  } catch (e) {
    console.error('Activity sync failed:', e && e.message);
    res.status(500).json({ error: 'Unable to sync activity' });
  }
});

// Get today
router.get('/today', authMw, async (req, res) => {
  try {
    const today = new Date().toISOString().split('T')[0];
    const doc   = await db.collection('activity')
      .doc(`${req.user.uid}_${today}`).get();
    res.json(doc.exists ? doc.data() : { steps: 0, distance_km: 0, calories_burned: 0, active_minutes: 0 });
  } catch (e) {
    console.error('Activity today fetch failed:', e && e.message);
    res.status(500).json({ error: 'Unable to fetch today activity' });
  }
});

// Weekly summary
router.get('/weekly', authMw, async (req, res) => {
  try {
    const snap = await db.collection('activity')
      .where('user_id', '==', req.user.uid)
      .orderBy('date', 'desc').limit(7).get();
    res.json(snap.docs.map(d => d.data()));
  } catch (e) {
    console.error('Activity weekly fetch failed:', e && e.message);
    res.status(500).json({ error: 'Unable to fetch weekly activity' });
  }
});

module.exports = router;
