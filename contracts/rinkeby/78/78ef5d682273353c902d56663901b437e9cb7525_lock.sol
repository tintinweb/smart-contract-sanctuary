/**
 *Submitted for verification at Etherscan.io on 2021-12-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


contract lock {
    
    mapping(address=>uint) public balance;
    mapping(address=>uint) public time;

    function deposit() payable public{
        // require(balance[msg.sender]==0,"only deposit once")
        require(block.timestamp>=time[msg.sender]+60,"in lock");


        balance[msg.sender]=balance[msg.sender]+msg.value;
        time[msg.sender]=block.timestamp;
    }

    function withdraw(uint amount) public{
        require(amount<=balance[msg.sender],"insufficient balance");
        require(block.timestamp>=time[msg.sender]+60, "in lock period");
        balance[msg.sender]=balance[msg.sender]-amount;
        payable(address(msg.sender)).transfer(amount);
    }
    
}