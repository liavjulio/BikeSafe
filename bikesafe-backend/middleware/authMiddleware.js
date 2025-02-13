//bikesafe-backend/middleware/authMiddleware.js
const jwt = require('jsonwebtoken');

module.exports = (req, res, next) => {
  try {
    // Extract the token from the Authorization header
    const token = req.header('Authorization')?.split(' ')[1];
    if (!token) {
      return res.status(403).json({ message: 'Access denied. No token provided.' });
    }

    // Verify the token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded; // Attach the decoded token payload to the request
    next(); // Proceed to the next middleware or controller
  } catch (err) {
    res.status(401).json({ message: 'Invalid token.' });
  }
};