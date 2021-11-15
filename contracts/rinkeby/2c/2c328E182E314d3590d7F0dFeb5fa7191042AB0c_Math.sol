// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

library Math {
    function abs(int256 a) internal pure returns (uint256) {
        return a >= 0 ? uint256(a) : uint256(-a);
    }
}

