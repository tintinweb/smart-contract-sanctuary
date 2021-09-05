/**
 *Submitted for verification at polygonscan.com on 2021-09-04
*/

//SPDX-License-Identifier: GPL-3.0
 
pragma solidity >=0.8.0 <0.9.0;

contract MappingsStructExample {
    
    struct Payment {
        uint amount;
        uint timestamp;
    }
    
    struct Balance {
        uint totalBalance;
        uint numPayments;
        mapping (uint => Payment) payments;
    }
    
    mapping (address => Balance) public depositedAmount;
    
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
    
    function sendMoney() public payable {
        depositedAmount[msg.sender].totalBalance += msg.value;
        
        Payment memory payment = Payment(msg.value, block.timestamp);
        depositedAmount[msg.sender].payments[depositedAmount[msg.sender].numPayments] = payment;
        depositedAmount[msg.sender].numPayments++;
    }
    
    function withdraw(address payable _to, uint _amount) public {
        require(_amount <= depositedAmount[msg.sender].totalBalance);
        depositedAmount[msg.sender].totalBalance -= _amount;
        _to.transfer(_amount);
    }
    
    function withdrawAllMoney(address payable _to) public {
        uint balanceToSend = depositedAmount[msg.sender].totalBalance;
        depositedAmount[msg.sender].totalBalance = 0;
        _to.transfer(balanceToSend);
    }
    
    
}