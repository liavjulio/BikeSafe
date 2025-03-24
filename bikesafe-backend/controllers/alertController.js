//bikesafe-backend/controllers/alertController.js
const User = require('../models/User');
const admin = require('firebase-admin');
const serviceAccount = require('../bike-safe-24118-e2932191e023.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

// ✅ Send notification
async function sendFCMNotification(deviceTokens, payload) {
  try {
    const response = await admin.messaging().sendMulticast({
      tokens: deviceTokens,
      notification: {
        title: payload.title,
        body: payload.body
      },
      data: payload.data || {}
    });

    console.log('Successfully sent message:', response);
  } catch (error) {
    console.log('Error sending message:', error);
  }
}
// ✅ עדכון העדפות התראות של המשתמש
exports.updateAlertPreferences = async (req, res) => {
  const { userId, alerts } = req.body;

  try {
    console.log(`Updating alert preferences for user: ${userId}`);
    console.log(`New Preferences:`, alerts);

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // עדכון העדפות ההתראות של המשתמש
    user.alerts = alerts;
    await user.save();

    console.log(`Updated preferences in DB: ${user.alerts}`);

    // מחזירים את ההעדפות בפורמט ברור
    res.status(200).json(user.alerts.reduce((prefs, alert) => {
      prefs[alert] = true;
      return prefs;
    }, { 'safe-zone': false, 'battery': false, 'temperature': false, 'theft': false, 'sensor-failure': false }));

  } catch (err) {
    console.error('Error updating alert preferences:', err);
    res.status(500).json({ error: err.message });
  }
};

// ✅ שליפת העדפות התראות של המשתמש
exports.getAlertPreferences = async (req, res) => {
  const { userId } = req.query;  // 📌 שינינו מ- `params` ל- `query`!

  try {
    console.log(`Fetching alert preferences for user: ${userId}`);
    const user = await User.findById(userId);

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    console.log(`User found: ${user.email}, Preferences: ${user.alerts}`);

    // מחזירים את ההעדפות בפורמט ברור
    res.status(200).json(user.alerts.reduce((prefs, alert) => {
      prefs[alert] = true;
      return prefs;
    }, { 'safe-zone': false, 'battery': false, 'temperature': false, 'theft': false, 'sensor-failure': false }));

  } catch (err) {
    console.error('Error fetching alert preferences:', err);
    res.status(500).json({ error: err.message });
  }
};
// ✅ שליחת התראה למשתמש לפי סוג ההתראה שהוא בחר
exports.sendAlert= async (userId, type, message) => {
  try {
    console.log(`Sending alert notification to user: ${userId}, Type: ${type}`);

    const user = await User.findById(userId);
    if (!user) {
      console.log('User not found');
      return;
    }

    if (!user.alerts.includes(type)) {
      console.log(`User has disabled ${type} alerts.`);
      return;
    }

    if (!user.deviceTokens || user.deviceTokens.length === 0) {
      console.log(`User has no device tokens registered.`);
      return;
    }

    await sendFCMNotification(user.deviceTokens, {
      title: `BikeSafe Alert: ${type}`,
      body: message,
      data: {
        type: type,
        userId: user._id.toString()
      }
    });

    console.log(`✅ Alert sent to user ${userId}: ${message}`);
  } catch (error) {
    console.error('Error sending alert notification:', error);
  }
};
  exports.saveDeviceToken = async (req, res) => {
    const { userId, token } = req.body;
  
    try {
      const user = await User.findById(userId);
  
      if (!user) {
        return res.status(404).json({ message: 'User not found' });
      }
  
      if (!user.deviceTokens.includes(token)) {
        user.deviceTokens.push(token);
        await user.save();
        console.log(`✅ Token saved for user: ${userId}`);
      }
  
      res.status(200).json({ message: 'Device token saved successfully' });
    } catch (error) {
      console.error('❌ Error saving device token:', error);
      res.status(500).json({ error: error.message });
    }
  };