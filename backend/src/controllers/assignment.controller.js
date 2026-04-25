/**
 * Assignment Controller
 */

const Assignment = require('../models/Assignment');
const User = require('../models/User');
const Notification = require('../models/Notification');
const ActivityLog = require('../models/ActivityLog');
const notificationService = require('../services/notification.service');
const { successResponse, errorResponse, paginatedResponse } = require('../utils/apiResponse');

const createAssignment = async (req, res) => {
  try {
    const { title, description, subject, dueDate, targetAudience, maxMarks } = req.body;
    const assignment = await Assignment.create({
      title, description, subject,
      dueDate: new Date(dueDate),
      targetAudience: targetAudience || { type: 'all' },
      maxMarks: maxMarks || 100,
      createdBy: req.user._id,
    });
    const userFilter = { role: 'student', isActive: true };
    if (targetAudience?.className) userFilter.className = targetAudience.className;
    const targetUsers = await User.find(userFilter).select('_id fcmToken').lean();
    await notificationService.notifyUsers({
      users: targetUsers,
      title: `New Assignment: ${title}`,
      body: `Due: ${new Date(dueDate).toLocaleDateString()}`,
      type: 'assignment', assignmentId: assignment._id, priority: 'important',
      data: { assignmentId: assignment._id.toString(), type: 'assignment' },
    });
    await ActivityLog.create({ userId: req.user._id, action: 'CREATE_ASSIGNMENT', metadata: { assignmentId: assignment._id } });
    await assignment.populate('createdBy', 'name email');
    return successResponse(res, assignment, 'Assignment created', 201);
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

const getAssignments = async (req, res) => {
  try {
    const { page = 1, limit = 20 } = req.query;
    const user = req.user;
    const filter = { isActive: true };
    if (user.role === 'student') {
      filter.$or = [
        { 'targetAudience.type': 'all' },
        { 'targetAudience.type': 'class', 'targetAudience.className': user.className },
        { 'targetAudience.type': 'department', 'targetAudience.department': user.department },
      ];
    } else if (user.role === 'teacher') {
      filter.createdBy = user._id;
    }
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const [assignments, total] = await Promise.all([
      Assignment.find(filter).populate('createdBy', 'name email avatarUrl').sort({ dueDate: 1 }).skip(skip).limit(parseInt(limit)),
      Assignment.countDocuments(filter),
    ]);
    let enriched = assignments;
    if (user.role === 'student') {
      enriched = assignments.map((a) => {
        const aObj = a.toObject();
        const completion = a.completedBy.find((c) => c.userId?.toString() === user._id.toString());
        aObj.isCompleted = completion?.status === 'completed';
        aObj.isPending = completion?.status === 'pending';
        return aObj;
      });
    }
    return paginatedResponse(res, enriched, total, page, limit);
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

const getAssignmentById = async (req, res) => {
  try {
    const assignment = await Assignment.findById(req.params.id)
      .populate('createdBy', 'name email avatarUrl')
      .populate('completedBy.userId', 'name email className rollNumber');
    if (!assignment) return errorResponse(res, 'Assignment not found', 404);

    // If student views, mark notification as read
    if (req.user.role === 'student') {
      await Notification.updateMany(
        { userId: req.user._id, assignmentId: assignment._id, readStatus: false },
        { readStatus: true, readAt: new Date() }
      );
    }

    let responseData = assignment.toObject();

    // Calculate status for student
    if (req.user.role === 'student') {
      const completion = assignment.completedBy.find((c) => 
        (c.userId?._id || c.userId)?.toString() === req.user._id.toString()
      );
      responseData.isCompleted = completion?.status === 'completed';
      responseData.isPending = completion?.status === 'pending';
    }

    // If teacher views, also return the list of targeted students who HAVEN'T completed it
    if (req.user.role === 'teacher' || req.user.role === 'admin') {
      const studentFilter = { role: 'student', isActive: true };
      if (assignment.targetAudience.type === 'class') {
        studentFilter.className = assignment.targetAudience.className;
      } else if (assignment.targetAudience.type === 'department') {
        studentFilter.department = assignment.targetAudience.department;
      }
      
      const allStudents = await User.find(studentFilter).select('_id name email className rollNumber').lean();
      responseData.allTargetedStudents = allStudents;
    }

    return successResponse(res, responseData, 'Assignment retrieved');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

const markComplete = async (req, res) => {
  try {
    const { id } = req.params;
    console.log('[DEBUG] markComplete called for assignment:', id, 'by user:', req.user._id);

    const assignment = await Assignment.findById(id);
    if (!assignment) {
      console.log('[DEBUG] Assignment not found:', id);
      return errorResponse(res, 'Assignment not found', 404);
    }
    
    const existing = assignment.completedBy.find((c) => c.userId?.toString() === req.user._id.toString());
    
    if (existing) {
      console.log('[DEBUG] Student already submitted, status:', existing.status);
      return successResponse(res, {}, 'Already marked as completed');
    }
    
    assignment.completedBy.push({ 
      userId: req.user._id, 
      note: req.body.note,
      status: 'pending'
    });
    
    await assignment.save();
    console.log('[DEBUG] Student submission saved successfully');
    await ActivityLog.create({ userId: req.user._id, action: 'COMPLETE_ASSIGNMENT', metadata: { assignmentId: assignment._id } });
    
    return successResponse(res, {}, 'Marked as completed');
  } catch (error) {
    console.error('[ERROR] markComplete:', error);
    return errorResponse(res, error.message, 500);
  }
};

const updateAssignment = async (req, res) => {
  try {
    const assignment = await Assignment.findOne({ _id: req.params.id, createdBy: req.user._id });
    if (!assignment) return errorResponse(res, 'Not found or unauthorized', 404);
    ['title', 'description', 'subject', 'dueDate', 'maxMarks', 'targetAudience'].forEach((key) => {
      if (req.body[key] !== undefined) assignment[key] = req.body[key];
    });
    await assignment.save();
    return successResponse(res, assignment, 'Assignment updated');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

const deleteAssignment = async (req, res) => {
  try {
    const filter = req.user.role === 'admin' ? { _id: req.params.id } : { _id: req.params.id, createdBy: req.user._id };
    const assignment = await Assignment.findOneAndDelete(filter);
    if (!assignment) return errorResponse(res, 'Not found or unauthorized', 404);
    await ActivityLog.create({ userId: req.user._id, action: 'DELETE_ASSIGNMENT', metadata: { assignmentId: req.params.id } });
    return successResponse(res, {}, 'Assignment deleted');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

const markStudentComplete = async (req, res) => {
  try {
    const { assignmentId, studentId } = req.body;
    console.log('[DEBUG] markStudentComplete called:', { assignmentId, studentId });

    if (!assignmentId || !studentId) {
      return errorResponse(res, 'Missing assignmentId or studentId', 400);
    }
    const mongoose = require('mongoose');
    if (!mongoose.Types.ObjectId.isValid(assignmentId) || !mongoose.Types.ObjectId.isValid(studentId)) {
      return errorResponse(res, 'Invalid assignment or student ID format', 400);
    }

    const assignment = await Assignment.findById(assignmentId);
    if (!assignment) return errorResponse(res, 'Assignment not found', 404);

    const completionIndex = assignment.completedBy.findIndex((c) => c.userId?.toString() === studentId);
    
    if (completionIndex !== -1) {
      // If already exists (likely pending), set to completed
      assignment.completedBy[completionIndex].status = 'completed';
      assignment.completedBy[completionIndex].completedAt = new Date();
    } else {
      // Teacher manually marking them as done
      assignment.completedBy.push({ 
        userId: studentId, 
        note: 'Marked/Approved by teacher',
        status: 'completed'
      });
    }
    
    await assignment.save();
    return successResponse(res, {}, 'Submission approved/completed');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

module.exports = { createAssignment, getAssignments, getAssignmentById, markComplete, markStudentComplete, updateAssignment, deleteAssignment };
