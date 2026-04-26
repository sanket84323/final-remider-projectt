/**
 * Authentication Controller
 */

const User = require('../models/User');
const ActivityLog = require('../models/ActivityLog');
const { generateTokenPair, verifyRefreshToken } = require('../utils/jwt');
const { successResponse, errorResponse } = require('../utils/apiResponse');

// ─── Login ────────────────────────────────────────────────────────────────────
const login = async (req, res) => {
  try {
    const { email, password, fcmToken } = req.body;

    // Find user and include passwordHash (normally excluded)
    const user = await User.findOne({ email, isActive: true }).select('+passwordHash');
    if (!user) {
      return errorResponse(res, 'Invalid email or password', 401);
    }

    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return errorResponse(res, 'Invalid email or password', 401);
    }

    // Generate tokens
    const { accessToken, refreshToken } = generateTokenPair(user);

    // Update user's refresh token and FCM token
    await User.findByIdAndUpdate(user._id, {
      refreshToken,
      fcmToken: fcmToken || user.fcmToken,
      lastLogin: new Date(),
    });

    // Log activity
    await ActivityLog.create({
      userId: user._id,
      action: 'LOGIN',
      metadata: { email: user.email },
      ipAddress: req.ip,
      userAgent: req.get('User-Agent'),
    });

    return successResponse(res, {
      accessToken,
      refreshToken,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        department: user.department,
        className: user.className,
        section: user.section,
        avatarUrl: user.avatarUrl,
        profileImage: user.profileImage,
      },
    }, 'Login successful');

  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

// ─── Refresh Token ────────────────────────────────────────────────────────────
const refreshToken = async (req, res) => {
  try {
    const { refreshToken: token } = req.body;
    if (!token) return errorResponse(res, 'Refresh token required', 400);

    const decoded = verifyRefreshToken(token);
    const user = await User.findOne({ _id: decoded.id, isActive: true }).select('+refreshToken');

    if (!user || user.refreshToken !== token) {
      return errorResponse(res, 'Invalid or expired refresh token', 401);
    }

    const { accessToken, refreshToken: newRefreshToken } = generateTokenPair(user);
    await User.findByIdAndUpdate(user._id, { refreshToken: newRefreshToken });

    return successResponse(res, { accessToken, refreshToken: newRefreshToken }, 'Token refreshed');
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return errorResponse(res, 'Refresh token expired. Please login again.', 401);
    }
    return errorResponse(res, 'Token refresh failed', 500);
  }
};

// ─── Logout ───────────────────────────────────────────────────────────────────
const logout = async (req, res) => {
  try {
    await User.findByIdAndUpdate(req.user._id, {
      refreshToken: null,
      fcmToken: null,
    });

    await ActivityLog.create({
      userId: req.user._id,
      action: 'LOGOUT',
      ipAddress: req.ip,
    });

    return successResponse(res, {}, 'Logged out successfully');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

// ─── Forgot Password (stub - requires email service) ─────────────────────────
const forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;
    const user = await User.findOne({ email, isActive: true });

    // Always return success to prevent email enumeration
    return successResponse(
      res,
      {},
      'If an account with that email exists, a password reset link has been sent.'
    );
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};
// ─── Register ─────────────────────────────────────────────────────────────────
const register = async (req, res) => {
  try {
    const { name, email, password, role, department, className, section, rollNumber } = req.body;

    // Check if user already exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return errorResponse(res, 'An account with this email already exists', 409);
    }

    // Only students can self-register
    if (role !== 'student') {
      return errorResponse(res, 'Only students can self-register. Please contact admin for other roles.', 403);
    }

    // Create user (pre-save hook will hash the password)
    const user = await User.create({
      name,
      email,
      passwordHash: password,
      role,
      department: department || undefined,
      className: className || undefined,
      section: section || undefined,
      rollNumber: rollNumber || undefined,
    });

    // Generate tokens
    const { accessToken, refreshToken } = generateTokenPair(user);

    // Save refresh token
    await User.findByIdAndUpdate(user._id, {
      refreshToken,
      lastLogin: new Date(),
    });

    // Log activity
    await ActivityLog.create({
      userId: user._id,
      action: 'REGISTER',
      metadata: { email: user.email, role: user.role },
      ipAddress: req.ip,
      userAgent: req.get('User-Agent'),
    });

    return successResponse(res, {
      accessToken,
      refreshToken,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        department: user.department,
        className: user.className,
        section: user.section,
        avatarUrl: user.avatarUrl,
        profileImage: user.profileImage,
      },
    }, 'Registration successful', 201);

  } catch (error) {
    if (error.code === 11000) {
      return errorResponse(res, 'An account with this email already exists', 409);
    }
    return errorResponse(res, error.message, 500);
  }
};

const getDemoCredentials = async (req, res) => {
  try {
    const [admin, teacher, student] = await Promise.all([
      User.findOne({ role: 'admin' }).select('email'),
      User.findOne({ role: 'teacher' }).select('email'),
      User.findOne({ role: 'student' }).select('email'),
    ]);

    return successResponse(res, {
      admin: { email: admin?.email || 'hod@aids.edu', password: 'Hod@123' },
      teacher: { email: teacher?.email || 'amit@aids.edu', password: 'Teacher@123' },
      student: { email: student?.email || 'sanket@student.edu', password: 'Student@123' },
    }, 'Demo credentials retrieved');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

// ─── Change Password ─────────────────────────────────────────────────────────
const changePassword = async (req, res) => {
  try {
    const { oldPassword, newPassword } = req.body;

    if (!oldPassword || !newPassword) {
      return errorResponse(res, 'Old and new passwords are required', 400);
    }

    // Find user and include passwordHash
    const user = await User.findById(req.user._id).select('+passwordHash');
    if (!user) {
      return errorResponse(res, 'User not found', 404);
    }

    // Verify old password
    const isMatch = await user.comparePassword(oldPassword);
    if (!isMatch) {
      return errorResponse(res, 'Incorrect current password', 401);
    }

    // Update password (pre-save hook will hash it)
    user.passwordHash = newPassword;
    await user.save();

    // Log activity
    await ActivityLog.create({
      userId: user._id,
      action: 'CHANGE_PASSWORD',
      ipAddress: req.ip,
    });

    return successResponse(res, {}, 'Password updated successfully');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

module.exports = { login, refreshToken, logout, forgotPassword, register, getDemoCredentials, changePassword };
