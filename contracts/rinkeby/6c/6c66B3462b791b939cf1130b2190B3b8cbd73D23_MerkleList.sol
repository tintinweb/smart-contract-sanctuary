pragma solidity 0.8.6;


import "MerkleProofIndex.sol";

/**
 * @notice TokenAllowList - Allow List that references a given `token` balance to return approvals.
 */
contract MerkleList {
 
    bytes32 public merkleRoot;

    bytes32 public constant TEMPLATE_ID = keccak256("MERKLE_LIST");

    /// @notice Whether initialised or not.
    bool private initialised;

    constructor() {
    }

    /**
     * @notice Initializes token point list with reference token.
     * @param _merkleRoot Merkle Root
     */

    function initMerkleList(bytes32 _merkleRoot) public {
        require(!initialised, "Already initialised");
        merkleRoot = _merkleRoot;
        initialised = true;
    }

    /**
     * @notice Checks if account address is in the list (has any tokens).
     * @param _account Account address.
     * @return bool True or False.
     */
    function tokensClaimable(uint _index, address _account, uint256 _amount, bytes32[] calldata _merkleProof ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_index, _account, _amount));
        (bool valid, uint256 index) = MerkleProofIndex.verify(_merkleProof, merkleRoot, leaf);
        return valid;
    }

}

// SPDX-License-Identifier: MIT
// Modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.0/contracts/utils/cryptography/MerkleProof.sol

pragma solidity 0.8.6;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProofIndex {
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
    ) internal pure returns (bool, uint256) {
        bytes32 computedHash = leaf;
        uint256 index = 0;

        for (uint256 i = 0; i < proof.length; i++) {
            index *= 2;
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
                index += 1;
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return (computedHash == root, index);
    }
}