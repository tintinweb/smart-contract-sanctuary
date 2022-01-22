/**
 *Submitted for verification at Etherscan.io on 2022-01-22
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Bank {

    //uint _balance;
    //0x69Fa3071253a16a5B7409bE8e14193cd6f7838AA
    mapping(address => uint) _balances;
    uint _totalSupply;

    function deposit() public payable {

        _balances[msg.sender] += msg.value;
        _totalSupply += msg.value;
    }

    function withdraw(uint amount) public payable {
        require(amount <= _balances[msg.sender], "not enough money");

        payable(msg.sender).transfer(amount);
        _balances[msg.sender] -= amount;
        _totalSupply -= amount;

    }

    function checkBalance() public view returns(uint balance) {
        return _balances[msg.sender];
    }

    function checkTotalSupply() public view returns(uint totalSupply){
       return _totalSupply;
    }
}