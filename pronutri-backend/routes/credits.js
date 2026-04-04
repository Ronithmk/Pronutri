const express  = require('express');
const router   = express.Router();
const authMw   = require('../middleware/auth');
const { db }   = require('../config/firebase');

// Get balance
router.get('/balance', authMw, async (req, res) => {
  const doc = await db.collection('users').doc(req.user.uid).get();
  res.json({ credits: doc.data().credits });
});

// Deduct ₹2 for AI chat
router.post('/deduct', authMw, async (req, res) => {
  const ref  = db.collection('users').doc(req.user.uid);
  const COST = 2;

  try {
    const result = await db.runTransaction(async tx => {
      const doc  = await tx.get(ref);
      const user = doc.data();

      if (user.credits < COST) {
        throw new Error('INSUFFICIENT_CREDITS');
      }

      tx.update(ref, { credits: user.credits - COST });
      return { remaining: user.credits - COST };
    });

    // Log transaction
    await db.collection('transactions').add({
      user_id: req.user.uid,
      type: 'debit',
      amount: COST,
      description: 'AI chat message',
      created_at: new Date(),
    });

    res.json(result);
  } catch (e) {
    if (e.message === 'INSUFFICIENT_CREDITS') {
      return res.status(402).json({ error: 'INSUFFICIENT_CREDITS', credits: 0 });
    }
    res.status(500).json({ error: e.message });
  }
});

// Transaction history
router.get('/history', authMw, async (req, res) => {
  const snap = await db.collection('transactions')
    .where('user_id', '==', req.user.uid)
    .orderBy('created_at', 'desc')
    .limit(50)
    .get();
  res.json(snap.docs.map(d => ({ id: d.id, ...d.data() })));
});

module.exports = router;