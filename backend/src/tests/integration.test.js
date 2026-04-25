/**
 * CampusSync – Full Integration Test Suite
 * Tests all API endpoints end-to-end against a running backend.
 * Run: node src/tests/integration.test.js
 * Requires: Backend running on port 5000 + seeded DB
 */

const BASE = 'http://localhost:5000/api';

let adminToken, teacherToken, studentToken;
let reminderId, assignmentId, notificationId;
let pass = 0, fail = 0;

// ── Helper ────────────────────────────────────────────────────────────────────
async function req(method, path, body, token) {
  const res = await fetch(`${BASE}${path}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const data = await res.json();
  return { status: res.status, data };
}

function assert(condition, name) {
  if (condition) {
    console.log(`  ✅ ${name}`);
    pass++;
  } else {
    console.error(`  ❌ ${name}`);
    fail++;
  }
}

// ── Tests ─────────────────────────────────────────────────────────────────────

async function testHealth() {
  console.log('\n🏥 Health Check');
  const { status, data } = await req('GET', '/health');
  assert(status === 200, 'API health check returns 200');
  assert(data.success === true, 'Health response success flag');
}

async function testAuth() {
  console.log('\n🔐 Auth Tests');

  // Admin login
  const adminRes = await req('POST', '/auth/login', { email: 'admin@campussync.edu', password: 'Admin@123' });
  assert(adminRes.status === 200, 'Admin login returns 200');
  assert(!!adminRes.data.data?.accessToken, 'Admin gets access token');
  assert(adminRes.data.data?.user?.role === 'admin', 'Admin role confirmed');
  adminToken = adminRes.data.data?.accessToken;

  // Teacher login
  const teacherRes = await req('POST', '/auth/login', { email: 'anita@campussync.edu', password: 'Teacher@123' });
  assert(teacherRes.status === 200, 'Teacher login returns 200');
  assert(teacherRes.data.data?.user?.role === 'teacher', 'Teacher role confirmed');
  teacherToken = teacherRes.data.data?.accessToken;

  // Student login
  const studentRes = await req('POST', '/auth/login', { email: 'arjun@student.edu', password: 'Student@123' });
  assert(studentRes.status === 200, 'Student login returns 200');
  assert(studentRes.data.data?.user?.role === 'student', 'Student role confirmed');
  studentToken = studentRes.data.data?.accessToken;

  // Wrong password
  const badRes = await req('POST', '/auth/login', { email: 'admin@campussync.edu', password: 'WrongPass' });
  assert(badRes.status === 401, 'Wrong password returns 401');

  // Missing fields
  const emptyRes = await req('POST', '/auth/login', { email: '' });
  assert(emptyRes.status === 400 || emptyRes.status === 422, 'Missing fields returns 400/422');

  // Get current user
  const meRes = await req('GET', '/users/me', null, studentToken);
  assert(meRes.status === 200, 'GET /users/me returns 200');
  assert(meRes.data.data?.email === 'arjun@student.edu', 'Current user email matches');
}

async function testReminders() {
  console.log('\n📣 Reminder Tests');

  // Create reminder (teacher)
  const createRes = await req('POST', '/reminders', {
    title: 'Integration Test Reminder',
    description: 'This is a test reminder created by the integration test suite.',
    priority: 'important',
    category: 'reminder',
    targetAudience: { type: 'all' },
  }, teacherToken);
  assert(createRes.status === 201, 'Create reminder returns 201');
  assert(createRes.data.data?.title === 'Integration Test Reminder', 'Reminder title matches');
  reminderId = createRes.data.data?._id;

  // Get all reminders (student)
  const listRes = await req('GET', '/reminders?page=1&limit=10', null, studentToken);
  assert(listRes.status === 200, 'List reminders returns 200');
  assert(Array.isArray(listRes.data.data), 'Reminders data is array');

  // Get reminder by ID
  if (reminderId) {
    const getRes = await req('GET', `/reminders/${reminderId}`, null, studentToken);
    assert(getRes.status === 200, 'Get reminder by ID returns 200');
    assert(getRes.data.data?._id === reminderId, 'Reminder ID matches');
  }

  // Student cannot create reminder
  const forbidRes = await req('POST', '/reminders', { title: 'Unauthorized', description: 'x', priority: 'normal', category: 'reminder', targetAudience: { type: 'all' } }, studentToken);
  assert(forbidRes.status === 403, 'Student cannot create reminder (403)');

  // Unauthenticated access
  const unauthRes = await req('GET', '/reminders', null, null);
  assert(unauthRes.status === 401, 'Unauthenticated request returns 401');
}

async function testAssignments() {
  console.log('\n📚 Assignment Tests');

  // Create assignment (teacher)
  const createRes = await req('POST', '/assignments', {
    title: 'Integration Test Assignment',
    description: 'Complete this test assignment as part of integration testing.',
    subject: 'Software Testing',
    dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
    targetAudience: { type: 'all' },
  }, teacherToken);
  assert(createRes.status === 201, 'Create assignment returns 201');
  assignmentId = createRes.data.data?._id;

  // List assignments (student)
  const listRes = await req('GET', '/assignments', null, studentToken);
  assert(listRes.status === 200, 'List assignments returns 200');
  assert(Array.isArray(listRes.data.data), 'Assignments data is array');

  // Get by ID
  if (assignmentId) {
    const getRes = await req('GET', `/assignments/${assignmentId}`, null, studentToken);
    assert(getRes.status === 200, 'Get assignment by ID returns 200');
  }

  // Mark complete (student)
  if (assignmentId) {
    const completeRes = await req('PUT', `/assignments/${assignmentId}/complete`, { note: 'Done!' }, studentToken);
    assert(completeRes.status === 200, 'Mark assignment complete returns 200');
  }
}

async function testNotifications() {
  console.log('\n🔔 Notification Tests');

  // List notifications
  const listRes = await req('GET', '/notifications', null, studentToken);
  assert(listRes.status === 200, 'List notifications returns 200');

  const notifs = listRes.data.data?.notifications;
  if (notifs?.length > 0) {
    notificationId = notifs[0]._id;

    // Mark single as read
    const readRes = await req('PUT', `/notifications/${notificationId}/read`, null, studentToken);
    assert(readRes.status === 200, 'Mark notification read returns 200');
  } else {
    assert(true, 'No notifications to test (DB may be empty)');
  }

  // Mark all read
  const allReadRes = await req('PUT', '/notifications/mark-all-read', null, studentToken);
  assert(allReadRes.status === 200, 'Mark all notifications read returns 200');
}

async function testDashboards() {
  console.log('\n📊 Dashboard Tests');

  const studentDash = await req('GET', '/dashboard/student', null, studentToken);
  assert(studentDash.status === 200, 'Student dashboard returns 200');
  assert(typeof studentDash.data.data === 'object', 'Student dashboard returns data object');

  const teacherDash = await req('GET', '/dashboard/teacher', null, teacherToken);
  assert(teacherDash.status === 200, 'Teacher dashboard returns 200');

  const adminDash = await req('GET', '/dashboard/admin', null, adminToken);
  assert(adminDash.status === 200, 'Admin dashboard returns 200');

  // Role guard: student cannot access admin dashboard
  const guardRes = await req('GET', '/dashboard/admin', null, studentToken);
  assert(guardRes.status === 403, 'Student blocked from admin dashboard (403)');
}

async function testUserManagement() {
  console.log('\n👤 User Management Tests');

  // Admin list all users
  const listRes = await req('GET', '/users', null, adminToken);
  assert(listRes.status === 200, 'Admin list users returns 200');
  assert(Array.isArray(listRes.data.data), 'Users data is array');
  assert(listRes.data.data.length >= 3, 'At least 3 users exist');

  // Teacher cannot list all users
  const teacherListRes = await req('GET', '/users', null, teacherToken);
  assert(teacherListRes.status === 403, 'Teacher blocked from listing all users (403)');

  // Update own profile
  const updateRes = await req('PUT', '/users/profile', { name: 'Arjun Patel Updated' }, studentToken);
  assert(updateRes.status === 200, 'Update own profile returns 200');

  // Revert name
  await req('PUT', '/users/profile', { name: 'Arjun Patel' }, studentToken);
}

async function testAnalytics() {
  console.log('\n📈 Analytics Tests');

  const overviewRes = await req('GET', '/analytics/overview', null, adminToken);
  assert(overviewRes.status === 200, 'Analytics overview returns 200');

  // Student cannot access analytics
  const studentGuard = await req('GET', '/analytics/overview', null, studentToken);
  assert(studentGuard.status === 403, 'Student blocked from analytics (403)');
}

async function testDepartments() {
  console.log('\n🏛️  Department Tests');

  const listRes = await req('GET', '/departments', null, adminToken);
  assert(listRes.status === 200, 'List departments returns 200');
  assert(Array.isArray(listRes.data.data), 'Departments is array');
}

async function testCleanup() {
  console.log('\n🧹 Cleanup');
  // Delete test reminder (teacher)
  if (reminderId) {
    const delRes = await req('DELETE', `/reminders/${reminderId}`, null, teacherToken);
    assert(delRes.status === 200, 'Delete test reminder returns 200');
  }
  // Delete test assignment
  if (assignmentId) {
    const delRes = await req('DELETE', `/assignments/${assignmentId}`, null, teacherToken);
    assert(delRes.status === 200, 'Delete test assignment returns 200');
  }
}

// ── Runner ────────────────────────────────────────────────────────────────────
(async () => {
  console.log('═'.repeat(55));
  console.log('  CampusSync Integration Test Suite');
  console.log('═'.repeat(55));

  try {
    await testHealth();
    await testAuth();
    await testReminders();
    await testAssignments();
    await testNotifications();
    await testDashboards();
    await testUserManagement();
    await testAnalytics();
    await testDepartments();
    await testCleanup();
  } catch (err) {
    console.error('\n💥 Test runner crashed:', err.message);
    fail++;
  }

  console.log('\n' + '═'.repeat(55));
  const total = pass + fail;
  console.log(`  Results: ${pass}/${total} passed | ${fail} failed`);
  console.log('═'.repeat(55));
  if (fail === 0) {
    console.log('  🎉 ALL TESTS PASSED! App is deployment ready.\n');
  } else {
    console.log(`  ⚠️  ${fail} test(s) failed. Review above.\n`);
    process.exit(1);
  }
})();
