// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract SHPPegOracle is Ownable {
    address public updater;
    uint256 public kshPerToken; // 1 SHP = X KSH (18 decimals)
    uint256 public reserveValue; // Total KSH value of reserve
    address public transactionToken; // SHP-T
    address public reserveToken; // SHP-R
    uint256 public lastUpdate;

    event PriceUpdated(uint256 newPrice, uint256 reserveValue, uint256 timestamp);

    constructor(address _transactionToken, address _reserveToken) Ownable(msg.sender) {
        require(_transactionToken != address(0), "Invalid transaction token");
        require(_reserveToken != address(0), "Invalid reserve token");
        transactionToken = _transactionToken;
        reserveToken = _reserveToken;
        kshPerToken = 1 ether; // Initial 1:1 peg
        updater = msg.sender;
        lastUpdate = block.timestamp;
        reserveValue = 0;
    }

    modifier onlyUpdater() {
        require(msg.sender == updater, "Caller is not the updater");
        _;
    }

    function setUpdater(address _updater) external onlyOwner {
        require(_updater != address(0), "Invalid address");
        updater = _updater;
    }

    function updatePriceAndReserve(uint256 _newPrice, uint256 _reserveValue) external onlyUpdater {
        require(_newPrice > 0, "Price must be positive");
        kshPerToken = _newPrice;
        reserveValue = _reserveValue;
        lastUpdate = block.timestamp;
        emit PriceUpdated(_newPrice, _reserveValue, block.timestamp);
    }

    function getTransactionTokenValue() external view returns (uint256) {
        SHPTransaction token = SHPTransaction(transactionToken);
        uint256 totalSupply = token.totalSupply();
        if (totalSupply == 0) return kshPerToken;
        uint256 circulatingValue = (totalSupply * kshPerToken) / 1e18;
        return (reserveValue + circulatingValue) / totalSupply;
    }

    function getReserveTokenValue() external view returns (uint256) {
        SHPReserve token = SHPReserve(reserveToken);
        uint256 totalSupply = token.totalSupply();
        if (totalSupply == 0) return kshPerToken;
        uint256 circulatingValue = (totalSupply * kshPerToken) / 1e18;
        return (reserveValue + circulatingValue) / totalSupply;
    }

    function tokenToKsh(uint256 tokenAmount) external view returns (uint256) {
        return (tokenAmount * kshPerToken) / 1e18;
    }

    function kshToToken(uint256 kshAmount) external view returns (uint256) {
        return (kshAmount * 1e18) / kshPerToken;
    }
}

interface SHPTransaction {
    function totalSupply() external view returns (uint256);
}

interface SHPReserve {
    function totalSupply() external view returns (uint256);
}
