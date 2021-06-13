/**
 *Submitted for verification at Etherscan.io on 2021-06-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;


contract escrowTest{

    enum State { AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE }
    
    State public currState;
    
    address public buyer;
    address payable public seller;
    bool internal Empty;

     modifier onlyBuyer() {
        require(msg.sender == buyer, "Only buyer can call this method");
        _;
    }

    function deposit(address payable sellerAddress) external payable {
        require(currState == State.AWAITING_PAYMENT, "Already paid");
        if (address(this).balance == 0){
            Empty = true;}
        else{
            Empty = false;
        
        }
        require(Empty == true, "Contract not empty");
        require(msg.value > 0, "Value cannot be zero");
        seller = sellerAddress;
        buyer = msg.sender;
        currState = State.AWAITING_DELIVERY;
    }

    function confirmDelivery() onlyBuyer external {
        require(currState == State.AWAITING_DELIVERY, "Cannot confirm delivery");
        seller.transfer(address(this).balance);
        currState = State.COMPLETE;
    }
}