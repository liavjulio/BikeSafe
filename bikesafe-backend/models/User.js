//bikesafe-backend/models/User.js
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  googleId: { type: String, required: false,sparse: true },
  phone: { type: String, required: false},
  name: { type: String, required: false },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: false },
  isVerified: { type: Boolean, default: false },  
  verificationCode: { type: String, required: false },  
  failedLoginAttempts: { type: Number, default: 0 },
  accountLocked: { type: Boolean, default: false },
  alerts: {
    type: [String],
    enum: ['safe-zone', 'battery', 'temperature', 'theft', 'sensor-failure'],
    default: ['safe-zone', 'battery'], // ברירת מחדל
  },
  deviceTokens: {
    type: [String],
    default: []
  },
  batteryCompany: { type: String },  
  batteryType: { type: String },
  isAdmin: { type: Boolean, default: false },       
});

const User = mongoose.model('User', userSchema);
module.exports = User;