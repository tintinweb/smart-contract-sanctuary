/**
 *Submitted for verification at BscScan.com on 2021-11-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

contract Bank 
{
    mapping(address => uint) _balances;
    uint _totalSupply;
    
    function deposit() public payable
    {
        _balances[msg.sender] += msg.value;
        _totalSupply += msg.value;
    }
    
    function withdraw(uint amount) public payable
    {
        require(amount <= _balances[msg.sender], 'not enough money');
        payable(msg.sender).transfer(amount);
        _balances[msg.sender] -= amount;
        _totalSupply -= amount;
    }
    
    function BalanceOf() public view returns(uint)
    {
        return _balances[msg.sender];
    }
    
    function CheckTotalSupply() public view returns(uint)
    {
        return _totalSupply;
    }
}