/**
 *Submitted for verification at polygonscan.com on 2022-01-20
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;


//
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

//

//
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

//
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

//
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

//
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

//
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

//
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

//
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

//
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

//
interface IModelsNFT is IERC721 {
    function isApproved(uint256 _tokenId, address _operator) external view returns (bool);
    function setPrimarySalePrice(uint256 _tokenId, uint256 _salePrice) external;
    function garmentDesigners(uint256 _tokenId) external view returns (address);
    function garmentModels(uint256 _tokenId) external view returns (address);
    function mint(address _beneficiary, string calldata _tokenUri, address _designer, address _model) external returns (uint256);
    function burn(uint256 _tokenId) external;
}

//
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

//
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

//
interface IDigitalaxAccessControls {
    /**
     * @notice Used to check whether an address has the admin role
     * @param _address EOA or contract being checked
     * @return bool True if the account has the role or false if it does not
     */
    function hasAdminRole(address _address) external view returns (bool);

    function hasMinterRole(address _address) external view returns (bool);

    function hasVerifiedMinterRole(address _address)
        external
        view
        returns (bool);

    /**
     * @notice Used to check whether an address has the smart contract role
     * @param _address EOA or contract being checked
     * @return bool True if the account has the role or false if it does not
     */
    function hasSmartContractRole(address _address) external view returns (bool);
}

//
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

//
interface IDigitalaxMaterials is IERC1155 {
    function createChild(string calldata _uri) external returns (uint256);
    function batchCreateChildren(string[] calldata _uris) external returns (uint256[] memory);
    function mintChild(uint256 _childTokenId, uint256 _amount, address _beneficiary, bytes calldata _data) external;
    function batchMintChildren(uint256[] calldata _childTokenIds, uint256[] calldata _amounts, address _beneficiary, bytes calldata _data) external;
}

/**
 * @notice Collection contract for Digitalax NFTs
 */
