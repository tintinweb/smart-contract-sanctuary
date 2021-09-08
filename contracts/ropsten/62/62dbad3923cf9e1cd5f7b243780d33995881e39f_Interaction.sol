/**
 *Submitted for verification at Etherscan.io on 2021-09-08
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

interface ICounter {
    function count() external view returns(uint);
    function increment() external;
    function balance() external view returns(uint);
}

contract Interaction {
    address testAddr;
    
    function setCounterAddr(address _counter) public payable {
        testAddr = _counter;
    }
    
    function getCount() external view returns(uint) {
        return ICounter(testAddr).count();
    }
    
    function getBalance() external view returns(uint) {
        return ICounter(testAddr).balance();
    }
}