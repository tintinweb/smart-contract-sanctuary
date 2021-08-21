/**
 *Submitted for verification at Etherscan.io on 2021-08-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleBank
{
    mapping (address => uint) _accounts;
    
    function deposit() payable external
    {
        _accounts[msg.sender] += msg.value;
    }
    
    function withdrawAll() payable external
    {
        payable(msg.sender).transfer(_accounts[msg.sender]);
        _accounts[msg.sender] = 0;
    }
    
    function getContractBalance() view external returns (uint)
    {
        return address(this).balance;
    }
    
    function getAccountBalance() view external returns (uint)
    {
        return _accounts[msg.sender];
    }
}