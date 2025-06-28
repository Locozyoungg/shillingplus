// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./Vesting.sol";

contract SHP_Utility is ERC20, Ownable, ReentrancyGuard {
    // Constants
    uint256 public constant MAX_SUPPLY = 900_000_000 * 10**18;
    uint256 public constant CREATOR_RESERVE = 90_000_000 * 10**18; // 10% for creator
    uint256 public constant KSH_FEE_EXEMPTION_THRESHOLD = 100 * 10**18; // 100 KSH in wei

    // State variables
    uint256 public burnRate = 50; // 50% of fees are burned
    uint256 public baseFeeRate = 5; // 0.05%
    address public treasury;
    address public bankIntegratedSHP;
    address public bankAdapter;
    Vesting public vesting;
    AggregatorV3Interface internal kshUsdFeed;
    mapping(address => bool) public feeExempt;
    mapping(address => bool) public whitelistedAddresses; // Whitelist for transfers

    // Events
    event TokensBurned(address indexed burner, uint256 amount);
    event TokensMinted(address indexed to, uint256 amount);
    event FeeRateUpdated(uint256 newRate);
    event VestingContractSet(address indexed vesting);
    event AddressWhitelisted(address indexed account, bool status);
    event EmergencyWithdrawal(address indexed token, address indexed to, uint256 amount);
    event BankAdapterSet(address indexed bankAdapter);

    // Constructor
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

        // Set fee exemptions and whitelist
        feeExempt[msg.sender] = true;
        feeExempt[_treasury] = true;
        feeExempt[address(vesting)] = true;
        whitelistedAddresses[msg.sender] = true;
        whitelistedAddresses[_treasury] = true;
        whitelistedAddresses[address(vesting)] = true;
    }

    // Modifiers
    modifier onlyAdapters() {
        require(msg.sender == bankAdapter || msg.sender == bankIntegratedSHP, "Only adapters");
        _;
    }

    // External functions
    function transfer(address to, uint256 amount) public override nonReentrant returns (bool) {
        require(to != address(0), "Invalid recipient");
        require(amount > 0, "Amount must be greater than 0");
        require(whitelistedAddresses[to], "Recipient not whitelisted");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");

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

    function setFeeExempt(address account, bool exempt) external onlyOwner {
        require(account != address(0), "Invalid account");
        feeExempt[account] = exempt;
    }

    function updateFeeRate(uint256 newRate) external onlyOwner {
        require(newRate <= 20, "Fee rate too high"); // Max 0.2%
        baseFeeRate = newRate;
        emit FeeRateUpdated(newRate);
    }

    function setBankIntegratedSHP(address _bankIntegratedSHP) external onlyOwner {
        require(_bankIntegratedSHP != address(0), "Invalid address");
        bankIntegratedSHP = _bankIntegratedSHP;
        whitelistedAddresses[_bankIntegratedSHP] = true;
        emit AddressWhitelisted(_bankIntegratedSHP, true);
    }

    function setBankAdapter(address _bankAdapter) external onlyOwner {
        require(_bankAdapter != address(0), "Invalid address");
        bankAdapter = _bankAdapter;
        whitelistedAddresses[_bankAdapter] = true;
        emit BankAdapterSet(_bankAdapter);
        emit AddressWhitelisted(_bankAdapter, true);
    }

    function setWhitelistedAddress(address _account, bool _status) external onlyOwner {
        require(_account != address(0), "Invalid address");
        whitelistedAddresses[_account] = _status;
        emit AddressWhitelisted(_account, _status);
    }

    function mintForDeposit(address to, uint256 amount) external nonReentrant onlyAdapters {
        require(to != address(0), "Invalid recipient");
        require(amount > 0, "Amount must be greater than 0");
        require(totalSupply() + amount <= MAX_SUPPLY, "Exceeds max supply");
        _mint(to, amount);
        emit TokensMinted(to, amount);
    }

    function burnForWithdrawal(address from, uint256 amount) external nonReentrant onlyAdapters {
        require(from != address(0), "Invalid address");
        require(amount > 0, "Amount must be greater than 0");
        require(balanceOf(from) >= amount, "Insufficient balance");
        _burn(from, amount);
        emit TokensBurned(from, amount);
    }

    function emergencyWithdraw(address _token, address _to, uint256 _amount) external onlyOwner nonReentrant {
        require(_to != address(0), "Invalid recipient");
        if (_token == address(0)) {
            (bool sent,) = _to.call{value: _amount}("");
            require(sent, "ETH transfer failed");
        } else {
            IERC20(_token).safeTransfer(_to, _amount);
        }
        emit EmergencyWithdrawal(_token, _to, _amount);
    }

    // Internal functions
    function _calculateFee(uint256 amount) internal view returns (uint256) {
        (, int256 kshPrice, , uint256 updatedAt, ) = kshUsdFeed.latestRoundData();
        require(kshPrice > 0, "Invalid KSH price");
        require(updatedAt >= block.timestamp - 1 hours, "Stale KSH data");

        uint256 kshEquivalent = amount * uint256(kshPrice) / 10**18;
        if (kshEquivalent <= KSH_FEE_EXEMPTION_THRESHOLD) {
            return 0;
        }

        return (amount * baseFeeRate) / 10000;
    }
}
