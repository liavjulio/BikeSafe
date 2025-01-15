const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  googleId: { type: String, required: false },
  phone: { type: String, required: false},
  name: { type: String, required: false },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: false },  // Optional initially for Google login
});

const User = mongoose.model('User', userSchema);
module.exports = User;