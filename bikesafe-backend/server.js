//bikesafe-backend/server.js
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
const Location = require('./models/Location');
const authRoutes = require('./routes/authRoutes');
const locationRoutes = require('./routes/locationRoutes');
const sensorRoutes = require('./routes/sensorRoutes');
const alertRoutes = require('./routes/alertRoutes');
const app = express();
// Debug: Log current environment variables (only non-sensitive ones)
console.log('=== Environment Variables ===');
console.log('PORT:', process.env.PORT);
console.log('MONGO_URI:', process.env.MONGO_URI);
console.log('GOOGLE_CLIENT_ID:', process.env.GOOGLE_CLIENT_ID);
console.log('GOOGLE_CLIENT_SECRET:', process.env.GOOGLE_CLIENT_SECRET ? '***' : 'not set');
console.log('GOOGLE_CLIENT_ID_WEB:', process.env.GOOGLE_CLIENT_ID_WEB);
console.log('GOOGLE_CLIENT_ID_ANDROID:', process.env.GOOGLE_CLIENT_ID_ANDROID);
console.log('GOOGLE_CLIENT_ID_IOS:', process.env.GOOGLE_CLIENT_ID_IOS);
console.log('JWT_SECRET:', process.env.JWT_SECRET ? '***' : 'not set');
console.log('=============================');
// Initialize Passport.js
app.use(session({ secret: 'your-secret', resave: true, saveUninitialized: true }));
app.use(passport.initialize());
app.use(passport.session());

// CORS configuration
app.use(cors());
const CLIENT_IDS = [
  process.env.GOOGLE_CLIENT_ID_WEB,
  process.env.GOOGLE_CLIENT_ID_ANDROID,
  process.env.GOOGLE_CLIENT_ID_IOS
];

// Google OAuth Strategy (Passport.js strategy)
passport.use(new GoogleStrategy({
  clientID: process.env.GOOGLE_CLIENT_ID,
  clientSecret: process.env.GOOGLE_CLIENT_SECRET,
  callbackURL: "https://bikesafe-backend-latest.onrender.com/api/auth/google/callback",
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
app.use('/api/location', locationRoutes);
app.use('/api/sensor', sensorRoutes);
app.use('/api/alerts', alertRoutes);
// Google callback route after successful Google login
app.post('/api/auth/google/callback', async (req, res) => {
  const { idToken, password } = req.body;
  const CLIENT_IDS = [
    process.env.GOOGLE_CLIENT_ID_WEB,
    process.env.GOOGLE_CLIENT_ID_ANDROID,
    process.env.GOOGLE_CLIENT_ID_IOS
  ];
  try {
    const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);
    const ticket = await client.verifyIdToken({
      idToken: idToken,
      audience: CLIENT_IDS,
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
      const location = new Location({
        userId: user._id,
        currentLocation: {
          latitude: 32.0853, // or any default coordinate you prefer
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
      console.log('User already exists:', user);//bikesafe-backend/server.js
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
const Location = require('./models/Location');
const authRoutes = require('./routes/authRoutes');
const locationRoutes = require('./routes/locationRoutes');
const sensorRoutes = require('./routes/sensorRoutes');
const alertRoutes = require('./routes/alertRoutes');
const app = express();

// Initialize Passport.js
app.use(session({ secret: 'your-secret', resave: true, saveUninitialized: true }));
app.use(passport.initialize());
app.use(passport.session());

// CORS configuration
app.use(cors());
const CLIENT_IDS = [
  process.env.GOOGLE_CLIENT_ID_WEB,
  process.env.GOOGLE_CLIENT_ID_ANDROID,
  process.env.GOOGLE_CLIENT_ID_IOS
];

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
app.use('/api/location', locationRoutes);
app.use('/api/sensor', sensorRoutes);
app.use('/api/alerts', alertRoutes);
// Google callback route after successful Google login
app.post('/api/auth/google/callback', async (req, res) => {
  const { idToken, password } = req.body;
  const CLIENT_IDS = [
    process.env.GOOGLE_CLIENT_ID_WEB,
    process.env.GOOGLE_CLIENT_ID_ANDROID,
    process.env.GOOGLE_CLIENT_ID_IOS
  ];
  try {
    const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);
    const ticket = await client.verifyIdToken({
      idToken: idToken,
      audience: CLIENT_IDS,
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
      const location = new Location({
        userId: user._id,
        currentLocation: {
          latitude: 32.0853, // or any default coordinate you prefer
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

      // If the user already exists but hasn't set a password, ask them to set one
      if (!user.password) {
        return res.status(400).json({ message: 'Please set a password to continue.' });
      }
    }

    const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, { expiresIn: '1h' });
    res.status(200).json({ token, userId:user._id });

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
app.listen(PORT, '0.0.0.0', () => console.log(`Server running on port ${PORT}`));

      // If the user already exists but hasn't set a password, ask them to set one
      if (!user.password) {
        return res.status(400).json({ message: 'Please set a password to continue.' });
      }
    }

    const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, { expiresIn: '1h' });
    res.status(200).json({ token, userId:user._id });

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
app.listen(PORT, '0.0.0.0', () => console.log(`Server running on port ${PORT}`));