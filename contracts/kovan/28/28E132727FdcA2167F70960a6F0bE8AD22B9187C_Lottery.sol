// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.3;

contract Lottery {
  address public manager;
  address payable[] public players;

  constructor() {
    manager = msg.sender;
  }

  function enter() public payable {
    require(msg.value >= .01 ether, 'requires payment');
    players.push(msg.sender);
  }

  function pickWinner() public restricted {
    require(players.length > 0, 'no players');
    uint index = random() % players.length;
    players[index].transfer(address(this).balance);
    players = new address payable[](0);
  }

  function getPlayers() public view returns (address payable[] memory) {
    return players;
  }

  // pseudorandom, never actually use this
  function random() private view returns (uint) {
    return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, players)));
  }

  modifier restricted() {
    require(msg.sender == manager, 'manager only');
    _;
  }
}

