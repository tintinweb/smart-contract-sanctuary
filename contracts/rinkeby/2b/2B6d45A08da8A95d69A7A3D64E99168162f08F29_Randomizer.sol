// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Randomizer {

    /**
    * generates a pseudorandom number for picking traits. Uses point in time randomization to prevent abuse.
    */
    function random(uint256 seed, uint64 timestamp, uint64 blockNumber) external view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            tx.origin,
            blockhash(blockNumber > 1 ? blockNumber - 2 : blockNumber),// Different block than DefpunkMain to ensure if needing to re-randomize that it goes down a different path
            timestamp,
            seed
        )));
    }

}