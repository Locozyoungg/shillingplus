const express = require('express');
const { withdrawRoyalties } = require('../controllers/royaltiesController');
const { protect, admin } = require('../middleware/auth');
const router = express.Router();

router.post('/withdraw', protect, admin, withdrawRoyalties);

module.exports = router;
