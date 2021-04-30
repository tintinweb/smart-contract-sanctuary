/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

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

contract AccessControlMixin is AccessControl {
    string private _revertMsg;
    function _setupContractId(string memory contractId) internal {
        _revertMsg = string(abi.encodePacked(contractId, ": INSUFFICIENT_PERMISSIONS"));
    }

    modifier only(bytes32 role) {
        require(
            hasRole(role, _msgSender()),
            _revertMsg
        );
        _;
    }
}

interface IStateSender {
    function syncState(address receiver, bytes calldata data) external;
}

/*
 * @author Hamdi Allam [email protected]
 * Please reach out with any questions or concerns
 * https://github.com/hamdiallam/Solidity-RLP/blob/e681e25a376dbd5426b509380bc03446f05d0f97/contracts/RLPReader.sol
 */
pragma solidity ^0.6.6;

library RLPReader {
    uint8 constant STRING_SHORT_START = 0x80;
    uint8 constant STRING_LONG_START = 0xb8;
    uint8 constant LIST_SHORT_START = 0xc0;
    uint8 constant LIST_LONG_START = 0xf8;
    uint8 constant WORD_SIZE = 32;

    struct RLPItem {
        uint256 len;
        uint256 memPtr;
    }

    /*
     * @param item RLP encoded bytes
     */
    function toRlpItem(bytes memory item)
        internal
        pure
        returns (RLPItem memory)
    {
        require(item.length > 0, "RLPReader: INVALID_BYTES_LENGTH");
        uint256 memPtr;
        assembly {
            memPtr := add(item, 0x20)
        }

        return RLPItem(item.length, memPtr);
    }

    /*
     * @param item RLP encoded list in bytes
     */
    function toList(RLPItem memory item)
        internal
        pure
        returns (RLPItem[] memory)
    {
        require(isList(item), "RLPReader: ITEM_NOT_LIST");

        uint256 items = numItems(item);
        RLPItem[] memory result = new RLPItem[](items);
        uint256 listLength = _itemLength(item.memPtr);
        require(listLength == item.len, "RLPReader: LIST_DECODED_LENGTH_MISMATCH");

        uint256 memPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint256 dataLen;
        for (uint256 i = 0; i < items; i++) {
            dataLen = _itemLength(memPtr);
            result[i] = RLPItem(dataLen, memPtr);
            memPtr = memPtr + dataLen;
        }

        return result;
    }

    // @return indicator whether encoded payload is a list. negate this function call for isData.
    function isList(RLPItem memory item) internal pure returns (bool) {
        uint8 byte0;
        uint256 memPtr = item.memPtr;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < LIST_SHORT_START) return false;
        return true;
    }

    /** RLPItem conversions into data types **/

    // @returns raw rlp encoding in bytes
    function toRlpBytes(RLPItem memory item)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory result = new bytes(item.len);

        uint256 ptr;
        assembly {
            ptr := add(0x20, result)
        }

        copy(item.memPtr, ptr, item.len);
        return result;
    }

    function toAddress(RLPItem memory item) internal pure returns (address) {
        require(!isList(item), "RLPReader: DECODING_LIST_AS_ADDRESS");
        // 1 byte for the length prefix
        require(item.len == 21, "RLPReader: INVALID_ADDRESS_LENGTH");

        return address(toUint(item));
    }

    function toUint(RLPItem memory item) internal pure returns (uint256) {
        require(!isList(item), "RLPReader: DECODING_LIST_AS_UINT");
        require(item.len <= 33, "RLPReader: INVALID_UINT_LENGTH");

        uint256 itemLength = _itemLength(item.memPtr);
        require(itemLength == item.len, "RLPReader: UINT_DECODED_LENGTH_MISMATCH");

        uint256 offset = _payloadOffset(item.memPtr);
        uint256 len = item.len - offset;
        uint256 result;
        uint256 memPtr = item.memPtr + offset;
        assembly {
            result := mload(memPtr)

            // shfit to the correct location if neccesary
            if lt(len, 32) {
                result := div(result, exp(256, sub(32, len)))
            }
        }

        return result;
    }

    // enforces 32 byte length
    function toUintStrict(RLPItem memory item) internal pure returns (uint256) {
        uint256 itemLength = _itemLength(item.memPtr);
        require(itemLength == item.len, "RLPReader: UINT_STRICT_DECODED_LENGTH_MISMATCH");
        // one byte prefix
        require(item.len == 33, "RLPReader: INVALID_UINT_STRICT_LENGTH");

        uint256 result;
        uint256 memPtr = item.memPtr + 1;
        assembly {
            result := mload(memPtr)
        }

        return result;
    }

    function toBytes(RLPItem memory item) internal pure returns (bytes memory) {
        uint256 listLength = _itemLength(item.memPtr);
        require(listLength == item.len, "RLPReader: BYTES_DECODED_LENGTH_MISMATCH");
        uint256 offset = _payloadOffset(item.memPtr);

        uint256 len = item.len - offset; // data length
        bytes memory result = new bytes(len);

        uint256 destPtr;
        assembly {
            destPtr := add(0x20, result)
        }

        copy(item.memPtr + offset, destPtr, len);
        return result;
    }

    /*
     * Private Helpers
     */

    // @return number of payload items inside an encoded list.
    function numItems(RLPItem memory item) private pure returns (uint256) {
        // add `isList` check if `item` is expected to be passsed without a check from calling function
        // require(isList(item), "RLPReader: NUM_ITEMS_NOT_LIST");

        uint256 count = 0;
        uint256 currPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint256 endPtr = item.memPtr + item.len;
        while (currPtr < endPtr) {
            currPtr = currPtr + _itemLength(currPtr); // skip over an item
            require(currPtr <= endPtr, "RLPReader: NUM_ITEMS_DECODED_LENGTH_MISMATCH");
            count++;
        }

        return count;
    }

    // @return entire rlp item byte length
    function _itemLength(uint256 memPtr) private pure returns (uint256) {
        uint256 itemLen;
        uint256 byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) itemLen = 1;
        else if (byte0 < STRING_LONG_START)
            itemLen = byte0 - STRING_SHORT_START + 1;
        else if (byte0 < LIST_SHORT_START) {
            assembly {
                let byteLen := sub(byte0, 0xb7) // # of bytes the actual length is
                memPtr := add(memPtr, 1) // skip over the first byte

                /* 32 byte word size */
                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to get the len
                itemLen := add(dataLen, add(byteLen, 1))
            }
        } else if (byte0 < LIST_LONG_START) {
            itemLen = byte0 - LIST_SHORT_START + 1;
        } else {
            assembly {
                let byteLen := sub(byte0, 0xf7)
                memPtr := add(memPtr, 1)

                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to the correct length
                itemLen := add(dataLen, add(byteLen, 1))
            }
        }

        return itemLen;
    }

    // @return number of bytes until the data
    function _payloadOffset(uint256 memPtr) private pure returns (uint256) {
        uint256 byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) return 0;
        else if (
            byte0 < STRING_LONG_START ||
            (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START)
        ) return 1;
        else if (byte0 < LIST_SHORT_START)
            // being explicit
            return byte0 - (STRING_LONG_START - 1) + 1;
        else return byte0 - (LIST_LONG_START - 1) + 1;
    }

    /*
     * @param src Pointer to source
     * @param dest Pointer to destination
     * @param len Amount of memory to copy from the source
     */
    function copy(
        uint256 src,
        uint256 dest,
        uint256 len
    ) private pure {
        if (len == 0) return;

        // copy as many word sizes as possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }

            src += WORD_SIZE;
            dest += WORD_SIZE;
        }

        // left over bytes. Mask is used to remove unwanted bytes from the word
        uint256 mask = 256**(WORD_SIZE - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask)) // zero out src
            let destpart := and(mload(dest), mask) // retrieve the bytes
            mstore(dest, or(destpart, srcpart))
        }
    }
}

