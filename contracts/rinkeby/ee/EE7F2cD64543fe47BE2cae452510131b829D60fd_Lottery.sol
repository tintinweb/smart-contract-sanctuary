/**
 *Submitted for verification at Etherscan.io on 2021-07-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Lottery {
   
    address public owner;
    address[] public players;
    
    modifier restricted() {
        require(msg.sender == owner);
        _;
    }
   
    constructor() {
        owner = msg.sender;
    }
    
    function getNumberOfPlayers() public view returns (uint) {
        return players.length;
    }
    
    function pseudoRandom() private view returns (uint) {
        uint source = block.difficulty + block.timestamp + players.length;
        bytes memory source_b = toBytes(source);
        return uint(keccak256(source_b));
    }

    function toBytes(uint256 x) private pure returns (bytes memory b) {
        b = new bytes(32);
        assembly { mstore(add(b, 32), x) }
    }
    
    function enter() public payable {
        require(msg.value == .001 ether);
        players.push(msg.sender);
    }
    
    function pickWinner() public restricted {
        uint winnerIndex = pseudoRandom() % players.length;
        payable(players[winnerIndex]).transfer(address(this).balance);
        players = new address[](0);
    }
}