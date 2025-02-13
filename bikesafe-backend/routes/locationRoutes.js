//bikesafe-backend/routes/locationRoutes.js
const express = require('express');
const router = express.Router();
const locationController = require('../controllers/locationController');
const authMiddleware = require('../middleware/authMiddleware');

router.post('/update', authMiddleware, locationController.updateLocation);
router.get('/realtime', authMiddleware, locationController.getRealtimeLocation);
router.post('/safe-zone', authMiddleware, locationController.setSafeZone);
router.get('/safe-zone', authMiddleware, locationController.getSafeZone);
module.exports = router;