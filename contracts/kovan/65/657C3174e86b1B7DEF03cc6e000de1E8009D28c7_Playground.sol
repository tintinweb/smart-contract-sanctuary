/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Playground {
    
    address public manager;
    address[] public players;


    constructor() {
    manager = msg.sender;
    }
    
    function enter() public payable {
        require(msg.value > .01 ether);
        players.push(msg.sender);
    }
    
    function random() public view returns (uint){
       return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }
    
    function pickWinner() public restricted payable {
        uint index = random() % players.length;
        address addr = players[index];
        address payable Player = payable(addr);
        Player.transfer(address(this).balance);
        players = new address[](0);
    }
    
    function getPlayers() public view returns(address[] memory){
    return players;    
    }
    
    modifier restricted(){
        require(msg.sender == manager);
        _;
    }
    
}