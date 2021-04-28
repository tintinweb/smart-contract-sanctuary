/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Lottery {

  address public owner;
  uint public ticketPrice = 0.1 ether;
  uint public gameDuration = 1 days;
  address[] private players;
  uint public startTime;

  
  constructor() {
    owner = msg.sender;
    startTime = block.timestamp;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  receive() external payable {
    require(block.timestamp <= startTime + gameDuration, "The ticket sales are closed");
    if (msg.value % ticketPrice != 0) {
        payable(msg.sender).transfer(msg.value % ticketPrice);
    }
    uint ticketsBought = msg.value / ticketPrice;
    for (uint i=0; i < ticketsBought; i++) {
        players.push(msg.sender);
    }
  } 

  function pickWinner() public {
    require(block.timestamp > startTime + gameDuration, "The ticket sales are still open");
    if (players.length != 0) {
      uint ticketsSold = players.length;
      uint winningID = block.timestamp % ticketsSold;
      address winner = players[winningID];
      payable(winner).transfer(address(this).balance*95/100);
      payable(owner).transfer(address(this).balance);
      delete players;
      delete winningID;
      delete winner;
    }
    startTime = block.timestamp;
  }

  function changeTicketPrice(uint _newPrice) public onlyOwner {
    require(players.length == 0, "In order not to disadvantage players, the price cannot be changed if the current game already has players");
    ticketPrice = _newPrice;
  }


  function changeGameDuration(uint _newGameDuration) public onlyOwner {
    require(players.length == 0, "In order not to disadvantage players, the duration cannot be changed if the current game already has players");
    gameDuration = _newGameDuration;
  }

}