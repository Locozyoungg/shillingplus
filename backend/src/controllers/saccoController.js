const blockchainService = require('../services/blockchainService');

exports.subscribeSACCO = async (req, res, next) => {
  try {
    const { saccoAddress } = req.body;
    const tx = await blockchainService.subscribeSACCO(saccoAddress);
    res.status(200).json({ message: 'SACCO subscribed', txHash: tx.hash });
  } catch (error) {
    next(error);
  }
};
