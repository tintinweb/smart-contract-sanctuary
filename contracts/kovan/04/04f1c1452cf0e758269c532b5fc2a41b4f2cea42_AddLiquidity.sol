/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

pragma solidity ^0.6.6;

interface IUniswap {
    
    function addLiquidityETH(address token,uint amountTokenDesired,uint amountTokenMin,uint amountETHMin,address to,uint deadline) external payable 
    returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
}

contract AddLiquidity {

    address internal constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // Ropsten

    IUniswap public uniswap;

    constructor() public {
        uniswap = IUniswap(UNISWAP_ROUTER_ADDRESS);
    }
    
    function addLiquidity(address token,uint amountTokenDesired,uint amountTokenMin,uint amountETHMin,address to,uint deadline) external payable {
        IERC20(token).approve(UNISWAP_ROUTER_ADDRESS, amountTokenDesired);
        uniswap.addLiquidityETH{ value: msg.value }(token, amountTokenDesired, amountTokenMin, amountETHMin, msg.sender, deadline);
    }
}