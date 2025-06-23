import { Container, Jumbotron, Button } from 'react-bootstrap';
import { Link } from 'react-router-dom';

function Home() {
  return (
    <Container>
      <Jumbotron>
        <h1>Welcome to ShillingPlus</h1>
        <p>A decentralized stablecoin platform with M-Pesa integration.</p>
        <Link to="/dashboard">
          <Button variant="primary">Get Started</Button>
        </Link>
      </Jumbotron>
    </Container>
  );
}

export default Home;
