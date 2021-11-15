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


// File @animoca/ethereum-contracts-core-1.1.1/contracts/metatx/[email protected]

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
        return msg.data;
    }
}


// File @animoca/ethereum-contracts-core-1.1.1/contracts/access/[email protected]

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


// File @animoca/ethereum-contracts-core-1.1.1/contracts/access/[email protected]

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
     * @param newOwner the address of the new owner. Use the zero address to renounce the ownership.
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


// File @animoca/ethereum-contracts-core-1.1.1/contracts/utils/types/[email protected]

// Partially derived from OpenZeppelin:
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/406c83649bd6169fc1b578e08506d78f0873b276/contracts/utils/Address.sol

pragma solidity >=0.7.6 <0.8.0;

/**
 * @dev Upgrades the address type to check if it is a contract.
 */
library AddressIsContract {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}


// File @animoca/ethereum-contracts-core-1.1.1/contracts/utils/[email protected]

pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC20Wrapper
 * Wraps ERC20 functions to support non-standard implementations which do not return a bool value.
 * Calls to the wrapped functions revert only if they throw or if they return false.
 */
library ERC20Wrapper {
    using AddressIsContract for address;

    function wrappedTransfer(
        IWrappedERC20 token,
        address to,
        uint256 value
    ) internal {
        _callWithOptionalReturnData(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function wrappedTransferFrom(
        IWrappedERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callWithOptionalReturnData(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function wrappedApprove(
        IWrappedERC20 token,
        address spender,
        uint256 value
    ) internal {
        _callWithOptionalReturnData(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function _callWithOptionalReturnData(IWrappedERC20 token, bytes memory callData) internal {
        address target = address(token);
        require(target.isContract(), "ERC20Wrapper: non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = target.call(callData);
        if (success) {
            if (data.length != 0) {
                require(abi.decode(data, (bool)), "ERC20Wrapper: operation failed");
            }
        } else {
            // revert using a standard revert message
            if (data.length == 0) {
                revert("ERC20Wrapper: operation failed");
            }

            // revert using the revert message coming from the call
            assembly {
                let size := mload(data)
                revert(add(32, data), size)
            }
        }
    }
}

interface IWrappedERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);
}


// File contracts/payout/PayoutClaimDistributor.sol
pragma solidity >=0.7.6 <0.8.0;



/// @title PayoutClaimDistributor
contract PayoutClaimDistributor is Ownable {
    using MerkleProof for bytes32[];
    using ERC20Wrapper for IWrappedERC20;

    event SetMerkleRoot(bytes32 indexed merkleRoot);
    event ClaimedPayout(address indexed account, uint256 amount, uint256 salt);
    event DistributionLocked(bool isLocked);
    event SetDistributorAddress(address indexed ownerAddress, address indexed distAddress);

    bytes32 public merkleRoot;
    IWrappedERC20 public token;
    address public distAddress;
    bool public isLocked;

    /*
     * Mapping for hash for (index,  address, amount, salt) for claimed status
     */
    mapping(bytes32 => bool) public claimed;

    /// @dev Constructor for setting ERC token address on deployment
    /// @param token_ Address for token to distribute
    /// @dev `distAddress` deployer address will be distributor address by default
    constructor(IWrappedERC20 token_) Ownable(msg.sender) {
        token = token_;
        distAddress = msg.sender;
    }

    /// @notice Merkle Root for current period to use for payout
    /// @dev Owner sets merkle hash generated based on the payout set
    /// @param merkleRoot_ bytes32 string of merkle root to set for specific period
    function setMerkleRoot(bytes32 merkleRoot_) public {
        _requireOwnership(_msgSender());
        merkleRoot = merkleRoot_;
        emit SetMerkleRoot(merkleRoot_);
    }

    /// @notice Set locked/unlocked status  for PayoutClaim Distributor
    /// @dev Owner lock/unlock each time new merkle root is being generated
    /// @param isLocked_ = true/false status
    function setLocked(bool isLocked_) public {
        _requireOwnership(_msgSender());
        isLocked = isLocked_;
        emit DistributionLocked(isLocked_);
    }

    /// @notice Distributor address in PayoutClaim Distributor
    /// @dev Wallet that holds token for distribution
    /// @param distributorAddress Distributor address used for distribution of `token` token
    function setDistributorAddress(address distributorAddress) public {
        _requireOwnership(_msgSender());
        distAddress = distributorAddress;
        emit SetDistributorAddress(_msgSender(), distributorAddress);
    }

    /// @notice Payout method that user calls to claim
    /// @dev Method user calls for claiming the payout for user
    /// @param account Address of the user to claim the payout
    /// @param amount Claimable amount of address
    /// @param salt Unique value for user for each new merkle root generating
    /// @param merkleProof Merkle proof of the user based on the merkle root
    function claimPayout(
        address account,
        uint256 amount,
        uint256 salt,
        bytes32[] calldata merkleProof
    ) external {
        require(!isLocked, "Payout locked");

        bytes32 leafHash = keccak256(abi.encodePacked(account, amount, salt));

        require(!claimed[leafHash], "Payout already claimed");
        require(merkleProof.verify(merkleRoot, leafHash), "Invalid proof");

        claimed[leafHash] = true;

        token.wrappedTransferFrom(distAddress, account, amount);

        emit ClaimedPayout(account, amount, salt);
    }
}

