// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

contract RandomStub {
    // stub the core RNG service function
    function returnValue() external view returns (bytes32){
        return keccak256(abi.encodePacked(
            block.number,
            block.coinbase,
            block.difficulty,
            blockhash(block.number - 1),
            tx.origin
        ));
    }
}