/**
 * Assignment Model
 * Represents assignments created by teachers
 */

const mongoose = require('mongoose');

const attachmentSchema = new mongoose.Schema({
  originalName: String,
  url: String,
  publicId: String,
  mimeType: String,
  size: Number,
});

const completionSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  completedAt: { type: Date, default: Date.now },
  note: String,
  status: { 
    type: String, 
    enum: ['pending', 'completed'], 
    default: 'completed' // Existing ones are completed
  },
});

const assignmentSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: [true, 'Assignment title is required'],
      trim: true,
      maxlength: [200, 'Title cannot exceed 200 characters'],
    },
    description: {
      type: String,
      required: [true, 'Description is required'],
      trim: true,
    },
    subject: {
      type: String,
      trim: true,
    },
    dueDate: {
      type: Date,
      required: [true, 'Due date is required'],
    },
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    targetAudience: {
      type: {
        type: String,
        enum: ['all', 'department', 'class', 'section'],
        default: 'class',
      },
      department: { type: mongoose.Schema.Types.ObjectId, ref: 'Department' },
      classNames: [String],
      className: String, // Keep for single class backward compatibility
      section: String,
    },
    attachments: [attachmentSchema],
    completedBy: [completionSchema],
    maxMarks: {
      type: Number,
      default: 100,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
  }
);

// ─── Virtual: is overdue ──────────────────────────────────────────────────────
assignmentSchema.virtual('isOverdue').get(function () {
  return this.dueDate < new Date();
});

// ─── Indexes ──────────────────────────────────────────────────────────────────
assignmentSchema.index({ createdBy: 1, dueDate: 1 });
assignmentSchema.index({ 'targetAudience.className': 1 });
assignmentSchema.index({ dueDate: 1 });

const Assignment = mongoose.model('Assignment', assignmentSchema);
module.exports = Assignment;
