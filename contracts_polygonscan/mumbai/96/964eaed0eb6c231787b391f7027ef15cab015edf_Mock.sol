/**
 *Submitted for verification at polygonscan.com on 2021-08-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Mock {
    uint private constant _number = 123456; 
    
    function getConstant() public pure returns(uint) {
        return _number;
    }
}