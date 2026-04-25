/**
 * Class Controller
 */

const Class = require('../models/Class');
const { successResponse, errorResponse } = require('../utils/apiResponse');

const getClasses = async (req, res) => {
  try {
    const { department } = req.query;
    const filter = { isActive: true };
    if (department) filter.department = department;
    const classes = await Class.find(filter)
      .populate('department', 'name code')
      .populate('teacherIds', 'name email')
      .sort({ name: 1 });
    return successResponse(res, classes, 'Classes retrieved');
  } catch (error) { return errorResponse(res, error.message, 500); }
};

const createClass = async (req, res) => {
  try {
    const cls = await Class.create(req.body);
    return successResponse(res, cls, 'Class created', 201);
  } catch (error) { return errorResponse(res, error.message, 500); }
};

const updateClass = async (req, res) => {
  try {
    const cls = await Class.findByIdAndUpdate(req.params.id, req.body, { new: true, runValidators: true });
    if (!cls) return errorResponse(res, 'Class not found', 404);
    return successResponse(res, cls, 'Class updated');
  } catch (error) { return errorResponse(res, error.message, 500); }
};

const deleteClass = async (req, res) => {
  try {
    await Class.findByIdAndUpdate(req.params.id, { isActive: false });
    return successResponse(res, {}, 'Class deleted');
  } catch (error) { return errorResponse(res, error.message, 500); }
};

module.exports = { getClasses, createClass, updateClass, deleteClass };
