/**
 *Submitted for verification at BscScan.com on 2021-10-16
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

    function balanceOf(
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

    function expxOp(
        address pool,
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 amountOutMin
    ) private returns (uint256) {
        (uint256 amountOut,) = IExpxPool(pool).swapExactAmountIn(
            tokenIn, amountIn, tokenOut, amountOutMin, type(uint256).max);

        return amountOut;
    }

    function expxSwap(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory pools,
        address[] memory route
    ) private returns (uint256) {
        uint256 tempAmount = amountIn;

        for (uint256 i = 0; i < pools.length; i++) {
            approve(route[i], pools[i], tempAmount);

            if (i == pools.length - 1) {
                tempAmount = expxOp(pools[i], route[i],
                    tempAmount, route[i+1], amountOutMin);
            } else {
                tempAmount = expxOp(pools[i], route[i],
                    tempAmount, route[i+1], 0);
            }
        }

        transferBack(route[0]);
        return tempAmount;
    }

    function expxFull(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory pools,
        address[] memory route
    ) private returns (uint256) {
        uint256 amountOut = expxSwap(amountIn,
            amountOutMin, pools, route);

        transferBack(route[pools.length]);
        return amountOut;
    }

    function expxRoute(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory pools,
        address[] memory route
    ) external returns (uint256) {
        transferFrom(route[0], amountIn);
        return expxFull(amountIn, amountOutMin, pools, route);
    }

    function uniswapSwap(
        uint256 amountIn,
        uint256 amountOutMin,
        address uniswapRouter,
        address[] memory route,
        address recipient
    ) private returns (uint256) {
        approve(route[0], uniswapRouter, amountIn);

        IUniswapRouter router = IUniswapRouter(uniswapRouter);
        uint256[] memory amounts = router.swapExactTokensForTokens(
            amountIn, amountOutMin, route, recipient, block.timestamp);

        return amounts[amounts.length - 1];
    }

    function uniswapRoute(
        uint256 amountIn,
        uint256 amountOutMin,
        address uniswapRouter,
        address[] memory route
    ) external returns (uint256) {
        transferFrom(route[0], amountIn);
        return uniswapSwap(amountIn, amountOutMin,
            uniswapRouter, route, msg.sender);
    }

    function expxUniswapPair(
        uint256 amountIn,
        uint256 amountOutMin,
        address expxPool,
        address uniswapRouter,
        address tempToken
    ) external returns (uint256) {
        transferFrom(WBNB, amountIn);

        address[] memory pools = poolsFromPool(expxPool);
        address[] memory route1 = routeFromPair(WBNB, tempToken);
        uint256 tempAmount = expxSwap(amountIn, 0, pools, route1);

        address[] memory route2 = routeFromPair(WBNB, tempToken);
        return uniswapSwap(tempAmount, amountOutMin,
            uniswapRouter, route2, msg.sender);
    }

    function uniswapExpxPair(
        uint256 amountIn,
        uint256 amountOutMin,
        address uniswapRouter,
        address expxPool,
        address tempToken
    ) external returns (uint256) {
        transferFrom(WBNB, amountIn);

        address[] memory route1 = routeFromPair(WBNB, tempToken);
        uint256 tempAmount = uniswapSwap(amountIn, 0,
            uniswapRouter, route1, address(this));

        address[] memory pools = poolsFromPool(expxPool);
        address[] memory route2 = routeFromPair(tempToken, WBNB);
        return expxFull(tempAmount, amountOutMin, pools, route2);
    }

    function uniswapUniswapPair(
        uint256 amountIn,
        uint256 amountOutMin,
        address uniswapRouter1,
        address uniswapRouter2,
        address tempToken
    ) external returns (uint256) {
        transferFrom(WBNB, amountIn);

        address[] memory route1 = routeFromPair(WBNB, tempToken);
        uint256 tempAmount = uniswapSwap(amountIn, 0,
            uniswapRouter1, route1, address(this));

        address[] memory route2 = routeFromPair(tempToken, WBNB);
        return uniswapSwap(tempAmount, amountOutMin,
            uniswapRouter2, route2, msg.sender);
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
        uint256 amount = tokenContract.balanceOf(address(this));
        tokenContract.transfer(msg.sender, amount);
    }
}