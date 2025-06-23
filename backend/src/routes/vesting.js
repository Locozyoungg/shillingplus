const express = require('express');
const { releaseVestedTokens } = require('../controllers/vestingController.js');
const { protect, admin } = require('../middleware/auth.js');
const router = express.Router();

router.post('/release', protect, admin, releaseVestedTokens);

module.exports = router;
