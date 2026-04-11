const express = require('express');
const router  = express.Router();
const { db }  = require('../config/firebase');
const authMiddleware = require('../middleware/auth');

// ── Agora token generation (optional — needs AGORA_APP_ID + AGORA_APP_CERT) ──
let AgoraToken = null;
try { AgoraToken = require('agora-token'); } catch (_) {}

const AGORA_APP_ID   = process.env.AGORA_APP_ID   || '';
const AGORA_APP_CERT = process.env.AGORA_APP_CERT  || '';

function _buildToken(channelName, uid, role) {
  if (!AgoraToken || !AGORA_APP_ID || !AGORA_APP_CERT) return null;
  const { RtcTokenBuilder, RtcRole } = AgoraToken;
  const expireTs = Math.floor(Date.now() / 1000) + 3600; // 1 h
  return RtcTokenBuilder.buildTokenWithUid(
    AGORA_APP_ID, AGORA_APP_CERT,
    channelName, uid,
    role === 'broadcaster' ? RtcRole.PUBLISHER : RtcRole.SUBSCRIBER,
    expireTs, expireTs,
  );
}

function _toSafeText(value, fallback, maxLen = 120) {
  if (typeof value !== 'string') return fallback;
  const v = value.trim();
  if (!v) return fallback;
  return v.slice(0, maxLen);
}

function _toSafeTags(tags) {
  if (!Array.isArray(tags)) return [];
  return tags
    .map((t) => (typeof t === 'string' ? t.trim() : ''))
    .filter(Boolean)
    .slice(0, 20);
}

async function _canHostLive(uid) {
  const doc = await db.collection('users').doc(uid).get();
  if (!doc.exists) return false;
  const user = doc.data() || {};
  if (user.role === 'admin') return true;
  return user.role === 'trainer' && user.trainer_status === 'approved';
}

