const express = require('express');
const mongoose = require('mongoose');
const config = require('./config/env');
const paymentRoutes = require('./controllers/payment.controller');

const app = express();

app.use(express.json());
app.use('/api/payments', paymentRoutes);

mongoose.connect(config.mongoUri, { useNewUrlParser: true, useUnifiedTopology: true })
  .then(() => console.log('MongoDB connected'))
  .catch(err => console.error('MongoDB error:', err));

app.listen(config.port, () => console.log(`Server running on port ${config.port}`));
