/**
 *Submitted for verification at BscScan.com on 2021-12-12
*/

/*
    SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.6;

contract Test {
    uint public _number = 0;

    function getNumber() public view returns(uint)
    {
        return _number;
    }

    function setNumber(uint number) external 
    {
        _number = number; 
    }
}