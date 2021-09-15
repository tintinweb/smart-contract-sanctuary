/**
 *Submitted for verification at polygonscan.com on 2021-09-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Router02 {
    function getAmountsOut(
        uint amountIn, 
        address[] memory path) 
        external view returns (uint[] memory amounts);
}

contract TokenPrice {
    IUniswapV2Router02 dfynRouter;
    IUniswapV2Router02 sushiRouter;
    IUniswapV2Router02 quickRouter;
    address public WETH;

    constructor() 
    {
        WETH = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
        dfynRouter = IUniswapV2Router02(0xA102072A4C07F06EC3B4900FDC4C7B80b6c57429);
        sushiRouter = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
        quickRouter = IUniswapV2Router02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
    }
    
    function getPrice(uint amountIn, address[] memory path) external view returns (uint targetPrice, uint8 routeNumber)
    {
        if (path[0] == WETH)
        {
            targetPrice = dfynRouter.getAmountsOut(amountIn, path)[1];
            routeNumber = 1;
        }
        else
        {
            targetPrice = sushiRouter.getAmountsOut(amountIn, path)[1];
            routeNumber = 2;
        }
    }
}