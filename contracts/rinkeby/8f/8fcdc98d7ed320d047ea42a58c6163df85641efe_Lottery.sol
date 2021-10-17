/**
 *Submitted for verification at Etherscan.io on 2021-10-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Lottery {
    address public manager;
    address payable[] public players;
    
    constructor(){
        manager = msg.sender;
    }
    
    // pay amount of money to participate in Lottery
    function enter() public payable {
        
        require(msg.value>0.01 ether,"Please send minimum 0.01 ether");
        players.push(payable(msg.sender));
        
    }
    
    // RANDOM NUMBER GENERATE
    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }
    
    // Pick a random winner
    function pickWinner() public restricted {
        
        require(players.length > 0,"No players found");
        
        uint index = random() % players.length;
        players[index].transfer(address(this).balance);
        players = new address payable[](0);
    }    
    
    
    function getPlayes() public view returns (address payable[] memory){
        return players;
    }
    
    modifier restricted() {
        require(msg.sender == manager,"Only manager can access");
        _;
    }
}