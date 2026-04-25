/**
 * FCM Push Notification Service
 */

const { getFirebaseAdmin } = require('../config/firebase');
const logger = require('../utils/logger');

/**
 * Send push notification to a single FCM token
 */
const sendToToken = async ({ token, title, body, data = {} }) => {
  const admin = getFirebaseAdmin();
  if (!admin || !token) return null;
  try {
    const result = await admin.messaging().send({
      token,
      notification: { title, body },
      data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
      android: { priority: 'high', notification: { sound: 'default', channelId: 'campussync_main' } },
      apns: { payload: { aps: { sound: 'default', badge: 1 } } },
    });
    return result;
  } catch (error) {
    if (error.code === 'messaging/registration-token-not-registered') {
      logger.warn(`Invalid FCM token detected: ${token.substring(0, 20)}...`);
    } else {
      logger.error(`FCM send error: ${error.message}`);
    }
    return null;
  }
};

/**
 * Send push notification to multiple FCM tokens (batch)
 */
const sendToMultipleTokens = async ({ tokens, title, body, data = {} }) => {
  const admin = getFirebaseAdmin();
  if (!admin || !tokens?.length) return null;
  const validTokens = tokens.filter(Boolean);
  if (!validTokens.length) return null;
  try {
    const result = await admin.messaging().sendEachForMulticast({
      tokens: validTokens,
      notification: { title, body },
      data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
      android: { priority: 'high' },
    });
    logger.info(`FCM batch: ${result.successCount} sent, ${result.failureCount} failed`);
    return result;
  } catch (error) {
    logger.error(`FCM batch error: ${error.message}`);
    return null;
  }
};

module.exports = { sendToToken, sendToMultipleTokens };
