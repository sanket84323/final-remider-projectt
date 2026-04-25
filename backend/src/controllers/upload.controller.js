/**
 * Upload Controller - Cloudinary file uploads
 */

const { cloudinaryConfigured } = require('../config/cloudinary');
const ActivityLog = require('../models/ActivityLog');
const { successResponse, errorResponse } = require('../utils/apiResponse');

const uploadFile = async (req, res) => {
  try {
    if (!cloudinaryConfigured) {
      return errorResponse(res, 'File upload service not configured', 503);
    }
    if (!req.file) {
      return errorResponse(res, 'No file provided', 400);
    }

    const fileData = {
      originalName: req.file.originalname,
      url: req.file.path,
      publicId: req.file.filename,
      mimeType: req.file.mimetype,
      size: req.file.size,
    };

    await ActivityLog.create({
      userId: req.user._id,
      action: 'UPLOAD_FILE',
      metadata: { filename: req.file.originalname, size: req.file.size },
    });

    return successResponse(res, fileData, 'File uploaded successfully', 201);
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

const uploadMultipleFiles = async (req, res) => {
  try {
    if (!cloudinaryConfigured) {
      return errorResponse(res, 'File upload service not configured', 503);
    }
    if (!req.files || req.files.length === 0) {
      return errorResponse(res, 'No files provided', 400);
    }

    const files = req.files.map((f) => ({
      originalName: f.originalname,
      url: f.path,
      publicId: f.filename,
      mimeType: f.mimetype,
      size: f.size,
    }));

    return successResponse(res, files, 'Files uploaded successfully', 201);
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};

module.exports = { uploadFile, uploadMultipleFiles };
