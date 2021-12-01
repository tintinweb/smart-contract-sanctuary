/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Testest  {
    constructor(){
        
    }

    uint256 value;

    function get_value() public view returns(uint256){
        return value;
    }

    function add_value(uint256 _value) public returns(uint256){
        value+=_value;
        return value;
    }

    function sub_value(uint256 _value) public returns(uint256){
        value-=_value;
        return value;
    }
}