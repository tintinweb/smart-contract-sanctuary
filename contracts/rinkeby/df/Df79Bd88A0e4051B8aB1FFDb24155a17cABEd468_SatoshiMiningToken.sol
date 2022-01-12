// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract SatoshiMiningToken {
    uint256 public number = 1000;

    function getNumber() public view returns(uint256) {
        return number;
    }
}