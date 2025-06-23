const User = require('../models/User');
const blockchainService = require('../services/blockchainService');

exports.submitKYC = async (req, res, next) => {
  try {
    const { userId, kycData } = req.body;
    // Simulate KYC verification (replace with actual KYC provider integration)
    const user = await User.findByIdAndUpdate(userId, { kycStatus: 'pending', kycData }, { new: true });
    res.status(200).json({ message: 'KYC submitted', user });
  } catch (error) {
    next(error);
  }
};

exports.verifyKYC = async (req, res, next) => {
  try {
    const { userId, status } = req.body;
    const user = await User.findByIdAndUpdate(userId, { kycStatus: status }, { new: true });
    await blockchainService.verifyKYC(userId, status === 'verified');
    res.status(200).json({ message: 'KYC updated', user });
  } catch (error) {
    next(error);
  }
};
