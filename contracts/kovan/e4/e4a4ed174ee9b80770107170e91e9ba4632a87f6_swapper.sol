/**
 *Submitted for verification at Etherscan.io on 2021-10-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IERC20 {
   function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
   function approve(address spender,uint256 amount) external returns (bool);
}

interface IUniswap {
  function swapExactTokensForTokens(uint256 amountIn,uint256 amountOutMin,address[] calldata path,address to,uint256 deadline) external returns (uint256[] memory amounts);
}

contract swapper {
    IUniswap uniswap;

    address private constant router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    constructor() {
        uniswap = IUniswap(router);
    }

    function swap(uint256 amountIn, uint256 amountOutMin) external {
        address[] memory path = new address[](2);
        path[0] = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa;
        path[1] = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;

        require(IERC20(path[0]).approve(router,amountIn), 'approve faild1');
        require(IERC20(path[0]).transferFrom(msg.sender,address(this),amountIn), 'transferFrom faild1');

        uniswap.swapExactTokensForTokens(amountIn, amountOutMin, path, msg.sender, block.timestamp+300);
    }
}