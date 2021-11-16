/**
 *Submitted for verification at polygonscan.com on 2021-11-16
*/

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.7;


interface IERC20 {
    function balanceOf(address _owner) external view returns(uint256);
    function approve(address _spender, uint256 _value) external returns (bool);
}

interface Swapper {
    function swapExactInputSingle(address _tokenIn, address _tokenOut, uint256 amountIn) external returns (uint256 amountOut);
}

contract client {
    function swap(address swapper, address tokenIn, address tokenOut, uint256 amountIn) external returns(uint256 amountOut){
        require(IERC20(tokenIn).approve(swapper, amountIn));
        return Swapper(swapper).swapExactInputSingle(tokenIn, tokenOut, amountIn);
    }
    
    function charge() external payable{}
    
    function tokenBalance(address tokenIn) external view returns(uint256){
        return IERC20(tokenIn).balanceOf(address(this));
    }
}