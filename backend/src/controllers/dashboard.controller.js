/**
 * Dashboard Controller - Role-specific dashboard data
 */

const User = require('../models/User');
const Reminder = require('../models/Reminder');
const Assignment = require('../models/Assignment');
const Notification = require('../models/Notification');
const ReadReceipt = require('../models/ReadReceipt');
const ActivityLog = require('../models/ActivityLog');
const { successResponse, errorResponse } = require('../utils/apiResponse');

const getStudentDashboard = async (req, res) => {
  try {
    const user = req.user;
    const now = new Date();

    const audienceFilter = {
      status: 'sent',
      $or: [
        { 'targetAudience.type': 'all' },
        { 'targetAudience.type': 'department', 'targetAudience.department': user.department },
        { 'targetAudience.type': 'class', 'targetAudience.className': user.className },
        { 'targetAudience.type': 'section', 'targetAudience.className': user.className, 'targetAudience.section': user.section },
      ],
    };

    const assignmentFilter = {
      isActive: true,
      $or: [
        { 'targetAudience.type': 'all' },
        { 'targetAudience.type': 'class', 'targetAudience.className': user.className },
      ],
    };

    const [latestRemindersRaw, upcomingAssignments, unreadCount, pinnedRemindersRaw] = await Promise.all([
      Reminder.find({ ...audienceFilter, isPinned: { $ne: true } }).populate('createdBy', 'name').sort({ createdAt: -1 }).limit(5),
      Assignment.find({ ...assignmentFilter, dueDate: { $gte: now } }).populate('createdBy', 'name').sort({ dueDate: 1 }).limit(5),
      Notification.countDocuments({ userId: user._id, readStatus: false }),
      Reminder.find({ ...audienceFilter, isPinned: true }).populate('createdBy', 'name').limit(3),
    ]);

    const attachNotifId = async (reminders) => {
      const results = await Promise.all(reminders.map(async (r) => {
        const notif = await Notification.findOne({ userId: user._id, reminderId: r._id });
        return notif ? { ...r.toObject(), notificationId: notif._id } : null;
      }));
      return results.filter(r => r !== null);
    };

    const latestReminders = await attachNotifId(latestRemindersRaw);
    const pinnedReminders = await attachNotifId(pinnedRemindersRaw);

    const pendingAssignments = await Assignment.countDocuments({
      ...assignmentFilter,
      dueDate: { $gte: now },
      'completedBy.userId': { $ne: user._id },
    });

    return successResponse(res, {
      latestReminders,
      upcomingAssignments,
      pinnedReminders,
      stats: { unreadNotifications: unreadCount, pendingAssignments },
    }, 'Student dashboard loaded');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

const getTeacherDashboard = async (req, res) => {
  try {
    const now = new Date();
    const [totalReminders, sentThisMonth, scheduledCount, recentReminders, assignments, scheduledReminders] = await Promise.all([
      Reminder.countDocuments({ createdBy: req.user._id }),
      Reminder.countDocuments({ createdBy: req.user._id, status: 'sent', createdAt: { $gte: new Date(now.getFullYear(), now.getMonth(), 1) } }),
      Reminder.countDocuments({ createdBy: req.user._id, status: 'scheduled' }),
      Reminder.find({ createdBy: req.user._id, status: 'sent' }).sort({ createdAt: -1 }).limit(5).populate('createdBy', 'name'),
      Assignment.find({ createdBy: req.user._id }).sort({ dueDate: 1 }).limit(10).populate('createdBy', 'name'),
      Reminder.find({ createdBy: req.user._id, status: 'scheduled' }).sort({ scheduledFor: 1 }).limit(5).populate('createdBy', 'name'),
    ]);

    return successResponse(res, {
      stats: { totalReminders, sentThisMonth, scheduledCount },
      recentReminders,
      scheduledReminders,
      assignments,
    }, 'Teacher dashboard loaded');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

const getAdminDashboard = async (req, res) => {
  try {
    const [totalUsers, totalStudents, totalTeachers, totalReminders, totalAssignments, recentActivity] = await Promise.all([
      User.countDocuments({ isActive: true }),
      User.countDocuments({ role: 'student', isActive: true }),
      User.countDocuments({ role: 'teacher', isActive: true }),
      Reminder.countDocuments({ status: 'sent' }),
      Assignment.countDocuments({ isActive: true }),
      ActivityLog.find().populate('userId', 'name role').sort({ createdAt: -1 }).limit(10),
    ]);

    const totalNotifications = await Notification.countDocuments();
    const readNotifications = await Notification.countDocuments({ readStatus: true });

    return successResponse(res, {
      stats: { totalUsers, totalStudents, totalTeachers, totalReminders, totalAssignments, totalNotifications },
      readRate: totalNotifications > 0 ? ((readNotifications / totalNotifications) * 100).toFixed(1) : 0,
      recentActivity,
    }, 'Admin dashboard loaded');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

module.exports = { getStudentDashboard, getTeacherDashboard, getAdminDashboard };
