/**
 *Submitted for verification at BscScan.com on 2021-09-16
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;


contract SetValue {
    uint256 value = 0;
    function getValue() public view returns(uint256){
        return value;
    }
    
    function setValue(uint256 _value) public returns(uint256 newValue){
        value = _value;
        return value;
    }
    
}