// ─────────────────────────────────────────────────────────────────────────────
// GET /live/sessions
// List live + scheduled sessions from Firestore.
// ─────────────────────────────────────────────────────────────────────────────
router.get('/sessions', authMiddleware, async (req, res) => {
  try {
    const snap = await db.collection('live_sessions')
      .where('status', 'in', ['live', 'scheduled'])
      .orderBy('scheduled_at', 'asc')
      .get();

    const sessions = snap.docs.map(doc => {
      const d = doc.data();
      return {
        id:               doc.id,
        trainer_id:       d.trainer_id,
        trainer_name:     d.trainer_name,
        title:            d.title,
        description:      d.description,
        category:         d.category,
        status:           d.status,
        scheduled_at:     d.scheduled_at?.toDate?.()?.toISOString() || null,
        started_at:       d.started_at?.toDate?.()?.toISOString()   || null,
        ended_at:         d.ended_at?.toDate?.()?.toISOString()     || null,
        viewer_count:     d.viewer_count || 0,
        is_recorded:      d.is_recorded  || false,
        tags:             d.tags         || [],
        agora_channel:    d.agora_channel || null,
      };
    });

    res.json({ sessions });
  } catch (e) {
    console.error('List sessions failed:', e && e.message);
    res.status(500).json({ error: 'Unable to fetch sessions' });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// POST /live/sessions
// Trainer creates/schedules a session.
// Body: { title, description, category, scheduled_at, is_recorded, tags, trainer_name }
// ─────────────────────────────────────────────────────────────────────────────
router.post('/sessions', authMiddleware, async (req, res) => {
  const { uid } = req.user;

  try {
    const canHost = await _canHostLive(uid);
    if (!canHost) {
      return res.status(403).json({ error: 'Only approved trainers can create sessions' });
    }

    const scheduledAtRaw = req.body?.scheduled_at;
    const parsedScheduledAt = scheduledAtRaw ? new Date(scheduledAtRaw) : new Date();
    const safeScheduledAt = Number.isNaN(parsedScheduledAt.getTime()) ? new Date() : parsedScheduledAt;

    const data = {
      trainer_id:    uid,
      trainer_name: _toSafeText(req.body?.trainer_name, '', 80),
      title: _toSafeText(req.body?.title, 'Live Session', 120),
      description: _toSafeText(req.body?.description, '', 800),
      category: _toSafeText(req.body?.category, 'Workout', 50),
      status:        'scheduled',
      scheduled_at:  safeScheduledAt,
      is_recorded: Boolean(req.body?.is_recorded),
      tags: _toSafeTags(req.body?.tags),
      viewer_count:  0,
      agora_channel: null,
      created_at:    new Date(),
    };

    const ref = await db.collection('live_sessions').add(data);
    return res.json({ id: ref.id, ...data });
  } catch (e) {
    console.error('Create live session failed:', e && e.message);
    return res.status(500).json({ error: 'Unable to create live session' });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// POST /live/start
// Trainer goes live — returns Agora token + channel name.
// Body: { session_id?, channel? }
// ─────────────────────────────────────────────────────────────────────────────
router.post('/start', authMiddleware, async (req, res) => {
  const { uid }       = req.user;
  const { session_id, channel } = req.body || {};

  const channelName = _toSafeText(channel, `pn_${uid.substring(0, 8)}_${Date.now()}`, 120);
  const broadcasterUid = 1; // fixed uid for broadcaster

  const agoraToken = _buildToken(channelName, broadcasterUid, 'broadcaster');

  try {
    const canHost = await _canHostLive(uid);
    if (!canHost) {
      return res.status(403).json({ error: 'Only approved trainers can start live sessions' });
    }

    if (session_id && session_id !== 'instant') {
      const sessionRef = db.collection('live_sessions').doc(session_id);
      const sessionDoc = await sessionRef.get();
      if (!sessionDoc.exists) return res.status(404).json({ error: 'Session not found' });
      const session = sessionDoc.data() || {};
      if (session.trainer_id !== uid) {
        return res.status(403).json({ error: 'Cannot start another trainer session' });
      }

      await db.collection('live_sessions').doc(session_id).update({
        status:        'live',
        agora_channel: channelName,
        started_at:    new Date(),
      });
    }

    res.json({
      agora_token:  agoraToken,
      app_id:       AGORA_APP_ID,
      channel:      channelName,
      uid:          broadcasterUid,
    });
  } catch (e) {
    console.error('Start live failed:', e && e.message);
    res.status(500).json({ error: 'Unable to start live session' });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// POST /live/join
// Viewer joins — returns Agora audience token.
// Body: { session_id, channel }
// ─────────────────────────────────────────────────────────────────────────────
router.post('/join', authMiddleware, async (req, res) => {
  const channel = _toSafeText(req.body?.channel, '', 120);
  if (!channel) return res.status(400).json({ error: 'Channel is required' });

  // Viewers get uid in 2000–900000 range (broadcaster is uid 1)
  const viewerUid  = Math.floor(Math.random() * 898000) + 2000;
  const agoraToken = _buildToken(channel, viewerUid, 'audience');

  res.json({
    agora_token: agoraToken,
    app_id:      AGORA_APP_ID,
    channel,
    uid:         viewerUid,
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// POST /live/end/:sessionId
// Trainer ends session.
// ─────────────────────────────────────────────────────────────────────────────
router.post('/end/:sessionId', authMiddleware, async (req, res) => {
  const { sessionId } = req.params;
  try {
    const sessionRef = db.collection('live_sessions').doc(sessionId);
    const sessionDoc = await sessionRef.get();
    if (!sessionDoc.exists) return res.status(404).json({ error: 'Session not found' });

    const session = sessionDoc.data() || {};
    if (session.trainer_id !== req.user.uid) {
      const callerDoc = await db.collection('users').doc(req.user.uid).get();
      const callerRole = callerDoc.exists ? callerDoc.data()?.role : null;
      if (callerRole !== 'admin') {
        return res.status(403).json({ error: 'Cannot end another trainer session' });
      }
    }

    await db.collection('live_sessions').doc(sessionId).update({
      status:   'ended',
      ended_at: new Date(),
    });
    res.json({ success: true });
  } catch (e) {
    console.error('End live failed:', e && e.message);
    res.status(500).json({ error: 'Unable to end live session' });
  }
});

module.exports = router;
