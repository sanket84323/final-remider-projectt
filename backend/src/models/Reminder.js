/**
 * Reminder Model
 * Represents reminders/notices created by teachers and admins
 */

const mongoose = require('mongoose');

const attachmentSchema = new mongoose.Schema({
  originalName: String,
  url: String,
  publicId: String,
  mimeType: String,
  size: Number,
});

const reminderSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: [true, 'Title is required'],
      trim: true,
      maxlength: [200, 'Title cannot exceed 200 characters'],
    },
    description: {
      type: String,
      required: [true, 'Description is required'],
      trim: true,
    },
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    // Who should receive this reminder
    targetAudience: {
      type: {
        type: String,
        enum: ['all', 'department', 'class', 'section', 'specific'],
        default: 'all',
      },
      department: { type: mongoose.Schema.Types.ObjectId, ref: 'Department' },
      className: String,
      section: String,
      userIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
    },
    priority: {
      type: String,
      enum: ['normal', 'important', 'urgent'],
      default: 'normal',
    },
    category: {
      type: String,
      enum: ['reminder', 'announcement', 'notice', 'event', 'exam', 'timetable'],
      default: 'reminder',
    },
    scheduledAt: {
      type: Date,
      default: null,
    },
    status: {
      type: String,
      enum: ['draft', 'scheduled', 'sent', 'cancelled'],
      default: 'sent',
    },
    attachments: [attachmentSchema],
    isPinned: {
      type: Boolean,
      default: false,
    },
    tags: [String],
    // Tracks auto-reminder sends (24h, 2h, 30min before deadline)
    autoReminders: {
      sent24h: { type: Boolean, default: false },
      sent2h: { type: Boolean, default: false },
      sent30min: { type: Boolean, default: false },
    },
    deadlineAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
  }
);

// ─── Virtual: read count (populated separately) ───────────────────────────────
reminderSchema.virtual('readCount', {
  ref: 'ReadReceipt',
  localField: '_id',
  foreignField: 'reminderId',
  count: true,
});

// ─── Indexes ──────────────────────────────────────────────────────────────────
reminderSchema.index({ createdBy: 1, createdAt: -1 });
reminderSchema.index({ status: 1, scheduledAt: 1 });
reminderSchema.index({ priority: 1 });
reminderSchema.index({ 'targetAudience.type': 1 });
reminderSchema.index({ title: 'text', description: 'text' }); // Full-text search

const Reminder = mongoose.model('Reminder', reminderSchema);
module.exports = Reminder;
