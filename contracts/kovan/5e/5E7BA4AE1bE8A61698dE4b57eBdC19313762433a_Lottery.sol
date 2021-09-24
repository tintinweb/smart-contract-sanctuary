/**
 *Submitted for verification at Etherscan.io on 2021-09-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract Lottery {
    address public manager;
    address payable[] public players;

    constructor() {
        manager = msg.sender;
    }
    
    function enter() public payable {
        require(msg.value >= .01 ether);
        players.push(payable(msg.sender));
    }
    
    function pickWinner() public restricted {
        uint indexOfWinner = random() % players.length;
        address payable winner = payable(players[indexOfWinner]);
        winner.transfer(address(this).balance);
        players = new address payable[](0);
    } 
    
    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }
    
    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }
    
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
}