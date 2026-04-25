/**
 * ActivityLog Model
 * System-wide audit trail for admin analytics
 */

const mongoose = require('mongoose');

const activityLogSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    action: {
      type: String,
      required: true,
      enum: [
        'LOGIN',
        'REGISTER',
        'LOGOUT',
        'CREATE_REMINDER',
        'EDIT_REMINDER',
        'DELETE_REMINDER',
        'CREATE_ASSIGNMENT',
        'EDIT_ASSIGNMENT',
        'DELETE_ASSIGNMENT',
        'READ_REMINDER',
        'COMPLETE_ASSIGNMENT',
        'CREATE_USER',
        'DELETE_USER',
        'UPLOAD_FILE',
        'SEND_ANNOUNCEMENT',
      ],
    },
    metadata: {
      type: mongoose.Schema.Types.Mixed,
      default: {},
    },
    ipAddress: String,
    userAgent: String,
  },
  { timestamps: true }
);

activityLogSchema.index({ userId: 1, createdAt: -1 });
activityLogSchema.index({ action: 1, createdAt: -1 });
// Auto-delete logs older than 90 days
activityLogSchema.index({ createdAt: 1 }, { expireAfterSeconds: 90 * 24 * 60 * 60 });

const ActivityLog = mongoose.model('ActivityLog', activityLogSchema);
module.exports = ActivityLog;
