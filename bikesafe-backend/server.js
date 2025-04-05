// bikesafe-backend/server.js
require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const bodyParser = require('body-parser');
const cors = require('cors');
const passport = require('passport');
const { OAuth2Client } = require('google-auth-library');
const jwt = require('jsonwebtoken');
const session = require('express-session');
const GoogleStrategy = require('passport-google-oauth20').Strategy;
const bcrypt = require('bcryptjs'); // For password hashing

// Import Models and Routes
const User = require('./models/User');
const Location = require('./models/Location');
const authRoutes = require('./routes/authRoutes');
const locationRoutes = require('./routes/locationRoutes');
const sensorRoutes = require('./routes/sensorRoutes');
const alertRoutes = require('./routes/alertRoutes');
const adminRoutes = require('./routes/adminRoutes');


const app = express();

// Middleware configuration
app.use(session({ secret: 'your-secret', resave: true, saveUninitialized: true }));
app.use(passport.initialize());
app.use(passport.session());
app.use(cors());
app.use(bodyParser.json());

console.log("✅ GOOGLE_CLIENT_ID_WEB:", process.env.GOOGLE_CLIENT_ID_WEB);
console.log("✅ GOOGLE_CLIENT_ID_ANDROID:", process.env.GOOGLE_CLIENT_ID_ANDROID);
console.log("✅ GOOGLE_CLIENT_ID_IOS:", process.env.GOOGLE_CLIENT_ID_IOS);

const CLIENT_IDS = [
  process.env.GOOGLE_CLIENT_ID_WEB,
  process.env.GOOGLE_CLIENT_ID_ANDROID,
  process.env.GOOGLE_CLIENT_ID_IOS
].filter(Boolean);

console.log("✅ CLIENT_IDS used:", CLIENT_IDS);

// Google OAuth Strategy
passport.use(new GoogleStrategy({
  clientID: process.env.GOOGLE_CLIENT_ID,
  clientSecret: process.env.GOOGLE_CLIENT_SECRET,
  // For production, use your live callback URL (e.g., on Render)
  callbackURL: "https://bikesafe-backend-latest.onrender.com/api/auth/google/callback",
}, async (accessToken, refreshToken, profile, done) => {
  console.log('Google OAuth Callback:', profile);
  try {
    // Look for user by googleId
    let user = await User.findOne({ googleId: profile.id });
    if (user) {
      console.log('User found:', user);
      return done(null, user);
    }
    // Create a new user if not found
    const newUser = new User({
      googleId: profile.id,
      name: profile.displayName,
      email: profile.emails[0].value,
    });
    await newUser.save();
    console.log('New user created:', newUser);
    done(null, newUser);
  } catch (error) {
    console.error('Error processing Google OAuth:', error);
    done(error, null);
  }
}));

// Passport session handling
passport.serializeUser((user, done) => done(null, user.id));
passport.deserializeUser(async (id, done) => {
  try {
    const user = await User.findById(id);
    done(null, user);
  } catch (error) {
    done(error, null);
  }
});

// Routes
app.get('api/auth/google',
  passport.authenticate('google', { scope: ['profile', 'email'] })
);
app.use('/api/auth', authRoutes);
app.use('/api/location', locationRoutes);
app.use('/api/sensor', sensorRoutes);
app.use('/api/alerts', alertRoutes);
app.use('/api/admin', adminRoutes);

// Google callback route after successful Google login
app.post('/api/auth/google/callback', async (req, res) => {
  const { idToken, password } = req.body;
  try {
    const client = new OAuth2Client();
    const ticket = await client.verifyIdToken({
      idToken: idToken,
      audience: CLIENT_IDS,
    });
    const payload = ticket.getPayload();
    console.log('Payload:', payload);
    let user = await User.findOne({ email: payload.email });
    if (!user) {
      console.log('Creating new user...');
      user = new User({
        googleId: payload.sub,
        name: payload.name,
        email: payload.email,
      });
      // Require password for first-time login
      if (!password) {
        return res.status(400).json({ message: 'Please set a password to continue.' });
      }
      user.password = password;
      const location = new Location({
        userId: user._id,
        currentLocation: {
          latitude: 32.0853,
          longitude: 34.7818
        }
      });
      await location.save();
      try {
        await user.save();
        console.log('New user saved:', user);
      } catch (error) {
        if (error.code === 11000) {
          return res.status(400).json({ message: 'Email already registered' });
        }
        throw error;
      }
    } else {
      console.log('User already exists:', user);
      if (!user.password) {
        return res.status(400).json({ message: 'Please set a password to continue.' });
      }
    }
    const token = jwt.sign({ id: user._id,isAdmin: user.isAdmin }, process.env.JWT_SECRET, { expiresIn: '1h' });
    res.status(200).json({ token, isAdmin: user.isAdmin,userId: user._id });
  } catch (error) {
    console.error('Error during Google authentication:', error);
    res.status(400).json({ message: 'Authentication failed', error: error.message });
  }
});

// MongoDB connection
mongoose.connect(process.env.MONGO_URI, { dbName: 'bikesafe' })
  .then(() => console.log('MongoDB connected'))
  .catch((err) => console.error('MongoDB connection error:', err));

// Start the server only if this module is the main module
const PORT = process.env.PORT || 5001;
if (require.main === module) {
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running on port ${PORT}`);
  }).on('error', (err) => {
    if (err.code === 'EADDRINUSE') {
      console.error(`Port ${PORT} is already in use.`);
    } else {
      console.error('Server error:', err);
    }
  });
}

module.exports = app;