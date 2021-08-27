/**
 *Submitted for verification at BscScan.com on 2021-08-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IERC20 {
    function approve(address _spender, uint256 _value) external returns (bool success);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IUniswapRouterV2 {
    function addLiquidityETH(
        address token,
        uint256 amountTokenMax,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

contract LiquidityInitiator {
    address public owner;
    
    IERC20 public SWAPP_CONTRACT = IERC20(0xA48cd655cF2dbd04BBa7ac3DFD9A834cb4a30507);
    IUniswapRouterV2 public UNISWAP_ROUTER = IUniswapRouterV2(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
    
     modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perfrom this action");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    function forwardLiquidity() external onlyOwner {
        uint256 balance = address(this).balance;
        uint256 tokenBalance = SWAPP_CONTRACT.balanceOf(address(this));

        SWAPP_CONTRACT.approve(address(UNISWAP_ROUTER), tokenBalance);

        UNISWAP_ROUTER.addLiquidityETH{value: balance}(
            address(SWAPP_CONTRACT),
            tokenBalance,
            0,
            0,
            owner,
            block.timestamp + 1 hours
        );
    }
    
    receive() external payable {}
    
    function getTokens(address to, address tokenAddress) external onlyOwner {
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        if (balance > 0) {
            IERC20(tokenAddress).transfer(to, balance);
        }
    }
    
    function getCurrency(uint256 amount) external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance >= amount, 'Not enough funds');
        address to = owner;
        payable(to).transfer(amount);
    }
}