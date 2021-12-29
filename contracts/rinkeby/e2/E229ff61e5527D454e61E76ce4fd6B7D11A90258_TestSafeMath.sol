/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Arctan {

    function log_2(uint256 x) internal pure returns (uint8) {
        uint8 res = 0;

        if (x < 256) {
            while (x > 1) {
                x >>= 1;
                res += 1;
            }
        } else {
            for (uint8 s = 128; s > 0; s >>= 1) {
                if (x >= (1 << s)) {
                    x >>= s;
                    res |= s;
                }
            }
        }

        return res;
    }
}

contract TestSafeMath {

    function testSquareRoot(uint x) public pure returns (uint) {
        return Arctan.log_2(x);
    }
}