/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Bank {
    // uint _balance;
    // mapping = dictionary
    // address = datatype
    mapping(address => uint) _balances;
    uint _totalSupply;

// payable ใช้คู่กับ msg.value 
    function deposit() public payable {
        _balances[msg.sender] +=  msg.value;
        _totalSupply += msg.value;
    }
    function  withdraw(uint amount) public payable  {
        require(amount <= _balances[msg.sender],"not enough money");
        payable(msg.sender).transfer(amount);
        _balances[msg.sender] -= amount;
        _totalSupply -= amount;
    }
    function checkBalance() public view returns (uint balance){
        return  _balances[msg.sender];
       
    }
    function checkTotalSupply() public view returns(uint totalSupply){
        return _totalSupply;
    }
}

// returns ใช้ตอน declare function 
// read only => ไม่เสียตัง
// write => gas เสียตัง
// pure function ใช้กับ static value 
// view function ใช้กับ read only ไม่เสียค่า gas 
// require == if 
// ข้อดีของค่า gas > ป้องกัน hacker