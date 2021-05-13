/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Bank {
    
    mapping(address => uint) public balances;
    
    // ใช้ uint จะเเทนการใช้ uint256 เลย ใน 0.8.0 ขึ้นไป
    // totalsupply สำหรับเช็ค supply ทั้งหมดของ contract นี้
    function totalSupply() public view returns(uint) {
        return address(this).balance;
    }
    
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }
    
    function myEtherBalance() public view returns(uint) {
        return msg.sender.balance;
    }
    
    // ถอนได้ทั้งของ address ของ contract
    // payable(msg.sender).transfer(address(this).balance);
    function withdraw() public {
        payable(msg.sender).transfer(balances[msg.sender]);
        balances[msg.sender] = 0;
    }
}