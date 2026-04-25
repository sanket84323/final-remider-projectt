/**
 * Reminder Controller
 */

const Reminder = require('../models/Reminder');
const User = require('../models/User');
const Notification = require('../models/Notification');
const ReadReceipt = require('../models/ReadReceipt');
const ActivityLog = require('../models/ActivityLog');
const notificationService = require('../services/notification.service');
const { successResponse, errorResponse, paginatedResponse } = require('../utils/apiResponse');

// ─── Helper: Build audience filter for finding target users ──────────────────
const buildAudienceUserFilter = async (targetAudience) => {
  const filter = { role: 'student', isActive: true };
  if (!targetAudience || targetAudience.type === 'all') return filter;

  if (targetAudience.type === 'department' && targetAudience.department) {
    filter.department = targetAudience.department;
  } else if (targetAudience.type === 'class' && targetAudience.className) {
    filter.className = targetAudience.className;
    if (targetAudience.section) filter.section = targetAudience.section;
  } else if (targetAudience.type === 'section') {
    if (targetAudience.className) filter.className = targetAudience.className;
    if (targetAudience.section) filter.section = targetAudience.section;
  }
  return filter;
};

// ─── Create Reminder ──────────────────────────────────────────────────────────
const createReminder = async (req, res) => {
  try {
    const { title, description, priority, category, targetAudience, scheduledAt, deadlineAt, tags, isPinned } = req.body;

    const isScheduled = scheduledAt && new Date(scheduledAt) > new Date();
    const reminder = await Reminder.create({
      title,
      description,
      priority: priority || 'normal',
      category: category || 'reminder',
      targetAudience: targetAudience || { type: 'all' },
      scheduledAt: scheduledAt ? new Date(scheduledAt) : null,
      deadlineAt: deadlineAt ? new Date(deadlineAt) : null,
      status: isScheduled ? 'scheduled' : 'sent',
      tags: tags || [],
      isPinned: isPinned || false,
      createdBy: req.user._id,
    });

    // If not scheduled, notify target users immediately
    if (!isScheduled) {
      const audienceFilter = await buildAudienceUserFilter(reminder.targetAudience);
      const targetUsers = await User.find(audienceFilter).select('_id fcmToken').lean();

      await notificationService.notifyUsers({
        users: targetUsers,
        title,
        body: description.substring(0, 150),
        type: 'reminder',
        reminderId: reminder._id,
        priority,
        data: { reminderId: reminder._id.toString(), type: 'reminder' },
      });
    }

    await ActivityLog.create({ userId: req.user._id, action: 'CREATE_REMINDER', metadata: { reminderId: reminder._id } });
    await reminder.populate('createdBy', 'name email avatarUrl');

    return successResponse(res, reminder, 'Reminder created', 201);
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

// ─── Get Reminders (Student/Teacher filtered) ─────────────────────────────────
const getReminders = async (req, res) => {
  try {
    const { page = 1, limit = 20, priority, category, search, status } = req.query;
    const user = req.user;
    const filter = { status: { $ne: 'cancelled' } };

    // Students only see sent reminders relevant to them
    if (user.role === 'student') {
      filter.status = 'sent';
      filter.$or = [
        { 'targetAudience.type': 'all' },
        { 'targetAudience.type': 'department', 'targetAudience.department': user.department },
        { 'targetAudience.type': 'class', 'targetAudience.className': user.className },
        { 'targetAudience.type': 'section', 'targetAudience.className': user.className, 'targetAudience.section': user.section },
      ];
    }

    // Teachers see their own reminders
    if (user.role === 'teacher') {
      filter.createdBy = user._id;
      if (status) filter.status = status;
    }

    if (priority) filter.priority = priority;
    if (category) filter.category = category;
    if (search) filter.$text = { $search: search };

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const [reminders, total] = await Promise.all([
      Reminder.find(filter)
        .populate('createdBy', 'name email avatarUrl')
        .populate('targetAudience.department', 'name')
        .sort({ isPinned: -1, createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit)),
      Reminder.countDocuments(filter),
    ]);

    return paginatedResponse(res, reminders, total, page, limit);
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

// ─── Get Single Reminder ──────────────────────────────────────────────────────
const getReminderById = async (req, res) => {
  try {
    const reminder = await Reminder.findById(req.params.id)
      .populate('createdBy', 'name email avatarUrl');

    if (!reminder) return errorResponse(res, 'Reminder not found', 404);

    // If student opens reminder, record read receipt
    if (req.user.role === 'student') {
      await ReadReceipt.findOneAndUpdate(
        { reminderId: reminder._id, userId: req.user._id },
        { readAt: new Date() },
        { upsert: true }
      );
      // Mark notification as read
      await Notification.updateMany(
        { userId: req.user._id, reminderId: reminder._id, readStatus: false },
        { readStatus: true, readAt: new Date() }
      );
    }

    const readCount = await ReadReceipt.countDocuments({ reminderId: reminder._id });
    return successResponse(res, { ...reminder.toObject(), readCount }, 'Reminder retrieved');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

// ─── Update Reminder ──────────────────────────────────────────────────────────
const updateReminder = async (req, res) => {
  try {
    const reminder = await Reminder.findOne({ _id: req.params.id, createdBy: req.user._id });
    if (!reminder) return errorResponse(res, 'Reminder not found or unauthorized', 404);

    const allowed = ['title', 'description', 'priority', 'category', 'targetAudience', 'scheduledAt', 'deadlineAt', 'tags', 'isPinned', 'status'];
    allowed.forEach((key) => {
      if (req.body[key] !== undefined) reminder[key] = req.body[key];
    });

    await reminder.save();
    await ActivityLog.create({ userId: req.user._id, action: 'EDIT_REMINDER', metadata: { reminderId: reminder._id } });
    return successResponse(res, reminder, 'Reminder updated');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

// ─── Delete Reminder ──────────────────────────────────────────────────────────
const deleteReminder = async (req, res) => {
  try {
    const filter = req.user.role === 'admin'
      ? { _id: req.params.id }
      : { _id: req.params.id, createdBy: req.user._id };

    const reminder = await Reminder.findOneAndDelete(filter);
    if (!reminder) return errorResponse(res, 'Reminder not found or unauthorized', 404);

    await ReadReceipt.deleteMany({ reminderId: reminder._id });
    await ActivityLog.create({ userId: req.user._id, action: 'DELETE_REMINDER', metadata: { reminderId: req.params.id } });
    return successResponse(res, {}, 'Reminder deleted');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

// ─── Get Read Receipts for a Reminder (Teacher) ───────────────────────────────
const getReadReceipts = async (req, res) => {
  try {
    const reminder = await Reminder.findOne({ _id: req.params.id, createdBy: req.user._id });
    if (!reminder && req.user.role !== 'admin') return errorResponse(res, 'Reminder not found', 404);

    const receipts = await ReadReceipt.find({ reminderId: req.params.id })
      .populate('userId', 'name email className section avatarUrl')
      .sort({ readAt: -1 });

    const totalTargeted = await User.countDocuments(
      await buildAudienceUserFilter(reminder?.targetAudience)
    );

    return successResponse(res, {
      receipts,
      readCount: receipts.length,
      totalTargeted,
      readRate: totalTargeted > 0 ? ((receipts.length / totalTargeted) * 100).toFixed(1) : 0,
    }, 'Read receipts retrieved');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

module.exports = { createReminder, getReminders, getReminderById, updateReminder, deleteReminder, getReadReceipts };
