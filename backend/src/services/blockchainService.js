const { ethers } = require('ethers');
const SHPReserveABI = require('../../abis/SHP_Reserve.json');
const KotaniAdapterABI = require('../../abis/KotaniAdapter.json');
const ForeverRoyaltiesABI = require('../../abis/ForeverRoyalties.json');
const VestingABI = require('../../abis/Vesting.json');
const BankIntegratedSHPAbi = require('../../abis/BankIntegratedSHP.json');


const bankIntegratedSHP = new ethers.Contract(process.env.BANK_INTEGRATED_SHP_ADDRESS, BankIntegratedSHPAbi, wallet);
const provider = new ethers.providers.JsonRpcProvider(process.env.POLYGON_ZKEVM_RPC);
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
const reserveContract = new ethers.Contract(process.env.SHP_RESERVE_ADDRESS, SHPReserveABI, wallet);
const adapterContract = new ethers.Contract(process.env.KOTANI_ADAPTER_ADDRESS, KotaniAdapterABI, wallet);
const royaltiesContract = new ethers.Contract(process.env.FOREVER_ROYALTIES_ADDRESS, ForeverRoyaltiesABI, wallet);
const vestingContract = new ethers.Contract(process.env.VESTING_ADDRESS, VestingABI, wallet);

exports.verifyKYC = async (userAddress, status) => {
  try {
    const tx = await reserveContract.verifyKYC(userAddress, status);
    await tx.wait();
    return tx;
  } catch (error) {
    throw new Error(`KYC verification failed: ${error.message}`);
  }
};

exports.mintTokens = async (userAddress, amount) => {
  try {
    const tx = await adapterContract.processDeposit(userAddress, ethers.utils.parseEther(amount.toString()));
    await tx.wait();
    return tx;
  } catch (error) {
    throw new Error(`Minting failed: ${error.message}`);
  }
};

exports.burnTokens = async (userAddress, amount, phone) => {
  try {
    const tx = await adapterContract.initiateWithdrawal(userAddress, ethers.utils.parseEther(amount.toString()), phone);
    await tx.wait();
    return tx;
  } catch (error) {
    throw new Error(`Burning failed: ${error.message}`);
  }
};

exports.withdrawRoyalties = async () => {
  try {
    const tx = await royaltiesContract.withdraw();
    await tx.wait();
    return tx;
  } catch (error) {
    throw new Error(`Royalties withdrawal failed: ${error.message}`);
  }
};

exports.releaseVestedTokens = async () => {
  try {
    const tx = await vestingContract.release();
    await tx.wait();
    return tx;
  } catch (error) {
    throw new Error(`Vesting release failed: ${error.message}`);
  }
};

exports.subscribeSACCO = async (saccoAddress) => {
  try {
    const tx = await bankIntegratedSHP.subscribeSACCO({ from: saccoAddress });
    await tx.wait();
    return tx;
  } catch (error) {
    throw new Error(`SACCO subscription failed: ${error.message}`);
  }
};
