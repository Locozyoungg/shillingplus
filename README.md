# ShillingPlus (SHP)

A dual-token payment system for Kenya, with SHP-R (store of value) and SHP-T (transaction medium), integrated with M-Pesa, banks, and USSD/SMS.

## Setup

1. Clone the repo:
   ```bash
   git clone https://github.com/yourusername/shillingplus.git
   cd shillingplus

Install dependencies:

 npm install

Configure environment:

 cp .env

Start backend:

 npm start

Run frontend:

 cd frontend
 npx expo start

Schedule daily updates:

 npm run auto-update

Testing

 npm test

Roadmap
Q3 2025: MVP on BSC testnet

Q4 2026: Mainnet launch

2027: Scale to 100,000 users


### Deployment Steps
1. **Initialize Repo**:
   ```bash
   git init
   git remote add origin https://github.com/yourusername/shillingplus.git

Install Tools:

 npm install
 npx hardhat

Configure .env:
Add your BSC private key, admin wallet, and API keys (Safaricom, bank, Onfido, Africa’s Talking).

Use MongoDB Atlas for MONGO_URI.


Compile Contracts:

 npx hardhat compile


Deploy to BSC Testnet:

 npm run deploy

Start Backend:

 npm start

Run Frontend:

 cd frontend
 npx expo start

Schedule Updates:

 Install node-cron and schedule auto-update.js daily:
  
  const cron = require('node-cron');
  cron.schedule('0 0 * * *', () => require('./auto-update.js'));


Security Measures
Contracts: Use OpenZeppelin, audit with CertiK (~$3,000) before mainnet.

KYC: Onfido for >500,000 KSH transactions.

Encryption: AES-256 for wallet keys (security.service.js).

Multi-Sig: Use Gnosis Safe for feeCollector and reserve wallets.

Rate Limits: Limit API calls to 100/minute in app.js.


Next Steps
Test: Deploy to BSC testnet, simulate 100 KSH and 1M KSH transactions.

APIs: Secure real M-Pesa (Safaricom Daraja), bank (e.g., KCB), and CBK data APIs.

USSD: Implement Africa’s Talking integration in backend.

Pilot: Target 100 users (e.g., JKUAT students) by Q3 2025.



