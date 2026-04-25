/**
 * Role-Based Access Control Middleware
 */

const { errorResponse } = require('../utils/apiResponse');

/**
 * requireRole - allows only specific roles to access a route
 * @param  {...string} roles - allowed roles
 */
const requireRole = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return errorResponse(res, 'Not authenticated', 401);
    }
    if (!roles.includes(req.user.role)) {
      return errorResponse(
        res,
        `Access forbidden. Required roles: ${roles.join(', ')}`,
        403
      );
    }
    next();
  };
};

/**
 * requireOwnerOrAdmin - allows resource owner or admin to access
 */
const requireOwnerOrAdmin = (getResourceUserId) => {
  return async (req, res, next) => {
    try {
      const resourceUserId = await getResourceUserId(req);
      const isOwner = req.user._id.toString() === resourceUserId?.toString();
      const isAdmin = req.user.role === 'admin';

      if (!isOwner && !isAdmin) {
        return errorResponse(res, 'Access forbidden. You do not own this resource.', 403);
      }
      next();
    } catch (err) {
      return errorResponse(res, 'Authorization check failed', 500);
    }
  };
};

module.exports = { requireRole, requireOwnerOrAdmin };
