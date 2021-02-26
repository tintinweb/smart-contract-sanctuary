/**
 *Submitted for verification at Etherscan.io on 2021-02-26
*/

// SPDX-License-Identifier: GPL-3.0



pragma solidity >=0.7.0 <0.8.0;

/** 
 * @title Escrow
 * @dev Implements a basic Escrow service with price tag setting
 */
 
 contract Escrow {
     
    enum State { AWAITING_PRICETAG, AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE }
    
    State public currState;
    
    address public buyer;
    address payable public seller;
    
    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only buyer can call this method");
        _;
    }
    
    modifier onlySeller() {
        require(msg.sender == seller, "Only seller can call this method");
        _;
    }
    
    constructor(address buy, address payable sell) {
        buyer = buy;
        seller = sell;
    }
    
    function setPrice() onlySeller external {
        require(currState == State.AWAITING_PRICETAG, "Price tag for product already set");
        currState = State.AWAITING_PAYMENT;
    }
    
    function deposit() onlyBuyer external payable {
        require(currState == State.AWAITING_PAYMENT, "Already received payment");
        currState = State.AWAITING_DELIVERY;
    }
    
    function confirmDelivery() onlyBuyer external {
        require(currState == State.AWAITING_DELIVERY, "Not awaiting delivery, has payment been made?");
        seller.transfer(address(this).balance);
        currState = State.COMPLETE;
    }
}