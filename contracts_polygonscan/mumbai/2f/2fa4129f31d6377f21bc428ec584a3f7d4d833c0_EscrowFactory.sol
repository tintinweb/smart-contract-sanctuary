/**
 *Submitted for verification at polygonscan.com on 2021-12-23
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

    }

    modifier onlyBuyer() {
        require(msg.sender == Buyer_Address, "Only buyer can call this method!");
        _;
    }

    function deposit() payable public {
        require(msg.value > 0, "Amount must be greater than 0");
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


contract EscrowFactory {
    
    Escrow[] Escrow_Contract;

    function Create_Escrow_Contract(
        address payable Buyer,
        address payable Seller,
        address payable Marketplace,
        uint Item_Amount,
        uint Commission_Amount,
        uint Delivery_Expenses_Amount
        ) public {
        Escrow_Contract.push(new Escrow(
            Buyer,
            Seller,
            Marketplace,
            Item_Amount,
            Commission_Amount,
            Delivery_Expenses_Amount));
        }

    function Deployed_Contracts_Counts() public view returns(uint Contracts) {
           return Escrow_Contract.length;
    }

    function get_Contract(uint ID) public view returns(Escrow) {
        return Escrow_Contract[ID];
    }

    function get_Contract_Balance(uint ID) public view returns(uint Balance) {
        return address(Escrow_Contract[ID]).balance;
    }

    function get_Contract_Buyer(uint ID) public view returns(address Buyer) {
        return Escrow_Contract[ID].Buyer_Address();
    }

    function get_Contract_Seller(uint ID) public view returns(address Seller) {
        return Escrow_Contract[ID].Seller_Address();
    }

    function get_Contract_Marketplace(uint ID) public view returns(address Marketplace) {
        return Escrow_Contract[ID].Marketplace_Address();
    }

    function get_Contract_Item_Amount(uint ID) public view returns(uint Item_Amount) {
        return Escrow_Contract[ID].Item_Amount();
    }

    function get_Contract_Commission_Amount(uint ID) public view returns(uint Commission_Amount) {
        return Escrow_Contract[ID].Commission_Amount();
    }

    function get_Contract_Total_Amount(uint ID) public view returns(uint Total_Amount) {
        return Escrow_Contract[ID].Total_Amount();
    }

    function get_Contract_Delivery_Expenses_Amount(uint ID) public view returns(uint Delivery_Expenses_Amount) {
        return Escrow_Contract[ID].Delivery_Expenses_Amount();
    }

    function get_Contract_State(uint ID) public view returns(Escrow.State CurrentState) {
        return Escrow_Contract[ID].currentState();
    }

    function exec_Deposit(uint ID) payable public{
        Escrow_Contract[ID].deposit();
    }

    function exec_ConfirmDelivery(uint ID) public{
        Escrow_Contract[ID].confirmDelivery();
    }

    function exec_Cancel(uint ID) public{
        Escrow_Contract[ID].cancel();
    }

}