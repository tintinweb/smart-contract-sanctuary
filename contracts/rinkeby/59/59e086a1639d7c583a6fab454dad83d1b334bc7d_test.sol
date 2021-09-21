/**
 *Submitted for verification at Etherscan.io on 2021-09-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract test{
    mapping(address => uint) contribute;
    receive() external payable{
        contribute[msg.sender] += msg.value;
    }
}