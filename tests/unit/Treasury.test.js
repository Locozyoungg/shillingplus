const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('Treasury', function () {
  let treasury, shpR, shpT, royalties, owner, liquidityPool, legalWallet;

  beforeEach(async () => {
    [owner, liquidityPool, legalWallet] = await ethers.getSigners();
    
    const Royalties = await ethers.getContractFactory('ForeverRoyalties');
    royalties = await Royalties.deploy();
    await royalties.deployed();

    const Reserve = await ethers.getContractFactory('SHP_Reserve');
    shpR = await Reserve.deploy(
      '0xMockKSHOracle',
      '0xMockETHOracle',
      '0xMockInflationOracle',
      '0xMockKotaniAddress'
    );
    await shpR.deployed();

    const Utility = await ethers.getContractFactory('SHP_Utility');
    shpT = await Utility.deploy(royalties.address, '0xMockKSHOracle');
    await shpT.deployed();

    const Treasury = await ethers.getContractFactory('Treasury');
    treasury = await Treasury.deploy(shpR.address, shpT.address, royalties.address);
    await treasury.deployed();

    await treasury.setLiquidityPool(liquidityPool.address);
    await treasury.setLegalWallet(legalWallet.address);

    // Transfer tokens to treasury for testing
    await shpT.transfer(treasury.address, ethers.utils.parseEther('1000'));
  });

  it('should distribute fees correctly', async function () {
    await treasury.distributeFees();
    expect(await shpT.balanceOf(royalties.address)).to.be.closeTo(ethers.utils.parseEther('150'), ethers.utils.parseEther('1'));
    expect(await shpT.balanceOf(liquidityPool.address)).to.be.closeTo(ethers.utils.parseEther('100'), ethers.utils.parseEther('1'));
    expect(await shpT.balanceOf(legalWallet.address)).to.be.closeTo(ethers.utils.parseEther('50'), ethers.utils.parseEther('1'));
  });
});
