//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

contract Counter {
    uint public counter;

    function increment() public {
        counter++;
    }
}