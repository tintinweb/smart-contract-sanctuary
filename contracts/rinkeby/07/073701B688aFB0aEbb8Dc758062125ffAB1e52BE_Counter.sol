/**
 *Submitted for verification at Etherscan.io on 2021-12-04
*/

pragma solidity ^0.8.0;

contract Counter {
    int256 public counter = 0;

    constructor() {}

    function increment() public returns (int256) {
        return counter++;
    }

    function decrement() public returns (int256) {
        return counter--;
    }

    function reset() public returns (int256) {
        counter = 0;
        return counter;
    }
}