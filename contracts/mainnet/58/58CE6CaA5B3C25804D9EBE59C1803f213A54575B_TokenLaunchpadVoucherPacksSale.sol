/**
 *Submitted for verification at Etherscan.io on 2021-11-02
*/

// Sources flattened with hardhat v2.6.5 https://hardhat.org

// File @animoca/ethereum-contracts-core-1.1.2/contracts/utils/types/[email protected]

// SPDX-License-Identifier: MIT

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


// File @animoca/ethereum-contracts-core-1.1.2/contracts/utils/[email protected]

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


// File @animoca/ethereum-contracts-core-1.1.2/contracts/algo/[email protected]

// Derived from OpenZeppelin:
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/406c83649bd6169fc1b578e08506d78f0873b276/contracts/utils/structs/EnumerableMap.sol

pragma solidity >=0.7.6 <0.8.0;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumMap for EnumMap.Map;
 *
 *     // Declare a set state variable
 *     EnumMap.Map private myMap;
 * }
 * ```
 */
library EnumMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // This means that we can only create new EnumMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 key;
        bytes32 value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] entries;
        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping(bytes32 => uint256) indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Map storage map,
        bytes32 key,
        bytes32 value
    ) internal returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map.indexes[key];

        if (keyIndex == 0) {
            // Equivalent to !contains(map, key)
            map.entries.push(MapEntry({key: key, value: value}));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map.indexes[key] = map.entries.length;
            return true;
        } else {
            map.entries[keyIndex - 1].value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Map storage map, bytes32 key) internal returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map.indexes[key];

        if (keyIndex != 0) {
            // Equivalent to contains(map, key)
            // To delete a key-value pair from the entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map.entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map.entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map.entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map.indexes[lastEntry.key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map.entries.pop();

            // Delete the index for the deleted slot
            delete map.indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Map storage map, bytes32 key) internal view returns (bool) {
        return map.indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(Map storage map) internal view returns (uint256) {
        return map.entries.length;
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Map storage map, uint256 index) internal view returns (bytes32, bytes32) {
        require(map.entries.length > index, "EnumMap: index out of bounds");

        MapEntry storage entry = map.entries[index];
        return (entry.key, entry.value);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Map storage map, bytes32 key) internal view returns (bytes32) {
        uint256 keyIndex = map.indexes[key];
        require(keyIndex != 0, "EnumMap: nonexistent key"); // Equivalent to contains(map, key)
        return map.entries[keyIndex - 1].value; // All indexes are 1-based
    }
}


// File @animoca/ethereum-contracts-core-1.1.2/contracts/algo/[email protected]

// Derived from OpenZeppelin:
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/406c83649bd6169fc1b578e08506d78f0873b276/contracts/utils/structs/EnumerableSet.sol

pragma solidity >=0.7.6 <0.8.0;

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
 *     using EnumSet for EnumSet.Set;
 *
 *     // Declare a set state variable
 *     EnumSet.Set private mySet;
 * }
 * ```
 */
library EnumSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Set storage set, bytes32 value) internal returns (bool) {
        if (!contains(set, value)) {
            set.values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set.indexes[value] = set.values.length;
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
    function remove(Set storage set, bytes32 value) internal returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set.indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set.values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set.values[lastIndex];

            // Move the last value to the index where the value to delete is
            set.values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set.indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set.values.pop();

            // Delete the index for the deleted slot
            delete set.indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Set storage set, bytes32 value) internal view returns (bool) {
        return set.indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(Set storage set) internal view returns (uint256) {
        return set.values.length;
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
    function at(Set storage set, uint256 index) internal view returns (bytes32) {
        require(set.values.length > index, "EnumSet: index out of bounds");
        return set.values[index];
    }
}


// File @animoca/ethereum-contracts-core-1.1.2/contracts/metatx/[email protected]

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


// File @animoca/ethereum-contracts-core-1.1.2/contracts/access/[email protected]

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


// File @animoca/ethereum-contracts-core-1.1.2/contracts/access/[email protected]

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


// File @animoca/ethereum-contracts-core-1.1.2/contracts/payment/[email protected]

pragma solidity >=0.7.6 <0.8.0;


/**
    @title PayoutWallet
    @dev adds support for a payout wallet
    Note: .
 */
abstract contract PayoutWallet is ManagedIdentity, Ownable {
    event PayoutWalletSet(address payoutWallet_);

    address payable public payoutWallet;

    constructor(address owner, address payable payoutWallet_) Ownable(owner) {
        require(payoutWallet_ != address(0), "Payout: zero address");
        payoutWallet = payoutWallet_;
        emit PayoutWalletSet(payoutWallet_);
    }

    function setPayoutWallet(address payable payoutWallet_) public {
        _requireOwnership(_msgSender());
        require(payoutWallet_ != address(0), "Payout: zero address");
        payoutWallet = payoutWallet_;
        emit PayoutWalletSet(payoutWallet);
    }
}


// File @animoca/ethereum-contracts-core-1.1.2/contracts/lifecycle/[email protected]

pragma solidity >=0.7.6 <0.8.0;

/**
 * Contract module which allows derived contracts to implement a mechanism for
 * activating, or 'starting', a contract.
 *
 * This module is used through inheritance. It will make available the modifiers
 * `whenNotStarted` and `whenStarted`, which can be applied to the functions of
 * your contract. Those functions will only be 'startable' once the modifiers
 * are put in place.
 */
abstract contract Startable is ManagedIdentity {
    event Started(address account);

    uint256 private _startedAt;

    /**
     * Modifier to make a function callable only when the contract has not started.
     */
    modifier whenNotStarted() {
        require(_startedAt == 0, "Startable: started");
        _;
    }

    /**
     * Modifier to make a function callable only when the contract has started.
     */
    modifier whenStarted() {
        require(_startedAt != 0, "Startable: not started");
        _;
    }

    /**
     * Constructor.
     */
    constructor() {}

    /**
     * Returns the timestamp when the contract entered the started state.
     * @return The timestamp when the contract entered the started state.
     */
    function startedAt() public view returns (uint256) {
        return _startedAt;
    }

    /**
     * Triggers the started state.
     * @dev Emits the Started event when the function is successfully called.
     */
    function _start() internal virtual whenNotStarted {
        _startedAt = block.timestamp;
        emit Started(_msgSender());
    }
}


// File @animoca/ethereum-contracts-core-1.1.2/contracts/lifecycle/[email protected]

pragma solidity >=0.7.6 <0.8.0;

/**
 * @dev Contract which allows children to implement pausability.
 */
abstract contract Pausable is ManagedIdentity {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool public paused;

    constructor(bool paused_) {
        paused = paused_;
    }

    function _requireNotPaused() internal view {
        require(!paused, "Pausable: paused");
    }

    function _requirePaused() internal view {
        require(paused, "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual {
        _requireNotPaused();
        paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual {
        _requirePaused();
        paused = false;
        emit Unpaused(_msgSender());
    }
}


// File @openzeppelin/contracts/math/[email protected]

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}


// File @animoca/ethereum-contracts-sale-2.0.0/contracts/sale/interfaces/[email protected]

pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ISale
 *
 * An interface for a contract which allows merchants to display products and customers to purchase them.
 *
 *  Products, designated as SKUs, are represented by bytes32 identifiers so that an identifier can carry an
 *  explicit name under the form of a fixed-length string. Each SKU can be priced via up to several payment
 *  tokens which can be ETH and/or ERC20(s). ETH token is represented by the magic value TOKEN_ETH, which means
 *  this value can be used as the 'token' argument of the purchase-related functions to indicate ETH payment.
 *
 *  The total available supply for a SKU is fixed at its creation. The magic value SUPPLY_UNLIMITED is used
 *  to represent a SKU with an infinite, never-decreasing supply. An optional purchase notifications receiver
 *  contract address can be set for a SKU at its creation: if the value is different from the zero address,
 *  the function `onPurchaseNotificationReceived` will be called on this address upon every purchase of the SKU.
 *
 *  This interface is designed to be consistent while managing a variety of implementation scenarios. It is
 *  also intended to be developer-friendly: all vital information is consistently deductible from the events
 *  (backend-oriented), as well as retrievable through calls to public functions (frontend-oriented).
 */
interface ISale {
    /**
     * Event emitted to notify about the magic values necessary for interfacing with this contract.
     * @param names An array of names for the magic values used by the contract.
     * @param values An array of values for the magic values used by the contract.
     */
    event MagicValues(bytes32[] names, bytes32[] values);

    /**
     * Event emitted to notify about the creation of a SKU.
     * @param sku The identifier of the created SKU.
     * @param totalSupply The initial total supply for sale.
     * @param maxQuantityPerPurchase The maximum allowed quantity for a single purchase.
     * @param notificationsReceiver If not the zero address, the address of a contract on which `onPurchaseNotificationReceived` will be called after
     *  each purchase. If this is the zero address, the call is not enabled.
     */
    event SkuCreation(bytes32 sku, uint256 totalSupply, uint256 maxQuantityPerPurchase, address notificationsReceiver);

    /**
     * Event emitted to notify about a change in the pricing of a SKU.
     * @dev `tokens` and `prices` arrays MUST have the same length.
     * @param sku The identifier of the updated SKU.
     * @param tokens An array of updated payment tokens. If empty, interpret as all payment tokens being disabled.
     * @param prices An array of updated prices for each of the payment tokens.
     *  Zero price values are used for payment tokens being disabled.
     */
    event SkuPricingUpdate(bytes32 indexed sku, address[] tokens, uint256[] prices);

    /**
     * Event emitted to notify about a purchase.
     * @param purchaser The initiater and buyer of the purchase.
     * @param recipient The recipient of the purchase.
     * @param token The token used as the currency for the payment.
     * @param sku The identifier of the purchased SKU.
     * @param quantity The purchased quantity.
     * @param userData Optional extra user input data.
     * @param totalPrice The amount of `token` paid.
     * @param extData Implementation-specific extra purchase data, such as
     *  details about discounts applied, conversion rates, purchase receipts, etc.
     */
    event Purchase(
        address indexed purchaser,
        address recipient,
        address indexed token,
        bytes32 indexed sku,
        uint256 quantity,
        bytes userData,
        uint256 totalPrice,
        bytes extData
    );

    /**
     * Returns the magic value used to represent the ETH payment token.
     * @dev MUST NOT be the zero address.
     * @return the magic value used to represent the ETH payment token.
     */
    // solhint-disable-next-line func-name-mixedcase
    function TOKEN_ETH() external pure returns (address);

    /**
     * Returns the magic value used to represent an infinite, never-decreasing SKU's supply.
     * @dev MUST NOT be zero.
     * @return the magic value used to represent an infinite, never-decreasing SKU's supply.
     */
    // solhint-disable-next-line func-name-mixedcase
    function SUPPLY_UNLIMITED() external pure returns (uint256);

    /**
     * Performs a purchase.
     * @dev Reverts if `recipient` is the zero address.
     * @dev Reverts if `token` is the address zero.
     * @dev Reverts if `quantity` is zero.
     * @dev Reverts if `quantity` is greater than the maximum purchase quantity.
     * @dev Reverts if `quantity` is greater than the remaining supply.
     * @dev Reverts if `sku` does not exist.
     * @dev Reverts if `sku` exists but does not have a price set for `token`.
     * @dev Emits the Purchase event.
     * @param recipient The recipient of the purchase.
     * @param token The token to use as the payment currency.
     * @param sku The identifier of the SKU to purchase.
     * @param quantity The quantity to purchase.
     * @param userData Optional extra user input data.
     */
    function purchaseFor(
        address payable recipient,
        address token,
        bytes32 sku,
        uint256 quantity,
        bytes calldata userData
    ) external payable;

    /**
     * Estimates the computed final total amount to pay for a purchase, including any potential discount.
     * @dev This function MUST compute the same price as `purchaseFor` would in identical conditions (same arguments, same point in time).
     * @dev If an implementer contract uses the `pricingData` field, it SHOULD document how to interpret the values.
     * @dev Reverts if `recipient` is the zero address.
     * @dev Reverts if `token` is the zero address.
     * @dev Reverts if `quantity` is zero.
     * @dev Reverts if `quantity` is greater than the maximum purchase quantity.
     * @dev Reverts if `quantity` is greater than the remaining supply.
     * @dev Reverts if `sku` does not exist.
     * @dev Reverts if `sku` exists but does not have a price set for `token`.
     * @param recipient The recipient of the purchase used to calculate the total price amount.
     * @param token The payment token used to calculate the total price amount.
     * @param sku The identifier of the SKU used to calculate the total price amount.
     * @param quantity The quantity used to calculate the total price amount.
     * @param userData Optional extra user input data.
     * @return totalPrice The computed total price to pay.
     * @return pricingData Implementation-specific extra pricing data, such as details about discounts applied.
     *  If not empty, the implementer MUST document how to interepret the values.
     */
    function estimatePurchase(
        address payable recipient,
        address token,
        bytes32 sku,
        uint256 quantity,
        bytes calldata userData
    ) external view returns (uint256 totalPrice, bytes32[] memory pricingData);

    /**
     * Returns the information relative to a SKU.
     * @dev WARNING: it is the responsibility of the implementer to ensure that the
     *  number of payment tokens is bounded, so that this function does not run out of gas.
     * @dev Reverts if `sku` does not exist.
     * @param sku The SKU identifier.
     * @return totalSupply The initial total supply for sale.
     * @return remainingSupply The remaining supply for sale.
     * @return maxQuantityPerPurchase The maximum allowed quantity for a single purchase.
     * @return notificationsReceiver The address of a contract on which to call the `onPurchaseNotificationReceived` function.
     * @return tokens The list of supported payment tokens.
     * @return prices The list of associated prices for each of the `tokens`.
     */
    function getSkuInfo(bytes32 sku)
        external
        view
        returns (
            uint256 totalSupply,
            uint256 remainingSupply,
            uint256 maxQuantityPerPurchase,
            address notificationsReceiver,
            address[] memory tokens,
            uint256[] memory prices
        );

    /**
     * Returns the list of created SKU identifiers.
     * @dev WARNING: it is the responsibility of the implementer to ensure that the
     *  number of SKUs is bounded, so that this function does not run out of gas.
     * @return skus the list of created SKU identifiers.
     */
    function getSkus() external view returns (bytes32[] memory skus);
}


// File @animoca/ethereum-contracts-sale-2.0.0/contracts/sale/interfaces/[email protected]

pragma solidity >=0.7.6 <0.8.0;

/**
 * @title IPurchaseNotificationsReceiver
 * Interface for any contract that wants to support purchase notifications from a Sale contract.
 */
interface IPurchaseNotificationsReceiver {
    /**
     * Handles the receipt of a purchase notification.
     * @dev This function MUST return the function selector, otherwise the caller will revert the transaction.
     *  The selector to be returned can be obtained as `this.onPurchaseNotificationReceived.selector`
     * @dev This function MAY throw.
     * @param purchaser The purchaser of the purchase.
     * @param recipient The recipient of the purchase.
     * @param token The token to use as the payment currency.
     * @param sku The identifier of the SKU to purchase.
     * @param quantity The quantity to purchase.
     * @param userData Optional extra user input data.
     * @param totalPrice The total price paid.
     * @param pricingData Implementation-specific extra pricing data, such as details about discounts applied.
     * @param paymentData Implementation-specific extra payment data, such as conversion rates.
     * @param deliveryData Implementation-specific extra delivery data, such as purchase receipts.
     * @return `bytes4(keccak256(
     *  "onPurchaseNotificationReceived(address,address,address,bytes32,uint256,bytes,uint256,bytes32[],bytes32[],bytes32[])"))`
     */
    function onPurchaseNotificationReceived(
        address purchaser,
        address recipient,
        address token,
        bytes32 sku,
        uint256 quantity,
        bytes calldata userData,
        uint256 totalPrice,
        bytes32[] calldata pricingData,
        bytes32[] calldata paymentData,
        bytes32[] calldata deliveryData
    ) external returns (bytes4);
}


// File @animoca/ethereum-contracts-sale-2.0.0/contracts/sale/abstract/[email protected]

pragma solidity >=0.7.6 <0.8.0;

/**
 * @title PurchaseLifeCycles
 * An abstract contract which define the life cycles for a purchase implementer.
 */
abstract contract PurchaseLifeCycles {
    /**
     * Wrapper for the purchase data passed as argument to the life cycle functions and down to their step functions.
     */
    struct PurchaseData {
        address payable purchaser;
        address payable recipient;
        address token;
        bytes32 sku;
        uint256 quantity;
        bytes userData;
        uint256 totalPrice;
        bytes32[] pricingData;
        bytes32[] paymentData;
        bytes32[] deliveryData;
    }

    /*                               Internal Life Cycle Functions                               */

    /**
     * `estimatePurchase` lifecycle.
     * @param purchase The purchase conditions.
     */
    function _estimatePurchase(PurchaseData memory purchase) internal view virtual returns (uint256 totalPrice, bytes32[] memory pricingData) {
        _validation(purchase);
        _pricing(purchase);

        totalPrice = purchase.totalPrice;
        pricingData = purchase.pricingData;
    }

    /**
     * `purchaseFor` lifecycle.
     * @param purchase The purchase conditions.
     */
    function _purchaseFor(PurchaseData memory purchase) internal virtual {
        _validation(purchase);
        _pricing(purchase);
        _payment(purchase);
        _delivery(purchase);
        _notification(purchase);
    }

    /*                            Internal Life Cycle Step Functions                             */

    /**
     * Lifecycle step which validates the purchase pre-conditions.
     * @dev Responsibilities:
     *  - Ensure that the purchase pre-conditions are met and revert if not.
     * @param purchase The purchase conditions.
     */
    function _validation(PurchaseData memory purchase) internal view virtual;

    /**
     * Lifecycle step which computes the purchase price.
     * @dev Responsibilities:
     *  - Computes the pricing formula, including any discount logic and price conversion;
     *  - Set the value of `purchase.totalPrice`;
     *  - Add any relevant extra data related to pricing in `purchase.pricingData` and document how to interpret it.
     * @param purchase The purchase conditions.
     */
    function _pricing(PurchaseData memory purchase) internal view virtual;

    /**
     * Lifecycle step which manages the transfer of funds from the purchaser.
     * @dev Responsibilities:
     *  - Ensure the payment reaches destination in the expected output token;
     *  - Handle any token swap logic;
     *  - Add any relevant extra data related to payment in `purchase.paymentData` and document how to interpret it.
     * @param purchase The purchase conditions.
     */
    function _payment(PurchaseData memory purchase) internal virtual;

    /**
     * Lifecycle step which delivers the purchased SKUs to the recipient.
     * @dev Responsibilities:
     *  - Ensure the product is delivered to the recipient, if that is the contract's responsibility.
     *  - Handle any internal logic related to the delivery, including the remaining supply update;
     *  - Add any relevant extra data related to delivery in `purchase.deliveryData` and document how to interpret it.
     * @param purchase The purchase conditions.
     */
    function _delivery(PurchaseData memory purchase) internal virtual;

    /**
     * Lifecycle step which notifies of the purchase.
     * @dev Responsibilities:
     *  - Manage after-purchase event(s) emission.
     *  - Handle calls to the notifications receiver contract's `onPurchaseNotificationReceived` function, if applicable.
     * @param purchase The purchase conditions.
     */
    function _notification(PurchaseData memory purchase) internal virtual;
}


// File @animoca/ethereum-contracts-sale-2.0.0/contracts/sale/abstract/[email protected]

pragma solidity >=0.7.6 <0.8.0;










/**
 * @title Sale
 * An abstract base sale contract with a minimal implementation of ISale and administration functions.
 *  A minimal implementation of the `_validation`, `_delivery` and `notification` life cycle step functions
 *  are provided, but the inheriting contract must implement `_pricing` and `_payment`.
 */
abstract contract Sale is PurchaseLifeCycles, ISale, PayoutWallet, Startable, Pausable {
    using AddressIsContract for address;
    using SafeMath for uint256;
    using EnumSet for EnumSet.Set;
    using EnumMap for EnumMap.Map;

    struct SkuInfo {
        uint256 totalSupply;
        uint256 remainingSupply;
        uint256 maxQuantityPerPurchase;
        address notificationsReceiver;
        EnumMap.Map prices;
    }

    address public constant override TOKEN_ETH = address(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
    uint256 public constant override SUPPLY_UNLIMITED = type(uint256).max;

    EnumSet.Set internal _skus;
    mapping(bytes32 => SkuInfo) internal _skuInfos;

    uint256 internal immutable _skusCapacity;
    uint256 internal immutable _tokensPerSkuCapacity;

    /**
     * Constructor.
     * @dev Emits the `MagicValues` event.
     * @dev Emits the `Paused` event.
     * @param payoutWallet_ the payout wallet.
     * @param skusCapacity the cap for the number of managed SKUs.
     * @param tokensPerSkuCapacity the cap for the number of tokens managed per SKU.
     */
    constructor(
        address payable payoutWallet_,
        uint256 skusCapacity,
        uint256 tokensPerSkuCapacity
    ) PayoutWallet(msg.sender, payoutWallet_) Pausable(true) {
        _skusCapacity = skusCapacity;
        _tokensPerSkuCapacity = tokensPerSkuCapacity;
        bytes32[] memory names = new bytes32[](2);
        bytes32[] memory values = new bytes32[](2);
        (names[0], values[0]) = ("TOKEN_ETH", bytes32(uint256(TOKEN_ETH)));
        (names[1], values[1]) = ("SUPPLY_UNLIMITED", bytes32(uint256(SUPPLY_UNLIMITED)));
        emit MagicValues(names, values);
    }

    /*                                   Public Admin Functions                                  */

    /**
     * Actvates, or 'starts', the contract.
     * @dev Emits the `Started` event.
     * @dev Emits the `Unpaused` event.
     * @dev Reverts if called by any other than the contract owner.
     * @dev Reverts if the contract has already been started.
     * @dev Reverts if the contract is not paused.
     */
    function start() public virtual {
        _requireOwnership(_msgSender());
        _start();
        _unpause();
    }

    /**
     * Pauses the contract.
     * @dev Emits the `Paused` event.
     * @dev Reverts if called by any other than the contract owner.
     * @dev Reverts if the contract has not been started yet.
     * @dev Reverts if the contract is already paused.
     */
    function pause() public virtual whenStarted {
        _requireOwnership(_msgSender());
        _pause();
    }

    /**
     * Resumes the contract.
     * @dev Emits the `Unpaused` event.
     * @dev Reverts if called by any other than the contract owner.
     * @dev Reverts if the contract has not been started yet.
     * @dev Reverts if the contract is not paused.
     */
    function unpause() public virtual whenStarted {
        _requireOwnership(_msgSender());
        _unpause();
    }

    /**
     * Sets the token prices for the specified product SKU.
     * @dev Reverts if called by any other than the contract owner.
     * @dev Reverts if `tokens` and `prices` have different lengths.
     * @dev Reverts if `sku` does not exist.
     * @dev Reverts if one of the `tokens` is the zero address.
     * @dev Reverts if the update results in too many tokens for the SKU.
     * @dev Emits the `SkuPricingUpdate` event.
     * @param sku The identifier of the SKU.
     * @param tokens The list of payment tokens to update.
     *  If empty, disable all the existing payment tokens.
     * @param prices The list of prices to apply for each payment token.
     *  Zero price values are used to disable a payment token.
     */
    function updateSkuPricing(
        bytes32 sku,
        address[] memory tokens,
        uint256[] memory prices
    ) public virtual {
        _requireOwnership(_msgSender());
        uint256 length = tokens.length;
        require(length == prices.length, "Sale: inconsistent arrays");
        SkuInfo storage skuInfo = _skuInfos[sku];
        require(skuInfo.totalSupply != 0, "Sale: non-existent sku");

        EnumMap.Map storage tokenPrices = skuInfo.prices;
        if (length == 0) {
            uint256 currentLength = tokenPrices.length();
            for (uint256 i = 0; i < currentLength; ++i) {
                // TODO add a clear function in EnumMap and EnumSet and use it
                (bytes32 token, ) = tokenPrices.at(0);
                tokenPrices.remove(token);
            }
        } else {
            _setTokenPrices(tokenPrices, tokens, prices);
        }

        emit SkuPricingUpdate(sku, tokens, prices);
    }

    /*                                   ISale Public Functions                                  */

    /**
     * Performs a purchase.
     * @dev Reverts if the sale has not started.
     * @dev Reverts if the sale is paused.
     * @dev Reverts if `recipient` is the zero address.
     * @dev Reverts if `token` is the zero address.
     * @dev Reverts if `quantity` is zero.
     * @dev Reverts if `quantity` is greater than the maximum purchase quantity.
     * @dev Reverts if `quantity` is greater than the remaining supply.
     * @dev Reverts if `sku` does not exist.
     * @dev Reverts if `sku` exists but does not have a price set for `token`.
     * @dev Emits the Purchase event.
     * @param recipient The recipient of the purchase.
     * @param token The token to use as the payment currency.
     * @param sku The identifier of the SKU to purchase.
     * @param quantity The quantity to purchase.
     * @param userData Optional extra user input data.
     */
    function purchaseFor(
        address payable recipient,
        address token,
        bytes32 sku,
        uint256 quantity,
        bytes calldata userData
    ) external payable virtual override whenStarted {
        _requireNotPaused();
        PurchaseData memory purchase;
        purchase.purchaser = _msgSender();
        purchase.recipient = recipient;
        purchase.token = token;
        purchase.sku = sku;
        purchase.quantity = quantity;
        purchase.userData = userData;

        _purchaseFor(purchase);
    }

    /**
     * Estimates the computed final total amount to pay for a purchase, including any potential discount.
     * @dev This function MUST compute the same price as `purchaseFor` would in identical conditions (same arguments, same point in time).
     * @dev If an implementer contract uses the `pricingData` field, it SHOULD document how to interpret the values.
     * @dev Reverts if the sale has not started.
     * @dev Reverts if the sale is paused.
     * @dev Reverts if `recipient` is the zero address.
     * @dev Reverts if `token` is the zero address.
     * @dev Reverts if `quantity` is zero.
     * @dev Reverts if `quantity` is greater than the maximum purchase quantity.
     * @dev Reverts if `quantity` is greater than the remaining supply.
     * @dev Reverts if `sku` does not exist.
     * @dev Reverts if `sku` exists but does not have a price set for `token`.
     * @param recipient The recipient of the purchase used to calculate the total price amount.
     * @param token The payment token used to calculate the total price amount.
     * @param sku The identifier of the SKU used to calculate the total price amount.
     * @param quantity The quantity used to calculate the total price amount.
     * @param userData Optional extra user input data.
     * @return totalPrice The computed total price.
     * @return pricingData Implementation-specific extra pricing data, such as details about discounts applied.
     *  If not empty, the implementer MUST document how to interepret the values.
     */
    function estimatePurchase(
        address payable recipient,
        address token,
        bytes32 sku,
        uint256 quantity,
        bytes calldata userData
    ) external view virtual override whenStarted returns (uint256 totalPrice, bytes32[] memory pricingData) {
        _requireNotPaused();
        PurchaseData memory purchase;
        purchase.purchaser = _msgSender();
        purchase.recipient = recipient;
        purchase.token = token;
        purchase.sku = sku;
        purchase.quantity = quantity;
        purchase.userData = userData;

        return _estimatePurchase(purchase);
    }

    /**
     * Returns the information relative to a SKU.
     * @dev WARNING: it is the responsibility of the implementer to ensure that the
     * number of payment tokens is bounded, so that this function does not run out of gas.
     * @dev Reverts if `sku` does not exist.
     * @param sku The SKU identifier.
     * @return totalSupply The initial total supply for sale.
     * @return remainingSupply The remaining supply for sale.
     * @return maxQuantityPerPurchase The maximum allowed quantity for a single purchase.
     * @return notificationsReceiver The address of a contract on which to call the `onPurchaseNotificationReceived` function.
     * @return tokens The list of supported payment tokens.
     * @return prices The list of associated prices for each of the `tokens`.
     */
    function getSkuInfo(bytes32 sku)
        external
        view
        override
        returns (
            uint256 totalSupply,
            uint256 remainingSupply,
            uint256 maxQuantityPerPurchase,
            address notificationsReceiver,
            address[] memory tokens,
            uint256[] memory prices
        )
    {
        SkuInfo storage skuInfo = _skuInfos[sku];
        uint256 length = skuInfo.prices.length();

        totalSupply = skuInfo.totalSupply;
        require(totalSupply != 0, "Sale: non-existent sku");
        remainingSupply = skuInfo.remainingSupply;
        maxQuantityPerPurchase = skuInfo.maxQuantityPerPurchase;
        notificationsReceiver = skuInfo.notificationsReceiver;

        tokens = new address[](length);
        prices = new uint256[](length);
        for (uint256 i = 0; i < length; ++i) {
            (bytes32 token, bytes32 price) = skuInfo.prices.at(i);
            tokens[i] = address(uint256(token));
            prices[i] = uint256(price);
        }
    }

    /**
     * Returns the list of created SKU identifiers.
     * @return skus the list of created SKU identifiers.
     */
    function getSkus() external view override returns (bytes32[] memory skus) {
        skus = _skus.values;
    }

    /*                               Internal Utility Functions                                  */

    /**
     * Creates an SKU.
     * @dev Reverts if `totalSupply` is zero.
     * @dev Reverts if `sku` already exists.
     * @dev Reverts if `notificationsReceiver` is not the zero address and is not a contract address.
     * @dev Reverts if the update results in too many SKUs.
     * @dev Emits the `SkuCreation` event.
     * @param sku the SKU identifier.
     * @param totalSupply the initial total supply.
     * @param maxQuantityPerPurchase The maximum allowed quantity for a single purchase.
     * @param notificationsReceiver The purchase notifications receiver contract address.
     *  If set to the zero address, the notification is not enabled.
     */
    function _createSku(
        bytes32 sku,
        uint256 totalSupply,
        uint256 maxQuantityPerPurchase,
        address notificationsReceiver
    ) internal virtual {
        require(totalSupply != 0, "Sale: zero supply");
        require(_skus.length() < _skusCapacity, "Sale: too many skus");
        require(_skus.add(sku), "Sale: sku already created");
        if (notificationsReceiver != address(0)) {
            require(notificationsReceiver.isContract(), "Sale: non-contract receiver");
        }
        SkuInfo storage skuInfo = _skuInfos[sku];
        skuInfo.totalSupply = totalSupply;
        skuInfo.remainingSupply = totalSupply;
        skuInfo.maxQuantityPerPurchase = maxQuantityPerPurchase;
        skuInfo.notificationsReceiver = notificationsReceiver;
        emit SkuCreation(sku, totalSupply, maxQuantityPerPurchase, notificationsReceiver);
    }

    /**
     * Updates SKU token prices.
     * @dev Reverts if one of the `tokens` is the zero address.
     * @dev Reverts if the update results in too many tokens for the SKU.
     * @param tokenPrices Storage pointer to a mapping of SKU token prices to update.
     * @param tokens The list of payment tokens to update.
     * @param prices The list of prices to apply for each payment token.
     *  Zero price values are used to disable a payment token.
     */
    function _setTokenPrices(
        EnumMap.Map storage tokenPrices,
        address[] memory tokens,
        uint256[] memory prices
    ) internal virtual {
        for (uint256 i = 0; i < tokens.length; ++i) {
            address token = tokens[i];
            require(token != address(0), "Sale: zero address token");
            uint256 price = prices[i];
            if (price == 0) {
                tokenPrices.remove(bytes32(uint256(token)));
            } else {
                tokenPrices.set(bytes32(uint256(token)), bytes32(price));
            }
        }
        require(tokenPrices.length() <= _tokensPerSkuCapacity, "Sale: too many tokens");
    }

    /*                            Internal Life Cycle Step Functions                             */

    /**
     * Lifecycle step which validates the purchase pre-conditions.
     * @dev Responsibilities:
     *  - Ensure that the purchase pre-conditions are met and revert if not.
     * @dev Reverts if `purchase.recipient` is the zero address.
     * @dev Reverts if `purchase.token` is the zero address.
     * @dev Reverts if `purchase.quantity` is zero.
     * @dev Reverts if `purchase.quantity` is greater than the SKU's `maxQuantityPerPurchase`.
     * @dev Reverts if `purchase.quantity` is greater than the available supply.
     * @dev Reverts if `purchase.sku` does not exist.
     * @dev Reverts if `purchase.sku` exists but does not have a price set for `purchase.token`.
     * @dev If this function is overriden, the implementer SHOULD super call this before.
     * @param purchase The purchase conditions.
     */
    function _validation(PurchaseData memory purchase) internal view virtual override {
        require(purchase.recipient != address(0), "Sale: zero address recipient");
        require(purchase.token != address(0), "Sale: zero address token");
        require(purchase.quantity != 0, "Sale: zero quantity purchase");
        SkuInfo storage skuInfo = _skuInfos[purchase.sku];
        require(skuInfo.totalSupply != 0, "Sale: non-existent sku");
        require(skuInfo.maxQuantityPerPurchase >= purchase.quantity, "Sale: above max quantity");
        if (skuInfo.totalSupply != SUPPLY_UNLIMITED) {
            require(skuInfo.remainingSupply >= purchase.quantity, "Sale: insufficient supply");
        }
        bytes32 priceKey = bytes32(uint256(purchase.token));
        require(skuInfo.prices.contains(priceKey), "Sale: non-existent sku token");
    }

    /**
     * Lifecycle step which delivers the purchased SKUs to the recipient.
     * @dev Responsibilities:
     *  - Ensure the product is delivered to the recipient, if that is the contract's responsibility.
     *  - Handle any internal logic related to the delivery, including the remaining supply update;
     *  - Add any relevant extra data related to delivery in `purchase.deliveryData` and document how to interpret it.
     * @dev Reverts if there is not enough available supply.
     * @dev If this function is overriden, the implementer SHOULD super call it.
     * @param purchase The purchase conditions.
     */
    function _delivery(PurchaseData memory purchase) internal virtual override {
        SkuInfo storage skuInfo = _skuInfos[purchase.sku];
        if (skuInfo.totalSupply != SUPPLY_UNLIMITED) {
            _skuInfos[purchase.sku].remainingSupply = skuInfo.remainingSupply.sub(purchase.quantity);
        }
    }

    /**
     * Lifecycle step which notifies of the purchase.
     * @dev Responsibilities:
     *  - Manage after-purchase event(s) emission.
     *  - Handle calls to the notifications receiver contract's `onPurchaseNotificationReceived` function, if applicable.
     * @dev Reverts if `onPurchaseNotificationReceived` throws or returns an incorrect value.
     * @dev Emits the `Purchase` event. The values of `purchaseData` are the concatenated values of `priceData`, `paymentData`
     * and `deliveryData`. If not empty, the implementer MUST document how to interpret these values.
     * @dev If this function is overriden, the implementer SHOULD super call it.
     * @param purchase The purchase conditions.
     */
    function _notification(PurchaseData memory purchase) internal virtual override {
        emit Purchase(
            purchase.purchaser,
            purchase.recipient,
            purchase.token,
            purchase.sku,
            purchase.quantity,
            purchase.userData,
            purchase.totalPrice,
            abi.encodePacked(purchase.pricingData, purchase.paymentData, purchase.deliveryData)
        );

        address notificationsReceiver = _skuInfos[purchase.sku].notificationsReceiver;
        if (notificationsReceiver != address(0)) {
            require(
                IPurchaseNotificationsReceiver(notificationsReceiver).onPurchaseNotificationReceived(
                    purchase.purchaser,
                    purchase.recipient,
                    purchase.token,
                    purchase.sku,
                    purchase.quantity,
                    purchase.userData,
                    purchase.totalPrice,
                    purchase.pricingData,
                    purchase.paymentData,
                    purchase.deliveryData
                ) == IPurchaseNotificationsReceiver(address(0)).onPurchaseNotificationReceived.selector, // TODO precompute return value
                "Sale: notification refused"
            );
        }
    }
}


// File @animoca/ethereum-contracts-sale-2.0.0/contracts/sale/[email protected]

pragma solidity >=0.7.6 <0.8.0;


/**
 * @title FixedPricesSale
 * An Sale which implements a fixed prices strategy.
 *  The final implementer is responsible for implementing any additional pricing and/or delivery logic.
 */
abstract contract FixedPricesSale is Sale {
    using ERC20Wrapper for IWrappedERC20;
    using SafeMath for uint256;
    using EnumMap for EnumMap.Map;

    /**
     * Constructor.
     * @dev Emits the `MagicValues` event.
     * @dev Emits the `Paused` event.
     * @param payoutWallet_ the payout wallet.
     * @param skusCapacity the cap for the number of managed SKUs.
     * @param tokensPerSkuCapacity the cap for the number of tokens managed per SKU.
     */
    constructor(
        address payable payoutWallet_,
        uint256 skusCapacity,
        uint256 tokensPerSkuCapacity
    ) Sale(payoutWallet_, skusCapacity, tokensPerSkuCapacity) {}

    /*                               Internal Life Cycle Functions                               */

    /**
     * Lifecycle step which computes the purchase price.
     * @dev Responsibilities:
     *  - Computes the pricing formula, including any discount logic and price conversion;
     *  - Set the value of `purchase.totalPrice`;
     *  - Add any relevant extra data related to pricing in `purchase.pricingData` and document how to interpret it.
     * @dev Reverts if `purchase.sku` does not exist.
     * @dev Reverts if `purchase.token` is not supported by the SKU.
     * @dev Reverts in case of price overflow.
     * @param purchase The purchase conditions.
     */
    function _pricing(PurchaseData memory purchase) internal view virtual override {
        SkuInfo storage skuInfo = _skuInfos[purchase.sku];
        require(skuInfo.totalSupply != 0, "Sale: unsupported SKU");
        EnumMap.Map storage prices = skuInfo.prices;
        uint256 unitPrice = _unitPrice(purchase, prices);
        purchase.totalPrice = unitPrice.mul(purchase.quantity);
    }

    /**
     * Lifecycle step which manages the transfer of funds from the purchaser.
     * @dev Responsibilities:
     *  - Ensure the payment reaches destination in the expected output token;
     *  - Handle any token swap logic;
     *  - Add any relevant extra data related to payment in `purchase.paymentData` and document how to interpret it.
     * @dev Reverts in case of payment failure.
     * @param purchase The purchase conditions.
     */
    function _payment(PurchaseData memory purchase) internal virtual override {
        if (purchase.token == TOKEN_ETH) {
            require(msg.value >= purchase.totalPrice, "Sale: insufficient ETH");

            payoutWallet.transfer(purchase.totalPrice);

            uint256 change = msg.value.sub(purchase.totalPrice);

            if (change != 0) {
                purchase.purchaser.transfer(change);
            }
        } else {
            IWrappedERC20(purchase.token).wrappedTransferFrom(_msgSender(), payoutWallet, purchase.totalPrice);
        }
    }

    /*                               Internal Utility Functions                                  */

    /**
     * Retrieves the unit price of a SKU for the specified payment token.
     * @dev Reverts if the specified payment token is unsupported.
     * @param purchase The purchase conditions specifying the payment token with which the unit price will be retrieved.
     * @param prices Storage pointer to a mapping of SKU token prices to retrieve the unit price from.
     * @return unitPrice The unit price of a SKU for the specified payment token.
     */
    function _unitPrice(PurchaseData memory purchase, EnumMap.Map storage prices) internal view virtual returns (uint256 unitPrice) {
        unitPrice = uint256(prices.get(bytes32(uint256(purchase.token))));
        require(unitPrice != 0, "Sale: unsupported payment token");
    }
}


// File @animoca/ethereum-contracts-core-1.1.2/contracts/utils/[email protected]

pragma solidity >=0.7.6 <0.8.0;



abstract contract Recoverable is ManagedIdentity, Ownable {
    using ERC20Wrapper for IWrappedERC20;

    /**
     * Extract ERC20 tokens which were accidentally sent to the contract to a list of accounts.
     * Warning: this function should be overriden for contracts which are supposed to hold ERC20 tokens
     * so that the extraction is limited to only amounts sent accidentally.
     * @dev Reverts if the sender is not the contract owner.
     * @dev Reverts if `accounts`, `tokens` and `amounts` do not have the same length.
     * @dev Reverts if one of `tokens` is does not implement the ERC20 transfer function.
     * @dev Reverts if one of the ERC20 transfers fail for any reason.
     * @param accounts the list of accounts to transfer the tokens to.
     * @param tokens the list of ERC20 token addresses.
     * @param amounts the list of token amounts to transfer.
     */
    function recoverERC20s(
        address[] calldata accounts,
        address[] calldata tokens,
        uint256[] calldata amounts
    ) external virtual {
        _requireOwnership(_msgSender());
        uint256 length = accounts.length;
        require(length == tokens.length && length == amounts.length, "Recov: inconsistent arrays");
        for (uint256 i = 0; i != length; ++i) {
            IWrappedERC20(tokens[i]).wrappedTransfer(accounts[i], amounts[i]);
        }
    }

    /**
     * Extract ERC721 tokens which were accidentally sent to the contract to a list of accounts.
     * Warning: this function should be overriden for contracts which are supposed to hold ERC721 tokens
     * so that the extraction is limited to only tokens sent accidentally.
     * @dev Reverts if the sender is not the contract owner.
     * @dev Reverts if `accounts`, `contracts` and `amounts` do not have the same length.
     * @dev Reverts if one of `contracts` is does not implement the ERC721 transferFrom function.
     * @dev Reverts if one of the ERC721 transfers fail for any reason.
     * @param accounts the list of accounts to transfer the tokens to.
     * @param contracts the list of ERC721 contract addresses.
     * @param tokenIds the list of token ids to transfer.
     */
    function recoverERC721s(
        address[] calldata accounts,
        address[] calldata contracts,
        uint256[] calldata tokenIds
    ) external virtual {
        _requireOwnership(_msgSender());
        uint256 length = accounts.length;
        require(length == contracts.length && length == tokenIds.length, "Recov: inconsistent arrays");
        for (uint256 i = 0; i != length; ++i) {
            IRecoverableERC721(contracts[i]).transferFrom(address(this), accounts[i], tokenIds[i]);
        }
    }
}

interface IRecoverableERC721 {
    /// See {IERC721-transferFrom(address,address,uint256)}
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}


// File contracts/sale/TokenLaunchpadVoucherPacksSale.sol

pragma solidity >=0.7.6 <0.8.0;


/**
 * @title TokenLaunchpad Vouchers Sale
 * A FixedPricesSale contract that handles the purchase and delivery of TokenLaunchpad vouchers.
 */
contract TokenLaunchpadVoucherPacksSale is FixedPricesSale, Recoverable {
    IVouchersContract public immutable vouchersContract;

    struct SkuAdditionalInfo {
        uint256[] tokenIds;
        uint256 startTimestamp;
        uint256 endTimestamp;
    }

    mapping(bytes32 => SkuAdditionalInfo) internal _skuAdditionalInfo;

    /**
     * Constructor.
     * @dev Emits the `MagicValues` event.
     * @dev Emits the `Paused` event.
     * @param vouchersContract_ The inventory contract from which the sale supply is attributed from.
     * @param payoutWallet the payout wallet.
     * @param skusCapacity the cap for the number of managed SKUs.
     * @param tokensPerSkuCapacity the cap for the number of tokens managed per SKU.
     */
    constructor(
        IVouchersContract vouchersContract_,
        address payable payoutWallet,
        uint256 skusCapacity,
        uint256 tokensPerSkuCapacity
    ) FixedPricesSale(payoutWallet, skusCapacity, tokensPerSkuCapacity) {
        vouchersContract = vouchersContract_;
    }

    /**
     * Creates an SKU.
     * @dev Reverts if `totalSupply` is zero.
     * @dev Reverts if `sku` already exists.
     * @dev Reverts if the update results in too many SKUs.
     * @dev Reverts if one of `tokenIds` is not a fungible token identifier.
     * @dev Emits the `SkuCreation` event.
     * @param sku The SKU identifier.
     * @param totalSupply The initial total supply.
     * @param maxQuantityPerPurchase The maximum allowed quantity for a single purchase.
     * @param tokenIds The inventory contract token IDs to associate with the SKU, used for purchase delivery.
     * @param startTimestamp The start timestamp of the sale.
     * @param endTimestamp The end timestamp of the sale, or zero to indicate there is no end.
     */
    function createSku(
        bytes32 sku,
        uint256 totalSupply,
        uint256 maxQuantityPerPurchase,
        uint256[] calldata tokenIds,
        uint256 startTimestamp,
        uint256 endTimestamp
    ) external {
        _requireOwnership(_msgSender());
        uint256 length = tokenIds.length;
        require(length != 0, "Sale: empty tokens");
        for (uint256 i; i != length; ++i) {
            require(vouchersContract.isFungible(tokenIds[i]), "Sale: not a fungible token");
        }
        _skuAdditionalInfo[sku] = SkuAdditionalInfo(tokenIds, startTimestamp, endTimestamp);
        _createSku(sku, totalSupply, maxQuantityPerPurchase, address(0));
    }

    /**
     * Updates start and end timestamps of a SKU.
     * @dev Reverts if not sent by the contract owner.
     * @dev Reverts if the SKU does not exist.
     * @param sku the SKU identifier.
     * @param startTimestamp The start timestamp of the sale.
     * @param endTimestamp The end timestamp of the sale, or zero to indicate there is no end.
     */
    function updateSkuTimestamps(
        bytes32 sku,
        uint256 startTimestamp,
        uint256 endTimestamp
    ) external {
        _requireOwnership(_msgSender());
        require(_skuInfos[sku].totalSupply != 0, "Sale: non-existent sku");
        SkuAdditionalInfo storage info = _skuAdditionalInfo[sku];
        info.startTimestamp = startTimestamp;
        info.endTimestamp = endTimestamp;
    }

    /**
     * Gets the additional sku info.
     * @dev Reverts if the SKU does not exist.
     * @param sku the SKU identifier.
     * @return tokenIds The identifiers of the tokens delivered via this SKU.
     * @return startTimestamp The start timestamp of the SKU sale.
     * @return endTimestamp The end timestamp of the SKU sale (zero if there is no end).
     */
    function getSkuAdditionalInfo(bytes32 sku)
        external
        view
        returns (
            uint256[] memory tokenIds,
            uint256 startTimestamp,
            uint256 endTimestamp
        )
    {
        require(_skuInfos[sku].totalSupply != 0, "Sale: non-existent sku");
        SkuAdditionalInfo memory info = _skuAdditionalInfo[sku];
        return (info.tokenIds, info.startTimestamp, info.endTimestamp);
    }

    /**
     * Returns whether a SKU is currently within the sale time range.
     * @dev Reverts if the SKU does not exist.
     * @param sku the SKU identifier.
     * @return true if `sku` is currently within the sale time range, false otherwise.
     */
    function canPurchaseSku(bytes32 sku) external view returns (bool) {
        require(_skuInfos[sku].totalSupply != 0, "Sale: non-existent sku");
        SkuAdditionalInfo memory info = _skuAdditionalInfo[sku];
        return block.timestamp > info.startTimestamp && (info.endTimestamp == 0 || block.timestamp < info.endTimestamp);
    }

    /// @inheritdoc Sale
    function _delivery(PurchaseData memory purchase) internal override {
        super._delivery(purchase);
        SkuAdditionalInfo memory info = _skuAdditionalInfo[purchase.sku];
        uint256 startTimestamp = info.startTimestamp;
        uint256 endTimestamp = info.endTimestamp;
        require(block.timestamp > startTimestamp, "Sale: not started yet");
        require(endTimestamp == 0 || block.timestamp < endTimestamp, "Sale: already ended");

        uint256 length = info.tokenIds.length;
        if (length == 1) {
            vouchersContract.safeMint(purchase.recipient, info.tokenIds[0], purchase.quantity, "");
        } else {
            uint256 purchaseQuantity = purchase.quantity;
            uint256[] memory quantities = new uint256[](length);
            for (uint256 i; i != length; ++i) {
                quantities[i] = purchaseQuantity;
            }
            vouchersContract.safeBatchMint(purchase.recipient, info.tokenIds, quantities, "");
        }
    }
}

interface IVouchersContract {
    function isFungible(uint256 id) external pure returns (bool);

    function safeMint(
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external;

    function safeBatchMint(
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external;
}