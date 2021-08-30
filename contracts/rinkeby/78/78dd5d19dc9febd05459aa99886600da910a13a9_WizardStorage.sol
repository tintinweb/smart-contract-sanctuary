//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.7;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract WizardStorage {
    mapping(uint256 => bool) public hasTraitsStored;

    bool private canStoreAffinities = true;
    bytes32 private merkleRoot;
    mapping(uint256 => bytes) private wizardToTraits;
    mapping(uint16 => uint16[]) private traitsToAffinities;
    mapping(uint16 => uint16) private affinityOccurrences;

    event StoredTrait(uint256 wizardId, bytes encodedTraits);

    constructor(bytes32 _root) {
        merkleRoot = _root;
    }

    // Store traits for a list of Wizards
    function storeWizardTraits(
        uint256 wizardId,
        uint16[] calldata traits,
        bytes32[] calldata proofs
    ) public {
        require(traits.length == 7, "Invalid Length");
        require(traits[0] == wizardId, "WizardsId to Trait mismatch");
        require(!hasTraitsStored[wizardId], "Traits are already stored");
        bytes memory encodedTraits = _encode(
            traits[0],
            traits[1],
            traits[2],
            traits[3],
            traits[4],
            traits[5],
            traits[6]
        );
        require(
            _verifyEncodedTraits(proofs, encodedTraits),
            "Merkle Proof Invalid!"
        );
        wizardToTraits[wizardId] = encodedTraits;
        hasTraitsStored[wizardId] = true;

        emit StoredTrait(wizardId, encodedTraits);
    }

    // Store related affinities for a list of traits
    function storeTraitAffinities(
        uint16[] calldata traits,
        uint16[][] calldata affinities
    ) public {
        require(canStoreAffinities, "Storing is over");
        for (uint256 i = 0; i < traits.length; i++) {
            traitsToAffinities[traits[i]] = affinities[i];
        }
    }

    // Store affinity occurrences for alist of affinities
    function storeAffinityOccurrences(
        uint16[] calldata affinities,
        uint16[] calldata occurrences
    ) public {
        require(canStoreAffinities, "Storing is over");
        for (uint256 i = 0; i < affinities.length; i++) {
            affinityOccurrences[affinities[i]] = occurrences[i];
        }
    }

    function stopStoring() public {
        require(canStoreAffinities, "Store is already over");
        canStoreAffinities = false;
    }

    /**
        VIEWS
     */

    function getWizardTraits(uint256 wizardId)
        public
        view
        returns (
            uint16 t0,
            uint16 t1,
            uint16 t2,
            uint16 t3,
            uint16 t4,
            uint16 t5
        )
    {
        //ignore id
        (, t0, t1, t2, t3, t4, t5) = _decode(wizardToTraits[wizardId]);
    }

    function getTraitAffinities(uint16 traitId)
        public
        view
        returns (uint16[] memory)
    {
        return traitsToAffinities[traitId];
    }

    function getAffinityOccurrences(uint16 id) public view returns (uint16) {
        return affinityOccurrences[id];
    }

    function getWizardAffinities(uint256 wizardId)
        public
        view
        returns (uint16[] memory)
    {
        // ignore id and t0 (background has no affinity)
        (, , uint16 t1, uint16 t2, uint16 t3, uint16 t4, uint16 t5) = _decode(
            wizardToTraits[wizardId]
        );

        uint16[] storage affinityT1 = traitsToAffinities[t1];
        uint16[] storage affinityT2 = traitsToAffinities[t2];
        uint16[] storage affinityT3 = traitsToAffinities[t3];
        uint16[] storage affinityT4 = traitsToAffinities[t4];
        uint16[] storage affinityT5 = traitsToAffinities[t5];

        uint16[] memory affinitiesList = new uint16[](
            affinityT1.length +
                affinityT2.length +
                affinityT3.length +
                affinityT4.length +
                affinityT5.length
        );

        uint256 lastIndexWritten = 0;

        // 7777 is used as a filler for empty Trait slots
        if (t1 != 7777) {
            for (uint256 i = 0; i < affinityT1.length; i++) {
                affinitiesList[i] = affinityT1[i];
            }
        }

        if (t2 != 7777) {
            lastIndexWritten = lastIndexWritten + affinityT1.length;
            for (uint256 i = 0; i < affinityT2.length; i++) {
                affinitiesList[lastIndexWritten + i] = affinityT2[i];
            }
        }

        if (t3 != 7777) {
            lastIndexWritten = lastIndexWritten + affinityT2.length;
            for (uint8 i = 0; i < affinityT3.length; i++) {
                affinitiesList[lastIndexWritten + i] = affinityT3[i];
            }
        }

        if (t4 != 7777) {
            lastIndexWritten = lastIndexWritten + affinityT3.length;
            for (uint8 i = 0; i < affinityT4.length; i++) {
                affinitiesList[lastIndexWritten + i] = affinityT4[i];
            }
        }

        if (t5 != 7777) {
            lastIndexWritten = lastIndexWritten + affinityT4.length;
            for (uint8 i = 0; i < affinityT5.length; i++) {
                affinitiesList[lastIndexWritten + i] = affinityT5[i];
            }
        }

        return affinitiesList;
    }

    function getWizardTraitsEncoded(uint256 id)
        public
        view
        returns (bytes memory)
    {
        return wizardToTraits[id];
    }

    /**
        INTERNAL
     */

    function _verifyEncodedTraits(bytes32[] memory proof, bytes memory traits)
        internal
        view
        returns (bool)
    {
        bytes32 hashedTraits = keccak256(abi.encodePacked(traits));
        return MerkleProof.verify(proof, merkleRoot, hashedTraits);
    }

    function _encode(
        uint16 id,
        uint16 t0,
        uint16 t1,
        uint16 t2,
        uint16 t3,
        uint16 t4,
        uint16 t5
    ) internal pure returns (bytes memory) {
        bytes memory data = new bytes(16);

        assembly {
            mstore(add(data, 32), 32)

            mstore(add(data, 34), shl(240, id))
            mstore(add(data, 36), shl(240, t0))
            mstore(add(data, 38), shl(240, t1))
            mstore(add(data, 40), shl(240, t2))
            mstore(add(data, 42), shl(240, t3))
            mstore(add(data, 44), shl(240, t4))
            mstore(add(data, 46), shl(240, t5))
        }

        return data;
    }

    function _decode(bytes memory data)
        internal
        pure
        returns (
            uint16 id,
            uint16 t0,
            uint16 t1,
            uint16 t2,
            uint16 t3,
            uint16 t4,
            uint16 t5
        )
    {
        assembly {
            let len := mload(add(data, 0))

            id := mload(add(data, 4))
            t0 := mload(add(data, 6))
            t1 := mload(add(data, 8))
            t2 := mload(add(data, 10))
            t3 := mload(add(data, 12))
            t4 := mload(add(data, 14))
            t5 := mload(add(data, 16))
        }
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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}