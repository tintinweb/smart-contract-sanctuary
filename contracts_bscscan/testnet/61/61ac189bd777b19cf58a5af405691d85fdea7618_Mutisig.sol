/**
 *Submitted for verification at BscScan.com on 2021-09-01
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.2;

contract Mutisig{
    address public address1;
    address public address2;
    bool public Approval1;
    bool public Approval2;
    uint256 public transactionAmount;
    address payable public toSendTo;
    constructor(){
        address1 = msg.sender;
    }
    //payables
    function deposit() public payable {}
    fallback () payable external{}
    receive() external payable {
    }
    //Change address 2
    function setAddress2(address ad) public {
        if(msg.sender==address1){
            address2 = ad;
        }
    }
    function setAddress1(address ad) public {
        if(msg.sender==address1){
            address1 = ad;
        }
    }
    function startTransaction(uint256 amount, address payable sendTo) public {
        transactionAmount = amount;
        toSendTo = sendTo;
        if(msg.sender==address1){
            Approval1 = true;
        }
        if(msg.sender==address2){
            Approval2 = true;
        }
    }
    //Called when need approval from other
    function approveTransaction() public {
        if(transactionAmount != 0){
            if(msg.sender == address1){
                if(Approval2 == true){
                    toSendTo.transfer(transactionAmount);
                }
            }
            if(msg.sender == address2){
                if(Approval1 == true){
                    toSendTo.transfer(transactionAmount);
                }
            }
        }
    }
    //Call when need to decline transaction
    function declineTransaction() public {
        if(msg.sender==address1){
            transactionAmount = 0;
            toSendTo = 0x0000000000000000000000000000000000000000;
            }
        if(msg.sender==address2){
            transactionAmount = 0;
            toSendTo = 0x0000000000000000000000000000000000000000;
        }
    }
    
    
}