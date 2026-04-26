require('dotenv').config();
const mongoose = require('mongoose');
const User = require('../src/models/User');

async function checkUsers() {
  await mongoose.connect(process.env.MONGODB_URI);
  console.log('Connected to DB');
  
  const users = await User.find({}).select('+passwordHash');
  console.log('Total users:', users.length);
  users.forEach(u => {
    console.log(`- ${u.email} (${u.role}) Password Hash: ${u.passwordHash.substring(0, 10)}...`);
  });
  
  await mongoose.disconnect();
}

checkUsers();
