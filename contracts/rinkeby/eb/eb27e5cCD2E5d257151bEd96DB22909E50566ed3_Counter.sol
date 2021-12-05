/**
 *Submitted for verification at Etherscan.io on 2021-12-05
*/

pragma solidity ^0.8.0;

contract Counter {
    int256 public counter = 0;
    event CounterChanged(int256 counter);

    constructor() {}

    function increment() public {
        emit CounterChanged(counter++);
    }

    function decrement() public {
        emit CounterChanged(counter--);
    }

    function reset() public {
        counter = 0;
        emit CounterChanged(counter);
    }
}