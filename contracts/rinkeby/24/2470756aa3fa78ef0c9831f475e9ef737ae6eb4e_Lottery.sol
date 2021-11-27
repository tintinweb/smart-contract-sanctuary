/**
 *Submitted for verification at Etherscan.io on 2021-11-27
*/

/**
 *Submitted for verification at Etherscan.io on 2021-11-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; 

contract Lottery { 
    uint MAX_PLAYERS = 3;
    address manager; 
    address winner; 
    address[] players;

    constructor() { 
        manager = msg.sender;
    }

    function getPlayers() public view returns (address[] memory) {
        return players;
    }

    function getWinner() public view returns (address) {
        return winner; 
    }

    function enter() public payable {
        require(msg.value > .001 ether);
        require(players.length < MAX_PLAYERS);

        players.push(msg.sender);

        if (players.length == MAX_PLAYERS) {
            pickWinner();
        }
    }

    function pickWinner() private {
        uint index = random() % players.length; 
        winner = players[index];
        payable(players[index]).transfer(address(this).balance);
    }

    function random() private view returns (uint) {
       return uint(keccak256(abi.encodePacked(block.number, block.timestamp, players)));
    }
}