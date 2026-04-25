const router = require('express').Router();
const { createAssignment, getAssignments, getAssignmentById, markComplete, updateAssignment, deleteAssignment, markStudentComplete } = require('../controllers/assignment.controller');
const { authenticate } = require('../middleware/auth.middleware');
const { requireRole } = require('../middleware/rbac.middleware');
const { createAssignmentValidation } = require('../middleware/validate.middleware');

router.get('/', authenticate, getAssignments);
router.post('/', authenticate, requireRole('teacher', 'admin'), createAssignmentValidation, createAssignment);
router.get('/:id', authenticate, getAssignmentById);
router.put('/:id/complete', authenticate, requireRole('student'), markComplete);
router.post('/mark-student-complete', authenticate, requireRole('teacher', 'admin'), markStudentComplete);
router.put('/:id', authenticate, requireRole('teacher', 'admin'), updateAssignment);
router.delete('/:id', authenticate, requireRole('teacher', 'admin'), deleteAssignment);

module.exports = router;
