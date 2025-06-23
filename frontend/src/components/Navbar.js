import { Navbar as BootstrapNavbar, Nav, Button } from 'react-bootstrap';
import { useWeb3 } from '../contexts/Web3Context';
import { Link } from 'react-router-dom';

function Navbar() {
  const { account, connectWallet, disconnectWallet } = useWeb3();

  return (
    <BootstrapNavbar bg="dark" variant="dark" expand="lg">
      <BootstrapNavbar.Brand as={Link} to="/">ShillingPlus</BootstrapNavbar.Brand>
      <BootstrapNavbar.Toggle aria-controls="basic-navbar-nav" />
      <BootstrapNavbar.Collapse id="basic-navbar-nav">
        <Nav className="me-auto">
          <Nav.Link as={Link} to="/">Home</Nav.Link>
          <Nav.Link as={Link} to="/dashboard">Dashboard</Nav.Link>
          <Nav.Link as={Link} to="/kyc">KYC</Nav.Link>
        </Nav>
        <Nav>
          {account ? (
            <>
              <Nav.Link>{account.slice(0, 6)}...{account.slice(-4)}</Nav.Link>
              <Button variant="outline-light" onClick={disconnectWallet}>Disconnect</Button>
            </>
          ) : (
            <Button variant="primary" onClick={connectWallet}>Connect Wallet</Button>
          )}
        </Nav>
      </BootstrapNavbar.Collapse>
    </BootstrapNavbar>
  );
}

export default Navbar;
