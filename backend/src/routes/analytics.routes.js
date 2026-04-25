const router = require('express').Router();
const { getAnalytics, getClassAssignmentDetail, getStudentDetail, getTeacherDetail } = require('../controllers/analytics.controller');
const { authenticate } = require('../middleware/auth.middleware');
const { requireRole } = require('../middleware/rbac.middleware');

router.get('/', authenticate, requireRole('admin'), getAnalytics);
router.get('/class/:className', authenticate, requireRole('admin'), getClassAssignmentDetail);
router.get('/student/:id', authenticate, requireRole('admin'), getStudentDetail);
router.get('/teacher/:id', authenticate, requireRole('admin'), getTeacherDetail);

module.exports = router;
