const router = require('express').Router();
const { getClasses, createClass, updateClass, deleteClass } = require('../controllers/class.controller');
const { authenticate } = require('../middleware/auth.middleware');
const { requireRole } = require('../middleware/rbac.middleware');

router.get('/', authenticate, getClasses);
router.post('/', authenticate, requireRole('admin'), createClass);
router.put('/:id', authenticate, requireRole('admin'), updateClass);
router.delete('/:id', authenticate, requireRole('admin'), deleteClass);

module.exports = router;
