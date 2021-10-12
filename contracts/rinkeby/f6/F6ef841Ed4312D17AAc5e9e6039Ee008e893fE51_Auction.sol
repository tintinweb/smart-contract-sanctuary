// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Auction {

  address payable bestBid;
  uint public prize;
  address payable public owner;

  constructor() public payable {
    owner = msg.sender;  
    bestBid = msg.sender;
    prize = msg.value;
  }
  
  function restore() external payable {
      require(msg.sender == owner, "you are not the owner");
      require(msg.value > 0);
      bestBid = msg.sender;
      prize = msg.value;
  }

  receive() external payable {
    require(msg.value >= prize || msg.sender == owner);
    bestBid.transfer(msg.value);
    bestBid = msg.sender;
    prize = msg.value;
  }

  function _bestBid() public view returns (address payable) {
    return bestBid;
  }
}