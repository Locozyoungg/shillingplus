const BankIntegratedSHPAbi = require('../../abis/BankIntegratedSHP.json');
const bankIntegratedSHP = new ethers.Contract(process.env.BANK_INTEGRATED_SHP_ADDRESS, BankIntegratedSHPAbi, wallet);

exports.initiateDeposit = async (userAddress, amount, bankDetails, isMpesa) => {
  try {
    let tx, depositId;
    if (isMpesa) {
      const response = await axios.post(
        process.env.MPESA_API_URL,
        { amount, phone: bankDetails.phone, reference: ethers.utils.id(`${userAddress}-${Date.now()}`) },
        { headers: { Authorization: `Bearer ${process.env.MPESA_API_KEY}` } }
      );
      depositId = response.data.transactionId;
      tx = await bankIntegratedSHP.depositFromMpesa(amount, bankDetails.phone);
    } else {
      const response = await axios.post(
        process.env.BANK_API_URL,
        { amount, sourceAccount: bankDetails.accountNumber, destinationAccount: process.env.PLATFORM_BANK_ACCOUNT, reference: ethers.utils.id(`${userAddress}-${Date.now()}`) },
        { headers: { Authorization: `Bearer ${process.env.BANK_API_KEY}` } }
      );
      depositId = response.data.transactionId;
      tx = await bankIntegratedSHP.depositFromBank(amount);
    }
    await tx.wait();
    return { txHash: tx.hash, depositId };
  } catch (error) {
    throw new Error(`Deposit initiation failed: ${error.message}`);
  }
};

exports.initiateWithdrawal = async (userAddress, tokenAmount, bankDetails, isMpesa) => {
  try {
    let tx, withdrawalId = ethers.utils.id(`${userAddress}-${Date.now()}`);
    if (isMpesa) {
      tx = await bankIntegratedSHP.withdrawToMpesa(tokenAmount, bankDetails.phone);
    } else {
      tx = await bankIntegratedSHP.withdrawToBank(tokenAmount);
    }
    await tx.wait();
    return { txHash: tx.hash, withdrawalId };
  } catch (error) {
    throw new Error(`Withdrawal initiation failed: ${error.message}`);
  }
};

// Existing confirmDeposit, confirmWithdrawal unchanged
