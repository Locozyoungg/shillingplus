// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SHPReserve is ERC20, Ownable {
    address public creatorWallet;
    uint256 public constant CREATOR_SHARE = 90_000_000 * 10**18; // 10% of 900M
    uint256 public vestingStart;
    uint256 public constant VESTING_DURATION = 4 * 365 days;
    uint256 public released;
    
    event CreatorTokensReleased(address indexed creator, uint256 amount);

    constructor(address _creatorWallet) ERC20("ShillingPlus Reserve", "SHP-R") Ownable(msg.sender) {
        require(_creatorWallet != address(0), "Invalid creator address");
        creatorWallet = _creatorWallet;
        vestingStart = block.timestamp;
        released = 0;
        _mint(_creatorWallet, CREATOR_SHARE); // 10% to creator
        _mint(msg.sender, 810_000_000 * 10**18); // 90% for pools, distribution
    }

    function releasableAmount() public view returns (uint256) {
        if (block.timestamp < vestingStart) return 0;
        uint256 elapsed = block.timestamp - vestingStart;
        if (elapsed >= VESTING_DURATION) return CREATOR_SHARE - released;
        uint256 vested = (CREATOR_SHARE * elapsed) / VESTING_DURATION;
        return vested - released;
    }

    function releaseCreatorTokens() external {
        require(msg.sender == creatorWallet, "Caller is not the creator");
        uint256 amount = releasableAmount();
        require(amount > 0, "No tokens to release");
        released += amount;
        _transfer(address(this), creatorWallet, amount);
        emit CreatorTokensReleased(creatorWallet, amount);
    }

    // Staking for merchant discounts (burns to enhance value)
    function stake(uint256 amount) external {
        require(amount > 0, "Amount must be positive");
        _burn(msg.sender, amount); // Burn to reduce supply
        // Discounts tracked off-chain
    }

    // Mint for SHP-T conversion
    function mint(address account, uint256 amount) external onlyOwner {
        require(account != address(0), "Invalid account");
        _mint(account, amount);
    }
}
