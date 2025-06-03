// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SHPTransaction.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenRebaser is Ownable {
    SHPTransaction public token;
    uint256 public lastRebase;
    uint256 public constant REBASE_INTERVAL = 1 days;
    uint256 public constant MAX_SUPPLY_CHANGE = 3 * 10**16; // 3% per rebase

    event RebaseTriggered(uint256 amount, bool isExpansion);

    constructor(address _tokenAddress) Ownable(msg.sender) {
        require(_tokenAddress != address(0), "Invalid token address");
        token = SHPTransaction(_tokenAddress);
        lastRebase = block.timestamp;
    }

    function rebase(uint256 amount, bool isExpansion) external onlyOwner {
        require(block.timestamp >= lastRebase + REBASE_INTERVAL, "Too soon");
        require(amount <= (token.totalSupply() * MAX_SUPPLY_CHANGE) / 1000, "Exceeds max change");
        lastRebase = block.timestamp;
        
        if (isExpansion) {
            token.rebaseMint(msg.sender, amount);
        } else {
            token.rebaseBurn(msg.sender, amount);
        }
        emit RebaseTriggered(amount, isExpansion);
    }
}
