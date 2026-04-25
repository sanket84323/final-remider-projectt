/**
 * Scratch script to ensure default department exists
 */
const mongoose = require('mongoose');
const Department = require('./src/models/Department');
require('dotenv').config();

async function seed() {
  await mongoose.connect(process.env.MONGODB_URI);
  console.log('Connected to DB');

  const exists = await Department.findOne({ code: 'AIDS' });
  if (!exists) {
    await Department.create({
      name: 'Artificial Intelligence and Data Science',
      code: 'AIDS',
      description: 'Department of AI & DS'
    });
    console.log('Created AIDS department');
  } else {
    console.log('AIDS department already exists');
  }

  await mongoose.disconnect();
}

seed();
