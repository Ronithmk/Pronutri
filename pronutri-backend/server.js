const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '.env') });
const express = require('express');
const cors    = require('cors');
const cron    = require('node-cron');
const app     = express();

const allowedOrigins = (process.env.CORS_ALLOWED_ORIGINS || '')
  .split(',')
  .map((o) => o.trim())
  .filter(Boolean);

app.disable('x-powered-by');
app.use(cors({
  origin(origin, cb) {
    if (!origin) return cb(null, true); // mobile/native clients
    if (!allowedOrigins.length) return cb(null, true); // backward-compatible fallback
    if (allowedOrigins.includes(origin)) return cb(null, true);
    return cb(new Error('Not allowed by CORS'));
  },
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  maxAge: 86400,
}));

// Razorpay signature verification needs the raw body.
app.use('/api/payments/webhook', express.raw({ type: 'application/json', limit: '1mb' }));
app.use(express.json({ limit: '1mb' }));

// Routes
app.use('/api/auth',         require('./routes/auth'));
app.use('/api/credits',      require('./routes/credits'));
app.use('/api/subscription', require('./routes/subscription'));
app.use('/api/activity',     require('./routes/activity'));
app.use('/api/payments',     require('./routes/payments'));
app.use('/api/notifications',require('./routes/notifications'));
app.use('/api/trainer',      require('./routes/trainer'));
app.use('/api/live',         require('./routes/live'));

// Scheduled notification job — every 2 hours
cron.schedule('0 */2 * * *', () => {
  require('./jobs/sendScheduledNotifications')();
});

app.get('/health', (_req, res) => res.json({ ok: true }));

app.use((_req, res) => {
  res.status(404).json({ error: 'Not found' });
});

app.use((err, _req, res, _next) => {
  if (err && err.message === 'Not allowed by CORS') {
    return res.status(403).json({ error: 'CORS blocked this origin' });
  }
  console.error('Unhandled server error:', err && (err.stack || err.message || err));
  res.status(500).json({ error: 'Internal server error' });
});

const PORT = Number(process.env.PORT || 3000);
app.listen(PORT, () => console.log(`ProNutri API running on port ${PORT}`));
