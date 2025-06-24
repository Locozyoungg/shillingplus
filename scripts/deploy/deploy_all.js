const { ethers } = require('hardhat');
require('dotenv').config();

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log('Deploying contracts with account:', deployer.address);

  const KSH_ORACLE = process.env.KSH_ORACLE || '0x9acD0d9D840726aE1Bc93d59d60D393d6d5C5Fb1';
  const ETH_ORACLE = process.env.ETH_ORACLE || '0x0715A7794a1dc8e42615F059dD6e406A6594651A';
  const INFLATION_ORACLE = process.env.INFLATION_ORACLE || '0x5e5D8F30A0aDBf97DB3c63D5656dFaC6D4f6A3F7';
  const KOTANI_ADDRESS = process.env.KOTANI_ADDRESS || '0xMockKotaniAddress';
  const UNISWAP_ROUTER = process.env.UNISWAP_ROUTER || '0xMockUniswapRouter';
  const WETH = process.env.WETH || '0xMockWETH';
  const VESTING_START_TIME = process.env.VESTING_START_TIME || Math.floor(Date.now() / 1000) + 3600; // 1 hour from now

  // Deploy SHP_Reserve
  const Reserve = await ethers.getContractFactory('SHP_Reserve');
  const shpR = await Reserve.deploy(KSH_ORACLE, ETH_ORACLE, INFLATION_ORACLE, KOTANI_ADDRESS);
  await shpR.deployed();
  console.log('SHP_Reserve deployed to:', shpR.address);

  // Deploy ForeverRoyalties
  const Royalties = await ethers.getContractFactory('ForeverRoyalties');
  const royalties = await Royalties.deploy('0xMockSHP-T', '0xMockSHP-R', UNISWAP_ROUTER, WETH);
  await royalties.deployed();
  console.log('ForeverRoyalties deployed to:', royalties.address);

  // Deploy Treasury
  const Treasury = await ethers.getContractFactory('Treasury');
  const treasury = await Treasury.deploy(shpR.address, '0xMockSHP-T', royalties.address);
  await treasury.deployed();
  console.log('Treasury deployed to:', treasury.address);

  // Deploy SHP_Utility and Vesting
  const Utility = await ethers.getContractFactory('SHP_Utility');
  const shpT = await Utility.deploy(treasury.address, KSH_ORACLE, deployer.address, VESTING_START_TIME);
  await shpT.deployed();
  console.log('SHP_Utility deployed to:', shpT.address);
  const vestingAddress = await shpT.vesting();
  console.log('Vesting deployed to:', vestingAddress);

  // Update ForeverRoyalties with token addresses
  await royalties.updateTokenAddresses(shpT.address, shpR.address);
  console.log('ForeverRoyalties updated with token addresses');

  // Update Treasury with SHP_Utility address
  await treasury.setAllocations(30, 20, 20, 10, 5, 15);
  console.log('Treasury updated with allocations');

  // Deploy KotaniAdapter
  const KotaniAdapter = await ethers.getContractFactory('KotaniAdapter');
  const kotaniAdapter = await KotaniAdapter.deploy(shpR.address, KOTANI_ADDRESS);
  await kotaniAdapter.deployed();
  console.log('KotaniAdapter deployed to:', kotaniAdapter.address);

  // Configure contracts
  await shpR.authorizeMinter(kotaniAdapter.address, true);
  await treasury.setLiquidityPool(process.env.LIQUIDITY_POOL || '0xMockLiquidityPool');
  await treasury.setLegalWallet(process.env.LEGAL_WALLET || '0xMockLegalWallet');
  console.log('Configuration completed');

  console.log('Contract addresses:');
  console.log(`SHP_Reserve: ${shpR.address}`);
  console.log(`SHP_Utility: ${shpT.address}`);
  console.log(`Treasury: ${treasury.address}`);
  console.log(`KotaniAdapter: ${kotaniAdapter.address}`);
  console.log(`ForeverRoyalties: ${royalties.address}`);
  console.log(`Vesting: ${vestingAddress}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
}

// Banks
const BankIntegratedSHP = await ethers.getContractFactory('BankIntegratedSHP');
const bankIntegratedSHP = await BankIntegratedSHP.deploy();
await bankIntegratedSHP.deployed();
console.log('BankIntegratedSHP deployed to:', bankIntegratedSHP.address);

await bankIntegratedSHP.initialize(
  shpT.address,
  shpR.address,
  treasury.address,
  royalties.address,
  kotaniAdapter.address,
  bankAdapter.address,
  KSH_ORACLE,
  ETH_ORACLE,
  deployer.address
);
console.log('BankIntegratedSHP initialized');

await shpT.setBankIntegratedSHP(bankIntegratedSHP.address);
await shpR.setBankIntegratedSHP(bankIntegratedSHP.address);
console.log('BankIntegratedSHP configured');

console.log(`BankIntegratedSHP: ${bankIntegratedSHP.address}`);
