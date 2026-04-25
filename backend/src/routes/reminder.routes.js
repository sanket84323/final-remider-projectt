const router = require('express').Router();
const { createReminder, getReminders, getReminderById, updateReminder, deleteReminder, getReadReceipts } = require('../controllers/reminder.controller');
const { authenticate } = require('../middleware/auth.middleware');
const { requireRole } = require('../middleware/rbac.middleware');
const { createReminderValidation } = require('../middleware/validate.middleware');

router.get('/', authenticate, getReminders);
router.post('/', authenticate, requireRole('teacher', 'admin'), createReminderValidation, createReminder);
router.get('/:id', authenticate, getReminderById);
router.put('/:id', authenticate, requireRole('teacher', 'admin'), updateReminder);
router.delete('/:id', authenticate, requireRole('teacher', 'admin'), deleteReminder);
router.get('/:id/read-receipts', authenticate, requireRole('teacher', 'admin'), getReadReceipts);

module.exports = router;
