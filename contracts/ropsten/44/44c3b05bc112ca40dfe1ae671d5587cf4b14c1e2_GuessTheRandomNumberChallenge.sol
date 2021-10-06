/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

pragma solidity ^0.4.21;

contract GuessTheRandomNumberChallenge {

    uint block_number;
    uint block_number_previous;
    bytes32 block_previous_hash;
    uint block_now;
    bytes32 keccak;
    uint8 answer;

    function GuessTheRandomNumberChallenge() public payable {
        block_number = block.number; 
        block_number_previous = block_number - 1;
        block_previous_hash = block.blockhash(block_number_previous);
        block_now = now;
        keccak = keccak256(block_previous_hash, block_now);
        answer = uint8(keccak);
    }

    function Block_Number() view public returns(uint) {
        return block_number; 
    }

    function Block_Number_Previous() view public returns(uint) {
        return block_number_previous;
    }

    function Block_Previous_Hash() view public returns(bytes32) {
        return block_previous_hash;
    }

    function Block_Now() view public returns(uint) {
        return block_now;
    }

    function Keccak() view public returns(bytes32) {
        return keccak;
    }

    function Answer() view public returns(uint8) {
        return answer;
    }
}