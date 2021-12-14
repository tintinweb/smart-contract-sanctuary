/**
 *Submitted for verification at Etherscan.io on 2021-12-14
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

    function getWinner() public view returns (address){
        return winner;
    }

    function getPlayers() public view returns (address[] memory) {
        return players;
    }

    function enter() public payable {
        require(msg.value > 0.001 ether);
        require(players.length < MAX_PLAYERS);

        players.push(msg.sender);

        if (players.length == 3){
            pickWinner();
        }
    }

    function pickWinner() private {
        uint index = random() % players.length;
        winner = players[index];
        payable(players[index]).transfer(address(this).balance);
    }

    function random() private view returns  (uint) {
        return uint(keccak256(abi.encodePacked(block.number, block.timestamp, players)));
    }

}