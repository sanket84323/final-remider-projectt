const router = require('express').Router();
const { 
  getDepartments, createDepartment, updateDepartment, deleteDepartment,
  getClasses, addClass, removeClass 
} = require('../controllers/department.controller');
const { authenticate } = require('../middleware/auth.middleware');
const { requireRole } = require('../middleware/rbac.middleware');

router.get('/', authenticate, getDepartments);
router.post('/', authenticate, requireRole('admin'), createDepartment);
router.put('/:id', authenticate, requireRole('admin'), updateDepartment);
router.delete('/:id', authenticate, requireRole('admin'), deleteDepartment);

// ─── Class Management ───────────────────────────────────────────────────────
router.get('/:id/classes', authenticate, requireRole('admin'), getClasses);
router.post('/:id/classes', authenticate, requireRole('admin'), addClass);
router.delete('/:id/classes', authenticate, requireRole('admin'), removeClass); // Using body for action/targetClass

module.exports = router;
