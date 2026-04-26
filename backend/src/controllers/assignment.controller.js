/**
 * Assignment Controller
 */

const Assignment = require('../models/Assignment');
const User = require('../models/User');
const Notification = require('../models/Notification');
const ActivityLog = require('../models/ActivityLog');
const notificationService = require('../services/notification.service');
const { successResponse, errorResponse, paginatedResponse } = require('../utils/apiResponse');
const PDFDocument = require('pdfkit');

const createAssignment = async (req, res) => {
  try {
    const { title, description, subject, dueDate, targetAudience, maxMarks, shouldNotify = true } = req.body;
    
    const assignment = await Assignment.create({
      title, description, subject,
      dueDate: new Date(dueDate),
      targetAudience: targetAudience || { type: 'all' },
      maxMarks: maxMarks || 100,
      createdBy: req.user._id,
    });

    if (shouldNotify) {
      const userFilter = { role: 'student', isActive: true };
      if (targetAudience?.type === 'class') {
        if (targetAudience.classNames && targetAudience.classNames.length > 0) {
          userFilter.className = { $in: targetAudience.classNames };
        } else if (targetAudience.className) {
          userFilter.className = targetAudience.className;
        }
      } else if (targetAudience?.type === 'department') {
        userFilter.department = targetAudience.department;
      }

      const targetUsers = await User.find(userFilter).select('_id fcmToken').lean();
      if (targetUsers.length > 0) {
        await notificationService.notifyUsers({
          users: targetUsers,
          title: `New Assignment: ${title}`,
          body: `Due: ${new Date(dueDate).toLocaleDateString()}`,
          type: 'assignment', assignmentId: assignment._id, priority: 'important',
          data: { assignmentId: assignment._id.toString(), type: 'assignment' },
        });
      }
    }

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
        { 'targetAudience.type': 'class', 'targetAudience.classNames': user.className },
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
        if (assignment.targetAudience.classNames && assignment.targetAudience.classNames.length > 0) {
          studentFilter.className = { $in: assignment.targetAudience.classNames };
        } else {
          studentFilter.className = assignment.targetAudience.className;
        }
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
    
    // Notify the teacher who created the assignment
    try {
      const teacher = await User.findById(assignment.createdBy).select('_id fcmToken').lean();
      if (teacher) {
        await notificationService.notifyUsers({
          users: [teacher],
          title: 'New Submission',
          body: `A student has submitted: ${assignment.title}`,
          type: 'assignment_submission',
          assignmentId: assignment._id,
          priority: 'normal',
          data: { assignmentId: assignment._id.toString(), type: 'assignment_submission' },
        });
      }
    } catch (notifErr) {
      console.error('[ERROR] Failed to notify teacher of submission:', notifErr);
    }

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

    // Notify the student that their submission was approved
    try {
      const student = await User.findById(studentId).select('_id fcmToken').lean();
      if (student) {
        await notificationService.notifyUsers({
          users: [student],
          title: 'Assignment Approved! ✅',
          body: `Your submission for "${assignment.title}" has been approved.`,
          type: 'assignment_approval',
          assignmentId: assignment._id,
          priority: 'important',
          data: { assignmentId: assignment._id.toString(), type: 'assignment_approval' },
        });
      }
    } catch (notifErr) {
      console.error('[ERROR] Failed to notify student of approval:', notifErr);
    }

    return successResponse(res, {}, 'Submission approved/completed');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

const generateAssignmentReport = async (req, res) => {
  try {
    const assignment = await Assignment.findById(req.params.id)
      .populate('createdBy', 'name email')
      .populate('completedBy.userId', 'name email className rollNumber');
    
    if (!assignment) return res.status(404).send('Assignment not found');

    const doc = new PDFDocument({ margin: 0, size: 'A4' });
    let filename = `${assignment.title.replace(/\s+/g, '_')}.pdf`;
    
    res.setHeader('Content-disposition', `attachment; filename="${filename}"`);
    res.setHeader('Content-type', 'application/pdf');

    doc.pipe(res);

    // ─── Professional Header ──────────────────────────────────────────────────
    doc.rect(0, 0, 612, 120).fill('#1565C0');
    doc.fillColor('#FFFFFF').fontSize(22).font('Helvetica-Bold').text(assignment.title.toUpperCase(), 50, 45);
    doc.fontSize(10).font('Helvetica').text('CAMPUSSYNC ACADEMIC REPORT', 50, 75);
    doc.fontSize(8).text(`GENERATED ON: ${new Date().toLocaleString()}`, 400, 45, { align: 'right', width: 160 });

    // ─── Assignment Overview Card ─────────────────────────────────────────────
    doc.fillColor('#1A1A2E').fontSize(18).font('Helvetica-Bold').text('Assignment Activity Report', 50, 150);
    
    doc.rect(50, 180, 512, 70).stroke('#E0E6F0');
    doc.fontSize(10).fillColor('#5A6070').font('Helvetica-Bold').text('TITLE:', 70, 195);
    doc.fillColor('#1A1A2E').font('Helvetica').text(assignment.title, 115, 195);
    
    doc.fillColor('#5A6070').font('Helvetica-Bold').text('SUBJECT:', 70, 220);
    doc.fillColor('#1A1A2E').font('Helvetica').text(assignment.subject || 'N/A', 130, 220);
    
    doc.fillColor('#5A6070').font('Helvetica-Bold').text('DUE DATE:', 320, 195);
    doc.fillColor('#1A1A2E').font('Helvetica').text(new Date(assignment.dueDate).toLocaleDateString(), 385, 195);
    
    doc.fillColor('#5A6070').font('Helvetica-Bold').text('TEACHER:', 320, 220);
    doc.fillColor('#1A1A2E').font('Helvetica').text(assignment.createdBy?.name || 'N/A', 380, 220);

    // ─── Stats Summary Boxes ──────────────────────────────────────────────────
    const studentFilter = { role: 'student', isActive: true };
    if (assignment.targetAudience.type === 'class') {
      studentFilter.className = assignment.targetAudience.className;
    } else if (assignment.targetAudience.type === 'department') {
      studentFilter.department = assignment.targetAudience.department;
    }
    const allStudents = await User.find(studentFilter).select('_id name email className rollNumber').lean();
    
    const approvedCount = assignment.completedBy.filter(c => c.status === 'completed').length;
    const pendingCount = assignment.completedBy.filter(c => c.status === 'pending').length;

    const drawStatBox = (x, label, value, color) => {
      doc.rect(x, 270, 120, 50).fill(color);
      doc.fillColor('#FFFFFF').fontSize(14).font('Helvetica-Bold').text(value, x, 280, { width: 120, align: 'center' });
      doc.fontSize(7).text(label, x, 300, { width: 120, align: 'center' });
    };

    drawStatBox(50, 'TOTAL TARGETED', `${allStudents.length}`, '#1565C0');
    drawStatBox(180, 'APPROVED', `${approvedCount}`, '#2E7D32');
    drawStatBox(310, 'PENDING', `${pendingCount}`, '#FF8F00');
    drawStatBox(440, 'NOT SUBMITTED', `${allStudents.length - (approvedCount + pendingCount)}`, '#C62828');

    // ─── Submission Table ─────────────────────────────────────────────────────
    doc.fillColor('#1A1A2E').fontSize(14).font('Helvetica-Bold').text('Detailed Student Status', 50, 350);
    
    const tableTop = 375;
    const colX = [50, 220, 300, 370, 470];
    const colLabels = ['Student Name', 'Roll No', 'Class', 'Status', 'Date'];

    // Header Background
    doc.rect(50, tableTop, 512, 25).fill('#F0F4F8');
    doc.fillColor('#1A1A2E').fontSize(9).font('Helvetica-Bold');
    
    for(let i=0; i<colLabels.length; i++) {
      doc.text(colLabels[i], colX[i], tableTop + 8);
    }

    let y = tableTop + 25;
    doc.font('Helvetica').fontSize(8);

    for (let i = 0; i < allStudents.length; i++) {
      const student = allStudents[i];
      const completion = assignment.completedBy.find(c => 
        (c.userId?._id || c.userId)?.toString() === student._id.toString()
      );
      
      // Row Background
      if (i % 2 === 0) {
        doc.rect(50, y, 512, 20).fill('#F8F9FE');
      }

      let statusText = 'Not Submitted';
      let dateText = '-';
      let statusColor = '#C62828';

      if (completion) {
        if (completion.status === 'completed') {
          statusText = 'Approved';
          statusColor = '#2E7D32';
        } else {
          statusText = 'Pending Approval';
          statusColor = '#FF8F00';
        }
        dateText = new Date(completion.completedAt).toLocaleDateString();
      }

      if (y > 750) {
        doc.addPage({ margin: 50 });
        y = 50;
      }

      doc.fillColor('#1A1A2E').text(student.name || 'N/A', colX[0] + 5, y + 6);
      doc.text(student.rollNumber || '-', colX[1], y + 6);
      doc.text(student.className || '-', colX[2], y + 6);
      doc.fillColor(statusColor).font('Helvetica-Bold').text(statusText, colX[3], y + 6);
      doc.fillColor('#5A6070').font('Helvetica').text(dateText, colX[4], y + 6);
      
      y += 20;
    }

    // Footer
    const pages = doc.bufferedPageRange();
    for (let i = 0; i < pages.count; i++) {
      doc.switchToPage(i);
      doc.fillColor('#9EA8B8').fontSize(8).text(
        `Page ${i + 1} of ${pages.count} - CampusSync Academic Report`,
        50, 800, { align: 'center', width: 512 }
      );
    }

    doc.end();
  } catch (error) {
    console.error('PDF Export Error:', error);
    res.status(500).send('Internal Server Error');
  }
};

module.exports = { createAssignment, getAssignments, getAssignmentById, markComplete, markStudentComplete, updateAssignment, deleteAssignment, generateAssignmentReport };
