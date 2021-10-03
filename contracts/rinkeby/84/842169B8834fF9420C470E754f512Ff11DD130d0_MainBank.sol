/**
 *Submitted for verification at Etherscan.io on 2021-10-03
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MainBank{
    mapping(address => uint) _balances;
    event Deposit(address indexed owner, uint amount);
    event WithDraw(address indexed owner, uint amount);
    
    function deposit()public payable{
        require(msg.value >0 , "Deposit money is zero");
        _balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    function withDraw(uint amount) public{
        require(amount>0 && amount<=_balances[msg.sender], "Not enugh money");
        payable(msg.sender).transfer(amount);
        _balances[msg.sender] -= amount;
        emit WithDraw(msg.sender, amount);
    }
    
    function check_balance() public view returns(uint){
        return _balances[msg.sender];
    }
    function balanceOf(address owner) public view returns (uint){
        return _balances[owner];
    }
}