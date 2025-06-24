const { expect } = require('chai');
const { ethers } = require('hardhat');
const { time } = require('@nomicfoundation/hardhat-network-helpers');

describe('BankIntegratedSHP', function () {
  let bankIntegratedSHP, shpT, shpR, treasury, royalties, kotaniAdapter, bankAdapter, owner, user, sacco;
  const AMOUNT = ethers.utils.parseEther('1000');

  beforeEach(async () => {
    [owner, user, sacco] = await ethers.getSigners();

    const Utility = await ethers.getContractFactory('SHP_Utility');
    shpT = await Utility.deploy(owner.address, '0xMockKSHOracle', owner.address, Math.floor(Date.now() / 1000));
    await shpT.deployed();

    const Reserve = await ethers.getContractFactory('SHP_Reserve');
    shpR = await Reserve.deploy('0xMockKSHOracle', '0xMockETHOracle', '0xMockInflationOracle', '0xMockKotani');
    await shpR.deployed();

    const Treasury = await ethers.getContractFactory('Treasury');
    treasury = await Treasury.deploy(shpR.address, shpT.address, '0xMockRoyalties');
    await treasury.deployed();

    const Royalties = await ethers.getContractFactory('ForeverRoyalties');
    royalties = await Royalties.deploy(shpT.address, shpR.address, '0xMockUniswapRouter', '0xMockWETH');
    await royalties.deployed();

    const KotaniAdapter = await ethers.getContractFactory('KotaniAdapter');
    kotaniAdapter = await KotaniAdapter.deploy(shpR.address, '0xMockKotani');
    await kotaniAdapter.deployed();

    const BankAdapter = await ethers.getContractFactory('BankAdapter');
    bankAdapter = await BankAdapter.deploy(shpT.address, shpR.address, treasury.address, owner.address);
    await bankAdapter.deployed();

    const BankIntegratedSHP = await ethers.getContractFactory('BankIntegratedSHP');
    bankIntegratedSHP = await BankIntegratedSHP.deploy();
    await bankIntegratedSHP.deployed();

    await bankIntegratedSHP.initialize(
      shpT.address,
      shpR.address,
      treasury.address,
      royalties.address,
      kotaniAdapter.address,
      bankAdapter.address,
      '0xMockKSHOracle',
      '0xMockETHOracle',
      owner.address
    );

    await shpT.setBankIntegratedSHP(bankIntegratedSHP.address);
    await shpR.setBankIntegratedSHP(bankIntegratedSHP.address);
    await bankIntegratedSHP.verifyUser(user.address);
    await bankIntegratedSHP.linkBankAccount('KCB');
  });

  it('should process bank deposit', async function () {
    await bankIntegratedSHP.connect(user).depositFromBank(AMOUNT);
    expect(await shpT.balanceOf(user.address)).to.equal(AMOUNT.sub(AMOUNT.mul(50).div(10000))); // 0.5% fee
  });

  it('should process SACCO batch deposit', async function () {
    await bankIntegratedSHP.authorizeSACCO(sacco.address, true);
    await shpT.mint(sacco.address, ethers.utils.parseEther('100000')); // Subscription fee
    await bankIntegratedSHP.connect(sacco).subscribeSACCO();
    await bankIntegratedSHP.connect(sacco).batchDepositForSACCO([user.address], [AMOUNT], 'KCB');
    expect(await shpT.balanceOf(user.address)).to.equal(AMOUNT.sub(AMOUNT.mul(50).div(10000)));
  });

  it('should maintain collateral ratio', async function () {
    await bankIntegratedSHP.connect(user).depositFromBank(AMOUNT);
    expect(await bankIntegratedSHP.collateralRatio()).to.be.gte(MIN_COLLATERAL_RATIO);
  });
});
