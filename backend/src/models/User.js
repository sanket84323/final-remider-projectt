/**
 * User Model
 * Represents students, teachers, and admins
 */

const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Name is required'],
      trim: true,
      maxlength: [100, 'Name cannot exceed 100 characters'],
    },
    email: {
      type: String,
      required: [true, 'Email is required'],
      unique: true,
      lowercase: true,
      trim: true,
      match: [/^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/, 'Invalid email'],
    },
    passwordHash: {
      type: String,
      required: true,
      minlength: 6,
      select: false, // Never return password in queries
    },
    role: {
      type: String,
      enum: ['student', 'teacher', 'admin'],
      required: true,
    },
    department: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Department',
    },
    className: {
      type: String,
      trim: true,
    },
    section: {
      type: String,
      trim: true,
      maxlength: 5,
    },
    rollNumber: {
      type: String,
      trim: true,
    },
    profileImage: {
      type: String,
      default: null,
    },
    fcmToken: {
      type: String,
      default: null,
      select: false,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    lastLogin: {
      type: Date,
    },
    refreshToken: {
      type: String,
      select: false,
    },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  }
);

// ─── Virtual: full profile URL ─────────────────────────────────────────────────
userSchema.virtual('avatarUrl').get(function () {
  return this.profileImage || `https://ui-avatars.com/api/?name=${encodeURIComponent(this.name)}&background=1565C0&color=fff`;
});

// ─── Hash password before save ────────────────────────────────────────────────
userSchema.pre('save', async function (next) {
  if (!this.isModified('passwordHash')) return next();
  this.passwordHash = await bcrypt.hash(this.passwordHash, 12);
  next();
});

// ─── Compare password ─────────────────────────────────────────────────────────
userSchema.methods.comparePassword = async function (candidatePassword) {
  return bcrypt.compare(candidatePassword, this.passwordHash);
};

// ─── Indexes ──────────────────────────────────────────────────────────────────
userSchema.index({ email: 1 });
userSchema.index({ role: 1 });
userSchema.index({ department: 1, className: 1, section: 1 });

const User = mongoose.model('User', userSchema);
module.exports = User;
