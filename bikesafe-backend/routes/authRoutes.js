const express = require('express');
const router = express.Router();
const { register, login } = require('../controllers/authController');
const { linkSensor } = require('../controllers/userController');
const authController = require('../controllers/authController');
const { verifyCode } = require('../controllers/authController');

router.post('/verify-code-and-reset-password', authController.verifyCodeForPasswordReset);
router.post('/link-sensor', linkSensor);
router.post('/register', register);
router.post('/login', login);
router.post('/forgot-password', authController.forgotPassword); 
router.post('/verify-code', authController.verifyCode);
module.exports = router;