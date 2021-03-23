/**
 *Submitted for verification at Etherscan.io on 2021-03-23
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

contract Lottery {
    address public manager;
    address payable[] public players;

    constructor() public {
        manager = msg.sender;
    }

    function enter() public payable {
        require(
            msg.value > .01 ether,
            "A minimum payment of .01 ether must be sent to enter the lottery"
        );

        players.push(msg.sender);
    }

    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.number, players)));
    }

    function pickWinner() public onlyOwner {
        uint index = random() % players.length;
        address contractAddress = address(this);
        players[index].transfer(contractAddress.balance);
        players = new address payable[](0);
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    modifier onlyOwner() {
        require(
            msg.sender == manager,
            "Only owner can call this function."
        );
        _;
    }
}