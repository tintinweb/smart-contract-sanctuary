/**
 *Submitted for verification at BscScan.com on 2021-08-03
*/

pragma solidity ^0.4.21;

contract Lottery {
  address public manager;
  address[] public players;

  constructor() public {
    manager = msg.sender;
  }

  function enter() public payable {
    require(msg.value > .01 ether);

    players.push(msg.sender);
  }

  function random() private view returns (uint) {
    return uint(keccak256(abi.encodePacked(block.difficulty, now, players)));
  }

  function pickWinner() public restricted {
    uint index = random() % players.length;

    players[index].transfer(address(this).balance);

    players = new address[](0);
  }

  function getPlayers() public view returns (address[]) {
    return players;
  }

  modifier restricted() {
    require(msg.sender == manager);
    _;
  }
}