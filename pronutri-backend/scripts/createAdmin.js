/**
 * ProNutri — One-time admin account seeder
 *
 * Run once from the backend folder:
 *   node scripts/createAdmin.js
 *
 * This creates (or resets) the admin account in Firestore.
 * Admin email  : mkronith1308@gmail.com
 * Admin password: set via ADMIN_PASSWORD env var, or defaults to a strong generated one.
 *
 * The script prints the final credentials to the console — save them immediately.
 */

require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });

const bcrypt = require('bcryptjs');
const { db } = require('../config/firebase');

const ADMIN_EMAIL    = process.env.ADMIN_EMAIL || 'mkronith1308@gmail.com';
const ADMIN_NAME     = 'Ronith (Admin)';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || _generatePassword();

function _generatePassword() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789!@#$';
  return Array.from({ length: 14 }, () =>
    chars[Math.floor(Math.random() * chars.length)]).join('');
}

async function main() {
  console.log('\n──────────────────────────────────────────');
  console.log('  ProNutri Admin Account Setup');
  console.log('──────────────────────────────────────────\n');

  // Check if admin already exists
  const existing = await db.collection('users')
    .where('email', '==', ADMIN_EMAIL)
    .where('role',  '==', 'admin')
    .limit(1).get();

  if (!existing.empty) {
    const doc = existing.docs[0];
    console.log(`⚠️  Admin account already exists (uid: ${doc.id})`);
    console.log(`   Email: ${ADMIN_EMAIL}`);
    console.log('\n   To reset the password, run:');
    console.log(`   ADMIN_PASSWORD=yourNewPass node scripts/createAdmin.js --reset\n`);

    if (!process.argv.includes('--reset')) {
      process.exit(0);
    }

    // Reset password
    const hash = await bcrypt.hash(ADMIN_PASSWORD, 12);
    await db.collection('users').doc(doc.id).update({ password: hash });
    console.log('✅  Password reset successfully.\n');
    _printCredentials();
    process.exit(0);
  }

  // Create new admin account
  const hash = await bcrypt.hash(ADMIN_PASSWORD, 12);
  const now  = new Date();

  const ref = await db.collection('users').add({
    name:                ADMIN_NAME,
    email:               ADMIN_EMAIL,
    password:            hash,
    role:                'admin',
    trainer_status:      null,
    credits:             0,
    trial_start:         now,
    trial_end:           new Date(now.getTime() + 365 * 24 * 60 * 60 * 1000), // 1 year
    subscription_active: true,
    fcm_token:           null,
    created_at:          now,
  });

  console.log('✅  Admin account created successfully!\n');
  console.log(`   Firestore UID : ${ref.id}`);
  _printCredentials();
  process.exit(0);
}

function _printCredentials() {
  console.log('──────────────────────────────────────────');
  console.log('  ADMIN CREDENTIALS — save these now!');
  console.log('──────────────────────────────────────────');
  console.log(`  Email    : ${ADMIN_EMAIL}`);
  console.log(`  Password : ${ADMIN_PASSWORD}`);
  console.log('──────────────────────────────────────────');
  console.log('\n  Use these to log in on the ProNutri app.');
  console.log('  The admin panel appears in Settings.\n');
}

main().catch(e => {
  console.error('❌ Error:', e.message);
  process.exit(1);
});
