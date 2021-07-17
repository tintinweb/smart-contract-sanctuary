/**
 *Submitted for verification at BscScan.com on 2021-07-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

contract BankAcc {
    
    uint balance;
    
    constructor() public {
        balance = 0;
    }
    
    function getBalance() view public returns(uint) {
        return balance;
    }
    
    function setBalance(uint256 fValue) public {
        balance=fValue;
    }
}