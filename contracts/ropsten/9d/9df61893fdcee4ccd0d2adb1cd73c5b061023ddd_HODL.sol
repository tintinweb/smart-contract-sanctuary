/*
LAB 2: HODL contract

This contract allows the user to save ethereum
without being able to spend it or withdraw until
a block height that is set by the user.

Yanesh
*/

pragma solidity ^0.4.25;

contract HODL {
    
    uint public blockheight;
    address public owner;
    
    constructor(uint _blockheight) public payable {
        owner = msg.sender;
        blockheight = _blockheight;
    }
    
    function withdraw() public {
        require(block.number > blockheight);
        owner.transfer(address(this).balance);
    }
    
}