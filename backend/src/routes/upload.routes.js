const router = require('express').Router();
const { uploadFile, uploadMultipleFiles } = require('../controllers/upload.controller');
const { authenticate } = require('../middleware/auth.middleware');
const { requireRole } = require('../middleware/rbac.middleware');
const { upload } = require('../config/cloudinary');

router.post('/single', authenticate, requireRole('teacher', 'admin'), upload.single('file'), uploadFile);
router.post('/multiple', authenticate, requireRole('teacher', 'admin'), upload.array('files', 5), uploadMultipleFiles);

module.exports = router;
