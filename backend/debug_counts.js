const mongoose = require('mongoose');
require('dotenv').config();
const User = require('./src/models/User');
const Notification = require('./src/models/Notification');

async function check() {
  await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/campussync');
  const hod = await User.findOne({ email: 'hod@aids.edu' });
  const students = await User.find({ department: hod.department, role: 'student' });
  const ids = students.map(s => s._id);
  
  const total = await Notification.countDocuments({ userId: { $in: ids } });
  const read = await Notification.countDocuments({ userId: { $in: ids }, readStatus: true });
  
  console.log('Total Notifs:', total);
  console.log('Read Notifs:', read);
  console.log('Read Rate:', total > 0 ? (read / total * 100).toFixed(1) : 0);
  
  process.exit(0);
}

check();
