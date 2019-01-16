pragma solidity ^0.4.7;

contract Challenge {
   
   function fill() public payable {
       
   }
   
    function claim() public {
       msg.sender.transfer(1 ether);
    }
}