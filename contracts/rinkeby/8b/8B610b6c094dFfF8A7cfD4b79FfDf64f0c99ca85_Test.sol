//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Test {
    uint256 number = 0;

    function updateNumber(uint256 _number) external {
        number = _number;
    }
}

