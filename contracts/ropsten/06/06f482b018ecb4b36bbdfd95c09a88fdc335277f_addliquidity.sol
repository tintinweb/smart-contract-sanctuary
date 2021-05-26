/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;


//import the ERC20 interface

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidityETH(address token,uint amountTokenDesired,uint amountTokenMin,uint amountETHMin,address to,uint deadline) 
    external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract addliquidity {
    
    //address of the uniswap v2 router
    address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    
    function addLiquidity(address token,uint amountTokenDesired,uint amountTokenMin,uint amountETHMin,address to,uint deadline) external payable returns (bool) {
    //IERC20(token).transferFrom(msg.sender, address(this), amountTokenDesired);
    //IERC20(token).approve(UNISWAP_V2_ROUTER, amountTokenDesired);
    IUniswapV2Router01(UNISWAP_V2_ROUTER).addLiquidityETH{value: msg.value}(token,amountTokenDesired,amountTokenMin,amountETHMin,to,deadline);
    return true;
        //return(amountToken,amountETH,liquidity);
    }
        
    
}