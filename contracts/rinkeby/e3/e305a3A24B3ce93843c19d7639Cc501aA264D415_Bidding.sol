// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Bidding {
  address payable public receiver;
  bool public isActive;

  address public topBidder;
  uint256 public highestValue;

  mapping(address => uint256) lostBidders;

  constructor(address payable _receiver, uint256 starting_price) {
    receiver = _receiver;

    topBidder = _receiver;
    highestValue = starting_price;

    isActive = true;
  }

  modifier onlyReceiver() {
    require(msg.sender == receiver, "Only the receiver can do this.");
    _;
  }

  modifier auctionActive() {
    require(isActive, "Auction has already ended");
    _;
  }

  function setBid() public payable auctionActive {
    require(
      msg.value > highestValue,
      "Please place a bid higher than the current highest bidder"
    );

    if (highestValue > 0) {
      lostBidders[topBidder] += highestValue;
    }

    topBidder = msg.sender;
    highestValue = msg.value;
  }

  function endBid() public onlyReceiver auctionActive {
    //todo: announce who the winner is
    (bool success, ) = (msg.sender).call{value: highestValue}("");
    isActive = !success;
  }

  function withdraw() public returns (bool) {
    uint256 amount = lostBidders[msg.sender];

    if (amount > 0) {
      lostBidders[msg.sender] = 0;
      (bool success, ) = (msg.sender).call{value: amount}("");
      if (!success) {
        lostBidders[msg.sender] = amount;
        return false;
      }
    }
    return true;
  }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}