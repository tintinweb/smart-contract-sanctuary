/**
 *Submitted for verification at Etherscan.io on 2021-08-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract Bands {

    function getBands(uint32 timeDuration) external view {
        uint32 zxc;
        for (uint32 i=0; i<timeDuration; i++) {
            zxc = i + 2;
        }
        
    }

    // function getTwap(IUniswapV3Pool pool, uint32 twapDuration) internal view returns (int24) {
    //     uint32 _twapDuration = twapDuration;
    //     uint32[] memory secondsAgo = new uint32[](2);
    //     secondsAgo[0] = _twapDuration;
    //     secondsAgo[1] = 0;

    //     (int56[] memory tickCumulatives, ) = pool.observe(secondsAgo);
    //     return int24((tickCumulatives[1] - tickCumulatives[0]) / _twapDuration);
    // }
}