/**
 * Department Model
 */

const mongoose = require('mongoose');

const departmentSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Department name is required'],
      trim: true,
      unique: true,
    },
    code: {
      type: String,
      required: [true, 'Department code is required'],
      trim: true,
      uppercase: true,
      unique: true,
      maxlength: 10,
    },
    description: {
      type: String,
      trim: true,
    },
    hodId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    classes: {
      type: [String],
      default: ['SE A', 'SE B', 'TE A', 'TE B']
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  { timestamps: true }
);

const Department = mongoose.model('Department', departmentSchema);
module.exports = Department;
