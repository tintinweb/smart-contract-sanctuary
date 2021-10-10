/**
 *Submitted for verification at BscScan.com on 2021-10-09
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

interface IBEP20 {
    function approve(
        address spender,
        uint256 amount
    ) external returns (bool);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function getBalance(
        address whom
    ) external view returns (uint256);
}

interface IExpxPool {
    function swapExactAmountIn(
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 minAmountOut,
        uint256 maxPrice
    ) external returns (uint256, uint256);
    
    function calcOutGivenIn(uint256, uint256, uint256, uint256, uint256, uint256) external pure returns (uint256);
    function getDenormalizedWeight(address) external view returns (uint256);
    function getBalance(address) external view returns (uint256);
    function getSwapFee() external view returns (uint256);
}

interface IUniswapRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address recipient,
        uint256 deadline
    ) external returns (uint256[] memory);
}

contract BscSwapper {

    address private constant WBNB =
        0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;

    function expxRoute(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory pools,
        address[] memory route
    ) public returns (uint256) {
        uint256 tempAmount = amountIn;

        for (uint256 i = 0; i < pools.length; i++) {
            approve(route[i], pools[i], tempAmount);

            if (i == pools.length - 1) {
                tempAmount = tempAmount + 1;
            } else {
                tempAmount = tempAmount + 2;
            }
        }

        transferBack(WBNB);
        return tempAmount;
    }

    function approve(address token, address spender, uint256 amount) public {
        IBEP20 tokenContract = IBEP20(token);
        tokenContract.approve(spender, amount);
    }

    function transferFrom(address token, uint256 amount) public {
        IBEP20 tokenContract = IBEP20(token);
        tokenContract.transferFrom(msg.sender, address(this), amount);
    }

    function transferBack(address token) public {
        IBEP20 tokenContract = IBEP20(token);
        uint256 amount = tokenContract.getBalance(address(this));
        tokenContract.transfer(msg.sender, amount);
    }
}