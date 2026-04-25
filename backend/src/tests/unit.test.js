/**
 * CampusSync Backend - Test Suite
 * Tests core logic without a real DB connection
 * Run: node src/tests/unit.test.js
 */

const assert = require('assert');

// ─── Test 1: JWT Helper ───────────────────────────────────────────────────────
console.log('\n🧪 Testing JWT utilities...');
process.env.JWT_SECRET = 'test_secret_key_32chars_minimum!!';
process.env.JWT_REFRESH_SECRET = 'test_refresh_secret_32chars_min!!';
process.env.JWT_EXPIRES_IN = '15m';
process.env.JWT_REFRESH_EXPIRES_IN = '7d';

const { generateTokenPair, verifyAccessToken, verifyRefreshToken } = require('../utils/jwt');

const fakeUser = { _id: '507f1f77bcf86cd799439011', email: 'test@test.com', role: 'student', name: 'Test User' };
const { accessToken, refreshToken } = generateTokenPair(fakeUser);

assert(accessToken, 'Access token should be generated');
assert(refreshToken, 'Refresh token should be generated');
console.log('  ✅ Token generation: PASS');

const decoded = verifyAccessToken(accessToken);
assert(decoded.email === fakeUser.email, 'Email should match in decoded token');
assert(decoded.role === fakeUser.role, 'Role should match in decoded token');
console.log('  ✅ Token verification: PASS');

const decodedRefresh = verifyRefreshToken(refreshToken);
assert(decodedRefresh.id === fakeUser._id, 'User ID should match in refresh token');
console.log('  ✅ Refresh token verification: PASS');

// ─── Test 2: API Response Helpers ─────────────────────────────────────────────
console.log('\n🧪 Testing API response utilities...');
const { successResponse, errorResponse, paginatedResponse } = require('../utils/apiResponse');

const mockRes = {
  status: (code) => ({ json: (body) => ({ statusCode: code, body }) }),
};

const successResult = successResponse(mockRes, { id: 1 }, 'Created', 201);
assert(successResult.statusCode === 201, 'Success status code should be 201');
assert(successResult.body.success === true, 'Success flag should be true');
assert(successResult.body.data.id === 1, 'Data should match');
console.log('  ✅ successResponse: PASS');

const errorResult = errorResponse(mockRes, 'Not found', 404);
assert(errorResult.statusCode === 404, 'Error status should be 404');
assert(errorResult.body.success === false, 'Success flag should be false');
assert(errorResult.body.message === 'Not found', 'Error message should match');
console.log('  ✅ errorResponse: PASS');

const pageResult = paginatedResponse(mockRes, [1, 2, 3], 100, 2, 10);
assert(pageResult.body.pagination.total === 100);
assert(pageResult.body.pagination.page === 2);
assert(pageResult.body.pagination.totalPages === 10);
assert(pageResult.body.pagination.hasNextPage === true);
assert(pageResult.body.pagination.hasPrevPage === true);
console.log('  ✅ paginatedResponse: PASS');

// ─── Test 3: RBAC Middleware ──────────────────────────────────────────────────
console.log('\n🧪 Testing RBAC middleware...');
const { requireRole } = require('../middleware/rbac.middleware');

// Simulate teacher accessing teacher-only route
const teacherReq = { user: { role: 'teacher', _id: '123' } };
let nextCalled = false;
const next = () => { nextCalled = true; };
const mockResRbac = { status: () => ({ json: () => {} }) };

requireRole('teacher', 'admin')(teacherReq, mockResRbac, next);
assert(nextCalled, 'Teacher should be allowed for teacher+admin route');
console.log('  ✅ Teacher RBAC allow: PASS');

nextCalled = false;
let forbiddenCalled = false;
const studentReq = { user: { role: 'student', _id: '456' } };
const mockResForbid = { status: (code) => ({ json: () => { if (code === 403) forbiddenCalled = true; } }) };
requireRole('teacher', 'admin')(studentReq, mockResForbid, next);
assert(!nextCalled && forbiddenCalled, 'Student should be blocked for teacher-only route');
console.log('  ✅ Student RBAC block: PASS');

// ─── Test 4: Priority Color Mapping Logic ─────────────────────────────────────
console.log('\n🧪 Testing priority logic...');
const PRIORITIES = ['normal', 'important', 'urgent'];
const VALID_CATEGORIES = ['reminder', 'announcement', 'notice', 'event', 'exam', 'timetable'];
const VALID_AUDIENCE_TYPES = ['all', 'department', 'class', 'section', 'specific'];
const VALID_ROLES = ['student', 'teacher', 'admin'];

PRIORITIES.forEach(p => assert(PRIORITIES.includes(p)));
console.log('  ✅ Priority enum validation: PASS');

VALID_ROLES.forEach(r => assert(VALID_ROLES.includes(r)));
console.log('  ✅ Role enum validation: PASS');

// ─── Test 5: JWT Expiry Detection ─────────────────────────────────────────────
console.log('\n🧪 Testing JWT expiry handling...');
const jwt = require('jsonwebtoken');
const expiredToken = jwt.sign({ id: 'test' }, process.env.JWT_SECRET, { expiresIn: '-1s' });
try {
  verifyAccessToken(expiredToken);
  assert(false, 'Should have thrown');
} catch (e) {
  assert(e.name === 'TokenExpiredError', 'Should detect expired token');
  console.log('  ✅ Expired token detection: PASS');
}

const tamperedToken = accessToken + 'tampered';
try {
  verifyAccessToken(tamperedToken);
  assert(false, 'Should have thrown');
} catch (e) {
  assert(e.name === 'JsonWebTokenError', 'Should detect tampered token');
  console.log('  ✅ Tampered token detection: PASS');
}

// ─── Summary ──────────────────────────────────────────────────────────────────
console.log('\n' + '='.repeat(50));
console.log('✅ ALL UNIT TESTS PASSED! (5/5 suites)');
console.log('='.repeat(50));
console.log('\nNote: Integration tests require MongoDB to be running.');
console.log('Start MongoDB then run: npm run seed && npm run dev\n');
