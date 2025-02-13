//bikesafe-backend/controllers/alertController.js
const User = require('../models/User');

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
exports.sendAlert = async (req, res) => {
    const { userId, type, message } = req.body;
  
    try {
      console.log(`Sending alert to user: ${userId}, Type: ${type}`);
  
      const user = await User.findById(userId);
      if (!user) {
        return res.status(404).json({ message: 'User not found' });
      }
  
      // אם המשתמש לא בחר לקבל את ההתראה הזו, לא שולחים לו אותה
      if (!user.alerts.includes(type)) {
        return res.status(200).json({ message: `User has disabled ${type} alerts.` });
      }
  
      // כאן אפשר להוסיף אינטגרציה לשליחת הודעה באפליקציה, SMS, או Firebase push notification
  
      res.status(200).json({ message: `Alert sent successfully: ${message}` });
  
    } catch (err) {
      console.error('Error sending alert:', err);
      res.status(500).json({ error: err.message });
    }
  };