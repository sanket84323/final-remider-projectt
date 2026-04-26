/**
 * Analytics Controller (Admin)
 */

const mongoose = require('mongoose');
const User = require('../models/User');
const Reminder = require('../models/Reminder');
const Assignment = require('../models/Assignment');
const Notification = require('../models/Notification');
const ActivityLog = require('../models/ActivityLog');
const { successResponse, errorResponse } = require('../utils/apiResponse');

const getAnalytics = async (req, res) => {
  try {
    const { department } = req.user;
    const { days = 30 } = req.query;

    // Convert to ObjectId for Aggregation pipelines
    const deptId = department ? new mongoose.Types.ObjectId(department) : null;
    const filter = deptId ? { department: deptId } : {};
    const reminderFilter = deptId ? { 'targetAudience.department': deptId } : {};
    
    const since = new Date(Date.now() - parseInt(days) * 24 * 60 * 60 * 1000);

    const [totalUsers, totalReminders, totalStudents, totalTeachers, userGrowth, remindersByPriority, remindersByCategory, noticeReadRates, topActiveTeachers, activityByDay, studentActivityByClass, assignmentStatsByClass] = await Promise.all([
      User.countDocuments({ ...filter, isActive: true }),
      Reminder.countDocuments(reminderFilter),
      User.countDocuments({ ...filter, role: 'student', isActive: true }),
      User.countDocuments({ ...filter, role: 'teacher', isActive: true }),
      User.aggregate([
        { $match: { ...filter, createdAt: { $gte: since } } },
        { $group: { _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } }, count: { $sum: 1 } } },
        { $sort: { _id: 1 } },
      ]),
      Reminder.aggregate([
        { $match: reminderFilter },
        { $group: { _id: '$priority', count: { $sum: 1 } } },
      ]),
      Reminder.aggregate([
        { $match: reminderFilter },
        { $group: { _id: '$category', count: { $sum: 1 } } },
      ]),
      // For notice read rate breakdown by category
      Notification.aggregate([
        { $lookup: { from: 'reminders', localField: 'reminderId', foreignField: '_id', as: 'reminder' } },
        { $unwind: '$reminder' },
        { $lookup: { from: 'users', localField: 'userId', foreignField: '_id', as: 'user' } },
        { $unwind: '$user' },
        { $match: deptId ? { 'user.department': deptId } : {} },
        { $group: { 
            _id: '$reminder.category', 
            total: { $sum: 1 }, 
            read: { $sum: { $cond: [{ $eq: ['$readStatus', true] }, 1, 0] } } 
        }},
        { $project: { category: '$_id', total: 1, read: 1, readRate: { $cond: [{ $gt: ['$total', 0] }, { $round: [{ $multiply: [{ $divide: ['$read', '$total'] }, 100] }, 0] }, 0] } } }
      ]),
      // Improved Top Teachers (counting both reminders and assignments)
      ActivityLog.aggregate([
        { $match: { action: { $in: ['CREATE_REMINDER', 'CREATE_ASSIGNMENT'] }, createdAt: { $gte: since } } },
        { $lookup: { from: 'users', localField: 'userId', foreignField: '_id', as: 'user' } },
        { $unwind: '$user' },
        { $match: { ...filter } },
        { $group: { _id: '$userId', count: { $sum: 1 }, name: { $first: '$user.name' }, email: { $first: '$user.email' } } },
        { $sort: { count: -1 } },
        { $limit: 5 }
      ]),
      ActivityLog.aggregate([
        { $match: { createdAt: { $gte: since } } },
        { $lookup: { from: 'users', localField: 'userId', foreignField: '_id', as: 'user' } },
        { $unwind: '$user' },
        { $match: { ...filter } },
        { $group: { _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } }, count: { $sum: 1 } } },
        { $sort: { _id: 1 } },
      ]),
      ActivityLog.aggregate([
        { $match: { createdAt: { $gte: since } } },
        { $lookup: { from: 'users', localField: 'userId', foreignField: '_id', as: 'user' } },
        { $unwind: '$user' },
        { $match: { 'user.role': 'student', ...filter } },
        { $group: { _id: '$user.className', count: { $sum: 1 } } },
        { $sort: { count: -1 } },
      ]),
      Assignment.aggregate([
        { $unwind: { path: '$completedBy', preserveNullAndEmptyArrays: false } },
        { $lookup: { from: 'users', localField: 'completedBy.userId', foreignField: '_id', as: 'student' } },
        { $unwind: '$student' },
        { $match: deptId ? { 'student.department': deptId } : {} },
        { $group: {
            _id: '$student.className',
            submitted: { $sum: 1 },
            approved: { $sum: { $cond: [{ $eq: ['$completedBy.status', 'completed'] }, 1, 0] } }
        }}
      ]),
    ]);

    // Calculate GLOBAL read rate for the dashboard
    const totalNotifications = noticeReadRates.reduce((acc, curr) => acc + (curr.total || 0), 0);
    const totalRead = noticeReadRates.reduce((acc, curr) => acc + (curr.read || 0), 0);
    const globalReadRate = totalNotifications > 0 ? Math.round((totalRead / totalNotifications) * 100) : 0;

    return successResponse(res, {
      globalStats: {
        totalUsers,
        totalReminders,
        totalStudents,
        totalTeachers,
        readRate: globalReadRate,
      },
      userGrowth,
      remindersByPriority,
      remindersByCategory,
      noticeReadRates, // Keeps the category breakdown for the charts
      topTeachers: topActiveTeachers,
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
    const { department } = req.user;
    const { className } = req.params;
    const deptId = department ? new mongoose.Types.ObjectId(department) : null;

    if (!deptId) return errorResponse(res, 'Department context required', 400);

    // 1. Get all assignments targeting this class AND this department
    const assignments = await Assignment.find({
      'targetAudience.department': deptId,
      $or: [
        { 'targetAudience.type': 'all' },
        { 'targetAudience.type': 'department' },
        { 'targetAudience.type': 'class', 'targetAudience.className': className }
      ]
    }).select('title dueDate createdBy').populate('createdBy', 'name');

    // 2. Get all students in this class and department
    const students = await User.find({ role: 'student', department: deptId, className, isActive: true }).select('name email rollNumber');

    // 3. For each student, calculate their stats across these assignments
    const studentStats = await Promise.all(students.map(async (student) => {
      const studentSubmissions = await Assignment.find({
        'targetAudience.department': deptId,
        $or: [
          { 'targetAudience.type': 'all' },
          { 'targetAudience.type': 'department' },
          { 'targetAudience.type': 'class', 'targetAudience.className': className }
        ],
        'completedBy.userId': student._id
      }).select('_id');

      const studentApprovals = await Assignment.find({
        'targetAudience.department': deptId,
        $or: [
          { 'targetAudience.type': 'all' },
          { 'targetAudience.type': 'department' },
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
    const assignments = await Assignment.find({
      'targetAudience.department': student.department?._id,
      $or: [
        { 'targetAudience.type': 'all' },
        { 'targetAudience.type': 'department' },
        { 'targetAudience.type': 'class', 'targetAudience.className': student.className }
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

    const reminders = await Reminder.find({ createdBy: id }).sort({ createdAt: -1 });
    const assignments = await Assignment.find({ createdBy: id }).sort({ createdAt: -1 });

    let totalTargetedStudents = 0;
    let totalSubmissions = 0;

    const assignmentDetails = await Promise.all(assignments.map(async (a) => {
      const filter = { role: 'student', isActive: true, department: teacher.department?._id };
      if (a.targetAudience.type === 'class') filter.className = a.targetAudience.className;
      
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

const getClasses = async (req, res) => {
  try {
    const { department } = req.user;
    const deptId = department ? new mongoose.Types.ObjectId(department) : null;
    const filter = deptId ? { department: deptId, role: 'student', isActive: true } : { role: 'student', isActive: true };

    const classes = await User.aggregate([
      { $match: filter },
      { $group: { _id: '$className' } },
      { $match: { _id: { $ne: null } } },
      { $sort: { _id: 1 } },
      { $project: { name: '$_id' } }
    ]);

    return successResponse(res, classes, 'Classes retrieved');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

const getUserStats = async (req, res) => {
  try {
    const { department } = req.user;
    const deptId = department ? new mongoose.Types.ObjectId(department) : null;
    const filter = deptId ? { department: deptId, isActive: true } : { isActive: true };

    const [totalTeachers, totalStudents, classStats] = await Promise.all([
      User.countDocuments({ ...filter, role: 'teacher' }),
      User.countDocuments({ ...filter, role: 'student' }),
      User.aggregate([
        { $match: { ...filter, role: 'student' } },
        { $group: { _id: '$className', count: { $sum: 1 } } },
        { $sort: { _id: 1 } }
      ])
    ]);

    return successResponse(res, {
      totalTeachers,
      totalStudents,
      classStats: classStats.map(c => ({ className: c._id || 'Unassigned', count: c.count }))
    }, 'User statistics retrieved');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

module.exports = { getAnalytics, getClassAssignmentDetail, getStudentDetail, getTeacherDetail, getClasses, getUserStats };
