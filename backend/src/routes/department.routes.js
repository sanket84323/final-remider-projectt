const router = require('express').Router();
const { getDepartments, createDepartment, updateDepartment, deleteDepartment } = require('../controllers/department.controller');
const { authenticate } = require('../middleware/auth.middleware');
const { requireRole } = require('../middleware/rbac.middleware');

router.get('/', authenticate, getDepartments);
router.post('/', authenticate, requireRole('admin'), createDepartment);
router.put('/:id', authenticate, requireRole('admin'), updateDepartment);
router.delete('/:id', authenticate, requireRole('admin'), deleteDepartment);

module.exports = router;
