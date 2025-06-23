const { ethers } = require('ethers');
const Transaction = require('../models/Transaction');
const blockchainService = require('../services/blockchainService');
const kotaniService = require('../services/kotaniService');

exports.deposit = async (req, res, next) => {
  try {
    const { userId, amount, phone } = req.body;
    const tx = await kotaniService.processDeposit(userId, amount, phone);
    await Transaction.create({ userId, type: 'deposit', amount, txHash: tx.hash });
    res.status(200).json({ message: 'Deposit processed', txHash: tx.hash });
  } catch (error) {
    next(error);
  }
};

exports.withdraw = async (req, res, next) => {
  try {
    const { userId, amount, phone } = req.body;
    const tx = await kotaniService.initiateWithdrawal(userId, amount, phone);
    await Transaction.create({ userId, type: 'withdrawal', amount, txHash: tx.hash });
    res.status(200).json({ message: 'Withdrawal initiated', txHash: tx.hash });
  } catch (error) {
    next(error);
  }
};

exports.getHistory = async (req, res, next) => {
  try {
    const transactions = await Transaction.find({ userId: req.user._id });
    res.json(transactions);
  } catch (error) {
    next(error);
  }
};
