// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IKotani {
    function initiateDeposit(
        string calldata phone,
        uint256 amount,
        address recipient
    ) external;
    
    function initiateWithdrawal(
        string calldata phone,
        uint256 amount
    ) external;
    
    function isSanctioned(address user) external view returns (bool);
    
    function dailyWithdrawal(address user) external view returns (uint256);
}
