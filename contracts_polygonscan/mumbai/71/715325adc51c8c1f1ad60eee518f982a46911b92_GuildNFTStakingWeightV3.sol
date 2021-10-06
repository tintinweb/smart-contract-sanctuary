/**
 *Submitted for verification at polygonscan.com on 2021-10-05
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;


// SPDX-License-Identifier: MIT
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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


/**
 * @notice Access Controls contract for the Digitalax Platform
 * @author BlockRocket.tech
 */
contract DigitalaxAccessControls is AccessControl {
    /// @notice Role definitions
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant SMART_CONTRACT_ROLE = keccak256("SMART_CONTRACT_ROLE");
    bytes32 public constant VERIFIED_MINTER_ROLE = keccak256("VERIFIED_MINTER_ROLE");

    /// @notice Events for adding and removing various roles
    event AdminRoleGranted(
        address indexed beneficiary,
        address indexed caller
    );

    event AdminRoleRemoved(
        address indexed beneficiary,
        address indexed caller
    );

    event MinterRoleGranted(
        address indexed beneficiary,
        address indexed caller
    );

    event MinterRoleRemoved(
        address indexed beneficiary,
        address indexed caller
    );

    event SmartContractRoleGranted(
        address indexed beneficiary,
        address indexed caller
    );

    event SmartContractRoleRemoved(
        address indexed beneficiary,
        address indexed caller
    );

    event VerifiedMinterRoleGranted(
        address indexed beneficiary,
        address indexed caller
    );

    event VerifiedMinterRoleRemoved(
        address indexed beneficiary,
        address indexed caller
    );

    /**
     * @notice The deployer is automatically given the admin role which will allow them to then grant roles to other addresses
     */
    constructor() public {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /////////////
    // Lookups //
    /////////////

    /**
     * @notice Used to check whether an address has the admin role
     * @param _address EOA or contract being checked
     * @return bool True if the account has the role or false if it does not
     */
    function hasAdminRole(address _address) external view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _address);
    }

    /**
     * @notice Used to check whether an address has the minter role
     * @param _address EOA or contract being checked
     * @return bool True if the account has the role or false if it does not
     */
    function hasMinterRole(address _address) external view returns (bool) {
        return hasRole(MINTER_ROLE, _address);
    }

    /**
     * @notice Used to check whether an address has the verified minter role
     * @param _address EOA or contract being checked
     * @return bool True if the account has the role or false if it does not
     */
    function hasVerifiedMinterRole(address _address)
        external
        view
        returns (bool)
    {
        return hasRole(VERIFIED_MINTER_ROLE, _address);
    }

    /**
     * @notice Used to check whether an address has the smart contract role
     * @param _address EOA or contract being checked
     * @return bool True if the account has the role or false if it does not
     */
    function hasSmartContractRole(address _address) external view returns (bool) {
        return hasRole(SMART_CONTRACT_ROLE, _address);
    }

    ///////////////
    // Modifiers //
    ///////////////

    /**
     * @notice Grants the admin role to an address
     * @dev The sender must have the admin role
     * @param _address EOA or contract receiving the new role
     */
    function addAdminRole(address _address) external {
        grantRole(DEFAULT_ADMIN_ROLE, _address);
        emit AdminRoleGranted(_address, _msgSender());
    }

    /**
     * @notice Removes the admin role from an address
     * @dev The sender must have the admin role
     * @param _address EOA or contract affected
     */
    function removeAdminRole(address _address) external {
        revokeRole(DEFAULT_ADMIN_ROLE, _address);
        emit AdminRoleRemoved(_address, _msgSender());
    }

    /**
     * @notice Grants the minter role to an address
     * @dev The sender must have the admin role
     * @param _address EOA or contract receiving the new role
     */
    function addMinterRole(address _address) external {
        grantRole(MINTER_ROLE, _address);
        emit MinterRoleGranted(_address, _msgSender());
    }

    /**
     * @notice Removes the minter role from an address
     * @dev The sender must have the admin role
     * @param _address EOA or contract affected
     */
    function removeMinterRole(address _address) external {
        revokeRole(MINTER_ROLE, _address);
        emit MinterRoleRemoved(_address, _msgSender());
    }

    /**
     * @notice Grants the verified minter role to an address
     * @dev The sender must have the admin role
     * @param _address EOA or contract receiving the new role
     */
    function addVerifiedMinterRole(address _address) external {
        grantRole(VERIFIED_MINTER_ROLE, _address);
        emit VerifiedMinterRoleGranted(_address, _msgSender());
    }

    /**
     * @notice Removes the verified minter role from an address
     * @dev The sender must have the admin role
     * @param _address EOA or contract affected
     */
    function removeVerifiedMinterRole(address _address) external {
        revokeRole(VERIFIED_MINTER_ROLE, _address);
        emit VerifiedMinterRoleRemoved(_address, _msgSender());
    }

    /**
     * @notice Grants the smart contract role to an address
     * @dev The sender must have the admin role
     * @param _address EOA or contract receiving the new role
     */
    function addSmartContractRole(address _address) external {
        grantRole(SMART_CONTRACT_ROLE, _address);
        emit SmartContractRoleGranted(_address, _msgSender());
    }

    /**
     * @notice Removes the smart contract role from an address
     * @dev The sender must have the admin role
     * @param _address EOA or contract affected
     */
    function removeSmartContractRole(address _address) external {
        revokeRole(SMART_CONTRACT_ROLE, _address);
        emit SmartContractRoleRemoved(_address, _msgSender());
    }
}

interface IGuildNFTStakingWeightStorage {
    function getDECAY_POINT_DEFAULT() external view returns (uint256);
    function getDECAY_POINT_WITH_APPRAISAL() external view returns (uint256);

//    // Overall variables

    function getClapMappingValue(uint256 _totalSupply, uint256 _balance) external view returns (uint256);
    function getDecoBonusMappingValue(uint256 _totalSupply, uint256 _balance) external view returns (uint256);
    function getAppraisedBonusMappingValue(uint256 _totalAppraised) external view returns (uint256);

//    // Mappings
    function getReactionPoint(string memory _type) external view returns (uint256);
}

/**
 * @title Digitalax Guild NFT Staking Weight
 * @dev Calculates the weight for staking on the PODE system
 * @author DIGITALAX CORE TEAM
 * @author
 */
