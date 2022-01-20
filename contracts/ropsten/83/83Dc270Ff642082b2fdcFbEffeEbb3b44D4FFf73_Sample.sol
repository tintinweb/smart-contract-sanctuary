/**
 *Submitted for verification at Etherscan.io on 2022-01-20
*/

// SPDX-License-Identifier: MIT
pragma solidity = 0.8.0;

contract Sample{
    uint public balance;

    constructor(uint initialBalance){
        balance = initialBalance;
    }
    function getBalance() external view returns (uint){
        return balance;
    }
    function setBalance(uint newBalance) external {
        balance = newBalance;
    }
}