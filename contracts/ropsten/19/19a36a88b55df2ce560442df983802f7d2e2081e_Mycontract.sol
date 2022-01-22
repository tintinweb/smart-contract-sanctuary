/**
 *Submitted for verification at Etherscan.io on 2022-01-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Mycontract{

//private
string _name;
uint _balance;

constructor(string memory name,uint balance){
    require(balance>=100,"balance greater and equal 100");
    _name = name;
    _balance = balance;
}

function getbalance() public view returns(uint balance){
    return _balance;
}

function deposite(uint amount) public{
    _balance+=amount;
}

}