const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  const creatorWallet = "YOUR_CREATOR_WALLET_ADDRESS"; // Replace
  const feeCollector = "YOUR_FEE_COLLECTOR_ADDRESS"; // Replace

  console.log("Deploying contracts with:", deployer.address);

  // Deploy SHPReserve
  const SHPReserve = await hre.ethers.getContractFactory("SHPReserve");
  const shpReserve = await SHPReserve.deploy(creatorWallet);
  await shpReserve.waitForDeployment();
  console.log("SHPReserve deployed to:", shpReserve.target);

  // Deploy SHPTransaction
  const SHPTransaction = await hre.ethers.getContractFactory("SHPTransaction");
  const shpTransaction = await SHPTransaction.deploy(shpReserve.target);
  await shpTransaction.waitForDeployment();
  console.log("SHPTransaction deployed to:", shpTransaction.target);

  // Deploy SHPPegOracle
  const SHPPegOracle = await hre.ethers.getContractFactory("SHPPegOracle");
  const pegOracle = await SHPPegOracle.deploy(shpTransaction.target, shpReserve.target);
  await pegOracle.waitForDeployment();
  console.log("SHPPegOracle deployed to:", pegOracle.target);

  // Deploy MpesaBridge
  const MpesaBridge = await hre.ethers.getContractFactory("MpesaBridge");
  const mpesaBridge = await MpesaBridge.deploy(shpTransaction.target, feeCollector, 100, 50); // 1% withdrawal, 0.5% deposit
  await mpesaBridge.waitForDeployment();
  console.log("MpesaBridge deployed to:", mpesaBridge.target);

  // Deploy BankBridge
  const BankBridge = await hre.ethers.getContractFactory("BankBridge");
  const bankBridge = await BankBridge.deploy(shpTransaction.target, feeCollector, 100); // 1% withdrawal
  await bankBridge.waitForDeployment();
  console.log("BankBridge deployed to:", bankBridge.target);

  // Deploy TokenRebaser
  const TokenRebaser = await hre.ethers.getContractFactory("TokenRebaser");
  const tokenRebaser = await TokenRebaser.deploy(shpTransaction.target);
  await tokenRebaser.waitForDeployment();
  console.log("TokenRebaser deployed to:", tokenRebaser.target);

  // Configure
  await shpTransaction.setMpesaBridge(mpesaBridge.target);
  await shpTransaction.setBankBridge(bankBridge.target);
  await shpTransaction.setRebaser(tokenRebaser.target);
  console.log("Bridges and rebaser configured");
}

main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
