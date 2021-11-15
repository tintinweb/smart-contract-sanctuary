//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Test {
    uint256 public number = 0;

    function updateNumber(uint256 _number) external {
        number = _number;
    }

    function updateNumber2(uint256 _number) external {
        number = _number;
    }
}

