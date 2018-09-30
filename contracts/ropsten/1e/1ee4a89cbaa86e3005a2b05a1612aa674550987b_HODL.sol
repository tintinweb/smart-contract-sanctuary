pragma solidity ^0.4.25;

contract HODL {
    uint public blockheight;
    address public owner;
    
    constructor(uint _blockheight) public payable {
        blockheight = _blockheight;
        owner = msg.sender;
    }
    
    function withdraw() public {
        require(block.number > blockheight);
        owner.transfer(owner.balance);
    }
}