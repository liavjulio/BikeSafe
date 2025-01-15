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
const bcrypt = require('bcryptjs');  // Added bcrypt for password hashing
const User = require('./models/User');
const authRoutes = require('./routes/authRoutes');

const app = express();

// Initialize Passport.js
app.use(session({ secret: 'your-secret', resave: true, saveUninitialized: true }));
app.use(passport.initialize());
app.use(passport.session());

// CORS configuration
app.use(cors());

// Google OAuth Strategy (Passport.js strategy)
passport.use(new GoogleStrategy({
  clientID: process.env.GOOGLE_CLIENT_ID,
  clientSecret: process.env.GOOGLE_CLIENT_SECRET,
  callbackURL: "http://localhost:5001/auth/google/callback",
}, async (accessToken, refreshToken, profile, done) => {
  console.log('Google OAuth Callback:', profile);
  try {
    const user = await User.findOne({ googleId: profile.id });

    if (user) {
      console.log('User found:', user);
      return done(null, user);
    }

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

// Serialize and deserialize user for session handling
passport.serializeUser((user, done) => done(null, user.id));
passport.deserializeUser(async (id, done) => {
  try {
    const user = await User.findById(id);
    done(null, user);
  } catch (error) {
    done(error, null);
  }
});

// Middleware
app.use(bodyParser.json());

// Google login route (front-end will trigger this)
app.get('/auth/google',
  passport.authenticate('google', { scope: ['profile', 'email'] })
);
app.use('/api/auth', authRoutes);

// Google callback route after successful Google login
app.post('/auth/google/callback', async (req, res) => {
  const { idToken, password } = req.body;

  try {
    const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);
    const ticket = await client.verifyIdToken({
      idToken: idToken,
      audience: process.env.GOOGLE_CLIENT_ID,
    });

    const payload = ticket.getPayload();
    console.log(User);
    // Check if the user already exists
    let user = await User.findOne({ email: payload.email });

    if (!user) {
      console.log('Creating new user...');
      user = new User({
        googleId: payload.sub,
        name: payload.name,
        email: payload.email,
      });

      // If the user is logging in for the first time, ask them to set a password
      if (!password) {
        return res.status(400).json({ message: 'Please set a password to continue.' });
      }

      user.password = password;

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

      // If the user already exists but hasn't set a password, ask them to set one
      if (!user.password) {
        return res.status(400).json({ message: 'Please set a password to continue.' });
      }
    }

    const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, { expiresIn: '1h' });
    res.status(200).json({ token, user });

  } catch (error) {
    console.error('Error during Google authentication:', error);
    res.status(400).json({ message: 'Authentication failed', error: error.message });
  }
});

// MongoDB Connection
mongoose.connect(process.env.MONGO_URI, { dbName: 'bikesafe' })
  .then(() => console.log('MongoDB connected'))
  .catch((err) => console.error('MongoDB connection error:', err));

const PORT = process.env.PORT || 5001;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));