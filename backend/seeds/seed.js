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

// Helper: hash a password (insertMany skips pre-save hooks, so we must hash manually)
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
  const [csDept, ecDept] = await Department.insertMany([
    { name: 'Computer Science', code: 'CS', description: 'Department of Computer Science & Engineering' },
    { name: 'Electronics', code: 'EC', description: 'Department of Electronics & Communication' },
  ]);

  // ─── Admin ──────────────────────────────────────────────────────────────────
  const admin = await User.create({
    name: 'Dr. Rajesh Kumar',
    email: 'admin@campussync.edu',
    passwordHash: 'Admin@123',
    role: 'admin',
    department: csDept._id,
  });

  // ─── Teachers (hash passwords manually for insertMany) ──────────────────────
  const teacherPwHash = hash('Teacher@123');
  const [teacher1, teacher2, teacher3] = await User.insertMany([
    { name: 'Prof. Anita Sharma', email: 'anita@campussync.edu', passwordHash: teacherPwHash, role: 'teacher', department: csDept._id },
    { name: 'Prof. Vikram Nair', email: 'vikram@campussync.edu', passwordHash: teacherPwHash, role: 'teacher', department: csDept._id },
    { name: 'Prof. Priya Mehta', email: 'priya@campussync.edu', passwordHash: teacherPwHash, role: 'teacher', department: ecDept._id },
  ]);

  // ─── Students (hash passwords manually for insertMany) ──────────────────────
  const studentPwHash = hash('Student@123');
  const students = await User.insertMany([
    { name: 'Arjun Patel', email: 'arjun@student.edu', passwordHash: studentPwHash, role: 'student', department: csDept._id, className: 'CS-3A', section: 'A', rollNumber: 'CS21001' },
    { name: 'Priya Singh', email: 'priya.s@student.edu', passwordHash: studentPwHash, role: 'student', department: csDept._id, className: 'CS-3A', section: 'A', rollNumber: 'CS21002' },
    { name: 'Rahul Gupta', email: 'rahul@student.edu', passwordHash: studentPwHash, role: 'student', department: csDept._id, className: 'CS-3A', section: 'A', rollNumber: 'CS21003' },
    { name: 'Neha Joshi', email: 'neha@student.edu', passwordHash: studentPwHash, role: 'student', department: csDept._id, className: 'CS-3B', section: 'B', rollNumber: 'CS21004' },
    { name: 'Karthik Reddy', email: 'karthik@student.edu', passwordHash: studentPwHash, role: 'student', department: csDept._id, className: 'CS-3B', section: 'B', rollNumber: 'CS21005' },
    { name: 'Meera Krishnan', email: 'meera@student.edu', passwordHash: studentPwHash, role: 'student', department: ecDept._id, className: 'EC-2A', section: 'A', rollNumber: 'EC22001' },
    { name: 'Aditya Verma', email: 'aditya@student.edu', passwordHash: studentPwHash, role: 'student', department: ecDept._id, className: 'EC-2A', section: 'A', rollNumber: 'EC22002' },
    { name: 'Sneha Pillai', email: 'sneha@student.edu', passwordHash: studentPwHash, role: 'student', department: csDept._id, className: 'CS-3A', section: 'A', rollNumber: 'CS21006' },
    { name: 'Rohan Malhotra', email: 'rohan@student.edu', passwordHash: studentPwHash, role: 'student', department: csDept._id, className: 'CS-3B', section: 'B', rollNumber: 'CS21007' },
    { name: 'Divya Iyer', email: 'divya@student.edu', passwordHash: studentPwHash, role: 'student', department: ecDept._id, className: 'EC-2A', section: 'A', rollNumber: 'EC22003' },
  ]);

  // ─── Classes ─────────────────────────────────────────────────────────────────
  const classCS3A = await Class.create({
    name: 'CS-3A', section: 'A', department: csDept._id, year: 3,
    teacherIds: [teacher1._id, teacher2._id],
    studentIds: students.filter((s) => s.className === 'CS-3A').map((s) => s._id),
  });
  const classCS3B = await Class.create({
    name: 'CS-3B', section: 'B', department: csDept._id, year: 3,
    teacherIds: [teacher1._id],
    studentIds: students.filter((s) => s.className === 'CS-3B').map((s) => s._id),
  });



  const now = new Date();
  // ─── Assignments ──────────────────────────────────────────────────────────────
  const [assign1, assign2] = await Assignment.insertMany([
    {
      title: 'Implement a Binary Search Tree in Python',
      description: 'Write a Python program to implement a Binary Search Tree with operations: insert, delete, search, inorder traversal, and level-order traversal. Include proper documentation and test cases.',
      subject: 'Data Structures & Algorithms',
      dueDate: new Date(now.getTime() + 5 * 24 * 60 * 60 * 1000),
      createdBy: teacher1._id,
      targetAudience: { type: 'class', className: 'CS-3A' },
      completedBy: [{ userId: students[0]._id }, { userId: students[1]._id }],
    },
    {
      title: 'Database Design Assignment - Library Management System',
      description: 'Design an ER diagram for a Library Management System. Create the relational schema, write SQL queries for CRUD operations, and implement normalization up to 3NF. Submit as PDF.',
      subject: 'Database Management Systems',
      dueDate: new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000),
      createdBy: teacher2._id,
      targetAudience: { type: 'class', className: 'CS-3A' },
    },
    {
      title: 'Operating System Concepts - Process Scheduling Simulation',
      description: 'Implement FCFS, SJF, and Round Robin scheduling algorithms in C or Java. Compare results with Gantt charts and analyze throughput, waiting time, and turnaround time.',
      subject: 'Operating Systems',
      dueDate: new Date(now.getTime() + 8 * 24 * 60 * 60 * 1000),
      createdBy: teacher1._id,
      targetAudience: { type: 'class', className: 'CS-3B' },
    },
  ]);



  console.log('\n✅ Seed data inserted successfully!');
  console.log('\n── Login Credentials ──────────────────────────');
  console.log('Admin:   admin@campussync.edu    / Admin@123');
  console.log('Teacher: anita@campussync.edu    / Teacher@123');
  console.log('Teacher: vikram@campussync.edu   / Teacher@123');
  console.log('Student: arjun@student.edu       / Student@123');
  console.log('Student: priya.s@student.edu     / Student@123');
  console.log('──────────────────────────────────────────────\n');

  await mongoose.disconnect();
};

seed().catch((err) => {
  console.error('❌ Seed failed:', err.message);
  process.exit(1);
});
