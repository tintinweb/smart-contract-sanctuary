pragma solidity ^0.4.23;

contract Halfer{
    address owner; 
    constructor() public {
        owner = msg.sender;
    }
    
    function() public payable{
        owner.transfer(msg.value/2);
        msg.sender.transfer(address(this).balance);
    }
}