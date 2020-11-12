// Dependency file: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

// pragma solidity ^0.6.0;

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
     * // importANT: Beware that changing an allowance with this method brings the risk
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


// Dependency file: contracts/interfaces/IGeneScience.sol


// pragma solidity =0.6.12;

interface IGeneScience {
    function isAlpacaGeneScience() external pure returns (bool);

    /**
     * @dev given genes of alpaca 1 & 2, return a genetic combination
     * @param genes1 genes of matron
     * @param genes2 genes of sire
     * @param generation child generation
     * @param targetBlock target block child is intended to be born
     * @return gene child gene
     * @return energy energy associated with the gene
     * @return generationFactor buffs child energy, higher the generation larger the generationFactor
     *   energy = gene energy * generationFactor
     */
    function mixGenes(
        uint256 genes1,
        uint256 genes2,
        uint256 generation,
        uint256 targetBlock
    )
        external
        view
        returns (
            uint256 gene,
            uint256 energy,
            uint256 generationFactor
        );
}


// Dependency file: @openzeppelin/contracts/introspection/IERC165.sol


// pragma solidity ^0.6.0;

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


// Dependency file: @openzeppelin/contracts/utils/Address.sol


// pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [// importANT]
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
        // This method relies in extcodesize, which returns 0 for contracts in
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
     * // importANT: because control is transferred to `recipient`, care must be
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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


// Dependency file: contracts/interfaces/ICryptoAlpacaEnergyListener.sol


// pragma solidity 0.6.12;

// import "@openzeppelin/contracts/introspection/IERC165.sol";

interface ICryptoAlpacaEnergyListener is IERC165 {
    /**
        @dev Handles the Alpaca energy change callback.
        @param id The id of the Alpaca which the energy changed
        @param oldEnergy The ID of the token being transferred
        @param newEnergy The amount of tokens being transferred
    */
    function onCryptoAlpacaEnergyChanged(
        uint256 id,
        uint256 oldEnergy,
        uint256 newEnergy
    ) external;
}


// Dependency file: @openzeppelin/contracts/math/SafeMath.sol


// pragma solidity ^0.6.0;

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


// Dependency file: @openzeppelin/contracts/utils/EnumerableMap.sol


// pragma solidity ^0.6.0;

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


// Dependency file: @openzeppelin/contracts/utils/ReentrancyGuard.sol


