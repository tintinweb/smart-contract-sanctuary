/**
 *Submitted for verification at Etherscan.io on 2021-04-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

contract Lottery {
    address public manager;
    address [] public players;

    constructor ()  {
        manager = msg.sender;
    }

    function enter() public payable {
        require(msg.value > .001 ether); // if in wei, the number is too big

        players.push(msg.sender);
    }
    // pseudo random
    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }

    function pickWinner() public restricted {
        uint index = random() % players.length; // % returns the remainder which is always less than players.leng 
        payable(players[index]).transfer( address(this).balance); // address.transfer() behave like receive by this address
        players = new address[](0);                               // `this` refers to current contract instance
    }

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    function getPlayers() public view returns (address[] memory) {
        return players;
    }
}