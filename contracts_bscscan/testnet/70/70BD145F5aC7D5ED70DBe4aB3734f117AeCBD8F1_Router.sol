/**
 *Submitted for verification at BscScan.com on 2021-09-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

abstract contract Ownable {
    address public owner;
    
    modifier onlyOwner {
        require(msg.sender == owner, 'Only owner');
        _;
    }
}

contract Router is Ownable {
    uint public balance;
    
    uint public refferalTax;
    mapping(address => uint) public getRefferalBalance;
    
    mapping(address => uint) public getToolPrice;

    modifier costs(uint price) {
        require(msg.value >= price, 'Router: Wrong price');
        _;
    }
    
    constructor() {
        owner = msg.sender;
        
        refferalTax = 25; //do usuniecia
    }
    
    function collectPayment(uint value_, address refferal_) external {
        uint price = getToolPrice[msg.sender];
        require(value_ >= price, 'Router: Wrong price');
        uint refferalValue = value_ * refferalTax / 100;
        getRefferalBalance[refferal_] += refferalValue;
        balance += value_ - refferalValue;
    }
    
    function setPrice(address tool, uint price_) external {
        getToolPrice[tool] = price_;
    }
    
    function withdraw() external onlyOwner {
        payable(owner).transfer(balance);
        balance = 0;
    }
    
    function refferalWithdraw() external {
        require(getRefferalBalance[msg.sender] > 0, 'No funds');
        payable(msg.sender).transfer(getRefferalBalance[msg.sender]);
        getRefferalBalance[msg.sender] = 0;
    }
    
    function setRefferalTax(uint tax_) external {
        require(tax_ >= 0 && tax_ <= 100, 'Invalid value');
        refferalTax = tax_;
    }
}