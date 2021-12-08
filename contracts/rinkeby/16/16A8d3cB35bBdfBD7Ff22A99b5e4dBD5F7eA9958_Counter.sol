/**
 *Submitted for verification at Etherscan.io on 2021-12-07
*/

pragma solidity ^0.8.0;

contract Counter {
    int256 public counter = 0;
    event CounterChanged(string eventType, int256 counter, address userAddress);

    constructor() {}

    function increment() public {
        emit CounterChanged("increment", counter++, msg.sender);
    }

    function decrement() public {
        emit CounterChanged("decrement", counter--, msg.sender);
    }

    function reset() public {
        counter = 0;
        emit CounterChanged("reset", counter, msg.sender);
    }
}