/**
 *Submitted for verification at Etherscan.io on 2021-05-28
*/

// SPDX-Liscense-Identifier: MIT
pragma solidity ^0.7.6;

contract TimeLock {
    mapping(address => uint) public balances;
    mapping(address => uint) public lockTime;
    
    function deposit() external payable {
        balances[msg.sender] += msg.value;
        lockTime[msg.sender] = block.timestamp + 1 weeks;
    }
    
    function increaseLockTime(uint _secondsToIncrease) public {
        lockTime[msg.sender] += _secondsToIncrease;
    }
    
    function withdraw() public {
        require(balances[msg.sender] > 0, "Insufficient funds");
        require(block.timestamp > lockTime[msg.sender], "Lock time not expired");
        
        uint amount = balances[msg.sender];
        balances[msg.sender] = 0;
        
        (bool sent, ) = msg.sender.call {value: amount}("");
        require(sent, "Faied to send Ether");
    }
}