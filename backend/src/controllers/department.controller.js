/**
 * Department Controller
 */

const Department = require('../models/Department');
const { successResponse, errorResponse } = require('../utils/apiResponse');

const getDepartments = async (req, res) => {
  try {
    const departments = await Department.find({ isActive: true }).populate('hodId', 'name email').sort({ name: 1 });
    return successResponse(res, departments, 'Departments retrieved');
  } catch (error) { return errorResponse(res, error.message, 500); }
};

const createDepartment = async (req, res) => {
  try {
    const dept = await Department.create(req.body);
    return successResponse(res, dept, 'Department created', 201);
  } catch (error) { return errorResponse(res, error.message, 500); }
};

const updateDepartment = async (req, res) => {
  try {
    const dept = await Department.findByIdAndUpdate(req.params.id, req.body, { new: true, runValidators: true });
    if (!dept) return errorResponse(res, 'Department not found', 404);
    return successResponse(res, dept, 'Department updated');
  } catch (error) { return errorResponse(res, error.message, 500); }
};

const deleteDepartment = async (req, res) => {
  try {
    await Department.findByIdAndUpdate(req.params.id, { isActive: false });
    return successResponse(res, {}, 'Department deleted');
  } catch (error) { return errorResponse(res, error.message, 500); }
};

module.exports = { getDepartments, createDepartment, updateDepartment, deleteDepartment };
