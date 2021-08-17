/**
 *Submitted for verification at Etherscan.io on 2021-08-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

contract CounterV1{
    uint counter;

    function getCounterValue() external view returns(uint){
        return counter;
    }

    function setCounterValue(uint _value) external{
        counter = _value;
    }
}