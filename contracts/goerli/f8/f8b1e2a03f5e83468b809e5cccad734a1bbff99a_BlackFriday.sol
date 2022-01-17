/**
 *Submitted for verification at Etherscan.io on 2022-01-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.9;

contract BlackFriday {

    address payable user;
    uint public balance;
    uint public depositTime;

    event Deposit(address issuer, uint amount, uint time, uint final_balance);
    event Withdraw(address beneficiary, uint amount, uint limit, uint time );

    function deposit () public payable {
        if(balance>0)
            require(msg.sender == user, "Already in use");
        user = payable(msg.sender);
        balance += msg.value;
        depositTime = block.timestamp;
        emit Deposit(msg.sender, msg.value, depositTime, balance);
    }

    function withdraw (uint amount) public {
        require(msg.sender == user, "You are not allowed");
        require(amount <= balance, "Too much!");
        require(block.timestamp > depositTime + 3 minutes, "Too early");
        balance -= amount;
        user.transfer(amount);
        emit Withdraw(msg.sender, amount, balance, block.timestamp);
    }

}