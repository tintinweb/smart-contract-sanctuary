/**
 *Submitted for verification at Etherscan.io on 2021-04-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Custom{
    uint public val;
    
    constructor(){
        val = 0;
    }
    
    function changeValue(uint new_val) public returns (uint){
        if(valid(new_val)) val = new_val;
        return val;
    }
    
    function valid(uint new_val) public returns(bool){
        if(new_val>0) return true;
    }
}