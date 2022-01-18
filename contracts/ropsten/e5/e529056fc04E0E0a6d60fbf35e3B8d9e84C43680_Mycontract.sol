/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract Mycontract{

string _name;
uint _balance;

constructor(string memory name,uint balance){
    require(balance > 0,"balance > 0");
    _name = name;
    _balance = balance;

}

function getBalance() public view returns(uint balance){
    return _balance;
}
function getName() public view returns(string  memory name){
    return _name;
}

function deposite(uint amount) public{
    _balance += amount;
}

}