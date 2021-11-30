/**
 *Submitted for verification at polygonscan.com on 2021-11-29
*/

pragma solidity 0.6.12;
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
interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

//
interface IDigitalaxMonaOracle {
    function getData() external returns (uint256, bool);
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
// solhint-disable-next-line compiler-version
/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

//
/**
 * @title Digitalax Rewards
 * @dev Calculates the rewards for staking on the Digitalax platform
 * @author DIGITALAX CORE TEAM
 * @author Based on original staking contract by Adrian Guerrera (deepyr)
 */
interface DigitalaxStaking {
    function stakedEthTotal() external view returns (uint256);
}

interface MONA is IERC20 {
    function mint(address tokenOwner, uint tokens) external returns (bool);
}

contract DigitalaxNFTRewardsV2 is BaseRelayRecipient, Initializable {
    using SafeMath for uint256;
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
    uint256 private _NOT_ENTERED;
    uint256 private _ENTERED;
    uint256 private _status;

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

    /* ========== Variables ========== */

    MONA public monaToken;
    /// @notice Mona to Ether Oracle
    IDigitalaxMonaOracle public oracle;
    DigitalaxAccessControls public accessControls;
    DigitalaxStaking public nftStaking;

    mapping(address => uint256) public rewardTokensIndex;
    address[] public rewardTokens;

    uint256 public MAX_REWARD_TOKENS;
    uint256 constant pointMultiplier = 10e18;
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 constant SECONDS_PER_WEEK = 7 * 24 * 60 * 60;

    mapping (uint256 => uint256) public weeklyMonaRevenueSharingPerSecond; // Mona revenue sharing
  	mapping (address => mapping(uint256 => uint256)) public weeklyTokenRevenueSharingPerSecond; // All token  revenue sharing


    uint256 public startTime;
    uint256 public monaRewardsPaidTotal;

	mapping(address => uint256) public tokenRewardsPaidTotal;
	mapping(address => uint256) public tokenRewardsPaid;

    /// @notice for storing information from oracle
    uint256 public lastOracleQuote;

    // We must trust admin to pass correct weighted values, if not we could use something like
    // / @notice mapping of a staker to its current properties
    //mapping (uint256 => uint256) public weeklyTotalWeightPoints;

    /* @notice staking pool id to staking pool reward mapping
    */
    StakingPoolRewards public pool;

    /* ========== Structs ========== */
    /**
       @notice Struct to track the active pool
       @dev weeklyWeightPoints mapping the week to the weight for this pool
       @dev lastRewardsTime last time the overall rewards
       @dev rewardsPaid amount of rewards that have been paid to this pool
       */
    struct StakingPoolRewards {
        uint256 lastRewardsTime;
        uint256 monaRewardsPaid;
    }

    /* ========== Events ========== */
    event UpdateAccessControls(
        address indexed accessControls
    );
    event RewardAdded(address indexed addr, uint256 reward);
    event RewardDistributed(address indexed addr, uint256 reward);
    event ReclaimedERC20(address indexed token, uint256 amount);

    event UpdateOracle(address indexed oracle);

    // Events
    event AddRewardTokens(
        address[] rewardTokens
    );

    event RemoveRewardTokens(
        address[] rewardTokens
    );

    event DepositRevenueSharing(
        uint256 weeklyMonaRevenueSharingPerSecond,
        uint256 _week,
        uint256 _amount,
        address[] rewardTokens,
        uint256[] rewardAmounts
    );

    event WithdrawRevenueSharing(
        uint256 weeklyMonaRevenueSharingPerSecond,
        uint256 _week,
        uint256 _amount,
        address[] rewardTokens,
        uint256[] rewardTokenAmounts
    );


    /* ========== Admin Functions ========== */
    function initialize(
        MONA _monaToken,
        DigitalaxAccessControls _accessControls,
        DigitalaxStaking _nftStaking,
        IDigitalaxMonaOracle _oracle,
        address _trustedForwarder,
        uint256 _startTime,
        uint256 _monaRewardsPaidTotal
    )
        public initializer
    {
        require(
            address(_monaToken) != address(0),
            "DigitalaxRewardsV2: Invalid Mona Address"
        );
        require(
            address(_accessControls) != address(0),
            "DigitalaxRewardsV2: Invalid Access Controls"
        );
        require(
            address(_nftStaking) != address(0),
            "DigitalaxRewardsV2: Invalid Mona Staking"
        );
        require(
            address(_oracle) != address(0),
            "DigitalaxRewardsV2: Invalid Mona Oracle"
        );
        monaToken = _monaToken;
        accessControls = _accessControls;
        nftStaking = _nftStaking;
        oracle = _oracle;
        startTime = _startTime;
        monaRewardsPaidTotal = _monaRewardsPaidTotal;
        trustedForwarder = _trustedForwarder;

        MAX_REWARD_TOKENS = 100;
        _NOT_ENTERED = 1;
        _ENTERED = 2;
        _status = _NOT_ENTERED;

        lastOracleQuote = 1e18;
    }
    receive() external payable {
    }


    function setTrustedForwarder(address _trustedForwarder) external  {
        require(
            accessControls.hasAdminRole(_msgSender()),
            "DigitalaxRewardsV2.setTrustedForwarder: Sender must be admin"
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
       * Override this function.
       * This version is to keep track of BaseRelayRecipient you are using
       * in your contract.
       */
    function versionRecipient() external view override returns (string memory) {
        return "1";
    }


/*
 * @notice Set the start time
 * @dev Setter functions for contract config
*/
    function setStartTime(
        uint256 _startTime
    )
        external
    {
        require(
            accessControls.hasAdminRole(_msgSender()),
            "DigitalaxRewardsV2.setStartTime: Sender must be admin"
        );
        startTime = _startTime;
    }

    /**
     @notice Method for updating oracle
     @dev Only admin
     @param _oracle new oracle
     */
    function updateOracle(IDigitalaxMonaOracle _oracle) external {
        require(
            accessControls.hasAdminRole(_msgSender()),
            "DigitalaxRewardsV2.updateOracle: Sender must be admin"
        );

        oracle = _oracle;
        emit UpdateOracle(address(_oracle));
    }


    /**
     @notice Method for updating the access controls contract used by the NFT
     @dev Only admin
     @param _accessControls Address of the new access controls contract (Cannot be zero address)
     */
    function updateAccessControls(DigitalaxAccessControls _accessControls) external {
        require(
            accessControls.hasAdminRole(_msgSender()),
            "DigitalaxRewardsV2.updateAccessControls: Sender must be admin"
        );
        require(address(_accessControls) != address(0), "DigitalaxRewardsV2.updateAccessControls: Zero Address");
        accessControls = _accessControls;
        emit UpdateAccessControls(address(_accessControls));
    }

    /**
     @notice Method for updating the address of the mona staking contract
     @dev Only admin
     @param _addr Address of the mona staking contract
    */
    function setNftStaking(address _addr)
        external
        {
            require(
                accessControls.hasAdminRole(_msgSender()),
                "DigitalaxRewardsV2.setNftStaking: Sender must be admin"
            );
            nftStaking = DigitalaxStaking(_addr);
    }

    /*
     * @notice Deposit revenue sharing rewards to be distributed during a certain week
     * @dev this number is the total rewards that week with 18 decimals
     */
    function depositRewards(
        uint256 _week,
        uint256 _amount,
        address[] memory _rewardTokens,
        uint256[] memory _rewardAmounts
    )
        external
    {
        require(
            accessControls.hasAdminRole(_msgSender()),
            "DigitalaxRewardsV2.depositMonaRewards: Sender must be admin"
        );

        require(
            _week >= getCurrentWeek(),
            "DigitalaxRewardsV2.depositRevenueSharingRewards: The rewards generated should be set for the future weeks"
        );

        require(IERC20(monaToken).allowance(_msgSender(), address(this)) >= _amount, "DigitalaxRewardsV2.depositRevenueSharingRewards: Failed to supply ERC20 Allowance");

        // Deposit this amount of MONA here
        require(IERC20(monaToken).transferFrom(
            address(_msgSender()),
            address(this),
            _amount
        ));


        uint256 monaAmount = _amount.mul(pointMultiplier)
                                   .div(SECONDS_PER_WEEK)
                                   .div(pointMultiplier);


        // Increase the revenue sharing per second for the week for Mona
        weeklyMonaRevenueSharingPerSecond[_week] = weeklyMonaRevenueSharingPerSecond[_week].add(monaAmount);

		for (uint i = 0; i < _rewardTokens.length; i++) {
            require(_rewardTokens[i] != address(0) && _rewardTokens[i] != address(monaToken), "This param is not for MONA or 0 address");
            require(IERC20(_rewardTokens[i]).allowance(_msgSender(), address(this)) >= _rewardAmounts[i], "DepositRevenueSharingRewards: Failed to supply ERC20 Allowance");

            // Deposit this amount of MONA here
            require(IERC20(_rewardTokens[i]).transferFrom(
                address(_msgSender()),
                address(this),
                _rewardAmounts[i]
            ));

            uint256 rewardAmount = _rewardAmounts[i].mul(pointMultiplier)
                .div(SECONDS_PER_WEEK)
                .div(pointMultiplier);

            weeklyTokenRevenueSharingPerSecond[_rewardTokens[i]][_week] = weeklyTokenRevenueSharingPerSecond[_rewardTokens[i]][_week].add(rewardAmount);
         }

        emit DepositRevenueSharing(weeklyMonaRevenueSharingPerSecond[_week], _week, _amount, _rewardTokens, _rewardAmounts);
    }

    /*
     * @notice Deposit revenue sharing rewards to be distributed during a certain week
     * @dev this number is the total rewards that week with 18 decimals
     */
    function withdrawRewards(
        uint256 _week,
        uint256 _amount,
        address[] memory _rewardTokens,
        uint256[] memory _rewardAmounts
    )
        external
    {
        require(
            accessControls.hasAdminRole(_msgSender()),
            "DigitalaxRewardsV2.withdrawMonaRewards: Sender must be admin"
        );

        require(
            _week > getCurrentWeek(),
            "DigitalaxRewardsV2.withdrawMonaRewards: The rewards generated should be set for the future weeks"
        );


        // Withdraw this amount of MONA here
       IERC20(monaToken).transfer(
            _msgSender(),
            _amount
        );


        uint256 monaAmount = _amount.mul(pointMultiplier)
                                   .div(SECONDS_PER_WEEK)
                                   .div(pointMultiplier);

        require(monaAmount <= weeklyMonaRevenueSharingPerSecond[_week], "DigitalaxRewardsV2.withdrawMonaRewards: Cannot withdraw back more then week amount");
        // Increase the revenue sharing per second for the week for Mona
        weeklyMonaRevenueSharingPerSecond[_week] = weeklyMonaRevenueSharingPerSecond[_week].sub(monaAmount);
		  for (uint i = 0; i < _rewardTokens.length; i++) {
            require(_rewardTokens[i] != address(0) && _rewardTokens[i] != address(monaToken), "This param is not for MONA or 0 address");

            uint256 rewardAmount = _rewardAmounts[i].mul(pointMultiplier)
                .div(SECONDS_PER_WEEK)
                .div(pointMultiplier);

            require(rewardAmount <= weeklyMonaRevenueSharingPerSecond[_week], "DigitalaxRewardsV2.withdrawMonaRewards: Cannot withdraw back more then week amount");


            // Deposit this amount of MONA here
            require(IERC20(_rewardTokens[i]).transferFrom(
                address(this),
                address(_msgSender()),
                _rewardAmounts[i]
            ));

            weeklyTokenRevenueSharingPerSecond[_rewardTokens[i]][_week] = weeklyTokenRevenueSharingPerSecond[_rewardTokens[i]][_week].sub(rewardAmount);
        }


        emit WithdrawRevenueSharing(weeklyMonaRevenueSharingPerSecond[_week], _week, _amount, _rewardTokens, _rewardAmounts);
    }

    /* From BokkyPooBah's DateTime Library v1.01
     * https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
     */
    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }


    /* ========== Mutative Functions ========== */

    /* @notice Calculate and update rewards
     * @dev
     */
    function updateRewards()
        external
        returns(bool)
    {
        if (_getNow() <= pool.lastRewardsTime) {
            return false;
        }

        /// @dev check that the staking pool has contributions, and rewards have started
        if (_getNow() <= startTime) {
            pool.lastRewardsTime = _getNow();
            return false;
        }

        // @dev Update the oracle
        (uint256 exchangeRate, bool rateValid) = oracle.getData();
        require(rateValid, "DigitalaxMarketplace.estimateMonaAmount: Oracle data is invalid");
        lastOracleQuote = exchangeRate;

        /// @dev This sends rewards (Mona from revenue sharing)
        _updateMonaRewards();

        /// @dev This updates the extra token rewards (Any token from revenue sharing)
        _updateTokenRewards();
        /// @dev update accumulated reward
        pool.lastRewardsTime = _getNow();
        return true;
    }


    /*
     * @dev Setter functions for contract config custom last rewards time for a pool
     */
    function setLastRewardsTime(uint256 _lastRewardsTime) external
    {
        require(
            accessControls.hasAdminRole(_msgSender()),
            "DigitalaxRewardsV2.setLastRewardsTime: Sender must be admin"
        );
        pool.lastRewardsTime = _lastRewardsTime;
    }


    /*
     * @dev Setter functions for contract config custom last rewards time for a pool
     */
    function setMaxRewardsTokens(
    uint256 _maxRewardsTokensCount) external
    {
        require(
            accessControls.hasAdminRole(_msgSender()),
            "DigitalaxRewardsV2.setMaxRewardsTokens: Sender must be admin"
        );
        MAX_REWARD_TOKENS = _maxRewardsTokensCount;

    }

    function addRewardTokens(address[] memory _rewardTokens) public {
        require(
            accessControls.hasAdminRole(_msgSender()),
            "AddRewardTokens: Sender must be admin"
        );
        require((_rewardTokens.length) > 0, "AddRewardTokens: Empty array not supported");
        require(MAX_REWARD_TOKENS >= _rewardTokens.length, "AddRewardTokens: Already reached max erc20 supported");
        for (uint i = 0; i < _rewardTokens.length; i++) {
            if(!checkInRewardTokens(_rewardTokens[i])) {
                uint256 index = rewardTokens.length;
                rewardTokens.push(_rewardTokens[i]);
                rewardTokensIndex[_rewardTokens[i]] = index;
            }
        }
        emit AddRewardTokens(_rewardTokens);
    }

    function removeRewardTokens(address[] memory _rewardTokens) public {
        require(
            accessControls.hasAdminRole(_msgSender()),
            "RemoveRewardTokens: Sender must be admin"
        );

        require((rewardTokens.length) > 0, "RemoveRewardTokens: No reward tokens instantiated");
        require((_rewardTokens.length) > 0, "RemoveRewardTokens: Empty array not supported");

        for (uint i = 0; i < _rewardTokens.length; i++) {
            if(checkInRewardTokens(_rewardTokens[i])) {
                uint256 rowToDelete = rewardTokensIndex[_rewardTokens[i]];
                address keyToMove = rewardTokens[rewardTokens.length-1];
                rewardTokens[rowToDelete] = keyToMove;
                rewardTokensIndex[keyToMove] = rowToDelete;
                rewardTokens.pop();
                delete(rewardTokensIndex[_rewardTokens[i]]);
            }
        }

        emit RemoveRewardTokens(_rewardTokens);
    }

    function checkInRewardTokens(address _rewardToken) public view returns (bool isAddress) {
        if(rewardTokens.length == 0) return false;
        return (rewardTokens[rewardTokensIndex[_rewardToken]] == _rewardToken);
    }

    function getExtraRewardTokens() external view returns (address[] memory returnRewardTokens){
        return getRewardTokens();
    }

    function getRewardTokens() internal view returns (address[] memory returnRewardTokens){
        address[] memory a = new address[](rewardTokens.length);
        for (uint i=0; i< rewardTokens.length; i++) {
            a[i] = rewardTokens[i];
        }
        return a;
    }

    /* ========== View Functions ========== */

    /*
     * @notice Gets the total rewards outstanding from last reward time
     */
    function totalNewMonaRewards() external view returns (uint256) {
        uint256 lRewards = MonaRewards(pool.lastRewardsTime, _getNow());
        return lRewards;
    }

     /*
     * @notice Gets the total rewards outstanding from last reward time
     */
    function totalNewRewardsWithToken(address _rewardToken) external view returns (uint256) {
        uint256 lRewards = TokenRevenueRewards(_rewardToken, pool.lastRewardsTime, _getNow());
        return lRewards;
    }

    /*
     * @notice Get the last rewards time for a pool
     * @return last rewards time for a pool
     */
    function lastRewardsTime()
        external
        view
        returns(uint256)
    {
        return pool.lastRewardsTime;
    }

    /* @notice Return mona revenue rewards over the given _from to _to timestamp.
     * @dev A fraction of the start, multiples of the middle weeks, fraction of the end
     */
    function MonaRewards(uint256 _from, uint256 _to) public view returns (uint256 rewards) {
        if (_to <= startTime) {
            return 0;
        }
        if (_from < startTime) {
            _from = startTime;
        }
        uint256 fromWeek = diffDays(startTime, _from) / 7;
        uint256 toWeek = diffDays(startTime, _to) / 7;

        if (fromWeek == toWeek) {
            return _rewardsFromPoints(weeklyMonaRevenueSharingPerSecond[fromWeek],
                                    _to.sub(_from));
        }
        /// @dev First count remainder of first week
        uint256 initialRemander = startTime.add((fromWeek+1).mul(SECONDS_PER_WEEK)).sub(_from);
        rewards = _rewardsFromPoints(weeklyMonaRevenueSharingPerSecond[fromWeek],
                                    initialRemander);

        /// @dev add multiples of the week
        for (uint256 i = fromWeek+1; i < toWeek; i++) {
            rewards = rewards.add(_rewardsFromPoints(weeklyMonaRevenueSharingPerSecond[i],
                                    SECONDS_PER_WEEK));
        }
        /// @dev Adds any remaining time in the most recent week till _to
        uint256 finalRemander = _to.sub(toWeek.mul(SECONDS_PER_WEEK).add(startTime));
        rewards = rewards.add(_rewardsFromPoints(weeklyMonaRevenueSharingPerSecond[toWeek],
                                    finalRemander));
        return rewards;
    }

 /* @notice Return bonus mona revenue rewards over the given _from to _to timestamp.
     * @dev A fraction of the start, multiples of the middle weeks, fraction of the end
     */
    function TokenRevenueRewards(address _rewardToken, uint256 _from, uint256 _to) public view returns (uint256 rewards) {
        if (_to <= startTime) {
            return 0;
        }
        if (_from < startTime) {
            _from = startTime;
        }
        uint256 fromWeek = diffDays(startTime, _from) / 7;
        uint256 toWeek = diffDays(startTime, _to) / 7;

        if (fromWeek == toWeek) {
            return _rewardsFromPoints(weeklyTokenRevenueSharingPerSecond[_rewardToken][fromWeek],
                                    _to.sub(_from));
        }
        /// @dev First count remainder of first week
        uint256 initialRemander = startTime.add((fromWeek+1).mul(SECONDS_PER_WEEK)).sub(_from);
        rewards = _rewardsFromPoints(weeklyTokenRevenueSharingPerSecond[_rewardToken][fromWeek],
                                    initialRemander);

        /// @dev add multiples of the week
        for (uint256 i = fromWeek+1; i < toWeek; i++) {
            rewards = rewards.add(_rewardsFromPoints(weeklyTokenRevenueSharingPerSecond[_rewardToken][i],
                                    SECONDS_PER_WEEK));
        }
        /// @dev Adds any remaining time in the most recent week till _to
        uint256 finalRemander = _to.sub(toWeek.mul(SECONDS_PER_WEEK).add(startTime));
        rewards = rewards.add(_rewardsFromPoints(weeklyTokenRevenueSharingPerSecond[_rewardToken][toWeek],
                                    finalRemander));
        return rewards;
    }
    /* ========== Internal Functions ========== */


    function _updateTokenRewards()
        internal
        returns(uint256 rewards)
    {
        address[] memory _rewardsTokens = getRewardTokens();
        for (uint i = 0; i < _rewardsTokens.length; i++)
        {
            rewards = TokenRevenueRewards(_rewardsTokens[i], pool.lastRewardsTime, _getNow());
            if ( rewards > 0 ) {
            tokenRewardsPaidTotal[_rewardsTokens[i]] = tokenRewardsPaidTotal[_rewardsTokens[i]].add(rewards);

                // Send this amount of tokens to the staking contract
                IERC20(_rewardsTokens[i]).transfer(
                    address(nftStaking),
                    rewards
                );
            }
        }
    }

    function _updateMonaRewards()
        internal
        returns(uint256 rewards)
    {
        rewards = MonaRewards(pool.lastRewardsTime, _getNow());
        if ( rewards > 0 ) {
            pool.monaRewardsPaid = pool.monaRewardsPaid.add(rewards);
            monaRewardsPaidTotal = monaRewardsPaidTotal.add(rewards);

            // Send this amount of MONA to the staking contract
            IERC20(monaToken).transfer(
                address(nftStaking),
                rewards
            );
        }
    }

    function getLastRewardsTime() external view returns(uint256 lastRewardsT){
        return pool.lastRewardsTime;
    }

    function _rewardsFromPoints(
        uint256 rate,
        uint256 duration
    )
        internal
        pure
        returns(uint256)
    {
        return rate.mul(duration);
    }


    /* ========== Reclaim ERC20 ========== */

    /*
     * @notice allows for the recovery of incorrect ERC20 tokens sent to contract
     */
    function reclaimERC20(
        address _tokenAddress,
        uint256 _tokenAmount
    )
        external
    {
        // Cannot recover the staking token or the rewards token
        require(
            accessControls.hasAdminRole(_msgSender()),
            "DigitalaxRewardsV2.reclaimERC20: Sender must be admin"
        );
//        require(
//            tokenAddress != address(monaToken),
//            "Cannot withdraw the rewards token"
//        );
        IERC20(_tokenAddress).transfer(_msgSender(), _tokenAmount);
        emit ReclaimedERC20(_tokenAddress, _tokenAmount);
    }

    /**
    * @notice EMERGENCY Recovers ETH, drains amount of eth sitting on the smart contract
    * @dev Only access controls admin can access
    */
    function reclaimETH(uint256 _amount) external {
        require(
            accessControls.hasAdminRole(_msgSender()),
            "DigitalaxRewardsV2.reclaimETH: Sender must be admin"
        );
        _msgSender().transfer(_amount);
    }


    /* ========== Getters ========== */

    function getCurrentWeek()
        public
        view
        returns(uint256)
    {
        return diffDays(startTime, _getNow()) / 7;
    }

    function getMonaStakedEthTotal()
        public
        view
        returns(uint256)
    {
        return nftStaking.stakedEthTotal();
    }

    function getMonaDailyAPY()
        external
        view
        returns (uint256)
    {
        uint256 stakedEth = nftStaking.stakedEthTotal();

        uint256 yearlyReturnInEth = 0;

        if ( stakedEth != 0) {
            uint256 rewards = MonaRewards(_getNow() - 60, _getNow());
            uint256 rewardsInEth = rewards.mul(getEthPerMona()).div(1e18);

            /// @dev minutes per year x 100 = 52560000
            yearlyReturnInEth = rewardsInEth.mul(52560000).mul(1e18).div(stakedEth);
        }

      return yearlyReturnInEth;
    }

     // Get the amount of yearly return of rewards token per 1 MONA
   function getTokenRewardDailyAPY(address _rewardToken)
        external
        view
        returns (uint256)
    {
        uint256 stakedValue = nftStaking.stakedEthTotal();

        uint256 yearlyReturnPerMona = 0;

        if ( stakedValue != 0) {
            uint256 rewards = TokenRevenueRewards(_rewardToken, _getNow() - 60, _getNow());

            /// @dev minutes per year x 100 = 52560000
            yearlyReturnPerMona = rewards.mul(52560000).mul(1e18).div(stakedValue);
        }
      return yearlyReturnPerMona;
    }


    // MONA amount for custom ETH amount
    function getMonaPerEth(uint256 _ethAmt)
        public
        view
        returns (uint256)
    {
        return _ethAmt.mul(1e18).div(lastOracleQuote);
    }

    // ETH amount for 1 MONA
    function getEthPerMona()
        public
        view
        returns (uint256)
    {
        return lastOracleQuote;
    }

    function _getNow() internal virtual view returns (uint256) {
        return block.timestamp;
    }
}