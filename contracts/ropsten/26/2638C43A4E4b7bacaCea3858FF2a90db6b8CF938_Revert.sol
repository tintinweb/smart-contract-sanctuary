/**
 *Submitted for verification at Etherscan.io on 2021-09-21
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Revert {
    int _value;
    
    function isValid(int value) public {
        assert(value < 0);
        require(value > 0 && value < 10000, "Value is integer from 1 to 9999.");
        if (value > 100) {
            revert("Value not supported yet.");
        }
        _value = value;
    }
}