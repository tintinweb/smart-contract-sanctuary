/**
 *Submitted for verification at Etherscan.io on 2022-01-16
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract MyContract{

    string _name;
    uint _balance;
    constructor(string memory name,uint balance ){
       require(balance>=500,"Balance greater and equal 500");
        _name = name;
        _balance = balance;
    }
    function getBalance() public view returns(uint balance){
        return _balance;
    }

    // function deposite(uint amount) public{
    //     _balance+=amount;
    // }
}