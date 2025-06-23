import { useState } from 'react';
import { Container, Form, Button, Alert } from 'react-bootstrap';
import axios from 'axios';

function KYC() {
  const [kycData, setKycData] = useState({ name: '', idNumber: '', document: '' });
  const [message, setMessage] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const response = await axios.post(
        `${process.env.REACT_APP_API_URL}/kyc/submit`,
        { userId: 'mock-user-id', kycData },
        { headers: { Authorization: `Bearer ${localStorage.getItem('token')}` } }
      );
      setMessage(response.data.message);
    } catch (error) {
      setMessage(error.response?.data?.message || 'Error submitting KYC');
    }
  };

  return (
    <Container>
      <h2>KYC Verification</h2>
      <Form onSubmit={handleSubmit}>
        {message && <Alert variant={message.includes('Error') ? 'danger' : 'success'}>{message}</Alert>}
        <Form.Group className="mb-3">
          <Form.Label>Full Name</Form.Label>
          <Form.Control
            type="text"
            value={kycData.name}
            onChange={(e) => setKycData({ ...kycData, name: e.target.value })}
            required
          />
        </Form.Group>
        <Form.Group className="mb-3">
          <Form.Label>ID Number</Form.Label>
          <Form.Control
            type="text"
            value={kycData.idNumber}
            onChange={(e) => setKycData({ ...kycData, idNumber: e.target.value })}
            required
          />
        </Form.Group>
        <Form.Group className="mb-3">
          <Form.Label>Document (URL or File Path)</Form.Label>
          <Form.Control
            type="text"
            value={kycData.document}
            onChange={(e) => setKycData({ ...kycData, document: e.target.value })}
            required
          />
        </Form.Group>
        <Button variant="primary" type="submit">Submit KYC</Button>
      </Form>
    </Container>
  );
}

export default KYC;
