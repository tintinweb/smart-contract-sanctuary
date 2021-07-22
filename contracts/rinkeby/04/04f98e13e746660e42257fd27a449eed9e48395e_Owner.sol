/**
 *Submitted for verification at Etherscan.io on 2021-07-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

contract Owner {
    mapping(address => uint256) public stat;
    
    function add (uint256 amount) public{
        stat[msg.sender]+=amount;
    }
    
    function del (uint256 amount) public{
        stat[msg.sender]-=amount;
    }

}