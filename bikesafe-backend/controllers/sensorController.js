const SensorHistory = require('../models/SensorHistory'); // היסטוריית חיישנים
const Sensor = require('../models/Sensor'); // מודל חיישן
const Location = require('../models/Location'); // מיקומים ואזורי בטיחות
const mongoose = require('mongoose');
const { sendAlert } = require('./alertController'); // ✅ ייבוא פונקציה לשליחת התראות

// ✅ פונקציה לבדיקת יציאה מהאזור הבטוח
const checkIfOutsideSafeZone = async (userId, latitude, longitude) => {
    const location = await Location.findOne({ userId });

    if (!location || !location.safeZone || !location.safeZone.center) {
        return false; // אם אין אזור בטוח מוגדר, אין צורך לשלוח התראה
    }

    const { center, radius } = location.safeZone;
    const distance = getDistance({ latitude, longitude }, center);
    
    return distance > radius; // אם המרחק חורג מהרדיוס, יש לשלוח התראה
};

// ✅ חישוב מרחק בין שתי נקודות גיאוגרפיות (נוסחת הווינסיין)
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
exports.getSensorData = async (req, res) => {
  const { userId, type } = req.query;

  try {
      const sensor = await Sensor.findOne({ userId, type });

      if (!sensor || !sensor.data) {
          return res.status(404).json({ message: "Sensor data not found" });
      }

      res.status(200).json(sensor.data); // מחזירים רק את הנתונים של החיישן
  } catch (error) {
      console.error("Error fetching sensor data:", error);
      res.status(500).json({ error: error.message });
  }
};
// ✅ יצירת חיישן חדש
exports.createSensor = async (req, res) => {
    try {
        console.log("Incoming request body:", req.body);

        const { userId, sensorId, type, data } = req.body;

        if (!userId || !sensorId || !type || !data) {
            return res.status(400).json({ message: 'Missing required fields' });
        }

        if (!mongoose.Types.ObjectId.isValid(userId)) {
            return res.status(400).json({ message: 'Invalid userId format' });
        }
        
        // בדיקה אם החיישן כבר קיים
        const existingSensor = await Sensor.findOne({ userId, type });
          if (existingSensor) {
            return res.status(400).json({ message: 'A sensor of this type already exists for this user' });
          }

        const sensor = new Sensor({
            userId: new mongoose.Types.ObjectId(userId),
            sensorId,
            type,
            data: {
                temperature: type === "temperature" ? data.temperature : undefined,
                latitude: type === "gps" ? data.latitude : undefined,
                longitude: type === "gps" ? data.longitude : undefined,
                batteryLevel: type === "battery" ? data.batteryLevel : undefined,
                humidity: type === "humidity" ? data.humidity : undefined
            }
        });

        await sensor.save();
        res.status(201).json({ message: 'Sensor created successfully', sensor });
    } catch (error) {
        console.error('Error creating sensor:', error);
        res.status(500).json({ message: 'Failed to create sensor', error });
    }
};

// ✅ עדכון נתוני חיישן + בדיקות התראה
const checkSensorFailure = async (sensor) => {
  const lastUpdate = new Date(sensor.lastUpdated);
  const now = new Date();
  const diffMinutes = (now - lastUpdate) / (1000 * 60);

  if (diffMinutes > 10) { // חיישן לא מעדכן יותר מ-10 דקות
      await sendAlert(sensor.userId, 'sensor-failure', `Sensor ${sensor.sensorId} has stopped responding.`);
  }
};

