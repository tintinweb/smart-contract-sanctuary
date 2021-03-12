/**
 *Submitted for verification at Etherscan.io on 2021-03-11
*/

//SPDX-License-Identifier: MIT 
pragma solidity >= 0.7.1;

contract Escrow{
  bool public buyerState_;
  bool public sellerState_;

  address payable public buyer_;
  address payable public seller_;
  address private escrow_;
  uint balance_;
  uint start_;

  
    constructor(address payable _buyer, address payable _seller) public{
        buyer_ = _buyer;
        seller_ = _seller;
        escrow_ = msg.sender;
        start_ = block.timestamp;
    }

    function accept() public{
      if(msg.sender == buyer_){
        buyerState_ = true;
      }
      if(msg.sender == seller_){
        sellerState_ = true;
      }
      if(buyerState_ && sellerState_){
        payOut();
      }
    }

    function reject() public{
      if(msg.sender == seller_){
        sellerState_ = false;
      }
      if(msg.sender == buyer_){
        buyerState_ = false;
      }
      if(!sellerState_ && !buyerState_){
          selfdestruct(buyer_); 
      }
      if(!buyerState_ && sellerState_ && block.timestamp >= start_ + 30 days){
        selfdestruct(buyer_);
      }
      if(buyerState_ && sellerState_){
        payOut();
      }
    }

    function deposit() public payable{
      if(msg.sender == buyer_){
        balance_ += msg.value;
      }
    }

    function payOut() private{
      require(buyerState_ && sellerState_);
      if (seller_.send(balance_)){
        balance_ = 0;
      }
    }

    function kill() public {
      if (msg.sender == escrow_) {
        selfdestruct(buyer_);
    }
  }
}