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
        0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    function expxSwap(
        address pool,
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 amountOutMin
    ) private returns (uint256) {
        (uint256 amountOut,) = IExpxPool(pool).swapExactAmountIn(
            tokenIn, amountIn, tokenOut, amountOutMin, type(uint).max);

        return amountOut;
    }

    function expxRoute(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory pools,
        address[] memory route
    ) public returns (uint256) {
        uint256 amountOut = amountIn;
        transferFrom(WBNB, amountIn);

        for (uint256 i = 0; i < pools.length; i++) {
            approve(route[i], pools[i], amountIn);

            if (i == pools.length - 1) {
                amountOut = expxSwap(pools[i], route[i],
                    amountOut, route[i+1], amountOutMin);
            } else {
                amountOut = expxSwap(pools[i], route[i],
                    amountOut, route[i+1], 0);
            }
        }

        transferBack(WBNB);
        return amountOut;
    }

    function uniswapRoute(
        uint256 amountIn,
        uint256 amountOutMin,
        address uniswapRouter,
        address[] memory route
    ) public returns (uint256) {
        transferFrom(WBNB, amountIn);
        approve(WBNB, uniswapRouter, amountIn);

        IUniswapRouter router = IUniswapRouter(uniswapRouter);
        uint256[] memory amounts = router.swapExactTokensForTokens(
            amountIn, amountOutMin, route, msg.sender, block.timestamp);

        return amounts[amounts.length - 1];
    }

    function expxUniswapPair(
        uint256 amountIn,
        uint256 amountOutMin,
        address expxPool,
        address uniswapRouter,
        address tempToken
    ) public returns (uint256) {
        address[] memory pools = poolsFromPool(expxPool);
        address[] memory route1 = routeFromPair(WBNB, tempToken);
        address[] memory route2 = routeFromPair(tempToken, WBNB);

        uint256 amountOut = expxRoute(amountIn, 0, pools, route1);
        return uniswapRoute(amountOut, amountOutMin, uniswapRouter, route2);
    }

    function uniswapExpxPair(
        uint256 amountIn,
        uint256 amountOutMin,
        address uniswapRouter,
        address expxPool,
        address tempToken
    ) public returns (uint256) {
        address[] memory pools = poolsFromPool(expxPool);
        address[] memory route1 = routeFromPair(WBNB, tempToken);
        address[] memory route2 = routeFromPair(tempToken, WBNB);

        uint256 amountOut = uniswapRoute(amountIn, 0, uniswapRouter, route1);
        return expxRoute(amountOut, amountOutMin, pools, route2);
    }

    function uniswapUniswapPair(
        uint256 amountIn,
        uint256 amountOutMin,
        address uniswapRouter1,
        address uniswapRouter2,
        address tempToken
    ) public returns (uint256) {
        address[] memory route1 = routeFromPair(WBNB, tempToken);
        address[] memory route2 = routeFromPair(tempToken, WBNB);

        uint256 amountOut = uniswapRoute(amountIn, 0, uniswapRouter1, route1);
        return uniswapRoute(amountOut, amountOutMin, uniswapRouter2, route2);
    }

    function routeFromPair(address token1, address token2)
    private pure returns(address[] memory) {
        address[] memory route = new address[](2);
        route[0] = token1;
        route[1] = token2;

        return route;
    }

    function poolsFromPool(address pool)
    private pure returns(address[] memory) {
        address[] memory pools = new address[](1);
        pools[0] = pool;

        return pools;
    }

    function approve(address token, address spender, uint256 amount) private {
        IBEP20 tokenContract = IBEP20(token);
        tokenContract.approve(spender, amount);
    }

    function transferFrom(address token, uint256 amount) private {
        IBEP20 tokenContract = IBEP20(token);
        tokenContract.transferFrom(msg.sender, address(this), amount);
    }

    function transferBack(address token) private {
        IBEP20 tokenContract = IBEP20(token);
        uint256 amount = tokenContract.getBalance(address(this));
        tokenContract.transfer(msg.sender, amount);
    }
}