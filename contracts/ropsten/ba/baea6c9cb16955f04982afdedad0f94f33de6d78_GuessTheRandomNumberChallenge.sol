/**
 *Submitted for verification at Etherscan.io on 2021-11-22
*/

/**
 *Submitted for verification at Etherscan.io on 2021-07-30
*/

pragma solidity ^0.4.21;

contract GuessTheRandomNumberChallenge {
    uint8 public answer;
    uint8 public answer2;
    bytes32 public hash2;
    
    /*0x9343e672bb7c2214aeceb80debd53844871a73f63e32937ab3e85d5fb9291741*/

    constructor() {
        answer = uint8(keccak256(block.blockhash(11474594 - 1), 1637585939));
        answer2 = uint8(keccak256(block.blockhash(11474886), 1637591211));
        hash2 = keccak256(block.blockhash(11474886), 1637591211);
    }
}