contract GuildNFTStakingWeightV3 {
    using SafeMath for uint256;

    bool initialised;
    // Important contract addresses we need to set
    DigitalaxAccessControls public accessControls;
    IERC20 public guildNativeERC20Token;
    IGuildNFTStakingWeightStorage public store;
    address public stakingContract; // Pode Membership NFTs Staking
    address public whitelistedStakingContract; // Whitelisted NFTs Staking

    struct TokenReaction {
        uint256 metaverseCount;
        uint256 clapCount;
        uint256 shareCount;
        uint256 followCount;
        uint256 favoriteCount;
        mapping (string => uint256) appraisalCount;
    }

    struct TokenWeight {
        uint256 lastWeight;
        mapping (uint256 => uint256) dailyWeight;
        mapping (uint256 => TokenReaction) dailyTokenReaction;

        uint256 lastUpdateDay;
    }

    struct OwnerWeight {
        uint256 lastWeight;
        uint256 lastGuildMemberWeight;

        uint256 totalWhitelistedNFTAppraisals;

        uint256 stakedNFTCount;
        uint256 stakedWhitelistedNFTCount;

        mapping (uint256 => uint256) dailyWeight; // whitelisted nfts
        mapping (uint256 => uint256) dailyGuildMemberWeight; // guild member weight

        uint256 startDay;
        uint256 lastUpdateDay;
        uint256 lastGuildMemberUpdateDay;
    }

    struct AppraiserStats {
        uint256 totalReactionCount;
        uint256 totalClapCount;
        mapping (uint256 => uint256) dailyReactionCount;
        mapping (uint256 => uint256) dailyClapCount;
        mapping (uint256 => uint256) dailyClapLimit;

        mapping (uint256 => mapping (address => mapping(uint256 => TokenReaction))) dailyTokenReaction;

        uint256 totalGuildMemberReactionCount;
        mapping (uint256 => uint256) dailyGuildMemberReactionCount;
        mapping (uint256 => mapping(address => uint256)) dailyGuildMemberAppraisalReactionCount;
        mapping (uint256 => mapping (address => TokenReaction)) dailyGuildMemberReaction;

        uint256 lastReactionDay;
        uint256 maxDecoBonus;
        uint256 maxAssetsPercentageAppraised;

        uint256 uniqueWhitelistedNFTAppraisedLastBonus;
        mapping (address => mapping(uint256 => bool)) hasAppraisedWhitelistedNFTBefore;
        uint256 uniqueWhitelistedNFTsAppraised;
    }

    // Constants
    uint256 constant MULTIPLIER = 100000;
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 constant DAILY_NFT_WEIGHT_DEFAULT = 10; // 1
    uint256 constant DEFAULT_POINT_WITHOUT_DECAY_RATE = 1000; // 100%

    uint256 public startTime;
    uint256 public stakedNFTCount;
    uint256 public stakedWhitelistedNFTCount;
    uint256 public totalWhitelistedNFTTokenWeight;
    uint256 public totalGuildWeight;

    uint256 public lastUpdateDay;
    uint256 public lastGuildMemberUpdateDay;

    // Mappings
    //   mapping (string => uint256) public reactionPoint;
    mapping (uint256 => address) public tokenOwner;
    mapping (address => mapping(uint256 => address)) public whitelistedNFTTokenOwner;

    // Mappings
    mapping (address => mapping(uint256 => TokenWeight)) public whitelistedNFTTokenWeight;
    mapping(uint256 => TokenWeight) public podeTokenWeight;
    mapping(address => TokenWeight) public guildMemberWeight;
    mapping (address => OwnerWeight) public ownerWeight;
    mapping (address => AppraiserStats) public appraiserStats;

    event StakedMembershipToken(
        address owner,
        uint256 tokenId
    );

    event UnstakedMembershipToken(
        address owner,
        uint256 tokenId
    );

    event StakedWhitelistedNFTToken(
        address owner,
        address whitelistedNFT,
        uint256 tokenId
    );
    event UnstakedWhitelistedNFTToken(
        address owner,
        address whitelistedNFT,
        uint256 tokenId
    );

    event WhitelistedNFTReaction(
        string reaction,
        uint256 quantity,
        address whitelistedNFT,
        uint256 tokenId
    );

    event AppraiseGuildMember(
        string reaction,
        address guildMember
    );

    function initialize(address _stakingContract, address _whitelistedStakingContract, IERC20 _guildNativeERC20Token, DigitalaxAccessControls _accessControls, IGuildNFTStakingWeightStorage _store) public  {
        require(!initialised);
        accessControls = _accessControls;
        stakingContract = _stakingContract;
        whitelistedStakingContract = _whitelistedStakingContract;
        guildNativeERC20Token = _guildNativeERC20Token;
        store = _store;
        initialised = true;
        startTime = _getNow();
    }

    function _balanceOf(address _owner) internal view returns (uint256) {
        return ownerWeight[_owner].stakedNFTCount;
    }
    function balanceOf(address _owner) external view returns (uint256) {
        return _balanceOf(_owner);
    }

    function balanceOfWhitelistedNFT(address _owner) external view returns (uint256) {
        return ownerWeight[_owner].stakedWhitelistedNFTCount;
    }

    function getTotalWhitelistedNFTTokenWeight() external view returns (uint256) {
        return calcNewTotalWhitelistedNFTWeight();
    }

    function getTotalWeight() external view returns (uint256) {
        return calcNewWeight();
    }

    function getOwnerWeight(address _tokenOwner) external view returns (uint256) {
        return calcNewOwnerWeight(_tokenOwner);
    }

    function getWhitelistedNFTOwnerWeight(address _tokenOwner) external view returns (uint256) {
        return calcNewWhitelistedNFTOwnerWeight(_tokenOwner);
    }

    //    function getOwnerLastGuildMemberWeight(address _tokenOwner) external view returns (uint256) {
    //        return ownerWeight[_tokenOwner].lastGuildMemberWeight;
    //    }
    //
    //    function getOwnerLastWhitelistedNFTWeight(address _tokenOwner) external view returns (uint256) {
    //        return ownerWeight[_tokenOwner].lastWeight;
    //    }

    function updateAccessControls(DigitalaxAccessControls _accessControls) external {
        require(
            accessControls.hasAdminRole(_msgSender()),
            "Sender must be admin"
        );
        accessControls = _accessControls;
    }

    // Overall variables
    function setStartTime(uint256 _startTime) external returns (uint256){
        require(
            accessControls.hasAdminRole(_msgSender()),
            "Sender must be admin"
        );
        startTime = _startTime;
        return startTime;
    }

  function setStakedWhitelistedNFTCount(address _tokenOwner, uint256 _manualSet) external returns (uint256){
        require(
            accessControls.hasAdminRole(_msgSender()),
            "Sender must be admin"
        );
      OwnerWeight storage owner = ownerWeight[_tokenOwner];

      owner.stakedWhitelistedNFTCount = _manualSet;
    }

    function calcNewWeight() public view returns (uint256) {
        uint256 _currentDay = diffDays(startTime, _getNow());

        if (_currentDay <= lastGuildMemberUpdateDay || (stakedNFTCount == 0 && stakedWhitelistedNFTCount == 0)) {
            return totalGuildWeight;
        }

        uint256 _totalPeriodUpToLastUpdateDay = _currentDay.sub(lastGuildMemberUpdateDay);
        uint256 _totalPeriodUpToStartDate = diffDays(startTime, _getNow());

        return totalGuildWeight.add(DAILY_NFT_WEIGHT_DEFAULT.mul(MULTIPLIER).mul(stakedNFTCount).mul(_totalPeriodUpToLastUpdateDay));
    }

    function calcNewTotalWhitelistedNFTWeight() public view returns (uint256) {
        uint256 _currentDay = diffDays(startTime, _getNow());

        if (_currentDay <= lastUpdateDay  || (stakedNFTCount == 0 && stakedWhitelistedNFTCount == 0)) {
            return totalWhitelistedNFTTokenWeight;
        }

        uint256 _totalPeriodUpToLastUpdateDay = _currentDay.sub(lastUpdateDay);
        uint256 _totalPeriodUpToStartDate = diffDays(startTime, _getNow());

        return totalWhitelistedNFTTokenWeight.add(DAILY_NFT_WEIGHT_DEFAULT.mul(MULTIPLIER).mul(stakedWhitelistedNFTCount).mul(_totalPeriodUpToLastUpdateDay));
    }

    function updateWeight() public returns (bool) {
        uint256 _currentDay = diffDays(startTime, _getNow());

        if (_currentDay <= lastGuildMemberUpdateDay) {
            return false;
        }
        totalGuildWeight = calcNewWeight();

        lastGuildMemberUpdateDay = _currentDay;

        return true;
    }

    function updateWhitelistedNFTWeight() public returns (bool) {
        uint256 _currentDay = diffDays(startTime, _getNow());

        if (_currentDay <= lastUpdateDay ) {
            return false;
        }
        totalWhitelistedNFTTokenWeight = (calcNewTotalWhitelistedNFTWeight());

        lastUpdateDay = (_currentDay);

        return true;
    }

    function calcNewOwnerWeight(address _tokenOwner) public view returns (uint256) {
        uint256 _currentDay = diffDays(startTime, _getNow());

        OwnerWeight storage _owner = ownerWeight[_tokenOwner];

        if(_owner.stakedNFTCount == 0){
            return 0; // This is to prevent a bonus from being provided to users.
        }

        if (_owner.lastGuildMemberUpdateDay >= _currentDay) {

            return _owner.lastGuildMemberWeight;
        }

        uint256 reactionActivityBonus = 0;

        // Set up appraisers info
        AppraiserStats storage appraiser = appraiserStats[_tokenOwner];

        // Appraised nft extra
        uint256 _appraisalMilestoneBonus = store.getAppraisedBonusMappingValue(appraiser.uniqueWhitelistedNFTsAppraised);
        if( appraiser.uniqueWhitelistedNFTAppraisedLastBonus < _appraisalMilestoneBonus) {
            reactionActivityBonus = reactionActivityBonus.add((_appraisalMilestoneBonus.sub(appraiser.uniqueWhitelistedNFTAppraisedLastBonus)).mul(MULTIPLIER).mul(DAILY_NFT_WEIGHT_DEFAULT));
            //  appraiser.uniqueWhitelistedNFTAppraisedLastBonus = _appraisalMilestoneBonus;
        }

        // percentage of total assets consideration
        if(stakedWhitelistedNFTCount > 0) {
            uint256 percentageTotalAssets = uint256(1000000000000000000).mul(appraiser.uniqueWhitelistedNFTsAppraised).div(stakedWhitelistedNFTCount);
            if( appraiser.maxAssetsPercentageAppraised < percentageTotalAssets) {
                // appraiser.maxAssetsPercentageAppraised = percentageTotalAssets;
                reactionActivityBonus = reactionActivityBonus.add(percentageTotalAssets.mul(uint256(100)).mul(MULTIPLIER).mul(DAILY_NFT_WEIGHT_DEFAULT) / 1000000000000000000);
            }
        }

        // 5 Appraisal days Bonus
        uint256 daysPassedSinceLastGuildAppraisal = diffDays(_owner.lastGuildMemberUpdateDay, _currentDay);
        if(daysPassedSinceLastGuildAppraisal < 10 && appraiser.totalReactionCount > 0) {
            reactionActivityBonus = reactionActivityBonus.add(uint256(10).sub(daysPassedSinceLastGuildAppraisal).mul(MULTIPLIER).mul(DAILY_NFT_WEIGHT_DEFAULT));
        }

        uint256 _newWeight = _owner.dailyGuildMemberWeight[_owner.lastGuildMemberUpdateDay];

        _newWeight = _newWeight.add((reactionActivityBonus.add(DAILY_NFT_WEIGHT_DEFAULT * MULTIPLIER * _owner.stakedNFTCount))
        .mul(DEFAULT_POINT_WITHOUT_DECAY_RATE - store.getDECAY_POINT_DEFAULT() )        // decay rate: 7.5%
        .div(DEFAULT_POINT_WITHOUT_DECAY_RATE).mul(_currentDay.sub(_owner.lastGuildMemberUpdateDay)));

        return _newWeight;
    }

    function calcNewWhitelistedNFTOwnerWeight(address _tokenOwner) public view returns (uint256) {
        uint256 _currentDay = diffDays(startTime, _getNow());

        OwnerWeight storage _owner = ownerWeight[_tokenOwner];

        if (_owner.lastUpdateDay >= _currentDay) {
            return _owner.lastWeight;
        }

        uint256 _newWeight = _owner.dailyWeight[_owner.lastUpdateDay];

        _newWeight = _newWeight.add((DAILY_NFT_WEIGHT_DEFAULT * MULTIPLIER * _owner.stakedWhitelistedNFTCount)
        .mul(DEFAULT_POINT_WITHOUT_DECAY_RATE - store.getDECAY_POINT_DEFAULT() )        // decay rate: 7.5%
        .div(DEFAULT_POINT_WITHOUT_DECAY_RATE).mul(_currentDay.sub(_owner.lastUpdateDay)));

        return _newWeight;
    }

    function updateWhitelistedNFTOwnerWeight(address _tokenOwner) public returns (bool) {
        updateWhitelistedNFTWeight();
        OwnerWeight storage owner = ownerWeight[_tokenOwner];

        uint256 _currentDay = diffDays(startTime, _getNow());

        if (_currentDay <= owner.lastUpdateDay) {
            return false;
        }
        uint256 newDays = _currentDay.sub(owner.lastUpdateDay);
        uint256 prevWeight = owner.lastWeight;
        owner.lastWeight = calcNewWhitelistedNFTOwnerWeight(_tokenOwner); // total weight?

        uint256 presumedIncreaseTokenWeight = newDays.mul(MULTIPLIER).mul(DAILY_NFT_WEIGHT_DEFAULT).mul(owner.stakedWhitelistedNFTCount);

        if(prevWeight <= totalWhitelistedNFTTokenWeight ) {
            totalWhitelistedNFTTokenWeight = (totalWhitelistedNFTTokenWeight.sub(prevWeight));
        }

        uint256 modWeight = 0;
        if(owner.lastWeight >= presumedIncreaseTokenWeight){
            modWeight = modWeight.add(owner.lastWeight.sub(presumedIncreaseTokenWeight));
        }

        totalWhitelistedNFTTokenWeight = (totalWhitelistedNFTTokenWeight.add(modWeight)); //owner.lastGuildMemberWeight).sub(presumedIncreaseGuildWeight);

        owner.lastUpdateDay = _currentDay;

        return true;
    }
    function updateOwnerWeight(address _tokenOwner) public returns (bool) {
        updateWeight();
        OwnerWeight storage owner = ownerWeight[_tokenOwner];

        uint256 _currentDay = diffDays(startTime, _getNow());

        if (_currentDay <= owner.lastGuildMemberUpdateDay) {
            return false;
        }
        uint256 newDays = _currentDay.sub(owner.lastGuildMemberUpdateDay);
        uint256 prevGuildMemberWeight = owner.lastGuildMemberWeight;

        owner.lastGuildMemberWeight = calcNewOwnerWeight(_tokenOwner);

        // ** AFTER SETTING UP THE CALC NEW OWNER WEIGHT ABOVE, NEED TO UPDATE THE APPRAISER ACHIEVEMENT VALUES
        // Set up appraisers info
        AppraiserStats storage appraiser = appraiserStats[_tokenOwner];
        // 1 Deco extra
//        if(guildNativeERC20Token.totalSupply() > 0) {
//            uint256 _decoBonus = store.getDecoBonusMappingValue(guildNativeERC20Token.totalSupply(), guildNativeERC20Token.balanceOf(_tokenOwner));
//            if( appraiser.maxDecoBonus < _decoBonus) {
//                appraiser.maxDecoBonus = _decoBonus;
//            }
//        }
        // 2 Appraised nft extra
        uint256 _appraisalMilestoneBonus = store.getAppraisedBonusMappingValue(appraiser.uniqueWhitelistedNFTsAppraised);
        if( appraiser.uniqueWhitelistedNFTAppraisedLastBonus < _appraisalMilestoneBonus) {
            appraiser.uniqueWhitelistedNFTAppraisedLastBonus = _appraisalMilestoneBonus;
        }
        // 4 percentage of total assets consideration
        if(stakedWhitelistedNFTCount > 0) {
            uint256 percentageTotalAssets = uint256(1000000000000000000).mul(appraiser.uniqueWhitelistedNFTsAppraised).div(stakedWhitelistedNFTCount);
            if( appraiser.maxAssetsPercentageAppraised < percentageTotalAssets) {
                appraiser.maxAssetsPercentageAppraised = percentageTotalAssets;
            }
        }
        // ***

        uint256 presumedIncreaseGuildWeight = newDays.mul(MULTIPLIER).mul(DAILY_NFT_WEIGHT_DEFAULT).mul(owner.stakedNFTCount);


        if(prevGuildMemberWeight <= totalGuildWeight ) {
            totalGuildWeight = (totalGuildWeight.sub(prevGuildMemberWeight));
        }


        uint256 modWeight = 0;
        if(owner.lastGuildMemberWeight >= presumedIncreaseGuildWeight){
            modWeight = modWeight.add(owner.lastGuildMemberWeight.sub(presumedIncreaseGuildWeight));
        }

        totalGuildWeight = (totalGuildWeight.add(modWeight));

        owner.lastGuildMemberUpdateDay = _currentDay;

        return true;
    }


    /**
     * @dev Calc today token weight by yesterday weight & today reactions
     */
    function _calcTokenWeight(address _whitelistedNFT, uint256 _tokenId) internal returns (uint256) {
        uint256 _currentDay = diffDays(startTime, _getNow());
        TokenWeight storage _token = whitelistedNFTTokenWeight[_whitelistedNFT][_tokenId];

        if (_currentDay < _token.lastUpdateDay) {

            return _token.lastWeight;
        }

        // init token weight
        if (_token.lastUpdateDay >= _currentDay) {
            return _token.lastWeight;
        }

        uint256 _yesterdayWeight = _token.dailyWeight[_token.lastUpdateDay];


        _yesterdayWeight = _yesterdayWeight.add((DAILY_NFT_WEIGHT_DEFAULT * MULTIPLIER)
        .mul(DEFAULT_POINT_WITHOUT_DECAY_RATE - store.getDECAY_POINT_DEFAULT() )        // decay rate: 7.5%
        .div(DEFAULT_POINT_WITHOUT_DECAY_RATE).mul(_currentDay.sub(_token.lastUpdateDay)));


        // ** Get Reaction points
        TokenReaction storage _reaction = whitelistedNFTTokenWeight[_whitelistedNFT][_tokenId].dailyTokenReaction[_currentDay];

        uint256 _currentDayReactionPoint = 0;

        _currentDayReactionPoint = _currentDayReactionPoint.add(_reaction.metaverseCount.mul(store.getReactionPoint("Metaverse")));

        _currentDayReactionPoint = _currentDayReactionPoint.add(_reaction.shareCount.mul(store.getReactionPoint("Share")));
        _currentDayReactionPoint = _currentDayReactionPoint.add(_reaction.favoriteCount.mul(store.getReactionPoint("Favorite")));
        _currentDayReactionPoint = _currentDayReactionPoint.add(_reaction.followCount.mul(store.getReactionPoint("Follow")));

        uint256 _totalSupply = guildNativeERC20Token.totalSupply();
        uint256 erc20Balance = guildNativeERC20Token.balanceOf(_msgSender());

        _currentDayReactionPoint = _currentDayReactionPoint.add(_reaction.clapCount);       // stake points = clap limit per day

        _currentDayReactionPoint = _currentDayReactionPoint.add(_reaction.appraisalCount["Love"].mul(store.getReactionPoint("Love")));
        _currentDayReactionPoint = _currentDayReactionPoint.add(_reaction.appraisalCount["Like"].mul(store.getReactionPoint("Like")));
        _currentDayReactionPoint = _currentDayReactionPoint.add(_reaction.appraisalCount["Fire"].mul(store.getReactionPoint("Fire")));
        _currentDayReactionPoint = _currentDayReactionPoint.add(_reaction.appraisalCount["Sad"].mul(store.getReactionPoint("Sad")));
        _currentDayReactionPoint = _currentDayReactionPoint.add(_reaction.appraisalCount["Angry"].mul(store.getReactionPoint("Angry")));
        _currentDayReactionPoint = _currentDayReactionPoint.add(_reaction.appraisalCount["Novel"].mul(store.getReactionPoint("Novel")));

        _currentDayReactionPoint = _currentDayReactionPoint.mul(MULTIPLIER).mul(DAILY_NFT_WEIGHT_DEFAULT);

        if (_currentDayReactionPoint > 0) {     // 2.5%
            return _yesterdayWeight.add((_currentDayReactionPoint.add((MULTIPLIER).mul(DAILY_NFT_WEIGHT_DEFAULT)))
            .mul(DEFAULT_POINT_WITHOUT_DECAY_RATE - store.getDECAY_POINT_WITH_APPRAISAL() )
                .div(DEFAULT_POINT_WITHOUT_DECAY_RATE));
        } else {                                // 7.5%
            return _yesterdayWeight; //.mul(DEFAULT_POINT_WITHOUT_DECAY_RATE - store.getDECAY_POINT_DEFAULT() )
            //.div(DEFAULT_POINT_WITHOUT_DECAY_RATE);
        }
    }

    /**
     * @dev Calc today token weight by yesterday weight & today reactions
     */
    function _calcGuildMemberWeight(address _guildMember) internal returns (uint256) {
        uint256 _currentDay = diffDays(startTime, _getNow());
        TokenWeight storage _guildMemberWeight = guildMemberWeight[_guildMember];

        if (_currentDay < _guildMemberWeight.lastUpdateDay) {
            return _guildMemberWeight.lastWeight;
        }

        // Get guild member reaction points
        TokenReaction storage _reaction = guildMemberWeight[_guildMember].dailyTokenReaction[_currentDay];

        uint256 _currentDayReactionPoint = 0;

        _currentDayReactionPoint = _currentDayReactionPoint.add(_reaction.appraisalCount["Love"].mul(store.getReactionPoint("Love")));
        _currentDayReactionPoint = _currentDayReactionPoint.add(_reaction.appraisalCount["Like"].mul(store.getReactionPoint("Like")));
        _currentDayReactionPoint = _currentDayReactionPoint.add(_reaction.appraisalCount["Fire"].mul(store.getReactionPoint("Fire")));
        _currentDayReactionPoint = _currentDayReactionPoint.add(_reaction.appraisalCount["Sad"].mul(store.getReactionPoint("Sad")));
        _currentDayReactionPoint = _currentDayReactionPoint.add(_reaction.appraisalCount["Angry"].mul(store.getReactionPoint("Angry")));
        _currentDayReactionPoint = _currentDayReactionPoint.add(_reaction.appraisalCount["Novel"].mul(store.getReactionPoint("Novel")));

        _currentDayReactionPoint = _currentDayReactionPoint.add(_reaction.appraisalCount["Self"].mul(store.getReactionPoint("Self")));

        _currentDayReactionPoint = _currentDayReactionPoint.mul(MULTIPLIER).mul(DAILY_NFT_WEIGHT_DEFAULT);

        // update current day reaction points with the other factors

        // init guild member weight *******

        if (_guildMemberWeight.lastUpdateDay >= _currentDay) {
            return _guildMemberWeight.lastWeight;
        }

        uint256 _newWeight = _guildMemberWeight.dailyWeight[_guildMemberWeight.lastUpdateDay];

        _newWeight = _newWeight.add((DAILY_NFT_WEIGHT_DEFAULT * MULTIPLIER)
        .mul(DEFAULT_POINT_WITHOUT_DECAY_RATE - store.getDECAY_POINT_DEFAULT() )        // decay rate: 7.5%
        .div(DEFAULT_POINT_WITHOUT_DECAY_RATE).mul(_currentDay.sub(_guildMemberWeight.lastUpdateDay)));

        if (_currentDayReactionPoint > 0) {     // 2.5%
            return _newWeight.add((_currentDayReactionPoint).add((MULTIPLIER).mul(DAILY_NFT_WEIGHT_DEFAULT))
            .mul(DEFAULT_POINT_WITHOUT_DECAY_RATE - store.getDECAY_POINT_WITH_APPRAISAL() )
                .div(DEFAULT_POINT_WITHOUT_DECAY_RATE));
        } else {                                // 7.5%
            return _newWeight; //.mul(DEFAULT_POINT_WITHOUT_DECAY_RATE - store.getDECAY_POINT_DEFAULT() )
            //.div(DEFAULT_POINT_WITHOUT_DECAY_RATE);
        }
    }

    function _updateTodayWeightByReaction(address _whitelistedNFT, uint256 _tokenId, address _tokenOwner) internal {
        uint256 _currentDay = diffDays(startTime, _getNow());

        TokenWeight storage token = whitelistedNFTTokenWeight[_whitelistedNFT][_tokenId];

        token.dailyWeight[_currentDay] = _calcTokenWeight(_whitelistedNFT, _tokenId);

        token.lastUpdateDay = _currentDay;

        // Owner
        OwnerWeight storage owner = ownerWeight[_tokenOwner];
        // This means that they provided a reaction
        owner.totalWhitelistedNFTAppraisals = owner.totalWhitelistedNFTAppraisals.add(1);
        owner.dailyWeight[_currentDay] = owner.dailyWeight[_currentDay]
        .add(token.dailyWeight[_currentDay]).sub(token.lastWeight);

        totalWhitelistedNFTTokenWeight = (totalWhitelistedNFTTokenWeight.sub(owner.lastWeight)
        .add(owner.dailyWeight[_currentDay]));

        token.lastWeight = token.dailyWeight[_currentDay];
        owner.lastWeight = owner.dailyWeight[_currentDay];
        owner.lastUpdateDay = _currentDay;


        AppraiserStats storage appraiser = appraiserStats[_msgSender()];
        if(!appraiser.hasAppraisedWhitelistedNFTBefore[_whitelistedNFT][_tokenId]){
            appraiser.hasAppraisedWhitelistedNFTBefore[_whitelistedNFT][_tokenId] = true;
            appraiser.uniqueWhitelistedNFTsAppraised = appraiser.uniqueWhitelistedNFTsAppraised.add(1);
        }

        lastUpdateDay = (_currentDay);
    }

    function _updateTodayGuildMemberWeightByReaction(address _guildMember) internal {
        uint256 _currentDay = diffDays(startTime, _getNow());

        TokenWeight storage _guildMemberWeight = guildMemberWeight[_guildMember];

        _guildMemberWeight.dailyWeight[_currentDay] = _calcGuildMemberWeight(_guildMember);
        _guildMemberWeight.lastUpdateDay = _currentDay;

        // Owner
        OwnerWeight storage owner = ownerWeight[_guildMember];

        owner.dailyGuildMemberWeight[_currentDay] = _guildMemberWeight.dailyWeight[_currentDay];

        totalGuildWeight = (totalGuildWeight.sub(owner.lastGuildMemberWeight)
        .add(owner.dailyGuildMemberWeight[_currentDay]));

        _guildMemberWeight.lastWeight = _guildMemberWeight.dailyWeight[_currentDay];
        owner.lastGuildMemberWeight = owner.dailyGuildMemberWeight[_currentDay];
        owner.lastGuildMemberUpdateDay = _currentDay;

        lastGuildMemberUpdateDay = (_currentDay);
    }

    // Fixed reaction - reactWhitelistedNFT represents favorite, follow, share, and metaverse.
    function reactWhitelistedNFT(address[] memory _whitelistedNFTs, uint256[] memory _tokenIds, string[] memory _reactions) external {
        require(ownerWeight[_msgSender()].stakedNFTCount > 0, "Sender must stake PODE");
        require(_whitelistedNFTs.length == _tokenIds.length, "Arrays must be equal in length");
        require(_whitelistedNFTs.length == _reactions.length, "Arrays must be equal in length");

        uint256 _currentDay = diffDays(startTime, _getNow());

        AppraiserStats storage appraiser = appraiserStats[_msgSender()];

        for (uint256 i = 0; i < _whitelistedNFTs.length; i++) {
            require(whitelistedNFTTokenOwner[_whitelistedNFTs[i]][ _tokenIds[i]] != _msgSender(), "Cannot React to Own token");

            TokenWeight storage token = whitelistedNFTTokenWeight[_whitelistedNFTs[i]][_tokenIds[i]];
            if (keccak256(bytes(_reactions[i])) == keccak256(bytes("Favorite"))) {
                require(appraiser.dailyTokenReaction[_currentDay][_whitelistedNFTs[i]][_tokenIds[i]].favoriteCount == 0,
                    "Members can favorite an NFT once per day.");
                appraiser.dailyTokenReaction[_currentDay][_whitelistedNFTs[i]][_tokenIds[i]].favoriteCount = 1;
                token.dailyTokenReaction[_currentDay].favoriteCount = token.dailyTokenReaction[_currentDay].favoriteCount.add(1);

            } else if (keccak256(bytes(_reactions[i])) == keccak256(bytes("Follow"))) {
                require(appraiser.dailyTokenReaction[_currentDay][_whitelistedNFTs[i]][_tokenIds[i]].followCount == 0,
                    "Members can follow an NFT once per day.");
                appraiser.dailyTokenReaction[_currentDay][_whitelistedNFTs[i]][_tokenIds[i]].followCount = 1;
                token.dailyTokenReaction[_currentDay].followCount = token.dailyTokenReaction[_currentDay].followCount.add(1);

            } else if (keccak256(bytes(_reactions[i])) == keccak256(bytes("Share"))) {
                require(appraiser.dailyTokenReaction[_currentDay][_whitelistedNFTs[i]][_tokenIds[i]].shareCount == 0,
                    "Members can share an NFT once per day.");
                appraiser.dailyTokenReaction[_currentDay][_whitelistedNFTs[i]][_tokenIds[i]].shareCount = 1;
                token.dailyTokenReaction[_currentDay].shareCount = token.dailyTokenReaction[_currentDay].shareCount.add(1);

            } else if (keccak256(bytes(_reactions[i])) == keccak256(bytes("Metaverse"))) {
                require(appraiser.dailyTokenReaction[_currentDay][_whitelistedNFTs[i]][_tokenIds[i]].metaverseCount == 0,
                    "Members can metaverse an NFT once per day.");
                appraiser.dailyTokenReaction[_currentDay][_whitelistedNFTs[i]][_tokenIds[i]].metaverseCount = 1;
                token.dailyTokenReaction[_currentDay].metaverseCount = token.dailyTokenReaction[_currentDay].metaverseCount.add(1);

            } else {
                require(
                    false,
                    "An inputted reaction string is not allowed"
                );
            }


            appraiser.totalReactionCount = appraiser.totalReactionCount + 1;
            _updateTodayWeightByReaction(_whitelistedNFTs[i], _tokenIds[i], whitelistedNFTTokenOwner[_whitelistedNFTs[i]][ _tokenIds[i]]);
            emit WhitelistedNFTReaction(_reactions[i], 1, _whitelistedNFTs[i], _tokenIds[i]);
        }
        // AppraiserStats - Boost
        TokenWeight storage _guildMemberWeight = guildMemberWeight[_msgSender()];
        uint256 currentDay = diffDays(startTime, _getNow());
        _guildMemberWeight.dailyTokenReaction[currentDay].appraisalCount["Self"] = _guildMemberWeight.dailyTokenReaction[currentDay].appraisalCount["Self"].add(_tokenIds.length);
        _updateTodayGuildMemberWeightByReaction(_msgSender());


    }

    // Emotional appraisals
    function appraiseWhitelistedNFT( address[] memory _whitelistedNFTs, uint256[] memory _tokenIds, string[] memory _reactions) external {
        require(ownerWeight[_msgSender()].stakedNFTCount > 0, "Sender must stake PODE");


        uint256 _currentDay = diffDays(startTime, _getNow());
        AppraiserStats storage appraiser = appraiserStats[_msgSender()];

        require(_whitelistedNFTs.length == _tokenIds.length, "Must be equal quantity of whitelisted and token ids");
        require(_whitelistedNFTs.length == _reactions.length, "Must be equal quantity of whitelisted and token ids");
        uint256 _totalSupply = guildNativeERC20Token.totalSupply();
        uint256 erc20Balance = guildNativeERC20Token.balanceOf(_msgSender());
        uint256 _clapLimit = store.getClapMappingValue(_totalSupply, erc20Balance);
        for (uint256 i = 0; i < _whitelistedNFTs.length; i++) {
            require(whitelistedNFTTokenOwner[_whitelistedNFTs[i]][ _tokenIds[i]] != _msgSender(), "Cannot React to Own token");

            require(
                appraiser.dailyReactionCount[_currentDay] < _clapLimit,
                "Limit appraisal count per day"
            );

            // AppraiserStats
            appraiser.dailyReactionCount[_currentDay] = appraiser.dailyReactionCount[_currentDay] + 1;
            appraiser.totalReactionCount = appraiser.totalReactionCount + 1;

            // Token
            TokenWeight storage token = whitelistedNFTTokenWeight[_whitelistedNFTs[i]][_tokenIds[i]];
            token.dailyTokenReaction[_currentDay].appraisalCount[_reactions[i]] = token.dailyTokenReaction[_currentDay].appraisalCount[_reactions[i]].add(1);

            _updateTodayWeightByReaction(_whitelistedNFTs[i], _tokenIds[i], whitelistedNFTTokenOwner[_whitelistedNFTs[i]][ _tokenIds[i]]);
            emit WhitelistedNFTReaction(_reactions[i], 1, _whitelistedNFTs[i], _tokenIds[i]);
        }
        // AppraiserStats - Boost
        TokenWeight storage _guildMemberWeight = guildMemberWeight[_msgSender()];
        uint256 currentDay = diffDays(startTime, _getNow());
        _guildMemberWeight.dailyTokenReaction[currentDay].appraisalCount["Self"] = _guildMemberWeight.dailyTokenReaction[currentDay].appraisalCount["Self"].add(_tokenIds.length);
        _updateTodayGuildMemberWeightByReaction(_msgSender());
    }


    function clapWhitelistedNFT( address[] memory _whitelistedNFTs, uint256[] memory _tokenIds, uint256[] memory _clapQuantity) external {
        require(ownerWeight[_msgSender()].stakedNFTCount > 0, "Sender must stake PODE");

        uint256 _currentDay = diffDays(startTime, _getNow());
        AppraiserStats storage appraiser = appraiserStats[_msgSender()];

        require(_whitelistedNFTs.length == _tokenIds.length, "Must be equal quantity of whitelisted token ids");
        uint256 _totalSupply = guildNativeERC20Token.totalSupply();
        uint256 erc20Balance = guildNativeERC20Token.balanceOf(_msgSender());
        uint256 _clapLimit = store.getClapMappingValue(_totalSupply, erc20Balance);
        for (uint256 i = 0; i < _whitelistedNFTs.length; i++) {

            require(whitelistedNFTTokenOwner[_whitelistedNFTs[i]][ _tokenIds[i]] != _msgSender(), "Cannot React to Own token");

            require(
                appraiser.dailyClapCount[_currentDay].add(_clapQuantity[i]) <= _clapLimit,
                "Limit appraisal count per day"
            );

            // AppraiserStats
            appraiser.dailyClapCount[_currentDay] = appraiser.dailyClapCount[_currentDay] + _clapQuantity[i];
            appraiser.totalClapCount = appraiser.totalClapCount + _clapQuantity[i];

            appraiser.totalReactionCount = appraiser.totalReactionCount + 1;

            // Token
            TokenWeight storage token = whitelistedNFTTokenWeight[_whitelistedNFTs[i]][_tokenIds[i]];
            token.dailyTokenReaction[_currentDay].clapCount = token.dailyTokenReaction[_currentDay].clapCount.add(_clapQuantity[i]);

            _updateTodayWeightByReaction(_whitelistedNFTs[i], _tokenIds[i], whitelistedNFTTokenOwner[_whitelistedNFTs[i]][ _tokenIds[i]]);
            emit WhitelistedNFTReaction("Clap", _clapQuantity[i], _whitelistedNFTs[i], _tokenIds[i]);
        }
        // AppraiserStats - Boost
        TokenWeight storage _guildMemberWeight = guildMemberWeight[_msgSender()];
        uint256 currentDay = diffDays(startTime, _getNow());
        _guildMemberWeight.dailyTokenReaction[currentDay].appraisalCount["Self"] = _guildMemberWeight.dailyTokenReaction[currentDay].appraisalCount["Self"].add(_tokenIds.length);
        _updateTodayGuildMemberWeightByReaction(_msgSender());
    }

    function appraiseGuildMember(address[] memory _guildMembers, string[] memory _reactions) external {
        require(ownerWeight[_msgSender()].stakedNFTCount > 0, "Sender must stake PODE");

        uint256 _currentDay = diffDays(startTime, _getNow());
        AppraiserStats storage appraiser = appraiserStats[_msgSender()];

        uint256 _totalSupply = guildNativeERC20Token.totalSupply();
        uint256 erc20Balance = guildNativeERC20Token.balanceOf(_msgSender());
        uint256 _clapLimit = store.getClapMappingValue(_totalSupply, erc20Balance);
        require(_guildMembers.length == _reactions.length, "Must be equal quantity of whitelisted and token ids");
        for (uint256 i = 0; i < _guildMembers.length; i++) {
            require(_msgSender() != _guildMembers[i], "Appraiser cannot appraise themselves");
            require(ownerWeight[_guildMembers[i]].stakedNFTCount > 0, "Appraiser cannot appraise non-pode stakers");

            require(
                appraiser.dailyGuildMemberReactionCount[_currentDay] < _clapLimit,
                "Limit appraisal count per day"
            );
            require(
                appraiser.dailyGuildMemberAppraisalReactionCount[_currentDay][_guildMembers[i]] == 0,
                "Reached Limit appraisal per appraisers per day"
            );

            // AppraiserStats
            appraiser.dailyGuildMemberReactionCount[_currentDay] = appraiser.dailyGuildMemberReactionCount[_currentDay] + 1;
            appraiser.totalGuildMemberReactionCount = appraiser.totalGuildMemberReactionCount + 1;
            appraiser.dailyGuildMemberAppraisalReactionCount[_currentDay][_guildMembers[i]] = appraiser.dailyGuildMemberAppraisalReactionCount[_currentDay][_guildMembers[i]] + 1;

            // Token
            TokenWeight storage _guildMemberWeight = guildMemberWeight[_guildMembers[i]];
            _guildMemberWeight.dailyTokenReaction[_currentDay].appraisalCount[_reactions[i]] = _guildMemberWeight.dailyTokenReaction[_currentDay].appraisalCount[_reactions[i]].add(1);

            _updateTodayGuildMemberWeightByReaction(_guildMembers[i]);
            emit AppraiseGuildMember(_reactions[i], _guildMembers[i]);
        }

        // AppraiserStats - Boost
        TokenWeight storage _guildMemberWeight = guildMemberWeight[_msgSender()];
        uint256 currentDay = diffDays(startTime, _getNow());
        _guildMemberWeight.dailyTokenReaction[currentDay].appraisalCount["Self"] = _guildMemberWeight.dailyTokenReaction[currentDay].appraisalCount["Self"].add(_guildMembers.length);
        _updateTodayGuildMemberWeightByReaction(_msgSender());
    }


    // TODO unit test this very thoroughly
    function migrateCurrentStake(uint256 _tokenId, address _tokenOwner, uint256 stakeWeight) external {
        require(
            accessControls.hasAdminRole(_msgSender()),
            "Sender must be admin"
        );

        // TokenWeight
        TokenWeight storage token = podeTokenWeight[_tokenId];
        token.lastWeight = stakeWeight;
        _stake(_tokenId, _tokenOwner);
    }

    function stake(uint256 _tokenId, address _tokenOwner, uint256 _primarySalePrice) external {
        require(_msgSender() == stakingContract);

        _stake(_tokenId, _tokenOwner);
    }

    function _stake(uint256 _tokenId, address _tokenOwner) internal {
        require(tokenOwner[_tokenId] == address(0) || tokenOwner[_tokenId] == _tokenOwner);
        uint256 _currentDay = diffDays(startTime, _getNow());

        // TokenWeight
        TokenWeight storage token = podeTokenWeight[_tokenId];
        if(token.lastWeight == 0){
            token.lastWeight = DAILY_NFT_WEIGHT_DEFAULT.mul(MULTIPLIER);
        }
        token.lastUpdateDay = _currentDay;

        tokenOwner[_tokenId] = _tokenOwner;

        // OwnerWeight
        OwnerWeight storage owner = ownerWeight[_tokenOwner];

        if (owner.stakedNFTCount == 0) {
            owner.startDay = _currentDay;
        }

        owner.stakedNFTCount = owner.stakedNFTCount.add(1);

        // GuildWeight
        updateWeight();

        stakedNFTCount = stakedNFTCount.add(1);
        totalGuildWeight = (totalGuildWeight.add(token.lastWeight));

        owner.dailyGuildMemberWeight[_currentDay] =owner.dailyGuildMemberWeight[_currentDay].add(token.lastWeight);
        owner.lastGuildMemberWeight = owner.lastGuildMemberWeight.add(token.lastWeight);

        updateOwnerWeight(_tokenOwner);

        owner.lastGuildMemberUpdateDay = _currentDay;
        lastGuildMemberUpdateDay = (_currentDay);
        emit StakedMembershipToken(_tokenOwner, _tokenId);
    }

    function unstake(uint256 _tokenId, address _tokenOwner) external {
        require(_msgSender() == stakingContract, "Sender must be staking contract");
        require(tokenOwner[_tokenId] == _tokenOwner);

        uint256 _currentDay = diffDays(startTime, _getNow());

        // TokenWeight storage token = tokenWeight[_tokenId];
        OwnerWeight storage owner = ownerWeight[_tokenOwner];

        owner.stakedNFTCount = owner.stakedNFTCount.sub(1);

        stakedNFTCount = stakedNFTCount.sub(1);

        TokenWeight storage token = podeTokenWeight[_tokenId];

        uint256 newWeight = owner.lastGuildMemberWeight.div(owner.stakedNFTCount.add(1));

        if(newWeight<= totalGuildWeight){
            totalGuildWeight = totalGuildWeight.sub(newWeight);
        }

        if(newWeight <= owner.lastGuildMemberWeight){
            owner.lastGuildMemberWeight = owner.lastGuildMemberWeight.sub(newWeight);
        }

        updateOwnerWeight(_tokenOwner);
        owner.lastGuildMemberUpdateDay = _currentDay;
        lastGuildMemberUpdateDay = (_currentDay);

        if (stakedNFTCount == 0) {
            totalGuildWeight = (0);
        }

        if(token.lastWeight <= totalGuildWeight ) {
            totalGuildWeight = (totalGuildWeight.sub(token.lastWeight));
        }

        token.lastWeight = newWeight;

        TokenWeight storage guildMember = guildMemberWeight[_tokenOwner];

        if(newWeight <= owner.dailyGuildMemberWeight[_currentDay]){
            owner.dailyGuildMemberWeight[_currentDay] = owner.dailyGuildMemberWeight[_currentDay].sub(newWeight);
        }
        guildMember.dailyWeight[_currentDay] = owner.dailyGuildMemberWeight[_currentDay];
        guildMember.lastWeight = owner.lastGuildMemberWeight;

        delete tokenOwner[_tokenId];

        emit UnstakedMembershipToken(_tokenOwner, _tokenId);
    }

    function stakeWhitelistedNFT(address _whitelistedNFT, uint256 _tokenId, address _tokenOwner) external {
        require(_msgSender() == whitelistedStakingContract, "Sender must be staking contract");
        require(whitelistedNFTTokenOwner[_whitelistedNFT][ _tokenId] == address(0) || whitelistedNFTTokenOwner[_whitelistedNFT][ _tokenId] == _tokenOwner);

        uint256 _currentDay = diffDays(startTime, _getNow());

        // TokenWeight
        TokenWeight storage token = whitelistedNFTTokenWeight[_whitelistedNFT][_tokenId];
        if(token.lastWeight == 0){
            token.lastWeight = DAILY_NFT_WEIGHT_DEFAULT.mul(MULTIPLIER);
        }

        token.lastUpdateDay = _currentDay;

        whitelistedNFTTokenOwner[_whitelistedNFT][_tokenId] = _tokenOwner;

        // OwnerWeight
        OwnerWeight storage owner = ownerWeight[_tokenOwner];

        if (owner.stakedWhitelistedNFTCount == 0) {
            owner.startDay = _currentDay;
        }

        owner.stakedWhitelistedNFTCount = owner.stakedWhitelistedNFTCount.add(1);
        owner.lastWeight = owner.lastWeight.add(token.lastWeight);

        // GuildWeight
        updateWeight();

        stakedWhitelistedNFTCount = stakedWhitelistedNFTCount.add(1);
        totalWhitelistedNFTTokenWeight = (totalWhitelistedNFTTokenWeight.add(token.lastWeight));

        updateWhitelistedNFTOwnerWeight(_tokenOwner);
        owner.lastUpdateDay = _currentDay;
        lastUpdateDay = (_currentDay);

        emit StakedWhitelistedNFTToken(_tokenOwner, _whitelistedNFT, _tokenId);
    }

    function unstakeWhitelistedNFT(address _whitelistedNFT,uint256 _tokenId, address _tokenOwner) external {
        require(_msgSender() == whitelistedStakingContract, "Sender must be staking contract");
        require(whitelistedNFTTokenOwner[_whitelistedNFT][ _tokenId] == _tokenOwner);

        uint256 _currentDay = diffDays(startTime, _getNow());

        TokenWeight storage token = whitelistedNFTTokenWeight[_whitelistedNFT][_tokenId];
        OwnerWeight storage owner = ownerWeight[_tokenOwner];

        token.dailyWeight[_currentDay] = _calcTokenWeight(_whitelistedNFT, _tokenId);
        token.lastWeight = token.dailyWeight[_currentDay];

        owner.stakedWhitelistedNFTCount = owner.stakedWhitelistedNFTCount.sub(1);

        if(token.lastWeight <= owner.lastWeight){
            owner.lastWeight = owner.lastWeight.sub(token.lastWeight);
        }

        if(token.lastWeight <= owner.dailyWeight[_currentDay]){
            owner.dailyWeight[_currentDay] = owner.dailyWeight[_currentDay].sub(token.lastWeight);
        }

        stakedWhitelistedNFTCount = stakedWhitelistedNFTCount.sub(1);

        if (stakedWhitelistedNFTCount == 0) {
            totalWhitelistedNFTTokenWeight = 0;
        }


        if(token.lastWeight <= totalWhitelistedNFTTokenWeight) {
            totalWhitelistedNFTTokenWeight = (totalWhitelistedNFTTokenWeight.sub(token.lastWeight));
        }

        updateWhitelistedNFTOwnerWeight(_tokenOwner);

        owner.lastUpdateDay = _currentDay;
        lastUpdateDay = (_currentDay);


        delete whitelistedNFTTokenOwner[_whitelistedNFT][ _tokenId];

        emit UnstakedWhitelistedNFTToken(_tokenOwner, _whitelistedNFT, _tokenId);
    }

    function _msgSender() internal view returns (address payable sender) {
        return msg.sender;
    }

    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }

    function _getNow() internal virtual view returns (uint256) {
        return block.timestamp;
    }
}