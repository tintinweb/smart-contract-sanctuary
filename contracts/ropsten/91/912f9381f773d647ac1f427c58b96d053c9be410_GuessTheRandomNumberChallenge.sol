/**
 *Submitted for verification at Etherscan.io on 2021-11-22
*/

/**
 *Submitted for verification at Etherscan.io on 2021-07-30
*/

pragma solidity ^0.4.21;

contract GuessTheRandomNumberChallenge {
    uint8 public answer;

    constructor() {
        answer = uint8(keccak256(block.blockhash(11474593), 1637585939));
    }
}