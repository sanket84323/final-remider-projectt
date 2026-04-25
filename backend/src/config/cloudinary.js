/**
 * Cloudinary Configuration
 */

const cloudinary = require('cloudinary').v2;  // v1.x - same v2 API
const { CloudinaryStorage } = require('multer-storage-cloudinary');
const multer = require('multer');
const logger = require('../utils/logger');

let cloudinaryConfigured = false;

if (process.env.CLOUDINARY_CLOUD_NAME && process.env.CLOUDINARY_API_KEY) {
  cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET,
  });
  cloudinaryConfigured = true;
  logger.info('☁️  Cloudinary configured');
} else {
  logger.warn('⚠️  Cloudinary not configured. File uploads disabled.');
}

// Cloudinary storage for multer
const storage = cloudinaryConfigured
  ? new CloudinaryStorage({
      cloudinary,
      params: {
        folder: 'campussync',
        allowed_formats: ['jpg', 'jpeg', 'png', 'gif', 'pdf', 'doc', 'docx', 'ppt', 'pptx', 'xlsx', 'txt'],
        resource_type: 'auto',
      },
    })
  : multer.memoryStorage();

const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
});

module.exports = { cloudinary, upload, cloudinaryConfigured };
