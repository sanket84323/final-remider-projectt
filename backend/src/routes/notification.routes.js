const router = require('express').Router();
const { getNotifications, markAsRead, markAllAsRead, deleteNotification } = require('../controllers/notification.controller');
const { authenticate } = require('../middleware/auth.middleware');

router.get('/', authenticate, getNotifications);
router.put('/mark-all-read', authenticate, markAllAsRead);
router.put('/:id/read', authenticate, markAsRead);
router.delete('/:id', authenticate, deleteNotification);

module.exports = router;
