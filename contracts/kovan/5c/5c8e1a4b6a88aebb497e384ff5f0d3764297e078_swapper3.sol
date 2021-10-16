/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IERC20 {
   function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
   function approve(address spender, uint256 amount) external returns (bool);
}

interface IUniswap {
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
}

contract swapper3 {
    IUniswap uniswap;

    constructor(){
        uniswap = IUniswap(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    }

    function swap(uint amountIn, uint amountOutMin, address[] calldata path) external {
        IERC20(path[0]).approve(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,amountIn);
        IERC20(path[0]).transferFrom(msg.sender,address(this),amountIn);

        uniswap.swapExactTokensForTokens(amountIn,amountOutMin,path,msg.sender,block.timestamp+300);
    }
}