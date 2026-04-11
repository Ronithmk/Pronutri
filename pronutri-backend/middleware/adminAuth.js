const jwt    = require('jsonwebtoken');
const { db } = require('../config/firebase');

function _extractBearerToken(authHeader) {
  if (!authHeader || typeof authHeader !== 'string') return null;
  const [scheme, token] = authHeader.split(' ');
  if (!scheme || scheme.toLowerCase() !== 'bearer' || !token) return null;
  return token.trim();
}

/**
 * Middleware: verifies JWT AND checks that user.role === 'admin' in Firestore.
 * Attach req.user = { uid, email, role } on success.
 */
module.exports = async (req, res, next) => {
  const secret = process.env.JWT_SECRET;
  if (!secret) return res.status(500).json({ error: 'Server configuration error' });

  const token = _extractBearerToken(req.headers.authorization);
  if (!token) return res.status(401).json({ error: 'Missing bearer token' });

  let payload;
  try {
    payload = jwt.verify(token, secret);
  } catch {
    return res.status(401).json({ error: 'Invalid token' });
  }

  try {
    const snap = await db.collection('users').doc(payload.uid).get();
    if (!snap.exists) return res.status(401).json({ error: 'User not found' });

    const data = snap.data();
    if (data.role !== 'admin') {
      return res.status(403).json({ error: 'Admin access required' });
    }

    req.user = { uid: payload.uid, email: payload.email, role: 'admin' };
    return next();
  } catch (e) {
    console.error('Admin auth middleware failed:', e && e.message);
    return res.status(500).json({ error: 'Authorization check failed' });
  }
};
