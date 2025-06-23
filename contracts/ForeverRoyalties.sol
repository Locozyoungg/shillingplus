// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IUniswapV2Router.sol";

contract ForeverRoyalties is Ownable, ReentrancyGuard {
    address public immutable creator;
    uint256 public constant CREATOR_SHARE = 15; // 15% forever
    IUniswapV2Router public uniswapRouter;
    IERC20 public shpT;
    IERC20 public shpR;
    address public weth;

    event RoyaltiesWithdrawn(address indexed creator, uint256 ethAmount);
    event TokensSwapped(address indexed token, uint256 tokenAmount, uint256 ethAmount);

    constructor(address _shpT, address _shpR, address _uniswapRouter, address _weth) Ownable(msg.sender) {
        require(_shpT != address(0), "Invalid SHP-T address");
        require(_shpR != address(0), "Invalid SHP-R address");
        require(_uniswapRouter != address(0), "Invalid router address");
        require(_weth != address(0), "Invalid WETH address");
        creator = msg.sender;
        shpT = IERC20(_shpT);
        shpR = IERC20(_shpR);
        uniswapRouter = IUniswapV2Router(_uniswapRouter);
        weth = _weth;
    }

    function withdraw() external nonReentrant {
        require(msg.sender == creator || msg.sender == owner(), "Not authorized");
        
        // Swap SHP-T to ETH
        uint256 shpTBalance = shpT.balanceOf(address(this));
        if (shpTBalance > 0) {
            _swapTokensForETH(address(shpT), shpTBalance);
        }

        // Swap SHP-R to ETH
        uint256 shpRBalance = shpR.balanceOf(address(this));
        if (shpRBalance > 0) {
            _swapTokensForETH(address(shpR), shpRBalance);
        }

        // Withdraw ETH
        uint256 ethBalance = address(this).balance;
        require(ethBalance > 0, "No ETH to withdraw");
        uint256 share = (ethBalance * CREATOR_SHARE) / 100;
        (bool sent,) = creator.call{value: share}("");
        require(sent, "ETH transfer failed");
        emit RoyaltiesWithdrawn(creator, share);
    }

    function _swapTokensForETH(address token, uint256 amount) internal {
        IERC20(token).approve(address(uniswapRouter), amount);
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = weth;

        uint256[] memory amounts = uniswapRouter.swapExactTokensForETH(
            amount,
            0, // Accept any output amount (for simplicity; add slippage protection in production)
            path,
            address(this),
            block.timestamp + 300
        );
        emit TokensSwapped(token, amount, amounts[1]);
    }

    function updateRouter(address newRouter) external onlyOwner {
        require(newRouter != address(0), "Invalid router address");
        uniswapRouter = IUniswapV2Router(newRouter);
    }

    receive() external payable {}
}
