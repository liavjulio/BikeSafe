// controllers/adminController.js
const User = require('../models/User');
const Location = require('../models/Location');
const Sensor = require('../models/Sensor');
const SensorHistory = require('../models/SensorHistory');
exports.getAllUsers = async (req, res) => {
  try {
    const users = await User.find().select('-password -verificationCode');
    res.status(200).json(users);
  } catch (err) {
    console.error('❌ Failed to fetch users:', err);
    res.status(500).json({ message: 'Failed to fetch users' });
  }
};

exports.deleteUserById = async (req, res) => {
  try {
    const userId = req.params.userId;
    await User.findByIdAndDelete(userId);
    await Location.deleteMany({ userId });
    await Sensor.deleteMany({ userId });
    await SensorHistory.deleteMany({ userId });
    res.status(200).json({ message: 'User and related data deleted' });
  } catch (err) {
    console.error('❌ Failed to delete user:', err);
    res.status(500).json({ message: 'Failed to delete user' });
  }
};

exports.toggleAdminStatus = async (req, res) => {
    try {
      const { userId } = req.params;
  
      if (userId === req.user.id) {
        return res.status(400).json({ message: "You can't change your own admin status." });
      }
  
      const user = await User.findById(userId);
      if (!user) return res.status(404).json({ message: 'User not found' });
  
      user.isAdmin = !user.isAdmin;
      await user.save();
  
      res.status(200).json({
        message: `User ${user.email} is now ${user.isAdmin ? 'an admin' : 'a regular user'}`,
        isAdmin: user.isAdmin,
      });
    } catch (err) {
      console.error('❌ Failed to toggle admin status:', err);
      res.status(500).json({ message: 'Failed to update user role' });
    }
  };