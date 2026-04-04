const { db, fcm } = require('../config/firebase');

const templates = [
  { id: 'hydration',  title: '💧 Time to hydrate!',
    body: "You haven't logged water in 2 hours. Drink a glass now!",  type: 'hydration' },
  { id: 'calories',   title: '🔥 Log your last meal',
    body: "Track what you ate to stay on target for your calorie goal.", type: 'calories' },
  { id: 'steps',      title: '👟 Keep moving!',
    body: "You're halfway to your step goal. A short walk will do it!",  type: 'steps' },
  { id: 'protein',    title: '💪 Protein check',
    body: "Your protein intake is low today. Time for a high-protein snack!", type: 'protein' },
  { id: 'evening',    title: '🌙 Evening check-in',
    body: "How did today go? Log your dinner to complete today's tracking.", type: 'evening' },
];

const getTemplate = () => {
  const hour = new Date().getHours();
  if (hour < 9)  return templates[0]; // morning hydration
  if (hour < 12) return templates[3]; // protein
  if (hour < 14) return templates[1]; // log meal
  if (hour < 17) return templates[2]; // steps
  if (hour < 20) return templates[0]; // afternoon hydration
  return templates[4];                // evening
};

module.exports = async function sendScheduledNotifications() {
  try {
    const tmpl = getTemplate();
    // Get all users with FCM tokens
    const snap = await db.collection('users')
      .where('fcm_token', '!=', null).get();

    const tokens = snap.docs
      .map(d => d.data().fcm_token)
      .filter(Boolean);

    if (!tokens.length) return;

    // FCM multicast — max 500 per batch
    const chunks = [];
    for (let i = 0; i < tokens.length; i += 500)
      chunks.push(tokens.slice(i, i + 500));

    for (const chunk of chunks) {
      await fcm.sendEachForMulticast({
        tokens: chunk,
        notification: { title: tmpl.title, body: tmpl.body },
        data: { type: tmpl.type, template_id: tmpl.id },
        android: { priority: 'high',
          notification: { channelId: 'pronutri_reminders', sound: 'default' } },
        apns: { payload: { aps: { sound: 'default', badge: 1 } } },
      });
    }

    console.log(`Sent ${tmpl.id} notification to ${tokens.length} users`);
  } catch (e) {
    console.error('Notification job failed:', e.message);
  }
};