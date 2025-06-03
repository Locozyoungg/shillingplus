// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SHPTransaction.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MpesaBridge is Ownable {
    SHPTransaction public token;
    address public feeCollector;
    uint256 public withdrawalFee; // e.g., 100 for 1%
    uint256 public depositFee; // e.g., 50 for 0.5%

    event DepositProcessed(address indexed user, uint256 tokenAmount, string phoneNumber);
    event WithdrawalRequested(address indexed user, uint256 tokenAmount, string phoneNumber);

    constructor(address _tokenAddress, address _feeCollector, uint256 _withdrawalFee, uint256 _depositFee) 
        Ownable(msg.sender) {
        require(_tokenAddress != address(0), "Invalid token address");
        require(_feeCollector != address(0), "Invalid fee collector");
        token = SHPTransaction(_tokenAddress);
        feeCollector = _feeCollector;
        withdrawalFee = _withdrawalFee;
        depositFee = _depositFee;
    }

    function setFeeCollector(address _feeCollector) external onlyOwner {
        require(_feeCollector != address(0), "Invalid address");
        feeCollector = _feeCollector;
    }

    function setWithdrawalFee(uint256 _withdrawalFee) external onlyOwner {
        withdrawalFee = _withdrawalFee;
    }

    function setDepositFee(uint256 _depositFee) external onlyOwner {
        depositFee = _depositFee;
    }

    function depositFromMpesa(uint256 tokenAmount, string calldata phoneNumber) external {
        require(tokenAmount > 0, "Amount must be positive");
        uint256 fee = (tokenAmount * depositFee) / 10000;
        uint256 netAmount = tokenAmount - fee;
        token.mint(msg.sender, netAmount);
        token.mint(feeCollector, fee);
        emit DepositProcessed(msg.sender, netAmount, phoneNumber);
    }

    function withdrawToMpesa(uint256 tokenAmount, string calldata phoneNumber) external {
        require(tokenAmount > 0, "Amount must be positive");
        require(token.balanceOf(msg.sender) >= tokenAmount, "Insufficient balance");
        uint256 fee = (tokenAmount * withdrawalFee) / 10000;
        uint256 netAmount = tokenAmount - fee;
        token.transferFrom(msg.sender, feeCollector, fee);
        token.transferFrom(msg.sender, address(this), netAmount);
        token.bridgeBurn(address(this), netAmount);
        emit WithdrawalRequested(msg.sender, netAmount, phoneNumber);
    }

    function batchWithdrawToMpesa(uint256[] calldata amounts, string[] calldata phoneNumbers) external {
        require(amounts.length == phoneNumbers.length, "Array length mismatch");
        for (uint i = 0; i < amounts.length; i++) {
            withdrawToMpesa(amounts[i], phoneNumbers[i]);
        }
    }
}
