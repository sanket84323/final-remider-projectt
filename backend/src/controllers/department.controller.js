/**
 * Department Controller
 */
const Department = require('../models/Department');
const User = require('../models/User');
const { successResponse, errorResponse } = require('../utils/apiResponse');

const getDepartments = async (req, res) => {
  try {
    const depts = await Department.find({ isActive: true });
    return successResponse(res, depts, 'Departments retrieved');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

const createDepartment = async (req, res) => {
  try {
    const dept = await Department.create(req.body);
    return successResponse(res, dept, 'Department created', 201);
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

const updateDepartment = async (req, res) => {
  try {
    const dept = await Department.findByIdAndUpdate(req.params.id, req.body, { new: true, runValidators: true });
    if (!dept) return errorResponse(res, 'Department not found', 404);
    return successResponse(res, dept, 'Department updated');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

const deleteDepartment = async (req, res) => {
  try {
    await Department.findByIdAndUpdate(req.params.id, { isActive: false });
    return successResponse(res, {}, 'Department deleted');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

// ─── Class Management Logic ───────────────────────────────────────────────

const getClasses = async (req, res) => {
  try {
    const dept = await Department.findById(req.params.id);
    if (!dept) return errorResponse(res, 'Department not found', 404);
    return successResponse(res, dept.classes, 'Classes retrieved');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

const addClass = async (req, res) => {
  try {
    const { className } = req.body;
    const dept = await Department.findById(req.params.id);
    if (!dept) return errorResponse(res, 'Department not found', 404);
    
    if (dept.classes.includes(className)) {
      return errorResponse(res, 'Class already exists', 400);
    }
    
    dept.classes.push(className);
    await dept.save();
    return successResponse(res, dept.classes, 'Class added successfully');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

const removeClass = async (req, res) => {
  try {
    const { id } = req.params; // Dept ID
    const { className, action, targetClass } = req.body; // className to remove
    
    const dept = await Department.findById(id);
    if (!dept) return errorResponse(res, 'Department not found', 404);
    
    if (!dept.classes.includes(className)) {
      return errorResponse(res, 'Class not found in this department', 404);
    }

    if (action === 'move') {
      if (!targetClass || !dept.classes.includes(targetClass)) {
        return errorResponse(res, 'Invalid target class for migration', 400);
      }
      // Move students
      await User.updateMany(
        { department: dept._id, className: className, role: 'student' },
        { className: targetClass }
      );
    } else if (action === 'delete') {
      // Delete students
      await User.deleteMany({ department: dept._id, className: className, role: 'student' });
    } else {
        return errorResponse(res, 'Invalid action (must be move or delete)', 400);
    }

    // Remove class from department list
    dept.classes = dept.classes.filter(c => c !== className);
    await dept.save();

    return successResponse(res, dept.classes, `Class removed and students ${action === 'move' ? 'migrated' : 'deleted'}`);
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

module.exports = { 
  getDepartments, createDepartment, updateDepartment, deleteDepartment,
  getClasses, addClass, removeClass 
};
