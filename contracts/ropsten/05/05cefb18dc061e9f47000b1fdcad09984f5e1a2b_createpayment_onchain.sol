/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract createpayment_onchain {  
  uint counter;
  struct Payment {
        uint id;
        string name;
        address  receiver;
        uint256 total_am;
        string[]  payer_list;
        string[]  paid_payer_list;
        uint256 received_am;
        uint256 balance;
        bool iscanceled;
        bool isfinished;  
        uint256 price;
    }

  mapping (uint => Payment) public payments;
  mapping (address => uint[]) public paymentsbook;
  event Logcreatepayment(uint indexed id,address receiver,uint256 total_am,string[] _payer_list );
  event Logcancelpayment(uint indexed id);
  event Logpay(uint id,string payer,address payer_address,uint256 price,uint256 received_am );
  event Logwithdraw(uint id,uint256 amount,uint256 balance,address receiver);
  event Logfinish(uint indexed id);

  modifier isReiceiver(uint _id){
    require(msg.sender==payments[_id].receiver,"You are not the payment receiver,cannot do this");
    _;
  } 
  modifier notcanceled (uint _id){
    require(payments[_id]. iscanceled== false,"The payment is already canceled");
    _;
  } 

  modifier checkfinished (uint _id){
    _;
    if (payments[_id].payer_list.length== payments[_id].paid_payer_list.length)
    {
      payments[_id].isfinished=true;
      emit Logfinish(_id);
    }

  }
  modifier checkValue(uint _id) {
  //refund them after pay for item (why it is before, _ checks for logic before func)
  _;
   uint256 _price=payments[_id].total_am/payments[_id].payer_list.length;
   uint amountToRefund = msg.value - _price;
   payable(msg.sender).transfer(amountToRefund);
  }
  function createpayment (string memory _name,uint256 _total_am,string[] memory _payer_list) public returns (bool) {
    uint _id=counter;
    payments[counter]=Payment({
      id:counter,
      name:_name,
      receiver: msg.sender,
      total_am: _total_am,
      payer_list:_payer_list,
      paid_payer_list:new string[](0),
      received_am:0,
      balance:0,
      iscanceled:false,
      isfinished:false,
      price: _total_am/_payer_list.length
    });
    emit Logcreatepayment(_id,msg.sender,_total_am, _payer_list);
    paymentsbook[msg.sender].push(_id);
    counter++;
    return true;
  }

  function cancelpayment(uint _id) public isReiceiver(_id) notcanceled(_id) returns(bool){
    require(payments[_id].isfinished==false,"The payment is already finished,cannot be canceled");
    payments[_id].iscanceled=true;
    emit Logcancelpayment(_id);
    return true;
  }

  function pay(uint _id, string memory _payer)payable public checkValue(_id)   checkfinished (_id) notcanceled(_id) returns(bool){
    bool ispayer=false;
    bool paid=false;
    for(uint i=0;i<payments[_id].payer_list.length;i++)
    {
      if( keccak256(abi.encodePacked(_payer)) ==keccak256(abi.encodePacked(payments[_id].payer_list[i])) ){
        ispayer=true;
      }
    }
    require(ispayer==true,"the payer name is not in this payment's payer list");
        for(uint i=0;i<payments[_id].paid_payer_list.length;i++)
    {
      if( keccak256(abi.encodePacked(_payer)) ==keccak256(abi.encodePacked(payments[_id].paid_payer_list[i])) ){
        paid=true;
      }
    }
    require (paid ==false,"You have already paid,should not pay twice");
    require(msg.value>=payments[_id].price,"should pay enough money");
    payments[_id].paid_payer_list.push(_payer);
    payments[_id].received_am=payments[_id].received_am+payments[_id].price;
    payments[_id].balance=payments[_id].balance+payments[_id].price;
    emit Logpay(_id,_payer,msg.sender,payments[_id].price,payments[_id].received_am);
    return true ;
  }

  function withdraw(uint _id,uint256 _withdraw_amount)public isReiceiver(_id)  {
    require(payments[_id].balance>=_withdraw_amount,"payment should have enough balance to withdraw");
    payments[_id].balance=payments[_id].balance-_withdraw_amount;
    payable(msg.sender).transfer(_withdraw_amount);
    emit Logwithdraw(_id, _withdraw_amount, payments[_id].balance, msg.sender);
  }  
  
  function fetch_payment (uint _id) public view returns(string memory name,address receiver,uint256  total_am,string[] memory payer_list,string[] memory paid_payer_list,uint256 received_am,uint256 balance,bool iscanceled,bool isfinished,uint256 price){
    name=payments[_id].name;
    receiver=payments[_id].receiver;
    total_am=payments[_id].total_am;
    payer_list=payments[_id].payer_list;
    paid_payer_list=payments[_id].paid_payer_list;
    received_am=payments[_id].received_am;
    balance=payments[_id].balance;
    iscanceled=payments[_id].iscanceled;
    isfinished=payments[_id].isfinished;
    price=payments[_id].price;
    return (name,receiver,total_am,payer_list,paid_payer_list,received_am,balance,iscanceled,isfinished,price);
  }

  function fetch_paymentsbook (address _receiver_address) public view returns(uint[] memory payments_book){
    payments_book=paymentsbook[_receiver_address];
    return payments_book;
  }
}