/**
 * Notification Controller
 */

const Notification = require('../models/Notification');
const { successResponse, errorResponse, paginatedResponse } = require('../utils/apiResponse');

const getNotifications = async (req, res) => {
  try {
    const { page = 1, limit = 30, unreadOnly } = req.query;
    const filter = { userId: req.user._id };
    if (unreadOnly === 'true') filter.readStatus = false;
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const [notifications, total, unreadCount] = await Promise.all([
      Notification.find(filter)
        .populate('reminderId', 'title priority category')
        .populate('assignmentId', 'title dueDate')
        .sort({ deliveredAt: -1 })
        .skip(skip)
        .limit(parseInt(limit)),
      Notification.countDocuments(filter),
      Notification.countDocuments({ userId: req.user._id, readStatus: false }),
    ]);
    return res.status(200).json({
      success: true,
      data: { notifications, unreadCount },
      pagination: { total, page: parseInt(page), limit: parseInt(limit), totalPages: Math.ceil(total / limit) },
    });
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

const markAsRead = async (req, res) => {
  try {
    const notif = await Notification.findOneAndUpdate(
      { _id: req.params.id, userId: req.user._id },
      { readStatus: true, readAt: new Date() },
      { new: true }
    );
    if (!notif) return errorResponse(res, 'Notification not found', 404);
    return successResponse(res, notif, 'Marked as read');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

const markAllAsRead = async (req, res) => {
  try {
    await Notification.updateMany(
      { userId: req.user._id, readStatus: false },
      { readStatus: true, readAt: new Date() }
    );
    return successResponse(res, {}, 'All notifications marked as read');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

const deleteNotification = async (req, res) => {
  try {
    await Notification.findOneAndDelete({ _id: req.params.id, userId: req.user._id });
    return successResponse(res, {}, 'Notification deleted');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

module.exports = { getNotifications, markAsRead, markAllAsRead, deleteNotification };
