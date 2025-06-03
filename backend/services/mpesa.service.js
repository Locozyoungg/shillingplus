const axios = require('axios');
const config = require('../config/env.js');
const Web3 = require('web3');

const web3 = new Web3(config.web3Provider);
const MpesaBridge = require('../config/MpesaBridge.json');
const contract = new web3.eth.Contract(JSON.stringify(MpesaBridge.abi), config.mpesaBridgeAddress);

// Mock Safaricom API
const processMpesaDeposit = async (phoneNumber, amount) => {
  try {
    const response = await axios.post('https://api.safaricom.co.ke/mpesa/stkpush/v1/processrequest', {
      apiKey: config.mpesaApiKey,
      phoneNumber,
      amount,
    });
    return { success: response.data.success, reference: response.data.CheckoutRequestID };
  } catch (error) {
    console.error('M-Pesa deposit error:', error);
    return { success: false };
  }
};

const processMpesaWithdrawal = async (phoneNumber, amount) => {
  try {
    const response = await axios.post('https://api.safaricom.co.ke/mpesa/b2c/v1/paymentrequest', {
      apiKey: config.mpesaApiKey,
      phoneNumber,
      amount,
    });
    return { success: response.data.success, reference: response.data.TransactionId };
  } catch (error) {
    console.error('M-Pesa withdrawal error:', error);
    return { success: false };
  }
};

exports.processDeposit = async (phoneNumber, amount, tokenAmount) => {
  try {
    const mpesaResult = await processMpesaDeposit(phoneNumber, amount);
    if (mpesaResult.success) {
      await contractResult = await contract.methods.depositFromMpesa(tokenAmount, phoneNumber).send({ from: config.adminWallet });
      return { success: true, tokens: tokenAmount, reference: mpesaResult.reference };
    }
    return { success: false };
  } catch (error) {
    console.error('Deposit error:', error);
    return { success: false };
  }
});

exports.processWithdrawal = async (phoneNumber, amount, tokenAmount) => {
  try {
    const contractResult = await contract.methods.withdrawToMpesa(tokenAmount, phoneNumber).send({ from: config.adminWallet });
    const mpesaResult = await processMpesaWithdrawal(phoneNumber, amount);
    if (mpesaResult.success) {
      return { success: true, reference: mpesaResult.reference };
    }
    return { success: false };
  } catch (error) {
    console.error('Withdrawal error:', error);
    return { success: false };
  }
});
