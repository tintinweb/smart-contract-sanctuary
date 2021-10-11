// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

contract Fluthereum {
    int public balance;
    
    constructor() {
        balance = 0;
    }
    
    function deposit(int amount) public {
        balance += amount;
    }
    
    function withdraw(int amount) public {
        balance -= amount;
    }
}