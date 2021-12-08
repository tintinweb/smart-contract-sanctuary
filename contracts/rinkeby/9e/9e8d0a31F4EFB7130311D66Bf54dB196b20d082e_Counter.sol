/**
 *Submitted for verification at Etherscan.io on 2021-12-08
*/

pragma solidity ^0.8.0;

abstract contract CounterRegistryInterface {
    function registerNewContract(address newContract, address userAddress)
        public
        virtual;
}

contract Counter {
    int256 public counter = 0;
    event CounterChanged(
        string eventType,
        int256 prevCounter,
        int256 newCounter,
        address userAddress
    );

    address counterRegistryAddress = 0x0eDD9d9CE0c51c707edb9CfA29501FD2FAb3dE66;
    CounterRegistryInterface counterRegistry =
        CounterRegistryInterface(counterRegistryAddress);

    constructor() {
        counterRegistry.registerNewContract(address(this), msg.sender);
    }

    function increment() public {
        emit CounterChanged("increment", counter, ++counter, msg.sender);
    }

    function decrement() public {
        emit CounterChanged("decrement", counter, --counter, msg.sender);
    }

    function reset() public {
        int256 prevCounter = counter;
        counter = 0;
        emit CounterChanged("reset", prevCounter, counter, msg.sender);
    }
}