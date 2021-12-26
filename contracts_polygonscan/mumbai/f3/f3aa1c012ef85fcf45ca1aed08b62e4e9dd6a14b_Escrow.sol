/**
 *Submitted for verification at polygonscan.com on 2021-12-25
*/

// SPDX-License-Identifier: KwstasG
pragma solidity ^0.8.7;

contract Escrow {
    enum State { AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE, CANCELED }
    State public currentState;

    address payable public Buyer_Address;
    address payable public Seller_Address;
    address payable public Marketplace_Address;

    uint public Item_Amount;
    uint public Commission_Amount;
    uint public Delivery_Expenses_Amount;
    uint public Total_Amount;
    
    event ContractCreated(
        address Creator_Address,
        address Contract_Address,
        address Buyer_Address,
        address Seller_Address,
        address Marketplace_Address,
        uint Item_Amount,
        uint Commission_Amount,
        uint Delivery_Expenses_Amount,
        uint Total_Amount);

    constructor(
        address payable Buyer,
        address payable Seller,
        address payable Marketplace,
        uint _Item_Amount,
        uint _Commission_Amount,
        uint _Delivery_Expenses_Amount) {

        Buyer_Address = Buyer;
        Seller_Address = Seller;
        Marketplace_Address = Marketplace;

        Item_Amount = _Item_Amount;
        Commission_Amount = _Commission_Amount;
        Delivery_Expenses_Amount = _Delivery_Expenses_Amount;

        Total_Amount = _Item_Amount + _Commission_Amount + _Delivery_Expenses_Amount;

        emit ContractCreated(msg.sender, address(this), Buyer, Seller, Marketplace, _Item_Amount, _Commission_Amount, _Delivery_Expenses_Amount, Total_Amount);
    }

    modifier onlyBuyer() {
        require(msg.sender == Buyer_Address, "Only buyer can call this method!");
        _;
    }

    function deposit() onlyBuyer payable public {
        require(msg.value == Total_Amount, "Deposit must be equal to Total Amount" );
        require(currentState == State.AWAITING_PAYMENT, "Already Paid!");
        currentState = State.AWAITING_DELIVERY;
    }
    
    function confirmDelivery() onlyBuyer public {
        require(currentState == State.AWAITING_DELIVERY, "Cannot Confirm Delivery!");
        Marketplace_Address.transfer(Commission_Amount);
        Seller_Address.transfer(Item_Amount + Delivery_Expenses_Amount);
        currentState = State.COMPLETE;
    }

     function cancel() onlyBuyer public {
         require(currentState == State.AWAITING_DELIVERY, "Cannot Cancel!");
         Buyer_Address.transfer(address(this).balance);
         currentState = State.CANCELED;
     }

}