const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('KotaniAdapter', function () {
  let reserve, kotaniAdapter, owner, user;

  beforeEach(async () => {
    [owner, user] = await ethers.getSigners();
    const Reserve = await ethers.getContractFactory('SHP_Reserve');
    reserve = await Reserve.deploy(
      '0xMockKSHOracle',
      '0xMockETHOracle',
      '0xMockInflationOracle',
      '0xMockKotaniAddress'
    );
    await reserve.deployed();

    const KotaniAdapter = await ethers.getContractFactory('KotaniAdapter');
    kotaniAdapter = await KotaniAdapter.deploy(reserve.address, '0xMockKotaniAddress');
    await kotaniAdapter.deployed();

    await reserve.authorizeMinter(kotaniAdapter.address, true);
    await reserve.verifyKYC(user.address, true);
  });

  it('should process deposit', async function () {
    await kotaniAdapter.processDeposit(user.address, ethers.utils.parseEther('1000'));
    expect(await reserve.balanceOf(user.address)).to.equal(ethers.utils.parseEther('1000'));
  });

  it('should fail deposit with zero amount', async function () {
    await expect(
      kotaniAdapter.processDeposit(user.address, 0)
    ).to.be.revertedWith('Amount must be greater than 0');
  });
});
