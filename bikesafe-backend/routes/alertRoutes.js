//bikesafe-backend/routes/alertRoutes.js
const express = require('express');
const router = express.Router();
const alertController = require('../controllers/alertController');
const authMiddleware = require('../middleware/authMiddleware');

router.post('/preferences', authMiddleware, alertController.updateAlertPreferences);
router.get('/preferences', authMiddleware, alertController.getAlertPreferences);
router.post('/send', authMiddleware, alertController.sendAlert);
router.post('/save-token', authMiddleware, alertController.saveDeviceToken);
module.exports = router;