/*
 * @title MerklePatriciaVerifier
 * @author Sam Mayo ([email protected])
 *
 * @dev Library for verifing merkle patricia proofs.
 */

library MerklePatriciaProof {
    /*
     * @dev Verifies a merkle patricia proof.
     * @param value The terminating value in the trie.
     * @param encodedPath The path in the trie leading to value.
     * @param rlpParentNodes The rlp encoded stack of nodes.
     * @param root The root hash of the trie.
     * @return The boolean validity of the proof.
     */
    function verify(
        bytes memory value,
        bytes memory encodedPath,
        bytes memory rlpParentNodes,
        bytes32 root
    ) internal pure returns (bool) {
        RLPReader.RLPItem memory item = RLPReader.toRlpItem(rlpParentNodes);
        RLPReader.RLPItem[] memory parentNodes = RLPReader.toList(item);

        bytes memory currentNode;
        RLPReader.RLPItem[] memory currentNodeList;

        bytes32 nodeKey = root;
        uint256 pathPtr = 0;

        bytes memory path = _getNibbleArray(encodedPath);
        if (path.length == 0) {
            return false;
        }

        for (uint256 i = 0; i < parentNodes.length; i++) {
            if (pathPtr > path.length) {
                return false;
            }

            currentNode = RLPReader.toRlpBytes(parentNodes[i]);
            if (nodeKey != keccak256(currentNode)) {
                return false;
            }
            currentNodeList = RLPReader.toList(parentNodes[i]);

            if (currentNodeList.length == 17) {
                if (pathPtr == path.length) {
                    if (
                        keccak256(RLPReader.toBytes(currentNodeList[16])) ==
                        keccak256(value)
                    ) {
                        return true;
                    } else {
                        return false;
                    }
                }

                uint8 nextPathNibble = uint8(path[pathPtr]);
                if (nextPathNibble > 16) {
                    return false;
                }
                nodeKey = bytes32(
                    RLPReader.toUintStrict(currentNodeList[nextPathNibble])
                );
                pathPtr += 1;
            } else if (currentNodeList.length == 2) {
                uint256 traversed = _nibblesToTraverse(
                    RLPReader.toBytes(currentNodeList[0]),
                    path,
                    pathPtr
                );
                if (pathPtr + traversed == path.length) {
                    //leaf node
                    if (
                        keccak256(RLPReader.toBytes(currentNodeList[1])) ==
                        keccak256(value)
                    ) {
                        return true;
                    } else {
                        return false;
                    }
                }

                //extension node
                if (traversed == 0) {
                    return false;
                }

                pathPtr += traversed;
                nodeKey = bytes32(RLPReader.toUintStrict(currentNodeList[1]));
            } else {
                return false;
            }
        }
    }

    function _nibblesToTraverse(
        bytes memory encodedPartialPath,
        bytes memory path,
        uint256 pathPtr
    ) private pure returns (uint256) {
        uint256 len = 0;
        // encodedPartialPath has elements that are each two hex characters (1 byte), but partialPath
        // and slicedPath have elements that are each one hex character (1 nibble)
        bytes memory partialPath = _getNibbleArray(encodedPartialPath);
        bytes memory slicedPath = new bytes(partialPath.length);

        // pathPtr counts nibbles in path
        // partialPath.length is a number of nibbles
        for (uint256 i = pathPtr; i < pathPtr + partialPath.length; i++) {
            bytes1 pathNibble = path[i];
            slicedPath[i - pathPtr] = pathNibble;
        }

        if (keccak256(partialPath) == keccak256(slicedPath)) {
            len = partialPath.length;
        } else {
            len = 0;
        }
        return len;
    }

    // bytes b must be hp encoded
    function _getNibbleArray(bytes memory b)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory nibbles = "";
        if (b.length > 0) {
            uint8 offset;
            uint8 hpNibble = uint8(_getNthNibbleOfBytes(0, b));
            if (hpNibble == 1 || hpNibble == 3) {
                nibbles = new bytes(b.length * 2 - 1);
                bytes1 oddNibble = _getNthNibbleOfBytes(1, b);
                nibbles[0] = oddNibble;
                offset = 1;
            } else {
                nibbles = new bytes(b.length * 2 - 2);
                offset = 0;
            }

            for (uint256 i = offset; i < nibbles.length; i++) {
                nibbles[i] = _getNthNibbleOfBytes(i - offset + 2, b);
            }
        }
        return nibbles;
    }

    function _getNthNibbleOfBytes(uint256 n, bytes memory str)
        private
        pure
        returns (bytes1)
    {
        return
            bytes1(
                n % 2 == 0 ? uint8(str[n / 2]) / 0x10 : uint8(str[n / 2]) % 0x10
            );
    }
}

contract ICheckpointManager {
    struct HeaderBlock {
        bytes32 root;
        uint256 start;
        uint256 end;
        uint256 createdAt;
        address proposer;
    }

    /**
     * @notice mapping of checkpoint header numbers to block details
     * @dev These checkpoints are submited by plasma contracts
     */
    mapping(uint256 => HeaderBlock) public headerBlocks;
}

library Merkle {
    function checkMembership(
        bytes32 leaf,
        uint256 index,
        bytes32 rootHash,
        bytes memory proof
    ) internal pure returns (bool) {
        require(proof.length % 32 == 0, "Invalid proof length");
        uint256 proofHeight = proof.length / 32;
        // Proof of size n means, height of the tree is n+1.
        // In a tree of height n+1, max #leafs possible is 2 ^ n
        require(index < 2 ** proofHeight, "Leaf index is too big");

        bytes32 proofElement;
        bytes32 computedHash = leaf;
        for (uint256 i = 32; i <= proof.length; i += 32) {
            assembly {
                proofElement := mload(add(proof, i))
            }

            if (index % 2 == 0) {
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }

            index = index / 2;
        }
        return computedHash == rootHash;
    }
}

