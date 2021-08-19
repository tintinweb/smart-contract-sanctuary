/**
 *Submitted for verification at Etherscan.io on 2021-08-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

contract MerkleTree {
    bytes32[] public hashes;

    constructor(
        uint256[] memory index,
        address[] memory account,
        uint256[] memory amount
    ) {
        for (uint256 i = 0; i < index.length; i++) {
            bytes32 node = keccak256(
                abi.encodePacked(index[i], account[i], amount[i])
            );
            hashes.push(node);
        }

        uint256 n = index.length;
        uint256 offset = 0;

        while (n > 0) {
            for (uint256 i = 0; i < n - 1; i += 2) {
                hashes.push(
                    keccak256(
                        abi.encodePacked(
                            hashes[offset + i],
                            hashes[offset + i + 1]
                        )
                    )
                );
            }
            offset += n;
            n = n / 2;
        }
    }

    function getRoot() public view returns (bytes32) {
        return hashes[hashes.length - 1];
    }
}