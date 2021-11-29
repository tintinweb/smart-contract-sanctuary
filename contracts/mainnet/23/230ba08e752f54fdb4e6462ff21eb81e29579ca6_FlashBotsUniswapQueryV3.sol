/**
 *Submitted for verification at Etherscan.io on 2021-11-29
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

pragma experimental ABIEncoderV2;

abstract contract IUniswapV3Pair {
    struct Slot0 {
        // the current price
        uint160 sqrtPriceX96;
        // the current tick
        int24 tick;

    }
    Slot0 public slot0;
    uint128 public liquidity;
}

// In order to quickly load up data from Uniswap-like market, this contract allows easy iteration with a single eth_call
contract FlashBotsUniswapQueryV3 {
    struct Slot0_fb {
        uint160 sqrtPriceX96;
        int24 tick;
        uint128 liquidity;
    }

    function getReservesByPairs(IUniswapV3Pair[] calldata _pairs) external view returns (Slot0_fb[] memory) {
        Slot0_fb[] memory result = new Slot0_fb[](_pairs.length);
        for (uint i = 0; i < _pairs.length; i++) {
            (uint160 sqrtPriceX96,
            int24 tick) = _pairs[i].slot0();
            result[i].sqrtPriceX96 = sqrtPriceX96;
            result[i].tick = tick;
            result[i].liquidity = _pairs[i].liquidity();
        }
        return result;
    }
}