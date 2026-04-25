/**
 * Class Model
 */

const mongoose = require('mongoose');

const classSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Class name is required'],
      trim: true,
    },
    section: {
      type: String,
      required: true,
      trim: true,
      maxlength: 5,
    },
    department: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Department',
      required: true,
    },
    year: {
      type: Number,
      min: 1,
      max: 6,
    },
    teacherIds: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
      },
    ],
    studentIds: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
      },
    ],
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

// ─── Virtual: student count ───────────────────────────────────────────────────
classSchema.virtual('studentCount').get(function () {
  return this.studentIds ? this.studentIds.length : 0;
});

classSchema.index({ department: 1 });
classSchema.index({ name: 1, section: 1 });

const Class = mongoose.model('Class', classSchema);
module.exports = Class;
