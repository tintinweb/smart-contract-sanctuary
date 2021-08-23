// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Token.sol';

contract DEX {
    event Sold(address recipient, uint amount);
    event Withdrawn(address recipient, uint amount);
    
    struct Sale {
        uint numTokens;
        uint soldAt;
        bool withdrawn;
    }
    
    mapping(address => Sale) public sales;
    
    uint public minAmount = 1;
    uint public maxAmount = 10;
    uint public tokenPrice = 0.01 ether;
    uint public duration = 20;
    uint public interest = 0.002 ether;
    Token public token;

    constructor() {
        token = new Token('Interest Token', 'ITK', 18, 100);
    }

    function buy(uint numTokens) payable public {
        address recipient = msg.sender;
        require(sales[recipient].numTokens == 0, 'You have already bought tokens');
        require(numTokens > minAmount && numTokens <= maxAmount, 'You must buy between minAmount and maxAmount tokens');
        require(msg.value == numTokens*tokenPrice, 'Please send correct amount of ether') ;
        uint dexBalance = token.balanceOf(address(this));
        require(numTokens <= dexBalance, "Not enough tokens in the reserve");
        token.transfer(recipient, numTokens);
        token.approve(recipient, numTokens);
        sales[recipient] = Sale (numTokens, block.timestamp, false);
        emit Sold(recipient, numTokens);
    }

    function withdraw() public {
        address recipient = msg.sender;
        Sale storage sale = sales[recipient];
        uint numTokens = sale.numTokens;
        require(numTokens > 0, "You don't have any tokens");
        require(block.timestamp >= sale.soldAt + duration, 'You cannot redeem your token yet');
        uint withdrawAmount = numTokens*(tokenPrice + interest);
        require(address(this).balance >= withdrawAmount, 'The contract has insufficient funds');
        token.transferFrom(recipient, address(this), numTokens);
        payable(recipient).transfer(withdrawAmount);
        token.approve(recipient, 0);
        sales[recipient].withdrawn = true;
        emit Withdrawn(recipient, numTokens);
    }
    
    function getTokenBalance(address account) public view returns (uint) {
        return token.balanceOf(account);
    }
    
    function getTokenAllowance(address account) public view returns (uint) {
        return token.allowance(address(this), account);
    }
    
    function getEtherBalance() public view returns (uint) {
        return address(this).balance;
    }

}