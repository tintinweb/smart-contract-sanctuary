/**
 *Submitted for verification at polygonscan.com on 2022-01-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Random {
    function canSteal(uint256, uint256) public view returns (bool) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.difficulty +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / (block.timestamp)) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                            (block.timestamp)) +
                        block.number
                )
            )
        );

        return ((seed % 100) + 1) <= 10 ? true : false;
    }

    function getMonsterId(
        uint256[] memory _tokenIds,
        uint256,
        uint256
    ) public view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.difficulty +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / (block.timestamp)) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                            (block.timestamp)) +
                        block.number
                )
            )
        );

        return (seed % _tokenIds.length);
    }
}