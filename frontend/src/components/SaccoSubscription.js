import { useState } from 'react';
import { Form, Button, Alert } from 'react-bootstrap';
import axios from 'axios';

function SaccoSubscription() {
  const [message, setMessage] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const response = await axios.post(
        `${process.env.REACT_APP_API_URL}/sacco/subscribe`,
        { saccoAddress: window.ethereum.selectedAddress },
        { headers: { Authorization: `Bearer ${localStorage.getItem('token')}` } }
      );
      setMessage(`SACCO subscribed: ${response.data.txHash}`);
    } catch (error) {
      setMessage(error.response?.data?.message || 'Error subscribing SACCO');
    }
  };

  return (
    <Form onSubmit={handleSubmit}>
      {message && <Alert variant={message.includes('Error') ? 'danger' : 'success'}>{message}</Alert>}
      <Button variant="primary" type="submit">Subscribe SACCO</Button>
    </Form>
  );
}

export default SaccoSubscription;
