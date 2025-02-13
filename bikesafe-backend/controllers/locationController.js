//bikesafe-backend/controllers/locationController.js
const Location = require('../models/Location');

// 🟢 Update bike's real-time location and trigger safe zone alert if needed
exports.updateLocation = async (req, res) => {
  const { userId, latitude, longitude } = req.body;

  try {
    // Check if location exists for the user
    let location = await Location.findOne({ userId });

    // If no location exists, create a new location for the user
    if (!location) {
      location = new Location({
        userId,
        currentLocation: { latitude, longitude },
        // Optionally initialize the safe zone here, if needed
        safeZone: {
          center: { latitude, longitude },
          radius: 500 // Default safe zone radius (you can adjust this)
        }
      });
    } else {
      // Update the current location if location already exists
      location.currentLocation = { latitude, longitude };
    }

    // Save the updated or newly created location
    await location.save();

    // Check if the bike is outside the safe zone
    if (location.safeZone && location.safeZone.center) {
      const distance = getDistance({ latitude, longitude }, location.safeZone.center);
      if (distance > location.safeZone.radius) {
        return res.status(200).json({
          alert: 'Bike exited safe zone',
          distance,
          currentLocation: location.currentLocation,
        });
      }
    }

    res.status(200).json({ message: 'Location updated successfully', location });
  } catch (error) {
    console.error('Error updating location:', error);
    res.status(500).json({ message: 'Failed to update location', error });
  }
};
exports.getSafeZone = async (req, res) => {
  const { userId } = req.query;
  console.log(`[getSafeZone] Called with userId=${userId}`);

  try {
    const location = await Location.findOne({ userId });
    console.log(`[getSafeZone] Found location doc for userId=${userId}:`, location);

    if (!location || !location.safeZone) {
      console.log('[getSafeZone] No safe zone found, returning 404...');
      return res.status(404).json({ message: 'Safe zone not found' });
    }

    // Debug: Print the safe zone data
    console.log('[getSafeZone] Returning safe zone data:', {
      latitude: location.safeZone.center.latitude,
      longitude: location.safeZone.center.longitude,
      radius: location.safeZone.radius,
    });

    res.status(200).json({
      latitude: location.safeZone.center.latitude,
      longitude: location.safeZone.center.longitude,
      radius: location.safeZone.radius,
    });
  } catch (error) {
    console.error('[getSafeZone] Error fetching safe zone:', error);
    res.status(500).json({ error: error.message });
  }
};
// 🟢 Get bike's real-time location
exports.getRealtimeLocation = async (req, res) => {
  const { userId } = req.query;

  try {
    const location = await Location.findOne({ userId });

    if (!location) {
      return res.status(404).json({ message: 'Location not found' });
    }

    res.status(200).json({
      currentLocation: location.currentLocation,
      safeZone: location.safeZone || null, // Ensure safeZone data is included
    });
  } catch (error) {
    console.error('Error fetching location:', error);
    res.status(500).json({ message: 'Failed to fetch location', error });
  }
};

// 🟢 Set or update Safe Zone
exports.setSafeZone = async (req, res) => {
  const { userId, latitude, longitude, radius } = req.body;

  try {
    let location = await Location.findOne({ userId });

    if (!location) {
      location = new Location({
        userId,
        safeZone: { center: { latitude, longitude }, radius },
      });
    } else {
      location.safeZone = { center: { latitude, longitude }, radius };
    }

    await location.save();
    res.status(200).json({ message: 'Safe zone updated successfully', location });
  } catch (error) {
    console.error('Error setting safe zone:', error);
    res.status(500).json({ message: 'Failed to set safe zone', error });
  }
};

// 🟢 Utility: Calculate distance using Haversine formula
const getDistance = (location1, location2) => {
  const toRad = (value) => (value * Math.PI) / 180;

  const R = 6371e3; // Earth radius in meters
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