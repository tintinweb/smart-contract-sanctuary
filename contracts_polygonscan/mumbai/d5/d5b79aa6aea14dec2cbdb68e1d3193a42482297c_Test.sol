/**
 *Submitted for verification at polygonscan.com on 2022-01-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity = 0.8.7;

contract Test {
    uint public blockNumber;
    bytes32 public blockHashNow;
    bytes32 public blockHashPrevious;

    function setValues() public {
        blockNumber = block.number;
        blockHashNow = blockhash(blockNumber);
        blockHashPrevious = blockhash(blockNumber - 1);
    }    
}