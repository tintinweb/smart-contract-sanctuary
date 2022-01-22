/**
 *Submitted for verification at BscScan.com on 2022-01-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
pragma experimental ABIEncoderV2;

interface UClonePair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

contract Data {
    
    struct PairNode {
        address token;
        address token0;
        address token1;
        uint swapFee;
    }

    receive() external payable {
        assert(msg.sender == 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c); // only accept ETH via fallback from the WETH contract
    }

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'EXPIRED');
        _;
    }

    function swapExactTokensForTokens(
        address tokenIn,
        uint amountIn,
        uint amountOutMin,
        PairNode[] calldata path,
        address to,
        uint deadline
    ) external virtual ensure(deadline) returns (uint[] memory amounts) {
        amounts = getAmountsOut(tokenIn, amountIn, path);
        require(amounts[path.length] >= amountOutMin);
    }

    function getAmountsOut(address tokenIn, uint amountIn, PairNode[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 1, 'getAmountsOut: INVALID_PATH');
        amounts = new uint[](path.length + 1);
        amounts[0] = amountIn;
        address token = tokenIn;
        for (uint i; i < path.length ; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(token, path[i]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut, path[i].swapFee);
            token = path[i].token0 == token ? path[i].token1 : path[i].token0;
        }
    }

    function getReserves(address tokenA, PairNode memory pair) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(pair.token0, pair.token1);
        (uint reserve0, uint reserve1,) = UClonePair(pair.token).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint swapFee) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'getAmountOut: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'getAmountOut: INSUFFICIENT_LIQUIDITY');
        require(swapFee >= 0 && swapFee < 10000, 'getAmountIn: INVALID_SWAP_FEE');
        uint amountInWithFee = amountIn * (uint(10000) - swapFee);
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 10000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'sortTokens: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'sortTokens: ZERO_ADDRESS');
    }
}