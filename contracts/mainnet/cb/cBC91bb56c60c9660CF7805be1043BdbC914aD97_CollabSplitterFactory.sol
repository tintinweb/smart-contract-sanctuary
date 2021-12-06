// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library ClonesUpgradeable {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
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
library MerkleProofUpgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @title CollabSplitterFactory
/// @author Simon Fremaux (@dievardump)
contract CollabSplitter is Initializable {
    event ETHClaimed(address operator, address account, uint256 amount);
    event ERC20Claimed(
        address operator,
        address account,
        uint256 amount,
        address token
    );

    struct ERC20Data {
        uint256 totalReceived;
        uint256 lastBalance;
    }

    // string public name;
    bytes32 public merkleRoot;

    // keeps track of how much was received in ETH since the start
    uint256 public totalReceived;

    // keeps track of how much an account already claimed ETH
    mapping(address => uint256) public alreadyClaimed;

    // keeps track of ERC20 data
    mapping(address => ERC20Data) public erc20Data;
    // keeps track of how much an account already claimed for a given ERC20
    mapping(address => mapping(address => uint256)) private erc20AlreadyClaimed;

    function initialize(bytes32 merkleRoot_) external initializer {
        merkleRoot = merkleRoot_;
    }

    receive() external payable {
        totalReceived += msg.value;
    }

    /// @notice Does claimETH and claimERC20 in one call
    /// @param account the account we want to claim for
    /// @param percent the allocation for this account | 2 decimal basis, meaning 1 = 100, 2.5 = 250 etc...
    /// @param merkleProof the merkle proof used to ensure this claim is legit
    /// @param erc20s the ERC20 contracts addresses to claim from
    function claimBatch(
        address account,
        uint256 percent,
        bytes32[] memory merkleProof,
        address[] memory erc20s
    ) public {
        require(
            MerkleProofUpgradeable.verify(
                merkleProof,
                merkleRoot,
                getNode(account, percent)
            ),
            'Invalid proof.'
        );

        _claimETH(account, percent);

        for (uint256 i; i < erc20s.length; i++) {
            _claimERC20(account, percent, erc20s[i]);
        }
    }

    /// @notice Allows to claim the ETH for an account
    /// @param account the account we want to claim for
    /// @param percent the allocation for this account | 2 decimal basis, meaning 1 = 100, 2.5 = 250 etc...
    /// @param merkleProof the merkle proof used to ensure this claim is legit
    function claimETH(
        address account,
        uint256 percent,
        bytes32[] memory merkleProof
    ) public {
        require(
            MerkleProofUpgradeable.verify(
                merkleProof,
                merkleRoot,
                getNode(account, percent)
            ),
            'Invalid proof.'
        );

        _claimETH(account, percent);
    }

    /// @notice Allows to claim an ERC20 for an account
    /// @dev To be able to do so, every time a claim is asked, we will compare both current and last known
    ///      balance for this contract, allowing to keep up to date on how much it has ever received
    ///      then we can calculate the full amount due to the account, and substract the amount already claimed
    /// @param account the account we want to claim for
    /// @param percent the allocation for this account | 2 decimal basis, meaning 1% = 100, 2.5% = 250 etc...
    /// @param merkleProof the merkle proof used to ensure this claim is legit
    /// @param erc20s the ERC20 contracts addresses to claim from
    function claimERC20(
        address account,
        uint256 percent,
        bytes32[] memory merkleProof,
        address[] memory erc20s
    ) public {
        require(
            MerkleProofUpgradeable.verify(
                merkleProof,
                merkleRoot,
                getNode(account, percent)
            ),
            'Invalid proof.'
        );

        for (uint256 i; i < erc20s.length; i++) {
            _claimERC20(account, percent, erc20s[i]);
        }
    }

    /// @notice Function to create the "node" in the merkle tree, given account and allocation
    /// @param account the account
    /// @param percent the allocation
    /// @return the bytes32 representing the node / leaf
    function getNode(address account, uint256 percent)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(account, percent));
    }

    /// @notice Helper allowing to know how much ETH is still claimable for a list of accounts
    /// @param accounts the account to check for
    /// @param percents the allocation for this account
    function getBatchClaimableETH(
        address[] memory accounts,
        uint256[] memory percents
    ) public view returns (uint256[] memory) {
        uint256[] memory claimable = new uint256[](accounts.length);
        for (uint256 i; i < accounts.length; i++) {
            claimable[i] = _calculateDue(
                totalReceived,
                percents[i],
                alreadyClaimed[accounts[i]]
            );
        }
        return claimable;
    }

    /// @notice Helper allowing to know how much of an ERC20 is still claimable for a list of accounts
    /// @param accounts the account to check for
    /// @param percents the allocation for this account
    /// @param token the token (ERC20 contract) to check on
    function getBatchClaimableERC20(
        address[] memory accounts,
        uint256[] memory percents,
        address token
    ) public view returns (uint256[] memory) {
        ERC20Data memory data = erc20Data[token];
        uint256 balance = IERC20(token).balanceOf(address(this));
        uint256 sinceLast = balance - data.lastBalance;

        // the difference between last claim and today's balance is what has been received as royalties
        // so we can add it to the total received
        data.totalReceived += sinceLast;

        uint256[] memory claimable = new uint256[](accounts.length);
        for (uint256 i; i < accounts.length; i++) {
            claimable[i] = _calculateDue(
                data.totalReceived,
                percents[i],
                erc20AlreadyClaimed[accounts[i]][token]
            );
        }

        return claimable;
    }

    /// @notice Helper to query how much an account already claimed for a list of tokens
    /// @param account the account to check for
    /// @param tokens the tokens addresses
    ///        use address(0) to query for nativ chain token
    function getBatchClaimed(address account, address[] memory tokens)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory claimed = new uint256[](tokens.length);
        for (uint256 i; i < tokens.length; i++) {
            if (tokens[i] == address(0)) {
                claimed[i] = alreadyClaimed[account];
            } else {
                claimed[i] = erc20AlreadyClaimed[account][tokens[i]];
            }
        }

        return claimed;
    }

    /// @dev internal function to claim ETH
    /// @param account the account we want to claim for
    /// @param percent the allocation for this account | 2 decimal basis, meaning 1% = 100, 2.5% = 250 etc...
    function _claimETH(address account, uint256 percent) internal {
        if (totalReceived == 0) return;

        uint256 dueNow = _calculateDue(
            totalReceived,
            percent,
            alreadyClaimed[account]
        );

        if (dueNow == 0) return;

        // update the already claimed first, blocking reEntrancy
        alreadyClaimed[account] += dueNow;

        // send the due;
        // @TODO: .call{}() calls with all gas left in the tx
        // Question: Should we limit the gas used here?!
        // It has to be at least enough for contracts (Gnosis etc...) to proxy and store
        (bool success, ) = account.call{value: dueNow}('');
        require(success, 'Error when sending ETH');

        emit ETHClaimed(msg.sender, account, dueNow);
    }

    /// @dev internal function to claim an ERC20
    /// @param account the account we want to claim for
    /// @param percent the allocation for this account | 2 decimal basis, meaning 1% = 100, 2.5% = 250 etc...
    /// @param erc20 the ERC20 contract to claim from
    function _claimERC20(
        address account,
        uint256 percent,
        address erc20
    ) internal {
        ERC20Data storage data = erc20Data[erc20];
        uint256 balance = IERC20(erc20).balanceOf(address(this));
        uint256 sinceLast = balance - data.lastBalance;

        // the difference between last known balance and today's balance is what has been received as royalties
        // so we can add it to the total received
        data.totalReceived += sinceLast;

        // now we can calculate how much is due to current account the same way we do for ETH
        if (data.totalReceived == 0) return;

        uint256 dueNow = _calculateDue(
            data.totalReceived,
            percent,
            erc20AlreadyClaimed[account][erc20]
        );

        if (dueNow == 0) return;

        // update the already claimed first
        erc20AlreadyClaimed[account][erc20] += dueNow;

        // transfer the dueNow
        require(
            IERC20(erc20).transfer(account, dueNow),
            'Error when sending ERC20'
        );

        // update the lastBalance, so we can recalculate next time
        // we could save this call by doing (balance - dueNow) but some ERC20 might have weird behavior
        // and actually make the balance different than this after the transfer
        // so for safety, reading the actual state again
        data.lastBalance = IERC20(erc20).balanceOf(address(this));

        // emitting an event will allow to identify claimable ERC20 in TheGraph
        // to be able to display them in the UI and keep stats
        emit ERC20Claimed(msg.sender, account, dueNow, erc20);
    }

    /// @dev Helpers that calculates how much is still left to claim
    /// @param total total received
    /// @param percent allocation
    /// @param claimed what was already claimed
    /// @return what is left to claim
    function _calculateDue(
        uint256 total,
        uint256 percent,
        uint256 claimed
    ) internal pure returns (uint256) {
        return (total * percent) / 10000 - claimed;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

import './CollabSplitterFactory/CollabSplitterFactoryStorage.sol';
import './CollabSplitter.sol';

/// @title CollabSplitterFactory
/// @author Simon Fremaux (@dievardump)
/// @notice This contract allows people to create a "Splitter" -> a contract that will
///         allow to split the ETH or ERC20 it received, between several addresses
///         This contract is upgradeable, because we might have to add functionalities
///         or versioning over time.
///         However, the Factory has no authority over a Splitter after it's created
///         which ensure that updates to the current contract
///         won't create any problems / exploits on existing Splitter
contract CollabSplitterFactory is
    OwnableUpgradeable,
    CollabSplitterFactoryStorage
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    // emitted when a splitter contract is created
    event SplitterCreated(
        address indexed splitter,
        string name,
        address[] recipients,
        uint256[] amounts
    );

    constructor() {}

    function initialize(address splitterImplementation, address owner_)
        external
        initializer
    {
        _setSplitterImplementation(splitterImplementation);

        if (owner_ != address(0)) {
            transferOwnership(owner_);
        }
    }

    /// @notice Getter for the Splitter Implementation
    function getSplitterImplementation() public view returns (address) {
        return _splitterImplementation;
    }

    /// @notice Creates a new CollabSplitter contract
    /// @dev the contract created is a minimal proxy to the _splitterImplementation
    ///      the list of recipients (and the corresponding amounts) should then be used in the exact same order
    ///      to create the merkleProof and merkleRoot
    /// @param name_ name of the Splitter (for convenience)
    /// @param merkleRoot merkle root of the tree of recipients
    /// @param recipients list of recipients
    /// @param amounts list of amounts
    /// @return newContract the address of the new contract
    function createSplitter(
        string memory name_,
        bytes32 merkleRoot,
        address[] memory recipients,
        uint256[] memory amounts
    ) external payable returns (address newContract) {
        require(_splitterImplementation != address(0), '!NO_IMPLEMENTATION!');

        require(recipients.length == amounts.length, '!LENGTH_MISMATCH!');

        uint256 total;
        for (uint256 i; i < amounts.length; i++) {
            require(amounts[i] != 0, '!NO_NULL_VALUE!');
            total += amounts[i];
        }

        require(total == 10000, '!VALUE_MUST_BE_100!');

        // create minimal proxy to _splitterImplementation
        newContract = ClonesUpgradeable.clone(_splitterImplementation);

        // initialize the non upgradeable proxy
        CollabSplitter(payable(newContract)).initialize(merkleRoot);

        // emit an event with all the data needed to reconstruct later the merkle tree
        // and allow people to claim their eth / tokens
        // using events will allow to store everything in TheGraph (or similar) in a decentralized way
        // while still be less expensive than storing in the CollabSplitter storage
        emit SplitterCreated(newContract, name_, recipients, amounts);
    }

    /// @notice Setter for the Splitter Implementation
    /// @param implementation the address to proxy calls to
    function setSplitterImplementation(address implementation)
        public
        onlyOwner
    {
        _setSplitterImplementation(implementation);
    }

    /// @dev internal setter for the Splitter Implementation
    /// @param implementation the address to proxy calls to
    function _setSplitterImplementation(address implementation) internal {
        _splitterImplementation = implementation;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol';

/// @title CollabSplitterFactoryStorage
/// @author Simon Fremaux (@dievardump)
contract CollabSplitterFactoryStorage {
    // current Splitter implementation
    address internal _splitterImplementation;

    // gap
    uint256[50] private __gap;
}