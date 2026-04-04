const express = require('express');
const router  = express.Router();
const authMw  = require('../middleware/auth');
const { db }  = require('../config/firebase');

// Sync steps from device (called by Flutter Health Connect / HealthKit)
router.post('/sync', authMw, async (req, res) => {
  const { steps, distance_km, calories_burned, active_minutes, date } = req.body;
  const docId = `${req.user.uid}_${date}`;

  await db.collection('activity').doc(docId).set({
    user_id: req.user.uid,
    date,
    steps,
    distance_km,
    calories_burned,
    active_minutes,
    updated_at: new Date(),
  }, { merge: true });

  res.json({ synced: true });
});

// Get today
router.get('/today', authMw, async (req, res) => {
  const today = new Date().toISOString().split('T')[0];
  const doc   = await db.collection('activity')
    .doc(`${req.user.uid}_${today}`).get();
  res.json(doc.exists ? doc.data() : { steps: 0, distance_km: 0, calories_burned: 0 });
});

// Weekly summary
router.get('/weekly', authMw, async (req, res) => {
  const snap = await db.collection('activity')
    .where('user_id', '==', req.user.uid)
    .orderBy('date', 'desc').limit(7).get();
  res.json(snap.docs.map(d => d.data()));
});

module.exports = router;