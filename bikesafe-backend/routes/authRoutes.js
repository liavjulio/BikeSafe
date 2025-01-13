const express = require('express');
const router = express.Router();
const { register, login, resetPassword } = require('../controllers/authController');
const { linkSensor } = require('../controllers/userController');
const authController = require('../controllers/authController');

router.post('/link-sensor', linkSensor);
router.post('/register', register);
router.post('/login', login);
router.post('/forgot-password', authController.forgotPassword); 

module.exports = router;