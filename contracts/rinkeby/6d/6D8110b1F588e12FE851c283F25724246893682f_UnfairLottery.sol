/**
 *Submitted for verification at Etherscan.io on 2021-10-31
*/

//UnfairLottery - Alejandro Ramirez Rodriguez

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract UnfairLottery {

    address public manager;
    address[] public players;
    address winner;

    constructor(){
        manager = msg.sender;    
    }

    //only allow manager to trigger the pick
    modifier isManager(){
        require(msg.sender == manager);
        _;
    }

    function enter() public payable{
        require(msg.value >= .01 ether);
        players.push(msg.sender);
    }

    function pickWinner() public isManager{
        winner = players[random() % players.length];
        payable(winner).transfer(address(this).balance);
        players = new address[](0);
    }

    function random() private view returns (uint){
        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,players)));
    }

    function getPlayers() public view returns (address[] memory){
        return players;
    }
}