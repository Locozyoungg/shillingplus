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
        uint16 creatorShare; // Added for ForeverRoyalties
    }
    
    Allocation public allocations = Allocation(30, 20, 20, 10, 5, 15); // Adjusted to include 15% creator share
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    
    address public liquidityPool;
    address public legalWallet;
    
    event FeesDistributed(uint256 totalAmount);
    event AllocationUpdated(Allocation newAllocation);

    constructor(address _reserve, address _utility, address _royalties) Ownable(msg.sender) {
        require(_reserve != address(0), "Invalid reserve address");
        require(_utility != address(0), "Invalid utility address");
        require(_royalties != address(0), "Invalid royalties address");
        shpR = SHP_Reserve(_reserve);
        shpT = SHP_Utility(_utility);
        royalties = ForeverRoyalties(_royalties);
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
            token.transfer(BURN_ADDRESS, burnAmount);
        }
        
        // Liquidity pool
        uint256 liquidityAmount = (balance * allocations.liquidity) / 100;
        if (liquidityAmount > 0 && liquidityPool != address(0)) {
            token.transfer(liquidityPool, liquidityAmount);
        }
        
        // Legal/compliance
        uint256 legalAmount = (balance * allocations.legal) / 100;
        if (legalAmount > 0 && legalWallet != address(0)) {
            token.transfer(legalWallet, legalAmount);
        }
        
        // Reinvest reserve growth (for SHP-R only)
        if (address(token) == address(shpR)) {
            uint256 reinvestAmount = (balance * allocations.reserveGrowth) / 100;
            if (reinvestAmount > 0) {
                shpR.mint(address(this), reinvestAmount);
            }
        }
        
        // Creator share (convert to ETH via liquidity pool if needed)
        uint256 creatorAmount = (balance * allocations.creatorShare) / 100;
        if (creatorAmount > 0) {
            // Assume a liquidity pool swap to ETH; for simplicity, transfer tokens directly to royalties
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
    }

    function setLegalWallet(address wallet) external onlyOwner {
        require(wallet != address(0), "Invalid wallet address");
        legalWallet = wallet;
    }

    receive() external payable {}
}
