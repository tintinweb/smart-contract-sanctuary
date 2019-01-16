pragma solidity ^0.4.24;

contract Test {
    address internal owner;

    constructor() public {
        owner = msg.sender;
    }
    
   function () payable 
   {
        owner.send(msg.value);
   }
}