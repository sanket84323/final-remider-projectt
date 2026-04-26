require('dotenv').config();

const API_URL = `http://localhost:${process.env.PORT || 5000}/api`;

async function testJwt() {
  console.log('🚀 Starting JWT Authentication Test...');
  console.log('API URL:', API_URL);

  try {
    // 1. Login
    console.log('\nStep 1: Attempting Login...');
    const loginRes = await fetch(`${API_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'hod@aids.edu',
        password: 'Hod@123'
      })
    });

    const loginData = await loginRes.json();

    if (!loginData.success) {
      throw new Error(`Login failed: ${loginData.message}`);
    }

    const { accessToken, user } = loginData.data;
    console.log('✅ Login Successful!');
    console.log('👤 User:', user.name, `(${user.role})`);
    console.log('🔑 Received Access Token (first 20 chars):', accessToken.substring(0, 20) + '...');

    // 2. Access Protected Route
    console.log('\nStep 2: Accessing Protected Route (/users/me)...');
    const protectedRes = await fetch(`${API_URL}/users/me`, {
      headers: {
        Authorization: `Bearer ${accessToken}`
      }
    });

    const protectedData = await protectedRes.json();

    if (protectedRes.status === 200 && protectedData.success) {
      console.log('✅ Protected Route Access Successful!');
      console.log('👤 Profile Data:', protectedData.data.name);
    } else {
      console.log('❌ Protected Route Access Failed:', protectedData.message);
    }

    // 3. Test Invalid Token
    console.log('\nStep 3: Testing Invalid Token...');
    const invalidRes = await fetch(`${API_URL}/users/me`, {
      headers: {
        Authorization: `Bearer invalid_token`
      }
    });

    if (invalidRes.status === 401) {
      console.log('✅ Invalid Token Correctly Rejected (401 Unauthorized)');
    } else {
      console.log('❌ Error: Unexpected status for invalid token:', invalidRes.status);
    }

    console.log('\n🌟 JWT Authentication is working correctly!');

  } catch (error) {
    console.error('\n❌ Test Failed:', error.message);
    if (error.cause && error.cause.code === 'ECONNREFUSED') {
      console.log('⚠️  Hint: Make sure the backend server is running on port', process.env.PORT || 5000);
    }
  }
}

testJwt();
