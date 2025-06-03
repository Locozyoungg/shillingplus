require('dotenv').config();

module.exports = {
  port: process.env.PORT || 5000,
  web3Provider: process.env.WEB3_PROVIDER || 'https://data-seed-prebsc-1-s1.binance.org:8545',
  adminWallet: process.env.ADMIN_WALLET,
  mpesaApiKey: process.env.MPESA_API_KEY,
  bankApiKey: process.env.BANK_API_KEY,
  onfidoToken: process.env.ONFIDO_TOKEN,
  encryptionKey: process.env.ENCRYPTION_KEY,
  mongoUri: process.env.MONGO_URI,
  africastsTalkingApiKey: process.env.AFRICASTS_TALKING_API_KEY,
};