// ✅ עדכון נתוני חיישן עם תמיכה בהתראות נוספות
exports.updateSensorData = async (req, res) => {
  const { sensorId, data } = req.body;

  try {
      let sensor = await Sensor.findOne({ sensorId });

      if (!sensor) {
          return res.status(404).json({ message: "Sensor not found" });
      }

      // בדיקה אם החיישן חדל לעדכן נתונים לזמן ממושך
      await checkSensorFailure(sensor);

      if (sensor.type === "temperature" && data.temperature !== undefined) {
          sensor.data.temperature = data.temperature;

          if (data.temperature > 60) {
              await sendAlert(sensor.userId, 'temperature', `Warning: High temperature detected (${data.temperature}°C)!`);
          }

          // אם הטמפרטורה עולה מעל 80°C, מכבים את הסוללה
          if (data.temperature > 80) {
              await sendAlert(sensor.userId, 'battery', `Battery shut down due to extreme heat (${data.temperature}°C).`);
          }
      }

      if (sensor.type === "gps" && data.latitude !== undefined && data.longitude !== undefined) {
        console.log(`Updating GPS sensor: ${sensorId}, New Location: ${data.latitude}, ${data.longitude}`);
        sensor.data.latitude = data.latitude;
        sensor.data.longitude = data.longitude;
    
        let location = await Location.findOne({ userId: sensor.userId });
        if (!location) {
            console.log(`Creating new location entry for user ${sensor.userId}`);
            location = new Location({
                userId: sensor.userId,
                currentLocation: { latitude: data.latitude, longitude: data.longitude }
            });
        } else {
            console.log(`Updating existing location for user ${sensor.userId}`);
            location.currentLocation = { latitude: data.latitude, longitude: data.longitude };
        }
        await location.save();
    }

      if (sensor.type === "battery" && data.batteryLevel !== undefined) {
          sensor.data.batteryLevel = data.batteryLevel;

          if (data.batteryLevel < 10) {
              await sendAlert(sensor.userId, 'battery', 'Battery is critically low!');
          }
      }

      sensor.lastUpdated = Date.now();
      await sensor.save();

      res.status(200).json({ message: "Sensor data updated", sensor });
  } catch (error) {
      console.error("Error updating sensor data:", error);
      res.status(500).json({ error: error.message });
  }
};

// ✅ בדיקת חיבור או ניתוק GPS
exports.checkGPSConnection = async (req, res) => {
  const { sensorId, status } = req.body; // status יכול להיות "connected" או "disconnected"

  try {
      let sensor = await Sensor.findOne({ sensorId });

      if (!sensor) {
          return res.status(404).json({ message: "Sensor not found" });
      }

      if (sensor.type !== "gps") {
          return res.status(400).json({ message: "This sensor is not a GPS sensor" });
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
const updateMockSensorsForUser = async (userId) => {
  const sensors = await Sensor.find({ userId });

  for (let sensor of sensors) {
      const newData = generateRandomData(sensor.type);
      sensor.data = { ...sensor.data, ...newData };
      sensor.lastUpdated = new Date();
      await sensor.save();

      console.log(`🔄 Updating mock data for sensor: ${sensor.sensorId}, type: ${sensor.type}`);
      
      // ✅ אם זה חיישן GPS - עדכן גם את `Location`
      if (sensor.type === "gps") {
          let location = await Location.findOne({ userId: sensor.userId });
          
          if (!location) {
              console.log(`🆕 Creating new location entry for user ${sensor.userId}`);
              location = new Location({
                  userId: sensor.userId,
                  currentLocation: { latitude: newData.latitude, longitude: newData.longitude }
              });
          } else {
              console.log(`🛠 Updating existing location for user ${sensor.userId}, New Location: ${newData.latitude}, ${newData.longitude}`);
              location.currentLocation = { latitude: newData.latitude, longitude: newData.longitude };
          }
          await location.save();
      }

      await new SensorHistory({
          userId: sensor.userId,
          sensorId: sensor.sensorId,
          type: sensor.type,
          data: sensor.data
      }).save();
  }

  console.log(`✅ Mock sensor data updated for user: ${userId}`);
};
const generateRandomData = (sensorType) => {
  switch (sensorType) {
      case "temperature":
          return { temperature: (Math.random() * 40 + 10).toFixed(1) }; // 10°C - 50°C
      case "gps":
          return {
              latitude: (32.015 + Math.random() * 0.01).toFixed(6), // שינויים קטנים
              longitude: (34.752 + Math.random() * 0.01).toFixed(6),
          };
      case "battery":
          return { batteryLevel: Math.floor(Math.random() * 100) }; // 0% - 100%
      case "humidity":
          return { humidity: (Math.random() * 50 + 30).toFixed(1) }; // 30% - 80%
      default:
          return {};
  }
};
// ✅ פונקציה לריצת עדכון חיישנים עבור משתמש ספציפי לפי `userId`
exports.triggerMockUpdateForUser = async (req, res) => {
  const { userId } = req.body;

  if (!userId) {
      return res.status(400).json({ message: "User ID is required" });
  }

  try {
      await updateMockSensorsForUser(userId);
      res.status(200).json({ message: "Mock sensor data updated successfully!" });
  } catch (error) {
      console.error("Error updating mock sensor data:", error);
      res.status(500).json({ error: error.message });
  }
};
// ✅ שליפת היסטוריית חיישן
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