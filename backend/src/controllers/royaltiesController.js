const blockchainService = require('../services/blockchainService');

exports.withdrawRoyalties = async (req, res, next) => {
  try {
    const tx = await blockchainService.withdrawRoyalties();
    res.status(200).json({ message: 'Royalties withdrawn', txHash: tx.hash });
  } catch (error) {
    next(error);
  }
};
