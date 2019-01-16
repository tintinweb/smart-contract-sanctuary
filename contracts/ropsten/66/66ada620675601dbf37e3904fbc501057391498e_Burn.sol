pragma solidity ^0.4.25;

contract Burn {
    
    uint256 public value;
    address public owner;
    
    constructor() public payable {
        value = msg.value;
        owner = msg.sender;
    }
   
   
}