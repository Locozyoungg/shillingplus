import { useState, useEffect } from 'react';
import { Table } from 'react-bootstrap';
import axios from 'axios';

function TransactionHistory({ userId }) {
  const [transactions, setTransactions] = useState([]);

  useEffect(() => {
    const fetchTransactions = async () => {
      try {
        const response = await axios.get(
          `${process.env.REACT_APP_API_URL}/transactions/history`,
          { headers: { Authorization: `Bearer ${localStorage.getItem('token')}` } }
        );
        setTransactions(response.data);
      } catch (error) {
        console.error('Error fetching transactions:', error);
      }
    };
    fetchTransactions();
  }, [userId]);

  return (
    <Table striped bordered hover>
      <thead>
        <tr>
          <th>Type</th>
          <th>Amount</th>
          <th>Status</th>
          <th>Tx Hash</th>
          <th>Date</th>
        </tr>
      </thead>
      <tbody>
        {transactions.map((tx) => (
          <tr key={tx._id}>
            <td>{tx.type}</td>
            <td>{tx.amount}</td>
            <td>{tx.status}</td>
            <td>{tx.txHash?.slice(0, 6)}...{tx.txHash?.slice(-4)}</td>
            <td>{new Date(tx.createdAt).toLocaleString()}</td>
          </tr>
        ))}
      </tbody>
    </Table>
  );
}

export default TransactionHistory;