// pragma solidity ^0.6.0;

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
contract ReentrancyGuard {
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


// Dependency file: @openzeppelin/contracts/GSN/Context.sol


// pragma solidity ^0.6.0;

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


// Dependency file: @openzeppelin/contracts/utils/Pausable.sol


// pragma solidity ^0.6.0;

// import "@openzeppelin/contracts/GSN/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
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


// Dependency file: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// pragma solidity ^0.6.2;

// import "@openzeppelin/contracts/introspection/IERC165.sol";

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


// Dependency file: @openzeppelin/contracts/token/ERC1155/IERC1155MetadataURI.sol


// pragma solidity ^0.6.2;

// import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

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


// Dependency file: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


// pragma solidity ^0.6.0;

// import "@openzeppelin/contracts/introspection/IERC165.sol";

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


// Dependency file: @openzeppelin/contracts/introspection/ERC165.sol


// pragma solidity ^0.6.0;

// import "@openzeppelin/contracts/introspection/IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165 is IERC165 {
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


// Dependency file: @openzeppelin/contracts/token/ERC1155/ERC1155.sol


// pragma solidity ^0.6.0;

// import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
// import "@openzeppelin/contracts/token/ERC1155/IERC1155MetadataURI.sol";
// import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
// import "@openzeppelin/contracts/GSN/Context.sol";
// import "@openzeppelin/contracts/introspection/ERC165.sol";
// import "@openzeppelin/contracts/math/SafeMath.sol";
// import "@openzeppelin/contracts/utils/Address.sol";

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
    constructor (string memory uri) public {
        _setURI(uri);

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


// Dependency file: @openzeppelin/contracts/access/Ownable.sol


// pragma solidity ^0.6.0;

// import "@openzeppelin/contracts/GSN/Context.sol";
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// Dependency file: contracts/CryptoAlpaca/AlpacaBase.sol


// pragma solidity =0.6.12;

// import "@openzeppelin/contracts/math/SafeMath.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/utils/EnumerableMap.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "contracts/interfaces/IGeneScience.sol";

contract AlpacaBase is Ownable {
    using SafeMath for uint256;

    /* ========== ENUM ========== */

    /**
     * @dev Alpaca can be in one of the two state:
     *
     * EGG - When two alpaca breed with each other, alpaca EGG is created.
     *       `gene` and `energy` are both 0 and will be assigned when egg is cracked
     *
     * GROWN - When egg is cracked and alpaca is born! `gene` and `energy` are determined
     *         in this state.
     */
    enum AlpacaGrowthState {EGG, GROWN}

    /* ========== PUBLIC STATE VARIABLES ========== */

    /**
     * @dev payment required to use cracked if it's done automatically
     * assigning to 0 indicate cracking action is not automatic
     */
    uint256 public autoCrackingFee = 0;

    /**
     * @dev Base breeding ALPA fee
     */
    uint256 public baseHatchingFee = 10e18; // 10 ALPA

    /**
     * @dev ALPA ERC20 contract address
     */
    IERC20 public alpa;

    /**
     * @dev 10% of the breeding ALPA fee goes to `devAddress`
     */
    address public devAddress;

    /**
     * @dev 90% of the breeding ALPA fee goes to `stakingAddress`
     */
    address public stakingAddress;

    /**
     * @dev number of percentage breeding ALPA fund goes to devAddress
     * dev percentage = devBreedingPercentage / 100
     * staking percentage = (100 - devBreedingPercentage) / 100
     */
    uint256 public devBreedingPercentage = 10;

    /**
     * @dev An approximation of currently how many seconds are in between blocks.
     */
    uint256 public secondsPerBlock = 15;

    /**
     * @dev amount of time a new born alpaca needs to wait before participating in breeding activity.
     */
    uint256 public newBornCoolDown = uint256(1 days);

    /**
     * @dev amount of time an egg needs to wait to be cracked
     */
    uint256 public hatchingDuration = uint256(5 minutes);

    /**
     * @dev when two alpaca just bred, the breeding multiplier will doubled to control
     * alpaca's population. This is the amount of time each parent must wait for the
     * breeding multiplier to reset back to 1
     */
    uint256 public hatchingMultiplierCoolDown = uint256(6 hours);

    /**
     * @dev hard cap on the maximum hatching cost multiplier it can reach to
     */
    uint16 public maxHatchCostMultiplier = 16;

    /**
     * @dev Gen0 generation factor
     */
    uint64 public constant GEN0_GENERATION_FACTOR = 10;

    /**
     * @dev maximum gen-0 alpaca energy. This is to prevent contract owner from
     * creating arbitrary energy for gen-0 alpaca
     */
    uint32 public constant MAX_GEN0_ENERGY = 3600;

    /**
     * @dev hatching fee increase with higher alpa generation
     */
    uint256 public generationHatchingFeeMultiplier = 2;

    /**
     * @dev gene science contract address for genetic combination algorithm.
     */
    IGeneScience public geneScience;

    /* ========== INTERNAL STATE VARIABLES ========== */

    /**
     * @dev An array containing the Alpaca struct for all Alpacas in existence. The ID
     * of each alpaca is the index into this array.
     */
    Alpaca[] internal alpacas;

    /**
     * @dev mapping from AlpacaIDs to an address where alpaca owner approved address to use
     * this alpca for breeding. addrss can breed with this cat multiple times without limit.
     * This will be resetted everytime someone transfered the alpaca.
     */
    EnumerableMap.UintToAddressMap internal alpacaAllowedToAddress;

    /* ========== ALPACA STRUCT ========== */

    /**
     * @dev Everything about your alpaca is stored in here. Each alpaca's appearance
     * is determined by the gene. The energy associated with each alpaca is also
     * related to the gene
     */
    struct Alpaca {
        // Theaalpaca genetic code.
        uint256 gene;
        // the alpaca energy level
        uint32 energy;
        // The timestamp from the block when this alpaca came into existence.
        uint64 birthTime;
        // The minimum timestamp alpaca needs to wait to avoid hatching multiplier
        uint64 hatchCostMultiplierEndBlock;
        // hatching cost multiplier
        uint16 hatchingCostMultiplier;
        // The ID of the parents of this alpaca, set to 0 for gen0 alpaca.
        uint32 matronId;
        uint32 sireId;
        // The "generation number" of this alpaca. The generation number of an alpacas
        // is the smaller of the two generation numbers of their parents, plus one.
        uint16 generation;
        // The minimum timestamp new born alpaca needs to wait to hatch egg.
        uint64 cooldownEndBlock;
        // The generation factor buffs alpaca energy level
        uint64 generationFactor;
        // defines current alpaca state
        AlpacaGrowthState state;
    }

    /* ========== VIEW ========== */

    function getTotalAlpaca() external view returns (uint256) {
        return alpacas.length;
    }

    function _getBaseHatchingCost(uint256 _generation)
        internal
        view
        returns (uint256)
    {
        return
            baseHatchingFee.add(
                _generation.mul(generationHatchingFeeMultiplier).mul(1e18)
            );
    }

    /* ========== OWNER MUTATIVE FUNCTION ========== */

    /**
     * @param _hatchingDuration hatching duration
     */
    function setHatchingDuration(uint256 _hatchingDuration) external onlyOwner {
        hatchingDuration = _hatchingDuration;
    }

    /**
     * @param _stakingAddress staking address
     */
    function setStakingAddress(address _stakingAddress) external onlyOwner {
        stakingAddress = _stakingAddress;
    }

    /**
     * @param _devAddress dev address
     */
    function setDevAddress(address _devAddress) external onlyDev {
        devAddress = _devAddress;
    }

    /**
     * @param _maxHatchCostMultiplier max hatch cost multiplier
     */
    function setMaxHatchCostMultiplier(uint16 _maxHatchCostMultiplier)
        external
        onlyOwner
    {
        maxHatchCostMultiplier = _maxHatchCostMultiplier;
    }

    /**
     * @param _devBreedingPercentage base generation factor
     */
    function setDevBreedingPercentage(uint256 _devBreedingPercentage)
        external
        onlyOwner
    {
        require(
            devBreedingPercentage <= 100,
            "CryptoAlpaca: invalid breeding percentage - must be between 0 and 100"
        );
        devBreedingPercentage = _devBreedingPercentage;
    }

    /**
     * @param _generationHatchingFeeMultiplier multiplier
     */
    function setGenerationHatchingFeeMultiplier(
        uint256 _generationHatchingFeeMultiplier
    ) external onlyOwner {
        generationHatchingFeeMultiplier = _generationHatchingFeeMultiplier;
    }

    /**
     * @param _baseHatchingFee base birthing
     */
    function setBaseHatchingFee(uint256 _baseHatchingFee) external onlyOwner {
        baseHatchingFee = _baseHatchingFee;
    }

    /**
     * @param _newBornCoolDown new born cool down
     */
    function setNewBornCoolDown(uint256 _newBornCoolDown) external onlyOwner {
        newBornCoolDown = _newBornCoolDown;
    }

    /**
     * @param _hatchingMultiplierCoolDown base birthing
     */
    function setHatchingMultiplierCoolDown(uint256 _hatchingMultiplierCoolDown)
        external
        onlyOwner
    {
        hatchingMultiplierCoolDown = _hatchingMultiplierCoolDown;
    }

    /**
     * @dev update how many seconds per blocks are currently observed.
     * @param _secs number of seconds
     */
    function setSecondsPerBlock(uint256 _secs) external onlyOwner {
        secondsPerBlock = _secs;
    }

    /**
     * @dev only owner can update autoCrackingFee
     */
    function setAutoCrackingFee(uint256 _autoCrackingFee) external onlyOwner {
        autoCrackingFee = _autoCrackingFee;
    }

    /**
     * @dev owner can upgrading gene science
     */
    function setGeneScience(IGeneScience _geneScience) external onlyOwner {
        require(
            _geneScience.isAlpacaGeneScience(),
            "CryptoAlpaca: invalid gene science contract"
        );

        // Set the new contract address
        geneScience = _geneScience;
    }

    /**
     * @dev owner can update ALPA erc20 token location
     */
    function setAlpaContract(IERC20 _alpa) external onlyOwner {
        alpa = _alpa;
    }

    /* ========== MODIFIER ========== */

    /**
     * @dev Throws if called by any account other than the dev.
     */
    modifier onlyDev() {
        require(
            devAddress == _msgSender(),
            "CryptoAlpaca: caller is not the dev"
        );
        _;
    }
}


// Dependency file: contracts/CryptoAlpaca/AlpacaToken.sol


// pragma solidity =0.6.12;

// import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
// import "contracts/CryptoAlpaca/AlpacaBase.sol";

contract AlpacaToken is AlpacaBase, ERC1155("") {
    /* ========== EVENTS ========== */

    /**
     * @dev Emitted when single `alpacaId` alpaca with `gene` and `energy` is born
     */
    event BornSingle(uint256 indexed alpacaId, uint256 gene, uint256 energy);

    /**
     * @dev Equivalent to multiple {BornSingle} events
     */
    event BornBatch(uint256[] alpacaIds, uint256[] genes, uint256[] energy);

    /* ========== VIEWS ========== */

    /**
     * @dev Check if `_alpacaId` is owned by `_account`
     */
    function isOwnerOf(address _account, uint256 _alpacaId)
        public
        view
        returns (bool)
    {
        return balanceOf(_account, _alpacaId) == 1;
    }

    /* ========== OWNER MUTATIVE FUNCTION ========== */

    /**
     * @dev Allow contract owner to update URI to look up all alpaca metadata
     */
    function setURI(string memory _newuri) external onlyOwner {
        _setURI(_newuri);
    }

    /**
     * @dev Allow contract owner to create generation 0 alpaca with `_gene`,
     *   `_energy` and transfer to `owner`
     *
     * Requirements:
     *
     * - `_energy` must be less than or equal to MAX_GEN0_ENERGY
     */
    function createGen0Alpaca(
        uint256 _gene,
        uint256 _energy,
        address _owner
    ) external onlyOwner {
        address alpacaOwner = _owner;
        if (alpacaOwner == address(0)) {
            alpacaOwner = owner();
        }

        _createGen0Alpaca(_gene, _energy, alpacaOwner);
    }

    /**
     * @dev Equivalent to multiple {createGen0Alpaca} function
     *
     * Requirements:
     *
     * - all `_energies` must be less than or equal to MAX_GEN0_ENERGY
     */
    function createGen0AlpacaBatch(
        uint256[] memory _genes,
        uint256[] memory _energies,
        address _owner
    ) external onlyOwner {
        address alpacaOwner = _owner;
        if (alpacaOwner == address(0)) {
            alpacaOwner = owner();
        }

        _createGen0AlpacaBatch(_genes, _energies, _owner);
    }

    /* ========== INTERNAL ALPA GENERATION ========== */

    /**
     * @dev Create an alpaca egg. Egg's `gene` and `energy` will assigned to 0
     * initially and won't be determined until egg is cracked.
     */
    function _createEgg(
        uint256 _matronId,
        uint256 _sireId,
        uint256 _generation,
        uint256 _cooldownEndBlock,
        address _owner
    ) internal returns (uint256) {
        require(_matronId == uint256(uint32(_matronId)));
        require(_sireId == uint256(uint32(_sireId)));
        require(_generation == uint256(uint16(_generation)));

        Alpaca memory _alpaca = Alpaca({
            gene: 0,
            energy: 0,
            birthTime: uint64(now),
            hatchCostMultiplierEndBlock: 0,
            hatchingCostMultiplier: 1,
            matronId: uint32(_matronId),
            sireId: uint32(_sireId),
            cooldownEndBlock: uint64(_cooldownEndBlock),
            generation: uint16(_generation),
            generationFactor: 0,
            state: AlpacaGrowthState.EGG
        });

        alpacas.push(_alpaca);
        uint256 eggId = alpacas.length - 1;

        _mint(_owner, eggId, 1, "");

        return eggId;
    }

    /**
     * @dev Internal gen-0 alpaca creation function
     *
     * Requirements:
     *
     * - `_energy` must be less than or equal to MAX_GEN0_ENERGY
     */
    function _createGen0Alpaca(
        uint256 _gene,
        uint256 _energy,
        address _owner
    ) internal returns (uint256) {
        require(_energy <= MAX_GEN0_ENERGY, "CryptoAlpaca: invalid energy");

        Alpaca memory _alpaca = Alpaca({
            gene: _gene,
            energy: uint32(_energy),
            birthTime: uint64(now),
            hatchCostMultiplierEndBlock: 0,
            hatchingCostMultiplier: 1,
            matronId: 0,
            sireId: 0,
            cooldownEndBlock: 0,
            generation: 0,
            generationFactor: GEN0_GENERATION_FACTOR,
            state: AlpacaGrowthState.GROWN
        });

        alpacas.push(_alpaca);
        uint256 newAlpacaID = alpacas.length - 1;

        _mint(_owner, newAlpacaID, 1, "");

        // emit the born event
        emit BornSingle(newAlpacaID, _gene, _energy);

        return newAlpacaID;
    }

    /**
     * @dev Internal gen-0 alpaca batch creation function
     *
     * Requirements:
     *
     * - all `_energies` must be less than or equal to MAX_GEN0_ENERGY
     */
    function _createGen0AlpacaBatch(
        uint256[] memory _genes,
        uint256[] memory _energies,
        address _owner
    ) internal returns (uint256[] memory) {
        require(
            _genes.length > 0,
            "CryptoAlpaca: must pass at least one genes"
        );
        require(
            _genes.length == _energies.length,
            "CryptoAlpaca: genes and energy length mismatch"
        );

        uint256 alpacaIdStart = alpacas.length;
        uint256[] memory ids = new uint256[](_genes.length);
        uint256[] memory amount = new uint256[](_genes.length);

        for (uint256 i = 0; i < _genes.length; i++) {
            require(
                _energies[i] <= MAX_GEN0_ENERGY,
                "CryptoAlpaca: invalid energy"
            );

            Alpaca memory _alpaca = Alpaca({
                gene: _genes[i],
                energy: uint32(_energies[i]),
                birthTime: uint64(now),
                hatchCostMultiplierEndBlock: 0,
                hatchingCostMultiplier: 1,
                matronId: 0,
                sireId: 0,
                cooldownEndBlock: 0,
                generation: 0,
                generationFactor: GEN0_GENERATION_FACTOR,
                state: AlpacaGrowthState.GROWN
            });

            alpacas.push(_alpaca);
            ids[i] = alpacaIdStart + i;
            amount[i] = 1;
        }

        _mintBatch(_owner, ids, amount, "");

        emit BornBatch(ids, _genes, _energies);

        return ids;
    }
}


// Dependency file: contracts/interfaces/ICryptoAlpaca.sol


// pragma solidity =0.6.12;

// import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface ICryptoAlpaca is IERC1155 {
    function getAlpaca(uint256 _id)
        external
        view
        returns (
            uint256 id,
            bool isReady,
            uint256 cooldownEndBlock,
            uint256 birthTime,
            uint256 matronId,
            uint256 sireId,
            uint256 hatchingCost,
            uint256 hatchingCostMultiplier,
            uint256 hatchCostMultiplierEndBlock,
            uint256 generation,
            uint256 gene,
            uint256 energy,
            uint256 state
        );

    function hasPermissionToBreedAsSire(address _addr, uint256 _id)
        external
        view
        returns (bool);

    function grandPermissionToBreed(address _addr, uint256 _sireId) external;

    function clearPermissionToBreed(uint256 _alpacaId) external;

    function hatch(uint256 _matronId, uint256 _sireId)
        external
        payable
        returns (uint256);

    function crack(uint256 _id) external;
}


// Dependency file: contracts/CryptoAlpaca/AlpacaBreed.sol


// pragma solidity =0.6.12;

// import "@openzeppelin/contracts/math/SafeMath.sol";
// import "@openzeppelin/contracts/utils/EnumerableMap.sol";
// import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
// import "@openzeppelin/contracts/utils/Pausable.sol";

// import "contracts/CryptoAlpaca/AlpacaToken.sol";
// import "contracts/interfaces/ICryptoAlpaca.sol";

contract AlpacaBreed is AlpacaToken, ICryptoAlpaca, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    /* ========== EVENTS ========== */

    // The Hatched event is fired when two alpaca successfully hached an egg.
    event Hatched(
        uint256 indexed eggId,
        uint256 matronId,
        uint256 sireId,
        uint256 cooldownEndBlock
    );

    // The GrantedToBreed event is fired whne an alpaca's owner granted
    // addr account to use alpacaId as sire to breed.
    event GrantedToBreed(uint256 indexed alpacaId, address addr);

    /* ========== VIEWS ========== */

    /**
     * Returns all the relevant information about a specific alpaca.
     * @param _id The ID of the alpaca of interest.
     */
    function getAlpaca(uint256 _id)
        external
        override
        view
        returns (
            uint256 id,
            bool isReady,
            uint256 cooldownEndBlock,
            uint256 birthTime,
            uint256 matronId,
            uint256 sireId,
            uint256 hatchingCost,
            uint256 hatchingCostMultiplier,
            uint256 hatchCostMultiplierEndBlock,
            uint256 generation,
            uint256 gene,
            uint256 energy,
            uint256 state
        )
    {
        Alpaca storage alpaca = alpacas[_id];

        id = _id;
        isReady = (alpaca.cooldownEndBlock <= block.number);
        cooldownEndBlock = alpaca.cooldownEndBlock;
        birthTime = alpaca.birthTime;
        matronId = alpaca.matronId;
        sireId = alpaca.sireId;
        hatchingCost = _getBaseHatchingCost(alpaca.generation);
        hatchingCostMultiplier = alpaca.hatchingCostMultiplier;
        if (alpaca.hatchCostMultiplierEndBlock <= block.number) {
            hatchingCostMultiplier = 1;
        }

        hatchCostMultiplierEndBlock = alpaca.hatchCostMultiplierEndBlock;
        generation = alpaca.generation;
        gene = alpaca.gene;
        energy = alpaca.energy;
        state = uint256(alpaca.state);
    }

    /**
     * @dev Calculating hatching ALPA cost
     */
    function hatchingALPACost(uint256 _matronId, uint256 _sireId)
        external
        view
        returns (uint256)
    {
        return _hatchingALPACost(_matronId, _sireId, false);
    }

    /**
     * @dev Checks to see if a given egg passed cooldownEndBlock and ready to crack
     * @param _id alpaca egg ID
     */

    function isReadyToCrack(uint256 _id) external view returns (bool) {
        Alpaca storage alpaca = alpacas[_id];
        return
            (alpaca.state == AlpacaGrowthState.EGG) &&
            (alpaca.cooldownEndBlock <= uint64(block.number));
    }

    /* ========== EXTERNAL MUTATIVE FUNCTIONS  ========== */

    /**
     * Grants permission to another account to sire with one of your alpacas.
     * @param _addr The address that will be able to use sire for breeding.
     * @param _sireId a alpaca _addr will be able to use for breeding as sire.
     */
    function grandPermissionToBreed(address _addr, uint256 _sireId)
        external
        override
    {
        require(
            isOwnerOf(msg.sender, _sireId),
            "CryptoAlpaca: You do not own sire alpaca"
        );

        alpacaAllowedToAddress.set(_sireId, _addr);
        emit GrantedToBreed(_sireId, _addr);
    }

    /**
     * check if `_addr` has permission to user alpaca `_id` to breed with as sire.
     */
    function hasPermissionToBreedAsSire(address _addr, uint256 _id)
        external
        override
        view
        returns (bool)
    {
        if (isOwnerOf(_addr, _id)) {
            return true;
        }

        return alpacaAllowedToAddress.get(_id) == _addr;
    }

    /**
     * Clear the permission on alpaca for another user to use to breed.
     * @param _alpacaId a alpaca to clear permission .
     */
    function clearPermissionToBreed(uint256 _alpacaId) external override {
        require(
            isOwnerOf(msg.sender, _alpacaId),
            "CryptoAlpaca: You do not own this alpaca"
        );

        alpacaAllowedToAddress.remove(_alpacaId);
    }

    /**
     * @dev Hatch an baby alpaca egg with two alpaca you own (_matronId and _sireId).
     * Requires a pre-payment of the fee given out to the first caller of crack()
     * @param _matronId The ID of the Alpaca acting as matron
     * @param _sireId The ID of the Alpaca acting as sire
     * @return The hatched alpaca egg ID
     */
    function hatch(uint256 _matronId, uint256 _sireId)
        external
        override
        payable
        whenNotPaused
        nonReentrant
        returns (uint256)
    {
        address msgSender = msg.sender;

        // Checks for payment.
        require(
            msg.value >= autoCrackingFee,
            "CryptoAlpaca: Required autoCrackingFee not sent"
        );

        // Checks for ALPA payment
        require(
            alpa.allowance(msgSender, address(this)) >=
                _hatchingALPACost(_matronId, _sireId, true),
            "CryptoAlpaca: Required hetching ALPA fee not sent"
        );

        // Checks if matron and sire are valid mating pair
        require(
            _ownerPermittedToBreed(msgSender, _matronId, _sireId),
            "CryptoAlpaca: Invalid permission"
        );

        // Grab a reference to the potential matron
        Alpaca storage matron = alpacas[_matronId];

        // Make sure matron isn't pregnant, or in the middle of a siring cooldown
        require(
            _isReadyToHatch(matron),
            "CryptoAlpaca: Matron is not yet ready to hatch"
        );

        // Grab a reference to the potential sire
        Alpaca storage sire = alpacas[_sireId];

        // Make sure sire isn't pregnant, or in the middle of a siring cooldown
        require(
            _isReadyToHatch(sire),
            "CryptoAlpaca: Sire is not yet ready to hatch"
        );

        // Test that matron and sire are a valid mating pair.
        require(
            _isValidMatingPair(matron, _matronId, sire, _sireId),
            "CryptoAlpaca: Matron and Sire are not valid mating pair"
        );

        // All checks passed, Alpaca gets pregnant!
        return _hatchEgg(_matronId, _sireId);
    }

    /**
     * @dev egg is ready to crack and give life to baby alpaca!
     * @param _id A Alpaca egg that's ready to crack.
     */
    function crack(uint256 _id) external override nonReentrant {
        // Grab a reference to the egg in storage.
        Alpaca storage egg = alpacas[_id];

        // Check that the egg is a valid alpaca.
        require(egg.birthTime != 0, "CryptoAlpaca: not valid egg");
        require(
            egg.state == AlpacaGrowthState.EGG,
            "CryptoAlpaca: not a valid egg"
        );

        // Check that the matron is pregnant, and that its time has come!
        require(_isReadyToCrack(egg), "CryptoAlpaca: egg cant be cracked yet");

        // Grab a reference to the sire in storage.
        Alpaca storage matron = alpacas[egg.matronId];
        Alpaca storage sire = alpacas[egg.sireId];

        // Call the sooper-sekret gene mixing operation.
        (
            uint256 childGene,
            uint256 childEnergy,
            uint256 generationFactor
        ) = geneScience.mixGenes(
            matron.gene,
            sire.gene,
            egg.generation,
            uint256(egg.cooldownEndBlock).sub(1)
        );

        egg.gene = childGene;
        egg.energy = uint32(childEnergy);
        egg.state = AlpacaGrowthState.GROWN;
        egg.cooldownEndBlock = uint64(
            (newBornCoolDown.div(secondsPerBlock)).add(block.number)
        );
        egg.generationFactor = uint64(generationFactor);

        // Send the balance fee to the person who made birth happen.
        if (autoCrackingFee > 0) {
            msg.sender.transfer(autoCrackingFee);
        }

        // emit the born event
        emit BornSingle(_id, childGene, childEnergy);
    }

    /* ========== PRIVATE FUNCTION ========== */

    /**
     * @dev Recalculate the hatchingCostMultiplier for alpaca after breed.
     * If hatchCostMultiplierEndBlock is less than current block number
     * reset hatchingCostMultiplier back to 2, otherwize multiply hatchingCostMultiplier by 2. Also update
     * hatchCostMultiplierEndBlock.
     */
    function _refreshHatchingMultiplier(Alpaca storage _alpaca) private {
        if (_alpaca.hatchCostMultiplierEndBlock < block.number) {
            _alpaca.hatchingCostMultiplier = 2;
        } else {
            uint16 newMultiplier = _alpaca.hatchingCostMultiplier * 2;
            if (newMultiplier > maxHatchCostMultiplier) {
                newMultiplier = maxHatchCostMultiplier;
            }

            _alpaca.hatchingCostMultiplier = newMultiplier;
        }
        _alpaca.hatchCostMultiplierEndBlock = uint64(
            (hatchingMultiplierCoolDown.div(secondsPerBlock)).add(block.number)
        );
    }

    function _ownerPermittedToBreed(
        address _sender,
        uint256 _matronId,
        uint256 _sireId
    ) private view returns (bool) {
        // owner must own matron, othersize not permitted
        if (!isOwnerOf(_sender, _matronId)) {
            return false;
        }

        // if owner owns sire, it's permitted
        if (isOwnerOf(_sender, _sireId)) {
            return true;
        }

        // if sire's owner has given permission to _sender to breed,
        // then it's permitted to breed
        if (alpacaAllowedToAddress.contains(_sireId)) {
            return alpacaAllowedToAddress.get(_sireId) == _sender;
        }

        return false;
    }

    /**
     * @dev Checks that a given alpaca is able to breed. Requires that the
     * current cooldown is finished (for sires) and also checks that there is
     * no pending pregnancy.
     */
    function _isReadyToHatch(Alpaca storage _alpaca)
        private
        view
        returns (bool)
    {
        return
            (_alpaca.state == AlpacaGrowthState.GROWN) &&
            (_alpaca.cooldownEndBlock < uint64(block.number));
    }

    /**
     * @dev Checks to see if a given alpaca is pregnant and (if so) if the gestation
     * period has passed.
     */

    function _isReadyToCrack(Alpaca storage _egg) private view returns (bool) {
        return
            (_egg.state == AlpacaGrowthState.EGG) &&
            (_egg.cooldownEndBlock < uint64(block.number));
    }

    /**
     * @dev Calculating breeding ALPA cost for internal usage.
     */
    function _hatchingALPACost(
        uint256 _matronId,
        uint256 _sireId,
        bool _strict
    ) private view returns (uint256) {
        uint256 blockNum = block.number;
        if (!_strict) {
            blockNum = blockNum + 1;
        }

        Alpaca storage sire = alpacas[_sireId];
        uint256 sireHatchingBase = _getBaseHatchingCost(sire.generation);
        uint256 sireMultiplier = sire.hatchingCostMultiplier;
        if (sire.hatchCostMultiplierEndBlock < blockNum) {
            sireMultiplier = 1;
        }

        Alpaca storage matron = alpacas[_matronId];
        uint256 matronHatchingBase = _getBaseHatchingCost(matron.generation);
        uint256 matronMultiplier = matron.hatchingCostMultiplier;
        if (matron.hatchCostMultiplierEndBlock < blockNum) {
            matronMultiplier = 1;
        }

        return
            (sireHatchingBase.mul(sireMultiplier)).add(
                matronHatchingBase.mul(matronMultiplier)
            );
    }

    /**
     * @dev Internal utility function to initiate hatching egg, assumes that all breeding
     *  requirements have been checked.
     */
    function _hatchEgg(uint256 _matronId, uint256 _sireId)
        private
        returns (uint256)
    {
        // Transfer birthing ALPA fee to this contract
        uint256 alpaCost = _hatchingALPACost(_matronId, _sireId, true);

        uint256 devAmount = alpaCost.mul(devBreedingPercentage).div(100);
        uint256 stakingAmount = alpaCost.mul(100 - devBreedingPercentage).div(
            100
        );

        assert(alpa.transferFrom(msg.sender, devAddress, devAmount));
        assert(alpa.transferFrom(msg.sender, stakingAddress, stakingAmount));

        // Grab a reference to the Alpacas from storage.
        Alpaca storage sire = alpacas[_sireId];
        Alpaca storage matron = alpacas[_matronId];

        // refresh hatching multiplier for both parents.
        _refreshHatchingMultiplier(sire);
        _refreshHatchingMultiplier(matron);

        // Determine the lower generation number of the two parents
        uint256 parentGen = matron.generation;
        if (sire.generation < matron.generation) {
            parentGen = sire.generation;
        }

        // child generation will be 1 larger than min of the two parents generation;
        uint256 childGen = parentGen.add(1);

        // Determine when the egg will be cracked
        uint256 cooldownEndBlock = (hatchingDuration.div(secondsPerBlock)).add(
            block.number
        );

        uint256 eggID = _createEgg(
            _matronId,
            _sireId,
            childGen,
            cooldownEndBlock,
            msg.sender
        );

        // Emit the hatched event.
        emit Hatched(eggID, _matronId, _sireId, cooldownEndBlock);

        return eggID;
    }

    /**
     * @dev Internal check to see if a given sire and matron are a valid mating pair.
     * @param _matron A reference to the Alpaca struct of the potential matron.
     * @param _matronId The matron's ID.
     * @param _sire A reference to the Alpaca struct of the potential sire.
     * @param _sireId The sire's ID
     */
    function _isValidMatingPair(
        Alpaca storage _matron,
        uint256 _matronId,
        Alpaca storage _sire,
        uint256 _sireId
    ) private view returns (bool) {
        // A Aapaca can't breed with itself
        if (_matronId == _sireId) {
            return false;
        }

        // Alpaca can't breed with their parents.
        if (_matron.matronId == _sireId || _matron.sireId == _sireId) {
            return false;
        }
        if (_sire.matronId == _matronId || _sire.sireId == _matronId) {
            return false;
        }

        return true;
    }

    /**
     * @dev openzeppelin ERC1155 Hook that is called before any token transfer
     * Clear any alpacaAllowedToAddress associated to the alpaca
     * that's been transfered
     */
    function _beforeTokenTransfer(
        address,
        address,
        address,
        uint256[] memory ids,
        uint256[] memory,
        bytes memory
    ) internal virtual override {
        for (uint256 i = 0; i < ids.length; i++) {
            if (alpacaAllowedToAddress.contains(ids[i])) {
                alpacaAllowedToAddress.remove(ids[i]);
            }
        }
    }
}


