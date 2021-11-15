// Sources flattened with hardhat v2.4.1 https://hardhat.org

// File @openzeppelin/contracts/cryptography/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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


// File @animoca/ethereum-contracts-core/contracts/metatx/[email protected]



pragma solidity >=0.7.6 <0.8.0;

/*
 * Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner.
 */
abstract contract ManagedIdentity {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File @animoca/ethereum-contracts-core/contracts/access/[email protected]



pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC-173 Contract Ownership Standard
 * Note: the ERC-165 identifier for this interface is 0x7f5828d0
 */
interface IERC173 {
    /**
     * Event emited when ownership of a contract changes.
     * @param previousOwner the previous owner.
     * @param newOwner the new owner.
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * Get the address of the owner
     * @return The address of the owner.
     */
    function owner() external view returns (address);

    /**
     * Set the address of the new owner of the contract
     * Set newOwner to address(0) to renounce any ownership.
     * @dev Emits an {OwnershipTransferred} event.
     * @param newOwner The address of the new owner of the contract. Using the zero address means renouncing ownership.
     */
    function transferOwnership(address newOwner) external;
}


// File @animoca/ethereum-contracts-core/contracts/access/[email protected]



pragma solidity >=0.7.6 <0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is ManagedIdentity, IERC173 {
    address internal _owner;

    /**
     * Initializes the contract, setting the deployer as the initial owner.
     * @dev Emits an {IERC173-OwnershipTransferred(address,address)} event.
     */
    constructor(address owner_) {
        _owner = owner_;
        emit OwnershipTransferred(address(0), owner_);
    }

    /**
     * Gets the address of the current contract owner.
     */
    function owner() public view virtual override returns (address) {
        return _owner;
    }

    /**
     * See {IERC173-transferOwnership(address)}
     * @dev Reverts if the sender is not the current contract owner.
     */
    function transferOwnership(address newOwner) public virtual override {
        _requireOwnership(_msgSender());
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
    }

    /**
     * @dev Reverts if `account` is not the contract owner.
     * @param account the account to test.
     */
    function _requireOwnership(address account) internal virtual {
        require(account == this.owner(), "Ownable: not the owner");
    }
}


// File @animoca/ethereum-contracts-assets/contracts/token/ERC1155/[email protected]



pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC-1155 Multi Token Standard, basic interface
 * @dev See https://eips.ethereum.org/EIPS/eip-1155
 * Note: The ERC-165 identifier for this interface is 0xd9b67a26.
 */
interface IERC1155 {
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);

    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    event URI(string _value, uint256 indexed _id);

    /**
     * Safely transfers some token.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if the sender is not approved.
     * @dev Reverts if `from` has an insufficient balance.
     * @dev Reverts if `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155received} fails or is refused.
     * @dev Emits a `TransferSingle` event.
     * @param from Current token owner.
     * @param to Address of the new token owner.
     * @param id Identifier of the token to transfer.
     * @param value Amount of token to transfer.
     * @param data Optional data to send along to a receiver contract.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external;

    /**
     * Safely transfers a batch of tokens.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if `ids` and `values` have different lengths.
     * @dev Reverts if the sender is not approved.
     * @dev Reverts if `from` has an insufficient balance for any of `ids`.
     * @dev Reverts if `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155batchReceived} fails or is refused.
     * @dev Emits a `TransferBatch` event.
     * @param from Current token owner.
     * @param to Address of the new token owner.
     * @param ids Identifiers of the tokens to transfer.
     * @param values Amounts of tokens to transfer.
     * @param data Optional data to send along to a receiver contract.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external;

    /**
     * Retrieves the balance of `id` owned by account `owner`.
     * @param owner The account to retrieve the balance of.
     * @param id The identifier to retrieve the balance of.
     * @return The balance of `id` owned by account `owner`.
     */
    function balanceOf(address owner, uint256 id) external view returns (uint256);

    /**
     * Retrieves the balances of `ids` owned by accounts `owners`. For each pair:
     * @dev Reverts if `owners` and `ids` have different lengths.
     * @param owners The addresses of the token holders
     * @param ids The identifiers to retrieve the balance of.
     * @return The balances of `ids` owned by accounts `owners`.
     */
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * Enables or disables an operator's approval.
     * @dev Emits an `ApprovalForAll` event.
     * @param operator Address of the operator.
     * @param approved True to approve the operator, false to revoke an approval.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * Retrieves the approval status of an operator for a given owner.
     * @param owner Address of the authorisation giver.
     * @param operator Address of the operator.
     * @return True if the operator is approved, false if not.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}


