/**
 *Submitted for verification at polygonscan.com on 2021-12-28
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
    
    event Contract_Created(
        address Creator_Address,
        address Contract_Address,
        address Buyer_Address,
        address Seller_Address,
        address Marketplace_Address,
        uint Item_Amount,
        uint Commission_Amount,
        uint Delivery_Expenses_Amount,
        uint Total_Amount,
        State currentState);

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

        emit Contract_Created(msg.sender, address(this), Buyer, Seller, Marketplace,
         _Item_Amount, _Commission_Amount, _Delivery_Expenses_Amount, Total_Amount, currentState);
    }

    modifier onlyBuyer() {
        require(msg.sender == Buyer_Address, "Only buyer can call this method!");
        _;
    }

    event Deposit_Successfull(
        address Depositor_Address,
        address Contract_Address,
        uint Total_Amount,
        uint Deposit_Amount,
        State currentState);

    function deposit() onlyBuyer payable public {
        require(msg.value == Total_Amount, "Deposit must be equal to Total Amount" );
        require(currentState == State.AWAITING_PAYMENT, "Already Paid!");

        currentState = State.AWAITING_DELIVERY;

        emit Deposit_Successfull(msg.sender, address(this),
        Total_Amount, msg.value, currentState);
    }

     event Complited(
        address Confirmator_Address,
        address Contract_Address,
        address Buyer_Address,
        address Seller_Address,
        address Marketplace_Address,
        uint Amount_To_Seller,
        uint Amount_To_Marketplace,
        uint Total_Amount,
        State currentState);
    
    function confirmDelivery() onlyBuyer public {
        require(currentState == State.AWAITING_DELIVERY, "Cannot Confirm Delivery!");
        Seller_Address.transfer(Item_Amount + Delivery_Expenses_Amount);
        Marketplace_Address.transfer(Commission_Amount);
        currentState = State.COMPLETE;
        
        emit Complited(msg.sender, address(this), Buyer_Address, Seller_Address, Marketplace_Address,
        Item_Amount + Delivery_Expenses_Amount,
        Commission_Amount,
        Total_Amount, currentState);
    }

     event Canceled(
        address Cancelation_Address,
        address Contract_Address,
        address Buyer_Address,
        uint Amount_To_Buyer,
        uint Total_Amount,
        State currentState);

     function cancel() onlyBuyer public {
         require(currentState == State.AWAITING_DELIVERY, "Cannot Cancel!");
         Buyer_Address.transfer(address(this).balance);
         currentState = State.CANCELED;

        emit Canceled(msg.sender, address(this), Buyer_Address, 
        address(this).balance, Total_Amount, currentState);
     }

}