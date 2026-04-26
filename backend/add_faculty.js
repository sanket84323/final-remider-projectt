/**
 * Script to add faculty members from the provided list
 */

require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./src/models/User');
const Department = require('./src/models/Department');

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/campussync';

const facultyList = [
  { name: 'Dr Bhagyashree Dhakulkar', email: 'bhagyashree.dhakulkar@dypic.in' },
  { name: 'Ankita Harshad Tidake', email: 'ankita.tidake@gmail.com' },
  { name: 'Ashwini Aniket Shinde', email: 'ashwinis@dypic.in' },
  { name: 'Vandana Vinayak Navale', email: 'vandana.vinayak@dypic.in' },
  { name: 'Priyanka Shreyas Bhore', email: 'priyankabhore@dypic.in' },
  { name: 'Payal Deshmukh', email: 'payaldeshmukh@dypic.in' },
  { name: 'Hemangi Patil', email: 'hemangipatil@dypic.in' },
  { name: 'Gopika Avinash Fattepurkar', email: 'gopikafattepurkar@dypic.in' },
  { name: 'Supriya Survase', email: 'supriyasurvase@dypic.in' },
  { name: 'Priyanka Waghmare', email: 'priyanka.waghmare@dypic.in' },
  { name: 'Gauri Nikhil Thite', email: 'gaurirasane@dypic.in' },
  { name: 'Divya Sharma', email: 'divya.sharma@dypic.in' },
  { name: 'Amruta More', email: 'amrutamore@dypic.in' },
  { name: 'Sushma Gunjal', email: 'sushmagunjal@dypic.in' },
  { name: 'Vishakha Gaddam', email: 'vishakhagedam@dypic.in' },
  { name: 'Neelam Jain', email: 'neelamjain@dypic.in' },
  { name: 'Geeta Kodabagi', email: 'geetakodabagi@dypic.in' },
  { name: 'Neha Verma', email: 'nehaverma@dypic.in' },
  { name: 'Prof. Rupali Wagh', email: 'rupaliwagh@dypic.in' },
  { name: 'Prof. Shweta Wankhade', email: 'swetawankhade@dypic.in' },
  { name: 'Rachana Chapte', email: 'rachanachapte@dypic.in' },
  { name: 'Varsha Babar', email: 'varshababar@dyoic.in' },
  { name: 'Pooja Dehankar', email: 'poojadehankar@dypic.in' },
  { name: 'Jayshree Suryawanshi', email: 'jayshreesuryawanshi@dypic.in' },
  { name: 'Shubhangi Amol Sawant', email: 'shubhangi.sawant@dypic.in' },
  { name: 'Urmila Mahesh Kotwal', email: 'urmila.kotwal@dypic.in' },
  { name: 'Mauli Haridas Pawar', email: 'maulipawaar@dypic.in' },
  { name: 'Akshay Somnath Burde', email: 'akshayburde@dypic.in' },
  { name: 'Pratiraj Maruti Dalavi', email: 'pratirajdalavi@dypic.in' },
  { name: 'Santosh Bhosle', email: 'santoshb21101983@gmail.com' }
];

const addFaculty = async () => {
  try {
    await mongoose.connect(MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Get the department
    const dept = await Department.findOne({ code: 'AI&DS' });
    if (!dept) {
      console.error('❌ AI&DS Department not found. Please run seed script first.');
      process.exit(1);
    }

    const password = 'faculty123';
    let addedCount = 0;
    let skippedCount = 0;

    for (const faculty of facultyList) {
      const existing = await User.findOne({ email: faculty.email });
      if (!existing) {
        // Dr Bhagyashree Dhakulkar might already be HOD but with different email in seed
        // We will add all as teachers as requested.
        await User.create({
          name: faculty.name,
          email: faculty.email,
          passwordHash: password, // Pre-save hook hashes this
          role: 'teacher',
          department: dept._id,
          isActive: true
        });
        addedCount++;
      } else {
        skippedCount++;
      }
    }

    console.log(`✅ Finished! Added ${addedCount} teachers, skipped ${skippedCount} existing users.`);
    
    await mongoose.disconnect();
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
};

addFaculty();
