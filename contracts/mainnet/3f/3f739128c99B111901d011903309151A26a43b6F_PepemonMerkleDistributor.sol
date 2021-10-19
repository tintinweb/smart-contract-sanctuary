// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface IPepemonFactory {
    function mint(
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data
    ) external;
}

contract PepemonMerkleDistributor {
    event Claimed(
        uint256 tokenId,
        uint256 index,
        address account,
        uint256 amount
    );

    IPepemonFactory public factory;
    mapping(uint256 => bytes32) merkleRoots;
    mapping(uint256 => mapping(uint256 => uint256)) private claimedTokens;

    // @dev do not use 0 for tokenId
    constructor(
        address pepemonFactory_,
        bytes32[] memory merkleRoots_,
        uint256[] memory pepemonIds_
    ) {
        require(pepemonFactory_ != address(0), "ZeroFactoryAddress");
        require(
            merkleRoots_.length == pepemonIds_.length,
            "RootsIdsCountMismatch"
        );

        factory = IPepemonFactory(pepemonFactory_);

        for (uint256 r = 0; r < merkleRoots_.length; r++) {
            merkleRoots[pepemonIds_[r]] = merkleRoots_[r];
        }
    }

    function isClaimed(uint256 pepemonTokenId, uint256 index)
        public
        view
        returns (bool)
    {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedTokens[pepemonTokenId][claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function claim(
        uint256 tokenId,
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external {
        require(merkleRoots[tokenId] != 0, "UnknownTokenId");
        require(
            !isClaimed(tokenId, index),
            "MerkleDistributor: Drop already claimed"
        );

        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(
            MerkleProof.verify(merkleProof, merkleRoots[tokenId], node),
            "MerkleDistributor: Invalid proof"
        );

        _setClaimed(tokenId, index);

        factory.mint(account, tokenId, 1, "");

        emit Claimed(tokenId, index, account, amount);
    }

    function _setClaimed(uint256 pepemonTokenId, uint256 index) internal {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedTokens[pepemonTokenId][claimedWordIndex] =
            claimedTokens[pepemonTokenId][claimedWordIndex] |
            (1 << claimedBitIndex);
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