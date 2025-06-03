const mongoose = require('mongoose');

const transactionSchema = new mongoose.Schema({
  userId: { type: String, required: true },
  type: { type: String, enum: ['deposit', 'withdrawal', 'bank_transfer', 'transfer'], required: true },
  amount: { type: Number, required: true },
  kshAmount: { type: Number },
  phoneNumber: { type: String },
  bankAccount: { type: String },
  reference: { type: String },
  timestamp: { type: Date, default: Date.now },
});

module.exports = mongoose.model('Transaction', transactionSchema);
