/**
 *Submitted for verification at Etherscan.io on 2021-09-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

contract Lottery {

    address public manager;
    address[] public players;

    uint public playersCount;

    constructor() {
        manager = msg.sender;
        playersCount = 0;
    }

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    function enter() public payable {
        require(msg.value > 0.01 ether);

        players.push(msg.sender);
        playersCount = playersCount + 1;
    }

    function pickWinner() public restricted payable {
        require(players.length > 0);

        uint index = random() % players.length;

        payable(players[index]).transfer(address(this).balance);

        players = new address[](0);
        playersCount = 0;
    }

    function random() private view returns(uint) {
        return uint(
            keccak256(
                abi.encodePacked(block.difficulty, block.timestamp, players)
            )
        );
    }

    function getPlayers() public view returns(address[] memory) {
        return players;
    }
}