// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

contract Gas {
    uint256[] private array;

    function add(uint256 n) public {
        for (uint256 i = 0; i < n; ++i) {
            array.push(type(uint256).max);
        }
    }
}