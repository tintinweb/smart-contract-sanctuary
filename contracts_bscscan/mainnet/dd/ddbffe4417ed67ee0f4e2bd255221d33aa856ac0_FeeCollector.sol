/**
 *Submitted for verification at BscScan.com on 2021-11-18
*/

pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

contract FeeCollector { // 0x25A7a9266e5d57c409A05A5C9f2a2a6b40e6165A
    address public owner;
    uint256 public balance;
    
    constructor() {
        owner = msg.sender; // store information who deployed contract
    }
    
    receive() payable external {
        balance += msg.value; // keep track of balance (in WEI)
    }
    
    
    function withdraw(uint amount, address payable destAddr) public {
        require(msg.sender == owner, "Only owner can withdraw");
        require(amount <= balance, "Insufficient funds");
        
        destAddr.transfer(amount); // send funds to given address
        balance -= amount;
    }
}