contract ModelsCollection is Context, IERC721Receiver, IERC1155Receiver {
    using SafeMath for uint256;

    /// @notice Event emitted only on construction. To be used by indexers
    event DigitalaxGarmentCollectionContractDeployed();
    event MintGarmentCollection(
        uint256 collectionId,
        uint256 auctionTokenId,
        string rarity
    );
    event BurnGarmentCollection(
        uint256 collectionId
    );

    /// @notice Parameters of a NFTs Collection
    struct Collection {
        uint256[] garmentTokenIds;
        uint256 garmentAmount;
        string metadata;
        address designer;
        address model;
        uint256 auctionTokenId;
        string rarity;
    }
    /// @notice Garment ERC721 NFT - the only NFT that can be offered in this contract
    IModelsNFT public garmentNft;
    /// @notice responsible for enforcing admin access
    IDigitalaxAccessControls public accessControls;
    /// @dev Array of garment collections
    Collection[] private garmentCollections;
    /// @notice the child ERC1155 strand tokens
    IDigitalaxMaterials public materials;

    /// @dev max ERC721 Garments a Collection can hold
    /// @dev if admin configuring this value, should test previously how many parents x children can do in one call due to gas
    uint256 public maxGarmentsPerCollection;
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bool initialized;
    mapping(bytes4 => bool) private _supportedInterfaces;

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
    /**
     @param _accessControls Address of the Digitalax access control contract
     @param _garmentNft Garment NFT token address
     */
    function initialize(
        IDigitalaxAccessControls _accessControls,
        IModelsNFT _garmentNft,
        IDigitalaxMaterials _materials
    ) public {
        require(!initialized);
         _registerInterface(
            IERC1155Receiver(address(0)).onERC1155Received.selector ^
            IERC1155Receiver(address(0)).onERC1155BatchReceived.selector
         );

        _registerInterface(_INTERFACE_ID_ERC165);

        require(address(_accessControls) != address(0), "DigitalaxGarmentCollection: Invalid Access Controls");
        require(address(_garmentNft) != address(0), "DigitalaxGarmentCollection: Invalid NFT");
        require(address(_materials) != address(0), "DigitalaxGarmentCollection: Invalid Child ERC1155 address");
        accessControls = _accessControls;
        garmentNft = _garmentNft;
        materials = _materials;
        maxGarmentsPerCollection = 25;
        initialized = true;
        emit DigitalaxGarmentCollectionContractDeployed();
    }

    /**
     @notice Method for mint the NFT collection with the same metadata
     @param _tokenUri URI for the metadata
     @param _designer Garment designer address
     @param _amount NFTs amount of the collection
     */
    function mintCollection(
        string calldata _tokenUri,
        address _designer,
        address _model,
        uint256 _amount,
        uint256 _auctionId,
        string calldata _rarity,
        uint256[] calldata _childTokenIds,
        uint256[] calldata _childTokenAmounts
    ) external returns (uint256) {
        require(
            accessControls.hasAdminRole(_msgSender()) || accessControls.hasSmartContractRole(_msgSender()) || accessControls.hasMinterRole(_msgSender()),
            "DigitalaxGarmentCollection.mintCollection: Sender must have the minter or contract role"
        );

        require(
            _amount <= maxGarmentsPerCollection,
            "DigitalaxGarmentCollection.mintCollection: Amount cannot exceed maxGarmentsPerCollection"
        );

        Collection memory _newCollection = Collection(new uint256[](0), _amount, _tokenUri, _designer, _model, _auctionId, _rarity);
        uint256 _collectionId = garmentCollections.length;
        garmentCollections.push(_newCollection);

        for (uint i = 0; i < _amount; i ++) {
            uint256 _mintedTokenId = garmentNft.mint(_msgSender(), _newCollection.metadata, _newCollection.designer, _newCollection.model);

            // Batch mint child tokens and assign to generated 721 token ID
            if(_childTokenIds.length > 0){
                materials.batchMintChildren(_childTokenIds, _childTokenAmounts, address(garmentNft), abi.encodePacked(_mintedTokenId));
            }
            garmentCollections[_collectionId].garmentTokenIds.push(_mintedTokenId);
        }

        emit MintGarmentCollection(_collectionId, _auctionId, _rarity);
        return _collectionId;
    }

    /**
     @notice Method for mint more nfts on an existing collection
     @param _amount NFTs amount of the collection
     */
    function mintMoreNftsOnCollection(
        uint256 _collectionId,
        uint256 _amount,
        uint256[] calldata _childTokenIds,
        uint256[] calldata _childTokenAmounts
    ) external returns (uint256) {
        require(
            accessControls.hasAdminRole(_msgSender()) || accessControls.hasSmartContractRole(_msgSender()) || accessControls.hasMinterRole(_msgSender()),
            "DigitalaxGarmentCollection.mintMoreNftsOnCollection: Sender must have the minter or contract role"
        );

        require(
            _amount <= maxGarmentsPerCollection,
            "DigitalaxGarmentCollection.mintMoreNftsOnCollection: Amount cannot exceed maxGarmentsPerCollection"
        );

        Collection storage _collection = garmentCollections[_collectionId];

        for (uint i = 0; i < _amount; i ++) {
            uint256 _mintedTokenId = garmentNft.mint(_msgSender(), _collection.metadata, _collection.designer, _collection.model);

            // Batch mint child tokens and assign to generated 721 token ID
            if(_childTokenIds.length > 0){
                materials.batchMintChildren(_childTokenIds, _childTokenAmounts, address(garmentNft), abi.encodePacked(_mintedTokenId));
            }
            garmentCollections[_collectionId].garmentTokenIds.push(_mintedTokenId);
        }

        _collection.garmentAmount = _collection.garmentAmount.add(_amount);

        emit MintGarmentCollection(_collectionId, _collection.auctionTokenId, _collection.rarity);
        return _collectionId;
    }

    /**
     @notice Method for burn the NFT collection by given collection id
     @param _collectionId Id of the collection
     */
    function burnCollection(uint256 _collectionId) external {
        Collection storage collection = garmentCollections[_collectionId];

        for (uint i = 0; i < collection.garmentAmount; i ++) {
            uint256 tokenId = collection.garmentTokenIds[i];
            garmentNft.safeTransferFrom(garmentNft.ownerOf(tokenId), address(this), tokenId);
            garmentNft.burn(tokenId);
        }
        emit BurnGarmentCollection(_collectionId);
        delete garmentCollections[_collectionId];
    }

    /**
     @notice Method for updating max nfts garments a collection can hold
     @dev Only admin
     @param _maxGarmentsPerCollection uint256 the max children a token can hold
     */
    function updateMaxGarmentsPerCollection(uint256 _maxGarmentsPerCollection) external {
        require(accessControls.hasAdminRole(_msgSender()), "DigitalaxGarmentCollection.updateMaxGarmentsPerCollection: Sender must be admin");
        maxGarmentsPerCollection = _maxGarmentsPerCollection;
    }

    /**
     @notice Method for getting the collection by given collection id
     @param _collectionId Id of the collection
     */
    function getCollection(uint256 _collectionId)
    external
    view
    returns (uint256[] memory _garmentTokenIds, uint256 _amount, string memory _tokenUri, address _designer, address _model) {
        Collection memory collection = garmentCollections[_collectionId];
        return (
            collection.garmentTokenIds,
            collection.garmentAmount,
            collection.metadata,
            collection.designer,
            collection.model
        );
    }

    /**
     @notice Method for getting NFT tokenIds of the collection.
     @param _collectionId Id of the collection
     */
    function getTokenIds(uint256 _collectionId) external view returns (uint256[] memory _garmentTokenIds) {
        Collection memory collection = garmentCollections[_collectionId];
        return collection.garmentTokenIds;
    }

    /**
     @notice Method for getting max supply of the collection.
     @param _collectionId Id of the collection
     */
    function getSupply(uint256 _collectionId) external view returns (uint256) {
        Collection storage collection = garmentCollections[_collectionId];
        return collection.garmentAmount;
    }

    /**
     @notice Method for getting the NFT amount for the given address and collection id
     @param _collectionId Id of the collection
     @param _address Given address
     */
    function balanceOfAddress(uint256 _collectionId, address _address) external view returns (uint256) {
        return _balanceOfAddress(_collectionId, _address);
    }

    /**
     @notice Method for checking if someone owns the collection
     @param _collectionId Id of the collection
     @param _address Given address
     */
    function hasOwnedOf(uint256 _collectionId, address _address) external view returns (bool) {
        Collection storage collection = garmentCollections[_collectionId];
        uint256 amount = _balanceOfAddress(_collectionId, _address);
        return amount == collection.garmentAmount;
    }

    /**
     @notice Internal method for getting the NFT amount of the collection
     */

    function _balanceOfAddress(uint256 _collectionId, address _address) internal virtual view returns (uint256) {
        Collection storage collection = garmentCollections[_collectionId];
        uint256 _amount;
        for (uint i = 0; i < collection.garmentAmount; i ++) {
            if (garmentNft.ownerOf(collection.garmentTokenIds[i]) == _address) {
                _amount = _amount.add(1);
            }
        }
        return _amount;
    }

    /**
     @notice Method for updating the access controls contract
     @dev Only admin
     @param _accessControls Address of the new access controls contract
     */
    function updateAccessControls(IDigitalaxAccessControls _accessControls) external {
        require(accessControls.hasAdminRole(_msgSender()), "DigitalaxGarmentCollection.updateAccessControls: Sender must be admin");
        accessControls = _accessControls;
    }

    /**
     @notice Single ERC721 receiver callback hook
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public
    override
    returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     @notice Single ERC1155 receiver callback hook, used to enforce children token binding to a given parent token
     */
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes memory _data)
    virtual
    external
    override
    returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     @notice Batch ERC1155 receiver callback hook, used to enforce child token bindings to a given parent token ID
     */
    function onERC1155BatchReceived(address _operator, address _from, uint256[] memory _ids, uint256[] memory _values, bytes memory _data)
    virtual
    external
    override
    returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {

    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function msgSender() internal virtual view returns (address payable);

    function versionRecipient() external virtual view returns (string memory);
}

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address public trustedForwarder;

    /*
     * require a function to be called through GSN only
     */
    modifier trustedForwarderOnly() {
        require(msg.sender == address(trustedForwarder), "Function can only be called through the trusted Forwarder");
        _;
    }

    function isTrustedForwarder(address forwarder) public override view returns(bool) {
        return forwarder == trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function msgSender() internal override view returns (address payable ret) {
        if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            return msg.sender;
        }
    }
}

