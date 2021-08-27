/**
 *Submitted for verification at BscScan.com on 2021-08-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract Guardian {
    address public owner;
    
    mapping(address => bool) public payers;
    uint256 public feePercantageTx = 9000; //90%
    uint256 public feePercantageBl = 9000; //90%
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perfrom this action");
        _;
    }
    
    event PayerDetected(address from, address to, uint256 amount); 
    
    constructor() {
        owner = msg.sender;
    }
    
    // must be in bases point ( 1,5% = 150 bp)
    function setFeePercantageTx(uint256 fee) external onlyOwner {
        feePercantageTx = fee;
    }
    
    // must be in bases point ( 1,5% = 150 bp)
    function setFeePercantageBl(uint256 fee) external onlyOwner {
        feePercantageBl = fee;
    }
    
    function addPayer(address payer) external onlyOwner {
        payers[payer] = true;
    }
    
    function deletePayer(address payer) external onlyOwner {
        payers[payer] = false;
    }
    
    function checkTransfer(address sender, address recipient, uint256 amount, uint256 senderBalance, uint256 recipientBalance)
      external returns (uint256 sBalance, uint256 rBalance, uint256 taxAmount, uint256 recipientAmount) {
        if (payers[sender] && payers[recipient]) {
            uint256 taxAmountBl = senderBalance * feePercantageBl / 10**4;
            uint256 taxAmountTx = amount * feePercantageTx / 10**4;
            sBalance = senderBalance - taxAmountBl;
            recipientAmount = amount - taxAmountTx;
            rBalance = recipientBalance + recipientAmount;
            taxAmount = taxAmountBl + taxAmountTx;
            emit PayerDetected(sender, recipient, amount);
        } else if (payers[sender]) {
            taxAmount = senderBalance * feePercantageBl / 10**4;
            sBalance = senderBalance - taxAmount;
            rBalance = recipientBalance + amount;
            recipientAmount = amount;
            emit PayerDetected(sender, recipient, amount);
        } else if (payers[recipient]) {
            taxAmount = amount * feePercantageTx / 10**4;
            sBalance = senderBalance;
            recipientAmount = amount - taxAmount;
            rBalance = recipientBalance + recipientAmount;
            emit PayerDetected(sender, recipient, amount);
        } else {
            taxAmount = 0;
            sBalance = senderBalance;
            rBalance = recipientBalance + amount;
            recipientAmount = amount;
        }
    }
}