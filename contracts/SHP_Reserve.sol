// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./interfaces/IKotani.sol";

contract SHP_Reserve is ERC20, Ownable, ReentrancyGuard {
    uint256 public totalCollateral;
    uint256 public ethCollateralRatio = 20;
    uint256 public constant MIN_COLLATERAL_RATIO = 110;
    
    AggregatorV3Interface internal kshUsdFeed;
    AggregatorV3Interface internal ethUsdFeed;
    AggregatorV3Interface internal inflationFeed;
    
    IKotani public kotani;
    mapping(address => bool) public authorizedMinters;
    mapping(address => bool) public kycVerified;
    
    event CollateralAdjusted(uint256 newEthRatio);
    event TokensMinted(address indexed user, uint256 amount);
    event TokensBurned(address indexed user, uint256 amount);

    constructor(
        address _kshOracle,
        address _ethOracle,
        address _inflationOracle,
        address _kotaniAddress
    ) ERC20("ShillingPlus Reserve", "SHP-R") Ownable(msg.sender) {
        require(_kshOracle != address(0), "Invalid KSH oracle");
        require(_ethOracle != address(0), "Invalid ETH oracle");
        require(_inflationOracle != address(0), "Invalid inflation oracle");
        require(_kotaniAddress != address(0), "Invalid Kotani address");
        
        kshUsdFeed = AggregatorV3Interface(_kshOracle);
        ethUsdFeed = AggregatorV3Interface(_ethOracle);
        inflationFeed = AggregatorV3Interface(_inflationOracle);
        kotani = IKotani(_kotaniAddress);
        
        _mint(msg.sender, 900_000_000 * 10**18);
    }

    modifier onlyMinter() {
        require(authorizedMinters[msg.sender], "Unauthorized minter");
        _;
    }

    function adjustForInflation() external nonReentrant {
        (uint80 roundId, int256 inflationRate, , uint256 updatedAt, ) = inflationFeed.latestRoundData();
        require(inflationRate > 0, "Invalid inflation rate");
        require(updatedAt >= block.timestamp - 1 hours, "Stale inflation data");
        
        if (inflationRate > 5e8) {
            ethCollateralRatio = 20 + (uint256(inflationRate) - 5e8) / 1e8;
            emit CollateralAdjusted(ethCollateralRatio);
        }
    }

    function mint(address user, uint256 kshAmount) external onlyMinter nonReentrant {
        require(kycVerified[user], "KYC verification required");
        require(user != address(0), "Invalid user address");
        require(kshAmount > 0, "Amount must be greater than 0");
        
        uint256 collateralValue = _calculateCollateral(kshAmount);
        totalCollateral += collateralValue;
        
        uint256 maxMint = (totalCollateral * 100) / MIN_COLLATERAL_RATIO;
        require(totalSupply() + kshAmount <= maxMint, "Undercollateralized");
        
        _mint(user, kshAmount);
        emit TokensMinted(user, kshAmount);
    }

    function burn(address user, uint256 amount) external onlyMinter nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(balanceOf(user) >= amount, "Insufficient balance");
        
        uint256 collateralValue = _calculateCollateral(amount);
        require(totalCollateral >= collateralValue, "Insufficient collateral");
        
        _burn(user, amount);
        totalCollateral -= collateralValue;
        emit TokensBurned(user, amount);
    }

    function batchTransfer(
        address to,
        uint256 totalAmount,
        uint256 batchSize
    ) external nonReentrant {
        require(to != address(0), "Invalid recipient");
        require(totalAmount > 0, "Amount must be greater than 0");
        require(batchSize > 0, "Batch size must be greater than 0");
        require(totalAmount <= balanceOf(msg.sender), "Insufficient balance");
        
        uint256 batches = totalAmount / batchSize;
        uint256 remaining = totalAmount % batchSize;
        
        for (uint256 i = 0; i < batches; i++) {
            _transfer(msg.sender, to, batchSize);
        }
        if (remaining > 0) {
            _transfer(msg.sender, to, remaining);
        }
    }

    function authorizeMinter(address minter, bool status) external onlyOwner {
        require(minter != address(0), "Invalid minter address");
        authorizedMinters[minter] = status;
    }

    function verifyKYC(address user, bool status) external onlyOwner {
        require(user != address(0), "Invalid user address");
        kycVerified[user] = status;
    }

    function _calculateCollateral(uint256 amount) internal view returns (uint256) {
        (, int256 kshPrice, , uint256 kshUpdatedAt, ) = kshUsdFeed.latestRoundData();
        (, int256 ethPrice, , uint256 ethUpdatedAt, ) = ethUsdFeed.latestRoundData();
        
        require(kshPrice > 0, "Invalid KSH price");
        require(ethPrice > 0, "Invalid ETH price");
        require(kshUpdatedAt >= block.timestamp - 1 hours, "Stale KSH data");
        require(ethUpdatedAt >= block.timestamp - 1 hours, "Stale ETH data");
        
        uint256 kshValue = (amount * uint256(kshPrice) * (100 - ethCollateralRatio)) / 100;
        uint256 ethValue = (amount * uint256(ethPrice) * ethCollateralRatio) / 100;
        
        return (kshValue + ethValue) / 1e8;
    }
}

// Add to existing SHP_Reserve.sol
address public bankIntegratedSHP;

function setBankIntegratedSHP(address _bankIntegratedSHP) external onlyOwner {
    require(_bankIntegratedSHP != address(0), "Invalid address");
    bankIntegratedSHP = _bankIntegratedSHP;
}

function mintForDeposit(address to, uint256 amount) external nonReentrant {
    require(msg.sender == bankAdapter || msg.sender == bankIntegratedSHP, "Only adapters");
    _mint(to, amount);
}

function burnForWithdrawal(address from, uint256 amount) external nonReentrant {
    require(msg.sender == bankAdapter || msg.sender == bankIntegratedSHP, "Only adapters");
    _burn(from, amount);
}
