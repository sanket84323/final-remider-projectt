/**
 * Notification Service
 * Creates DB notification records and dispatches FCM push notifications
 */

const Notification = require('../models/Notification');
const fcmService = require('./fcm.service');
const logger = require('../utils/logger');

/**
 * Create in-app notifications for a list of users and optionally send FCM push
 * @param {Object} options
 * @param {Array} options.users - Array of user objects with _id and fcmToken
 * @param {string} options.title
 * @param {string} options.body
 * @param {string} options.type - 'reminder' | 'assignment' | 'announcement' | 'system'
 * @param {string} options.priority
 * @param {ObjectId} options.reminderId
 * @param {ObjectId} options.assignmentId
 * @param {Object} options.data - Extra payload for deep linking
 */
const notifyUsers = async ({ users, title, body, type = 'reminder', priority = 'normal', reminderId, assignmentId, data = {} }) => {
  if (!users || users.length === 0) return;

  try {
    // Bulk create in-app notification records
    const notificationDocs = users.map((user) => ({
      userId: user._id,
      reminderId: reminderId || null,
      assignmentId: assignmentId || null,
      title,
      body,
      type,
      priority,
      data,
      deliveredAt: new Date(),
    }));

    await Notification.insertMany(notificationDocs, { ordered: false });

    // Batch push notification via FCM
    const fcmTokens = users.map((u) => u.fcmToken).filter(Boolean);
    if (fcmTokens.length > 0) {
      await fcmService.sendToMultipleTokens({ tokens: fcmTokens, title, body, data });
    }

    logger.info(`Notified ${users.length} users: "${title}"`);
  } catch (error) {
    logger.error(`Notification dispatch failed: ${error.message}`);
  }
};

module.exports = { notifyUsers };