// Dependency file: contracts/CryptoAlpaca/AlpacaOperator.sol


// pragma solidity =0.6.12;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/introspection/IERC165.sol";
// import "@openzeppelin/contracts/utils/Address.sol";
// import "contracts/interfaces/IGeneScience.sol";
// import "contracts/interfaces/ICryptoAlpacaEnergyListener.sol";
// import "contracts/CryptoAlpaca/AlpacaBreed.sol";

contract AlpacaOperator is AlpacaBreed {
    using Address for address;

    address public operator;

    /*
     * bytes4(keccak256('onCryptoAlpacaEnergyChanged(uint256,uint256,uint256)')) == 0x5a864e1c
     */
    bytes4
        private constant _INTERFACE_ID_CRYPTO_ALPACA_ENERGY_LISTENER = 0x5a864e1c;

    /* ========== EVENTS ========== */

    /**
     * @dev Event for when alpaca's energy changed from `fromEnergy`
     */
    event EnergyChanged(
        uint256 indexed id,
        uint256 oldEnergy,
        uint256 newEnergy
    );

    /* ========== OPERATOR ONLY FUNCTION ========== */

    function updateAlpacaEnergy(
        address _owner,
        uint256 _id,
        uint32 _newEnergy
    ) external onlyOperator nonReentrant {
        require(_newEnergy > 0, "CryptoAlpaca: invalid energy");

        require(
            isOwnerOf(_owner, _id),
            "CryptoAlpaca: alpaca does not belongs to owner"
        );

        Alpaca storage thisAlpaca = alpacas[_id];
        uint32 oldEnergy = thisAlpaca.energy;
        thisAlpaca.energy = _newEnergy;

        emit EnergyChanged(_id, oldEnergy, _newEnergy);
        _doSafeEnergyChangedAcceptanceCheck(_owner, _id, oldEnergy, _newEnergy);
    }

    /**
     * @dev Transfers operator role to different address
     * Can only be called by the current operator.
     */
    function transferOperator(address _newOperator) external onlyOperator {
        require(
            _newOperator != address(0),
            "CryptoAlpaca: new operator is the zero address"
        );
        operator = _newOperator;
    }

    /* ========== MODIFIERS ========== */

    /**
     * @dev Throws if called by any account other than operator.
     */
    modifier onlyOperator() {
        require(
            operator == _msgSender(),
            "CryptoAlpaca: caller is not the operator"
        );
        _;
    }

    /* =========== PRIVATE ========= */

    function _doSafeEnergyChangedAcceptanceCheck(
        address _to,
        uint256 _id,
        uint256 _oldEnergy,
        uint256 _newEnergy
    ) private {
        if (_to.isContract()) {
            if (
                IERC165(_to).supportsInterface(
                    _INTERFACE_ID_CRYPTO_ALPACA_ENERGY_LISTENER
                )
            ) {
                ICryptoAlpacaEnergyListener(_to).onCryptoAlpacaEnergyChanged(
                    _id,
                    _oldEnergy,
                    _newEnergy
                );
            }
        }
    }
}


