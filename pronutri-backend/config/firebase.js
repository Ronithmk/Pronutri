const admin = require('firebase-admin');

function _isPlaceholder(value) {
  const v = String(value || '').toLowerCase();
  return (
    !v ||
    v.includes('your-project-id') ||
    v.includes('firebase-adminsdk@...') ||
    v.includes('your_') ||
    v.includes('...')
  );
}

if (!admin.apps.length) {
  const projectId = process.env.FIREBASE_PROJECT_ID;
  const privateKey = process.env.FIREBASE_PRIVATE_KEY;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;

  if (_isPlaceholder(projectId) || _isPlaceholder(privateKey) || _isPlaceholder(clientEmail)) {
    throw new Error(
      'Firebase credentials are not configured. Set FIREBASE_PROJECT_ID, FIREBASE_PRIVATE_KEY, and FIREBASE_CLIENT_EMAIL in pronutri-backend/.env',
    );
  }

  if (!privateKey) {
    throw new Error('FIREBASE_PRIVATE_KEY is not configured');
  }
  try {
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId,
        privateKey: privateKey.replace(/\\n/g, '\n'),
        clientEmail,
      }),
    });
  } catch (err) {
    throw new Error(
      `Firebase initialization failed. Check FIREBASE_* credentials in pronutri-backend/.env. ${err.message}`,
    );
  }
}

const db  = admin.firestore();
const fcm = admin.messaging();
module.exports = { admin, db, fcm };
