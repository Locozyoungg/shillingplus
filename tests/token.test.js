const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("SHPTransaction", function () {
  let shpTransaction, owner, addr1;

  beforeEach(async function () {
    const SHPReserve = await ethers.getContractFactory("SHPReserve");
    const shpReserve = await SHPReserve.deploy("0x123");
    await shpReserve.waitForDeployment();

    const SHPTransaction = await ethers.getContractFactory("SHPTransaction");
    shpTransaction = await SHPTransaction.deploy(shpReserve.target);
    await shpTransaction.waitForDeployment();

    [owner, addr1] = await ethers.getSigners();
  });

  it("Should burn 0.1% on transfer", async function () {
    await shpTransaction.transfer(addr1.address, ethers.parseEther("1000"));
    const balance = await shpTransaction.balanceOf(addr1.address);
    expect(balance).to.equal(ethers.parseEther("999"));
  });
});
