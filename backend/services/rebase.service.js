const Web3 = require('web3');
const config = require('../config/env');
const TokenRebaser = require('../config/TokenRebaser.json');

const web3 = new Web3(config.web3Provider);
const contract = new web3.eth.Contract(JSON.stringify(TokenRebaser.abi), config.rebaserAddress);

const getCbkData = async (metric) => {
  return metric === 'gdp_growth' ? 5.6 : 0;
};

const getSafaricomApi = async (metric) => {
  return metric === 'volume' ? 200_000_000 : 0;
};

const getUserGrowth = async () => {
  return 10.0;
};

exports.triggerRebase = async () => {
  try {
    const gdpGrowth = await getCbkData('gdp_growth');
    const mpesaVolume = await getSafaricomApi('volume');
    const userGrowth = await getUserGrowth();

    let supplyAdjustmentPct = 0;
    if (mpesaVolume > 100_000_000) {
      supplyAdjustmentPct = (userGrowth * 0.7) + (gdpGrowth * 0.3);
    }
    const isExpansion = supplyAdjustmentPct > 0;
    const currentSupply = await contractResult = await contract.methods.totalSupply().call();
    const adjustment = (currentSupply * supplyAdjustmentPct) / 100;
    const adjustmentInWei = web3.utils.toWei(adjustment.toString(), 'ether');

    if (adjustment > 0) {
      await contractResult = await contract.methods.rebase(adjustmentInWei, isExpansion).send({ from: config.adminWallet });
      console.log('Rebase triggered:', supplyAdjustmentPct, '%', isExpansion ? 'expansion' : 'contraction');
      return { success: true, adjustment: supplyAdjustmentPct };
    }
    return { success: true, adjustment: 0 };
  } catch (error) {
    console.error('Rebase error:', error);
    return { success: false };
  }
});
