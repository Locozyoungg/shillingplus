import React, { useState } from 'react';
import { View, Text, TextInput, Button, StyleSheet, Alert } from 'react-native';
import QRScanner from '../components/QRScanner';
import api from '../utils/api';

const SendScreen = ({ route }) => {
  const [user] = useState({ walletAddress: '0x123...', balance: 1000000 }); // Mock
  const [amount, setAmount] = useState('');
  const [recipient, setRecipient] = useState('');
  const [method, setMethod] = useState('wallet'); // wallet, mpesa, bank
  const { scan } = route.params || {};

  const handleSend = async () => {
    try {
      if (parseFloat(amount) > 500000) {
        const kycVerified = await api.get(`/users/${user.walletAddress}/kyc`);
        if (!kycVerified.data.verified) {
          Alert.alert('KYC Required', 'Complete KYC for transactions over 500,000 KSH');
          return;
        }
      }
      let endpoint = '/payments/transfer';
      if (method === 'mpesa') endpoint = '/payments/withdrawMpesa';
      if (method === 'bank') endpoint = '/payments/withdrawBank';
      
      const response = await api.post(endpoint, {
        from: user.walletAddress,
        to: recipient,
        amount,
        ...(method === 'mpesa' && { phone: recipient }),
        ...(method === 'bank' && { bankAccount: recipient }),
      });
      if (response.data.success) {
        Alert.alert('Success', `Sent ${amount} SHP-T`);
      }
    } catch (error) {
      Alert.alert('Error', 'Transaction failed');
    }
  };

  const handleScan = (data) => {
    setRecipient(data.address);
    setAmount(data.amount);
  };

  return (
    <View style={styles.container}>
      {scan ? (
        <QRScanner onScan={handleScan} />
      ) : (
        <>
          <Text style={styles.title}>Send SHP-T</Text>
          <TextInput
            style={styles.input}
            placeholder="Recipient (Wallet, Phone, or Bank Account)"
            value={recipient}
            onChangeText={setRecipient}
          />
          <TextInput
            style={styles.input}
            placeholder="Amount (SHP-T)"
            value={amount}
            onChangeText={setAmount}
            keyboardType="numeric"
          />
          <Button title="Wallet Transfer" onPress={() => setMethod('wallet')} />
          <Button title="M-Pesa Withdrawal" onPress={() => setMethod('mpesa')} />
          <Button title="Bank Withdrawal" onPress={() => setMethod('bank')} />
          <Button title="Send" onPress={handleSend} />
        </>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, padding: 20 },
  title: { fontSize: 18, fontWeight: 'bold', marginBottom: 10 },
  input: { borderWidth: 1, borderColor: '#ccc', padding: 10, marginBottom: 10 },
});

export default SendScreen;
