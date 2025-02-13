// bikesafe-backend/models/Sensor.js
const mongoose = require('mongoose');

const sensorSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  sensorId: { type: String, required: true, unique: true }, 
  type: { type: String, enum: ['temperature', 'gps', 'battery', 'humidity'], required: true },
  data: {
    temperature: { type: Number },
    latitude: { type: Number },
    longitude: { type: Number },
    batteryLevel: { type: Number },
    humidity: { type: Number }
  },
  lastUpdated: { type: Date, default: Date.now }
});

const Sensor = mongoose.model('Sensor', sensorSchema);
module.exports = Sensor;