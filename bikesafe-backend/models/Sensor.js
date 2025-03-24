// bikesafe-backend/models/Sensor.js
const mongoose = require('mongoose');

const sensorSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  sensorId: { type: String, required: true, unique: true }, 
  data: {
    temperature: { type: Number },
    latitude: { type: Number },
    longitude: { type: Number },
    batteryLevel: { type: Number },
    humidity: { type: Number }
  },
  lastUpdated: { type: Date, default: Date.now },
  lastSavedToHistory: { type: Date, default: null } // ✅ ADD THIS

});

const Sensor = mongoose.model('Sensor', sensorSchema);
module.exports = Sensor;