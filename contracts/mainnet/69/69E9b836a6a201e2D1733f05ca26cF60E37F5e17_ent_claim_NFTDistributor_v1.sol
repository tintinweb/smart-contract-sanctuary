// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

// Interfaces
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface ITellerNFT {
    struct Tier {
        uint256 baseLoanSize;
        string[] hashes;
        address contributionAsset;
        uint256 contributionSize;
        uint8 contributionMultiplier;
    }

    /**
     * @notice The contract metadata URI.
     */
    function contractURI() external view returns (string memory);

    /**
     * @notice It returns information about a Tier for a token ID.
     * @param index Tier index to get info.
     */
    function getTier(uint256 index) external view returns (Tier memory tier_);

    /**
     * @notice It returns information about a Tier for a token ID.
     * @param tokenId ID of the token to get Tier info.
     */
    function getTokenTier(uint256 tokenId)
        external
        view
        returns (uint256 index_, Tier memory tier_);

    /**
     * @notice It returns an array of token IDs owned by an address.
     * @dev It uses a EnumerableSet to store values and loops over each element to add to the array.
     * @dev Can be costly if calling within a contract for address with many tokens.
     */
    function getTierHashes(uint256 tierIndex)
        external
        view
        returns (string[] memory hashes_);

    /**
     * @notice It returns an array of token IDs owned by an address.
     * @dev It uses a EnumerableSet to store values and loops over each element to add to the array.
     * @dev Can be costly if calling within a contract for address with many tokens.
     */
    function getOwnedTokens(address owner)
        external
        view
        returns (uint256[] memory owned);

    /**
     * @notice It mints a new token for a Tier index.
     *
     * Requirements:
     *  - Caller must be an authorized minter
     */
    function mint(uint256 tierIndex, address owner) external;

    /**
     * @notice Adds a new Tier to be minted with the given information.
     * @dev It auto increments the index of the next tier to add.
     * @param newTier Information about the new tier to add.
     *
     * Requirements:
     *  - Caller must have the {MINTER} role
     */
    function addTier(Tier memory newTier) external;

    /**
     * @notice Sets the contract level metadata URI hash.
     * @param contractURIHash The hash to the initial contract level metadata.
     */
    function setContractURIHash(string memory contractURIHash) external;

    /**
     * @notice Initializes the TellerNFT.
     * @param minters The addresses that should allowed to mint tokens.
     */
    function initialize(address[] calldata minters) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

bytes32 constant ADMIN = keccak256("ADMIN");
bytes32 constant MINTER = keccak256("MINTER");

struct MerkleRoot {
    bytes32 merkleRoot;
    uint256 tierIndex;
}

struct ClaimNFTRequest {
    uint256 merkleIndex;
    uint256 nodeIndex;
    uint256 amount;
    bytes32[] merkleProof;
}

library DistributorEvents {
    event Claimed(address indexed account);

    event MerkleAdded(uint256 index);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import "../store.sol";
import "../internal/distributor.sol";

// Utils
import { ClaimNFTRequest, DistributorEvents } from "../data.sol";

contract ent_claim_NFTDistributor_v1 is
    sto_NFTDistributor,
    int_distributor_NFT_v1
{
    /**
     * @notice Claims TellerNFTs for a given verifiable merkle proofs for each tier.
     * @param account The address to claim NFTs on behalf.
     * @param requests An array requests data generated from the merkle tree.
     *
     * Requirements:
     *  - Node in the merkle root must not be claimed already
     *  - Proof of the node must match the merkle tree
     */
    function claim(address account, ClaimNFTRequest[] calldata requests)
        external
    {
        for (uint256 i; i < requests.length; i++) {
            require(
                !_isClaimed(requests[i].merkleIndex, requests[i].nodeIndex),
                "TellerNFT Distributor: already claimed"
            );
            require(
                _verifyProof(account, requests[i]),
                "TellerNFT Distributor: invalid proof"
            );

            // Mark it claimed and send the token.
            _setClaimed(requests[i].merkleIndex, requests[i].nodeIndex);
            uint256 tierIndex =
                distributorStore().merkleRoots[requests[i].merkleIndex]
                    .tierIndex;
            for (uint256 j; j < requests[i].amount; j++) {
                distributorStore().nft.mint(tierIndex, account);
            }
        }

        emit DistributorEvents.Claimed(account);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import "../store.sol";

// Libraries
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// Utils
import { ClaimNFTRequest } from "../data.sol";

contract int_distributor_NFT_v1 is sto_NFTDistributor {
    /**
     * @notice It checks the merkle root for a tier if it has already been claimed.
     * @param merkleIndex Index of the tier.
     * @param nodeIndex Index of the node in the merkle root.
     */
    function _setClaimed(uint256 merkleIndex, uint256 nodeIndex) internal {
        uint256 claimedWordIndex = nodeIndex / 256;
        uint256 claimedBitIndex = nodeIndex % 256;
        distributorStore().claimedBitMap[merkleIndex][claimedWordIndex] =
            distributorStore().claimedBitMap[merkleIndex][claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    /**
     * @notice It checks the merkle root for a tier if it has already been claimed.
     * @param merkleIndex Index of the tier.
     * @param nodeIndex Index of the node in the merkle root.
     */
    function _isClaimed(uint256 merkleIndex, uint256 nodeIndex)
        internal
        view
        returns (bool)
    {
        uint256 claimedWordIndex = nodeIndex / 256;
        uint256 claimedBitIndex = nodeIndex % 256;
        uint256 claimedWord =
            distributorStore().claimedBitMap[merkleIndex][claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _verifyProof(address account, ClaimNFTRequest memory request)
        internal
        view
        returns (bool verified)
    {
        verified = MerkleProof.verify(
            request.merkleProof,
            distributorStore().merkleRoots[request.merkleIndex].merkleRoot,
            keccak256(
                abi.encodePacked(request.nodeIndex, account, request.amount)
            )
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Interfaces
import "../ITellerNFT.sol";

// Utils
import { MerkleRoot } from "./data.sol";

abstract contract sto_NFTDistributor {
    struct DistributorStorage {
        ITellerNFT nft;
        MerkleRoot[] merkleRoots;
        mapping(uint256 => mapping(uint256 => uint256)) claimedBitMap;
    }

    bytes32 constant POSITION = keccak256("teller_nft.distributor");

    function distributorStore()
        internal
        pure
        returns (DistributorStorage storage s)
    {
        bytes32 P = POSITION;
        assembly {
            s.slot := P
        }
    }
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