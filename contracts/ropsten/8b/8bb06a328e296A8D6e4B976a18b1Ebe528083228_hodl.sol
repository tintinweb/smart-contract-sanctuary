pragma solidity ^0.4.25;

contract hodl {

    uint256 public blockheight;
    address public owner;

    constructor(uint256 _blockheight) public payable {
        owner = msg.sender;
        blockheight = _blockheight;
    }

    function withdraw() public payable {
        require(block.number > blockheight && msg.sender == owner);
        owner.transfer(msg.value);
    }

}