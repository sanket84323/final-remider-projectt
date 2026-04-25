/**
 * Firebase Admin SDK Initialization
 */

const admin = require('firebase-admin');
const logger = require('../utils/logger');

let firebaseInitialized = false;

const initFirebase = () => {
  // Skip if credentials not configured
  if (!process.env.FIREBASE_PROJECT_ID || !process.env.FIREBASE_PRIVATE_KEY) {
    logger.warn('⚠️  Firebase credentials not configured. Push notifications disabled.');
    return;
  }

  try {
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId: process.env.FIREBASE_PROJECT_ID,
        privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      }),
    });

    firebaseInitialized = true;
    logger.info('🔥 Firebase Admin SDK initialized');
  } catch (error) {
    logger.error(`Firebase initialization failed: ${error.message}`);
  }
};

const getFirebaseAdmin = () => {
  if (!firebaseInitialized) return null;
  return admin;
};

module.exports = { initFirebase, getFirebaseAdmin };
