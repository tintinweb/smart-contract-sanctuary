/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

//SPDX-License-Identifier:MIT License
pragma solidity ^0.8.0;

contract WitchRaffle{
  address public manager;
  address payable[] public players;

  constructor() public {
    manager = msg.sender;
  }

  function enter(uint ticketNumber) public payable {
    require(msg.value > ((ticketNumber*1) * 10 **16));
    for(uint256 i=0;i<ticketNumber;i++){
      players.push(payable(msg.sender));
    }
  }

  function random() private view returns (uint) {
    return uint(keccak256(abi.encodePacked(block.difficulty, players)));
  }

  function pickWinner() public restricted {
    uint index = random() % players.length;

    players[index].transfer(address(this).balance);

    players = new address payable[](0);
  }

  function getPlayers() public view  returns (address payable[] memory) {
    return players;
  }
  function getNumberofTickets() public view returns (uint256) {
    return players.length;
  }
  function getAccountBalance() public view returns (uint256) {
    return address(this).balance;
  }
  modifier restricted() {
    require(msg.sender == manager);
    _;
  }
}