// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
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
pragma solidity ^0.8.0;

/*****************************************************************************************************/
/**                                             WARNING                                             **/
/**                              THIS CONTRACT IS AN UPGRADEABLE FACET!                             **/
/**  ---------------------------------------------------------------------------------------------  **/
/**  Do NOT place ANY storage/state variables directly in this contract! If you wish to make        **/
/**  make changes to the state variables used by this contract, do so in its defined Storage        **/
/**  contract that this contract inherits from                                                      **/
/**                                                                                                 **/
/**  Visit https://docs.openzeppelin.com/upgrades/2.6/proxies#upgrading-via-the-proxy-pattern for   **/
/**  more information.                                                                              **/
/*****************************************************************************************************/
/**
    @notice This contract stores the logic to clone an already deployed contract with minimal amount of code.
    @notice By cloning a contract, we are able to create a new contract instance without having to spend all the deployment cost of the same code.

    @author [email protected]
 */
contract Factory {
    function _clone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);

        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            result := create(0, clone, 0x37)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

// Contracts
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../Factory.sol";
import "../../interfaces/nft/ITellerNFT.sol";

// Interfaces

/*****************************************************************************************************/
/**                                             WARNING                                             **/
/**                        THIS CONTRACT IS AN UPGRADEABLE STORAGE CONTRACT!                        **/
/**  ---------------------------------------------------------------------------------------------  **/
/**  Do NOT change the order of or PREPEND any storage variables to this or new versions            **/
/**  of this contract as this will cause a ripple affect to the storage slots of all child          **/
/**  contracts that inherit from this contract to be overwritten on the deployed proxy contract!!   **/
/**                                                                                                 **/
/**  Visit https://docs.openzeppelin.com/upgrades/2.6/proxies#upgrading-via-the-proxy-pattern for   **/
/**  more information.                                                                              **/
/*****************************************************************************************************/
/**
 * @notice
 *
 * @author [email protected]
 */
contract NFTDistributor {
    ITellerNFT public nft;

    bytes32[] public tierMerkleRoots;

    mapping(uint256 => mapping(uint256 => uint256)) public claimedBitMap;

    event Claimed(uint256 index, address account, uint256 amount);

    event TierAdded(uint256 index);

    function getTierMerkleRoots() external view returns (bytes32[] memory) {
        return tierMerkleRoots;
    }

    function claim(
        uint256 tierIndex,
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external {
        require(!isClaimed(tierIndex, index), "Teller: NFT already claimed.");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(
            MerkleProof.verify(merkleProof, tierMerkleRoots[tierIndex], node),
            "Teller: Invalid proof."
        );

        // Mark it claimed and send the token.
        _setClaimed(tierIndex, index);
        for (uint256 i; i < amount; i++) {
            nft.mint(tierIndex, account);
        }

        emit Claimed(index, account, amount);
    }

    function _setClaimed(uint256 tierIndex, uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[tierIndex][claimedWordIndex] =
            claimedBitMap[tierIndex][claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    function isClaimed(uint256 tierIndex, uint256 index)
        public
        view
        returns (bool)
    {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[tierIndex][claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function addTier(bytes32 merkleRoot) external {
        tierMerkleRoots.push(merkleRoot);

        emit TierAdded(tierMerkleRoots.length - 1);
    }

    function initialize(address nftAddress) external {
        require(address(nft) == address(0), "Teller: Already initialized");
        nft = ITellerNFT(nftAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface ITellerNFT {
    struct Tier {
        uint256 baseLoanSize;
        string[] hashes;
        address contributionAsset;
        uint256 contributionSize;
        uint8 contributionMultiplier;
    }

    function mint(uint256 tierIndex, address owner) external virtual;

    function addTier(Tier memory newTier) external virtual;
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}