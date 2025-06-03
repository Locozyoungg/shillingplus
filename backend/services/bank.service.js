const axios = require('axios');
const Web3 = require('web3');
const config = require('../config/env');
const BankBridge = require('../config/BankBridge.json');

const web3 = new Web3(config.web3Provider);
const contract = new web3.eth.Contract(JSON.stringify(BankBridge.abi), config.bankBridgeAddress);

// Mock bank API
const processBankWithdrawal = async (bankAccount, amount) => {
  try {
    const response = await axios.post('https://api.bank.co.ke/withdraw', {
      account: bankAccount,
      amount: amount / 1e18,
      apiKey: config.bankApiKey,
    });
    return { success: response.data.success, reference: response.data.reference };
  } catch (error) {
    console.error('Bank withdrawal error:', error);
    return { success: false };
  }
};

exports.withdrawToBank = async (userAddress, bankAccount, tokenAmount) => {
  try {
    await contractResult = await contract.methods.withdrawToBank(tokenAmount, bankAccount).send({ from: config.adminWallet });
    const result = await processBankWithdrawal(bankAccount, tokenAmount);
    if (result.success) {
      return { success: true, reference: result.reference };
    }
    return { success: false };
  } catch (error) {
    console.error('Withdrawal error:', error);
    return { success: false };
  }
});
