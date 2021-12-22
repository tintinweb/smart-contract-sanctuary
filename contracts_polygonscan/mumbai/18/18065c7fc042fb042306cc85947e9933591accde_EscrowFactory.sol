/**
 *Submitted for verification at polygonscan.com on 2021-12-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Escrow {
    enum State { AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE }
    State public currentState;

    address public Buyer_Address;
    address payable public Seller_Address;
    
    constructor(address payable Buyer, address payable Seller) {
        Buyer_Address = Buyer;
        Seller_Address = Seller;
    }

    modifier onlyBuyer() {
        require(msg.sender == Buyer_Address, "Only buyer can call this method");
        _;
    }

    function deposit() onlyBuyer payable public {
        require(msg.value > 0, "Amount cant be 0");
        require(currentState == State.AWAITING_PAYMENT, "Already paid");
        currentState = State.AWAITING_DELIVERY;
    }
    
    function confirmDelivery() onlyBuyer public {
        require(currentState == State.AWAITING_DELIVERY, "Cannot confirm delivery");
        Seller_Address.transfer(address(this).balance);
        currentState = State.COMPLETE;
    }
     function Cancel() onlyBuyer public {
         selfdestruct(payable(Buyer_Address));
     }

}


contract EscrowFactory {
    

    function Create_Escrow_Contract(address payable Buyer, address payable Seller) public returns(Escrow) {
         return new Escrow(Buyer, Seller);
    }

}