//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

library Math {
    function isEven(uint256 n) public pure returns (bool) {
        return n % 2 == 0;
    }
}