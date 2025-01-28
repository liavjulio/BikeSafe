const Location = require('../models/Location');

// Update bike's real-time location
exports.updateLocation = async (req, res) => {
  const { userId, latitude, longitude } = req.body;

  try {
    let location = await Location.findOne({ userId });

    if (!location) {
      location = new Location({ userId, currentLocation: { latitude, longitude } });
    } else {
      location.currentLocation = { latitude, longitude };
    }

    await location.save();
    res.status(200).json({ message: 'Location updated successfully', location });
  } catch (error) {
    console.error('Error updating location:', error);
    res.status(500).json({ message: 'Failed to update location', error });
  }
};
exports.updateBattery = async (req, res) => {
    const { userId, batteryLevel } = req.body;
  
    try {
      const location = await Location.findOne({ userId });
      if (!location) return res.status(404).json({ message: 'Location not found' });
  
      location.batteryLevel = batteryLevel;
      await location.save();
  
      // Check for low battery alert
      if (batteryLevel < 20) {
        res.status(200).json({ alert: 'Battery is low', batteryLevel });
      } else {
        res.status(200).json({ message: 'Battery updated', batteryLevel });
      }
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  };
// Retrieve bike's real-time location
exports.getRealtimeLocation = async (req, res) => {
  const { userId } = req.query;

  try {
    const location = await Location.findOne({ userId });

    if (!location) {
      return res.status(404).json({ message: 'Location not found' });
    }

    res.status(200).json(location);
  } catch (error) {
    console.error('Error fetching location:', error);
    res.status(500).json({ message: 'Failed to fetch location', error });
  }
};

// Set or update safe zone
exports.setSafeZone = async (req, res) => {
  const { userId, center, radius } = req.body;

  try {
    let location = await Location.findOne({ userId });

    if (!location) {
      location = new Location({ userId, safeZone: { center, radius } });
    } else {
      location.safeZone = { center, radius };
    }

    await location.save();
    res.status(200).json({ message: 'Safe zone updated successfully', location });
  } catch (error) {
    console.error('Error setting safe zone:', error);
    res.status(500).json({ message: 'Failed to set safe zone', error });
  }
};

// Check if bike exits safe zone
exports.checkSafeZone = async (req, res) => {
  const { userId, currentLocation } = req.body;

  try {
    const location = await Location.findOne({ userId });

    if (!location || !location.safeZone) {
      return res.status(400).json({ message: 'Safe zone not defined' });
    }

    const { center, radius } = location.safeZone;
    const distance = getDistance(currentLocation, center); // Helper function to calculate distance

    if (distance > radius) {
      return res.status(200).json({ alert: 'Bike exited safe zone', distance });
    }

    res.status(200).json({ message: 'Bike is within the safe zone' });
  } catch (error) {
    console.error('Error checking safe zone:', error);
    res.status(500).json({ message: 'Failed to check safe zone', error });
  }
};

// Utility: Calculate distance (Haversine formula)
const getDistance = (location1, location2) => {
  const toRad = (value) => (value * Math.PI) / 180;

  const R = 6371e3; // Radius of Earth in meters
  const lat1 = toRad(location1.latitude);
  const lat2 = toRad(location2.latitude);
  const deltaLat = toRad(location2.latitude - location1.latitude);
  const deltaLon = toRad(location2.longitude - location1.longitude);

  const a =
    Math.sin(deltaLat / 2) * Math.sin(deltaLat / 2) +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(deltaLon / 2) * Math.sin(deltaLon / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
};