const User = require('../models/User');
const jwt = require('jsonwebtoken');
const emailSender = require('../utils/emailSender');

const generateVerificationCode = () => {
  return Math.floor(100000 + Math.random() * 900000); // Generates a 6-digit code
};

exports.register = async (req, res) => {
  try {
    const { email, phone, password } = req.body;

    // Check if the user already exists
    const existingUser = await User.findOne({ email });
    console.log("Checking existing user: ", existingUser);
    if (existingUser) {
      return res.status(400).json({ message: 'User already exists' });
    }

    // Create a new user
    const user = await User.create({ email, phone, password });

    // Generate and store a verification code (you can store it in the user model or a temporary model)
    const verificationCode = generateVerificationCode();
    user.verificationCode = verificationCode;
    await user.save();

    // Send verification email with the code
    await emailSender.sendVerificationEmail(user.email, verificationCode);


    res.status(201).json({ message: 'User registered successfully. Verify your email.' });
  } catch (err) {
    console.error('Registration error:', err);
    res.status(500).json({ message: err.message });
  }
};

exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Find user by email
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Check if the account is locked
    if (user.accountLocked) {
      return res.status(403).json({ message: 'Account is locked' });
    }

    console.log('Entered password:', password);
    console.log('Stored password:', user.password);

    // Compare passwords
    if (password !== user.password) {
      // Increment failed login attempts
      user.failedLoginAttempts += 1;
      if (user.failedLoginAttempts >= 5) {
        user.accountLocked = true;
      }
      await user.save();
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    // Reset failed login attempts
    user.failedLoginAttempts = 0;
    await user.save();

    // Generate a JWT token
    const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, { expiresIn: '1h' });
    res.status(200).json({ token });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ message: err.message });
  }
};
// In authController.js

exports.verifyCode = async (req, res) => {
  const { code } = req.body;

  try {
    const user = await User.findOne({ verificationCode: code });

    if (!user) {
      return res.status(400).json({ message: 'Invalid verification code' });
    }

    // Clear the verification code once it has been used
    user.verificationCode = null;
    await user.save();

    res.status(200).json({ status: 'success', message: 'Code verified successfully' });
  } catch (err) {
    res.status(500).json({ message: 'Error verifying code' });
  }
};
exports.forgotPassword = async (req, res) => {
  const { email } = req.body;

  try {
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Generate and store the verification code
    const verificationCode = generateVerificationCode();
    user.verificationCode = verificationCode;
    await user.save();

    // Send verification code email
    await emailSender.sendVerificationEmail(email, verificationCode);

    res.status(200).json({ message: 'Verification code sent to your email' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error processing request' });
  }
};

exports.verifyCodeForPasswordReset = async (req, res) => {
  const { email, code, newPassword } = req.body;

  try {
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Check if the entered code matches the stored verification code
    if (user.verificationCode !== code) {
      return res.status(400).json({ message: 'Invalid verification code' });
    }

    // Hash the new password and save it
    user.password = newPassword;
    user.verificationCode = null; // Clear the verification code after it's used
    await user.save();

    res.status(200).json({ message: 'Password reset successfully' });
  } catch (err) {
    res.status(500).json({ message: 'Error resetting password' });
  }
};