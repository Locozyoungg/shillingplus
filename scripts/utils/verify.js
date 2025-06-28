// shillingplus/scripts/utils/verify.js
require('dotenv').config();
const { run } = require('hardhat');

async function main() {
  const contracts = [
    {
      name: 'ForeverRoyalties',
      address: process.env.FOREVER_ROYALTIES_ADDRESS,
      args: [
        process.env.SHP_T_ADDRESS,
        process.env.SHP_R_ADDRESS,
        process.env.UNISWAP_ROUTER,
        process.env.WETH,
      ],
    },
    {
      name: 'SHP_Reserve',
      address: process.env.SHP_RESERVE_ADDRESS,
      args: [
        process.env.KSH_ORACLE,
        process.env.ETH_ORACLE,
        process.env.INFLATION_ORACLE,
        process.env.KOTANI_ADDRESS,
      ],
    },
    {
      name: 'SHP_Utility',
      address: process.env.SHP_UTILITY_ADDRESS,
      args: [
        process.env.TREASURY_ADDRESS,
        process.env.KSH_ORACLE,
        process.env.CREATOR_ADDRESS,
        process.env.VESTING_START_TIME,
      ],
    },
    {
      name: 'KotaniAdapter',
      address: process.env.KOTANI_ADAPTER_ADDRESS,
      args: [process.env.SHP_RESERVE_ADDRESS, process.env.KOTANI_ADDRESS],
    },
    {
      name: 'Treasury',
      address: process.env.TREASURY_ADDRESS,
      args: [
        process.env.SHP_RESERVE_ADDRESS,
        process.env.SHP_UTILITY_ADDRESS,
        process.env.FOREVER_ROYALTIES_ADDRESS,
      ],
    },
    {
      name: 'Vesting',
      address: process.env.VESTING_ADDRESS,
      args: [
        process.env.SHP_UTILITY_ADDRESS,
        process.env.CREATOR_ADDRESS,
        process.env.VESTING_START_TIME,
        1 * 365 * 24 * 60 * 60, // 1-year cliff
        4 * 365 * 24 * 60 * 60, // 4-year vesting
        90_000_000 * 10**18,
      ],
    },
    {
      name: 'BankIntegratedSHP',
      address: process.env.BANK_INTEGRATED_SHP_ADDRESS,
      args: [], // Constructor args empty due to initialize
    },
  ];

  for (const contract of contracts) {
    console.log(`Verifying ${contract.name} at ${contract.address}`);
    try {
      await run('verify:verify', {
        address: contract.address,
        constructorArguments: contract.args,
      });
      console.log(`${contract.name} verified`);
    } catch (error) {
      console.error(`Error verifying ${contract.name}:`, error);
    }
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
