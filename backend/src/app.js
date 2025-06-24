const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const { errorHandler } = require('./middleware/errorHandler.js');
const authRoutes = require('./routes/auth.js');
const transactionRoutes = require('./routes/transactions.js');
const kycRoutes = require('./routes/kyc.js');
const royaltiesRoutes = require('./routes/royalties.js');
const vestingRoutes = require('./routes/vesting.js');
require('dotenv').config();

const app = express();

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json());

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/transactions', transactionRoutes);
app.use('/api/kyc', kycRoutes);
app.use('/api/royalties', royaltiesRoutes);
app.use('/api/vesting', vestingRoutes);
app.use('/api/sacco', require('./routes/sacco'));

// Error Handler
app.use(errorHandler);

// Database Connection
mongoose.connect(process.env.MONGO_URI, { useNewUrlParser: true, useUnifiedTopology: true })
  .then(() => console.log('Connected to MongoDB'))
  .catch((err) => console.error('MongoDB connection error:', err));

// Start Server
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
