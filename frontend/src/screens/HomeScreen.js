import React, { useState, useEffect } from 'react';
import { View, Text, Button, StyleSheet } from 'react-native';
import api from '../utils/api';

const HomeScreen = ({ navigation }) => {
  const [user, setUser] = useState(null);

  useEffect(() => {
    // Mock user fetch
    api.get('/users/0x123').then(res => setUser(res.data));
  }, []);

  return (
    <View style={styles.container}>
      <Text style={styles.title}>ShillingPlus Wallet</Text>
      {user && (
        <>
          <Text>Balance: {user.balance} SHP-T</Text>
          <Text>Reserve: {user.reserveBalance} SHP-R</Text>
          <Button title="Send SHP-T" onPress={() => navigation.navigate('Send')} />
          <Button title="Scan QR" onPress={() => navigation.navigate('Send', { scan: true })} />
        </>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, padding: 20 },
  title: { fontSize: 18, fontWeight: 'bold', marginBottom: 10 },
});

export default HomeScreen;
