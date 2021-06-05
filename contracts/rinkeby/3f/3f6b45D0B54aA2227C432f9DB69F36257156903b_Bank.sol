/**
 *Submitted for verification at Etherscan.io on 2021-06-05
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Bank {
    
    mapping(address => uint256) balance;
    
    function deposit(uint256 amount) public {
        balance[msg.sender] += amount;
    }
    
    function withdraw(uint256 amount) public {
        require(amount <= balance[msg.sender], "not enough money");
        balance[msg.sender] -=  amount;
    }
    
    function checkbalance() public view returns(uint256) {
        return balance[msg.sender];
    }
}