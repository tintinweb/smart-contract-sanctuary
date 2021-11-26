/**
 *Submitted for verification at Etherscan.io on 2021-11-26
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Lottery {
  address public manager;
  address[] public players;
  
  constructor() {
    manager = msg.sender;
  }

  function enter() public payable {
    require(msg.value >= 0.001 ether);

    players.push(msg.sender);
  }

  function getAllPlayers() public view returns (address[] memory) {
    return players;
  }

  function pickWinner() public restricted {
    uint index = random() % players.length;
    payable(players[index]).transfer(address(this).balance);
    players = new address[](0);
  }

  // Pseudo-random number generator that just returns a huge number
  // Shouldn't actually be used in a production app
  function random() private view returns (uint) {
    return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
  }

  modifier restricted() {
    require(msg.sender == manager);
    _;
  }
}