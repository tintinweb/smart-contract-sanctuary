/**
 *Submitted for verification at Etherscan.io on 2021-11-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Lottery {
    address public owner;
    address public winner = address(0);
    
    uint256 ticketPrice = 0.1 ether;
    
    address[] participants;
    
    constructor() {
        owner = msg.sender;
    }
    
    function purchaseTicket() public payable {
        require(msg.value >= ticketPrice);
        require(msg.sender != owner);
        require(winner == address(0));
        
        participants.push(msg.sender);
    }
    
    function announceWinner() external {
        require(msg.sender == owner);
        require(winner == address(0));
        require(participants.length > 2);
        
        uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, participants)));
        uint256 winnerIndex = rand % participants.length;
        
        winner = participants[winnerIndex];
    }
    
    function withdraw() public payable {
        require(winner == msg.sender);
        
        payable(winner).transfer(address(this).balance);
    }
}