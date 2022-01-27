/**
 *Submitted for verification at Etherscan.io on 2022-01-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Lottery {
    address public manager;
    address payable[] public participants;

    constructor() {
        manager = msg.sender;
    }

    receive() external payable {
        require(msg.value >= .1 ether);
        participants.push(payable(msg.sender));
    }

    function getBalance() view public returns(uint) {
        require(msg.sender == manager);
        return address(this).balance;
    }

    function random() view public returns(uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,participants.length)));
    }

    function selectWinner() public {
        require(msg.sender == manager);
        require(participants.length >= 3);
        address payable winner;
        uint index = random() % participants.length;
        winner = participants[index];
        winner.transfer(getBalance());
        participants = new address payable[](0);
    }
}