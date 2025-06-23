const { ethers } = require('hardhat');
require('dotenv').config();

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log('Configuring contracts with account:', deployer.address);

  const reserveAddress = process.env.SHP_RESERVE_ADDRESS;
  const treasuryAddress = process.env.TREASURY_ADDRESS;
  const kotaniAdapterAddress = process.env.KOTANI_ADAPTER_ADDRESS;

  const Reserve = await ethers.getContractFactory('SHP_Reserve');
  const Treasury = await ethers.getContractFactory('Treasury');

  const reserve = Reserve.attach(reserveAddress);
  const treasury = Treasury.attach(treasuryAddress);

  await reserve.authorizeMinter(kotaniAdapterAddress, true);
  console.log('KotaniAdapter authorized as minter');

  await treasury.setLiquidityPool(process.env.LIQUIDITY_POOL || '0xMockLiquidityPool');
  await treasury.setLegalWallet(process.env.LEGAL_WALLET || '0xMockLegalWallet');
  console.log('Treasury configured');
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
