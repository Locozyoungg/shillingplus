# ShillingPlus

A decentralized stablecoin platform integrated with Kotani Pay for M-Pesa bridging, built on Polygon zkEVM.

## Overview
ShillingPlus provides a collateralized stablecoin (SHP-R) and utility token (SHP-T) with:
- Inflation-adjusted reserves
- M-Pesa integration
- Fee management and treasury
- KYC verification
- Batch transactions

## Structure
- **contracts/**: Solidity smart contracts
- **backend/**: Node.js/Express API
- **frontend/**: React-based UI
- **scripts/**: Deployment and utility scripts
- **test/**: Unit and integration tests

## Setup
1. Clone the repo: `git clone <repo-url>`
2. Install dependencies: `npm install`
3. Configure `.env` files in root, backend, and frontend directories
4. Compile contracts: `npx hardhat compile`
5. Deploy contracts: `npm run deploy:testnet`
6. Start backend: `cd backend && npm start`
7. Start frontend: `cd frontend && npm start`

## Deployment
- Testnet: Polygon zkEVM Testnet
- Mainnet: Polygon zkEVM Mainnet
- Verify contracts: `npm run verify`

## License
MIT
