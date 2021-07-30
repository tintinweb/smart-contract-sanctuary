/**
 *Submitted for verification at polygonscan.com on 2021-07-29
*/

pragma solidity ^0.4.19;

contract Faucet {
 
     function withdraw(uint withdraw_amount) public {
 
         // Limit withdrawal amount
         require(withdraw_amount <= 100000000000000000, "Too many");

         // Send the amount to the address that requested it
         msg.sender.transfer(withdraw_amount);
     }
 
     // Accept any incoming amount
     function () public payable {}
 
 }