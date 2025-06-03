const Web3 = require('web3');
const config = require('../config/env');
const SHPPegOracle = require('../config/SHPPegOracle.json');
const axios = require('axios');

const web3 = new Web3(config.web3Provider);
const contract = new web3.eth.Contract(JSON.stringify(SHPPegOracle.abi), config.oracleAddress);

// Mock APIs
const getCbkData = async (metric) => {
  return metric === 'gdp_growth' ? 5.6 : 0; // Mock 5.6% GDP growth
};

const getSafaricomApi = async (metric) => {
  return metric === 'volume' ? 200_000_000 : 0; // Mock 200M KSH
};

const getUserGrowth = async () => {
  return 10.0; // Mock 10% growth
};

const getReserveValue = async () => {
  return 200_000_000 * 1e18; // Mock 200M KSH
};

exports.updatePrice = async () => {
  try {
    const gdpGrowth = await getCbkData('gdp_growth');
    const mpesaVolume = await getSafaricomApi('volume');
    const userGrowth = await getUserGrowth();
    const reserve = await getReserveValue();

    let newPrice = 1.0;
    if (gdpGrowth > 5 && mpesaVolume > 100_000_000) {
      newPrice = 1.0 + (gdpGrowth - 5) / 100;
    }
    const priceInWei = web3.utils.toWei(newPrice.toString(), 'ether');
    const reserveInWei = reserve;

    await contractResult = await contract.methods.updatePriceAndReserve(priceInWei, reserveInWei).send({ from: config.adminWallet });
    console.log('Price updated to:', newPrice, 'Reserve:', reserve);
    return { success: true, price: newPrice, reserve };
  } catch (error) {
    console.error('Price update error:', error);
    return { success: false };
  }
});
