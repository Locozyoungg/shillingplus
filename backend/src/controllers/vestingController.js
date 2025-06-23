const blockchainService = require('../services/blockchainService');

exports.releaseVestedTokens = async (req, res, next) => {
  try {
    const tx = await blockchainService.handleVestingRelease();
    await tx;
    res.status(200).json({ message: 'Vested tokens released', txHash: tx.hash });
  }
   catch (error) {
    next(errorHandler(error));
  }
};
