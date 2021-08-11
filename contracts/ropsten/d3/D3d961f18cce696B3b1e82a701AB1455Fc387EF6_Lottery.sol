/**
 *Submitted for verification at Etherscan.io on 2021-08-10
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

contract Lottery {
    address public manager;
    address[] public players;

function lottery1() public {
    manager = msg.sender;
}

function enter() public payable {
    require(msg.value > 0.1 ether, '402: not enough');

    players.push(msg.sender);
}

function getPlayers() public view returns(address[] memory) {
    return players;
}

function random() private view returns(uint) {
    return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
}

function pickWinner() public managerUser {

  if (players.length > 0) {
    uint index = random() % players.length;

    address payable winner = payable(players[index]);

    winner.transfer(address(this).balance);

    players = new address[](0);
  }
}

modifier managerUser() {
    require(msg.sender == manager);
    _;
}
}