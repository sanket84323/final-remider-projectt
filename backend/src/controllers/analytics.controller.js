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

    const [totalUsers, totalReminders, userGrowth, remindersByPriority, remindersByCategory, notificationReadRate, topActiveTeachers, activityByDay, studentActivityByClass, assignmentStatsByClass] = await Promise.all([
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
      Reminder.aggregate([
        { $group: { _id: '$category', count: { $sum: 1 } } },
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
      ActivityLog.aggregate([
        { $match: { createdAt: { $gte: since } } },
        { $lookup: { from: 'users', localField: 'userId', foreignField: '_id', as: 'user' } },
        { $unwind: '$user' },
        { $match: { 'user.role': 'student' } },
        { $group: { _id: '$user.className', count: { $sum: 1 } } },
        { $sort: { count: -1 } },
      ]),
      Assignment.aggregate([
        { $unwind: { path: '$completedBy', preserveNullAndEmptyArrays: false } },
        { $lookup: { from: 'users', localField: 'completedBy.userId', foreignField: '_id', as: 'student' } },
        { $unwind: '$student' },
        { $group: {
            _id: '$student.className',
            submitted: { $sum: 1 },
            approved: { $sum: { $cond: [{ $eq: ['$completedBy.status', 'completed'] }, 1, 0] } }
        }}
      ]),
    ]);

    return successResponse(res, {
      totalUsers,
      totalReminders,
      userGrowth,
      remindersByPriority,
      remindersByCategory,
      notificationReadRate,
      topActiveTeachers,
      activityByDay,
      studentActivityByClass,
      assignmentStatsByClass,
    }, 'Analytics retrieved');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

const getClassAssignmentDetail = async (req, res) => {
  try {
    const { className } = req.params;

    // 1. Get all assignments targeting this class
    const assignments = await Assignment.find({
      $or: [
        { 'targetAudience.type': 'all' },
        { 'targetAudience.type': 'class', 'targetAudience.className': className }
      ]
    }).select('title dueDate createdBy').populate('createdBy', 'name');

    // 2. Get all students in this class
    const students = await User.find({ role: 'student', className, isActive: true }).select('name email rollNumber');

    // 3. For each student, calculate their stats across these assignments
    const studentStats = await Promise.all(students.map(async (student) => {
      const studentSubmissions = await Assignment.find({
        $or: [
          { 'targetAudience.type': 'all' },
          { 'targetAudience.type': 'class', 'targetAudience.className': className }
        ],
        'completedBy.userId': student._id
      }).select('_id');

      const studentApprovals = await Assignment.find({
        $or: [
          { 'targetAudience.type': 'all' },
          { 'targetAudience.type': 'class', 'targetAudience.className': className }
        ],
        completedBy: {
          $elemMatch: { userId: student._id, status: 'completed' }
        }
      }).select('_id');

      return {
        id: student._id,
        name: student.name,
        email: student.email,
        rollNumber: student.rollNumber,
        submittedIds: studentSubmissions.map(s => s._id.toString()),
        approvedIds: studentApprovals.map(s => s._id.toString()),
        submitted: studentSubmissions.length,
        approved: studentApprovals.length,
        total: assignments.length
      };
    }));

    return successResponse(res, {
      className,
      totalAssignments: assignments.length,
      assignments,
      students: studentStats,
    }, 'Class assignment details retrieved');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

const getStudentDetail = async (req, res) => {
  try {
    const { id } = req.params;
    const student = await User.findById(id).populate('department', 'name code');
    if (!student) return errorResponse(res, 'Student not found', 404);

    // 1. Notifications/Reminders Read Rate
    const totalNotifications = await Notification.countDocuments({ userId: id });
    const readNotifications = await Notification.countDocuments({ userId: id, readStatus: true });

    // 2. Assignments
    // Get all assignments for this student's class
    const assignments = await Assignment.find({
      $or: [
        { 'targetAudience.type': 'all' },
        { 'targetAudience.type': 'class', 'targetAudience.className': student.className },
        { 'targetAudience.type': 'department', 'targetAudience.departmentId': student.department?._id }
      ]
    }).populate('createdBy', 'name').sort({ dueDate: 1 });

    const assignmentList = assignments.map(a => {
      const submission = a.completedBy.find(c => c.userId.toString() === id);
      return {
        _id: a._id,
        title: a.title,
        dueDate: a.dueDate,
        teacher: a.createdBy?.name,
        status: submission ? (submission.status === 'completed' ? 'approved' : 'submitted') : 'pending'
      };
    });

    const stats = {
      submitted: assignmentList.filter(a => a.status !== 'pending').length,
      approved: assignmentList.filter(a => a.status === 'approved').length,
      pending: assignmentList.filter(a => a.status === 'pending').length,
      totalAssignments: assignmentList.length,
      totalNotifications,
      readNotifications,
      readRate: totalNotifications > 0 ? Math.round((readNotifications / totalNotifications) * 100) : 0
    };

    return successResponse(res, { student, stats, assignments: assignmentList }, 'Student details retrieved');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

const getTeacherDetail = async (req, res) => {
  try {
    const { id } = req.params;
    const teacher = await User.findById(id).populate('department', 'name code');
    if (!teacher) return errorResponse(res, 'Teacher not found', 404);

    // 1. Reminders sent by this teacher
    const reminders = await Reminder.find({ createdBy: id }).sort({ createdAt: -1 });

    // 2. Assignments posted by this teacher
    const assignments = await Assignment.find({ createdBy: id }).sort({ createdAt: -1 });

    // 3. Overall Student Impact
    // For all assignments this teacher posted, how many students were targeted and how many submitted?
    let totalTargetedStudents = 0;
    let totalSubmissions = 0;

    const assignmentDetails = await Promise.all(assignments.map(async (a) => {
      // Find students targeted by this assignment
      const filter = { role: 'student', isActive: true };
      if (a.targetAudience.type === 'class') filter.className = a.targetAudience.className;
      if (a.targetAudience.type === 'department') filter.department = a.targetAudience.departmentId;
      
      const targetedCount = await User.countDocuments(filter);
      const submissionCount = a.completedBy.length;
      
      totalTargetedStudents += targetedCount;
      totalSubmissions += submissionCount;

      return {
        _id: a._id,
        title: a.title,
        dueDate: a.dueDate,
        targeted: targetedCount,
        submitted: submissionCount,
        rate: targetedCount > 0 ? Math.round((submissionCount / targetedCount) * 100) : 0
      };
    }));

    const stats = {
      totalReminders: reminders.length,
      totalAssignments: assignments.length,
      totalTargetedStudents,
      totalSubmissions,
      overallSubmissionRate: totalTargetedStudents > 0 ? Math.round((totalSubmissions / totalTargetedStudents) * 100) : 0
    };

    return successResponse(res, { 
      teacher, 
      stats, 
      reminders: reminders.map(r => ({ _id: r._id, title: r.title, priority: r.priority, createdAt: r.createdAt })),
      assignments: assignmentDetails 
    }, 'Teacher details retrieved');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

module.exports = { getAnalytics, getClassAssignmentDetail, getStudentDetail, getTeacherDetail };
