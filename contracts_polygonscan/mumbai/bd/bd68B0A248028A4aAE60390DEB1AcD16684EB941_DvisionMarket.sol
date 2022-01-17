/**
 *Submitted for verification at polygonscan.com on 2022-01-17
*/

// File: github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/utils/ReentrancyGuard.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/token/ERC20/IERC20.sol



pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// File: github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/utils/Strings.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// File: github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/utils/EnumerableMap.sol



pragma solidity >=0.6.0 <0.8.0;

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
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
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
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        return _get(map, key, "EnumerableMap: nonexistent key");
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint256(value)));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key), errorMessage)));
    }
}

// File: github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/math/SafeMath.sol



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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/token/ERC721/IERC721Receiver.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// File: github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/token/ERC721/ERC721Holder.sol



pragma solidity >=0.6.0 <0.8.0;


  /**
   * @dev Implementation of the {IERC721Receiver} interface.
   *
   * Accepts all token transfers. 
   * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
   */
contract ERC721Holder is IERC721Receiver {

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// File: github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/GSN/Context.sol



pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/utils/Pausable.sol



pragma solidity >=0.6.0 <0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/utils/Address.sol



pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/utils/EnumerableSet.sol



pragma solidity >=0.6.0 <0.8.0;

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
library EnumerableSet {
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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
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
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
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
        return address(uint256(_at(set._inner, index)));
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

// File: github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/access/AccessControl.sol



pragma solidity >=0.6.0 <0.8.0;




/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// File: github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/introspection/IERC165.sol



pragma solidity >=0.6.0 <0.8.0;

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

// File: github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/token/ERC1155/IERC1155Receiver.sol



pragma solidity >=0.6.0 <0.8.0;


/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// File: github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/introspection/ERC165.sol



pragma solidity >=0.6.0 <0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// File: github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/token/ERC1155/ERC1155Receiver.sol



pragma solidity >=0.6.0 <0.8.0;



/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    constructor() internal {
        _registerInterface(
            ERC1155Receiver(0).onERC1155Received.selector ^
            ERC1155Receiver(0).onERC1155BatchReceived.selector
        );
    }
}

// File: github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/token/ERC1155/ERC1155Holder.sol



pragma solidity >=0.6.0 <0.8.0;


/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// File: github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/token/ERC1155/IERC1155.sol



pragma solidity >=0.6.2 <0.8.0;


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// File: github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/token/ERC1155/IERC1155MetadataURI.sol



pragma solidity >=0.6.2 <0.8.0;


/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// File: github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/token/ERC1155/ERC1155.sol



pragma solidity >=0.6.0 <0.8.0;








/**
 *
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using SafeMath for uint256;
    using Address for address;

    // Mapping from token ID to account balances
    mapping (uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping (address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /*
     *     bytes4(keccak256('balanceOf(address,uint256)')) == 0x00fdd58e
     *     bytes4(keccak256('balanceOfBatch(address[],uint256[])')) == 0x4e1273f4
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,uint256,bytes)')) == 0xf242432a
     *     bytes4(keccak256('safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)')) == 0x2eb2c2d6
     *
     *     => 0x00fdd58e ^ 0x4e1273f4 ^ 0xa22cb465 ^
     *        0xe985e9c5 ^ 0xf242432a ^ 0x2eb2c2d6 == 0xd9b67a26
     */
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    /*
     *     bytes4(keccak256('uri(uint256)')) == 0x0e89341c
     */
    bytes4 private constant _INTERFACE_ID_ERC1155_METADATA_URI = 0x0e89341c;

    /**
     * @dev See {_setURI}.
     */
    constructor (string memory uri_) public {
        _setURI(uri_);

        // register the supported interfaces to conform to ERC1155 via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155);

        // register the supported interfaces to conform to ERC1155MetadataURI via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155_METADATA_URI);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) external view override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    )
        public
        view
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            require(accounts[i] != address(0), "ERC1155: batch balance query for the zero address");
            batchBalances[i] = _balances[ids[i]][accounts[i]];
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][from] = _balances[id][from].sub(amount, "ERC1155: insufficient balance for transfer");
        _balances[id][to] = _balances[id][to].add(amount);

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            _balances[id][from] = _balances[id][from].sub(
                amount,
                "ERC1155: insufficient balance for transfer"
            );
            _balances[id][to] = _balances[id][to].add(amount);
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] = _balances[id][account].add(amount);
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] = amounts[i].add(_balances[ids[i]][to]);
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(address account, uint256 id, uint256 amount) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        _balances[id][account] = _balances[id][account].sub(
            amount,
            "ERC1155: burn amount exceeds balance"
        );

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][account] = _balances[ids[i]][account].sub(
                amounts[i],
                "ERC1155: burn amount exceeds balance"
            );
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal virtual
    { }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// File: contracts/Dvision1155Dvi.sol


pragma solidity ^0.6.12;









