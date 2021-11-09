/**
 *Submitted for verification at polygonscan.com on 2021-11-08
*/

/**
 *Submitted for verification at polygonscan.com on 2021-11-05
*/

/**
 *Submitted for verification at polygonscan.com on 2021-08-25
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract UniswapV2PairEth {
    uint112 reserve0;
    uint112 reserve1;
    uint32 blockTimestampLast;

    constructor() public {
        reserve0 = 4930907061771343738833829;
        reserve1 = 9504807623844;
        blockTimestampLast = 1636355307;
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