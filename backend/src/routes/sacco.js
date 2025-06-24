const express = require('express');
const { subscribeSACCO } = require('../controllers/saccoController');
const { protect, admin } = require('../middleware/auth');
const router = express.Router();

router.post('/subscribe', protect, admin, subscribeSACCO);

module.exports = router;
