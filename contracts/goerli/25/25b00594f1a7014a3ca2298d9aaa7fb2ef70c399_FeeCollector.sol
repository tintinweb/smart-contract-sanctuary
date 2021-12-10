/**
 *Submitted for verification at Etherscan.io on 2021-12-09
*/

pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

contract FeeCollector 
{
    address public owner;  //
    uint256 public balance; //

    constructor()
    {
        owner = msg.sender;
    }

    receive() payable external
    {
        balance += msg.value;
    }
}