// File contracts/payout/NFTPayoutClaim.sol

pragma solidity >=0.7.6 <0.8.0;
pragma experimental ABIEncoderV2;

//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/token/ERC1155/IERC1155.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/cryptography/MerkleProof.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/access/Ownable.sol";



contract NFTPayoutClaim is Ownable {
    using MerkleProof for bytes32[];

    event SetDistributor(address indexed account, address indexed distributorAddress);
    event SetMerkleRoot(address indexed account, bytes32 merkleRoot);
    event ClaimPayout(address indexed fromAddress, address indexed toAddress, uint256[] tokenId, uint256[] amount);
    event SetMerkleRootStatus(bytes32 merkleRoot, bool status);

    address public distributorAddress;

    uint256 public merkleRootCount = 0;
    mapping(bytes32 => mapping(bytes32 => bool)) public claimed; // merkleRoot -> (hash, claimed)
    mapping(bytes32 => bool) public merkleRoots; // merkleRoot -> enabled
    mapping(bytes32 => bool) public merkleRootExists; // merkleRoot -> exists (optional - for validation)

    constructor() Ownable(msg.sender) {
        distributorAddress = msg.sender;
    }

    function setDistributor(address distAddress) external {
        _requireOwnership(_msgSender());
        distributorAddress = distAddress;
        emit SetDistributor(_msgSender(), distAddress);
    }

    function addMerkleRoot(bytes32 merkleRoot) external {
        _requireOwnership(_msgSender());
        require(merkleRootExists[merkleRoot] == false, "MerkleRoot already exists.");

        uint256 count = merkleRootCount;
        merkleRootCount = count + 1;

        merkleRoots[merkleRoot] = true;
        merkleRootExists[merkleRoot] = true;

        emit SetMerkleRoot(_msgSender(), merkleRoot);
    }

    function disableMerkleRoot(bytes32 merkleRoot) external {
        _requireOwnership(_msgSender());
        require(merkleRootExists[merkleRoot] == true, "Invalid MerkleRoot.");
        require(merkleRoots[merkleRoot] == true, "MerkleRoot disabled.");

        merkleRoots[merkleRoot] = false;
        emit SetMerkleRootStatus(merkleRoot, false);
    }

    function claimPayout(
        uint256 batch,
        address receiver,
        address[] calldata contractAddress,
        uint256[][] calldata tokenIds,
        uint256[][] calldata amounts,
        bytes32 merkleRoot,
        bytes32[][] calldata merkleProof
    ) external {
        require(merkleRootExists[merkleRoot] == true, "Invalid MerkleRoot.");
        require(merkleRoots[merkleRoot] == true, "MerkleRoot disabled.");

        uint256 i;
        for (i = 0; i < contractAddress.length; i++) {
            address contractAddr = contractAddress[i];

            bytes32 leafHash = keccak256(abi.encodePacked(batch, receiver, contractAddr, tokenIds[i], amounts[i]));

            require(!claimed[merkleRoot][leafHash], "Payout already claimed.");
            require(merkleProof[i].verify(merkleRoot, leafHash), "Invalid proof.");

            claimed[merkleRoot][leafHash] = true;

            IERC1155(contractAddr).safeBatchTransferFrom(distributorAddress, receiver, tokenIds[i], amounts[i], "");
            emit ClaimPayout(distributorAddress, receiver, tokenIds[i], amounts[i]);
        }
    }
}

