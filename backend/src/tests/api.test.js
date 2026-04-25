async function testLogin() {
  try {
    const response = await fetch('http://localhost:5000/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'admin@campussync.edu',
        password: 'Admin@123'
      })
    });
    const data = await response.json();
    if (response.ok) {
      console.log('✅ Login Successful!');
      console.log('User Role:', data.data.user.role);
      console.log('Access Token exists:', !!data.data.accessToken);
    } else {
      console.error('❌ Login Failed:', data.message);
    }
  } catch (error) {
    console.error('❌ Request Error:', error.message);
  }
}

testLogin();
