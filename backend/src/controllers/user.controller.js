/**
 * User Controller
 * Handles user CRUD — mostly admin operations
 */

const User = require('../models/User');
const ActivityLog = require('../models/ActivityLog');
const { successResponse, errorResponse, paginatedResponse } = require('../utils/apiResponse');

// ─── Get Current User Profile ─────────────────────────────────────────────────
const getMe = async (req, res) => {
  try {
    const user = await User.findById(req.user._id).populate('department', 'name code');
    return successResponse(res, user, 'Profile retrieved');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

// ─── Update FCM Token ─────────────────────────────────────────────────────────
const updateFcmToken = async (req, res) => {
  try {
    const { fcmToken } = req.body;
    await User.findByIdAndUpdate(req.user._id, { fcmToken });
    return successResponse(res, {}, 'FCM token updated');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

// ─── Get All Users (Admin) ────────────────────────────────────────────────────
const getAllUsers = async (req, res) => {
  try {
    const { role, department, className, page = 1, limit = 20, search } = req.query;
    const filter = { isActive: true };
    if (role) filter.role = role;
    if (department) filter.department = department;
    if (className) filter.className = className;
    if (search) {
      filter.$or = [
        { name: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } },
      ];
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const [users, total] = await Promise.all([
      User.find(filter).populate('department', 'name code').skip(skip).limit(parseInt(limit)).sort({ createdAt: -1 }),
      User.countDocuments(filter),
    ]);

    return paginatedResponse(res, users, total, page, limit);
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

// ─── Create User (Admin) ──────────────────────────────────────────────────────
const createUser = async (req, res) => {
  try {
    const { name, email, password, role, department, className, section, rollNumber } = req.body;

    const existing = await User.findOne({ email });
    if (existing) return errorResponse(res, 'Email already registered', 409);

    const user = await User.create({
      name,
      email,
      passwordHash: password, // Pre-save hook hashes this
      role,
      department,
      className,
      section,
      rollNumber,
    });

    await ActivityLog.create({
      userId: req.user._id,
      action: 'CREATE_USER',
      metadata: { createdUserId: user._id, role },
    });

    const { passwordHash: _, ...userObj } = user.toObject();
    return successResponse(res, userObj, 'User created successfully', 201);
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

// ─── Update User ──────────────────────────────────────────────────────────────
const updateUser = async (req, res) => {
  try {
    const { id } = req.params;
    const allowedFields = ['name', 'department', 'className', 'section', 'rollNumber', 'profileImage', 'isActive'];
    
    // Only admin can change roles
    if (req.user.role === 'admin') allowedFields.push('role');

    const updates = {};
    allowedFields.forEach((field) => {
      if (req.body[field] !== undefined) updates[field] = req.body[field];
    });

    const user = await User.findByIdAndUpdate(id, updates, { new: true, runValidators: true })
      .populate('department', 'name code');

    if (!user) return errorResponse(res, 'User not found', 404);
    return successResponse(res, user, 'User updated');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

// ─── Delete User (Admin) ──────────────────────────────────────────────────────
const deleteUser = async (req, res) => {
  try {
    const { id } = req.params;
    if (id === req.user._id.toString()) {
      return errorResponse(res, 'Cannot delete your own account', 400);
    }

    const user = await User.findByIdAndUpdate(id, { isActive: false }, { new: true });
    if (!user) return errorResponse(res, 'User not found', 404);

    await ActivityLog.create({
      userId: req.user._id,
      action: 'DELETE_USER',
      metadata: { deletedUserId: id },
    });

    return successResponse(res, {}, 'User deactivated');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

// ─── Get Students by Class (Teacher) ─────────────────────────────────────────
const getStudentsByClass = async (req, res) => {
  try {
    const { className, section, department } = req.query;
    const filter = { role: 'student', isActive: true };
    if (className) filter.className = className;
    if (section) filter.section = section;
    if (department) filter.department = department;

    const students = await User.find(filter).populate('department', 'name').sort({ name: 1 });
    return successResponse(res, students, 'Students retrieved');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

// ─── Change Password ─────────────────────────────────────────────────────────
const changePassword = async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;

    // Find user and include passwordHash
    const user = await User.findById(req.user._id).select('+passwordHash');
    if (!user) {
      return errorResponse(res, 'User not found', 404);
    }

    // Verify current password
    const isMatch = await user.comparePassword(currentPassword);
    if (!isMatch) {
      return errorResponse(res, 'Invalid current password', 400);
    }

    // Set new password (pre-save hook will hash it)
    user.passwordHash = newPassword;
    await user.save();

    return successResponse(res, {}, 'Password changed successfully');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

module.exports = { getMe, updateFcmToken, getAllUsers, createUser, updateUser, deleteUser, getStudentsByClass, changePassword };
