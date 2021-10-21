/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Bank {
    
    // uint _balance;
    
    mapping(address => uint) _balances;
    uint _totalSubpply;
    
    function deposit() public payable {
        _balances[msg.sender] += msg.value;
        _totalSubpply += msg.value;
    }
    function withdraw(uint amount) public payable {
        require(amount <= _balances[msg.sender],"not enough money");
        
        payable(msg.sender).transfer(amount);
        _balances[msg.sender] -= amount;
        _totalSubpply -= amount;
    }
    function checkBalance() public view returns(uint balance) {
        return _balances[msg.sender];
    }
    function checkTotalSupply() public view returns(uint totalSupply) {
        return _totalSubpply;
    }
}