// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.7.4;

library MerkleLib {

    function verifyProof(bytes32 root, bytes32 leaf, bytes32[] memory proof) public pure returns (bool) {
        bytes32 currentHash = leaf;

        for (uint i = 0; i < proof.length; i += 1) {
            currentHash = parentHash(currentHash, proof[i]);
        }

        return currentHash == root;
    }

    function parentHash(bytes32 a, bytes32 b) public pure returns (bytes32) {
        if (a < b) {
            return keccak256(abi.encode(a, b));
        } else {
            return keccak256(abi.encode(b, a));
        }
    }

}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.7.4;

import "../interfaces/IVotingIdentity.sol";
import "../interfaces/IGate.sol";
import "../MerkleLib.sol";

contract GatedMerkleIdentity {
    using MerkleLib for *;

    struct MerkleTree {
        bytes32 addressMerkleRoot;
        bytes32 metadataMerkleRoot;
        bytes32 leafHash;
        address nftAddress;
        address gateAddress;
    }

    mapping (uint => MerkleTree) public merkleTrees;
    uint public numTrees;

    address public management;

    mapping (uint => mapping(address => bool)) public withdrawn;

    event ManagementUpdated(address oldManagement, address newManagement);
    event MerkleTreeAdded(uint indexed index, address indexed nftAddress);

    modifier managementOnly() {
        require (msg.sender == management, 'Only management may call this');
        _;
    }

    constructor(address _mgmt) {
        management = _mgmt;
    }

    // change the management key
    function setManagement(address newMgmt) external managementOnly {
        address oldMgmt =  management;
        management = newMgmt;
        emit ManagementUpdated(oldMgmt, newMgmt);
    }

    function addMerkleTree(bytes32 addressMerkleRoot, bytes32 metadataMerkleRoot, bytes32 leafHash, address nftAddress, address gateAddress) external managementOnly {
        MerkleTree storage tree = merkleTrees[++numTrees];
        tree.addressMerkleRoot = addressMerkleRoot;
        tree.metadataMerkleRoot = metadataMerkleRoot;
        tree.leafHash = leafHash;
        tree.nftAddress = nftAddress;
        tree.gateAddress = gateAddress;
        emit MerkleTreeAdded(numTrees, nftAddress);
    }

    function withdraw(uint merkleIndex, string memory uri, bytes32[] memory addressProof, bytes32[] memory metadataProof) external payable {
        MerkleTree storage tree = merkleTrees[merkleIndex];
        IVotingIdentity id = IVotingIdentity(tree.nftAddress);
        uint tokenId = id.numIdentities() + 1;

        require(merkleIndex <= numTrees, 'merkleIndex out of range');
        require(verifyEntitled(tree.addressMerkleRoot, msg.sender, addressProof), "The address proof could not be verified.");
        require(verifyMetadata(tree.metadataMerkleRoot, tokenId, uri, metadataProof), "The metadata proof could not be verified");
        require(!withdrawn[merkleIndex][msg.sender], "You have already withdrawn your nft from this merkle tree.");

        // close re-entrance gate, prevent double withdrawals
        withdrawn[merkleIndex][msg.sender] = true;

        // pass thru the gate
        IGate(tree.gateAddress).passThruGate{value: msg.value}();

        // mint an identity
        id.createIdentityFor(msg.sender, tokenId, uri);
    }

    function getNextTokenId(uint merkleIndex) public view returns (uint) {
        MerkleTree memory tree = merkleTrees[merkleIndex];
        IVotingIdentity id = IVotingIdentity(tree.nftAddress);
        uint tokenId = id.totalSupply() + 1;
        return tokenId;
    }

    function getPrice(uint merkleIndex) public view returns (uint) {
        MerkleTree memory tree = merkleTrees[merkleIndex];
        uint ethCost = IGate(tree.gateAddress).getCost();
        return ethCost;
    }

    // mostly for debugging
    function getLeaf(address data1, string memory data2) external pure returns (bytes memory) {
        return abi.encode(data1, data2);
    }

    // mostly for debugging
    function getHash(address data1, string memory data2) external pure returns (bytes32) {
        return keccak256(abi.encode(data1, data2));
    }

    function verifyEntitled(bytes32 root, address recipient, bytes32[] memory proof) public pure returns (bool) {
        // We need to pack the 20 bytes address to the 32 bytes value
        bytes32 leaf = keccak256(abi.encode(recipient));
        return root.verifyProof(leaf, proof);
    }

    function verifyMetadata(bytes32 root, uint tokenId, string memory uri, bytes32[] memory proof) public pure returns (bool) {
        bytes32 leaf = keccak256(abi.encode(tokenId, uri));
        return root.verifyProof(leaf, proof);
    }

}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.7.4;

interface IGate {

    function getCost() external view returns (uint ethCost);

    function passThruGate() external payable;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.7.4;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IVotingIdentity {
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
    function balanceOf(address) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address);

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
    function isApprovedForAll(address, address) external view returns (bool);

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

    /**
        Minting function
    */
    function createIdentityFor(address newId, uint tokenId, string memory uri) external;

    /**
        Who's in charge around here
    */
    function owner() external view returns (address);

    function numIdentities() external view returns (uint);

    function totalSupply() external view returns (uint);
}

