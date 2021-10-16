/**
 *Submitted for verification at Etherscan.io on 2021-10-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Random {
    function toKeccak256(string memory input) public pure returns(uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function randNum(uint256 seed, uint256 length) public view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(seed, block.difficulty, block.timestamp))) % length;
    }

    function toHash(address sender, string memory secret) public pure returns(uint256) {
        return uint256(keccak256(abi.encodePacked(sender, secret)));
    }
}