contract Dvision1155Dvi is ERC1155, ERC1155Holder, AccessControl, ReentrancyGuard
{   
    using Strings for string;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;
    
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    
    uint private _currentTokenId;
    uint private _currentOrderId;
    uint private _currentSaleAmount;
    // uint private _currentUserId;
    
    address payable public feeAddr;
    uint256 public feePercent;
    uint256 public feeOnMint;
    
    IERC20 public currencyToken;

    mapping(uint => bool) public _itemExists;
    mapping(address => mapping(uint256 => uint256)) public _items;// mapping(address => mapping(uint => Item)) public _items;
    mapping(uint => uint256) public _itemSupply;
    mapping(uint => Order) public _itemForSale;    
    // mapping(uint=>address) public _tokenUsers;
    mapping(address => EnumerableSet.UintSet) private _ownedToken;

    // struct Item 
    // { 
    //     uint256 amount;
    //     uint256 orderId;
    // }
    
    struct Order
    {
        address seller;
        uint256 tokenId;
        uint256 price;
        uint256 currency;
        uint256 sellAmount;
        bool forSale;
    }
    
    event TokenChange(address indexed _old, address indexed _new);
    event ItemSelled(uint256 _tokenId);
    event CancelItemSelled(uint256 _tokenId, uint256 _cancelAmount);
    event MintEvent(uint256 _tokenId);    
    event FeeAddressChange(address indexed _new);
    event FeePercentChange(uint256 _percent);
    event FeeOnMintChange(uint256 _fee);    
    // event SetUser(address indexed _new);
    event URIChange(string _new);
    
    modifier onlyManager{
        require(hasRole(MANAGER_ROLE, msg.sender), "You are not manager.");
        _;
    }
    
    constructor(address _erc20, address payable _feeAddr, string memory _uri) 
    ERC1155("DVI 1155") ERC1155Holder() ReentrancyGuard() public 
    {
        require(_erc20 != address(0), "_erc20 is a zero address.");
        require(_feeAddr != address(0), "_feeAddr is a zero address.");
        
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        
        currencyToken = IERC20(_erc20);
        feeAddr = _feeAddr;
        _setURI(_uri);
    }
    
    
    function set20Token(
        address _new
    ) onlyManager external 
    {
        require(_new != address(0) ,"_new is a zero address.");
        
        emit TokenChange(address(currencyToken), _new);
        currencyToken = IERC20(_new);
    }
        
    function setURI(
        string memory _newURI
    ) onlyManager external 
    {
        emit URIChange(_newURI);
       _setURI(_newURI);
    }
    
    function mint(
        uint256 _amount
    ) external payable returns(uint256)
    {
        require(_amount > 0, "ERC1155 : Amount of token to create must be bigger than 0");
        require(msg.value >= feeOnMint, "fee is not enough");
        
        // Item memory _item = Item({
        //     amount : _amount,
        //     orderId : 0
        // });
        
        uint _id = _getNextTokenId();
        _mint(msg.sender, _id, _amount, "");
        
        _incrementTokenId();
        
        _items[msg.sender][_id] = 0; //_item;
        _itemExists[_id] = true;        
        _itemSupply[_id] = _amount;
        
        // this.setUser(msg.sender);
        
        feeAddr.transfer(msg.value);
        
        emit MintEvent(_id);
        return (_id);
    }
    
    function mintTo(
        address _to, 
        uint256 _amount
    ) onlyManager external returns(uint256)
    {
        require(_amount > 0, "ERC1155 : Amount of token to create must be bigger than 0.");
        
        // Item memory _item = Item({
        //     amount : _amount,
        //     orderId : 0
        // });
        
        uint _id = _getNextTokenId();
        _mint(_to, _id, _amount, "");
        
        _incrementTokenId();
        
        _items[_to][_id] = 0;//_item;
        _itemExists[_id] = true;
        _itemSupply[_id] = _amount;
        
        // this.setUser(_to);
        
        emit MintEvent(_id);
        return (_id);
    }
    
    function _getNextTokenId() private view returns (uint256) 
    {
        return _currentTokenId.add(1);
    }    
    function _incrementTokenId() private 
    {
        _currentTokenId++;
    }
    
    function sellItem(
        address _marketaddress, 
        uint256 _tokenId, 
        uint256 _price, 
        uint256 _currency, 
        uint256 _sellAmount
    ) external 
    {
        require(_marketaddress != address(0), "_marketaddress is a zero address.");
        require(_sellAmount > 0, "_sellAmount should be greater than zero.");
        require(balanceOf(msg.sender, _tokenId) >= _sellAmount, "Not enough balance.");
        
        if(_items[msg.sender][_tokenId] > 0) //selled many times
        {
            if(!_itemForSale[_items[msg.sender][_tokenId]].forSale) 
            {
                _currentSaleAmount++;
            }
            
            _itemForSale[_items[msg.sender][_tokenId]].seller = msg.sender;
            _itemForSale[_items[msg.sender][_tokenId]].tokenId = _tokenId;
            _itemForSale[_items[msg.sender][_tokenId]].sellAmount = _sellAmount;
            _itemForSale[_items[msg.sender][_tokenId]].price = _price;
            _itemForSale[_items[msg.sender][_tokenId]].currency = _currency;
            _itemForSale[_items[msg.sender][_tokenId]].forSale = true;
                
            setApprovalForAll(_marketaddress, true);
                
            emit ItemSelled(_tokenId);
        }
        else // selled first time
        {
            uint _orderId = _getNextOrderId();
            _items[msg.sender][_tokenId] = _orderId;
            
            _itemForSale[_orderId].seller = msg.sender;
            _itemForSale[_orderId].tokenId = _tokenId;
            _itemForSale[_orderId].sellAmount = _sellAmount;
            _itemForSale[_orderId].price = _price;
            _itemForSale[_orderId].currency = _currency;
            _itemForSale[_orderId].forSale = true;
            
            setApprovalForAll(_marketaddress, true);
            
            _currentSaleAmount++;
            _incrementOrderId();
            
            emit ItemSelled(_tokenId);
        }        
    }

    function batchSellItem(
        address _marketaddress, 
        uint256[] memory _tokenIds, 
        uint256[] memory _prices, 
        uint256 _currency, 
        uint256[] memory _sellAmounts
    ) external 
    {
        require(_marketaddress != address(0), "_marketaddress is a zero address.");
        require(_tokenIds.length == _prices.length, "length of token IDs and length of price is not matched.");
        require(_tokenIds.length == _sellAmounts.length, "length of token IDs and length of sell amounts is not matched.");

        for (uint256 index = 0; index < _tokenIds.length; index++) {

            uint256 _tokenId = _tokenIds[index];
            uint256 _price = _prices[index];
            uint256 _sellAmount = _sellAmounts[index];

            require(_sellAmount > 0, "_sellAmount should be greater than zero.");
            require(balanceOf(msg.sender, _tokenId) >= _sellAmount, "Not enough balance.");
            
            if(_items[msg.sender][_tokenId] > 0) //selled many times
            {
                if(!_itemForSale[_items[msg.sender][_tokenId]].forSale) 
                {
                    _currentSaleAmount++;
                }
                
                _itemForSale[_items[msg.sender][_tokenId]].seller = msg.sender;
                _itemForSale[_items[msg.sender][_tokenId]].tokenId = _tokenId;
                _itemForSale[_items[msg.sender][_tokenId]].sellAmount = _sellAmount;
                _itemForSale[_items[msg.sender][_tokenId]].price = _price;
                _itemForSale[_items[msg.sender][_tokenId]].currency = _currency;
                _itemForSale[_items[msg.sender][_tokenId]].forSale = true;
                    
                // setApprovalForAll(_marketaddress, true);
                emit ItemSelled(_tokenId);
            }
            else // selled first time
            {
                uint _orderId = _getNextOrderId();
                _items[msg.sender][_tokenId] = _orderId;
                
                _itemForSale[_orderId].seller = msg.sender;
                _itemForSale[_orderId].tokenId = _tokenId;
                _itemForSale[_orderId].sellAmount = _sellAmount;
                _itemForSale[_orderId].price = _price;
                _itemForSale[_orderId].currency = _currency;
                _itemForSale[_orderId].forSale = true;
                
                // setApprovalForAll(_marketaddress, true);
                _currentSaleAmount++;
                _incrementOrderId();
                
                emit ItemSelled(_tokenId);
            }            
        }

        setApprovalForAll(_marketaddress, true);
    }

    function batchMintAndSellItem(
        address _marketaddress, 
        uint256[] memory _mintAmounts,
        uint256[] memory _prices, 
        uint256 _currency, 
        uint256[] memory _sellAmounts
    ) external payable
    {
        require(_marketaddress != address(0), "_marketaddress is a zero address.");
        require(_mintAmounts.length > 0, "length of mint amount must be greater than 0.");
        require(_mintAmounts.length == _prices.length, "length of token IDs and length of price is not matched.");
        require(_mintAmounts.length == _sellAmounts.length, "length of token IDs and length of sell amounts is not matched.");
        require(msg.value >= feeOnMint * _mintAmounts.length, "fee is not enough");

        for (uint256 index = 0; index < _mintAmounts.length; index++) {

            uint256 _amount = _mintAmounts[index];
            require(_amount > 0, "mint amount should be greater than zero.");

            // Item memory _item = Item({
            //     amount : _amount,
            //     orderId : 0
            // });
            
            uint _tokenId = _getNextTokenId();
            _mint(msg.sender, _tokenId, _amount, "");
            
            _incrementTokenId();
            
            _items[msg.sender][_tokenId] = 0; //_item;
            _itemExists[_tokenId] = true;            
            _itemSupply[_tokenId] = _amount;
            
            emit MintEvent(_tokenId);
            
            uint256 _price = _prices[index];
            uint256 _sellAmount = _sellAmounts[index];

            require(_sellAmount > 0, "sell amount should be greater than zero.");
            
            uint _orderId = _getNextOrderId();
            _items[msg.sender][_tokenId] = _orderId;
            
            _itemForSale[_orderId].seller = msg.sender;
            _itemForSale[_orderId].tokenId = _tokenId;
            _itemForSale[_orderId].sellAmount = _sellAmount;
            _itemForSale[_orderId].price = _price;
            _itemForSale[_orderId].currency = _currency;
            _itemForSale[_orderId].forSale = true;
            
            // setApprovalForAll(_marketaddress, true);

            _currentSaleAmount++;
            _incrementOrderId();
            
            emit ItemSelled(_tokenId);
        }

        setApprovalForAll(_marketaddress, true);
        
        // this.setUser(msg.sender);
        feeAddr.transfer(msg.value);
    }

    function cancelSellItem(
        uint256 _tokenId,
        uint256 _cancelAmount
    ) external
    {
        require(balanceOf(msg.sender, _tokenId) > 0, "you are not owner of this token.");
        require(_itemForSale[_items[msg.sender][_tokenId]].forSale, "this token is already not for sale.");
        require(_itemForSale[_items[msg.sender][_tokenId]].sellAmount >= _cancelAmount, "_cancelAmount must not be greater than current sell amount.");

        _afterTokenTransfer(msg.sender, _tokenId, _cancelAmount);
       
        emit CancelItemSelled(_tokenId, _cancelAmount);
    }

    //_from : seller, _to : buyer
    function transactionItem(address _from, address _to, uint256 _tokenId, uint256 _amount) nonReentrant external payable 
    { 
        address payable owner = address(uint160(_from));
        require(owner != msg.sender, "Owner can't buy their tokens.");
        require(owner != address(0), "Owner must not be zero address.");
        
        require(msg.value >= _itemForSale[_items[_from][_tokenId]].price * _amount, "Not Enough Pays.");
        require(_itemForSale[_items[_from][_tokenId]].forSale, "This order is not for sale.");
        require(_itemForSale[_items[_from][_tokenId]].sellAmount > 0, "Not For Sale.");
        require(_itemForSale[_items[_from][_tokenId]].sellAmount >= _amount, "Not Enough Tokens.");
        require(_itemForSale[_items[_from][_tokenId]].currency == 0, "This token can buy on ethereum.");
        
        //approve(_to, _order.itemId);
        owner.transfer(_itemForSale[_items[_from][_tokenId]].price * _amount * (100 - feePercent) / 100);
        feeAddr.transfer(_itemForSale[_items[_from][_tokenId]].price * _amount * feePercent / 100);
        
        safeTransferFrom(owner, _to, _tokenId, _amount, "");
        
        // this.setUser(_to);
    }
    
    //_from : seller, _to : buyer
    function transactionItemWithToken(address _from, address _to, uint256 _tokenId, uint256 _amount, uint256 _price) nonReentrant external 
    {
        address owner = address(uint160(_from));
        require(owner != msg.sender, "Owner can't buy their tokens.");
        require(owner != address(0), "Owner must not be zero address.");
    
        require(_price >= _itemForSale[_items[_from][_tokenId]].price * _amount, "Not Enough Pays.");
        require(_itemForSale[_items[_from][_tokenId]].forSale, "This order is not for sale.");
        require(_itemForSale[_items[_from][_tokenId]].sellAmount > 0, "Not For Sale.");
        require(_itemForSale[_items[_from][_tokenId]].sellAmount >= _amount, "Not Enough Tokens");
        require(_itemForSale[_items[_from][_tokenId]].currency == 1, "This token can buy on DVI token.");
        
        //approve(_to, _order.itemId);
        bool result = currencyToken.transferFrom(_to, owner, _price);
        require(result, "transfer token failed");
        
        safeTransferFrom(owner, _to, _tokenId, _amount, "");
        // this.setUser(_to);
    }
    
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
        override
    {
        super.safeTransferFrom(from, to, id, amount, data);
        _afterTokenTransfer(from, id, amount);
    }
    
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        public
        override
    {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);

        for(uint256 i = 0; i < ids.length; ++i)
        {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            
            _afterTokenTransfer(from, id, amount);
        }
    }

    function _afterTokenTransfer(
        address from,
        //address to, 
        uint256 id,
        uint256 amount
    ) private
    {
        _itemForSale[_items[from][id]].sellAmount -= amount;
        // _items[from][id].amount -= amount;        
        // _items[to][id].amount += amount;
        //_items[from][id].amount
        if(balanceOf(from, id) == 0 || _itemForSale[_items[from][id]].sellAmount == 0)
        {
            if(_itemForSale[_items[from][id]].forSale)//_currentSaleAmount > 0)
            {
                _currentSaleAmount--;
            }
            
            _itemForSale[_items[from][id]].forSale = false;
        }
    }
        
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override 
    {
        //횟수 제한 필요
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) 
        {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            if (from == address(0)) //mint
            {
                
            } 
            else if (from != to) 
            {                
                uint256 _remainAmount = balanceOf(from, id).sub(amount);
                if(_remainAmount == 0)
                {
                    _ownedToken[from].remove(id);
                }
            }

            if (to == address(0)) //burn
            {
                
            } 
            else if (to != from) 
            {
                if(!_ownedToken[to].contains(id))
                {
                    _ownedToken[to].add(id);
                }
            }           
        }
    }
    
    function _getNextOrderId() private view returns (uint256) 
    {
        return _currentOrderId.add(1);
    }
    
    function _incrementOrderId() private 
    {
        _currentOrderId++;
    }

    function getOrders(address _seller, uint _tokenId) external view returns(uint256 _id, uint256 _price, uint256 _currency, uint256 _amount, address _owner)
    {        
        _id = _tokenId;
        _price = _itemForSale[_items[_seller][_tokenId]].price;
        _currency = _itemForSale[_items[_seller][_tokenId]].currency;
        _amount = _itemForSale[_items[_seller][_tokenId]].sellAmount;
        _owner = _itemForSale[_items[_seller][_tokenId]].seller;
    }
    
    function getTokensOfOwnerCount(
        address _addr
    ) external view returns(uint256) 
    {
        require(_addr != address(0), "_addr is a zero address.");
        return _ownedToken[_addr].length();
    }

    function getTokensOfOwner(
        address _owner,
        uint256 _count,
        uint256 _start
    ) external view returns(uint[] memory)
    {
        require(_owner != address(0), "_addr is a zero address.");
        // require(_ownedToken[_owner].length() > 0, "_addr has no tokens.");
        if(_ownedToken[_owner].length() == 0){ return new uint256[](0); }
        require(_count > 0, "_count must not be zero.");
        require(_count <= 50, "_count must be smaller than 51.");
        require(_ownedToken[_owner].length() >= (_count + _start), "(_count + _start) must be smaller than owned token count.");

        uint256[] memory _result = new uint256[](_count);

        for (uint256 _i = _start; _i < (_count + _start); _i++) 
        {
            _result[_i - _start] = _ownedToken[_owner].at(_i);
        }

        return _result;
    }
    
    function getSellingItems() external view returns(uint[] memory, address[] memory, uint[] memory, uint[] memory, uint[] memory)
    {
        uint[] memory _result_Id = new uint[](_currentSaleAmount);
        address[] memory _result_Addr = new address[](_currentSaleAmount);
        uint[] memory _result_Price = new uint[](_currentSaleAmount); 
        uint[] memory _result_Currency = new uint[](_currentSaleAmount);
        uint[] memory _result_SellAmount = new uint[](_currentSaleAmount);

        uint256 _maxOrderId = _currentOrderId;
        uint256 _idx = 0;
        
        uint256 _orderId = 0;
        for(_orderId = 1; _orderId < _maxOrderId + 1; _orderId++)
        {
            if(_itemForSale[_orderId].forSale)
            {
                _result_Id[_idx] = _orderId;
                _result_Addr[_idx] = _itemForSale[_orderId].seller;
                _result_Price[_idx] = _itemForSale[_orderId].price;
                _result_Currency[_idx] = _itemForSale[_orderId].currency;
                _result_SellAmount[_idx] = _itemForSale[_orderId].sellAmount;
                _idx++;
            }
        }   
            
        return (_result_Id, _result_Addr, _result_Price, _result_Currency, _result_SellAmount);
    }
    
    
    //// About Fee
    function changeFeeAddr(address payable _addr) onlyManager external returns(address)
    {
        require(_addr != address(0), "_addr is a zero address.");
        
        feeAddr = _addr;
        
        emit FeeAddressChange(_addr);
        
        return(feeAddr);
    }
    
    function changeFeePercent(uint256 _percent) onlyManager external returns(uint256)
    {
        require(_percent <= 100, "_percent exeed 100.");

        feePercent = _percent;
        
        emit FeePercentChange(_percent);
        
        return(feePercent);
    }

    function changeFeeOnMint(uint256 _new) onlyManager external returns(uint256)
    {
        feeOnMint = _new;
        
        emit FeeOnMintChange(_new);
        
        return(feeOnMint);
    }
    
    function exists(
        uint256 id
    ) public view virtual returns (bool) {
        return _itemExists[id];
    }

    function tokenURI(
        uint256 _tokenId
    ) external view returns (string memory) 
    {
        require(exists(_tokenId),"not exist query.");        
        return string(abi.encodePacked(this.uri(_tokenId), Strings.toString(_tokenId)));
    }

    
    /*
    function setUser(address _user) external
    {
        if(!containUser(_user))
        {
            _currentUserId++;
            _tokenUsers[_currentUserId] = _user;
            
            emit SetUser(_user);
        }        
    }
    
    function containUser(address _user) private view returns(bool)
    {
        bool _result = false;
        
        uint _i = 1;
        for(_i = 1; _i < _currentUserId + 1; _i++)
        {
            if(_tokenUsers[_i] == _user)
            {
                _result = true;
                break;
            }
        }
        
        return _result;
    }
    
    function ownerOf(uint _tokenId) external view returns(address[] memory, uint256[] memory)
    {
        uint _holders = 0;
        uint _i = 1;
        
        for(_i = 1; _i < _currentUserId + 1; _i++)
        {
            if(balanceOf(_tokenUsers[_i], _tokenId) > 0)
            {
                _holders++;
            }
        }
        
        address[] memory _addr = new address[](_holders);
        uint256[] memory _amount = new uint256[](_holders);        
        
        uint _idx = 0;
        for(_i = 1; _i < _currentUserId + 1; _i++)
        {
            uint256 _balance = balanceOf(_tokenUsers[_i], _tokenId);
            
            if(_balance > 0)
            {
                _addr[_idx] = _tokenUsers[_i];
                _amount[_idx] = _balance;
                
                _idx++;
            }
        }
        
        return(_addr, _amount);
    }
    */
}

