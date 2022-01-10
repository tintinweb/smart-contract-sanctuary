/**
 *Submitted for verification at Etherscan.io on 2022-01-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract escrow{
    enum State{AWAITING_PAYMENT,AWAITING_DELIVERY,COMPLETE}
    State public currentState;
    address public buyer;
    address payable public seller;
    //  We'll create a variable of that new type as well as variables
    //  for the buyer and seller. The seller must be defined as payable because
    //   they will actually receive Ether in the end.
     modifier onlyBuyer() {
        require(msg.sender == buyer, "Only buyer can call this method");
        _;
    }
    constructor (address _buyer,address payable _seller){
        buyer=_buyer;
        seller=_seller;

    }
    function deposite() onlyBuyer external payable{
        require(currentState==State.AWAITING_PAYMENT,"already paid");
        currentState=State.AWAITING_DELIVERY;
    }
     function confirmDelivery() onlyBuyer external {
        require(currentState == State.AWAITING_DELIVERY, "Cannot confirm delivery");
        seller.transfer(address(this).balance);
        currentState = State.COMPLETE;
    }
  


}