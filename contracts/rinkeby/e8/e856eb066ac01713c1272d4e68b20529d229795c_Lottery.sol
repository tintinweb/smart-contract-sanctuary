/**
 *Submitted for verification at Etherscan.io on 2021-07-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Lottery {
    address public manager;
    address payable[] public players;

    constructor() {
        manager = msg.sender;
    }

    function enter() public payable {
        require(
            msg.value >= 0.01 ether,
            "A minimum payment of .01 ether must be sent to enter the lottery"
        );
        players.push(payable(msg.sender));
    }

    function pickWinder() public onlyOwner {
        if (players.length == 0) {
            return;
        }

        address payable winner = players[random() % players.length];
        address contractAddress = address(this);
        winner.transfer(contractAddress.balance);
        players = new address payable[](0);
    }

    function getEntries() public view returns (address payable[] memory) {
        return players;
    }

    function random() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.difficulty, block.timestamp, players)
                )
            );
    }

    modifier onlyOwner() {
        require(msg.sender == manager, "Only owner can call this function");
        _;
    }
}