/**
 *Submitted for verification at BscScan.com on 2021-08-10
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;


contract SimpleRNG {

    event RandomEmitted(string message, uint random);

    /**
     * Message can specify the purpose of the random value if desired.
     */
    function getRandom(string calldata message, uint max) external {
        emit RandomEmitted(message, uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp))) % max);
    }
}