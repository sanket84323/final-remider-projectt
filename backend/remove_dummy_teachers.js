/**
 * Script to remove dummy teachers from the database
 */

require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./src/models/User');

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/campussync';

const removeTeachers = async () => {
  try {
    await mongoose.connect(MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // List of dummy teacher emails from seed.js
    const dummyEmails = ['amit@aids.edu', 'sarika@aids.edu'];

    const result = await User.deleteMany({ 
      role: 'teacher',
      email: { $in: dummyEmails }
    });

    console.log(`🗑️  Successfully removed ${result.deletedCount} dummy teachers.`);
    
    await mongoose.disconnect();
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
};

removeTeachers();
