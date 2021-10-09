/**
 *Submitted for verification at Etherscan.io on 2021-10-08
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity > 0.8.0 < 0.9.0;

contract Lottery {

    address public owner;
    address payable[] public players;

    constructor() {
        owner = msg.sender;
    }

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    function enter() public payable {
        require(msg.value >= 0.01 ether);

        players.push(payable(msg.sender));
    }

    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }

    function pickWinner() public isOwner {
        uint index = random() % players.length;
        players[index].transfer(address(this).balance);

        players = new address payable[](0);
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }
}