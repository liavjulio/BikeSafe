const User = require('../models/User');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const sgMail = require('@sendgrid/mail');

// Configure SendGrid with your API key
sgMail.setApiKey(process.env.SENDGRID_API_KEY);

// User registration
exports.register = async (req, res) => {
  const { email, password } = req.body;

  try {
    // Check if user already exists
    const existingUser = await User.findOne({ email });
    if (existingUser) return res.status(400).json({ message: 'User already exists' });

    // Hash the password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create a new user
    const newUser = new User({ email, password: hashedPassword });
    await newUser.save();

    // Send verification email
    await sendVerificationEmail(email);

    res.status(201).json({ message: 'User registered successfully. Please verify your email.' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// User login
exports.login = async (req, res) => {
  const { email, password } = req.body;

  try {
    // Find the user
    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'User not found' });

    // Compare passwords
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) return res.status(401).json({ message: 'Invalid credentials' });

    // Generate a JWT token
    const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, { expiresIn: '1h' });

    res.status(200).json({ token, message: 'Login successful' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Password reset
exports.resetPassword = async (req, res) => {
  const { email, newPassword } = req.body;

  try {
    // Find the user
    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'User not found' });

    // Hash the new password
    const hashedPassword = await bcrypt.hash(newPassword, 10);

    // Update the user's password
    user.password = hashedPassword;
    await user.save();

    res.status(200).json({ message: 'Password updated successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
exports.linkSensor = async (req, res) => {
  const { userId, sensorId } = req.body;

  try {
    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ message: 'User not found' });

    // Placeholder logic for linking sensor
    user.sensorId = sensorId;
    await user.save();

    res.status(200).json({ message: 'Sensor linked successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
// Utility function to send verification email using SendGrid
const sendVerificationEmail = async (email) => {
  const msg = {
    to: email, // Recipient email
    from: process.env.EMAIL, // Sender email (must be verified in SendGrid)
    subject: 'Verify Your Account',
    text: 'Please verify your account to complete registration.',
    html: '<strong>Please verify your account to complete registration.</strong>',
  };

  try {
    await sgMail.send(msg);
    console.log(`Verification email sent to ${email}`);
  } catch (error) {
    console.error('Error sending email:', error.response ? error.response.body : error.message);
    throw new Error('Failed to send verification email');
  }
};