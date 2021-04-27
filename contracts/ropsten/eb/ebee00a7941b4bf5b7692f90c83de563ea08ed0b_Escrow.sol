/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

pragma solidity ^0.4.25;

contract Escrow {
    
    
    address  buyer;
    address  seller;
    address  escrow_agent;
    uint256  escrow_fee;        //Fee charged by escrow
    uint256   amount;

    
    function deposit(address _seller,address _escrow_agent,uint256 _escrow_fee) public payable {
         buyer = msg.sender;
        seller = _seller;
        amount =  msg.value-(msg.value * _escrow_fee)/100;
        escrow_agent = _escrow_agent;
        escrow_fee = ( msg.value * _escrow_fee)/100;
        seller.transfer(amount);
        escrow_agent.transfer(escrow_fee);
    }
    
   
}