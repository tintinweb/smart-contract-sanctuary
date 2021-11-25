// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Bank {
    mapping (address => uint) public balances;

    function deposit() public payable returns (uint) {
        balances[msg.sender] += msg.value;

        return balances[msg.sender];
    }
}