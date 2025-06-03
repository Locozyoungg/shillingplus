const mpesaService = require('../services/mpesa.service');
const bankService = require('../services/bank.service');
const securityService = require('../services/security.service');
const Transaction = require('../models/Transaction');

exports.deposit = async (req, res) => {
  const { phone, amount, txRef } = req.body;
  try {
    const result = await mpesaService.processDeposit(phone, amount, txRef);
    if (result.success) {
      const tx = new Transaction({
        userId: req.user._id,
        type: 'deposit',
        amount: result.tokens,
        kshAmount: amount,
        phoneNumber: phone,
      });
      await tx.save();
      res.json({ success: true, tokens: result.tokens });
    } else {
      res.status(400).json({ error: 'Deposit failed' });
    }
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
};

exports.withdrawMpesa = async (req, res) => {
  const { phone, amount } = req.body;
  try {
    if (amount > 500000) {
      const kycVerified = await securityService.verifyUserKyc(req.user._id, null, null);
      if (!kycVerified) {
        return res.status(403).json({ error: 'KYC required for large withdrawals' });
      }
    }
    const result = await mpesaService.processWithdrawal(phone, amount);
    if (result.success) {
      const tx = new Transaction({
        userId: req.user._id,
        type: 'withdrawal',
        amount,
        kshAmount: amount,
        phoneNumber: phone,
      });
      await tx.save();
      res.json({ success: true, reference: result.reference });
    } else {
      res.status(400).json({ error: 'Withdrawal failed' });
    }
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
};

exports.withdrawBank = async (req, res) => {
  const { bankAccount, amount } = req.body;
  try {
    if (amount > 500000) {
      const kycVerified = await securityService.verifyUserKyc(req.user._id, null, null);
      if (!kycVerified) {
        return res.status(403).json({ error: 'KYC required for large withdrawals' });
      }
    }
    const result = await bankService.withdrawToBank(req.user.walletAddress, bankAccount, amount);
    if (result.success) {
      const tx = new Transaction({
        userId: req.user._id,
        type: 'bank_withdrawal',
        amount,
        kshAmount: amount,
        bankAccount,
      });
      await tx.save();
      res.json({ success: true, reference: result.reference });
    } else {
      res.status(400).json({ error: 'Bank withdrawal failed' });
    }
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
};

exports.transfer = async (req, res) => {
  const { to, amount } = req.body;
  try {
    if (amount > 500000) {
      const kycVerified = await securityService.verifyUserKyc(req.user._id, null, null);
      if (!kycVerified) {
        return res.status(403).json({ error: 'KYC required for large transfers' });
      }
    }
    // Mock transfer logic (integrate with SHPTransaction contract)
    const tx = new Transaction({
      userId: req.user._id,
      type: 'transfer',
      amount,
      kshAmount: amount,
    });
    await tx.save();
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
};
