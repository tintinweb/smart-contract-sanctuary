/**
 *Submitted for verification at Etherscan.io on 2021-06-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

contract KDCalculator{
    
    address public _owner;
    
    constructor(){
        _owner = msg.sender;
    }
    
    function Add(int _a, int _b) external pure returns(int _sum){
        return _a + _b;
    }
}