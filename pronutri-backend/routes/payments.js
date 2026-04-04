const express   = require('express');
const router    = express.Router();
const Razorpay  = require('razorpay');
const crypto    = require('crypto');
const authMw    = require('../middleware/auth');
const { db }    = require('../config/firebase');

const rp = new Razorpay({
  key_id:     process.env.RAZORPAY_KEY_ID,
  key_secret: process.env.RAZORPAY_KEY_SECRET,
});

// Create order — ₹100 for credits or subscription
router.post('/create-order', authMw, async (req, res) => {
  const { type } = req.body; // 'credits' or 'subscription'
  try {
    const order = await rp.orders.create({
      amount:   10000, // ₹100 in paise
      currency: 'INR',
      notes:    { uid: req.user.uid, type },
    });
    res.json({ order_id: order.id, amount: 10000, currency: 'INR',
               key: process.env.RAZORPAY_KEY_ID });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Webhook — called by Razorpay after payment
router.post('/webhook', express.raw({ type: 'application/json' }), async (req, res) => {
  const sig       = req.headers['x-razorpay-signature'];
  const body      = req.body.toString();
  const expected  = crypto
    .createHmac('sha256', process.env.RAZORPAY_WEBHOOK_SECRET)
    .update(body).digest('hex');

  if (sig !== expected) return res.status(400).send('Invalid signature');

  const event = JSON.parse(body);
  if (event.event === 'payment.captured') {
    const payment = event.payload.payment.entity;
    const { uid, type } = payment.notes;
    const ref = db.collection('users').doc(uid);

    if (type === 'credits') {
      await db.runTransaction(async tx => {
        const doc = await tx.get(ref);
        tx.update(ref, { credits: doc.data().credits + 100 });
      });
      await db.collection('transactions').add({
        user_id: uid, type: 'credit', amount: 100,
        description: 'Credit topup via Razorpay',
        razorpay_payment_id: payment.id,
        created_at: new Date(),
      });
    } else if (type === 'subscription') {
      const end = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
      await ref.update({ subscription_active: true, subscription_end: end });
      await db.collection('transactions').add({
        user_id: uid, type: 'subscription', amount: 100,
        description: 'Monthly subscription',
        razorpay_payment_id: payment.id,
        created_at: new Date(),
      });
    }
  }
  res.json({ status: 'ok' });
});

module.exports = router;