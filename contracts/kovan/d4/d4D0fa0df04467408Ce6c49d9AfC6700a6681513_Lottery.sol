/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Lottery{
    address manager;
    address payable[] players;
    constructor(){
        manager = msg.sender;
    }
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
    function buyLottery() public payable {
        require(msg.value == 0.2 ether,"Plaese But Lottery 0.2 ETH");
        players.push(payable(msg.sender));
    }
    function getLength() public view returns(uint){
        return players.length;
    }
    function randomNumber() public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,players.length)));
    }
    function selectWinner() public{
        require(msg.sender == manager,"Anauthorrized");
        require(players.length >= 2,"less then 2 players");
        uint pickerRandom = randomNumber();
        address payable winner;
        uint selectPlayer = pickerRandom % players.length;
        winner = players[selectPlayer];
        winner.transfer(getBalance());
        players = new address payable[](0);
    }
}