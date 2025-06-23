const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('SHP_Utility', function () {
  let utility, owner, treasury, user;

  beforeEach(async () => {
    [owner, treasury, user] = await ethers.getSigners();
    const Utility = await ethers.getContractFactory('SHP_Utility');
    utility = await Utility.deploy(treasury.address, '0xMockKSHOracle');
    await utility.deployed();
  });

  it('should apply fees on top of transfer amount', async function () {
    await utility.transfer(user.address, ethers.utils.parseEther('1000'));
    const userBalance = await utility.balanceOf(user.address);
    const treasuryBalance = await utility.balanceOf(treasury.address);
    expect(userBalance).to.equal(ethers.utils.parseEther('1000')); // Receiver gets full amount
    expect(treasuryBalance).to.be.closeTo(ethers.utils.parseEther('0.25'), ethers.utils.parseEther('0.1'));
  });

  it('should exempt transactions <= 100 KSH', async function () {
    // Mock small amount (assuming 1 SHP-T = 1 KSH for simplicity)
    await utility.transfer(user.address, ethers.utils.parseEther('50'));
    expect(await utility.balanceOf(user.address)).to.equal(ethers.utils.parseEther('50'));
    expect(await utility.balanceOf(treasury.address)).to.equal(0);
  });

  it('should exempt treasury from fees', async function () {
    await utility.transfer(treasury.address, ethers.utils.parseEther('1000'));
    expect(await utility.balanceOf(treasury.address)).to.equal(ethers.utils.parseEther('1000'));
  });
});
