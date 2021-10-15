/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IRouter {
  function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);
}

interface IERC20 {
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Swapper {
    address private constant router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    function swap(uint256 amountOutMin, address[] memory path, uint256 amountIn) external {
        IERC20(path[0]).approve(address(router), amountIn);
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        IRouter(router).swapExactTokensForTokens(amountIn, amountOutMin, path, msg.sender, block.timestamp+150);
    }
}