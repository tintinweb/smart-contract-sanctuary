/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.5;

contract simple_set
{
    uint private value;
    
    constructor(uint value_)
    {
        value = value_;
    }
    
    function get_value() public view returns(uint)
    {
        return value;
    }
}