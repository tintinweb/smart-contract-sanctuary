/**
 *Submitted for verification at Etherscan.io on 2022-01-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract NumberGuessingGame {
    uint8 private answer;
    address public winner;
    address public owner;
    uint public jackpot = address(this).balance;
    uint count = 0;
    bool isGameOn = true;

    constructor(uint8 number) payable {
        require(
            0 < number && number <= 10,
            "Number provided should be between 1 - 10"
        );
        require(
            msg.value == 30 ether,
            "30 ether initial funding required for reward"
        );

        answer = number;

        owner = msg.sender;
    }

    function guess(uint8 number) payable public{
        jackpot = address(this).balance;

        require(
            0 < number && number <= 10,
            "Number provided should be between 1 - 10"
        );
        require(
            isGameOn == true,
            "the game is over!"
        );

        require(
            msg.value == 1 ether,
            "You have to pay 1ETH to play the game"
        );

        require(
            msg.sender != owner,
            "You are the owner, you are not allowed to play!"
        );

        count += 1;

        if(number == answer){
            winner = msg.sender;
            payable(winner).transfer(jackpot);
            isGameOn == false;
        }
        if(count == 5){
            payable(owner).transfer(jackpot);
            isGameOn == false;
        }
    }
}