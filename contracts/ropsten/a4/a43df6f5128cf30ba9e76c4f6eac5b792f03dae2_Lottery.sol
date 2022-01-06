/**
 *Submitted for verification at Etherscan.io on 2022-01-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract Lottery {
    address public manager;
    address[] public players;

    constructor() {
        manager = msg.sender;
    }

    modifier restricted() {
        require(msg.sender == manager, "Not allowed");
        _;
    }

    function enter() public payable {
        require(msg.value > 0.001 ether, "Not enough Wei sent");

        players.push(msg.sender);
    }

    function random() private view returns (uint) {
        return uint(keccak256(abi.encode(block.difficulty, block.timestamp, players)));
    }

    function pickWinner() public restricted {
        uint index = random() % players.length;
        payable (players[index]).transfer(address(this).balance);

        // Reset players array, with initial size of 0
        players = new address payable[](0);
    }

    function getPlayers() public view returns (address[] memory) {
        return players;
    }
}