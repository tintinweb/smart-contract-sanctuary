/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; // define language and compiler

contract MyContract{
    string _name;
    uint _balance;

    constructor(string memory name, uint balance) {
        require(balance >= 1000, "balance must greater and equal to 1000");
        _name = name;
        _balance = balance;
    }   

    function getBalance() public view returns (uint balance) {
        return _balance;
    }

    function getConstantBalance() public pure returns (uint balance) {
        return 1000;
    }

    function deposit(uint amount) public {
        _balance += amount;
    }
}