/**
 *Submitted for verification at Etherscan.io on 2021-07-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Lottery {
    
    address public manager;
    address[] public players;
    
    constructor ()  {
        manager = msg.sender;
    }
    
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
    
    function enter() public payable {
        require(msg.value > .01 ether);
        players.push(msg.sender);
    }
    
    function random() private view returns (uint256) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }
    
    function pickWinner() public restricted {
        uint index = random() % players.length;
        address payable winner = payable(players[index]);
        winner.transfer(address(this).balance);
        players = new address[](0);
    }
    
    function getPlayers() public view returns (address[] memory) {
        return players;
    }
}