//bikesafe-backend/models/SensorHistory.js
const mongoose = require('mongoose');

const sensorHistorySchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  sensorId: { type: String, required: true },
  type: { type: String, required: true }, // סוג החיישן (טמפרטורה, GPS, סוללה וכו')
  data: {
    temperature: { type: Number },
    latitude: { type: Number },
    longitude: { type: Number },
    batteryLevel: { type: Number },
    humidity: { type: Number }
  },
  timestamp: { type: Date, default: Date.now } // זמן השמירה
});

const SensorHistory = mongoose.model('SensorHistory', sensorHistorySchema);
module.exports = SensorHistory;