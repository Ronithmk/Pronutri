require('dotenv').config();
const express = require('express');
const cors = require('cors');
const cron = require('node-cron');
const app = express();

app.use(cors());
app.use(express.json());

// Routes
app.use('/api/auth',         require('./routes/auth'));
app.use('/api/credits',      require('./routes/credits'));
app.use('/api/subscription', require('./routes/subscription'));
app.use('/api/activity',     require('./routes/activity'));
app.use('/api/payments',     require('./routes/payments'));
app.use('/api/notifications',require('./routes/notifications'));

// Scheduled notification job — every 2 hours
cron.schedule('0 */2 * * *', () => {
  require('./jobs/sendScheduledNotifications')();
});

app.listen(process.env.PORT || 3000, () =>
  console.log('ProNutri API running on port 3000'));