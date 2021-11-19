/**
 *Submitted for verification at BscScan.com on 2021-11-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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


pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


pragma solidity ^0.8.0;

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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
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
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
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


pragma solidity ^0.8.0;

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}


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


pragma solidity ^0.8.0;

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


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


pragma solidity ^0.8.0;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}


pragma solidity ^0.8.0;

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
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


pragma solidity ^0.8.0;

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
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}


pragma solidity ^0.8.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function withdraw(uint) external;
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address user) external view returns (uint);
}


pragma solidity ^0.8.0;

library EnumerableMap {
    struct MapEntry {
        bytes32 _key;
        uint256 _value;
        uint256 _id;
        address _addr;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;
        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(
        Map storage map,
        bytes32 key,
        uint256 value,
        uint256 _id,
        address _addr
    ) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) {
            // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({_key: key, _value: value, _id: _id, _addr: _addr}));
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

        if (keyIndex != 0) {
            // Equivalent to contains(map, key)
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
    function _at(Map storage map, uint256 index) private view returns (bytes32, uint256, uint256, address) {
        require(map._entries.length > index, 'EnumerableMap: index out of bounds');

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value, entry._id, entry._addr);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (uint256, uint256, address) {
        return _get(map, key, 'EnumerableMap: nonexistent key');
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     */
    function _get(
        Map storage map,
        bytes32 key,
        string memory errorMessage
    ) private view returns (uint256, uint256, address) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return (map._entries[keyIndex - 1]._value, map._entries[keyIndex - 1]._id, map._entries[keyIndex - 1]._addr); // All indexes are 1-based
    }

    // UintToUintMap

    struct Bytes32ToUintMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToUintMap storage map,
        bytes32 key,
        uint256 value,
        uint256 id,
        address addr
    ) internal returns (bool) {
        return _set(map._inner, key, value, id, addr);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToUintMap storage map, bytes32 key) internal returns (bool) {
        return _remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool) {
        return _contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(Bytes32ToUintMap storage map) internal view returns (uint256) {
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
    function at(Bytes32ToUintMap storage map, uint256 index) internal view returns (bytes32, uint256, uint256, address) {
        return _at(map._inner, index);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToUintMap storage map, bytes32 key) internal view returns (uint256, uint256, address) {
        return _get(map._inner, key);
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     */
    function get(
        Bytes32ToUintMap storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (uint256, uint256, address) {
        return _get(map._inner, key, errorMessage);
    }
}

contract ClosedSeaNFTController is ERC721Holder, Ownable, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;
    using EnumerableMap for EnumerableMap.Bytes32ToUintMap;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    struct AskEntry {
        address tokenAddr;
        uint256 tokenId;
        uint256 price;
        bool withEther;
    }

    struct BidEntry {
        address bidder;
        uint256 price;
        bool withEther;
    }

    struct UserBidEntry {
        address tokenAddr;
        uint256 tokenId;
        uint256 price;
    }

    IERC721 public closedSeaNFT;
    IERC20 public quoteErc20;
    IWETH public weth;
    IERC20 public usdToken;    // busd in bsc, usdt in etheruem, etc...
    address quoteTokenAndUSDPairAddress;    // weth - quoteToken pair
    address usdAndETHPair;    // usdToken - weth pair
    address payable public feeAddr;
    uint256 public feePercent;
    uint256 public constant MAX_FEE_PERCENT = 10000;
    EnumerableMap.Bytes32ToUintMap private _asksMap;
    mapping(bytes32 => address) private _tokenSellers;
    mapping(bytes32 => bytes32) private _tokenCategories;
    mapping(bytes32 => bool) private _tokenAskedWithEther;
    mapping(address => EnumerableSet.Bytes32Set) private _userSellingTokens;
    mapping(bytes32 => EnumerableSet.Bytes32Set) private _categorySellingTokens;
    mapping(bytes32 => BidEntry[]) private _tokenBids;
    mapping(address => EnumerableMap.Bytes32ToUintMap) private _userBids;

    event Trade(address indexed seller, address indexed buyer, uint256 indexed tokenId, uint256 price, uint256 fee);
    event Ask(address indexed seller, uint256 indexed tokenId, uint256 price);
    event CancelSellToken(address indexed seller, uint256 indexed tokenId);
    event FeeAddressTransferred(address indexed previousOwner, address indexed newOwner);
    event SetFeePercent(address indexed seller, uint256 oldFeePercent, uint256 newFeePercent);
    event Bid(address indexed bidder, uint256 indexed tokenId, uint256 price);
    event CancelBidToken(address indexed bidder, uint256 indexed tokenId);

    constructor(
        address _nftAddress,
        address _quoteErc20Address,
        address payable _feeAddr,
        uint256 _feePercent,
        address _weth,
        address _usdToken
    ) public {
        require(_nftAddress != address(0) && _nftAddress != address(this));
        require(_quoteErc20Address != address(0) && _quoteErc20Address != address(this));
        require(_feePercent <= MAX_FEE_PERCENT);
        closedSeaNFT = IERC721(_nftAddress);
        quoteErc20 = IERC20(_quoteErc20Address);
        feeAddr = _feeAddr;
        feePercent = _feePercent;
        weth = IWETH(_weth);
        usdToken = IERC20(_usdToken);
        emit FeeAddressTransferred(address(0), feeAddr);
        emit SetFeePercent(_msgSender(), 0, feePercent);
    }

    function _getKey(address _tokenAddr, uint256 _tokenId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_tokenAddr, _tokenId));
    }

    function buyToken(address _tokenAddr, uint256 _tokenId) public payable whenNotPaused {
        require(_msgSender() != address(0) && _msgSender() != address(this), 'Wrong msg sender');
        bytes32 key = _getKey(_tokenAddr, _tokenId);
        require(!_userBids[_msgSender()].contains(key), 'You must cancel your bid first');

        (uint256 price, , ) = _asksMap.get(key);
        uint256 feeAmount = price.mul(feePercent).div(MAX_FEE_PERCENT);
        address seller = _tokenSellers[key];
        if (_tokenAskedWithEther[key]) {
            require(msg.value >= price.add(feeAmount), 'pay amount insufficient');
            if (feeAmount != 0) {
                feeAddr.transfer(feeAmount);
            }
            payable(seller).transfer(price.sub(feeAmount));
        } else {
            IERC20(quoteErc20).transferFrom(_msgSender(), seller, price);
        }

        IERC721(_tokenAddr).safeTransferFrom(seller, _msgSender(), _tokenId);
        _asksMap.remove(key);
        _userSellingTokens[_tokenSellers[key]].remove(key);
        _categorySellingTokens[_tokenCategories[key]].remove(key);
        emit Trade(_tokenSellers[key], _msgSender(), _tokenId, price, feeAmount);
        delete _tokenSellers[key];
        delete _tokenCategories[key];
        delete _tokenAskedWithEther[key];
    }

    function setCurrentPrice(address _tokenAddr, uint256 _tokenId, uint256 _price) public whenNotPaused {
        bytes32 key = _getKey(_tokenAddr, _tokenId);
        require(_userSellingTokens[_msgSender()].contains(key), 'Only Seller can update price');
        require(_price != 0, 'Price must be granter than zero');
        _asksMap.set(key, _price, _tokenId, _tokenAddr);
        emit Ask(_msgSender(), _tokenId, _price);
    }

    function readyToSellToken(address _tokenAddr, uint256 _tokenId, uint256 _price, string memory _category, bool _withEther) public whenNotPaused {
        readyToSellTokenTo(_tokenAddr, _tokenId, _price, address(_msgSender()), _category, _withEther);
    }

    function readyToSellTokenTo(
        address _tokenAddr,
        uint256 _tokenId,
        uint256 _price,
        address _to,
        string memory _category,
        bool _withEther
    ) public whenNotPaused {
        require(_msgSender() == IERC721(_tokenAddr).ownerOf(_tokenId), 'Only Token Owner can sell token');
        bytes32 key = _getKey(_tokenAddr, _tokenId);
        require(_price != 0, 'Price must be granter than zero');
        // closedSeaNFT.safeTransferFrom(address(_msgSender()), address(this), _tokenId);
        _asksMap.set(key, _price, _tokenId, _tokenAddr);
        _tokenSellers[key] = _to;
        _tokenCategories[key] = bytes32(bytes(_category));
        _tokenAskedWithEther[key] = _withEther;
        _userSellingTokens[_to].add(key);
        _categorySellingTokens[bytes32(bytes(_category))].add(key);
        emit Ask(_to, _tokenId, _price);
    }

    function cancelSellToken(address _tokenAddr, uint256 _tokenId) public whenNotPaused {
        bytes32 key = _getKey(_tokenAddr, _tokenId);
        require(_userSellingTokens[_msgSender()].contains(key), 'Only Seller can cancel sell token');
        // closedSeaNFT.safeTransferFrom(address(this), _msgSender(), _tokenId);
        _asksMap.remove(key);
        _userSellingTokens[_tokenSellers[key]].remove(key);
        _categorySellingTokens[_tokenCategories[key]].remove(key);
        delete _tokenSellers[key];
        delete _tokenCategories[key];
        delete _tokenAskedWithEther[key];
        emit CancelSellToken(_msgSender(), _tokenId);
    }

    function getAskLength() public view returns (uint256) {
        return _asksMap.length();
    }

    function getAskByCategoryLength(string memory _category) public view returns (uint256) {
        return _categorySellingTokens[bytes32(bytes(_category))].length();
    }

    function getAsks() public view returns (AskEntry[] memory) {
        AskEntry[] memory asks = new AskEntry[](_asksMap.length());
        for (uint256 i = 0; i < _asksMap.length(); ++i) {
            ( , uint256 price, uint256 tokenId, address tokenAddr) = _asksMap.at(i);
            bytes32 key = _getKey(tokenAddr, tokenId);
            asks[i] = AskEntry({ tokenAddr: tokenAddr, tokenId: tokenId, price: price, withEther: _tokenAskedWithEther[key] });
        }
        return asks;
    }

    function getAsksDesc() public view returns (AskEntry[] memory) {
        AskEntry[] memory asks = new AskEntry[](_asksMap.length());
        if (_asksMap.length() > 0) {
            for (uint256 i = _asksMap.length() - 1; i > 0; --i) {
                ( , uint256 price, uint256 tokenId, address tokenAddr) = _asksMap.at(i);
                bytes32 key = _getKey(tokenAddr, tokenId);
                asks[_asksMap.length() - 1 - i] = AskEntry({tokenAddr: tokenAddr, tokenId: tokenId, price: price, withEther: _tokenAskedWithEther[key]});
            }
            ( , uint256 price, uint256 tokenId, address tokenAddr) = _asksMap.at(0);
            bytes32 key = _getKey(tokenAddr, tokenId);
            asks[_asksMap.length() - 1] = AskEntry({tokenAddr: tokenAddr, tokenId: tokenId, price: price, withEther: _tokenAskedWithEther[key]});
        }
        return asks;
    }

    function getAsksByPage(uint256 page, uint256 size) public view returns (AskEntry[] memory) {
        if (_asksMap.length() > 0) {
            uint256 from = page == 0 ? 0 : (page - 1) * size;
            uint256 to = Math.min((page == 0 ? 1 : page) * size, _asksMap.length());
            AskEntry[] memory asks = new AskEntry[]((to - from));
            for (uint256 i = 0; from < to; ++i) {
                ( , uint256 price, uint256 tokenId, address tokenAddr) = _asksMap.at(from);
                bytes32 key = _getKey(tokenAddr, tokenId);
                asks[i] = AskEntry({tokenAddr: tokenAddr, tokenId: tokenId, price: price, withEther: _tokenAskedWithEther[key]});
                ++from;
            }
            return asks;
        } else {
            return new AskEntry[](0);
        }
    }

    function getAsksByPageDesc(uint256 page, uint256 size) public view returns (AskEntry[] memory) {
        if (_asksMap.length() > 0) {
            uint256 from = _asksMap.length() - 1 - (page == 0 ? 0 : (page - 1) * size);
            uint256 to = _asksMap.length() - 1 - Math.min((page == 0 ? 1 : page) * size - 1, _asksMap.length() - 1);
            uint256 resultSize = from - to + 1;
            AskEntry[] memory asks = new AskEntry[](resultSize);
            if (to == 0) {
                for (uint256 i = 0; from > to; ++i) {
                    ( , uint256 price, uint256 tokenId, address tokenAddr) = _asksMap.at(from);
                    bytes32 key = _getKey(tokenAddr, tokenId);
                    asks[i] = AskEntry({tokenAddr: tokenAddr, tokenId: tokenId, price: price, withEther: _tokenAskedWithEther[key]});
                    --from;
                }
                ( , uint256 price, uint256 tokenId, address tokenAddr) = _asksMap.at(0);
                bytes32 key = _getKey(tokenAddr, tokenId);
                asks[resultSize - 1] = AskEntry({tokenAddr: tokenAddr, tokenId: tokenId, price: price, withEther: _tokenAskedWithEther[key]});
            } else {
                for (uint256 i = 0; from >= to; ++i) {
                    ( , uint256 price, uint256 tokenId, address tokenAddr) = _asksMap.at(from);
                    bytes32 key = _getKey(tokenAddr, tokenId);
                    asks[i] = AskEntry({tokenAddr: tokenAddr, tokenId: tokenId, price: price, withEther: _tokenAskedWithEther[key]});
                    --from;
                }
            }
            return asks;
        }
        return new AskEntry[](0);
    }

    function getAsksByUser(address user) public view returns (AskEntry[] memory) {
        AskEntry[] memory asks = new AskEntry[](_userSellingTokens[user].length());
        for (uint256 i = 0; i < _userSellingTokens[user].length(); ++i) {
            bytes32 key = _userSellingTokens[user].at(i);
            (uint256 price, uint256 tokenId, address tokenAddr) = _asksMap.get(key);
            asks[i] = AskEntry({tokenAddr: tokenAddr, tokenId: tokenId, price: price, withEther: _tokenAskedWithEther[key]});
        }
        return asks;
    }

    function getAsksByUserDesc(address user) public view returns (AskEntry[] memory) {
        AskEntry[] memory asks = new AskEntry[](_userSellingTokens[user].length());
        if (_userSellingTokens[user].length() > 0) {
            for (uint256 i = _userSellingTokens[user].length() - 1; i > 0; --i) {
                bytes32 _key = _userSellingTokens[user].at(i);
                (uint256 _price, uint256 _tokenId, address _tokenAddr) = _asksMap.get(_key);
                asks[_userSellingTokens[user].length() - 1 - i] = AskEntry({tokenAddr: _tokenAddr, tokenId: _tokenId, price: _price, withEther: _tokenAskedWithEther[_key]});
            }
            bytes32 key = _userSellingTokens[user].at(0);
            (uint256 price, uint256 tokenId, address tokenAddr) = _asksMap.get(key);
            asks[_userSellingTokens[user].length() - 1] = AskEntry({tokenAddr: tokenAddr, tokenId: tokenId, price: price, withEther: _tokenAskedWithEther[key]});
        }
        return asks;
    }

    function getAsksByCategoryAndPageDesc(string memory _category, uint256 _page, uint256 _size) public view returns (AskEntry[] memory) {
        bytes32 catBytes32 = bytes32(bytes(_category));
        if (_categorySellingTokens[catBytes32].length() > 0) {
            uint256 categoryTokenLength = _categorySellingTokens[catBytes32].length();
            uint256 from = categoryTokenLength - 1 - (_page == 0 ? 0 : (_page - 1) * _size);
            uint256 to = categoryTokenLength - 1 - Math.min((_page == 0 ? 1 : _page) * _size - 1, categoryTokenLength - 1);
            uint256 resultSize = from - to + 1;
            AskEntry[] memory asks = new AskEntry[](resultSize);
            if (to == 0) {
                for (uint256 i = 0; from > to; ++i) {
                    ( , uint256 price, uint256 tokenId, address tokenAddr) = _asksMap.at(from);
                    bytes32 key = _getKey(tokenAddr, tokenId);
                    asks[i] = AskEntry({tokenAddr: tokenAddr, tokenId: tokenId, price: price, withEther: _tokenAskedWithEther[key]});
                    --from;
                }
                ( , uint256 price, uint256 tokenId, address tokenAddr) = _asksMap.at(0);
                bytes32 key = _getKey(tokenAddr, tokenId);
                asks[resultSize - 1] = AskEntry({tokenAddr: tokenAddr, tokenId: tokenId, price: price, withEther: _tokenAskedWithEther[key]});
            } else {
                for (uint256 i = 0; from >= to; ++i) {
                    ( , uint256 price, uint256 tokenId, address tokenAddr) = _asksMap.at(from);
                    bytes32 key = _getKey(tokenAddr, tokenId);
                    asks[i] = AskEntry({tokenAddr: tokenAddr, tokenId: tokenId, price: price, withEther: _tokenAskedWithEther[key]});
                    --from;
                }
            }
            return asks;
        }
        return new AskEntry[](0);
    }

    function getAsksByCategoryDesc(string memory _category) public view returns (AskEntry[] memory) {
        bytes32 catBytes32 = bytes32(bytes(_category));
        AskEntry[] memory asks = new AskEntry[](_categorySellingTokens[catBytes32].length());
        if (_categorySellingTokens[catBytes32].length() > 0) {
            for (uint256 i = _categorySellingTokens[catBytes32].length() - 1; i > 0; --i) {
                bytes32 _key = _categorySellingTokens[catBytes32].at(i);
                (uint256 _price, uint256 _tokenId, address _tokenAddr) = _asksMap.get(_key);
                asks[_categorySellingTokens[catBytes32].length() - 1 - i] = AskEntry({tokenAddr: _tokenAddr, tokenId: _tokenId, price: _price, withEther: _tokenAskedWithEther[_key]});
            }
            bytes32 key = _categorySellingTokens[catBytes32].at(0);
            (uint256 price, uint256 tokenId, address tokenAddr) = _asksMap.get(key);
            asks[_categorySellingTokens[catBytes32].length() - 1] = AskEntry({tokenAddr: tokenAddr, tokenId: tokenId, price: price, withEther: _tokenAskedWithEther[key]});
        }

        return asks;
    }

    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    function transferFeeAddress(address payable _feeAddr) public {
        require(_msgSender() == feeAddr, 'FORBIDDEN');
        feeAddr = _feeAddr;
        emit FeeAddressTransferred(_msgSender(), feeAddr);
    }

    function setFeePercent(uint256 _feePercent) public onlyOwner {
        require(feePercent != _feePercent, 'Not need update');
        require(_feePercent <= MAX_FEE_PERCENT, '!fee');
        feePercent = _feePercent;
        emit SetFeePercent(_msgSender(), feePercent, _feePercent);
    }

    function bidToken(address _tokenAddr, uint256 _tokenId, uint256 _price, bool _withEther) public payable whenNotPaused {
        require(_msgSender() != address(0) && _msgSender() != address(this), 'Wrong msg sender');
        require(_price != 0, 'Price must be granter than zero');
        bytes32 key = _getKey(_tokenAddr, _tokenId);
        require(_asksMap.contains(key), 'Token not in sell book');
        address _seller = _tokenSellers[key];
        address _to = address(_msgSender());
        require(_seller != _to, 'Owner cannot bid');
        require(!_userBids[_to].contains(key), 'Bidder already exists');
        if (_withEther) {
            require(msg.value >= _price.add(_price.mul(feePercent).div(MAX_FEE_PERCENT)), '!price');
        } else {
            quoteErc20.safeTransferFrom(address(_msgSender()), address(this), _price);
        }
        _userBids[_to].set(key, _price, _tokenId, _tokenAddr);
        _tokenBids[key].push(BidEntry({bidder: _to, price: _price, withEther: _withEther}));
        emit Bid(_msgSender(), _tokenId, _price);
    }

    function updateBidPrice(address _tokenAddr, uint256 _tokenId, uint256 _price) public payable whenNotPaused {
        bytes32 key = _getKey(_tokenAddr, _tokenId);
        require(_userBids[_msgSender()].contains(key), 'Only Bidder can update the bid price');
        require(_price != 0, 'Price must be granter than zero');
        address payable _to = payable(address(_msgSender())); // find  bid and the index
        (BidEntry memory bidEntry, uint256 _index) = getBidByTokenInfoAndAddress(_tokenId, _tokenAddr, _to);
        require(bidEntry.price != 0, 'Bidder does not exist');
        require(bidEntry.price != _price, 'The bid price cannot be the same');
        if (_price > bidEntry.price) {
            if (bidEntry.withEther) {
                require(msg.value >= _price.sub(bidEntry.price).add(_price.sub(bidEntry.price).mul(feePercent).div(MAX_FEE_PERCENT)), '!price');
            } else {
                quoteErc20.safeTransferFrom(address(_msgSender()), address(this), _price - bidEntry.price);
            }
        } else {
            if (bidEntry.withEther) {
                _to.transfer(bidEntry.price - _price);
            } else {
                quoteErc20.transfer(_to, bidEntry.price - _price);
            }
        }
        _userBids[_to].set(key, _price, _tokenId, _tokenAddr);
        _tokenBids[key][_index] = BidEntry({bidder: _to, price: _price, withEther: bidEntry.withEther});
        emit Bid(_msgSender(), _tokenId, _price);
    }

    function getBidByTokenInfoAndAddress(uint256 _tokenId, address _tokenAddr, address _address)
        private
        view
        returns (BidEntry memory, uint256)
    {
        // find the index of the bid
        bytes32 key = _getKey(_tokenAddr, _tokenId);
        BidEntry[] memory bidEntries = _tokenBids[key];
        uint256 len = bidEntries.length;
        uint256 _index;
        BidEntry memory bidEntry;
        for (uint256 i = 0; i < len; i++) {
            if (_address == bidEntries[i].bidder) {
                _index = i;
                bidEntry = BidEntry({bidder: bidEntries[i].bidder, price: bidEntries[i].price, withEther: bidEntries[i].withEther});
                break;
            }
        }
        return (bidEntry, _index);
    }

    function delBidByTokenInfoAndIndex(address _tokenAddr, uint256 _tokenId, uint256 _index) private {
        bytes32 key = _getKey(_tokenAddr, _tokenId);
        _userBids[_tokenBids[key][_index].bidder].remove(key);
        // delete the bid
        uint256 len = _tokenBids[key].length;
        for (uint256 i = _index; i < len - 1; i++) {
            _tokenBids[key][i] = _tokenBids[key][i + 1];
        }
        _tokenBids[key].pop();
    }

    function sellTokenTo(address _tokenAddr, uint256 _tokenId, address _to) public whenNotPaused {
        bytes32 key = _getKey(_tokenAddr, _tokenId);
        require(_asksMap.contains(key), 'Token not in sell book');
        address _seller = _tokenSellers[key];
        address _owner = address(_msgSender());
        require(_seller == _owner, 'Only owner can sell token');
        // find  bid and the index
        (BidEntry memory bidEntry, uint256 _index) = getBidByTokenInfoAndAddress(_tokenId, _tokenAddr, _to);
        require(bidEntry.price != 0, 'Bidder does not exist');
        // transfer token to bidder
        IERC721(_tokenAddr).safeTransferFrom(_msgSender(), _to, _tokenId);
        uint256 price = bidEntry.price;
        uint256 feeAmount = 0;
        if (bidEntry.withEther) {
            feeAmount = price.mul(feePercent).div(MAX_FEE_PERCENT);
            if (feeAmount > 0) {
                payable(feeAddr).transfer(feeAmount);
            }
            payable(_seller).transfer(price.sub(feeAmount));
        } else {
            quoteErc20.transfer(_seller, price);
        }
        _asksMap.remove(key);
        _userSellingTokens[_tokenSellers[key]].remove(key);
        _categorySellingTokens[_tokenCategories[key]].remove(key);
        delBidByTokenInfoAndIndex(_tokenAddr, _tokenId, _index);
        emit Trade(_tokenSellers[key], _to, _tokenId, price, feeAmount);
        delete _tokenSellers[key];
        delete _tokenCategories[key];
        delete _tokenAskedWithEther[key];
    }

    function cancelBidToken(address _tokenAddr, uint256 _tokenId) public whenNotPaused {
        bytes32 key = _getKey(_tokenAddr, _tokenId);
        require(_userBids[_msgSender()].contains(key), 'Only Bidder can cancel the bid');
        address _address = address(_msgSender());
        // find  bid and the index
        (BidEntry memory bidEntry, uint256 _index) = getBidByTokenInfoAndAddress(_tokenId, _tokenAddr, _address);
        require(bidEntry.price != 0, 'Bidder does not exist');
        if (bidEntry.withEther) {
            payable(_address).transfer(bidEntry.price);
        } else {
            quoteErc20.transfer(_address, bidEntry.price);
        }
        delBidByTokenInfoAndIndex(_tokenAddr, _tokenId, _index);
        emit CancelBidToken(_msgSender(), _tokenId);
    }

    function getBidsLength(address _tokenAddr, uint256 _tokenId) public view returns (uint256) {
        bytes32 key = _getKey(_tokenAddr, _tokenId);
        return _tokenBids[key].length;
    }

    function getBids(address _tokenAddr, uint256 _tokenId) public view returns (BidEntry[] memory) {
        bytes32 key = _getKey(_tokenAddr, _tokenId);
        return _tokenBids[key];
    }

    function getUserBids(address user) public view returns (UserBidEntry[] memory) {
        uint256 len = _userBids[user].length();
        UserBidEntry[] memory bids = new UserBidEntry[](len);
        for (uint256 i = 0; i < len; i++) {
            (, uint256 price, uint256 tokenId, address tokenAddr) = _userBids[user].at(i);
            bids[i] = UserBidEntry({tokenAddr: tokenAddr, tokenId: tokenId, price: price});
        }
        return bids;
    }

    function getQuoteTokenPrice() public view returns (uint) {
        if (quoteTokenAndUSDPairAddress != address(0)) {
            uint pairBalInUSD = usdToken.balanceOf(quoteTokenAndUSDPairAddress);
            uint pairBalInQuote = quoteErc20.balanceOf(quoteTokenAndUSDPairAddress);
            return pairBalInUSD.mul(1e18).div(pairBalInQuote);
        }
        return 0;
    }

    function getETHPrice() public view returns (uint) {
        if (usdAndETHPair != address(0)) {
            uint pairBalInWETH = weth.balanceOf(usdAndETHPair);
            uint pairBalInUSD = usdToken.balanceOf(usdAndETHPair);
            return pairBalInUSD.mul(1e18).div(pairBalInWETH);
        }
        return 0;
    }

    function updatePair(address _factory) external onlyOwner {
        address _quoteTokenAndUSDPair = IUniswapV2Factory(_factory).getPair(address(usdToken), address(quoteErc20));
        quoteTokenAndUSDPairAddress = _quoteTokenAndUSDPair;
        address _usdAndETHPair = IUniswapV2Factory(_factory).getPair(address(usdToken), address(weth));
        usdAndETHPair = _usdAndETHPair;
    }
}