const admin = require('firebase-admin');
const serviceAccount = require('./doc/codeclub-b8e50-firebase-adminsdk-fbsvc-70030a5eaa.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

admin
  .auth()
  .getUser('DajLMQP6gvaXY9z7PxAgTDPnfRG3')
  .then((userRecord) => {
    console.log('User:', userRecord.email);
    console.log('Custom Claims:', userRecord.customClaims);
    process.exit(0);
  })
  .catch((err) => {
    console.error('Error fetching user:', err);
    process.exit(1);
  });
