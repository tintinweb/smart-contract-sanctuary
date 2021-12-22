/**
 *Submitted for verification at Etherscan.io on 2021-12-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract Lottery {
    address public manager;
    address[] public players;
    address public lastWinner;
    
    constructor() {
        manager = msg.sender;
    }

    // function modifier to remove reusablity of code
    modifier restricted() {
        require(msg.sender == manager);
        _; // here rest of function code comes to execute
    } 

    function enter() public payable {
        require(msg.value > .01 ether); // require - if check

        players.push(msg.sender);
    }

    function allPlayers() public view returns (address[] memory) {
        return players;
    }

    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,players)));
    }

    function pickWinner() public restricted {
        uint index = random() % players.length;
        payable(players[index]).transfer(address(this).balance); // balance - current balance in contract
        lastWinner = players[index];
        players = new address[](0); // 0 - num of initial addresses in array
    }
}