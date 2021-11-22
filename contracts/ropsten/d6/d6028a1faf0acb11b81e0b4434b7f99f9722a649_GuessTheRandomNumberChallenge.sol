/**
 *Submitted for verification at Etherscan.io on 2021-11-22
*/

pragma solidity ^0.4.21;

contract GuessTheRandomNumberChallenge {
    uint8 public answer;
    bytes32 public hashAll;
    bytes32 public blockHash;
    uint public time;
    uint public blockNum;

    function GuessTheRandomNumberChallenge() {
        answer = uint8(keccak256(block.blockhash(block.number - 1), now));
        hashAll = keccak256(block.blockhash(block.number - 1), now);
        blockHash = block.blockhash(block.number - 1);
        time = now;
        blockNum = block.number - 1;
    }

    function guess(uint8 n) public view returns (bool) {
        return (n == answer);
    }
}