abstract contract BaseRootTunnel is AccessControlMixin {
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;
    using Merkle for bytes32;
    using SafeMath for uint256;

    // keccak256(MessageSent(bytes))
    bytes32 public constant SEND_MESSAGE_EVENT_SIG = 0x8c5261668696ce22758910d05bab8f186d6eb247ceac2af2e82c7dc17669b036;

    // state sender contract
    IStateSender public stateSender;
    // root chain manager
    ICheckpointManager public checkpointManager;
    // child tunnel contract which receives and sends messages 
    address public childTunnel;
    // storage to avoid duplicate exits
    mapping(bytes32 => bool) public processedExits;

    constructor() internal {
      _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
      _setupContractId("RootTunnel");
    }

    /**
     * @notice Set the state sender, callable only by admins
     * @dev This should be the state sender from plasma contracts
     * It is used to send bytes from root to child chain
     * @param newStateSender address of state sender contract
     */
    function setStateSender(address newStateSender)
        external
        only(DEFAULT_ADMIN_ROLE)
    {
        stateSender = IStateSender(newStateSender);
    }

    /**
     * @notice Set the checkpoint manager, callable only by admins
     * @dev This should be the plasma contract responsible for keeping track of checkpoints
     * @param newCheckpointManager address of checkpoint manager contract
     */
    function setCheckpointManager(address newCheckpointManager)
        external
        only(DEFAULT_ADMIN_ROLE)
    {
        checkpointManager = ICheckpointManager(newCheckpointManager);
    }

    /**
     * @notice Set the child chain tunnel, callable only by admins
     * @dev This should be the contract responsible to receive data bytes on child chain
     * @param newChildTunnel address of child tunnel contract
     */
    function setChildTunnel(address newChildTunnel)
        external
        only(DEFAULT_ADMIN_ROLE)
    {
        require(newChildTunnel != address(0x0), "RootTunnel: INVALID_CHILD_TUNNEL_ADDRESS");
        childTunnel = newChildTunnel;
    }

    /**
     * @notice Send bytes message to Child Tunnel
     * @param message bytes message that will be sent to Child Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToChild(bytes memory message) internal {
        stateSender.syncState(childTunnel, message);
    }

    function _validateAndExtractMessage(bytes memory inputData) internal returns (bytes memory) {
        RLPReader.RLPItem[] memory inputDataRLPList = inputData
            .toRlpItem()
            .toList();

        // checking if exit has already been processed
        // unique exit is identified using hash of (blockNumber, branchMask, receiptLogIndex)
        bytes32 exitHash = keccak256(
            abi.encodePacked(
                inputDataRLPList[2].toUint(), // blockNumber
                // first 2 nibbles are dropped while generating nibble array
                // this allows branch masks that are valid but bypass exitHash check (changing first 2 nibbles only)
                // so converting to nibble array and then hashing it
                MerklePatriciaProof._getNibbleArray(inputDataRLPList[8].toBytes()), // branchMask
                inputDataRLPList[9].toUint() // receiptLogIndex
            )
        );
        require(
            processedExits[exitHash] == false,
            "RootTunnel: EXIT_ALREADY_PROCESSED"
        );
        processedExits[exitHash] = true;

        RLPReader.RLPItem[] memory receiptRLPList = inputDataRLPList[6]
            .toBytes()
            .toRlpItem()
            .toList();
        RLPReader.RLPItem memory logRLP = receiptRLPList[3]
            .toList()[
                inputDataRLPList[9].toUint() // receiptLogIndex
            ];

        RLPReader.RLPItem[] memory logRLPList = logRLP.toList();
        
        // check child tunnel
        require(childTunnel == RLPReader.toAddress(logRLPList[0]), "RootTunnel: INVALID_CHILD_TUNNEL");

        // verify receipt inclusion
        require(
            MerklePatriciaProof.verify(
                inputDataRLPList[6].toBytes(), // receipt
                inputDataRLPList[8].toBytes(), // branchMask
                inputDataRLPList[7].toBytes(), // receiptProof
                bytes32(inputDataRLPList[5].toUint()) // receiptRoot
            ),
            "RootTunnel: INVALID_RECEIPT_PROOF"
        );

        // verify checkpoint inclusion
        _checkBlockMembershipInCheckpoint(
            inputDataRLPList[2].toUint(), // blockNumber
            inputDataRLPList[3].toUint(), // blockTime
            bytes32(inputDataRLPList[4].toUint()), // txRoot
            bytes32(inputDataRLPList[5].toUint()), // receiptRoot
            inputDataRLPList[0].toUint(), // headerNumber
            inputDataRLPList[1].toBytes() // blockProof
        );

        RLPReader.RLPItem[] memory logTopicRLPList = logRLPList[1].toList(); // topics

        require(
            bytes32(logTopicRLPList[0].toUint()) == SEND_MESSAGE_EVENT_SIG, // topic0 is event sig
            "RootTunnel: INVALID_SIGNATURE"
        );

        // received message data
        bytes memory receivedData = logRLPList[2].toBytes();
        (bytes memory message) = abi.decode(receivedData, (bytes)); // event decodes params again, so decoding bytes to get message
        return message;
    }

    function _checkBlockMembershipInCheckpoint(
        uint256 blockNumber,
        uint256 blockTime,
        bytes32 txRoot,
        bytes32 receiptRoot,
        uint256 headerNumber,
        bytes memory blockProof
    ) private view returns (uint256) {
        (
            bytes32 headerRoot,
            uint256 startBlock,
            ,
            uint256 createdAt,

        ) = checkpointManager.headerBlocks(headerNumber);

        require(
            keccak256(
                abi.encodePacked(blockNumber, blockTime, txRoot, receiptRoot)
            )
                .checkMembership(
                blockNumber.sub(startBlock),
                headerRoot,
                blockProof
            ),
            "RootTunnel: INVALID_HEADER"
        );
        return createdAt;
    }

    /**
     * @notice receive message from  L2 to L1, validated by proof
     * @dev This function verifies if the transaction actually happened on child chain
     *
     * @param inputData RLP encoded data of the reference tx containing following list of fields
     *  0 - headerNumber - Checkpoint header block number containing the reference tx
     *  1 - blockProof - Proof that the block header (in the child chain) is a leaf in the submitted merkle root
     *  2 - blockNumber - Block number containing the reference tx on child chain
     *  3 - blockTime - Reference tx block time
     *  4 - txRoot - Transactions root of block
     *  5 - receiptRoot - Receipts root of block
     *  6 - receipt - Receipt of the reference transaction
     *  7 - receiptProof - Merkle proof of the reference receipt
     *  8 - branchMask - 32 bits denoting the path of receipt in merkle tree
     *  9 - receiptLogIndex - Log Index to read from the receipt
     */
    function receiveMessage(bytes memory inputData) public virtual {
        bytes memory message = _validateAndExtractMessage(inputData);
        _processMessageFromChild(message);
    }

    /**
     * @notice Process message received from Child Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param message bytes message that was sent from Child Tunnel
     */
    function _processMessageFromChild(bytes memory message) virtual internal;
}

interface IMessengerWrapper {
    function sendCrossDomainMessage(bytes memory _calldata) external;
    function verifySender(address l1BridgeCaller, bytes memory _data) external;
}

abstract contract MessengerWrapper is IMessengerWrapper {
    address public immutable l1BridgeAddress;

    constructor(address _l1BridgeAddress) public {
        l1BridgeAddress = _l1BridgeAddress;
    }

    modifier onlyL1Bridge {
        require(msg.sender == l1BridgeAddress, "MW: Sender must be the L1 Bridge");
        _;
    }
}

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

/**
 * @dev Accounting is an abstract contract that encapsulates the most critical logic in the Hop contracts.
 * The accounting system works by using two balances that can only increase `_credit` and `_debit`.
 * A bonder's available balance is the total credit minus the total debit. The contract exposes
 * two external functions that allows a bonder to stake and unstake and exposes two internal
 * functions to its child contracts that allow the child contract to add to the credit 
 * and debit balance. In addition, child contracts can override `_additionalDebit` to account
 * for any additional debit balance in an alternative way. Lastly, it exposes a modifier,
 * `requirePositiveBalance`, that can be used by child contracts to ensure the bonder does not
 * use more than its available stake.
 */

