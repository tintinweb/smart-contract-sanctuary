/**
 *Submitted for verification at Etherscan.io on 2021-10-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IERC20 {
   function transferFrom(address sender, address recipient, uint256 amount) external;
   function approve(address spender,uint256 amount) external;
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
        path[0] = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        path[1] = 0x054D64b73d3D8A21Af3D764eFd76bCaA774f3Bb2;

        IERC20(path[0]).approve(router,amountIn);
        IERC20(path[0]).transferFrom(msg.sender,address(this),amountIn);

        uniswap.swapExactTokensForTokens(amountIn, amountOutMin, path, msg.sender, block.timestamp+300);
    }
}