const http = require('http');
const { URL } = require('url');

const PORT = Number(process.env.MOCK_PORT || 3000);
const MOCK_EMAIL = 'testtrainer@example.com';
const MOCK_PASSWORD = 'Trainer@1234';
const MOCK_TOKEN = 'mock-trainer-token';
const MOCK_UID = 'mock-trainer-uid';

let trainerStatus = 'pending';

function sendJson(res, code, data) {
  res.writeHead(code, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(data));
}

function parseJsonBody(req) {
  return new Promise((resolve) => {
    let raw = '';
    req.on('data', (chunk) => {
      raw += chunk;
      if (raw.length > 1_000_000) {
        req.destroy();
      }
    });
    req.on('end', () => {
      if (!raw) {
        resolve({});
        return;
      }
      try {
        resolve(JSON.parse(raw));
      } catch (_) {
        resolve(null);
      }
    });
    req.on('error', () => resolve(null));
  });
}

const server = http.createServer(async (req, res) => {
  const method = req.method || '';
  const url = new URL(req.url || '/', `http://127.0.0.1:${PORT}`);
  const path = url.pathname;

  if (method === 'GET' && path === '/health') {
    sendJson(res, 200, { ok: true, trainer_status: trainerStatus });
    return;
  }

  if (method === 'POST' && path === '/api/auth/login') {
    const body = await parseJsonBody(req);
    if (!body) {
      sendJson(res, 400, { error: 'Invalid JSON' });
      return;
    }

    const email = String(body.email || '').trim().toLowerCase();
    const password = String(body.password || '');
    if (email !== MOCK_EMAIL || password !== MOCK_PASSWORD) {
      sendJson(res, 401, { error: 'Invalid credentials' });
      return;
    }

    sendJson(res, 200, {
      token: MOCK_TOKEN,
      uid: MOCK_UID,
      name: 'Mock Trainer',
      credits: 0,
      subscription_active: false,
      trial_end: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
      role: 'trainer',
      trainer_status: trainerStatus,
    });
    return;
  }

  if (method === 'GET' && path === '/api/auth/trainer-status') {
    const auth = String(req.headers.authorization || '');
    if (auth !== `Bearer ${MOCK_TOKEN}`) {
      sendJson(res, 401, { error: 'Invalid token' });
      return;
    }
    sendJson(res, 200, { trainer_status: trainerStatus });
    return;
  }

  if (method === 'POST' && path === '/api/notifications/register-token') {
    sendJson(res, 200, { success: true });
    return;
  }

  if (method === 'POST' && path === '/api/test/reset') {
    trainerStatus = 'pending';
    sendJson(res, 200, { ok: true, trainer_status: trainerStatus });
    return;
  }

  if (method === 'POST' && path === '/api/test/approve') {
    trainerStatus = 'approved';
    sendJson(res, 200, { ok: true, trainer_status: trainerStatus });
    return;
  }

  sendJson(res, 404, { error: 'Not found', method, path });
});

server.listen(PORT, () => {
  console.log(`mock_server listening on ${PORT}`);
});
