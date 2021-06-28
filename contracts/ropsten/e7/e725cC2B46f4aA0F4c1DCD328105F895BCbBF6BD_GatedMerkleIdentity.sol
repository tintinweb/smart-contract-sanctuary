// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.7.4;

import "../interfaces/IVotingIdentity.sol";
import "../interfaces/IIncinerator.sol";

contract GatedMerkleIdentity {

    mapping (uint => bytes32) public merkleRoots;
    mapping (uint => bytes32) public ipfsHashes;
    uint public numRoots;
    IVotingIdentity public token;

    address public management;

    IIncinerator public incinerator;
    address public burnToken;
    uint public ethCost;

    mapping (address => bool) public withdrawn;

    event ManagementUpdated(address oldManagement, address newManagement);
    event MerkleRootAdded(uint indexed index, bytes32 newRoot);

    modifier managementOnly() {
        require (msg.sender == management, 'Only management may call this');
        _;
    }

    constructor(
        IVotingIdentity _token,
        bytes32 _root,
        address _mgmt,
        address _incinerator,
        address _burnToken,
        uint _ethCost) {
        token = _token;
        merkleRoots[1] = _root;
        management = _mgmt;
        setGateParameters(_incinerator, _burnToken, _ethCost);
        numRoots = 1;
    }

    function setGateParameters(address _incinerator, address _burnToken, uint _ethCost) public managementOnly {
        incinerator = IIncinerator(_incinerator);
        burnToken = _burnToken;
        ethCost = _ethCost;
    }

    // change the management key
    function setManagement(address newMgmt) external managementOnly {
        address oldMgmt =  management;
        management = newMgmt;
        emit ManagementUpdated(oldMgmt, newMgmt);
    }

    function addMerkleRoot(bytes32 newRoot) external managementOnly {
        merkleRoots[++numRoots] = newRoot;
        emit MerkleRootAdded(numRoots, newRoot);
    }

    function withdraw(uint merkleIndex, bytes32[] memory proof) external payable {
        require(msg.value >= ethCost, 'Please send more ETH');
        require(verifyEntitled(merkleRoots[merkleIndex], msg.sender, proof), "The proof could not be verified.");
        // note that this effectively prevents inclusion of the same address in multiple merkle roots
        require(! withdrawn[msg.sender], "You have already withdrawn your nft.");

        withdrawn[msg.sender] = true;

        // burn token cost
        if (msg.value > 0) {
            incinerator.incinerate{value: msg.value}(burnToken);
        }


        token.createIdentityFor(msg.sender);

    }

    function getLeaf(address data) external pure returns (bytes memory) {
        return abi.encode(data);
    }

    function getHash(address data) external pure returns (bytes32) {
        return keccak256(abi.encode(data));
    }

    function verifyEntitled(bytes32 root, address recipient, bytes32[] memory proof) public pure returns (bool) {
        // We need to pack the 20 bytes address to the 32 bytes value
        // to match with the proof made with the python merkle-drop package
        bytes32 leaf = keccak256(abi.encode(recipient));
        return verifyProof(root, leaf, proof);
    }

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

interface IIncinerator {

    function incinerate(address tokenAddr) external payable;
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
    function createIdentityFor(address newId) external;

    /**
        Who's in charge around here
    */
    function owner() external view returns (address);


}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
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