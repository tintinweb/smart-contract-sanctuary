/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IRouter {
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
}

interface IERC20 {
    function transferFrom(address from, address to, uint value) external;
    function approve(address to, uint value) external returns (bool);

}

contract Swapper {
    address private router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    function swap(uint256 amountOutMin, address[] calldata path, uint256 amountIn, uint256 deadline) external {
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        IERC20(path[0]).approve(router, amountIn);
        IRouter(router).swapExactTokensForTokens(amountIn, amountOutMin, path, msg.sender, deadline);
    }
}