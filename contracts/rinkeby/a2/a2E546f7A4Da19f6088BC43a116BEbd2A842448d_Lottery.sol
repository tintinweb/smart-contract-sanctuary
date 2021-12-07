/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

contract Lottery {

// variables
address public manager;
address payable public lastWinner;
address payable[] public players;

constructor() {
    manager = msg.sender;
}

function enter() public payable {
    require(msg.value > .0001 ether);
    // msg.sender is not inherently payable in solc 0.8 
    players.push(payable(msg.sender));
}

// sudo random number generator
function random() public view returns (uint) {
    // keccak256 are global functions. they are the sha algorithms
    // turns hash (given from kaccak) and turns it into an unsigned integer.
    // only kaccak256 only accepts one argument, so we encode all the arguments into one and pass that in. 
    return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
}

function pickWinner() public restricted {
    uint index = random() % players.length;
    // transfer is a function available on every address that we store inside of solidity. 
    players[index].transfer(address(this).balance);
    lastWinner = players[index];

    players = new address payable[](0);
}

modifier restricted() {
    require(msg.sender == manager);
    _;
}

function getPlayers() public view returns(address payable[] memory) {
    return players;
}
}