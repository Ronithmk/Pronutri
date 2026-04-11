const express   = require('express');
const router    = express.Router();
const Razorpay  = require('razorpay');
const crypto    = require('crypto');
const authMw    = require('../middleware/auth');
const { db }    = require('../config/firebase');

let rp = null;
if (process.env.RAZORPAY_KEY_ID && process.env.RAZORPAY_KEY_SECRET) {
  try {
    rp = new Razorpay({
      key_id: process.env.RAZORPAY_KEY_ID,
      key_secret: process.env.RAZORPAY_KEY_SECRET,
    });
  } catch (e) {
    console.warn('Razorpay initialization failed:', e && e.message);
  }
}

const ALLOWED_ORDER_TYPES = new Set(['credits', 'subscription']);

function _isRazorpayConfigured() {
  return !!(process.env.RAZORPAY_KEY_ID && process.env.RAZORPAY_KEY_SECRET && rp);
}

function _safeEqual(a, b) {
  if (typeof a !== 'string' || typeof b !== 'string') return false;
  const aBuf = Buffer.from(a, 'utf8');
  const bBuf = Buffer.from(b, 'utf8');
  if (aBuf.length !== bBuf.length) return false;
  return crypto.timingSafeEqual(aBuf, bBuf);
}

function _getRawBodyBuffer(body) {
  if (Buffer.isBuffer(body)) return body;
  if (typeof body === 'string') return Buffer.from(body);
  if (body && typeof body === 'object') return Buffer.from(JSON.stringify(body));
  return Buffer.from('');
}

// Create order — ₹100 for credits or subscription
router.post('/create-order', authMw, async (req, res) => {
  const type = req.body?.type;
  if (!ALLOWED_ORDER_TYPES.has(type)) {
    return res.status(400).json({ error: 'Invalid order type' });
  }
  if (!_isRazorpayConfigured()) {
    return res.status(503).json({ error: 'Payments are not configured' });
  }

  try {
    const order = await rp.orders.create({
      amount:   10000, // ₹100 in paise
      currency: 'INR',
      notes:    { uid: req.user.uid, type },
    });
    return res.json({
      order_id: order.id,
      amount: 10000,
      currency: 'INR',
      key: process.env.RAZORPAY_KEY_ID,
    });
  } catch (e) {
    console.error('Create order failed:', e && e.message);
    return res.status(500).json({ error: 'Unable to create payment order' });
  }
});

// Webhook — called by Razorpay after payment
router.post('/webhook', async (req, res) => {
  if (!process.env.RAZORPAY_WEBHOOK_SECRET) {
    return res.status(503).send('Webhook secret missing');
  }

  const sig       = req.headers['x-razorpay-signature'];
  const bodyBuf   = _getRawBodyBuffer(req.body);
  const body      = bodyBuf.toString('utf8');
  const expected  = crypto
    .createHmac('sha256', process.env.RAZORPAY_WEBHOOK_SECRET)
    .update(bodyBuf).digest('hex');

  if (!_safeEqual(String(sig || ''), expected)) {
    return res.status(400).send('Invalid signature');
  }

  let event;
  try {
    event = JSON.parse(body);
  } catch {
    return res.status(400).send('Invalid payload');
  }

  if (event.event === 'payment.captured') {
    const payment = event.payload.payment.entity;
    const uid = payment?.notes?.uid;
    const type = payment?.notes?.type;
    const paymentId = payment?.id;
    if (!uid || !ALLOWED_ORDER_TYPES.has(type) || !paymentId) {
      return res.status(400).send('Invalid payment metadata');
    }

    // Idempotency guard: don't double-credit on webhook retries.
    const existing = await db.collection('transactions')
      .where('razorpay_payment_id', '==', paymentId)
      .limit(1)
      .get();
    if (!existing.empty) return res.json({ status: 'ok', duplicate: true });

    const ref = db.collection('users').doc(uid);

    if (type === 'credits') {
      await db.runTransaction(async tx => {
        const doc = await tx.get(ref);
        if (!doc.exists) throw new Error('USER_NOT_FOUND');
        tx.update(ref, { credits: doc.data().credits + 100 });
      });
      await db.collection('transactions').add({
        user_id: uid, type: 'credit', amount: 100,
        description: 'Credit topup via Razorpay',
        razorpay_payment_id: paymentId,
        created_at: new Date(),
      });
    } else if (type === 'subscription') {
      const end = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
      await ref.update({ subscription_active: true, subscription_end: end });
      await db.collection('transactions').add({
        user_id: uid, type: 'subscription', amount: 100,
        description: 'Monthly subscription',
        razorpay_payment_id: paymentId,
        created_at: new Date(),
      });
    }
  }

  return res.json({ status: 'ok' });
});

module.exports = router;