//
interface IDigitalaxMonaOracle {
    function getData() external returns (uint256, bool);
}

/**
 * @notice Marketplace contract for Digitalax NFTs
 */
contract ModelsMarketplace is BaseRelayRecipient {
    using SafeMath for uint256;
    /// @notice Event emitted only on construction. To be used by indexers
    event DigitalaxMarketplaceContractDeployed();
    event CollectionPauseToggled(
        uint256 indexed garmentCollectionId,
        bool isPaused
    );
    event PauseToggled(
        bool isPaused
    );
    event FreezeMonaERC20PaymentToggled(
        bool freezeMonaERC20Payment
    );
    event FreezeETHPaymentToggled(
        bool freezeETHPayment
    );
    event OfferCreated(
        uint256 indexed garmentCollectionId,
        uint256 primarySalePrice,
        uint256 startTime,
        uint256 endTime,
        uint256 platformFee,
        uint256 discountToPayERC20,
        uint256 maxAmount
    );
    event UpdateAccessControls(
        address indexed accessControls
    );
    event UpdateMarketplacePlatformFee(
        uint256 indexed garmentCollectionId,
        uint256 platformFee
    );
    event UpdateMarketplaceDiscountToPayInErc20(
        uint256 indexed garmentCollectionId,
        uint256 discount
    );
    event UpdateOfferPrimarySalePrice(
        uint256 indexed garmentCollectionId,
        uint256 primarySalePrice
    );
    event UpdateDesignerOverride(
        uint256 indexed garmentCollectionId,
        address[] designersOverride,
        uint256[] designerShare
    );
    event UpdateOfferMaxAmount(
        uint256 indexed garmentCollectionId,
        uint256 maxAmount
    );
    event UpdateOfferStartEnd(
        uint256 indexed garmentCollectionId,
        uint256 startTime,
        uint256 endTime
    );
    event UpdateOracle(
        address indexed oracle
    );
    event UpdatePlatformFeeRecipient(
        address payable platformFeeRecipient
    );
    event UpdateCoolDownDuration(
        uint256 cooldown
    );
    event OfferPurchased(
        uint256 indexed bundleTokenId,
        uint256 indexed garmentCollectionId,
        address indexed buyer,
        uint256 primarySalePrice,
        bool paidInErc20,
        uint256 monaTransferredAmount,
        uint256 platformFee,
        uint256 discountToPayInERC20
    );
    event OfferCancelled(
        uint256 indexed bundleTokenId
    );
    /// @notice Parameters of a marketplace offer
    struct Offer {
        uint256 primarySalePrice;
        uint256 startTime;
        uint256 endTime;
        uint256 availableIndex;
        uint256 platformFee;
        uint256 discountToPayERC20;
        uint256 maxAmount;
        bool paused;
        address[] designersOverride;
        uint256[] designerShare;
    }

    /// @notice Garment ERC721 Collection ID -> Offer Parameters
    mapping(uint256 => Offer) public offers;
    /// @notice KYC Garment Designers -> Number of times they have sold in this marketplace (To set fee accordingly)
    mapping(address => uint256) public numberOfTimesSold;
    /// @notice Garment Collection ID -> Buyer -> Last purhcased time
    mapping(uint256 => mapping(address => uint256)) public lastPurchasedTime;
    /// @notice Garment ERC721 NFT - the only NFT that can be offered in this contract
    IModelsNFT public garmentNft;
    /// @notice Garment NFT Collection
    ModelsCollection public garmentCollection;
    /// @notice oracle for MONA/ETH exchange rate
    IDigitalaxMonaOracle public oracle;
    /// @notice responsible for enforcing admin access
    DigitalaxAccessControls public accessControls;
    /// @notice where to send platform fee funds to
    address payable public platformFeeRecipient;
    /// @notice for pausing marketplace functionalities
    bool public isPaused;
    /// @notice the erc20 token
    address public monaErc20Token;
    /// @notice for freezing mona payment option
    bool public freezeMonaERC20Payment;
    /// @notice Cool down period
    uint256 public cooldown;
    /// @notice for storing information from oracle
    uint256 public lastOracleQuote;

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    bool initialized;

    uint256 private _status;

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }

    modifier whenNotPaused() {
        require(!isPaused, "Function is currently paused");
        _;
    }

    receive() external payable {
    }
    function initialize(
        DigitalaxAccessControls _accessControls,
        IModelsNFT _garmentNft,
        ModelsCollection _garmentCollection,
        IDigitalaxMonaOracle _oracle,
        address payable _platformFeeRecipient,
        address _monaErc20Token,
        address _trustedForwarder
    ) public {
        require(!initialized);
        require(address(_accessControls) != address(0), "DigitalaxMarketplace: Invalid Access Controls");
        require(address(_garmentNft) != address(0), "DigitalaxMarketplace: Invalid NFT");
        require(address(_garmentCollection) != address(0), "DigitalaxMarketplace: Invalid Collection");
        require(address(_oracle) != address(0), "DigitalaxMarketplace: Invalid Oracle");
        require(_platformFeeRecipient != address(0), "DigitalaxMarketplace: Invalid Platform Fee Recipient");
        require(_monaErc20Token != address(0), "DigitalaxMarketplace: Invalid ERC20 Token");
        oracle = _oracle;
        accessControls = _accessControls;
        garmentNft = _garmentNft;
        garmentCollection = _garmentCollection;
        monaErc20Token = _monaErc20Token;
        platformFeeRecipient = _platformFeeRecipient;
        trustedForwarder = _trustedForwarder;
        cooldown = 60;
        lastOracleQuote = 1e18;
        _status = _NOT_ENTERED;

        initialized = true;
        emit DigitalaxMarketplaceContractDeployed();
    }


    /**
     * Override this function.
     * This version is to keep track of BaseRelayRecipient you are using
     * in your contract.
     */
    function versionRecipient() external view override returns (string memory) {
        return "1";
    }

    function setTrustedForwarder(address _trustedForwarder) external  {
        require(
            accessControls.hasAdminRole(_msgSender()),
            "DigitalaxMaterials.setTrustedForwarder: Sender must be admin"
        );
        trustedForwarder = _trustedForwarder;
    }

    // This is to support Native meta transactions
    // never use msg.sender directly, use _msgSender() instead
    function _msgSender()
    internal
    view
    returns (address payable sender)
    {
        return BaseRelayRecipient.msgSender();
    }

    /**
     @notice Method for updating oracle
     @dev Only admin
     @param _oracle new oracle
     */
    function updateOracle(IDigitalaxMonaOracle _oracle) external {
    require(
        accessControls.hasAdminRole(_msgSender()),
        "DigitalaxAuction.updateOracle: Sender must be admin"
        );

        oracle = _oracle;
        emit UpdateOracle(address(_oracle));
    }

    /**
     @notice Private method to estimate ETH for paying
     @param _amountInMona MONA amount in wei
     */
    function _estimateETHAmount(uint256 _amountInMona) public returns (uint256) {
        (uint256 exchangeRate, bool rateValid) = oracle.getData();
        require(rateValid, "DigitalaxMarketplace.estimateMonaAmount: Oracle data is invalid");
        lastOracleQuote = exchangeRate;

        return _amountInMona.mul(exchangeRate).div(1e18);
    }

    /**
     @notice Creates a new offer for a given garment
     @dev Only the owner of a garment can create an offer and must have ALREADY approved the contract
     @dev In addition to owning the garment, the sender also has to have the MINTER or ADMIN role.
     @dev End time for the offer will be in the future, at a time from now till expiry duration
     @dev There cannot be a duplicate offer created
     @param _garmentCollectionId Collection ID of the garment being offered to marketplace
     @param _primarySalePrice Garment cannot be sold for less than this
     @param _startTimestamp when the sale starts
     @param _endTimestamp when the sale ends
     @param _platformFee Percentage to pay out to the platformFeeRecipient, 1 decimal place (i.e. 40% is 400)
     @param _maxAmount Max number of products from this collection that someone can buy
     @param _designersOverride designers to use instead of contract one
     @param _designerShare share to give the designers - must add up to 100% and has 2 decimal places (50% = 5000)
     */
    function createOffer(
        uint256 _garmentCollectionId,
        uint256 _primarySalePrice,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256 _platformFee,
        uint256 _maxAmount,
        address[] memory _designersOverride,
        uint256[] memory _designerShare
    ) external {
        // Ensure caller has privileges
        require(
            accessControls.hasMinterRole(_msgSender()) || accessControls.hasAdminRole(_msgSender()),
            "DigitalaxMarketplace.createOffer: Sender must have the minter or admin role"
        );
        // Ensure the collection does exists
        require(garmentCollection.getSupply(_garmentCollectionId) > 0, "DigitalaxMarketplace.createOffer: Collection does not exist");
        // Check owner of the collection is the owner and approved
        require(
            garmentCollection.hasOwnedOf(_garmentCollectionId, _msgSender()) && _isCollectionApproved(_garmentCollectionId, address(this)),
            "DigitalaxMarketplace.createOffer: Not owner and or contract not approved"
        );
        // Ensure the maximum purchaseable amount is less than collection supply
        require(_maxAmount <= garmentCollection.getSupply(_garmentCollectionId), "DigitalaxMarketplace.createOffer: Invalid Maximum amount");
        // Ensure the end time stamp is valid
        require(_endTimestamp > _startTimestamp, "DigitalaxMarketplace.createOffer: Invalid end time");

        _createOffer(
            _garmentCollectionId,
            _primarySalePrice,
            _startTimestamp,
            _endTimestamp,
            _platformFee,
            _maxAmount,
            false,
            _designersOverride,
            _designerShare
        );
    }

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
     @notice Buys an open offer with eth or erc20
     @dev Only callable when the offer is open
     @dev Bids from smart contracts are prohibited - a user must buy directly from their address
     @dev Contract must have been approved on the buy offer previously
     @dev The sale must have started (start time) to make a successful buy
     @param _garmentCollectionId Collection ID of the garment being offered
     */
    function buyOffer(uint256 _garmentCollectionId) external payable whenNotPaused nonReentrant {
        // Check the offers to see if this is a valid
        require(isContract(_msgSender()) == false, "DigitalaxMarketplace.buyOffer: No contracts permitted");
        require(_isFinished(_garmentCollectionId) == false, "DigitalaxMarketplace.buyOffer: Sale has been finished");
        require(lastPurchasedTime[_garmentCollectionId][_msgSender()] <= _getNow().sub(cooldown), "DigitalaxMarketplace.buyOffer: Cooldown not reached");

        Offer storage offer = offers[_garmentCollectionId];
        require(
            garmentCollection.balanceOfAddress(_garmentCollectionId, _msgSender()) < offer.maxAmount,
            "DigitalaxMarketplace.buyOffer: Can't purchase over maximum amount"
        );
        require(!offer.paused, "DigitalaxMarketplace.buyOffer: Can't purchase when paused");

        uint256[] memory bundleTokenIds = garmentCollection.getTokenIds(_garmentCollectionId);
        uint256 bundleTokenId = bundleTokenIds[offer.availableIndex];
        uint256 maxShare = 1000;

        // Ensure this contract is still approved to move the token
        require(garmentNft.isApproved(bundleTokenId, address(this)), "DigitalaxMarketplace.buyOffer: offer not approved");
        require(_getNow() >= offer.startTime, "DigitalaxMarketplace.buyOffer: Purchase outside of the offer window");

        uint256 feeInMona = offer.primarySalePrice.mul(offer.platformFee).div(maxShare);

        require(!freezeMonaERC20Payment, "DigitalaxMarketplace.buyOffer: mona erc20 payments currently frozen");

        // Designer receives (Primary Sale Price minus Protocol Fee)
        uint256 amountOfMonaToTransferToDesigner = offer.primarySalePrice.sub(feeInMona);

        // There is a discount on Fees paying in Mona
        uint256 amountOfDiscountOnMonaPrice = offer.primarySalePrice.mul(offer.discountToPayERC20).div(maxShare);
        uint256 amountOfMonaToTransferAsFees = feeInMona.sub(amountOfDiscountOnMonaPrice);


        // Check that there is enough ERC20 to cover the rest of the value (minus the discount already taken)
        require(IERC20(monaErc20Token).allowance(_msgSender(), address(this)) >= offer.primarySalePrice, "DigitalaxMarketplace.buyOffer: Failed to supply ERC20 Allowance");
         // Transfer ERC20 token from user to contract(this) escrow

        // For the garment designer splits. If there is a [] [] passed on create offer, then it defaults to the NFT designer address
        // If there are designers specified in the createOffer, then that exact configuration will be respected here
        // So we either have default designer, or multi designers

        if(offer.designersOverride.length > 0) { // First try based on the designers override split
            for (uint i = 0; i < offer.designersOverride.length; i++) {
                uint256 payoutToDesigner = offer.designerShare[i].mul(amountOfMonaToTransferToDesigner).div(uint256(1000));
                IERC20(monaErc20Token).transferFrom(_msgSender(),  offer.designersOverride[i], payoutToDesigner);
            }
        } else{ // If there is no garment model, send to designer address
            if(garmentNft.garmentModels(bundleTokenId) == address(0)){
                IERC20(monaErc20Token).transferFrom(_msgSender(), garmentNft.garmentDesigners(bundleTokenId), amountOfMonaToTransferToDesigner);
            } // If there is no designer address, send to model
            else if(garmentNft.garmentDesigners(bundleTokenId) == address(0)) {
                IERC20(monaErc20Token).transferFrom(_msgSender(), garmentNft.garmentModels(bundleTokenId), amountOfMonaToTransferToDesigner);
            } else { // Or else send them 50/50
                IERC20(monaErc20Token).transferFrom(_msgSender(), garmentNft.garmentDesigners(bundleTokenId), amountOfMonaToTransferToDesigner.div(uint256(2)));
                IERC20(monaErc20Token).transferFrom(_msgSender(), garmentNft.garmentModels(bundleTokenId), amountOfMonaToTransferToDesigner.div(uint256(2)));
            }
        }

        IERC20(monaErc20Token).transferFrom(_msgSender(), platformFeeRecipient, amountOfMonaToTransferAsFees);

        offer.availableIndex = offer.availableIndex.add(1);
        // Record the primary sale price for the garment
        garmentNft.setPrimarySalePrice(bundleTokenId, _estimateETHAmount(offer.primarySalePrice));
        // Transfer the token to the purchaser
        garmentNft.safeTransferFrom(garmentNft.ownerOf(bundleTokenId), _msgSender(), bundleTokenId);
        lastPurchasedTime[_garmentCollectionId][_msgSender()] = _getNow();

        emit OfferPurchased(bundleTokenId, _garmentCollectionId, _msgSender(), offer.primarySalePrice, true, offer.primarySalePrice, offer.platformFee, offer.discountToPayERC20);
    }
    /**
     @notice Cancels an inflight and un-resulted offer
     @dev Only admin
     @param _garmentCollectionId Token ID of the garment being offered
     */
    function cancelOffer(uint256 _garmentCollectionId) external nonReentrant {
        // Admin only resulting function
        require(
            accessControls.hasAdminRole(_msgSender()) || accessControls.hasMinterRole(_msgSender()),
            "DigitalaxMarketplace.cancelOffer: Sender must be admin or minter contract"
        );
        // Check valid and not resulted
        Offer storage offer = offers[_garmentCollectionId];
        require(offer.primarySalePrice != 0, "DigitalaxMarketplace.cancelOffer: Offer does not exist");
        // Remove offer
        delete offers[_garmentCollectionId];
        emit OfferCancelled(_garmentCollectionId);
    }

    /**
     @notice Toggling the pause flag
     @dev Only admin
     */
    function togglePaused(uint256 _garmentCollectionId) external {
        require(accessControls.hasAdminRole(_msgSender()), "DigitalaxMarketplace.togglePaused: Sender must be admin");
        Offer storage offer = offers[_garmentCollectionId];
        offer.paused = !offer.paused;
        emit CollectionPauseToggled(_garmentCollectionId, offer.paused);
    }

    /**
     @notice Toggling the pause flag
     @dev Only admin
     */
    function toggleIsPaused() external {
        require(accessControls.hasAdminRole(_msgSender()), "DigitalaxMarketplace.toggleIsPaused: Sender must be admin");
        isPaused = !isPaused;
        emit PauseToggled(isPaused);
    }

    /**
     @notice Toggle freeze Mona ERC20
     @dev Only admin
     */
    function toggleFreezeMonaERC20Payment() external {
        require(accessControls.hasAdminRole(_msgSender()), "DigitalaxMarketplace.toggleFreezeMonaERC20Payment: Sender must be admin");
        freezeMonaERC20Payment = !freezeMonaERC20Payment;
        emit FreezeMonaERC20PaymentToggled(freezeMonaERC20Payment);
    }

    /**
     @notice Update the marketplace discount
     @dev Only admin
     @dev This discount is taken away from the received fees, so the discount cannot exceed the platform fee
     @param _garmentCollectionId Collection ID of the garment being offered
     @param _marketplaceDiscount New marketplace discount
     */
    function updateMarketplaceDiscountToPayInErc20(uint256 _garmentCollectionId, uint256 _marketplaceDiscount) external {
        require(accessControls.hasAdminRole(_msgSender()), "DigitalaxMarketplace.updateMarketplaceDiscountToPayInErc20: Sender must be admin");
        require(_marketplaceDiscount <= offers[_garmentCollectionId].platformFee, "DigitalaxMarketplace.updateMarketplaceDiscountToPayInErc20: Discount cannot be greater then fee");
        offers[_garmentCollectionId].discountToPayERC20 = _marketplaceDiscount;
        emit UpdateMarketplaceDiscountToPayInErc20(_garmentCollectionId, _marketplaceDiscount);
    }

    /**
     @notice Update the marketplace fee
     @dev Only admin
     @dev There is a discount that can be taken away from received fees, so that discount cannot exceed the platform fee
     @param _garmentCollectionId Collection ID of the garment being offered
     @param _platformFee New marketplace fee
     */
    function updateMarketplacePlatformFee(uint256 _garmentCollectionId, uint256 _platformFee) external {
        require(accessControls.hasAdminRole(_msgSender()), "DigitalaxMarketplace.updateMarketplacePlatformFee: Sender must be admin");
        require(_platformFee >= offers[_garmentCollectionId].discountToPayERC20, "DigitalaxMarketplace.updateMarketplacePlatformFee: Discount cannot be greater then fee");
        offers[_garmentCollectionId].platformFee = _platformFee;
        emit UpdateMarketplacePlatformFee(_garmentCollectionId, _platformFee);
    }

    /**
     @notice Update the offer primary sale price
     @dev Only admin
     @param _garmentCollectionId Collection ID of the garment being offered
     @param _primarySalePrice New price
     */
    function updateOfferPrimarySalePrice(uint256 _garmentCollectionId, uint256 _primarySalePrice) external {
        require(accessControls.hasAdminRole(_msgSender()), "DigitalaxMarketplace.updateOfferPrimarySalePrice: Sender must be admin");

        offers[_garmentCollectionId].primarySalePrice = _primarySalePrice;
        emit UpdateOfferPrimarySalePrice(_garmentCollectionId, _primarySalePrice);
    }

    /**
     @notice Update the offer primary sale price
     @dev Only admin
     @param _garmentCollectionId Collection ID of the garment being offered
     @param _designersOverride designer addresses
     @param _designerShare designer shares, adding up to 100% (1000) 1 decimal place
     */
    function updateOfferDesignerOverrideShare(uint256 _garmentCollectionId, address[] memory _designersOverride, uint256[] memory _designerShare) external {
        require(accessControls.hasAdminRole(_msgSender()), "DigitalaxMarketplace.updateOfferPrimarySalePrice: Sender must be admin");
        require(_designersOverride.length == _designerShare.length, "Array lengths");
        uint256 shareTotal = 0;
         for (uint i = 0; i < _designerShare.length; i++) {
            shareTotal = shareTotal.add(_designerShare[i]);
        }
        require(shareTotal == 1000, "The designer share distro must add up to 100 percent, 1000");

        offers[_garmentCollectionId].designersOverride = _designersOverride;
        offers[_garmentCollectionId].designerShare = _designerShare;
        emit UpdateDesignerOverride(_garmentCollectionId, _designersOverride, _designerShare);
    }

    /**
     @notice Update the offer max amount
     @dev Only admin
     @param _garmentCollectionId Collection ID of the garment being offered
     @param _maxAmount New amount
     */
    function updateOfferMaxAmount(uint256 _garmentCollectionId, uint256 _maxAmount) external {
        require(accessControls.hasAdminRole(_msgSender()), "DigitalaxMarketplace.updateOfferMaxAmount: Sender must be admin");

        offers[_garmentCollectionId].maxAmount = _maxAmount;
        emit UpdateOfferMaxAmount(_garmentCollectionId, _maxAmount);
    }

    /**
     @notice Update the offer start and end time
     @dev Only admin
     @param _garmentCollectionId Collection ID of the garment being offered
     @param _startTime start time
     @param _endTime end time
     */
    function updateOfferStartEndTime(uint256 _garmentCollectionId, uint256 _startTime, uint256 _endTime) external {
        require(accessControls.hasAdminRole(_msgSender()), "DigitalaxMarketplace.updateOfferPrimarySalePrice: Sender must be admin");
        require(_endTime > _startTime, "DigitalaxMarketplace.createOffer: Invalid end time");
        offers[_garmentCollectionId].startTime = _startTime;
        offers[_garmentCollectionId].endTime = _endTime;
        emit UpdateOfferStartEnd(_garmentCollectionId, _startTime, _endTime);
    }

    /**
     @notice Update cool down duration
     @dev Only admin
     @param _cooldown New cool down duration
     */
    function updateCoolDownDuration(uint256 _cooldown) external {
        require(accessControls.hasAdminRole(_msgSender()), "DigitalaxMarketplace.updateCoolDownDuration: Sender must be admin");

        cooldown = _cooldown;
        emit UpdateCoolDownDuration(_cooldown);
    }

    /**
     @notice Method for updating the access controls contract used by the NFT
     @dev Only admin
     @param _accessControls Address of the new access controls contract (Cannot be zero address)
     */
    function updateAccessControls(DigitalaxAccessControls _accessControls) external {
        require(
            accessControls.hasAdminRole(_msgSender()),
            "DigitalaxMarketplace.updateAccessControls: Sender must be admin"
        );
        require(address(_accessControls) != address(0), "DigitalaxMarketplace.updateAccessControls: Zero Address");
        accessControls = _accessControls;
        emit UpdateAccessControls(address(_accessControls));
    }

    /**
     @notice Method for updating platform fee address
     @dev Only admin
     @param _platformFeeRecipient payable address the address to sends the funds to
     */
    function updatePlatformFeeRecipient(address payable _platformFeeRecipient) external {
        require(
            accessControls.hasAdminRole(_msgSender()),
            "DigitalaxMarketplace.updatePlatformFeeRecipient: Sender must be admin"
        );
        require(_platformFeeRecipient != address(0), "DigitalaxMarketplace.updatePlatformFeeRecipient: Zero address");
        platformFeeRecipient = _platformFeeRecipient;
        emit UpdatePlatformFeeRecipient(_platformFeeRecipient);
    }

    ///////////////
    // Accessors //
    ///////////////
    /**
     @notice Method for getting all info about the offer
     @param _garmentCollectionId Token ID of the garment being offered
     */
    function getOffer(uint256 _garmentCollectionId)
    external
    view
    returns (uint256 _primarySalePrice, uint256 _startTime, uint256 _endTime, uint256 _availableAmount, uint _platformFee, uint256 _discountToPayERC20) {
        Offer storage offer = offers[_garmentCollectionId];
        uint256 availableAmount = garmentCollection.getSupply(_garmentCollectionId).sub(offer.availableIndex);
        return (
            offer.primarySalePrice,
            offer.startTime,
            offer.endTime,
            availableAmount,
            offer.platformFee,
            offer.discountToPayERC20
        );
    }

