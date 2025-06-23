const { expect } = require('chai');
const { ethers } = require('hardhat');
const { time } = require('@nomicfoundation/hardhat-network-helpers');

describe('Vesting', function () {
  let vesting, token, owner, beneficiary;
  const TOTAL_AMOUNT = ethers.utils.parseEther('90000000');
  const CLIFF_DURATION = 365 * 24 * 60 * 60; // 1 year
  const VESTING_DURATION = 4 * 365 * 24 * 60 * 60; // 4 years
  const START_TIME = Math.floor(Date.now() / 1000) + 3600;

  beforeEach(async () => {
    [owner, beneficiary] = await ethers.getSigners();
    const Token = await ethers.getContractFactory('SHP_Utility');
    token = await Token.deploy(owner.address, '0xMockKSHOracle', beneficiary.address, START_TIME);
    await token.deployed();

    const Vesting = await ethers.getContractFactory('Vesting');
    vesting = await Vesting.deploy(
      token.address,
      beneficiary.address,
      START_TIME,
      CLIFF_DURATION,
      VESTING_DURATION,
      TOTAL_AMOUNT
    );
    await vesting.deployed();

    await token.transfer(vesting.address, TOTAL_AMOUNT);
  });

  it('should not release tokens before cliff', async function () {
    await expect(vesting.release()).to.be.revertedWith('No tokens to release');
  });

  it('should release tokens linearly after cliff', async function () {
    await time.increase(CLIFF_DURATION + VESTING_DURATION / 2); // 2.5 years
    await vesting.connect(beneficiary).release();
    const balance = await token.balanceOf(beneficiary.address);
    expect(balance).to.be.closeTo(TOTAL_AMOUNT.div(2), ethers.utils.parseEther('1000'));
  });

  it('should release all tokens after vesting duration', async function () {
    await time.increase(VESTING_DURATION + CLIFF_DURATION);
    await vesting.connect(beneficiary).release();
    expect(await token.balanceOf(beneficiary.address)).to.equal(TOTAL_AMOUNT);
  });
});
