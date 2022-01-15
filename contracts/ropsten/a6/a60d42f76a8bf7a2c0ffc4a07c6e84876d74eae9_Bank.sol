/**
 *Submitted for verification at Etherscan.io on 2022-01-15
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Bank{
    mapping(address => uint) _balances;
    uint _totalSupply;

    event Deposite(address indexed owner,uint amount);
    event Withdraw(address indexed owner,uint amount);

    function deposite() public payable{
        require(msg.value > 0,"deposite money is zero");
        _balances[msg.sender] += msg.value;
        _totalSupply += msg.value;
        emit Deposite(msg.sender,msg.value);
    }

    function withdraw(uint amount) public{
        require(amount > 0 && amount <= _balances[msg.sender],"not enought money");
        payable(msg.sender).transfer(amount);
        _balances[msg.sender] -= amount;
        _totalSupply -= amount;
        emit Withdraw(msg.sender,amount);
    }

    function checkBalance() public view returns(uint balance_){
        return _balances[msg.sender];
    }

    function checkBalanceOf(address owner) public view returns(uint balance_){
        return _balances[owner];
    }

    function checkTotalSupply() public view returns(uint totalSupply_){
        return _totalSupply;
    }
}