/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract BlackFriday {

    address payable user;
    uint balance;

    function deposit () public payable {
        if(balance > 0)
            require(msg.sender == user, "Already in use");
        user = payable(msg.sender);
        balance += msg.value;
    }

    function withdray (uint amount) public {
        require(msg.sender == user, "You are not allowed");
        require(amount <= balance, "Too much!");
        balance -= amount;
        user.transfer(amount);
    }

}