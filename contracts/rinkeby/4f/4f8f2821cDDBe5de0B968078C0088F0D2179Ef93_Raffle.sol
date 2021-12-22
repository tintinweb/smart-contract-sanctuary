/**
 *Submitted for verification at Etherscan.io on 2021-12-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
  Requirements:
    The creator sets the number of tickets and ticket price
    The creator must purchase the first ticket on creation
    Participants can buy as many tickets as are available
    The prize is awarded to a random participant once all tickets are sold
*/

contract Raffle {
  
  uint public maxTickets;
  uint public price;
  address public creator;
  address[] public participants;
  address public winner;

  event JoinEvent(uint _length, uint _qty);
  event DrawEvent(address _winner, uint _prize);
  event Paid(address _from, uint _value);

  constructor(uint _maxTickets, uint _price) {
    
    maxTickets = _maxTickets;
    price = _price;
    creator = msg.sender;
    uint qty = 1;
    joinraffle(qty);

  }

  // `fallback` function called when eth is sent to Payable contract
  receive () external payable {
    emit Paid(msg.sender, msg.value);
  }

  // purchase tickets
  function joinraffle(uint _qty) public payable returns(bool) {

    if (msg.value < price * _qty) {
      return false;
    }

    if (int(participants.length) > int(maxTickets - _qty)) {
      return false;
    }

    for (uint i = 0; i < _qty; i++) {
      participants.push(msg.sender);
    }

    emit JoinEvent (participants.length, _qty);
    
    if (participants.length == maxTickets) {
      return draw();
    }
    return true;
  }

  // award prize when all tickets are sold
  function draw() internal returns (bool) {

    uint seed = block.number;
    uint random = uint(keccak256(abi.encodePacked(seed))) % participants.length;
    winner = participants[random];
    uint prize = address(this).balance; // maxTickets * price;
    payable(winner).transfer(prize);
    emit DrawEvent (address(winner), prize);
    return true;
  }
}