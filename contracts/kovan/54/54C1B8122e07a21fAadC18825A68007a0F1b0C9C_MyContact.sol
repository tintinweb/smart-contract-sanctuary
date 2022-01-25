/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract MyContact{

//private
string _name;
uint _balance;

constructor(string memory name,uint balance){
//    require(balance>=500,"balance > 0")
    _name = name;
    _balance = balance;
}

function getBalance() public view returns(uint balance){
    return _balance;
}

//function deposite(uint amount) public{
//  _balance+=amount;
//}
}