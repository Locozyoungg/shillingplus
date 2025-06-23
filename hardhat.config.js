require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

module.exports = {
  solidity: "0.8.20",
  networks: {
    "polygon-zkevm-testnet": {
      url: process.env.POLYGON_ZKEVM_TESTNET_RPC,
      accounts: [process.env.PRIVATE_KEY]
    },
    "polygon-zkevm-mainnet": {
      url: process.env.POLYGON_ZKEVM_MAINNET_RPC,
      accounts: [process.env.PRIVATE_KEY]
    }
  },
  etherscan: {
    apiKey: {
      polygonZKEVMTestnet: process.env.POLYGONSCAN_API_KEY,
      polygonZKEMV: process.env.POLYGONSCAN_API_KEY
    }
  }
};
