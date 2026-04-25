/**
 * Analytics Controller (Admin)
 */

const User = require('../models/User');
const Reminder = require('../models/Reminder');
const Assignment = require('../models/Assignment');
const Notification = require('../models/Notification');
const ActivityLog = require('../models/ActivityLog');
const { successResponse, errorResponse } = require('../utils/apiResponse');

const getAnalytics = async (req, res) => {
  try {
    const { days = 30 } = req.query;
    const since = new Date(Date.now() - parseInt(days) * 24 * 60 * 60 * 1000);

    const [totalUsers, totalReminders, userGrowth, remindersByPriority, notificationReadRate, topActiveTeachers, activityByDay] = await Promise.all([
      User.countDocuments({ isActive: true }),
      Reminder.countDocuments(),
      User.aggregate([
        { $match: { createdAt: { $gte: since } } },
        { $group: { _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } }, count: { $sum: 1 } } },
        { $sort: { _id: 1 } },
      ]),
      Reminder.aggregate([
        { $group: { _id: '$priority', count: { $sum: 1 } } },
      ]),
      Notification.aggregate([
        { $group: { _id: '$readStatus', count: { $sum: 1 } } },
      ]),
      ActivityLog.aggregate([
        { $match: { action: 'CREATE_REMINDER', createdAt: { $gte: since } } },
        { $group: { _id: '$userId', count: { $sum: 1 } } },
        { $sort: { count: -1 } },
        { $limit: 5 },
        { $lookup: { from: 'users', localField: '_id', foreignField: '_id', as: 'user' } },
        { $unwind: '$user' },
        { $project: { name: '$user.name', email: '$user.email', count: 1 } },
      ]),
      ActivityLog.aggregate([
        { $match: { createdAt: { $gte: since } } },
        { $group: { _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } }, count: { $sum: 1 } } },
        { $sort: { _id: 1 } },
      ]),
    ]);

    return successResponse(res, {
      totalUsers,
      totalReminders,
      userGrowth,
      remindersByPriority,
      notificationReadRate,
      topActiveTeachers,
      activityByDay,
    }, 'Analytics retrieved');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

module.exports = { getAnalytics };
