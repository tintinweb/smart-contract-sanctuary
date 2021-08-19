/**
 *Submitted for verification at Etherscan.io on 2021-08-18
*/

pragma solidity ^0.4.21;

contract GuessTheRandomNumberChallenge {
    function answer() public view returns (uint8) {
        return uint8(keccak256(block.blockhash(block.number - 1), now));
    }
}