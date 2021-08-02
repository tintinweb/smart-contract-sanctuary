/**
 *Submitted for verification at Etherscan.io on 2021-08-01
*/

pragma solidity ^0.6.0;

// SPDX-License-Identifier: MIT



contract Interaction {
    address counterAddr;

    function setCounterAddr(address _counter) public payable {
       counterAddr = _counter;
    }

    function getCount() external view returns (uint) {
        return ICounter(counterAddr).count();
    }
    function increment() external {
        ICounter(counterAddr).increment();
    }
}

interface ICounter {
    function count() external view returns (uint);
    function increment() external;
}