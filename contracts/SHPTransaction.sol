// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SHPTransaction is ERC20, Ownable {
    address public rebaser;
    address public mpesaBridge;
    address public bankBridge;
    address public reserveToken; // SHP-R for conversion
    uint256 private _totalBurned;
    
    event TokensBurned(address indexed burner, uint256 value);

    constructor(address _reserveToken) ERC20("ShillingPlus Transaction", "SHP-T") Ownable(msg.sender) {
        require(_reserveToken != address(0), "Invalid reserve token");
        reserveToken = _reserveToken;
        _mint(msg.sender, 900_000_000 * 10**18); // Initial elastic supply
    }

    modifier onlyRebaser() {
        require(msg.sender == rebaser, "Caller is not the rebaser");
        _;
    }

    modifier onlyBridge() {
        require(msg.sender == mpesaBridge || msg.sender == bankBridge, "Caller is not a bridge");
        _;
    }

    function setRebaser(address _rebaser) external onlyOwner {
        require(_rebaser != address(0), "Invalid address");
        rebaser = _rebaser;
    }

    function setMpesaBridge(address _bridge) external onlyOwner {
        require(_bridge != address(0), "Invalid address");
        mpesaBridge = _bridge;
    }

    function setBankBridge(address _bridge) external onlyOwner {
        require(_bridge != address(0), "Invalid address");
        bankBridge = _bridge;
    }

    function rebaseMint(address account, uint256 amount) external onlyRebaser {
        require(account != address(0), "Invalid account");
        require(amount > 0, "Amount must be positive");
        _mint(account, amount);
    }

    function rebaseBurn(address account, uint256 amount) external onlyRebaser {
        require(account != address(0), "Invalid account");
        require(amount > 0, "Amount must be positive");
        _burn(account, amount);
        _totalBurned += amount;
        emit TokensBurned(account, amount);
    }

    function bridgeBurn(address account, uint256 amount) external onlyBridge {
        require(account != address(0), "Invalid account");
        require(amount > 0, "Amount must be positive");
        _burn(account, amount);
        _totalBurned += amount;
        emit TokensBurned(account, amount);
    }

    function totalBurned() external view returns (uint256) {
        return _totalBurned;
    }

    // Convert SHP-T to SHP-R at par
    function convertToReserve(uint256 amount) external {
        require(amount > 0, "Amount must be positive");
        _burn(msg.sender, amount);
        SHPReserve(reserveToken).mint(msg.sender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        uint256 burnAmount = amount / 1000; // 0.1% burn
        uint256 netAmount = amount - burnAmount;
        if (burnAmount > 0) {
            _burn(sender, burnAmount);
            _totalBurned += burnAmount;
            emit TokensBurned(sender, burnAmount);
        }
        super._transfer(sender, recipient, netAmount);
    }
}

interface SHPReserve {
    function mint(address account, uint256 amount) external;
}
