/**
 *Submitted for verification at Etherscan.io on 2021-03-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.1;

contract MessageInABottle {
  event NewMessage(address indexed from);
  
  struct Message {
    address from;
    string value;
    uint timestamp;
  }

  Message public message;

  constructor(string memory _value) public {
    setMessage(_value);
  }

  function setMessage(string memory _value) public {
    require(bytes(_value).length > 0, "message can't be empty");
    message = Message(msg.sender, _value, block.timestamp);
    emit NewMessage(msg.sender);
  }
}