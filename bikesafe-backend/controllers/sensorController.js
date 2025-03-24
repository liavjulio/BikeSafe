const SensorHistory = require('../models/SensorHistory'); 
const Sensor = require('../models/Sensor'); 
const Location = require('../models/Location'); 
const mongoose = require('mongoose');
const { sendAlert } = require('./alertController'); 

const checkIfOutsideSafeZone = async (userId, latitude, longitude) => {
    const location = await Location.findOne({ userId });

    if (!location || !location.safeZone || !location.safeZone.center) {
        return false; 
    }

    const { center, radius } = location.safeZone;
    const distance = getDistance({ latitude, longitude }, center);
    
    return distance > radius;
};

const getDistance = (location1, location2) => {
    const toRad = (value) => (value * Math.PI) / 180;
    
    const R = 6371e3; // רדיוס כדור הארץ במטרים
    const lat1 = toRad(location1.latitude);
    const lat2 = toRad(location2.latitude);
    const deltaLat = toRad(location2.latitude - location1.latitude);
    const deltaLon = toRad(location2.longitude - location1.longitude);

    const a =
        Math.sin(deltaLat / 2) * Math.sin(deltaLat / 2) +
        Math.cos(lat1) * Math.cos(lat2) * Math.sin(deltaLon / 2) * Math.sin(deltaLon / 2);

    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
};

// ✅ שליפת נתוני סנסור ע"י userId
exports.getSensorData = async (req, res) => {
    const { userId } = req.query;

    try {
        const sensor = await Sensor.findOne({ userId });

        if (!sensor || !sensor.data) {
            return res.status(404).json({ message: "Sensor data not found" });
        }

        res.status(200).json(sensor.data);
    } catch (error) {
        console.error("Error fetching sensor data:", error);
        res.status(500).json({ error: error.message });
    }
};

// ✅ יצירת סנסור חדש
exports.createSensor = async (req, res) => {
    try {
        const { userId, sensorId, data } = req.body;

        if (!userId || !sensorId) {
            return res.status(400).json({ message: 'Missing required fields (userId or sensorId)' });
        }

        if (!mongoose.Types.ObjectId.isValid(userId)) {
            return res.status(400).json({ message: 'Invalid userId format' });
        }

        const existingSensor = await Sensor.findOne({ userId, sensorId });
        if (existingSensor) {
            return res.status(400).json({ message: 'A sensor with this ID already exists for this user' });
        }

        const sensor = new Sensor({
            userId: new mongoose.Types.ObjectId(userId),
            sensorId,
            data: data || {},
            lastUpdated: Date.now()
        });

        await sensor.save();
        res.status(201).json({ message: 'Sensor created successfully', sensor });
    } catch (error) {
        console.error('Error creating sensor:', error);
        res.status(500).json({ message: 'Failed to create sensor', error });
    }
};

// ✅ בדיקת כשלון חיישן (לא מעדכן בזמן)
const checkSensorFailure = async (sensor) => {
    const lastUpdate = new Date(sensor.lastUpdated);
    const now = new Date();
    const diffMinutes = (now - lastUpdate) / (1000 * 60);

    if (diffMinutes > 10) {
        await sendAlert(sensor.userId, 'sensor-failure', `Sensor ${sensor.sensorId} has stopped responding.`);
    }
};

// ✅ עדכון נתוני חיישן
exports.updateSensorData = async (req, res) => {
    const { sensorId, data } = req.body;

    try {
        let sensor = await Sensor.findOne({ sensorId });

        if (!sensor) {
            console.log("Sensor not found! Auto-creating sensor...");

            sensor = new Sensor({
                userId: req.user.id,
                sensorId,
                data: {},
                lastUpdated: Date.now()
            });

            await sensor.save();
        }

        await checkSensorFailure(sensor);

        // Update fields based on data sent
        if (data.temperature !== undefined) {
            sensor.data.temperature = data.temperature;

            if (data.temperature > 60) {
                await sendAlert(sensor.userId, 'temperature', `Warning: High temperature detected (${data.temperature}°C)!`);
            }

            if (data.temperature > 80) {
                await sendAlert(sensor.userId, 'battery', `Battery shut down due to extreme heat (${data.temperature}°C).`);
            }
        }

        if (data.latitude !== undefined && data.longitude !== undefined) {
            sensor.data.latitude = data.latitude;
            sensor.data.longitude = data.longitude;

            let location = await Location.findOne({ userId: sensor.userId });
            if (!location) {
                location = new Location({
                    userId: sensor.userId,
                    currentLocation: { latitude: data.latitude, longitude: data.longitude }
                });
            } else {
                location.currentLocation = { latitude: data.latitude, longitude: data.longitude };
            }

            await location.save();

            const outsideSafeZone = await checkIfOutsideSafeZone(sensor.userId, data.latitude, data.longitude);
            if (outsideSafeZone) {
                await sendAlert(sensor.userId, 'safe-zone', `Device is outside the safe zone!`);
            }
        }

        if (data.batteryLevel !== undefined) {
            sensor.data.batteryLevel = data.batteryLevel;

            if (data.batteryLevel < 10) {
                await sendAlert(sensor.userId, 'battery', 'Battery is critically low!');
            }
        }

        if (data.humidity !== undefined) {
            sensor.data.humidity = data.humidity;
        }

        sensor.lastUpdated = Date.now();
        await sensor.save();

const now = Date.now();

const lastSaved = sensor.lastSavedToHistory
  ? new Date(sensor.lastSavedToHistory).getTime()
  : 0; // 0 makes sure we always save the first time

if (now - lastSaved >= 30 * 1000) {
  await new SensorHistory({
    userId: sensor.userId,
    sensorId: sensor.sensorId,
    data: sensor.data,
    timestamp: new Date()
  }).save();

  sensor.lastSavedToHistory = new Date(now);
  await sensor.save();

  console.log(`✅ Sensor history saved at ${new Date(now).toISOString()}`);
} else {
  console.log(`⏳ Skipped save. Next allowed save at ${new Date(lastSaved + 30 * 1000).toISOString()}`);
}
        res.status(200).json({ message: "Sensor data updated", sensor });
    } catch (error) {
        console.error("Error updating sensor data:", error);
        res.status(500).json({ error: error.message });
    }
};

