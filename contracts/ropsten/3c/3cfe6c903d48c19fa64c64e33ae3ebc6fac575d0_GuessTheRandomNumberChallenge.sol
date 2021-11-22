/**
 *Submitted for verification at Etherscan.io on 2021-11-22
*/

/**
 *Submitted for verification at Etherscan.io on 2021-07-30
*/

pragma solidity ^0.4.21;

contract GuessTheRandomNumberChallenge {
    uint8 answer;
    bytes32 hashAll;
    uint time;
    uint blockNum;

    constructor() {
        answer = uint8(keccak256(block.blockhash(block.number - 1), now));
        hashAll = keccak256(block.blockhash(block.number - 1), now);
        time = now;
        blockNum = block.number -1;
    }

    function guess(uint8 n) public returns (bool) {
        return (n == answer);
    }
}