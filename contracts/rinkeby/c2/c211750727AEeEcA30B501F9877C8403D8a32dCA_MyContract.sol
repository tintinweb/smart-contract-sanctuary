/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract MyContract{

// Variable
/* Variable Definition
-type
-access_modifier
-name
*/

//private
string  _name;
uint  _balance;

constructor(string memory name , uint balance){
//require(balance >= 500, "Balance Greater than 500");
    _name = name;
    _balance = balance;
    }

function getBalance() public view returns(uint balance){
    return _balance;
    }

//function deposit(uint amout) public{
//    _balance += amout;
//    } 

//function withdraw(uint amout) public{
//    _balance -= amout;
//    } 
}