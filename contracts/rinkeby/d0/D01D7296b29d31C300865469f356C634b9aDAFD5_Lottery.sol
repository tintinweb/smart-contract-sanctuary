/**
 *Submitted for verification at Etherscan.io on 2022-01-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Lottery {
    address public manager;
    address[] public players;

    constructor () {
        // Using global variable msg object to get the address of the sender
        // i.e., manager is by default the one who creates the contract
        manager = msg.sender;
    }

    // Strings are stored as dynamic arrays, i.e., arrays with variable lemgth
    // So, an array of strings would be like a nested dynamic array
    // Nested dynamic arrays, although cause no problems in solidity, they do cause problem
    // in JS due to the ABI issues, so we should not be using them directly

    // Payable as in anyone who calls this function will send some ether along
    function enter() public payable {
        // Prerequisite for players to send atleast 0.01 ether
        require(msg.value > 0.01 ether, "Insufficient funds to enter");

        players.push(msg.sender);
    }

    function random() private view returns (uint) {
        // Psuedo random number generator function as all this values can be known previously
        // Using builtin keccak256/sha256 hashing and encode its parameters using the minimal space required by the type. 
        // block is a builtin object to get info about the current block
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }

    function pickWinner() public restricted {
        // restricted modifier called
        uint index = random() % players.length;
        // Getting the balance present in contract's address and transfering all the amount to the winning index
        payable(players[index]).transfer(address(this).balance);
        // Resetting the array for new round of lottery
        players = new address[](0);
    }
    
    modifier restricted() {
        // To avoid repetition of code, we can add modifiers in function declaration
        require(msg.sender == manager);
        // _ replaces function code block for which the modifier is called
        _;
    }

    function getPlayers() public view returns (address[] memory) {
        // function to show all elements of array at once 
        return players;
    }
}