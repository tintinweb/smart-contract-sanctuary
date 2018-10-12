pragma solidity ^0.4.25;

contract Lab2 {
  uint public blockheight;
  address public owner;

constructor(uint _blockheight) public payable {
    owner = msg.sender;
    blockheight = _blockheight;
    }
    
function withdraw() public{
    require(block.number > blockheight);
    owner.transfer (address(this).balance);
    }
}