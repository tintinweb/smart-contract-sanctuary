/**
 *Submitted for verification at BscScan.com on 2022-01-20
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

contract MyUpgradedTestContract {
    uint public _value;

    function heheheha ( ) external 
    {
        _value += 1;
    }

    function initialize ( uint value ) external
    {
        _value = value;
    }
}