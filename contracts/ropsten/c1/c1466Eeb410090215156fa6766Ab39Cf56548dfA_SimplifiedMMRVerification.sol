// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.8.5;

struct SimplifiedMMRProof {
    bytes32[] merkleProofItems;
    uint64 merkleProofOrderBitField;
}

contract  SimplifiedMMRVerification {
    function verifyInclusionProof(
        bytes32 root,
        bytes32 leafNodeHash,
        SimplifiedMMRProof memory proof
    ) public pure returns (bool) {
        require(proof.merkleProofItems.length < 64);

        return root == calculateMerkleRoot(leafNodeHash, proof.merkleProofItems, proof.merkleProofOrderBitField);
    }

    // Get the value of the bit at the given 'index' in 'self'.
    // index should be validated beforehand to make sure it is less than 64
    function bit(uint64 self, uint index) internal pure returns (bool) {
        if (uint8(self >> index & 1) == 1) {
            return true;
        } else {
            return false;
        }
    }

    function calculateMerkleRoot(
        bytes32 leafNodeHash,
        bytes32[] memory merkleProofItems,
        uint64 merkleProofOrderBitField
    ) internal pure returns (bytes32) {
        bytes32 currentHash = leafNodeHash;

        for (uint currentPosition = 0; currentPosition < merkleProofItems.length; currentPosition++) {
            bool isSiblingLeft = bit(merkleProofOrderBitField, currentPosition);
            bytes32 sibling = merkleProofItems[currentPosition];

            if (isSiblingLeft) {
                currentHash = keccak256(
                    abi.encodePacked(sibling, currentHash)
                );
            } else {
                currentHash = keccak256(
                    abi.encodePacked(currentHash, sibling)
                );
            }
        }

        return currentHash;
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "devdoc",
        "userdoc",
        "metadata",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}