// routes/adminRoutes.js
const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const authMiddleware = require('../middleware/auth');

router.get('/users', authMiddleware, requireAdmin, adminController.getAllUsers);
router.delete('/users/:userId', authMiddleware, requireAdmin, adminController.deleteUserById);
router.patch('/users/:userId/toggle-admin', authMiddleware, requireAdmin, adminController.toggleAdminStatus);
// Custom middleware to check isAdmin
function requireAdmin(req, res, next) {
  if (!req.user || !req.user.isAdmin) {
    return res.status(403).json({ message: 'Admin access required' });
  }
  next();
}

module.exports = router;