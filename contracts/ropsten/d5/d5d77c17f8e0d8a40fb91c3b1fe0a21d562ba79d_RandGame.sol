/**
 *Submitted for verification at Etherscan.io on 2021-09-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract RandGame {
    
    address owner;
    address public winner = address(0);
    
    address[] players;
    
    constructor() {
        owner = msg.sender;
    }
    
    function buyIn() public payable {
        require(msg.value == 0.01 ether);
        players.push(msg.sender);
    }
    
    function announceWinner() public {
        require(msg.sender == owner, "Only owner can finish the game");
        require(winner == address(0));
        
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp)));

        winner = players[randomNumber % players.length];
    }
    
    function withdraw() external payable {
        require(msg.sender == winner);
        //address payable winnerAddress = payable(winner);
        payable(winner).transfer(msg.value);
    }
    
}