const router = require('express').Router();
const { getAnalytics, getClassAssignmentDetail, getStudentDetail, getTeacherDetail, getClasses, getUserStats } = require('../controllers/analytics.controller');
const { authenticate } = require('../middleware/auth.middleware');
const { requireRole } = require('../middleware/rbac.middleware');

router.get('/', authenticate, requireRole('admin'), getAnalytics);
router.get('/user-stats', authenticate, requireRole('admin'), getUserStats);
router.get('/classes', authenticate, requireRole('admin', 'teacher'), getClasses);
router.get('/class/:className', authenticate, requireRole('admin', 'teacher'), getClassAssignmentDetail);
router.get('/student/:id', authenticate, requireRole('admin', 'teacher'), getStudentDetail);
router.get('/teacher/:id', authenticate, requireRole('admin', 'teacher'), getTeacherDetail);

module.exports = router;
