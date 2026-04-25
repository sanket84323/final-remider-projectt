/**
 * Request Validation Middleware using express-validator
 */

const { validationResult, body, param, query } = require('express-validator');
const { errorResponse } = require('../utils/apiResponse');

// ─── Validation Runner ────────────────────────────────────────────────────────
const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return errorResponse(res, 'Validation failed', 400, errors.array());
  }
  next();
};

// ─── Auth Validators ──────────────────────────────────────────────────────────
const loginValidation = [
  body('email').isEmail().normalizeEmail().withMessage('Valid email required'),
  body('password').notEmpty().withMessage('Password required'),
  validate,
];

const registerValidation = [
  body('name').trim().notEmpty().withMessage('Name required').isLength({ max: 100 }),
  body('email').isEmail().normalizeEmail().withMessage('Valid email required'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
  body('role').isIn(['student', 'teacher', 'admin']).withMessage('Invalid role'),
  validate,
];

// ─── Reminder Validators ──────────────────────────────────────────────────────
const createReminderValidation = [
  body('title').trim().notEmpty().withMessage('Title required').isLength({ max: 200 }),
  body('description').trim().notEmpty().withMessage('Description required'),
  body('priority').optional().isIn(['normal', 'important', 'urgent']),
  body('category').optional().isIn(['reminder', 'announcement', 'notice', 'event', 'exam', 'timetable']),
  body('scheduledAt').optional().isISO8601().withMessage('Invalid date format'),
  validate,
];

// ─── Assignment Validators ────────────────────────────────────────────────────
const createAssignmentValidation = [
  body('title').trim().notEmpty().withMessage('Title required').isLength({ max: 200 }),
  body('description').trim().notEmpty().withMessage('Description required'),
  body('dueDate').isISO8601().withMessage('Valid due date required'),
  validate,
];

// ─── User Validators ──────────────────────────────────────────────────────────
const createUserValidation = [
  body('name').trim().notEmpty().withMessage('Name required'),
  body('email').isEmail().normalizeEmail().withMessage('Valid email required'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
  body('role').isIn(['student', 'teacher', 'admin']).withMessage('Invalid role'),
  validate,
];

// ─── ObjectId Param Validator ─────────────────────────────────────────────────
const validateObjectId = (paramName = 'id') => [
  param(paramName).isMongoId().withMessage(`Invalid ${paramName} format`),
  validate,
];

module.exports = {
  loginValidation,
  registerValidation,
  createReminderValidation,
  createAssignmentValidation,
  createUserValidation,
  validateObjectId,
  validate,
};
