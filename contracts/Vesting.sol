// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Vesting is Ownable, ReentrancyGuard {
    IERC20 public token;
    address public beneficiary;
    uint256 public startTime;
    uint256 public cliffDuration;
    uint256 public vestingDuration;
    uint256 public totalAmount;
    uint256 public releasedAmount;

    event TokensReleased(address indexed beneficiary, uint256 amount);
    event VestingInitialized(address indexed beneficiary, uint256 amount, uint256 startTime);

    constructor(
        address _token,
        address _beneficiary,
        uint256 _startTime,
        uint256 _cliffDuration,
        uint256 _vestingDuration,
        uint256 _totalAmount
    ) Ownable(msg.sender) {
        require(_token != address(0), "Invalid token address");
        require(_beneficiary != address(0), "Invalid beneficiary address");
        require(_startTime >= block.timestamp, "Start time must be in the future");
        require(_cliffDuration <= _vestingDuration, "Cliff longer than vesting duration");
        require(_totalAmount > 0, "Amount must be greater than 0");

        token = IERC20(_token);
        beneficiary = _beneficiary;
        startTime = _startTime;
        cliffDuration = _cliffDuration;
        vestingDuration = _vestingDuration;
        totalAmount = _totalAmount;

        emit VestingInitialized(_beneficiary, _totalAmount, _startTime);
    }

    function release() external nonReentrant {
        require(msg.sender == beneficiary || msg.sender == owner(), "Not authorized");
        uint256 vested = vestedAmount();
        require(vested > releasedAmount, "No tokens to release");

        uint256 amount = vested - releasedAmount;
        releasedAmount += amount;

        require(token.transfer(beneficiary, amount), "Token transfer failed");
        emit TokensReleased(beneficiary, amount);
    }

    function vestedAmount() public view returns (uint256) {
        if (block.timestamp < startTime + cliffDuration) {
            return 0;
        }
        if (block.timestamp >= startTime + vestingDuration) {
            return totalAmount;
        }
        return (totalAmount * (block.timestamp - startTime)) / vestingDuration;
    }

    function remainingAmount() public view returns (uint256) {
        return totalAmount - releasedAmount;
    }
}
