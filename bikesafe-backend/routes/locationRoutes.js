const express = require('express');
const router = express.Router();
const locationController = require('../controllers/locationController');
const authMiddleware = require('../middleware/authMiddleware');

router.post('/update', authMiddleware,locationController.updateLocation);
router.get('/realtime', authMiddleware,locationController.getRealtimeLocation);
router.post('/safe-zone', authMiddleware,locationController.setSafeZone);
router.post('/alert', authMiddleware,locationController.checkSafeZone);
router.post('/battery', authMiddleware, locationController.updateBattery);
module.exports = router;