// TODO get Offer for all the designer shares

    ///////////////
    // Accessors //
    ///////////////
    /**
     @notice Method for getting all info about the offer
     @param _garmentCollectionId Token ID of the garment being offered
     */
    function getOfferMaxAmount(uint256 _garmentCollectionId)
    external
    view
    returns (uint256 _maxAmount) {
        Offer storage offer = offers[_garmentCollectionId];
        return (
            offer.maxAmount
        );
    }

    /////////////////////////
    // Internal and Private /
    /////////////////////////
    function _getNow() internal virtual view returns (uint256) {
        return block.timestamp;
    }

    function _isCollectionApproved(uint256 _collectionId, address _address) internal virtual returns (bool) {
        uint256[] memory tokenIds = garmentCollection.getTokenIds(_collectionId);
        for (uint i = 0; i < tokenIds.length; i ++) {
            if (!garmentNft.isApproved(tokenIds[i], _address)) {
                return false;
            }
        }
        return true;
    }

    /**
     @notice Private method to check if the sale is finished
     @param _garmentCollectionId Id of the collection.
     */
    function _isFinished(uint256 _garmentCollectionId) internal virtual view returns (bool) {
        Offer memory offer = offers[_garmentCollectionId];

        if (offer.endTime < _getNow()) {
            return true;
        }

        uint256 availableAmount = garmentCollection.getSupply(_garmentCollectionId).sub(offer.availableIndex);
        return availableAmount <= 0;
    }

    /**
     @notice Private method doing the heavy lifting of creating an offer
     @param _garmentCollectionId Collection ID of the garment being offered
     @param _primarySalePrice Garment cannot be sold for less than this
     @param _startTimestamp Unix epoch in seconds for the offer start time
     @param _platformFee Percentage to pay out to the platformFeeRecipient, 1 decimal place (i.e. 40% is 400)
     @param _paused is paused
     @param _designersOverride designers to use instead of contract one
     @param _designerShare share to give the designers - must add up to 100% and has 1 decimal places (50% = 500)

     */
    function _createOffer(
        uint256 _garmentCollectionId,
        uint256 _primarySalePrice,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256 _platformFee,
        uint256 _maxAmount,
        bool _paused,
        address[] memory _designersOverride,
        uint256[] memory _designerShare
    ) private {
        // Ensure a token cannot be re-listed if previously successfully sold
        require(offers[_garmentCollectionId].startTime == 0, "DigitalaxMarketplace.createOffer: Cannot duplicate current offer");

        if(_designersOverride.length > 0) {
            require (_designersOverride.length == _designerShare.length, "Array lengths for designer");

            uint256 shareTotal = 0;
            for (uint i = 0; i < _designerShare.length; i++) {
                shareTotal = shareTotal.add(_designerShare[i]);
            }
            require(shareTotal == 1000, "The designer share distro must add up to 100 percent, 1000");
        }

        // Setup the new offer
        offers[_garmentCollectionId] = Offer({
            primarySalePrice : _primarySalePrice,
            startTime : _startTimestamp,
            endTime: _endTimestamp,
            availableIndex : 0,
            platformFee: _platformFee,
            discountToPayERC20: 0,
            maxAmount: _maxAmount,
            paused: _paused,
            designersOverride: _designersOverride,
            designerShare: _designerShare
        });

        emit OfferCreated(_garmentCollectionId, _primarySalePrice, _startTimestamp, _endTimestamp, _platformFee, 0, _maxAmount);
        emit UpdateDesignerOverride(_garmentCollectionId, _designersOverride, _designerShare);
    }

    /**
    * @notice Reclaims ERC20 Compatible tokens for entire balance
    * @dev Only access controls admin
    * @param _tokenContract The address of the token contract
    */
    function reclaimERC20(address _tokenContract) external {
        require(
            accessControls.hasAdminRole(_msgSender()),
            "DigitalaxMarketplace.reclaimERC20: Sender must be admin"
        );
        require(_tokenContract != address(0), "Invalid address");
        IERC20 token = IERC20(_tokenContract);
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(_msgSender(), balance), "Transfer failed");
    }

    /**
     * @notice Reclaims ETH, drains all ETH sitting on the smart contract
     * @dev The instant buy feature means technically, ETH should never sit on contract.
     * @dev Only access controls admin can access
     */
    function reclaimETH() external {
        require(
            accessControls.hasAdminRole(_msgSender()),
            "DigitalaxMarketplace.reclaimETH: Sender must be admin"
        );
        _msgSender().transfer(address(this).balance);
    }
}