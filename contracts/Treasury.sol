// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./SHP_Reserve.sol";
import "./SHP_Utility.sol";
import "./ForeverRoyalties.sol";

contract Treasury is Ownable, ReentrancyGuard {
    SHP_Reserve public shpR;
    SHP_Utility public shpT;
    ForeverRoyalties public royalties;

    struct Allocation {
        uint16 reserveGrowth;
        uint16 userIncentives;
        uint16 tokenBurn;
        uint16 liquidity;
        uint16 legal;
        uint16 creatorShare;
    }

    Allocation public allocations = Allocation(30, 20, 20, 10, 5, 15);
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    address public liquidityPool;
    address public legalWallet;
    mapping(address => bool) public whitelistedAddresses;

    event FeesDistributed(uint256 totalAmount);
    event AllocationUpdated(Allocation newAllocation);
    event EmergencyWithdrawal(address indexed token, address indexed to, uint256 amount);
    event AddressWhitelisted(address indexed account, bool status);

    constructor(address _reserve, address _utility, address _royalties) Ownable(msg.sender) {
        require(_reserve != address(0), "Invalid reserve address");
        require(_utility != address(0), "Invalid utility address");
        require(_royalties != address(0), "Invalid royalties address");
        shpR = SHP_Reserve(_reserve);
        shpT = SHP_Utility(_utility);
        royalties = ForeverRoyalties(_royalties);
        whitelistedAddresses[msg.sender] = true;
        whitelistedAddresses[_royalties] = true;
        emit AddressWhitelisted(msg.sender, true);
        emit AddressWhitelisted(_royalties, true);
    }

    function distributeFees() external onlyOwner nonReentrant {
        uint256 shpRBalance = shpR.balanceOf(address(this));
        uint256 shpTBalance = shpT.balanceOf(address(this));
        uint256 ethBalance = address(this).balance;
        require(shpRBalance > 0 || shpTBalance > 0 || ethBalance > 0, "No fees to distribute");

        // Distribute SHP-R
        if (shpRBalance > 0) {
            _distribute(shpR, shpRBalance);
        }

        // Distribute SHP-T
        if (shpTBalance > 0) {
            _distribute(shpT, shpTBalance);
        }

        // Distribute ETH to ForeverRoyalties
        if (ethBalance > 0) {
            uint256 creatorAmount = (ethBalance * allocations.creatorShare) / 100;
            (bool sent,) = address(royalties).call{value: creatorAmount}("");
            require(sent, "Creator share transfer failed");
        }

        emit FeesDistributed(shpRBalance + shpTBalance + ethBalance);
    }

    function _distribute(IERC20 token, uint256 balance) internal {
        // Burn portion
        uint256 burnAmount = (balance * allocations.tokenBurn) / 100;
        if (burnAmount > 0) {
            require(whitelistedAddresses[BURN_ADDRESS], "Burn address not whitelisted");
            token.transfer(BURN_ADDRESS, burnAmount);
        }

        // Liquidity pool
        uint256 liquidityAmount = (balance * allocations.liquidity) / 100;
        if (liquidityAmount > 0 && liquidityPool != address(0)) {
            require(whitelistedAddresses[liquidityPool], "Liquidity pool not whitelisted");
            token.transfer(liquidityPool, liquidityAmount);
        }

        // Legal/compliance
        uint256 legalAmount = (balance * allocations.legal) / 100;
        if (legalAmount > 0 && legalWallet != address(0)) {
            require(whitelistedAddresses[legalWallet], "Legal wallet not whitelisted");
            token.transfer(legalWallet, legalAmount);
        }

        // Reinvest reserve growth (for SHP-R only)
        if (address(token) == address(shpR)) {
            uint256 reinvestAmount = (balance * allocations.reserveGrowth) / 100;
            if (reinvestAmount > 0) {
                shpR.mint(address(this), reinvestAmount);
            }
        }

        // Creator share
        uint256 creatorAmount = (balance * allocations.creatorShare) / 100;
        if (creatorAmount > 0) {
            require(whitelistedAddresses[address(royalties)], "Royalties not whitelisted");
            token.transfer(address(royalties), creatorAmount);
        }
    }

    function setAllocations(
        uint16 reserveGrowth,
        uint16 userIncentives,
        uint16 tokenBurn,
        uint16 liquidity,
        uint16 legal,
        uint16 creatorShare
    ) external onlyOwner {
        require(reserveGrowth + userIncentives + tokenBurn + liquidity + legal + creatorShare == 100,
                "Allocations must sum to 100");

        allocations = Allocation(reserveGrowth, userIncentives, tokenBurn, liquidity, legal, creatorShare);
        emit AllocationUpdated(allocations);
    }

    function setLiquidityPool(address pool) external onlyOwner {
        require(pool != address(0), "Invalid pool address");
        liquidityPool = pool;
        whitelistedAddresses[pool] = true;
        emit AddressWhitelisted(pool, true);
    }

    function setLegalWallet(address wallet) external onlyOwner {
        require(wallet != address(0), "Invalid wallet address");
        legalWallet = wallet;
        whitelistedAddresses[wallet] = true;
        emit AddressWhitelisted(wallet, true);
    }

    function setWhitelistedAddress(address _account, bool _status) external onlyOwner {
        require(_account != address(0), "Invalid address");
        whitelistedAddresses[_account] = _status;
        emit AddressWhitelisted(_account, _status);
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

    receive() external payable {}
}
