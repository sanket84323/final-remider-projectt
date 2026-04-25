const router = require('express').Router();
const { getAnalytics } = require('../controllers/analytics.controller');
const { authenticate } = require('../middleware/auth.middleware');
const { requireRole } = require('../middleware/rbac.middleware');

router.get('/', authenticate, requireRole('admin'), getAnalytics);

module.exports = router;
