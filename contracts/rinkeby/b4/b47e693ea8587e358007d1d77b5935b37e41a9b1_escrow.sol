/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

pragma solidity ^0.5.2;
 
 contract escrow{
     
     address public payer;
     address  payable public payee;
     address public lawyer;
     uint public amount;
     
     constructor(
         address _payer,
         address payable _payee,
         uint _amount
         )
         public
         {
            payer = _payer;
            payee = _payee;
            lawyer = msg.sender;
            amount = _amount;
         }
         
         function deposit() payable public {
             require(msg.sender == payer) ;
             require(address(this).balance <= amount);
             
         }
         function release() public {
             require(address(this).balance == amount);
             require(msg.sender == lawyer);
             payee.transfer(amount);
         }
         function balance() view public returns(uint){
             return address(this).balance;
         }
         
         
 }