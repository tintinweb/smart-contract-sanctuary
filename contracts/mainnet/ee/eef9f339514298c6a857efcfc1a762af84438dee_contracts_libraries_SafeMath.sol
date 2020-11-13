// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

// A library for performing overflow-safe math, courtesy of DappHub: https://github.com/dapphub/ds-math/blob/d0ef6d6a5f/src/math.sol
// Modified to include only the essentials
library SafeMath {
    string private constant ERROR_ADD_OVERFLOW = "MATH:ADD_OVERFLOW";
    string private constant ERROR_SUB_UNDERFLOW = "MATH:SUB_UNDERFLOW";

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, ERROR_ADD_OVERFLOW);
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, ERROR_SUB_UNDERFLOW);
    }
}
