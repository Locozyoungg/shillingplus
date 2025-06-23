import { Container, Row, Col, Card } from 'react-bootstrap';
import DepositForm from '../components/DepositForm';
import WithdrawForm from '../components/WithdrawForm';
import TransactionHistory from '../components/TransactionHistory';
import WalletConnect from '../components/WalletConnect';
import RoyaltiesWithdraw from '../components/RoyaltiesWithdraw';
import VestingRelease from '../components/VestingRelease';
import { useWeb3 } from '../contexts/Web3Context';

function Dashboard() {
  const { account } = useWeb3();
  // Mock userId and isAdmin (replace with actual user authentication)
  const userId = 'mock-user-id';
  const isAdmin = true; // Replace with actual admin check

  return (
    <Container>
      <h2>Dashboard</h2>
      <Row>
        <Col md={4}>
          <Card>
            <Card.Body>
              <Card.Title>Wallet</Card.Title>
              <WalletConnect />
            </Card.Body>
          </Card>
        </Col>
        <Col md={4}>
          <Card>
            <Card.Body>
              <Card.Title>Deposit</Card.Title>
              {account ? <DepositForm userId={userId} /> : <p>Connect wallet to deposit</p>}
            </Card.Body>
          </Card>
        </Col>
        <Col md={4}>
          <Card>
            <Card.Body>
              <Card.Title>Withdraw</Card.Title>
              {account ? <WithdrawForm userId={userId} /> : <p>Connect wallet to withdraw</p>}
            </Card.Body>
          </Card>
        </Col>
      </Row>
      {isAdmin && (
        <Row className="mt-4">
          <Col md={4}>
            <Card>
              <Card.Body>
                <Card.Title>Royalties</Card.Title>
                <RoyaltiesWithdraw />
              </Card.Body>
            </Card>
          </Col>
          <Col md={4}>
            <Card>
              <Card.Body>
                <Card.Title>Vesting</Card.Title>
                <VestingRelease />
              </Card.Body>
            </Card>
          </Col>
        </Row>
      )}
      <Row className="mt-4">
        <Col>
          <Card>
            <Card.Body>
              <Card.Title>Transaction History</Card.Title>
              {account ? <TransactionHistory userId={userId} /> : <p>Connect wallet to view history</p>}
            </Card.Body>
          </Card>
        </Col>
      </Row>
    </Container>
  );
}

export default Dashboard;
