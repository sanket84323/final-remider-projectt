/**
 * Authentication Middleware
 * Verifies JWT access token and attaches user to request
 */

const { verifyAccessToken } = require('../utils/jwt');
const User = require('../models/User');
const { errorResponse } = require('../utils/apiResponse');

const authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return errorResponse(res, 'Access denied. No token provided.', 401);
    }

    const token = authHeader.split(' ')[1];
    const decoded = verifyAccessToken(token);

    // Fetch fresh user (ensures account still active)
    const user = await User.findById(decoded.id).select('-passwordHash -refreshToken');
    if (!user) {
      return errorResponse(res, 'User not found. Token invalid.', 401);
    }
    if (!user.isActive) {
      return errorResponse(res, 'Account deactivated. Contact admin.', 403);
    }

    req.user = user;
    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return errorResponse(res, 'Token expired. Please refresh or login again.', 401);
    }
    if (error.name === 'JsonWebTokenError') {
      return errorResponse(res, 'Invalid token.', 401);
    }
    return errorResponse(res, 'Authentication failed.', 500);
  }
};

module.exports = { authenticate };
