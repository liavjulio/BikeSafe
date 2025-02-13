//bikesafe-backend/routes/sensorRoutes.js
const express = require('express');
const router = express.Router();
const sensorController = require('../controllers/sensorController.js');
const authMiddleware = require('../middleware/authMiddleware');

router.get('/data', authMiddleware, sensorController.getSensorData);
router.post('/create', authMiddleware, sensorController.createSensor);
router.post('/update', authMiddleware, sensorController.updateSensorData);  
router.get('/alldata', authMiddleware, sensorController.getAllSensorsForUser);
router.delete('/delete/:sensorId', authMiddleware, sensorController.deleteSensor);
router.post('/update-mock', authMiddleware, sensorController.triggerMockUpdateForUser);
router.get('/history', authMiddleware, sensorController.getSensorHistory);

module.exports = router;