exports.checkGPSConnection = async (req, res) => {
    const { sensorId, status } = req.body;

    try {
        let sensor = await Sensor.findOne({ sensorId });

        if (!sensor) {
            return res.status(404).json({ message: "Sensor not found" });
        }

        if (status === "disconnected") {
            await sendAlert(sensor.userId, 'gps', 'GPS sensor has lost connection!');
        } else if (status === "connected") {
            await sendAlert(sensor.userId, 'gps', 'GPS sensor is back online.');
        }

        res.status(200).json({ message: `GPS connection updated: ${status}` });
    } catch (error) {
        console.error("Error updating GPS connection:", error);
        res.status(500).json({ error: error.message });
    }
};

// ✅ שליפת כל החיישנים של משתמש
exports.getAllSensorsForUser = async (req, res) => {
    const { userId } = req.query;

    try {
        const sensors = await Sensor.find({ userId });

        if (!sensors.length) {
            return res.status(404).json({ message: "No sensors found for this user" });
        }

        res.status(200).json(sensors);
    } catch (error) {
        console.error("Error fetching sensor data:", error);
        res.status(500).json({ error: error.message });
    }
};

// ✅ מחיקת חיישן
exports.deleteSensor = async (req, res) => {
    const { sensorId } = req.params;

    try {
        const sensor = await Sensor.findOneAndDelete({ sensorId });

        if (!sensor) {
            return res.status(404).json({ message: "Sensor not found" });
        }

        res.status(200).json({ message: "Sensor deleted successfully", sensor });
    } catch (error) {
        console.error("Error deleting sensor:", error);
        res.status(500).json({ error: error.message });
    }
};

// ✅ שליפת היסטוריית נתוני סנסור
exports.getSensorHistory = async (req, res) => {
    const { userId, sensorId, startDate, endDate } = req.query;

    try {
        let query = { userId };

        if (sensorId) query.sensorId = sensorId;
        if (startDate && endDate) {
            query.timestamp = { $gte: new Date(startDate), $lte: new Date(endDate) };
        }

        const history = await SensorHistory.find(query).sort({ timestamp: -1 });

        if (!history.length) {
            return res.status(404).json({ message: "No sensor history found for this user" });
        }

        res.status(200).json(history);
    } catch (error) {
        console.error("Error fetching sensor history:", error);
        res.status(500).json({ error: error.message });
    }
};
exports.deleteAllSensorHistoryForUser = async (req, res) => {
    const { userId } = req.params;
  
    if (!userId) {
      return res.status(400).json({ message: 'User ID is required' });
    }
  
    try {
      const result = await SensorHistory.deleteMany({ userId });
  
      if (result.deletedCount === 0) {
        return res.status(404).json({ message: 'No sensor history found to delete' });
      }
  
      res.status(200).json({ message: `Deleted ${result.deletedCount} sensor history records for user` });
    } catch (error) {
      console.error("Error deleting all sensor history:", error);
      res.status(500).json({ error: error.message });
    }
  };
  exports.deleteSensorHistoryById = async (req, res) => {
    const { historyId } = req.params;
  
    if (!historyId) {
      return res.status(400).json({ message: 'History ID is required' });
    }
  
    try {
      const result = await SensorHistory.findByIdAndDelete(historyId);
  
      if (!result) {
        return res.status(404).json({ message: 'Sensor history entry not found' });
      }
  
      res.status(200).json({ message: 'Sensor history entry deleted successfully', deletedEntry: result });
    } catch (error) {
      console.error("Error deleting sensor history by ID:", error);
      res.status(500).json({ error: error.message });
    }
  };