/**
 *Submitted for verification at polygonscan.com on 2021-08-25
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract UniswapV2Pair {
    uint112 reserve0;
    uint112 reserve1;
    uint32 blockTimestampLast;

    constructor() public {
        reserve0 = 13492362462;
        reserve1 = 22437064870723375187620;
        blockTimestampLast = 1628865512;
    }

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function updateReserves(uint112 _reserve0, uint112 _reserve1) public {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
    }
}