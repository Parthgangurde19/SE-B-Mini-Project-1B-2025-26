// setAdminClaim.js
const admin = require('firebase-admin');
const serviceAccount = require('./doc/codeclub-b8e50-firebase-adminsdk-fbsvc-70030a5eaa.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const uid = 'DajLMQP6gvaXY9z7PxAgTDPnfRG3';

admin
  .auth()
  .setCustomUserClaims(uid, { admin: true })
  .then(() => {
    console.log('✅ Custom claim set: admin=true');
    process.exit(0);
  })
  .catch((err) => {
    console.error('❌ Failed to set custom claim', err);
    process.exit(1);
  });