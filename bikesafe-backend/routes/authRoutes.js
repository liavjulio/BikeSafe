//bikesafe-backend/routes/authRoutes.js
const express = require('express');
const router = express.Router();
const { register, login } = require('../controllers/authController');
const { linkSensor } = require('../controllers/userController');
const userController = require('../controllers/userController');
const authController = require('../controllers/authController');
const { verifyCode } = require('../controllers/authController');
const authMiddleware = require('../middleware/authMiddleware');

router.post('/verify-code-and-reset-password', authController.verifyCodeForPasswordReset);
router.post('/register', register);
router.post('/login', login);
// User Profile Routes
router.get('/user/:userId', authMiddleware, authController.getUserProfile);  // Fetch profile
router.put('/user/:userId', authMiddleware, authController.updateUserProfile); // Update profile
router.delete('/delete-account/:userId', authMiddleware, authController.deleteUserAccount); // Delete account
router.put('/user/change-password/:userId', authMiddleware, authController.changePassword);
router.post('/forgot-password', authController.forgotPassword); 
router.post('/verify-code', authController.verifyCode);
router.post('/feedback', authMiddleware, userController.submitFeedback);
module.exports = router;