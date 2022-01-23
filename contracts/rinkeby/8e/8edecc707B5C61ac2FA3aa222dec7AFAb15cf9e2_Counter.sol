//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Counter {
    uint256 private counter = 0;

    event UpdatedCounter(uint256 _counter);

    constructor(uint256 _counter) {
        counter = _counter;
    }

    function increment() public {
        counter++;
        emit UpdatedCounter(counter);
    }

    function getCounter() public view returns (uint256) {
        return counter;
    }
}