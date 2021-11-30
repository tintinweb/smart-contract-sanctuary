/**
 *Submitted for verification at Etherscan.io on 2021-11-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Bank {

    mapping(address => uint) balance;
    uint totalSupply;

    function deposit() public payable {
        balance[msg.sender] += msg.value;
        totalSupply += msg.value;
    }
    
    function withdraw(uint amount) public {
        require(amount <= balance[msg.sender], "Not Enogh Money to Withdraw");
        payable(msg.sender).transfer(amount);
        balance[msg.sender] -= amount;
        totalSupply -= amount;
    }

    function checkBalance() public view returns(uint totalBalance) {
        return balance[msg.sender];
    }

    function checkTotalSupply() public view returns(uint TotalDeposit) {
        return totalSupply;
    }
}