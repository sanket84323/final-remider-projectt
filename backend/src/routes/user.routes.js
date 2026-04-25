const router = require('express').Router();
const { getMe, updateFcmToken, getAllUsers, createUser, updateUser, deleteUser, getStudentsByClass, changePassword } = require('../controllers/user.controller');
const { authenticate } = require('../middleware/auth.middleware');
const { requireRole } = require('../middleware/rbac.middleware');
const { createUserValidation } = require('../middleware/validate.middleware');

router.get('/me', authenticate, getMe);
router.put('/me/fcm-token', authenticate, updateFcmToken);
router.post('/change-password', authenticate, changePassword);
router.get('/students', authenticate, requireRole('teacher', 'admin'), getStudentsByClass);
router.get('/', authenticate, requireRole('admin'), getAllUsers);
router.post('/', authenticate, requireRole('admin'), createUserValidation, createUser);
router.put('/:id', authenticate, updateUser);
router.delete('/:id', authenticate, requireRole('admin'), deleteUser);

module.exports = router;
