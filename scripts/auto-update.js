const oracleService = require('../backend/services/oracle.service');
const rebaseService = require('../backend/services/rebase.service');

const autoUpdate = async () => {
  console.log('Starting daily update at', new Date().toISOString());
  
  const priceResult = await oracleService.updatePrice();
  if (!priceResult.success) {
    console.error('Price update failed');
    return;
  }

  const rebaseResult = await rebaseService.triggerRebase();
  if (!rebaseResult.success) {
    console.error('Rebase failed');
    return;
  }

  console.log('Update complete: Price:', priceResult.price, 'Adjustment:', rebaseResult.adjustment, '%');
};

autoUpdate().catch(console.error);
