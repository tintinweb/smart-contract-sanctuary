// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract ExampleExternalContract {
    bool public completed;
    uint256 public balance;

    function complete(uint256 value) public {
        completed = true;
        balance = value;
    }
}