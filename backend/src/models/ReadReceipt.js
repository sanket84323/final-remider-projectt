/**
 * ReadReceipt Model
 * Tracks which users have read which reminders
 */

const mongoose = require('mongoose');

const readReceiptSchema = new mongoose.Schema(
  {
    reminderId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Reminder',
      required: true,
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    readAt: {
      type: Date,
      default: Date.now,
    },
  },
  { timestamps: true }
);

// Ensure one receipt per user per reminder
readReceiptSchema.index({ reminderId: 1, userId: 1 }, { unique: true });

const ReadReceipt = mongoose.model('ReadReceipt', readReceiptSchema);
module.exports = ReadReceipt;
