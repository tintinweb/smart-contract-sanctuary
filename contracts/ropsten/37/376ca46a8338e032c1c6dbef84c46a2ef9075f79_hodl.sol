pragma solidity ^0.4.25;

contract hodl {
    
    address public owner;
    
    uint public blockheight;
    
    constructor( uint _blockheight) {

        owner = msg.sender;
        
        blockheight = _blockheight;
        
    }
    
    function withdraw() public returns (bool) {
        
        require( block.number >= blockheight  );

        uint256 balance = address(this).balance;

        msg.sender.transfer(balance);
        
        return true;
    }
}