# ShillingPlus Backend

Node.js/Express backend for ShillingPlus, handling user authentication, transactions, and KYC.

## Setup
1. Install dependencies: `npm install`
2. Configure `.env` file
3. Start server: `npm start` or `npm run dev` for development

## Endpoints
- **Auth**: `/api/auth/register`, `/api/auth/login`
- **Transactions**: `/api/transactions/deposit`, `/api/transactions/withdraw`, `/api/transactions/history`
- **KYC**: `/api/kyc/submit`, `/api/kyc/verify`
