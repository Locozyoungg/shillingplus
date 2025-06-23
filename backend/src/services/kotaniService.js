const axios = require('axios');
const blockchainService = require('./blockchainService');

exports.processDeposit = async (userId, amount, phone) => {
  try {
    // Replace with actual Kotani Pay API endpoint
    const response = await axios.post('https://api.kotani.com/deposit', {
      phone,
      amount,
      apiKey: process.env.KOTANI_API_KEY,
    });
    const tx = await blockchainService.mintTokens(userId, amount);
    return tx;
  } catch (error) {
    throw new Error(`Deposit failed: ${error.response?.data?.message || error.message}`);
  }
};

exports.initiateWithdrawal = async (userId, amount, phone) => {
  try {
    // Replace with actual Kotani Pay API endpoint
    const response = await axios.post('https://api.kotani.com/withdraw', {
      phone,
      amount,
      apiKey: process.env.KOTANI_API_KEY,
    });
    const tx = await blockchainService.burnTokens(userId, amount, phone);
    return tx;
  } catch (error) {
    throw new Error(`Withdrawal failed: ${error.response?.data?.message || error.message}`);
  }
};
