// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./Vesting.sol";

contract SHP_Utility is ERC20, Ownable, ReentrancyGuard {
    uint256 public constant MAX_SUPPLY = 900_000_000 * 10**18;
    uint256 public constant CREATOR_RESERVE = 90_000_000 * 10**18; // 10% for creator
    uint256 public burnRate = 50; // 50% of fees are burned
    uint256 public baseFeeRate = 5; // 0.05%
    uint256 public constant KSH_FEE_EXEMPTION_THRESHOLD = 100 * 10**18; // 100 KSH in wei
    
    address public treasury;
    Vesting public vesting;
    AggregatorV3Interface internal kshUsdFeed;
    mapping(address => bool) public feeExempt;
    
    event TokensBurned(address indexed burner, uint256 amount);
    event FeeRateUpdated(uint256 newRate);
    event VestingContractSet(address indexed vesting);

    constructor(
        address _treasury,
        address _kshOracle,
        address _creator,
        uint256 _vestingStartTime
    ) ERC20("ShillingPlus Utility", "SHP-T") Ownable(msg.sender) {
        require(_treasury != address(0), "Invalid treasury address");
        require(_kshOracle != address(0), "Invalid KSH oracle");
        require(_creator != address(0), "Invalid creator address");
        
        treasury = _treasury;
        kshUsdFeed = AggregatorV3Interface(_kshOracle);
        
        // Deploy vesting contract
        vesting = new Vesting(
            address(this),
            _creator,
            _vestingStartTime,
            1 * 365 days, // 1-year cliff
            4 * 365 days, // 4-year vesting
            CREATOR_RESERVE
        );
        emit VestingContractSet(address(vesting));

        // Mint tokens
        _mint(address(this), MAX_SUPPLY);
        _transfer(address(this), address(vesting), CREATOR_RESERVE); // Send to vesting
        _transfer(address(this), msg.sender, MAX_SUPPLY - CREATOR_RESERVE); // Rest to deployer
        feeExempt[msg.sender] = true;
        feeExempt[_treasury] = true;
        feeExempt[address(vesting)] = true;
    }

    function transfer(address to, uint256 amount) public override nonReentrant returns (bool) {
        require(to != address(0), "Invalid recipient");
        require(amount > 0, "Amount must be greater than 0");
        
        uint256 fee = _calculateFee(amount);
        uint256 totalAmount = amount + fee;
        require(balanceOf(msg.sender) >= totalAmount, "Insufficient balance including fee");
        
        if (feeExempt[msg.sender] || feeExempt[to] || fee == 0) {
            return super.transfer(to, amount);
        }
        
        uint256 burnAmount = (fee * burnRate) / 100;
        uint256 treasuryAmount = fee - burnAmount;
        
        if (burnAmount > 0) {
            _burn(msg.sender, burnAmount);
            emit TokensBurned(msg.sender, burnAmount);
        }
        
        if (treasuryAmount > 0) {
            super.transfer(treasury, treasuryAmount);
        }
        
        return super.transfer(to, amount);
    }

    function _calculateFee(uint256 amount) internal view returns (uint256) {
        (, int256 kshPrice, , uint256 updatedAt, ) = kshUsdFeed.latestRoundData();
        require(kshPrice > 0, "Invalid KSH price");
        require(updatedAt >= block.timestamp - 1 hours, "Stale KSH data");
        
        // Convert SHP-T amount to KSH equivalent (assuming 1 SHP-T = 1 KSH for simplicity)
        uint256 kshEquivalent = amount * uint256(kshPrice) / 10**18;
        if (kshEquivalent <= KSH_FEE_EXEMPTION_THRESHOLD) {
            return 0;
        }
        
        return (amount * baseFeeRate) / 10000;
    }

    function setFeeExempt(address account, bool exempt) external onlyOwner {
        require(account != address(0), "Invalid account");
        feeExempt[account] = exempt;
    }

    function updateFeeRate(uint256 newRate) external onlyOwner {
        require(newRate <= 20, "Fee rate too high"); // Max 0.2%
        baseFeeRate = newRate;
        emit FeeRateUpdated(newRate);
    }
}
