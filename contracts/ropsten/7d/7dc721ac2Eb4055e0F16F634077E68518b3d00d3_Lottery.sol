// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Lottery {
    address public manager;
    address[] public players;

    constructor() {
        manager = msg.sender;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "Only avaible for manager");
        _;
    }

    function enter() public payable {
        require(msg.value >= .01 ether);
        players.push(msg.sender);
    }

    function pickWinner() public payable onlyManager {
        uint256 index = random() % players.length;
        uint256 balance = address(this).balance;
        payable(players[index]).transfer(balance);
        players = new address[](0);
    }

    function random() private view returns (uint256) {
        bytes32 pack = keccak256(
            abi.encodePacked(block.difficulty, block.timestamp, players)
        );
        return uint256(pack);
    }

    function getPlayers() public view returns (address[] memory) {
        return players;
    }
}