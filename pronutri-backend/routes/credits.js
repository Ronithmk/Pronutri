const express  = require('express');
const router   = express.Router();
const authMw   = require('../middleware/auth');
const { db }   = require('../config/firebase');

// Get balance
router.get('/balance', authMw, async (req, res) => {
  try {
    const doc = await db.collection('users').doc(req.user.uid).get();
    if (!doc.exists) return res.status(404).json({ error: 'User not found' });
    const credits = Number(doc.data()?.credits || 0);
    return res.json({ credits: Number.isFinite(credits) ? credits : 0 });
  } catch (e) {
    console.error('Credits balance failed:', e && e.message);
    return res.status(500).json({ error: 'Unable to fetch credits' });
  }
});

// Deduct ₹2 for AI chat
router.post('/deduct', authMw, async (req, res) => {
  const ref  = db.collection('users').doc(req.user.uid);
  const COST = 2;

  try {
    const result = await db.runTransaction(async tx => {
      const doc  = await tx.get(ref);
      if (!doc.exists) throw new Error('USER_NOT_FOUND');
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
    if (e.message === 'USER_NOT_FOUND') {
      return res.status(404).json({ error: 'User not found' });
    }
    console.error('Credits deduct failed:', e && e.message);
    res.status(500).json({ error: 'Unable to deduct credits' });
  }
});

// Transaction history
router.get('/history', authMw, async (req, res) => {
  try {
    const snap = await db.collection('transactions')
      .where('user_id', '==', req.user.uid)
      .orderBy('created_at', 'desc')
      .limit(50)
      .get();
    res.json(snap.docs.map(d => ({ id: d.id, ...d.data() })));
  } catch (e) {
    console.error('Credits history failed:', e && e.message);
    res.status(500).json({ error: 'Unable to fetch transaction history' });
  }
});

module.exports = router;
