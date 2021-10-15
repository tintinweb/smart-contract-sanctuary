/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IUniswapV2Router {
  function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);
}

contract Swapper {
    address private constant router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    function swap(uint256 _amountOutMin, uint256 _amountIn, address[] memory _path) external {
        IERC20(_path[0]).approve(address(router), _amountIn);
        IERC20(_path[0]).transferFrom(msg.sender, address(this), _amountIn);
        
        IUniswapV2Router(router).swapExactTokensForTokens(_amountIn, _amountOutMin, _path, msg.sender, block.timestamp);
    }
}