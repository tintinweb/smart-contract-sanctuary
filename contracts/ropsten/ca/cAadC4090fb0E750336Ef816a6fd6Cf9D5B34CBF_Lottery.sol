/**
 *Submitted for verification at Etherscan.io on 2021-04-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

contract Lottery {

    string public authorName;

    address public manager;

    address payable public lastWinner;

    address[] public players;

    constructor(){
        authorName = 'g14';
        manager = msg.sender;
    }

    function enter() public payable {
        require(msg.value >= 1 ether, "Insufficient ETH. Entry costs 1 ETH");
        players.push(msg.sender);
    }

    function pickWinner() public returns (address) {
        require(msg.sender == manager);
        uint winnerIndex = random() % players.length;
        lastWinner = payable(players[winnerIndex]);
        lastWinner.transfer(address(this).balance);
        players = new address[](0);
        return lastWinner;
    }

    function getPlayers() public view returns (address[] memory) {
        return players;
    }

    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }

}