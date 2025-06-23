const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('SHP_Reserve', function () {
  let reserve, owner, minter, user;

  beforeEach(async () => {
    [owner, minter, user] = await ethers.getSigners();
    const Reserve = await ethers.getContractFactory('SHP_Reserve');
    reserve = await Reserve.deploy(
      '0xMockKSHOracle',
      '0xMockETHOracle',
      '0xMockInflationOracle',
      '0xMockKotaniAddress'
    );
    await reserve.deployed();
    await reserve.authorizeMinter(minter.address, true);
    await reserve.verifyKYC(user.address, true);
  });

  it('should mint tokens for KYC-verified users', async function () {
    await reserve.connect(minter).mint(user.address, ethers.utils.parseEther('1000'));
    expect(await reserve.balanceOf(user.address)).to.equal(ethers.utils.parseEther('1000'));
  });

  it('should fail minting for non-KYC-verified users', async function () {
    await reserve.verifyKYC(user.address, false);
    await expect(
      reserve.connect(minter).mint(user.address, ethers.utils.parseEther('1000'))
    ).to.be.revertedWith('KYC verification required');
  });

  it('should fail minting with zero amount', async function () {
    await expect(
      reserve.connect(minter).mint(user.address, 0)
    ).to.be.revertedWith('Amount must be greater than 0');
  });
});
