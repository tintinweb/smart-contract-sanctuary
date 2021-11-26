/**
 *Submitted for verification at Etherscan.io on 2021-11-26
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Guess {
    address public owner;
    uint private answer;
    uint private randNonce;

    event GuessChecked(address guesser, uint guess, string reply);

    constructor() {
        answer = 50;
        owner = msg.sender;
    }

    function newAnswer() internal {
        answer = randMod(100);
    }

    function randMod(uint _modulus) internal returns(uint) {
        randNonce++;
        return uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % _modulus;
    }

    function guess(uint _guess) public returns (string memory) {
        if (_guess > answer) {
            emit GuessChecked(msg.sender, _guess, "Lower");
            return "Lower";
        }

        if (_guess < answer) {
            emit GuessChecked(msg.sender, _guess, "Higher");
            return "Higher";
        }

        emit GuessChecked(msg.sender, _guess, "Correct");

        newAnswer();
        return "Correct";
    }

    function setAnswer(uint _answer) public {
        require(owner == msg.sender, "Only owner can set answer");
        answer = _answer;
    }

    function getAnswer() public view returns(uint) {
        require(owner == msg.sender, "Only owner can get answer");
        return answer;
    }
}