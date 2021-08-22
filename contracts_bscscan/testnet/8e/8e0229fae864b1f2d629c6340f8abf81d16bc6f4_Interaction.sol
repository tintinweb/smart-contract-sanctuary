/**
 *Submitted for verification at BscScan.com on 2021-08-22
*/

pragma solidity ^0.6.0;

// SPDX-License-Identifier: MIT

interface ICounter {
    function coolNumber() external view returns (uint);
    function setCoolNumber(uint a) external ;
}

contract Interaction {
    address counterAddr;

    function setCounterAddr(address _counter) public payable {
       counterAddr = _counter;
    }

    function getCount() external view returns (uint) {
        return ICounter(counterAddr).coolNumber();
    }
    function setCool(uint a) external {
        return ICounter(counterAddr).setCoolNumber(a);
    }
}