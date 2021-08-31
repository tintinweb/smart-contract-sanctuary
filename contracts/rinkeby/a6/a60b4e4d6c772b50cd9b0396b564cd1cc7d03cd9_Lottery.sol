/**
 *Submitted for verification at Etherscan.io on 2021-08-31
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract Lottery
{
    address public manager;
    
    address[] public players;
    
    constructor()
    {
        manager = msg.sender;
    }
    
    modifier onlyOwner()
    {
        require(msg.sender == manager, "Must be called by the owner!");
        _;
    }
    
    function enter() public payable
    {
        require(msg.value > .01 ether, "Not sufficient funds!");
        
        players.push(msg.sender);
    }
    
    function pickWinner() public onlyOwner
    {
        uint256 winnerIndex = random() % players.length;
        
        (bool sentResult, ) = payable(players[winnerIndex]).call{value: address(this).balance}("");
        require(sentResult, "Couldn't send ether to the winner!");
        
        players = new address[](0);
    }
    
    function getPlayers() public view returns (address[] memory)
    {
        return players;
    }
    
    function random() private view returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }
}