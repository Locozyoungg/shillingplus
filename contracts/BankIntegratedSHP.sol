// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./SHP_Utility.sol";
import "./SHP_Reserve.sol";
import "./Treasury.sol";
import "./ForeverRoyalties.sol";
import "./KotaniAdapter.sol";
import "./BankAdapter.sol";

contract BankIntegratedSHP is ERC20, Pausable, Ownable, ReentrancyGuard, Initializable {
    using SafeERC20 for IERC20;

    // ShillingPlus contracts
    SHP_Utility public shpT;
    SHP_Reserve public shpR;
    Treasury public treasury;
    ForeverRoyalties public royalties;
    KotaniAdapter public kotaniAdapter;
    BankAdapter public bankAdapter;

    // Collateral management
    uint256 public totalCollateral;
    uint256 public constant MIN_COLLATERAL_RATIO = 110; // 110%

    // Chainlink price feeds
    AggregatorV3Interface internal kshUsdFeed;
    AggregatorV3Interface internal ethUsdFeed;

    // Bank integration
    struct Bank {
        string name;
        address wallet;
        bool authorized;
        uint256 dailyLimit;
        uint256 dailyVolume;
        uint256 lastReset;
    }
    mapping(string => Bank) public banks;
    mapping(address => string) public bankAccounts;
    mapping(address => bool) public verifiedUsers;
    string[] public bankNames; // Enumerable list of banks

    // SACCO integration
    mapping(address => bool) public authorizedSACCOs;
    mapping(address => uint256) public saccoSubscriptions; // Timestamp of last payment
    uint256 public constant SACCO_SUBSCRIPTION_FEE = 100_000 * 10**18; // 100,000 KSH in SHP-T
    uint256 public constant SACCO_SUBSCRIPTION_DURATION = 30 days;

    // Fees
    uint256 public depositFee = 50; // 0.5%
    uint256 public withdrawalFee = 50; // 0.5%
    uint256 public constant TREASURY_FEE = 15; // 15% to treasury (aligned with ShillingPlus)

    // Events
    event BankRegistered(string name, address wallet);
    event BankAuthorizationChanged(string name, bool authorized);
    event Deposit(address indexed user, uint256 amount, string bank);
    event Withdrawal(address indexed user, uint256 amount, string bank);
    event UserVerified(address indexed user);
    event DailyLimitUpdated(string bank, uint256 newLimit);
    event SACCOAuthorized(address indexed sacco, bool authorized);
    event SACCOSubscribed(address indexed sacco, uint256 expiry);

    constructor() ERC20("ShillingPlus Integrated", "SHP-I") {
        _disableInitializers(); // Prevent initialization during deployment
    }

    function initialize(
        address _shpT,
        address _shpR,
        address _treasury,
        address _royalties,
        address _kotaniAdapter,
        address _bankAdapter,
        address _kshFeed,
        address _ethFeed,
        address _creator
    ) external initializer onlyOwner {
        __Ownable_init(_creator);
        __Pausable_init();

        shpT = SHP_Utility(_shpT);
        shpR = SHP_Reserve(_shpR);
        treasury = Treasury(_treasury);
        royalties = ForeverRoyalties(_royalties);
        kotaniAdapter = KotaniAdapter(_kotaniAdapter);
        bankAdapter = BankAdapter(_bankAdapter);
        kshUsdFeed = AggregatorV3Interface(_kshFeed);
        ethUsdFeed = AggregatorV3Interface(_ethFeed);

        // Initialize banks (aligned with ShillingPlus)
        _registerBank("KCB", 0x1234567890123456789012345678901234567890, 1_000_000 * 10**18);
        _registerBank("Equity", 0x2345678901234567890123456789012345678901, 1_000_000 * 10**18);
        _registerBank("Cooperative", 0x3456789012345678901234567890123456789012, 750_000 * 10**18);
        _registerBank("Standard Chartered", 0x4567890123456789012345678901234567890123, 500_000 * 10**18);
    }

    modifier onlyBank() {
        string memory bankName = bankAccounts[msg.sender];
        require(bytes(bankName).length > 0, "Not a bank account");
        require(banks[bankName].authorized, "Bank not authorized");
        _;
    }

    modifier onlyVerified() {
        require(verifiedUsers[msg.sender], "User not verified");
        _;
    }

    modifier onlyAuthorizedSACCO() {
        require(authorizedSACCOs[msg.sender], "Not an authorized SACCO");
        require(saccoSubscriptions[msg.sender] >= block.timestamp, "SACCO subscription expired");
        _;
    }

    // Bank management
    function registerBank(string memory _name, address _wallet, uint256 _dailyLimit) external onlyOwner {
        _registerBank(_name, _wallet, _dailyLimit);
    }

    function _registerBank(string memory _name, address _wallet, uint256 _dailyLimit) internal {
        require(bytes(_name).length > 0, "Invalid bank name");
        banks[_name] = Bank({
            name: _name,
            wallet: _wallet,
            authorized: true,
            dailyLimit: _dailyLimit,
            dailyVolume: 0,
            lastReset: block.timestamp
        });
        bankNames.push(_name);
        emit BankRegistered(_name, _wallet);
    }

    function authorizeBank(string memory _name, bool _authorized) external onlyOwner {
        require(bytes(_name).length > 0, "Invalid bank name");
        banks[_name].authorized = _authorized;
        emit BankAuthorizationChanged(_name, _authorized);
    }

    function updateDailyLimit(string memory _name, uint256 _newLimit) external onlyOwner {
        require(bytes(_name).length > 0, "Invalid bank name");
        banks[_name].dailyLimit = _newLimit;
        emit DailyLimitUpdated(_name, _newLimit);
    }

    // SACCO management
    function authorizeSACCO(address _sacco, bool _authorized) external onlyOwner {
        authorizedSACCOs[_sacco] = _authorized;
        emit SACCOAuthorized(_sacco, _authorized);
    }

    function subscribeSACCO() external {
        require(authorizedSACCOs[msg.sender], "Not an authorized SACCO");
        require(shpT.balanceOf(msg.sender) >= SACCO_SUBSCRIPTION_FEE, "Insufficient SHP-T");
        shpT.safeTransferFrom(msg.sender, address(treasury), SACCO_SUBSCRIPTION_FEE);
        saccoSubscriptions[msg.sender] = block.timestamp + SACCO_SUBSCRIPTION_DURATION;
        emit SACCOSubscribed(msg.sender, saccoSubscriptions[msg.sender]);
    }

    // User verification
    function verifyUser(address _user) external onlyBank {
        verifiedUsers[_user] = true;
        emit UserVerified(_user);
    }

    // Bank account linking
    function linkBankAccount(string memory _bankName) external {
        require(bytes(_bankName).length > 0, "Invalid bank name");
        require(banks[_bankName].authorized, "Bank not authorized");
        bankAccounts[msg.sender] = _bankName;
    }

    // Deposits
    function depositFromBank(uint256 _amount) external onlyVerified whenNotPaused nonReentrant {
        string memory bankName = bankAccounts[msg.sender];
        require(bytes(bankName).length > 0, "Bank account not linked");
        Bank storage bank = banks[bankName];
        _resetDailyVolumeIfNeeded(bank);
        require(bank.dailyVolume + _amount <= bank.dailyLimit, "Daily limit exceeded");

        // Calculate fees
        uint256 fee = (_amount * depositFee) / 10_000;
        uint256 treasuryFee = (fee * TREASURY_FEE) / 100;
        uint256 netAmount = _amount - fee;

        // Mint SHP-T and SHP-R (1:100 ratio)
        shpT.mintForDeposit(msg.sender, netAmount);
        shpR.mintForDeposit(msg.sender, netAmount / 100);

        // Update collateral
        totalCollateral += _convertToUSD(netAmount);

        // Update bank volume
        bank.dailyVolume += _amount;

        // Transfer fees to treasury
        if (treasuryFee > 0) {
            shpT.mintForDeposit(address(treasury), treasuryFee);
            shpR.mintForDeposit(address(treasury), treasuryFee / 100);
        }

        emit Deposit(msg.sender, _amount, bankName);
    }

    function depositFromMpesa(uint256 _amount, string memory _phone) external onlyVerified whenNotPaused nonReentrant {
        kotaniAdapter.processDeposit(msg.sender, _amount, _phone);
        uint256 fee = (_amount * depositFee) / 10_000;
        uint256 treasuryFee = (fee * TREASURY_FEE) / 100;
        uint256 netAmount = _amount - fee;

        // Update collateral
        totalCollateral += _convertToUSD(netAmount);

        // Transfer fees to treasury
        if (treasuryFee > 0) {
            shpT.mintForDeposit(address(treasury), treasuryFee);
            shpR.mintForDeposit(address(treasury), treasuryFee / 100);
        }

        emit Deposit(msg.sender, _amount, "M-Pesa");
    }

    // Withdrawals
    function withdrawToBank(uint256 _amount) external onlyVerified whenNotPaused nonReentrant {
        string memory bankName = bankAccounts[msg.sender];
        require(bytes(bankName).length > 0, "Bank account not linked");
        Bank storage bank = banks[bankName];
        _resetDailyVolumeIfNeeded(bank);
        require(bank.dailyVolume + _amount <= bank.dailyLimit, "Daily limit exceeded");

        // Calculate fees
        uint256 fee = (_amount * withdrawalFee) / 10_000;
        uint256 treasuryFee = (fee * TREASURY_FEE) / 100;
        uint256 netAmount = _amount - fee;

        // Burn tokens
        shpT.burnForWithdrawal(msg.sender, netAmount);
        shpR.burnForWithdrawal(msg.sender, netAmount / 100);

        // Update collateral
        uint256 usdValue = _convertToUSD(netAmount);
        require(usdValue <= totalCollateral, "Insufficient collateral");
        totalCollateral -= usdValue;

        // Update bank volume
        bank.dailyVolume += _amount;

        // Transfer fees to treasury
        if (treasuryFee > 0) {
            shpT.mintForDeposit(address(treasury), treasuryFee);
            shpR.mintForDeposit(address(treasury), treasuryFee / 100);
        }

        // Trigger bank transfer via BankAdapter
        bytes32 withdrawalId = keccak256(abi.encodePacked(msg.sender, block.timestamp));
        bankAdapter.initiateWithdrawal(msg.sender, netAmount, withdrawalId, banks[bankName].wallet);

        emit Withdrawal(msg.sender, _amount, bankName);
    }

    function withdrawToMpesa(uint256 _amount, string memory _phone) external onlyVerified whenNotPaused nonReentrant {
        kotaniAdapter.initiateWithdrawal(msg.sender, _amount, _phone);
        uint256 fee = (_amount * withdrawalFee) / 10_000;
        uint256 treasuryFee = (fee * TREASURY_FEE) / 100;
        uint256 netAmount = _amount - fee;

        // Burn tokens
        shpT.burnForWithdrawal(msg.sender, netAmount);
        shpR.burnForWithdrawal(msg.sender, netAmount / 100);

        // Update collateral
        uint256 usdValue = _convertToUSD(netAmount);
        require(usdValue <= totalCollateral, "Insufficient collateral");
        totalCollateral -= usdValue;

        // Transfer fees to treasury
        if (treasuryFee > 0) {
            shpT.mintForDeposit(address(treasury), treasuryFee);
            shpR.mintForDeposit(address(treasury), treasuryFee / 100);
        }

        emit Withdrawal(msg.sender, _amount, "M-Pesa");
    }

    // Batch processing for SACCOs
    function batchDepositForSACCO(address[] calldata _users, uint256[] calldata _amounts, string memory _bankName)
        external
        onlyAuthorizedSACCO
        whenNotPaused
        nonReentrant
    {
        require(_users.length == _amounts.length, "Arrays length mismatch");
        require(bytes(_bankName).length > 0, "Invalid bank name");
        Bank storage bank = banks[_bankName];
        _resetDailyVolumeIfNeeded(bank);

        uint256 totalAmount;
        for (uint256 i = 0; i < _amounts.length; i++) {
            totalAmount += _amounts[i];
        }
        require(bank.dailyVolume + totalAmount <= bank.dailyLimit, "Daily limit exceeded");

        for (uint256 i = 0; i < _users.length; i++) {
            require(verifiedUsers[_users[i]], "User not verified");
            uint256 fee = (_amounts[i] * depositFee) / 10_000;
            uint256 treasuryFee = (fee * TREASURY_FEE) / 100;
            uint256 netAmount = _amounts[i] - fee;

            shpT.mintForDeposit(_users[i], netAmount);
            shpR.mintForDeposit(_users[i], netAmount / 100);
            totalCollateral += _convertToUSD(netAmount);

            if (treasuryFee > 0) {
                shpT.mintForDeposit(address(treasury), treasuryFee);
                shpR.mintForDeposit(address(treasury), treasuryFee / 100);
            }

            emit Deposit(_users[i], _amounts[i], _bankName);
        }

        bank.dailyVolume += totalAmount;
    }

    // Internal helpers
    function _resetDailyVolumeIfNeeded(Bank storage _bank) internal {
        if (block.timestamp > _bank.lastReset + 1 days) {
            _bank.dailyVolume = 0;
            _bank.lastReset = block.timestamp;
        }
    }

    function _convertToUSD(uint256 _amount) internal view returns (uint256) {
        (, int256 kshPrice,,,) = kshUsdFeed.latestRoundData();
        (, int256 ethPrice,,,) = ethUsdFeed.latestRoundData();
        require(kshPrice > 0, "Invalid KSH price");
        require(ethPrice > 0, "Invalid ETH price");

        // 80% KSH, 20% ETH collateral
        uint256 kshValue = (_amount * uint256(kshPrice) * 80) / 100 / 10**8;
        uint256 ethValue = (_amount * uint256(ethPrice) * 20) / 100 / 10**8;
        return (kshValue + ethValue) * 10**10; // Scale to 18 decimals
    }

    // Collateral health
    function collateralRatio() public view returns (uint256) {
        uint256 totalTokens = shpT.totalSupply() + (shpR.totalSupply() * 100); // SHP-R at 1:100
        if (totalTokens == 0) return type(uint256).max;
        return (totalCollateral * 100) / totalTokens;
    }

    // Bank utilities
    function getBankCount() public view returns (uint256) {
        return bankNames.length;
    }

    function getBankNameAtIndex(uint256 _index) public view returns (string memory) {
        require(_index < bankNames.length, "Invalid index");
        return bankNames[_index];
    }

    // Fee management
    function updateFees(uint256 _depositFee, uint256 _withdrawalFee) external onlyOwner {
        require(_depositFee <= 100, "Deposit fee too high"); // Max 1%
        require(_withdrawalFee <= 100, "Withdrawal fee too high"); // Max 1%
        depositFee = _depositFee;
        withdrawalFee = _withdrawalFee;
    }

    // Emergency controls
    function emergencyPause() external onlyOwner {
        _pause();
    }

    function emergencyUnpause() external onlyOwner {
        _unpause();
    }
}
