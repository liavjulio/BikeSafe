const express = require('express');
const router = express.Router();
const { register, login } = require('../controllers/authController');
const { linkSensor } = require('../controllers/userController');
const userController = require('../controllers/userController');
const authController = require('../controllers/authController');
const { verifyCode } = require('../controllers/authController');
const authMiddleware = require('../middleware/authMiddleware');

router.post('/verify-code-and-reset-password', authController.verifyCodeForPasswordReset);
router.post('/link-sensor', linkSensor);
router.post('/register', register);
router.post('/login', login);
router.post('/forgot-password', authController.forgotPassword); 
router.post('/verify-code', authController.verifyCode);
router.post('/update-alerts', authMiddleware, userController.updateAlertPreferences);
router.post('/feedback', authMiddleware, userController.submitFeedback);
router.get('/alert-preferences/:userId', authMiddleware, userController.getAlertPreferences);
module.exports = router;