// File: github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/token/ERC721/IERC721.sol



pragma solidity >=0.6.2 <0.8.0;


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

// File: github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/token/ERC721/IERC721Enumerable.sol



pragma solidity >=0.6.2 <0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/token/ERC721/IERC721Metadata.sol



pragma solidity >=0.6.2 <0.8.0;


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

// File: github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/token/ERC721/ERC721.sol



pragma solidity >=0.6.0 <0.8.0;












/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        // If there is no base URI, return the token URI.
        if (bytes(_baseURI).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(_baseURI, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(_baseURI, tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

// File: contracts/Dvision721Dvi.sol


pragma solidity ^0.6.12;







contract Dvision721Dvi is ERC721, ERC721Holder, AccessControl, ReentrancyGuard
{
    using SafeMath for uint256;
    
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    
    uint private _currentTokenId;
    uint private _currentSaleAmount;
    
    address payable public feeAddr;
    uint256 public feePercent;
    uint256 public feeOnMint;
    
    IERC20 public currencyToken;
    
    //Item[] public items;
    mapping(uint => Item) public _items;
    mapping(uint => bool) public _itemExists;
    //mapping(uint256 => uint256) _itemId;    
    
    struct Item 
    {
        uint256 price;
        uint8 currency;
        bool forSale;
    }
    
    event TokenChange(address indexed _old, address indexed _new);
    event ItemSelled(uint256 _tokenId);
    event CancelItemSelled(uint256 _tokenId);
    event MintEvent(uint256 _tokenId);    
    event FeeAddressChange(address indexed _new);
    event FeePercentChange(uint256 _percent);
    event FeeOnMintChange(uint256 _fee);    
    event URIChange(string _new);
        
    modifier onlyManager{
        require(hasRole(MANAGER_ROLE, msg.sender), "You are not manager.");
        _;
    }
        
    constructor(address _erc20, address payable _feeAddr, string memory _uri) 
    ERC721("DVI 721", "DVI721") ERC721Holder() ReentrancyGuard() public 
    {
        require(_erc20 != address(0), "_erc20 is a zero address.");
        require(_feeAddr != address(0), "_feeAddr is a zero address.");
        
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        
        currencyToken = IERC20(_erc20);
        feeAddr = _feeAddr;
        _setBaseURI(_uri);
    }
        
    function set20Token(address _new) onlyManager external 
    {
        require(_new != address(0), "_new is a zero address.");
        emit TokenChange(address(currencyToken), _new);
        currencyToken = IERC20(_new);
        
    }

    function setURI(string memory _new) onlyManager external returns(string memory)
    {
        emit URIChange(_new);
        
        _setBaseURI(_new);
        return baseURI();
    }

    function mint() external payable returns (uint256)
    {
        require(msg.value >= feeOnMint, "fee is not enough");
        
        Item memory _Item = Item({
            price : 0,
            currency : 0,
            forSale : false
        });
        
        uint _id = _getNextTokenId();
        _mint(msg.sender, _id);
        
        _incrementTokenId();
        
        _items[_id] = _Item;
        _itemExists[_id] = true;
        
        feeAddr.transfer(msg.value);
        
        emit MintEvent(_id);
        return (_id);
    }

    function batchMint(
        uint256 _mintAmount
    ) external payable 
    {
        require(msg.value >= feeOnMint * _mintAmount ,"fee is not enough");
        
        for (uint256 i = 0; i < _mintAmount; i++) {
            Item memory _Item = Item({
                price : 0,
                currency : 0,
                forSale : false
            });
            
            uint _id = _getNextTokenId();
            _mint(msg.sender, _id);
            
            _incrementTokenId();
            
            _items[_id] = _Item;
            _itemExists[_id] = true;
            
            emit MintEvent(_id);
        }

        feeAddr.transfer(msg.value);
    }
    
    function mintTo(address _to) onlyManager external returns(uint256, address)
    {
        Item memory _Item = Item({
            price : 0,
            currency : 0,
            forSale : false
        });
        
        uint256 _id = _currentTokenId.add(1);
        _mint(_to, _id);
        
        _incrementTokenId();
        
        _items[_id] = _Item;
        _itemExists[_id] = true;
        
        emit MintEvent(_id);
        return (_id, ownerOf(_id));
    }
    
    function _getNextTokenId() private view returns (uint256) 
    {
        return _currentTokenId.add(1);
    }
    
    function _incrementTokenId() private 
    {
        _currentTokenId++;
    }
    
    function sellItem(
        address _marketaddress, 
        uint256 _tokenId, 
        uint256 _price, 
        uint8 _currency
    ) external 
    {
        require(_marketaddress != address(0), "_marketaddress is a zero address.");
        require(ownerOf(_tokenId) == msg.sender, "you are not owner of this token.");
        
        if(!_items[_tokenId].forSale)
        {
            _currentSaleAmount++;
        }
        
        _items[_tokenId].price = _price;
        _items[_tokenId].currency = _currency;
        _items[_tokenId].forSale = true;

        approve(_marketaddress, _tokenId);
        
        emit ItemSelled(_tokenId);
    }

    function batchSellItem(
        address _marketaddress, 
        uint256[] memory _tokenIds, 
        uint256[] memory _prices, 
        uint8 _currency
    ) external 
    {
        require(_marketaddress != address(0), "_marketaddress is a zero address.");
        require(_tokenIds.length == _prices.length, "length of token IDs and length of price is not matched.");

        for (uint index = 0; index < _tokenIds.length; index++) 
        {
            uint _tokenId = _tokenIds[index];
            uint _price = _prices[index];
            
            require(ownerOf(_tokenId) == msg.sender, "you are not owner of this token.");
        
            if(!_items[_tokenId].forSale)
            {
                _currentSaleAmount++;
            }
            
            _items[_tokenId].price = _price;
            _items[_tokenId].currency = _currency;
            _items[_tokenId].forSale = true;
            
            //setApprovalForAll(_marketaddress, true);
            approve(_marketaddress, _tokenId);
            
            emit ItemSelled(_tokenId);            
        }
    }
    
    function batchMintAndSellItem(
        address _marketaddress,
        uint256[] memory _prices,
        uint8 _currency
    ) external payable
    {
        require(_marketaddress != address(0), "_marketaddress is a zero address.");
        require(_prices.length > 0, "length of prices must be greater than 0.");
        require(msg.value >= feeOnMint * _prices.length, "fee is not enough");
        
        for (uint256 index = 0; index < _prices.length; index++) 
        {
            uint256 _price = _prices[index];

            Item memory _Item = Item({
                price : _price,
                currency : _currency,
                forSale : true
            });
            
            uint256 _tokenId = _getNextTokenId();
            _mint(msg.sender, _tokenId);
            
            _incrementTokenId();
            
            _items[_tokenId] = _Item;
            _itemExists[_tokenId] = true;
            
            emit MintEvent(_tokenId);

            approve(_marketaddress, _tokenId);            
            emit ItemSelled(_tokenId);
        }

        feeAddr.transfer(msg.value);
    }

    function cancelSellItem(
        uint256 _tokenId
    ) external
    {
        require(ownerOf(_tokenId) == msg.sender,"you are not owner of this token.");
        require(_items[_tokenId].forSale, "this token is already not for sale.");

        _currentSaleAmount--;
        _items[_tokenId].forSale = false;

        emit CancelItemSelled(_tokenId);
    }
    
    function transactionItem(
        address _to, 
        uint _tokenId
    ) nonReentrant external payable 
    {        
        address payable owner = address(uint160(ownerOf(_tokenId)));
        require(owner != msg.sender, "You can't trade your item.");
        require(owner != address(0), "Owner of item is a zero address.");
    
        require(msg.value >= _items[_tokenId].price, "The payment is insufficient.");
        require(_items[_tokenId].forSale, "This token is not for sale.");
        require(_items[_tokenId].currency == 0, "This token can buy on ethereum.");
        
        //approve(_to, _tokenId);
        
        if(feePercent == 0)
        {
            owner.transfer(_items[_tokenId].price);
        }
        else
        {
            owner.transfer(_items[_tokenId].price * (100 - feePercent) / 100);
            feeAddr.transfer(_items[_tokenId].price * feePercent / 100);
        }
        
        //if(_currentSaleAmount > 0)
        //{
        //    _currentSaleAmount--;
        //}
        
        safeTransferFrom(owner, _to, _tokenId);
        //_items[_tokenId].price = 0;
        //_items[_tokenId].currency = 0;
        //_items[_tokenId].forSale = false;
    }
    
    //_to : buyer
    function transactionItemWithToken(
        address _to, 
        uint _tokenId, 
        uint256 _price
    ) nonReentrant external 
    {
        address owner = address(uint160(ownerOf(_tokenId)));
        require(owner != msg.sender, "You can't trade your item.");
        require(owner != address(0), "Owner of item is a zero address.");
    
        require(_price >= _items[_tokenId].price, "The payment is insufficient.");
        require(_items[_tokenId].forSale, "This token is not for sale.");
        require(_items[_tokenId].currency == 1, "This token can buy on DVI token.");
        
        //approve(_to, _tokenId);
        
        bool result = currencyToken.transferFrom(_to, owner, _price);
        require(result, "transfer token failed");
        
        //if(_currentSaleAmount > 0)
        //{
        //    _currentSaleAmount--;
        //}
        
        safeTransferFrom(owner, _to, _tokenId);
        //_items[_tokenId].price = 0;
        //_items[_tokenId].currency = 0;
        //_items[_tokenId].forSale = false;
    }
    
    // override edit    
    // override exist transferFrom to edit forSale
    function transferFrom(
        address from, 
        address to, 
        uint256 tokenId
    ) public override
    {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        
        if(_items[tokenId].forSale)
        {
            _currentSaleAmount--;
        }

        _items[tokenId].forSale = false;
        
        _transfer(from, to, tokenId);
    }
    
    function safeTransferFrom(
        address from, 
        address to, 
        uint256 tokenId
    ) public override 
    {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from, 
        address to, 
        uint256 tokenId, 
        bytes memory _data
    ) public override 
    {
        super.safeTransferFrom(from, to, tokenId, _data);
        
        if(_items[tokenId].forSale)
        {
            _currentSaleAmount--;
        }
        
        _items[tokenId].forSale = false;
    }
    
    
    function getTokensOfOwner(
        address _owner,
        uint256 _count,
        uint256 _start
    ) external view returns(uint[] memory)
    {
        require(_owner != address(0), "_addr is a zero address.");
        if(balanceOf(_owner) == 0){ return new uint256[](0); }
        require(_count > 0, "_count must not be zero.");
        require(_count <= 50, "_count must be smaller than 51.");
        require(balanceOf(_owner) >= (_count + _start), "(_count + _start) must be smaller than balanceOf _addr.");

        uint256[] memory _result = new uint256[](_count);

        for (uint256 _i = _start; _i < (_count + _start); _i++) 
        {
            _result[_i - _start] = tokenOfOwnerByIndex(_owner, _i);
        }

        return _result;
    }
    
    function getItems(uint _tokenId) external view returns(uint _id, uint256 _price, uint8 _currency, bool _forSale, address _owner)
    {
        _id = _tokenId;
        _price = _items[_tokenId].price;
        _currency = _items[_tokenId].currency;
        _forSale = _items[_tokenId].forSale;
        _owner = ownerOf(_tokenId);
    }
    
    function getSellingItems() external view returns(uint[] memory, uint[] memory, uint[] memory)
    {
        uint[] memory _result_Id = new uint[](_currentSaleAmount);
        uint[] memory _result_Price = new uint[](_currentSaleAmount);
        uint[] memory _result_Currency = new uint[](_currentSaleAmount);

        uint256 _maxTokenId = totalSupply();
        uint256 _idx = 0;
        
        uint256 _tokenId;
        for(_tokenId = 1; _tokenId < _maxTokenId + 1; _tokenId++)
        {
            if(_items[_tokenId].forSale)
            {
                _result_Id[_idx] = _tokenId;
                _result_Price[_idx] = _items[_tokenId].price;
                _result_Currency[_idx] = _items[_tokenId].currency;
                _idx++;
            }
        }   
            
        return (_result_Id, _result_Price, _result_Currency);
    }
    
        
    //// About Fee
    function changeFeeAddr(address payable _addr) onlyManager external returns(address)
    {
        require(_addr != address(0), "_addr is a zero address.");
        
        feeAddr = _addr;
        
        emit FeeAddressChange(_addr);
        
        return(feeAddr);
    }
        
    function changeFeePercent(uint256 _percent) onlyManager external returns(uint256)
    {
        require(_percent <= 100, "_percent exceed 100");
        
        feePercent = _percent;
        
        emit FeePercentChange(_percent);
        
        return(feePercent);
    }
           
    function changeFeeOnMint(uint256 _new) onlyManager external returns(uint256)
    {
        feeOnMint = _new;
        
        emit FeeOnMintChange(_new);
        
        return(feeOnMint);
    }
    
}
// File: contracts/DvisionMarket.sol


pragma solidity ^0.6.12;








contract DvisionMarket is AccessControl, Pausable
{
    
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    
    uint256 private tradeCounter;
    
    Dvision721Dvi private item721Dvi;
    Dvision1155Dvi private item1155Dvi;
    
    
    mapping(uint256 => Trade) public trades;
        
    struct Trade {
        address poster;
        string token;
        uint tokenId;
        uint256 price;
    }
    
    event TradeEvent(uint256, bytes32);
    event AddressChange(address indexed _new, bytes32 _msg);
    
    modifier onlyManager{
        require(hasRole(MANAGER_ROLE, msg.sender), "You are not manager.");
        _;
    }
    
    constructor(address _721, address _1155) public 
    {
        require(_721 != address(0), "_721 is a zero address.");
        require(_1155 != address(0), "_1155 is a zero address.");
        
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        
        item721Dvi = Dvision721Dvi(_721);
        item1155Dvi = Dvision1155Dvi(_1155);
        
        tradeCounter = 0;
    }
    
    function trade721ETH(uint _tokenId) whenNotPaused external payable 
    {
        (uint256 _id, uint256 _price_token,,,address _owner) = item721Dvi.getItems(_tokenId);
        require(msg.value >= _price_token, "Not Enough Pays.");
        require(_owner != msg.sender, "You can't trade your item.");
       
        item721Dvi.transactionItem{value : msg.value}(msg.sender, _id);
        
        trades[tradeCounter] = Trade({
            poster : msg.sender,
            token : "721-eth",
            tokenId : _tokenId,
            price : msg.value
        });
        tradeCounter += 1;
        
        emit TradeEvent(tradeCounter - 1 , "Open");
    }
    
    function trade1155ETH(address _seller, uint _tokenId, uint256 _amount) whenNotPaused external payable 
    {
        (uint256 _id, uint256 _price_token,,,address _owner) = item1155Dvi.getOrders(_seller, _tokenId);
        require(_amount > 0, "_amount should be greater than zero.");
        require(msg.value >= _price_token * _amount, "Not enough pay.");
        require(_seller != msg.sender, "You can't trade your item.");
       
        item1155Dvi.transactionItem{value : msg.value}(_owner, msg.sender, _id, _amount);
        
        trades[tradeCounter] = Trade({
            poster : msg.sender,
            token : "1155-eth",
            tokenId : _tokenId,
            price : msg.value
        });
        tradeCounter += 1;
        
        emit TradeEvent(tradeCounter - 1 , "Open");
    }
    
    function trade721DVI(uint _tokenId, uint256 _price) whenNotPaused external 
    {
        (uint256 _id, uint256 _price_token,,,address _owner) = item721Dvi.getItems(_tokenId);
        require(_price >= _price_token, "Not Enough Pays.");
        require(_owner != msg.sender, "You can't trade your item.");
        
        item721Dvi.transactionItemWithToken(msg.sender, _id, _price);
        
        trades[tradeCounter] = Trade({
            poster : msg.sender,
            token : "721-dvi",
            tokenId : _tokenId,
            price : _price
        });
        tradeCounter += 1;
        
        emit TradeEvent(tradeCounter - 1 , "Open");
    }
    
    function trade1155DVI(address _seller, uint _tokenId, uint256 _price, uint256 _amount) whenNotPaused external
    {
        (uint256 _id, uint256 _price_token,,,address _owner) = item1155Dvi.getOrders(_seller, _tokenId);
        require(_price >= _price_token, "Not Enough Pays.");
        require(_seller != msg.sender, "You can't trade your item.");
        
        item1155Dvi.transactionItemWithToken(_owner, msg.sender, _id, _amount,  _price * _amount);
        
        trades[tradeCounter] = Trade({
            poster : msg.sender,
            token : "1155-dvi",
            tokenId : _tokenId,
            price : _price * _amount
            //status : "Open"
        });
        tradeCounter += 1;
        
        emit TradeEvent(tradeCounter - 1 , "Open");
    }
    
    
    
    function set721Token(address _new) onlyManager external 
    {
        require(_new != address(0), "_new is a zero address.");
        
        item721Dvi = Dvision721Dvi(_new);
        
        emit AddressChange(_new,"ERC721");
    }
    
    function set1155Token(address _new) onlyManager external 
    {
        require(_new != address(0), "_new is a zero address.");
        
        item1155Dvi = Dvision1155Dvi(_new);
        
        emit AddressChange(_new,"ERC1155");
    }
    
    function pauseMarket() onlyManager external
    {
        _pause();
    }

    function unpauseMarket() onlyManager external
    {
        _unpause();
    }
    
}