abstract contract Accounting is ReentrancyGuard {
    using SafeMath for uint256;

    mapping(address => bool) private _isBonder;

    mapping(address => uint256) private _credit;
    mapping(address => uint256) private _debit;

    event Stake (
        address account,
        uint256 amount
    );

    event Unstake (
        address account,
        uint256 amount
    );

    event BonderAdded (
        address newBonder
    );

    event BonderRemoved (
        address previousBonder
    );

    /* ========== Modifiers ========== */

    modifier onlyBonder {
        require(_isBonder[msg.sender], "ACT: Caller is not bonder");
        _;
    }

    modifier onlyGovernance {
        _requireIsGovernance();
        _;
    }

    /// @dev Used by parent contract to ensure that the bonder is solvent at the end of the transaction.
    modifier requirePositiveBalance {
        _;
        require(getCredit(msg.sender) >= getDebitAndAdditionalDebit(msg.sender), "ACT: Not enough available credit");
    }

    /// @dev Sets the bonder addresses
    constructor(address[] memory bonders) public {
        for (uint256 i = 0; i < bonders.length; i++) {
            _isBonder[bonders[i]] = true;
        }
    }

    /* ========== Virtual functions ========== */
    /**
     * @dev The following functions are overridden in L1_Bridge and L2_Bridge
     */
    function _transferFromBridge(address recipient, uint256 amount) internal virtual;
    function _transferToBridge(address from, uint256 amount) internal virtual;
    function _requireIsGovernance() internal virtual;

    /**
     * @dev This function can be optionally overridden by a parent contract to track any additional
     * debit balance in an alternative way.
     */
    function _additionalDebit(address /*bonder*/) internal view virtual returns (uint256) {
        this; // Silence state mutability warning without generating any additional byte code
        return 0;
    }

    /* ========== Public/external getters ========== */

    /**
     * @dev Check if address is a Bonder
     * @param maybeBonder The address being checked
     * @return true if address is a Bonder
     */
    function getIsBonder(address maybeBonder) public view returns (bool) {
        return _isBonder[maybeBonder];
    }

    /**
     * @dev Get the Bonder's credit balance
     * @param bonder The owner of the credit balance being checked
     * @return The credit balance for the Bonder
     */
    function getCredit(address bonder) public view returns (uint256) {
        return _credit[bonder];
    }

    /**
     * @dev Gets the debit balance tracked by `_debit` and does not include `_additionalDebit()`
     * @param bonder The owner of the _debit balance being checked
     * @return The _debit amount for the Bonder
     */
    function getRawDebit(address bonder) external view returns (uint256) {
        return _debit[bonder];
    }

    /**
     * @dev Get the Bonder's total debit
     * @param bonder The owner of the debit balance being checked
     * @return The Bonder's total debit balance
     */
    function getDebitAndAdditionalDebit(address bonder) public view returns (uint256) {
        return _debit[bonder].add(_additionalDebit(bonder));
    }

    /* ========== Bonder external functions ========== */

    /** 
     * @dev Allows the bonder to deposit tokens and increase its credit balance
     * @param bonder The address being staked on
     * @param amount The amount being staked
     */
    function stake(address bonder, uint256 amount) external payable nonReentrant {
        require(_isBonder[bonder] == true, "ACT: Address is not bonder");
        _transferToBridge(msg.sender, amount);
        _addCredit(bonder, amount);

        emit Stake(bonder, amount);
    }

    /**
     * @dev Allows the caller to withdraw any available balance and add to their debit balance
     * @param amount The amount being staked
     */
    function unstake(uint256 amount) external requirePositiveBalance nonReentrant {
        _addDebit(msg.sender, amount);
        _transferFromBridge(msg.sender, amount);

        emit Unstake(msg.sender, amount);
    }

    /**
     * @dev Add Bonder to allowlist
     * @param bonder The address being added as a Bonder
     */
    function addBonder(address bonder) external onlyGovernance {
        require(_isBonder[bonder] == false, "ACT: Address is already bonder");
        _isBonder[bonder] = true;

        emit BonderAdded(bonder);
    }

    /**
     * @dev Remove Bonder from allowlist
     * @param bonder The address being removed as a Bonder
     */
    function removeBonder(address bonder) external onlyGovernance {
        require(_isBonder[bonder] == true, "ACT: Address is not bonder");
        _isBonder[bonder] = false;

        emit BonderRemoved(bonder);
    }

    /* ========== Internal functions ========== */

    function _addCredit(address bonder, uint256 amount) internal {
        _credit[bonder] = _credit[bonder].add(amount);
    }

    function _addDebit(address bonder, uint256 amount) internal {
        _debit[bonder] = _debit[bonder].add(amount);
    }
}

/**
 * @title Lib_MerkleTree
 * @author River Keefer
 */
library Lib_MerkleTree {

    /**********************
     * Internal Functions *
     **********************/

    /**
     * Calculates a merkle root for a list of 32-byte leaf hashes.  WARNING: If the number
     * of leaves passed in is not a power of two, it pads out the tree with zero hashes.
     * If you do not know the original length of elements for the tree you are verifying,
     * then this may allow empty leaves past _elements.length to pass a verification check down the line.
     * Note that the _elements argument is modified, therefore it must not be used again afterwards
     * @param _elements Array of hashes from which to generate a merkle root.
     * @return Merkle root of the leaves, with zero hashes for non-powers-of-two (see above).
     */
    function getMerkleRoot(
        bytes32[] memory _elements
    )
        internal
        pure
        returns (
            bytes32
        )
    {
        require(
            _elements.length > 0,
            "Lib_MerkleTree: Must provide at least one leaf hash."
        );

        if (_elements.length == 1) {
            return _elements[0];
        }

        uint256[16] memory defaults = [
            0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563,
            0x633dc4d7da7256660a892f8f1604a44b5432649cc8ec5cb3ced4c4e6ac94dd1d,
            0x890740a8eb06ce9be422cb8da5cdafc2b58c0a5e24036c578de2a433c828ff7d,
            0x3b8ec09e026fdc305365dfc94e189a81b38c7597b3d941c279f042e8206e0bd8,
            0xecd50eee38e386bd62be9bedb990706951b65fe053bd9d8a521af753d139e2da,
            0xdefff6d330bb5403f63b14f33b578274160de3a50df4efecf0e0db73bcdd3da5,
            0x617bdd11f7c0a11f49db22f629387a12da7596f9d1704d7465177c63d88ec7d7,
            0x292c23a9aa1d8bea7e2435e555a4a60e379a5a35f3f452bae60121073fb6eead,
            0xe1cea92ed99acdcb045a6726b2f87107e8a61620a232cf4d7d5b5766b3952e10,
            0x7ad66c0a68c72cb89e4fb4303841966e4062a76ab97451e3b9fb526a5ceb7f82,
            0xe026cc5a4aed3c22a58cbd3d2ac754c9352c5436f638042dca99034e83636516,
            0x3d04cffd8b46a874edf5cfae63077de85f849a660426697b06a829c70dd1409c,
            0xad676aa337a485e4728a0b240d92b3ef7b3c372d06d189322bfd5f61f1e7203e,
            0xa2fca4a49658f9fab7aa63289c91b7c7b6c832a6d0e69334ff5b0a3483d09dab,
            0x4ebfd9cd7bca2505f7bef59cc1c12ecc708fff26ae4af19abe852afe9e20c862,
            0x2def10d13dd169f550f578bda343d9717a138562e0093b380a1120789d53cf10
        ];

        // Reserve memory space for our hashes.
        bytes memory buf = new bytes(64);

        // We'll need to keep track of left and right siblings.
        bytes32 leftSibling;
        bytes32 rightSibling;

        // Number of non-empty nodes at the current depth.
        uint256 rowSize = _elements.length;

        // Current depth, counting from 0 at the leaves
        uint256 depth = 0;

        // Common sub-expressions
        uint256 halfRowSize;         // rowSize / 2
        bool rowSizeIsOdd;           // rowSize % 2 == 1

        while (rowSize > 1) {
            halfRowSize = rowSize / 2;
            rowSizeIsOdd = rowSize % 2 == 1;

            for (uint256 i = 0; i < halfRowSize; i++) {
                leftSibling  = _elements[(2 * i)    ];
                rightSibling = _elements[(2 * i) + 1];
                assembly {
                    mstore(add(buf, 32), leftSibling )
                    mstore(add(buf, 64), rightSibling)
                }

                _elements[i] = keccak256(buf);
            }

            if (rowSizeIsOdd) {
                leftSibling  = _elements[rowSize - 1];
                rightSibling = bytes32(defaults[depth]);
                assembly {
                    mstore(add(buf, 32), leftSibling)
                    mstore(add(buf, 64), rightSibling)
                }

                _elements[halfRowSize] = keccak256(buf);
            }

            rowSize = halfRowSize + (rowSizeIsOdd ? 1 : 0);
            depth++;
        }

        return _elements[0];
    }

    /**
     * Verifies a merkle branch for the given leaf hash.  Assumes the original length
     * of leaves generated is a known, correct input, and does not return true for indices
     * extending past that index (even if _siblings would be otherwise valid.)
     * @param _root The Merkle root to verify against.
     * @param _leaf The leaf hash to verify inclusion of.
     * @param _index The index in the tree of this leaf.
     * @param _siblings Array of sibline nodes in the inclusion proof, starting from depth 0 (bottom of the tree).
     * @param _totalLeaves The total number of leaves originally passed into.
     * @return Whether or not the merkle branch and leaf passes verification.
     */
    function verify(
        bytes32 _root,
        bytes32 _leaf,
        uint256 _index,
        bytes32[] memory _siblings,
        uint256 _totalLeaves
    )
        internal
        pure
        returns (
            bool
        )
    {
        require(
            _totalLeaves > 0,
            "Lib_MerkleTree: Total leaves must be greater than zero."
        );

        require(
            _index < _totalLeaves,
            "Lib_MerkleTree: Index out of bounds."
        );

        require(
            _siblings.length == _ceilLog2(_totalLeaves),
            "Lib_MerkleTree: Total siblings does not correctly correspond to total leaves."
        );

        bytes32 computedRoot = _leaf;

        for (uint256 i = 0; i < _siblings.length; i++) {
            if ((_index & 1) == 1) {
                computedRoot = keccak256(
                    abi.encodePacked(
                        _siblings[i],
                        computedRoot
                    )
                );
            } else {
                computedRoot = keccak256(
                    abi.encodePacked(
                        computedRoot,
                        _siblings[i]
                    )
                );
            }

            _index >>= 1;
        }

        return _root == computedRoot;
    }


    /*********************
     * Private Functions *
     *********************/

    /**
     * Calculates the integer ceiling of the log base 2 of an input.
     * @param _in Unsigned input to calculate the log.
     * @return ceil(log_base_2(_in))
     */
    function _ceilLog2(
        uint256 _in
    )
        private
        pure
        returns (
            uint256
        )
    {
        require(
            _in > 0,
            "Lib_MerkleTree: Cannot compute ceil(log_2) of 0."
        );

        if (_in == 1) {
            return 0;
        }

        // Find the highest set bit (will be floor(log_2)).
        // Borrowed with <3 from https://github.com/ethereum/solidity-examples
        uint256 val = _in;
        uint256 highest = 0;
        for (uint256 i = 128; i >= 1; i >>= 1) {
            if (val & (uint(1) << i) - 1 << i != 0) {
                highest += i;
                val >>= i;
            }
        }

        // Increment by one if this is not a perfect logarithm.
        if ((uint(1) << highest) != _in) {
            highest += 1;
        }

        return highest;
    }
}

