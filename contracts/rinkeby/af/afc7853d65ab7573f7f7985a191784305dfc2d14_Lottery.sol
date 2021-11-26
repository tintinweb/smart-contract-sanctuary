/**
 *Submitted for verification at Etherscan.io on 2021-11-26
*/

pragma solidity ^0.4.21;
 
contract Lottery {
   address public manager;
   address public winner;
   address[] public players;
 
   constructor() public {
       manager = msg.sender;
   }
 
   function random() private view returns (uint) {
       return uint(keccak256(abi.encodePacked(block.difficulty, now, players)));
   }
 
   function pickWinner() private {
       uint index = random() % players.length;
 
       winner = players[index];
       players[index].transfer(address(this).balance);
   }
 
   function enter() public payable {
       require(msg.value > .001 ether);
       require(players.length < 3); 
 
       players.push(msg.sender);
 
       if (players.length == 3) {
           pickWinner();
       }
   }
 
   function getPlayers() public view returns (address[]) {
       return players;
   }
 
   function getWinner() public view returns (address) {
       return winner;
   }
}