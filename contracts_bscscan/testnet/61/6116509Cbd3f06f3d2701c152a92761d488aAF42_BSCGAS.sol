/**
 *Submitted for verification at BscScan.com on 2021-10-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract BSCGAS {
    string public name = "BSC Transaction Fee";
    string public symbol = "BSCGAS";
    string public info1 = "Mint 1coin/transaction/address/hour";
    string public info2 = "Minimum transfer = 2 coins";
    uint public decimals = 18;
    uint public totalSupply = 1000000000000000000000000;
    mapping (address => uint) public balance;
    mapping (address => uint) private deadline;
    
    constructor() {
        balance[msg.sender] = 1000000000000000000000000 ; 
    }
    
    function transfer(address _to, uint amount) public {
        require( msg.sender!=_to  && amount>=2000000000000000000 && balance[msg.sender]>=amount );
        if(block.timestamp > deadline[msg.sender]){
            deadline[msg.sender] = block.timestamp + 1 hours;
            totalSupply++;
            balance[msg.sender] -= (amount-1000000000000000000) ; // on every transaction, mint one coin to mimic transaction fee
        }
        else{
            balance[msg.sender] -= (amount) ; 
        }
        balance[_to] += amount;
    }
}