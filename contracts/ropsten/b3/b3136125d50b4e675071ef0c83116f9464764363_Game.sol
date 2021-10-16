/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.0 < 0.9.0;

contract Game {
    
    address private player;
    address private owner;
    bool private playing = false;
    uint reward;
    uint randomNumer;
    
    uint private constant cost = 200000000000000000;
  
    event Numbers(string, uint _randomNumber, string, uint discoveredNumber, string, uint reward);
    
    constructor() public payable {
        require(msg.value >= 1000000000000000000, "at least 0.1 ether is required");
        owner = msg.sender;
    }
    
    function discover(uint discoveredNumber) public payable {
        require(msg.value == 200000000000000000, "the cost of the game is 0.2 ether");
        require(!playing, "there is currently someone playing, please wait a moment");
        
        uint _randomNumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 10 + 1;
        
        if (discoveredNumber == _randomNumber) {
            player = msg.sender;
            reward = 1000000000000000000;
        }
        
        emit Numbers("number generated was: ", _randomNumber, " you chose ", discoveredNumber, " you win ", reward);
    }
}