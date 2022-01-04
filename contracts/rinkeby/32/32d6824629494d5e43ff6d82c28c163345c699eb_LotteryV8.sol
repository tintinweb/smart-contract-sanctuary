/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

contract LotteryV8 {
    //global variables
    address payable[] public players;
    address payable public manager;

    constructor() {
        manager = payable(msg.sender);
    }

    function enterIntoLottery() public payable {
        require(msg.value > 0.01 ether);
        players.push(payable(msg.sender));
    }

    function pseudoRandom() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.difficulty, block.timestamp, players)
                )
            );
    }

    function pickWinner() public restricted {
        uint256 index = pseudoRandom() % players.length;
        payable(players[index]).transfer(address(this).balance);
        players = new address payable[](0);
    }

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }
}