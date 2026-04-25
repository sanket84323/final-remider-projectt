const router = require('express').Router();
const { getStudentDashboard, getTeacherDashboard, getAdminDashboard } = require('../controllers/dashboard.controller');
const { authenticate } = require('../middleware/auth.middleware');
const { requireRole } = require('../middleware/rbac.middleware');

router.get('/student', authenticate, requireRole('student'), getStudentDashboard);
router.get('/teacher', authenticate, requireRole('teacher'), getTeacherDashboard);
router.get('/admin', authenticate, requireRole('admin'), getAdminDashboard);

module.exports = router;
