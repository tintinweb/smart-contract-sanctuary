/**
 *Submitted for verification at polygonscan.com on 2021-12-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Lottery {

  address public manager;

  address[] public players;
  uint[] public tickets;

  constructor(){
    manager = msg.sender;
  }

  function enter() public payable {
    require(msg.value > .01 ether);
    //require(ticket> 1 ether);
    players.push(msg.sender);
  }

  function getBalance() public view returns (uint) {
    return address(this).balance;
  }

  function getManagerBalance() public view returns (uint) {
    return manager.balance;
  }

  function transferBalance() public {
    payable(manager).transfer(address(this).balance);
  }



  function random() public view returns (uint) {
    return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,players)));
  }

  function addTicket() public {
    tickets.push(random());
  }

  function pickWinner() public restricted {
    uint index=random() % players.length;
    payable(players[index]).transfer(address(this).balance); //0x23423423asdf234234
    players = new address[](0);
  }

  modifier restricted(){
    require(msg.sender==manager);
    _;
  }

  function getPlayers() public restricted view returns(address[] memory){
    return players;
  }

  function getTickets() public restricted view returns(uint[] memory){
    return tickets;
  }







}