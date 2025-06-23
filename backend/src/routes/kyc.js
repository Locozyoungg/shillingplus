const express = require('express');
const { submitKYC, verifyKYC } = require('../controllers/kycController');
const { protect, admin } = require('../middleware/auth');
const router = express.Router();

router.post('/submit', protect, submitKYC);
router.post('/verify', protect, admin, verifyKYC);

module.exports = router;
