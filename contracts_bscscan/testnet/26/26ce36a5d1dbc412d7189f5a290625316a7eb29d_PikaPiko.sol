/**
 *Submitted for verification at BscScan.com on 2022-01-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;


contract PikaPiko {
     uint256 public myTotal = 0;
    function addTotal(uint8 _myArg) public {
        myTotal = myTotal + _myArg;
    }
}