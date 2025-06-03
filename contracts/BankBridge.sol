// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SHPTransaction.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BankBridge is Ownable {
    SHPTransaction public token;
    address public feeCollector;
    uint256 public withdrawalFee; // e.g., 100 for 1%

    event WithdrawalRequested(address indexed user, uint256 tokenAmount, string bankAccount);

    constructor(address _tokenAddress, address _feeCollector, uint256 _withdrawalFee) Ownable(msg.sender) {
        require(_tokenAddress != address(0), "Invalid token address");
        require(_feeCollector != address(0), "Invalid fee collector");
        token = SHPTransaction(_tokenAddress);
        feeCollector = _feeCollector;
        withdrawalFee = _withdrawalFee;
    }

    function setFeeCollector(address _feeCollector) external onlyOwner {
        require(_feeCollector != address(0), "Invalid address");
        feeCollector = _feeCollector;
    }

    function setWithdrawalFee(uint256 _withdrawalFee) external onlyOwner {
        withdrawalFee = _withdrawalFee;
    }

    function withdrawToBank(uint256 tokenAmount, string calldata bankAccount) external {
        require(tokenAmount > 0, "Amount must be positive");
        require(token.balanceOf(msg.sender) >= tokenAmount, "Insufficient balance");
        uint256 fee = (tokenAmount * withdrawalFee) / 10000;
        uint256 netAmount = tokenAmount - fee;
        token.transferFrom(msg.sender, feeCollector, fee);
        token.transferFrom(msg.sender, address(this), netAmount);
        token.bridgeBurn(address(this), netAmount);
        emit WithdrawalRequested(msg.sender, netAmount, bankAccount);
    }

    function batchWithdrawToBank(uint256[] calldata amounts, string[] calldata bankAccounts) external {
        require(amounts.length == bankAccounts.length, "Array length mismatch");
        for (uint i = 0; i < amounts.length; i++) {
            withdrawToBank(amounts[i], bankAccounts[i]);
        }
    }
}
