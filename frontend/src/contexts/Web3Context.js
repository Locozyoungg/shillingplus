import { createContext, useContext, useState, useEffect } from 'react';
import { InjectedConnector } from '@web3-react/injected-connector';
import { Web3ReactProvider, useWeb3React } from '@web3-react/core';
import { ethers } from 'ethers';

const Web3Context = createContext();

const injected = new InjectedConnector({ supportedChainIds: [1101, 1442] }); // Polygon zkEVM Mainnet & Testnet

export function Web3Provider({ children }) {
  const { activate, deactivate, account, library } = useWeb3React();
  const [provider, setProvider] = useState(null);

  const connectWallet = async () => {
    try {
      await activate(injected);
    } catch (error) {
      console.error('Error connecting wallet:', error);
    }
  };

  const disconnectWallet = () => {
    deactivate();
  };

  useEffect(() => {
    if (library) {
      setProvider(new ethers.providers.Web3Provider(library));
    }
  }, [library]);

  return (
    <Web3Context.Provider value={{ account, provider, connectWallet, disconnectWallet }}>
      {children}
    </Web3Context.Provider>
  );
}

export function useWeb3() {
  return useContext(Web3Context);
}

export function Web3ReactWrapper({ children }) {
  return <Web3ReactProvider getLibrary={(provider) => provider}>{children}</Web3ReactProvider>;
}
