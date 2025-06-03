const onfido = require('onfido-sdk'); // Hypothetical
const crypto = require('crypto');
const config = require('../config/env');

const onfidoClient = new onfido({ apiToken: config.onfidoToken });

exports.verifyUserKyc = async (userId, document, selfie) => {
  try {
    const applicant = await onfidoClient.applicant.create({ externalId: userId });
    await onfidoClient.document.upload(applicant.id, document);
    await onfidoClient.check.create(applicant.id, { type: 'standard', selfie });
    const result = await onfidoClient.check.retrieve(applicant.id);
    return result.status === 'complete' && result.result === 'clear';
  } catch (error) {
    console.error('KYC error:', error);
    return false;
  }
};

exports.encryptWalletKey = (privateKey) => {
  const cipher = crypto.createCipher('aes-256-cbc', config.encryptionKey);
  let encrypted = cipher.update(privateKey, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  return encrypted;
};

exports.decryptWalletKey = (encryptedKey) => {
  const decipher = crypto.createDecipher('aes-256-cbc', config.encryptionKey);
  let decrypted = decipher.update(encryptedKey, 'hex', 'utf8');
  decrypted += decipher.final('utf8');
  return decrypted;
};
