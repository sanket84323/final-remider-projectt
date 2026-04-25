const mongoose = require('mongoose');
require('dotenv').config();

async function forceMigration() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to DB');

    const Department = mongoose.model('Department', new mongoose.Schema({
      code: String
    }));

    const User = mongoose.model('User', new mongoose.Schema({
      department: mongoose.Schema.Types.ObjectId,
      className: String,
      role: String
    }));

    const aids = await Department.findOne({ code: 'AIDS' });
    if (!aids) {
      console.error('AIDS department not found. Run cleanup_dept.js first.');
      process.exit(1);
    }

    const students = await User.find({ role: 'student' });
    console.log(`Found ${students.length} students. Starting migration...`);

    const classMapping = {
      'CS-3A': 'AIDS TE A',
      'CS-3B': 'AIDS TE B',
      'TE B': 'AIDS TE B',
      'TE C': 'AIDS TE C',
      'EC-2A': 'AIDS SE A',
      'SE A': 'AIDS SE A',
      'SE B': 'AIDS SE B',
      'SE C': 'AIDS SE C'
    };

    let updatedCount = 0;
    for (const student of students) {
      const oldClass = student.className;
      const newClass = classMapping[oldClass] || 'AIDS SE A';
      
      student.className = newClass;
      student.department = aids._id;
      await student.save();
      updatedCount++;
    }

    console.log(`Successfully migrated ${updatedCount} students to AIDS classes.`);
    process.exit(0);
  } catch (error) {
    console.error('Migration failed:', error);
    process.exit(1);
  }
}

forceMigration();