/**
 * @dev Bridge extends the accounting system and encapsulates the logic that is shared by both the
 * L1 and L2 Bridges. It allows to TransferRoots to be set by parent contracts and for those
 * TransferRoots to be withdrawn against. It also allows the bonder to bond and withdraw Transfers
 * directly through `bondWithdrawal` and then settle those bonds against their TransferRoot once it
 * has been set.
 */

abstract contract Bridge is Accounting {
    using MerkleProof for bytes32[];

    struct TransferRoot {
        uint256 total;
        uint256 amountWithdrawn;
        uint256 createdAt;
    }

    /* ========== Events ========== */

    event Withdrew(
        bytes32 indexed transferId,
        address indexed recipient,
        uint256 amount,
        bytes32 transferNonce
    );

    event WithdrawalBonded(
        bytes32 indexed transferId,
        uint256 amount
    );

    event WithdrawalBondSettled(
        address bonder,
        bytes32 transferId,
        bytes32 rootHash
    );

    event MultipleWithdrawalsSettled(
        address bonder,
        bytes32 rootHash,
        uint256 totalBondsSettled
    );

    event TransferRootSet(
        bytes32 rootHash,
        uint256 totalAmount
    );

    /* ========== State ========== */

    mapping(bytes32 => TransferRoot) private _transferRoots;
    mapping(bytes32 => bool) private _spentTransferIds;
    mapping(address => mapping(bytes32 => uint256)) private _bondedWithdrawalAmounts;

    uint256 constant RESCUE_DELAY = 8 weeks;

    constructor(address[] memory bonders) public Accounting(bonders) {}

    /* ========== Public Getters ========== */

    /**
     * @dev Get the hash that represents an individual Transfer.
     * @param chainId The id of the destination chain
     * @param recipient The address receiving the Transfer
     * @param amount The amount being transferred including the `_bonderFee`
     * @param transferNonce Used to avoid transferId collisions
     * @param bonderFee The amount paid to the address that withdraws the Transfer
     * @param amountOutMin The minimum amount received after attempting to swap in the destination
     * AMM market. 0 if no swap is intended.
     * @param deadline The deadline for swapping in the destination AMM market. 0 if no
     * swap is intended.
     */
    function getTransferId(
        uint256 chainId,
        address recipient,
        uint256 amount,
        bytes32 transferNonce,
        uint256 bonderFee,
        uint256 amountOutMin,
        uint256 deadline
    )
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(
            chainId,
            recipient,
            amount,
            transferNonce,
            bonderFee,
            amountOutMin,
            deadline
        ));
    }

    /**
     * @notice getChainId can be overridden by subclasses if needed for compatibility or testing purposes.
     * @dev Get the current chainId
     * @return chainId The current chainId
     */
    function getChainId() public virtual view returns (uint256 chainId) {
        this; // Silence state mutability warning without generating any additional byte code
        assembly {
            chainId := chainid()
        }
    }

    /**
     * @dev Get the TransferRoot id for a given rootHash and totalAmount
     * @param rootHash The merkle root of the TransferRoot
     * @param totalAmount The total of all Transfers in the TransferRoot
     * @return The calculated transferRootId
     */
    function getTransferRootId(bytes32 rootHash, uint256 totalAmount) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(rootHash, totalAmount));
    }

    /**
     * @dev Get the TransferRoot for a given rootHash and totalAmount
     * @param rootHash The merkle root of the TransferRoot
     * @param totalAmount The total of all Transfers in the TransferRoot
     * @return The TransferRoot with the calculated transferRootId
     */
    function getTransferRoot(bytes32 rootHash, uint256 totalAmount) public view returns (TransferRoot memory) {
        return _transferRoots[getTransferRootId(rootHash, totalAmount)];
    }

    /**
     * @dev Get the amount bonded for the withdrawal of a transfer
     * @param bonder The Bonder of the withdrawal
     * @param transferId The Transfer's unique identifier
     * @return The amount bonded for a Transfer withdrawal
     */
    function getBondedWithdrawalAmount(address bonder, bytes32 transferId) external view returns (uint256) {
        return _bondedWithdrawalAmounts[bonder][transferId];
    }

    /**
     * @dev Get the spent status of a transfer ID
     * @param transferId The transfer's unique identifier
     * @return True if the transferId has been spent
     */
    function isTransferIdSpent(bytes32 transferId) external view returns (bool) {
        return _spentTransferIds[transferId];
    }

    /* ========== User/Relayer External Functions ========== */

    /**
     * @notice Can be called by anyone (recipient or relayer)
     * @dev Withdraw a Transfer from its destination bridge
     * @param recipient The address receiving the Transfer
     * @param amount The amount being transferred including the `_bonderFee`
     * @param transferNonce Used to avoid transferId collisions
     * @param bonderFee The amount paid to the address that withdraws the Transfer
     * @param amountOutMin The minimum amount received after attempting to swap in the destination
     * AMM market. 0 if no swap is intended. (only used to calculate `transferId` in this function)
     * @param deadline The deadline for swapping in the destination AMM market. 0 if no
     * swap is intended. (only used to calculate `transferId` in this function)
     * @param rootHash The Merkle root of the TransferRoot
     * @param transferRootTotalAmount The total amount being transferred in a TransferRoot
     * @param proof The Merkle proof that proves the Transfer's inclusion in the TransferRoot
     */
    function withdraw(
        address recipient,
        uint256 amount,
        bytes32 transferNonce,
        uint256 bonderFee,
        uint256 amountOutMin,
        uint256 deadline,
        bytes32 rootHash,
        uint256 transferRootTotalAmount,
        bytes32[] calldata proof
    )
        external
        nonReentrant
    {
        bytes32 transferId = getTransferId(
            getChainId(),
            recipient,
            amount,
            transferNonce,
            bonderFee,
            amountOutMin,
            deadline
        );

        require(proof.verify(rootHash, transferId), "BRG: Invalid transfer proof");
        bytes32 transferRootId = getTransferRootId(rootHash, transferRootTotalAmount);
        _addToAmountWithdrawn(transferRootId, amount);
        _fulfillWithdraw(transferId, recipient, amount, uint256(0));

        emit Withdrew(transferId, recipient, amount, transferNonce);
    }

    /**
     * @dev Allows the bonder to bond individual withdrawals before their TransferRoot has been committed.
     * @param recipient The address receiving the Transfer
     * @param amount The amount being transferred including the `_bonderFee`
     * @param transferNonce Used to avoid transferId collisions
     * @param bonderFee The amount paid to the address that withdraws the Transfer
     */
    function bondWithdrawal(
        address recipient,
        uint256 amount,
        bytes32 transferNonce,
        uint256 bonderFee
    )
        external
        onlyBonder
        requirePositiveBalance
        nonReentrant
    {
        bytes32 transferId = getTransferId(
            getChainId(),
            recipient,
            amount,
            transferNonce,
            bonderFee,
            0,
            0
        );

        _bondWithdrawal(transferId, amount);
        _fulfillWithdraw(transferId, recipient, amount, bonderFee);
    }

    /**
     * @dev Refunds the bonders stake from a bonded withdrawal and counts that withdrawal against
     * its TransferRoot.
     * @param bonder The Bonder of the withdrawal
     * @param transferId The Transfer's unique identifier
     * @param rootHash The merkle root of the TransferRoot
     * @param transferRootTotalAmount The total amount being transferred in a TransferRoot
     * @param proof The Merkle proof that proves the Transfer's inclusion in the TransferRoot
     */
    function settleBondedWithdrawal(
        address bonder,
        bytes32 transferId,
        bytes32 rootHash,
        uint256 transferRootTotalAmount,
        bytes32[] calldata proof
    )
        external
    {
        require(proof.verify(rootHash, transferId), "L2_BRG: Invalid transfer proof");
        bytes32 transferRootId = getTransferRootId(rootHash, transferRootTotalAmount);

        uint256 amount = _bondedWithdrawalAmounts[bonder][transferId];
        require(amount > 0, "L2_BRG: transferId has no bond");

        _bondedWithdrawalAmounts[bonder][transferId] = 0;
        _addToAmountWithdrawn(transferRootId, amount);
        _addCredit(bonder, amount);

        emit WithdrawalBondSettled(bonder, transferId, rootHash);
    }

    /**
     * @dev Refunds the Bonder for all withdrawals that they bonded in a TransferRoot.
     * @param bonder The address of the Bonder being refunded
     * @param transferIds All transferIds in the TransferRoot in order
     * @param totalAmount The totalAmount of the TransferRoot
     */
    function settleBondedWithdrawals(
        address bonder,
        // transferIds _must_ be calldata or it will be mutated by Lib_MerkleTree.getMerkleRoot
        bytes32[] calldata transferIds,
        uint256 totalAmount
    )
        external
    {
        bytes32 rootHash = Lib_MerkleTree.getMerkleRoot(transferIds);
        bytes32 transferRootId = getTransferRootId(rootHash, totalAmount);

        uint256 totalBondsSettled = 0;
        for(uint256 i = 0; i < transferIds.length; i++) {
            uint256 transferBondAmount = _bondedWithdrawalAmounts[bonder][transferIds[i]];
            if (transferBondAmount > 0) {
                totalBondsSettled = totalBondsSettled.add(transferBondAmount);
                _bondedWithdrawalAmounts[bonder][transferIds[i]] = 0;
            }
        }

        _addToAmountWithdrawn(transferRootId, totalBondsSettled);
        _addCredit(bonder, totalBondsSettled);

        emit MultipleWithdrawalsSettled(bonder, rootHash, totalBondsSettled);
    }

    /* ========== External TransferRoot Rescue ========== */

    /**
     * @dev Allows governance to withdraw the remaining amount from a TransferRoot after the rescue delay has passed.
     * @param rootHash the Merkle root of the TransferRoot
     * @param originalAmount The TransferRoot's recorded total
     * @param recipient The address receiving the remaining balance
     */
    function rescueTransferRoot(bytes32 rootHash, uint256 originalAmount, address recipient) external onlyGovernance {
        bytes32 transferRootId = getTransferRootId(rootHash, originalAmount);
        TransferRoot memory transferRoot = getTransferRoot(rootHash, originalAmount);

        require(transferRoot.createdAt != 0, "BRG: TransferRoot not found");
        assert(transferRoot.total == originalAmount);
        uint256 rescueDelayEnd = transferRoot.createdAt.add(RESCUE_DELAY);
        require(block.timestamp >= rescueDelayEnd, "BRG: TransferRoot cannot be rescued before the Rescue Delay");

        uint256 remainingAmount = transferRoot.total.sub(transferRoot.amountWithdrawn);
        _addToAmountWithdrawn(transferRootId, remainingAmount);
        _transferFromBridge(recipient, remainingAmount);
    }

    /* ========== Internal Functions ========== */

    function _markTransferSpent(bytes32 transferId) internal {
        require(!_spentTransferIds[transferId], "BRG: The transfer has already been withdrawn");
        _spentTransferIds[transferId] = true;
    }

    function _addToAmountWithdrawn(bytes32 transferRootId, uint256 amount) internal {
        TransferRoot storage transferRoot = _transferRoots[transferRootId];
        require(transferRoot.total > 0, "BRG: Transfer root not found");

        uint256 newAmountWithdrawn = transferRoot.amountWithdrawn.add(amount);
        require(newAmountWithdrawn <= transferRoot.total, "BRG: Withdrawal exceeds TransferRoot total");

        transferRoot.amountWithdrawn = newAmountWithdrawn;
    }

    function _setTransferRoot(bytes32 rootHash, uint256 totalAmount) internal {
        bytes32 transferRootId = getTransferRootId(rootHash, totalAmount);
        require(_transferRoots[transferRootId].total == 0, "BRG: Transfer root already set");
        require(totalAmount > 0, "BRG: Cannot set TransferRoot totalAmount of 0");

        _transferRoots[transferRootId] = TransferRoot(totalAmount, 0, block.timestamp);

        emit TransferRootSet(rootHash, totalAmount);
    }

    function _bondWithdrawal(bytes32 transferId, uint256 amount) internal {
        require(_bondedWithdrawalAmounts[msg.sender][transferId] == 0, "BRG: Withdrawal has already been bonded");
        _addDebit(msg.sender, amount);
        _bondedWithdrawalAmounts[msg.sender][transferId] = amount;

        emit WithdrawalBonded(transferId, amount);
    }

    /* ========== Private Functions ========== */

    /// @dev Completes the Transfer, distributes the Bonder fee and marks the Transfer as spent.
    function _fulfillWithdraw(
        bytes32 transferId,
        address recipient,
        uint256 amount,
        uint256 bonderFee
    ) private {
        _markTransferSpent(transferId);
        _transferFromBridge(recipient, amount.sub(bonderFee));
        if (bonderFee > 0) {
            _transferFromBridge(msg.sender, bonderFee);
        }
    }
}

