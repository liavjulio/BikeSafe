//bikesafe-backend/models/Location.js
const mongoose = require('mongoose');

const locationSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  currentLocation: {
    latitude: { type: Number, required: true },
    longitude: { type: Number, required: true },
  },
  safeZone: {
    radius: { type: Number, required: false }, // meters
    center: {
      latitude: { type: Number, required: false },
      longitude: { type: Number, required: false },
    },
  },
  batteryLevel: { type: Number, default: 100 },
});

const Location = mongoose.model('Location', locationSchema);
module.exports = Location;