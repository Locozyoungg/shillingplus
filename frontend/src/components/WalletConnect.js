import { Button } from 'react-bootstrap';
import { useWeb3 } from '../contexts/Web3Context';

function WalletConnect() {
  const { account, connectWallet, disconnectWallet } = useWeb3();

  return (
    <div>
      {account ? (
        <>
          <p>Connected: {account.slice(0, 6)}...{account.slice(-4)}</p>
          <Button variant="danger" onClick={disconnectWallet}>Disconnect</Button>
        </>
      ) : (
        <Button variant="primary" onClick={connectWallet}>Connect Wallet</Button>
      )}
    </div>
  );
}

export default WalletConnect;
