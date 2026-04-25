const mongoose = require('mongoose');
require('dotenv').config();

async function cleanup() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to DB');

    const Department = mongoose.model('Department', new mongoose.Schema({
      name: { type: String, unique: true },
      code: { type: String, unique: true },
      classes: [String]
    }));

    const User = mongoose.model('User', new mongoose.Schema({
      department: mongoose.Schema.Types.ObjectId,
      className: String,
      role: String
    }));

    // 1. Remove all departments except AIDS
    const deleteResult = await Department.deleteMany({ code: { $ne: 'AIDS' } });
    console.log(`Deleted ${deleteResult.deletedCount} non-AIDS departments`);

    // 2. Setup AIDS department
    let aids = await Department.findOne({ code: 'AIDS' });
    if (!aids) {
      aids = await Department.create({
        name: 'Artificial Intelligence and Data Science',
        code: 'AIDS',
        classes: ['AIDS SE A', 'AIDS SE B', 'AIDS SE C', 'AIDS TE A', 'AIDS TE B', 'AIDS TE C']
      });
      console.log('Created AIDS department');
    } else {
      aids.classes = ['AIDS SE A', 'AIDS SE B', 'AIDS SE C', 'AIDS TE A', 'AIDS TE B', 'AIDS TE C'];
      await aids.save();
      console.log('Updated AIDS classes');
    }

    // 3. Update all students to be in the first AIDS class if they are lost
    await User.updateMany(
      { department: aids._id, role: 'student' },
      { className: 'AIDS SE A' }
    );
    
    // Also update any users that were in deleted departments
    await User.updateMany(
      { department: { $ne: aids._id }, role: { $ne: 'admin' } },
      { department: aids._id }
    );

    console.log('Cleanup complete');
    process.exit(0);
  } catch (error) {
    console.error('Cleanup failed:', error);
    process.exit(1);
  }
}

cleanup();
