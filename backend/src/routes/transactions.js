const express = require('express');
const { deposit, withdraw, getHistory } = require('../controllers/transactionController');
const { protect } = require('../middleware/auth');
const router = express.Router();

router.post('/deposit', protect, deposit);
router.post('/withdraw', protect, withdraw);
router.get('/history', protect, getHistory);

module.exports = router;