// Root file: contracts/CryptoAlpaca/AlpacaCore.sol


pragma solidity =0.6.12;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "contracts/interfaces/IGeneScience.sol";
// import "contracts/CryptoAlpaca/AlpacaOperator.sol";

contract AlpacaCore is AlpacaOperator {
    /**
     * @dev Initializes crypto alpaca contract.
     * @param _alpa ALPA ERC20 contract address
     * @param _devAddress dev address.
     * @param _stakingAddress staking address.
     */
    constructor(
        IERC20 _alpa,
        IGeneScience _geneScience,
        address _operator,
        address _devAddress,
        address _stakingAddress
    ) public {
        alpa = _alpa;
        geneScience = _geneScience;
        operator = _operator;
        devAddress = _devAddress;
        stakingAddress = _stakingAddress;

        // start with the mythical genesis alpaca
        _createGen0Alpaca(uint256(-1), 0, msg.sender);
    }

    /* ========== OWNER MUTATIVE FUNCTION ========== */

    /**
     * @dev Allows owner to withdrawal the balance available to the contract.
     */
    function withdrawBalance(uint256 _amount, address payable _to)
        external
        onlyOwner
    {
        _to.transfer(_amount);
    }

    /**
     * @dev pause crypto alpaca contract stops any further hatching.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev unpause crypto alpaca contract.
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}