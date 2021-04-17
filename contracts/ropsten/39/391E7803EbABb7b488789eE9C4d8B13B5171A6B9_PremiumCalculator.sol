/**
 *Submitted for verification at Etherscan.io on 2021-04-17
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

// File: contracts/PremiumCalculator.sol

contract PremiumCalculator {

    // The base of utilization.
    uint256 constant UTILIZATION_BASE = 1e6;

    function getPremiumRate(uint8 category_, uint256 assetUtilization_) public pure returns(uint256) {
        uint256 extra;
        uint256 cap = UTILIZATION_BASE * 8 / 10;  // 80%

        if (assetUtilization_ >= cap) {
            extra = 1000;
        } else {
            extra = 1000 * assetUtilization_ / cap;
        }

        if (category_ == 0) {
            return 500 + extra;
        } else if (category_ == 1) {
            return 1135 + extra;
        } else {
            return 2173 + extra;
        }
    }
}