/**
 * @dev L1_Bridge is responsible for the bonding and challenging of TransferRoots. All TransferRoots
 * originate in the L1_Bridge through `bondTransferRoot` and are propagated up to destination L2s.
 */

abstract contract L1_Bridge is Bridge {

    struct TransferBond {
        address bonder;
        uint256 createdAt;
        uint256 totalAmount;
        uint256 challengeStartTime;
        address challenger;
        bool challengeResolved;
    }

    /* ========== State ========== */

    mapping(bytes32 => uint256) public transferRootCommittedAt;
    mapping(bytes32 => TransferBond) public transferBonds;
    mapping(uint256 => mapping(address => uint256)) public timeSlotToAmountBonded;
    mapping(uint256 => uint256) public chainBalance;

    /* ========== Config State ========== */

    address public governance;
    mapping(uint256 => IMessengerWrapper) public crossDomainMessengerWrappers;
    mapping(uint256 => bool) public isChainIdPaused;
    uint256 public challengePeriod = 1 days;
    uint256 public challengeResolutionPeriod = 10 days;
    uint256 public minTransferRootBondDelay = 15 minutes;
    
    uint256 public constant CHALLENGE_AMOUNT_DIVISOR = 10;
    uint256 public constant TIME_SLOT_SIZE = 4 hours;

    /* ========== Events ========== */

    event TransferRootBonded (
        bytes32 indexed root,
        uint256 amount
    );

    event TransferRootConfirmed(
        uint256 originChainId,
        uint256 destinationChainId,
        bytes32 rootHash,
        uint256 totalAmount
    );

    event TransferBondChallenged(
        bytes32 transferRootId,
        bytes32 rootHash,
        uint256 originalAmount
    );

    event ChallengeResolved(
        bytes32 transferRootId,
        bytes32 rootHash,
        uint256 originalAmount
    );

    /* ========== Modifiers ========== */

    modifier onlyL2Bridge(uint256 chainId) {
        IMessengerWrapper messengerWrapper = crossDomainMessengerWrappers[chainId];
        messengerWrapper.verifySender(msg.sender, msg.data);
        _;
    }

    constructor (address[] memory bonders, address _governance) public Bridge(bonders) {
        governance = _governance;
    }

    /* ========== Send Functions ========== */

    /**
     * @notice `amountOutMin` and `deadline` should be 0 when no swap is intended at the destination.
     * @notice `amount` is the total amount the user wants to send including the relayer fee
     * @dev Send tokens to a supported layer-2 to mint hToken and optionally swap the hToken in the
     * AMM at the destination.
     * @param chainId The chainId of the destination chain
     * @param recipient The address receiving funds at the destination
     * @param amount The amount being sent
     * @param amountOutMin The minimum amount received after attempting to swap in the destination
     * AMM market. 0 if no swap is intended.
     * @param deadline The deadline for swapping in the destination AMM market. 0 if no
     * swap is intended.
     * @param relayer The address of the at the destination.
     * @param relayerFee The amount distributed to the relayer at the destination. This is subtracted from the `amount`.
     */
    function sendToL2(
        uint256 chainId,
        address recipient,
        uint256 amount,
        uint256 amountOutMin,
        uint256 deadline,
        address relayer,
        uint256 relayerFee
    )
        external
        payable
    {
        IMessengerWrapper messengerWrapper = crossDomainMessengerWrappers[chainId];
        require(messengerWrapper != IMessengerWrapper(0), "L1_BRG: chainId not supported");
        require(isChainIdPaused[chainId] == false, "L1_BRG: Sends to this chainId are paused");
        require(amount > 0, "L1_BRG: Must transfer a non-zero amount");
        require(amount >= relayerFee, "L1_BRG: Relayer fee cannot exceed amount");

        _transferToBridge(msg.sender, amount);

        bytes memory message = abi.encodeWithSignature(
            "distribute(address,uint256,uint256,uint256,address,uint256)",
            recipient,
            amount,
            amountOutMin,
            deadline,
            relayer,
            relayerFee
        );

        chainBalance[chainId] = chainBalance[chainId].add(amount);
        messengerWrapper.sendCrossDomainMessage(message);
    }

    /* ========== TransferRoot Functions ========== */

    /**
     * @dev Setting a TransferRoot is a two step process.
     * @dev   1. The TransferRoot is bonded with `bondTransferRoot`. Withdrawals can now begin on L1
     * @dev      and recipient L2's
     * @dev   2. The TransferRoot is confirmed after `confirmTransferRoot` is called by the l2 bridge
     * @dev      where the TransferRoot originated.
     */

    /**
     * @dev Used by the bonder to bond a TransferRoot and propagate it up to destination L2s
     * @param rootHash The Merkle root of the TransferRoot Merkle tree
     * @param destinationChainId The id of the destination chain
     * @param totalAmount The amount destined for the destination chain
     */
    function bondTransferRoot(
        bytes32 rootHash,
        uint256 destinationChainId,
        uint256 totalAmount
    )
        external
        onlyBonder
        requirePositiveBalance
    {
        bytes32 transferRootId = getTransferRootId(rootHash, totalAmount);
        require(transferRootCommittedAt[transferRootId] == 0, "L1_BRG: TransferRoot has already been confirmed");
        require(transferBonds[transferRootId].createdAt == 0, "L1_BRG: TransferRoot has already been bonded");

        uint256 currentTimeSlot = getTimeSlot(block.timestamp);
        uint256 bondAmount = getBondForTransferAmount(totalAmount);
        timeSlotToAmountBonded[currentTimeSlot][msg.sender] = timeSlotToAmountBonded[currentTimeSlot][msg.sender].add(bondAmount);

        transferBonds[transferRootId] = TransferBond(
            msg.sender,
            block.timestamp,
            totalAmount,
            uint256(0),
            address(0),
            false
        );

        _distributeTransferRoot(rootHash, destinationChainId, totalAmount);

        emit TransferRootBonded(rootHash, totalAmount);
    }

    /**
     * @dev Used by an L2 bridge to confirm a TransferRoot via cross-domain message. Once a TransferRoot
     * has been confirmed, any challenge against that TransferRoot can be resolved as unsuccessful.
     * @param originChainId The id of the origin chain
     * @param rootHash The Merkle root of the TransferRoot Merkle tree
     * @param destinationChainId The id of the destination chain
     * @param totalAmount The amount destined for each destination chain
     * @param rootCommittedAt The block timestamp when the TransferRoot was committed on its origin chain
     */
    function confirmTransferRoot(
        uint256 originChainId,
        bytes32 rootHash,
        uint256 destinationChainId,
        uint256 totalAmount,
        uint256 rootCommittedAt
    )
        external
        onlyL2Bridge(originChainId)
    {
        bytes32 transferRootId = getTransferRootId(rootHash, totalAmount);
        require(transferRootCommittedAt[transferRootId] == 0, "L1_BRG: TransferRoot already confirmed");
        require(rootCommittedAt > 0, "L1_BRG: rootCommittedAt must be greater than 0");
        transferRootCommittedAt[transferRootId] = rootCommittedAt;
        chainBalance[originChainId] = chainBalance[originChainId].sub(totalAmount, "L1_BRG: Amount exceeds chainBalance. This indicates a layer-2 failure.");

        // If the TransferRoot was never bonded, distribute the TransferRoot.
        TransferBond storage transferBond = transferBonds[transferRootId];
        if (transferBond.createdAt == 0) {
            _distributeTransferRoot(rootHash, destinationChainId, totalAmount);
        }

        emit TransferRootConfirmed(originChainId, destinationChainId, rootHash, totalAmount);
    }

    function _distributeTransferRoot(
        bytes32 rootHash,
        uint256 chainId,
        uint256 totalAmount
    )
        internal
    {
        // Set TransferRoot on recipient Bridge
        if (chainId == getChainId()) {
            // Set L1 TransferRoot
            _setTransferRoot(rootHash, totalAmount);
        } else {
            IMessengerWrapper messengerWrapper = crossDomainMessengerWrappers[chainId];
            require(messengerWrapper != IMessengerWrapper(0), "L1_BRG: chainId not supported");

            // Set L2 TransferRoot
            bytes memory setTransferRootMessage = abi.encodeWithSignature(
                "setTransferRoot(bytes32,uint256)",
                rootHash,
                totalAmount
            );
            messengerWrapper.sendCrossDomainMessage(setTransferRootMessage);
        }
    }

    /* ========== External TransferRoot Challenges ========== */

    /**
     * @dev Challenge a TransferRoot believed to be fraudulent
     * @param rootHash The Merkle root of the TransferRoot Merkle tree
     * @param originalAmount The total amount bonded for this TransferRoot
     */
    function challengeTransferBond(bytes32 rootHash, uint256 originalAmount) external payable {
        bytes32 transferRootId = getTransferRootId(rootHash, originalAmount);
        TransferBond storage transferBond = transferBonds[transferRootId];

        require(transferRootCommittedAt[transferRootId] == 0, "L1_BRG: TransferRoot has already been confirmed");
        require(transferBond.createdAt != 0, "L1_BRG: TransferRoot has not been bonded");
        uint256 challengePeriodEnd = transferBond.createdAt.add(challengePeriod);
        require(challengePeriodEnd >= block.timestamp, "L1_BRG: TransferRoot cannot be challenged after challenge period");
        require(transferBond.challengeStartTime == 0, "L1_BRG: TransferRoot already challenged");

        transferBond.challengeStartTime = block.timestamp;
        transferBond.challenger = msg.sender;

        // Move amount from timeSlotToAmountBonded to debit
        uint256 timeSlot = getTimeSlot(transferBond.createdAt);
        uint256 bondAmount = getBondForTransferAmount(originalAmount);
        address bonder = transferBond.bonder;
        timeSlotToAmountBonded[timeSlot][bonder] = timeSlotToAmountBonded[timeSlot][bonder].sub(bondAmount);

        _addDebit(transferBond.bonder, bondAmount);

        // Get stake for challenge
        uint256 challengeStakeAmount = getChallengeAmountForTransferAmount(originalAmount);
        _transferToBridge(msg.sender, challengeStakeAmount);

        emit TransferBondChallenged(transferRootId, rootHash, originalAmount);
    }

    /**
     * @dev Resolve a challenge after the `challengeResolutionPeriod` has passed
     * @param rootHash The Merkle root of the TransferRoot Merkle tree
     * @param originalAmount The total amount originally bonded for this TransferRoot
     */
    function resolveChallenge(bytes32 rootHash, uint256 originalAmount) external {
        bytes32 transferRootId = getTransferRootId(rootHash, originalAmount);
        TransferBond storage transferBond = transferBonds[transferRootId];

        require(transferBond.challengeStartTime != 0, "L1_BRG: TransferRoot has not been challenged");
        require(block.timestamp > transferBond.challengeStartTime.add(challengeResolutionPeriod), "L1_BRG: Challenge period has not ended");
        require(transferBond.challengeResolved == false, "L1_BRG: TransferRoot already resolved");
        transferBond.challengeResolved = true;

        uint256 challengeStakeAmount = getChallengeAmountForTransferAmount(originalAmount);

        if (transferRootCommittedAt[transferRootId] > 0) {
            // Invalid challenge

            if (transferBond.createdAt > transferRootCommittedAt[transferRootId].add(minTransferRootBondDelay)) {
                // Credit the bonder back with the bond amount plus the challenger's stake
                _addCredit(transferBond.bonder, getBondForTransferAmount(originalAmount).add(challengeStakeAmount));
            } else {
                // If the TransferRoot was bonded before it was committed, the challenger and Bonder
                // get their stake back. This discourages Bonders from tricking challengers into
                // challenging a valid TransferRoots that haven't yet been committed. It also ensures
                // that Bonders are not punished if a TransferRoot is bonded too soon in error.

                // Return the challenger's stake
                _addCredit(transferBond.challenger, challengeStakeAmount);
                // Credit the bonder back with the bond amount
                _addCredit(transferBond.bonder, getBondForTransferAmount(originalAmount));
            }
        } else {
            // Valid challenge
            // Burn 25% of the challengers stake
            _transferFromBridge(address(0xdead), challengeStakeAmount.mul(1).div(4));
            // Reward challenger with the remaining 75% of their stake plus 100% of the Bonder's stake
            _addCredit(transferBond.challenger, challengeStakeAmount.mul(7).div(4));
        }

        emit ChallengeResolved(transferRootId, rootHash, originalAmount);
    }

    /* ========== Override Functions ========== */

    function _additionalDebit(address bonder) internal view override returns (uint256) {
        uint256 currentTimeSlot = getTimeSlot(block.timestamp);
        uint256 bonded = 0;

        uint256 numTimeSlots = challengePeriod / TIME_SLOT_SIZE;
        for (uint256 i = 0; i < numTimeSlots; i++) {
            bonded = bonded.add(timeSlotToAmountBonded[currentTimeSlot - i][bonder]);
        }

        return bonded;
    }

    function _requireIsGovernance() internal override {
        require(governance == msg.sender, "L1_BRG: Caller is not the owner");
    }

    /* ========== External Config Management Setters ========== */

    function setGovernance(address _newGovernance) external onlyGovernance {
        require(_newGovernance != address(0), "L1_BRG: _newGovernance cannot be address(0)");
        governance = _newGovernance;
    }

    function setCrossDomainMessengerWrapper(uint256 chainId, IMessengerWrapper _crossDomainMessengerWrapper) external onlyGovernance {
        crossDomainMessengerWrappers[chainId] = _crossDomainMessengerWrapper;
    }

    function setChainIdDepositsPaused(uint256 chainId, bool isPaused) external onlyGovernance {
        isChainIdPaused[chainId] = isPaused;
    }

    function setChallengePeriod(uint256 _challengePeriod) external onlyGovernance {
        require(_challengePeriod % TIME_SLOT_SIZE == 0, "L1_BRG: challengePeriod must be divisible by TIME_SLOT_SIZE");

        challengePeriod = _challengePeriod;
    }

    function setChallengeResolutionPeriod(uint256 _challengeResolutionPeriod) external onlyGovernance {
        challengeResolutionPeriod = _challengeResolutionPeriod;
    }

    function setMinTransferRootBondDelay(uint256 _minTransferRootBondDelay) external onlyGovernance {
        minTransferRootBondDelay = _minTransferRootBondDelay;
    }

    /* ========== Public Getters ========== */

    function getBondForTransferAmount(uint256 amount) public view returns (uint256) {
        // Bond covers amount plus a bounty to pay a potential challenger
        return amount.add(getChallengeAmountForTransferAmount(amount));
    }

    function getChallengeAmountForTransferAmount(uint256 amount) public view returns (uint256) {
        // Bond covers amount plus a bounty to pay a potential challenger
        return amount.div(CHALLENGE_AMOUNT_DIVISOR);
    }

    function getTimeSlot(uint256 time) public pure returns (uint256) {
        return time / TIME_SLOT_SIZE;
    }
}

/**
 * @dev A MessengerWrapper for Polygon - https://docs.matic.network/docs
 * @notice Deployed on layer-1
 */

contract PolygonMessengerWrapper is BaseRootTunnel, MessengerWrapper {

    constructor(
        address _l1BridgeAddress
    )
        public
        MessengerWrapper(_l1BridgeAddress)
    {}

    /** 
     * @dev Sends a message to the l2MessengerProxy from layer-1
     * @param _calldata The data that l2MessengerProxy will be called with
     * @notice The msg.sender is sent to the L2_PolygonMessengerProxy and checked there.
     */
    function sendCrossDomainMessage(bytes memory _calldata) public override {
        _sendMessageToChild(
            abi.encode(msg.sender, _calldata)
        );
    }

    function verifySender(address l1BridgeCaller, bytes memory /*_data*/) public override {
        require(l1BridgeCaller == address(this), "L1_PLGN_WPR: Caller must be this contract");
    }

    function _processMessageFromChild(bytes memory message) internal override {
        (bool success,) = l1BridgeAddress.call(message);
        require(success, "L1_PLGN_WPR: Call to L1 Bridge failed");
    }
}