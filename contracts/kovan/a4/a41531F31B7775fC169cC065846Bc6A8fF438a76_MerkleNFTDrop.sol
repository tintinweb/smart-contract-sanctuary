// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./IAlEthNFT.sol";

contract MerkleNFTDrop {

    IAlEthNFT public alEthNFT;
    bytes32 public merkleRoot;

    constructor(address _alEthNFT, bytes32 _merkleRoot) {
        alEthNFT = IAlEthNFT(_alEthNFT);
        merkleRoot = _merkleRoot;
    }

    function claim(uint256 _tokenId, uint256 _tokenData, address _receiver, bytes32[] calldata _proof) external {
        bytes32 leaf = keccak256(abi.encodePacked(_tokenId, _tokenData, _receiver));
        require(MerkleProof.verify(_proof, merkleRoot, leaf), "MerkleNFTDrop.claim: Proof invalid");
        // Mint NFT
        alEthNFT.mint(_tokenId, _tokenData, _receiver);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IAlEthNFT {
    function mint(uint256 _tokenId, uint256 _tokenData, address _receiver) external;
    function tokenData(uint256 _tokenId) external view returns (uint256);
}

