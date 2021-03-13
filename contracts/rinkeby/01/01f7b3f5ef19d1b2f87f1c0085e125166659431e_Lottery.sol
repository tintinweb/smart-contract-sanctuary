/**
 *Submitted for verification at Etherscan.io on 2021-03-12
*/

//"SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.4.17;
contract Lottery {
    
    address public owner;
    address[] public players;
    
    function Lottery() public {
        owner = msg.sender;
    }
    
    function join() public payable {
        require(msg.value >= .01 ether);
        players.push(msg.sender);
    }

    function getRandom() private view returns (uint) {
        return uint(keccak256(block.difficulty, now, players));
    }
    
    function pickWinner() public restrictedToOwner {
        require(players.length > 0);
        uint winnerIndex = getRandom() % players.length;
        players[winnerIndex].transfer(this.balance);
        players = new address[](0);
    }
    
    function getPlayers() public view returns(address[] memory) {
        return players;
    }
    
    modifier restrictedToOwner() {
        require(msg.sender == owner);
        _;
    }
}