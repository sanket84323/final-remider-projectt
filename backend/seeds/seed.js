/**
 * Seed Script - Populates database with sample data
 * Run: npm run seed
 */

require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const User = require('../src/models/User');
const Department = require('../src/models/Department');
const Class = require('../src/models/Class');
const Reminder = require('../src/models/Reminder');
const Assignment = require('../src/models/Assignment');
const Notification = require('../src/models/Notification');

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/campussync';

// Helper: hash a password
const hash = (pw) => bcrypt.hashSync(pw, 12);

const seed = async () => {
  await mongoose.connect(MONGODB_URI);
  console.log('✅ Connected to MongoDB');

  // Clear existing data
  await Promise.all([
    User.deleteMany({}), Department.deleteMany({}), Class.deleteMany({}),
    Reminder.deleteMany({}), Assignment.deleteMany({}), Notification.deleteMany({}),
  ]);
  console.log('🗑️  Cleared existing data');

  // ─── Departments ────────────────────────────────────────────────────────────
  const [csDept] = await Department.insertMany([
    { name: 'Artificial Intelligence and Data Science', code: 'AI&DS', description: 'Department of AI & DS' },
  ]);

  // ─── HOD ──────────────────────────────────────────────────────────────────
  const hod = await User.create({
    name: 'Dr. Bhagyshree Dhakulkar',
    email: 'hod@aids.edu',
    passwordHash: 'Hod@123',
    role: 'admin',
    department: csDept._id,
  });

  // ─── Teachers ──────────────────────────────────────────────────────────────
  const teacherPw = 'Teacher@123';
  const [teacher1, teacher2] = await User.create([
    { name: 'Prof. Amit Verma', email: 'amit@aids.edu', passwordHash: teacherPw, role: 'teacher', department: csDept._id },
    { name: 'Prof. Sarika Patil', email: 'sarika@aids.edu', passwordHash: teacherPw, role: 'teacher', department: csDept._id },
  ]);

  // ─── Students ──────────────────────────────────────────────────────────────
  const studentPw = 'Student@123';
  const students = await User.create([
    { name: 'Sanket Solanke', email: 'sanket@student.edu', passwordHash: studentPw, role: 'student', department: csDept._id, className: 'AIDS TE A', section: 'A', rollNumber: 'TE001' },
    { name: 'Aditya Mane', email: 'aditya@student.edu', passwordHash: studentPw, role: 'student', department: csDept._id, className: 'AIDS TE A', section: 'A', rollNumber: 'TE002' },
    { name: 'Neha Deshmukh', email: 'neha@student.edu', passwordHash: studentPw, role: 'student', department: csDept._id, className: 'AIDS TE B', section: 'B', rollNumber: 'TE050' },
  ]);


  // ─── Classes ─────────────────────────────────────────────────────────────────
  await Class.create({
    name: 'AIDS TE A', section: 'A', department: csDept._id, year: 3,
    teacherIds: [teacher1._id, teacher2._id],
    studentIds: students.filter((s) => s.className === 'AIDS TE A').map((s) => s._id),
  });

  const now = new Date();
  // ─── Reminders ──────────────────────────────────────────────────────────────
  const reminders = await Reminder.insertMany([
    {
      title: 'Workshop on Generative AI',
      description: 'Hands-on workshop on GPT and Stable Diffusion models.',
      category: 'event',
      priority: 'important',
      status: 'sent',
      isPinned: true,
      createdBy: hod._id,
      targetAudience: { type: 'all' }
    },
    {
      title: 'Internal Assessment - I',
      description: 'IA-1 for AI & DS subjects starts from next Monday.',
      category: 'exam',
      priority: 'urgent',
      status: 'sent',
      createdBy: teacher1._id,
      targetAudience: { type: 'class', className: 'AIDS TE A' }
    }
  ]);

  // Create notifications for all students
  for (const [idx, reminder] of reminders.entries()) {
    for (const [sIdx, student] of students.entries()) {
      // Mark some as read for variety
      const isRead = (idx + sIdx) % 2 === 0;
      await Notification.create({
        userId: student._id,
        reminderId: reminder._id,
        title: reminder.title,
        body: reminder.description,
        type: reminder.category,
        priority: reminder.priority,
        deliveredAt: now,
        readStatus: isRead,
        readAt: isRead ? now : null
      });
    }
  }

  console.log('\n✅ Seed data inserted successfully!');
  console.log('\n── Login Credentials ──────────────────────────');
  console.log('HOD:      hod@aids.edu        / Hod@123');
  console.log('Teacher:  amit@aids.edu       / Teacher@123');
  console.log('Student:  sanket@student.edu  / Student@123');
  console.log('──────────────────────────────────────────────\n');

  await mongoose.disconnect();
};

seed().catch((err) => {
  console.error('❌ Seed failed:', err.message);
  process.exit(1);
});
