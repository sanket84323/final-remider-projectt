const router = require('express').Router();
const { login, refreshToken, logout, forgotPassword, register, getDemoCredentials, changePassword } = require('../controllers/auth.controller');
const { loginValidation, registerValidation } = require('../middleware/validate.middleware');
const { authenticate } = require('../middleware/auth.middleware');

router.get('/demo-credentials', getDemoCredentials);
router.post('/login', loginValidation, login);
router.post('/register', registerValidation, register);
router.post('/refresh', refreshToken);
router.post('/logout', authenticate, logout);
router.post('/change-password', authenticate, changePassword);
router.post('/forgot-password', forgotPassword);

module.exports = router;
