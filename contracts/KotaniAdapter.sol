// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IKotani.sol";
import "./SHP_Reserve.sol";

contract KotaniAdapter is Ownable, ReentrancyGuard {
    SHP_Reserve public immutable shpR;
    IKotani public kotani;
    
    event DepositProcessed(address indexed user, uint256 amount);
    event WithdrawalInitiated(address indexed user, uint256 amount);

    constructor(address _reserve, address _kotaniAddress) Ownable(msg.sender) {
        require(_reserve != address(0), "Invalid reserve address");
        require(_kotaniAddress != address(0), "Invalid Kotani address");
        shpR = SHP_Reserve(_reserve);
        kotani = IKotani(_kotaniAddress);
    }

    function processDeposit(address user, uint256 kshAmount) external onlyOwner nonReentrant {
        require(user != address(0), "Invalid user address");
        require(kshAmount > 0, "Amount must be greater than 0");
        shpR.mint(user, kshAmount);
        emit DepositProcessed(user, kshAmount);
    }

    function initiateWithdrawal(
        address user,
        uint256 shpAmount,
        string memory phone
    ) external onlyOwner nonReentrant {
        require(user != address(0), "Invalid user address");
        require(shpAmount > 0, "Amount must be greater than 0");
        require(bytes(phone).length > 0, "Invalid phone number");
        
        shpR.burn(user, shpAmount);
        kotani.initiateWithdrawal(phone, shpAmount);
        emit WithdrawalInitiated(user, shpAmount);
    }

    function updateKotaniAddress(address newAddress) external onlyOwner {
        require(newAddress != address(0), "Invalid Kotani address");
        kotani = IKotani(newAddress);
    }
}
