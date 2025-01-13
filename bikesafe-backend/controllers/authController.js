const User = require('../models/User');
const jwt = require('jsonwebtoken');
const emailSender = require('../utils/emailSender');

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

    // Send verification email
    await emailSender.sendVerificationEmail(user.email);

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

exports.forgotPassword = async (req, res) => {
  const { email } = req.body;

  try {
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Generate a password reset token
    const resetToken = jwt.sign({ id: user._id }, process.env.JWT_SECRET, { expiresIn: '1h' });

    // Send the password reset email
    await emailSender.sendPasswordResetEmail(email, resetToken);

    res.status(200).json({ message: 'Password reset email sent successfully' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error processing request' });
  }
};