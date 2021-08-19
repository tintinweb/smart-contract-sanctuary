/**
 *Submitted for verification at Etherscan.io on 2021-08-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

contract Staking {

    uint8 balance;

    constructor() {
    }

    function stake(uint8 amount) public {
        balance += amount;
    }

    function unstake(uint8 amount) public {
        balance -= amount;
    }
    
    function getBalance() public view returns(uint8) {
        return balance;
    }
}