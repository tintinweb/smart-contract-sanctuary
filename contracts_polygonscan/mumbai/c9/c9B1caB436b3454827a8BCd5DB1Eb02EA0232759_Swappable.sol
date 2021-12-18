/**
 *Submitted for verification at polygonscan.com on 2021-12-17
*/

// Sources flattened with hardhat v2.6.5 https://hardhat.org

// File contracts/interface/IUniswapV2Router.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
}


// File contracts/library/Swappable.sol


pragma solidity ^0.8.2;
library Swappable {

    function swapExactTokensForTokens(
        address swapRouter,
        uint amountIn,
        uint amountOutMin,
        address tokenIn,
        address tokenOut,
        address to,
        uint deadline
    ) external returns (uint amountOut) {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        uint[] memory amounts = IUniswapV2Router(swapRouter).swapExactTokensForTokens(amountIn, amountOutMin, path, to, deadline);
        amountOut = amounts[amounts.length - 1];
    }

    function swapExactTokensForETH(
        address swapRouter,
        address weth,
        uint amountIn, 
        uint amountOutMin, 
        address tokenIn, 
        address to, 
        uint deadline
    ) external returns (uint amountOut) {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = weth;

        uint[] memory amounts = IUniswapV2Router(swapRouter).swapExactTokensForETH(amountIn, amountOutMin, path, to, deadline);
        amountOut = amounts[amounts.length - 1];
    }
}