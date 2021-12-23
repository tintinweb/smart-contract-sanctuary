/**
 *Submitted for verification at Etherscan.io on 2021-12-23
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract Bank {


    //uint _balance;
    mapping(address => uint) _balance;
    uint _totalSupply;

    function deposit() public payable {
        _balance[msg.sender] += msg.value;
        _totalSupply += msg.value;
    }
    function withdraw(uint amount) public payable {
        require(amount <= _balance[msg.sender],"not enough money");

        payable(msg.sender).transfer(amount);
        _balance[msg.sender] -= amount;
        _totalSupply -= amount;
    }
    function cheakBalance() public view returns(uint balance) {
        return _balance[msg.sender];
    }

    function checkTotalSupply() public view returns(uint totalSupply) {
        return _totalSupply;
    }
}