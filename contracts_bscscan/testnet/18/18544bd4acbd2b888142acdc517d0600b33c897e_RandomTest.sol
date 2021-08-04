/**
 *Submitted for verification at BscScan.com on 2021-08-04
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

contract RandomTest {
    function randomGen(
        address sender,
        uint256 seed,
        uint256 max
    ) external view returns (uint256 randomNumber) {
        return (uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, sender, block.difficulty, seed))
        ) % max);
    }
}