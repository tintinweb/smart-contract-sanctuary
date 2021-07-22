/**
 *Submitted for verification at Etherscan.io on 2021-07-22
*/

// SPDX-License-Identifier: GPL-3.0-or-later
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
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

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


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transfered from `from` to `to`.
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

/** @title SafeSwap constract
    @author Tal Asa <[email protected]> , Ori Shalom <[email protected]>
    @notice handles swapping of token between 2 parties:
        sender - fills the information for both parties
        addresses - his address and the recipient address
        token - address of the specific token to be transferred (eth, token20, token721)
        value - the value that he will be sending and the value he will be recieving
        fees - both parties fees
        secretHash - a hash of his secret for the secure transfer

        recipient - checks that all the agreed between the two is the info is filled correctly
        and if so, approves the swap
 */
contract SafeSwap is AccessControl {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // keccak256("ACTIVATOR_ROLE");
    bytes32 public constant ACTIVATOR_ROLE =
        0xec5aad7bdface20c35bc02d6d2d5760df981277427368525d634f4e2603ea192;

    // keccak256("hiddenSwap(address from,address to,address token0,uint256 value0,uint256 fees0,address token1,uint256 value1,uint256 fees1,bytes32 secretHash)");
    bytes32 public constant HIDDEN_SWAP_TYPEHASH =
        0x0f11af065228fe4d4a82a264c46914620a3a99413bfee68f390bd6a3ba05e2c2;

    // keccak256("hiddenSwapERC721(address from,address to,address token0,uint256 value0,bytes tokenData0,uint256 fees0,address token1,uint256 value1,bytes tokenData1,uint256 fees1,bytes32 secretHash)");
    bytes32 public constant HIDDEN_ERC721_SWAP_TYPEHASH =
        0x22eb06b067ef6305a65d8334d41817cd2fb49f43ee331996ed20687c8152e5ed;

    uint256 s_fees;

    struct SwapInfo {
        address token0;
        uint256 value0;
        uint256 fees0;
        address token1;
        uint256 value1;
        uint256 fees1;
        bytes32 secretHash;
    }

    struct SwapERC721Info {
        address token0;
        uint256 value0; //in case of ether it's a value, in case of 721 it's tokenId
        bytes tokenData0;
        uint256 fees0;
        address token1;
        uint256 value1; //in case of ether it's a value, in case of 721 it's tokenId
        bytes tokenData1;
        uint256 fees1;
        bytes32 secretHash;
    }

    mapping(bytes32 => uint256) s_swaps;
    mapping(bytes32 => uint256) s_hswaps;

    string public constant NAME = "Kirobo Safe Swap";
    string public constant VERSION = "1";
    uint8 public constant VERSION_NUMBER = 0x1;

    event Deposited(
        address indexed from,
        address indexed to,
        address indexed token0,
        uint256 value0,
        uint256 fees0,
        address token1,
        uint256 value1,
        uint256 fees1,
        bytes32 secretHash
    );

    event TimedDeposited(
        address indexed from,
        address indexed to,
        address indexed token0,
        uint256 value0,
        uint256 fees0,
        address token1,
        uint256 value1,
        uint256 fees1,
        bytes32 secretHash,
        uint64 availableAt,
        uint64 expiresAt,
        uint128 autoRetrieveFees
    );

    event Retrieved(
        address indexed from,
        address indexed to,
        bytes32 indexed id,
        uint256 value
    );

    event Swapped(
        address indexed from,
        address indexed to,
        bytes32 indexed id,
        address token0,
        uint256 value0,
        address token1,
        uint256 value1
    );

    event ERC721Deposited(
        address indexed from,
        address indexed to,
        address indexed token0,
        uint256 value0, //in case of ether it's a value, in case of 721 it's tokenId
        uint256 fees0,
        address token1,
        uint256 value1, //in case of ether it's a value, in case of 721 it's tokenId
        uint256 fees1,
        bytes32 secretHash
    );

    event ERC721TimedDeposited(
        address indexed from,
        address indexed to,
        address indexed token0,
        uint256 value0, //in case of ether it's a value, in case of 721 it's tokenId
        uint256 fees0,
        address token1,
        uint256 value1, //in case of ether it's a value, in case of 721 it's tokenId
        uint256 fees1,
        bytes32 secretHash,
        uint64 availableAt,
        uint64 expiresAt,
        uint128 autoRetrieveFees
    );

    event ERC721Retrieved(
        address indexed token,
        address indexed from,
        address indexed to,
        bytes32 id,
        uint256 tokenId
    );

    event ERC721Swapped(
        address indexed from,
        address indexed to,
        address indexed token0,
        uint256 value0,
        address token1,
        uint256 value1,
        bytes32 id
    );

    event HDeposited(address indexed from, uint256 value, bytes32 indexed id1);

    event HTimedDeposited(
        address indexed from,
        uint256 value,
        bytes32 indexed id1,
        uint64 availableAt,
        uint64 expiresAt,
        uint128 autoRetrieveFees
    );

    event HRetrieved(address indexed from, bytes32 indexed id1, uint256 value);

    event HSwapped(
        address indexed from,
        address indexed to,
        bytes32 indexed id1,
        address token0,
        uint256 value0,
        address token1,
        uint256 value1
    );

    event HERC721Swapped(
        address indexed from,
        address indexed to,
        bytes32 indexed id1,
        address token0,
        uint256 value0,
        address token1,
        uint256 value1
    );

    modifier onlyActivator() {
        require(
            hasRole(ACTIVATOR_ROLE, msg.sender),
            "SafeSwap: not an activator"
        );
        _;
    }

    constructor(address activator) public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ACTIVATOR_ROLE, msg.sender);
        _setupRole(ACTIVATOR_ROLE, activator);
    }

    receive() external payable {
        require(false, "SafeSwap: not accepting ether directly");
    }

    function transferERC20(
        address token,
        address wallet,
        uint256 value
    ) external onlyActivator() {
        IERC20(token).safeTransfer(wallet, value);
    }

    function transferERC721(
        address token,
        address wallet,
        uint256 tokenId,
        bytes calldata data
    ) external onlyActivator() {
        IERC721(token).safeTransferFrom(address(this), wallet, tokenId, data);
    }

    function transferFees(address payable wallet, uint256 value)
        external
        onlyActivator()
    {
        s_fees = s_fees.sub(value);
        wallet.transfer(value);
    }

    function totalFees() external view returns (uint256) {
        return s_fees;
    }

    // --------------------------------- ETH <==> ERC20 ---------------------------------

    /** @notice deposit - safe swap function that the sender side fills with all the relevet information for the swap
               this function deels with Ether and token20 swaps
        @param to: address of the recipient
        @param token0: the address of the token he is sending to the recipient
        @param value0: the amount being sent to the recipient side in the selected token in token0
        @param fees0: the amount of fees the he needs to pay for the swap
        @param token1: the address of the token he is recieving from the recipient
        @param value1: the amount being sent to him by the recipient in the selected token in token1
        @param fees1: the amount of fees the recipient needs to pay for the swap
        @param secretHash: a hash of the secret
 */
    function deposit(
        address payable to,
        address token0,
        uint256 value0,
        uint256 fees0,
        address token1,
        uint256 value1,
        uint256 fees1,
        bytes32 secretHash
    ) external payable {
        require(token0 != token1, "SafeSwap: try to swap the same token");
        if (token0 == address(0)) {
            require(msg.value == value0.add(fees0), "SafeSwap: value mismatch");
        } else {
            require(msg.value == fees0, "SafeSwap: value mismatch");
        }
        require(to != msg.sender, "SafeSwap: sender==recipient");
        bytes32 id = keccak256(
            abi.encode(
                msg.sender,
                to,
                token0,
                value0,
                fees0,
                token1,
                value1,
                fees1,
                secretHash
            )
        );
        require(s_swaps[id] == 0, "SafeSwap: request exist");
        s_swaps[id] = 0xffffffffffffffff; // expiresAt: max, AvailableAt: 0, autoRetrieveFees: 0
        emit Deposited(
            msg.sender,
            to,
            token0,
            value0,
            fees0,
            token1,
            value1,
            fees1,
            secretHash
        );
    }

    /** @notice timedDeposit - handles deposits with an addition that has a timer in seconds
        @param to: address of the recipient
        @param token0: the address of the token he is sending to the recipient
        @param value0: the amount being sent to the recipient side in the selected token in token0
        @param fees0: the amount of fees the he needs to pay for the swap
        @param token1: the address of the token he is recieving from the recipient
        @param value1: the amount being sent to him by the recipient in the selected token in token1
        @param fees1: the amount of fees the recipient needs to pay for the swap
        @param secretHash: a hash of the secret
        @param availableAt: sets a start time in seconds for when the deposite can happen
        @param expiresAt: sets an end time in seconds for when the deposite can happen
        @param autoRetrieveFees: the amount of fees that will be collected from the sender in case of retrieve
     */
    function timedDeposit(
        address payable to,
        address token0,
        uint256 value0,
        uint256 fees0,
        address token1,
        uint256 value1,
        uint256 fees1,
        bytes32 secretHash,
        uint64 availableAt,
        uint64 expiresAt,
        uint128 autoRetrieveFees
    ) external payable {
        require(token0 != token1, "SafeSwap: try to swap the same token");
        require(
            fees0 >= autoRetrieveFees,
            "SafeSwap: autoRetrieveFees exeed fees"
        );
        require(to != msg.sender, "SafeSwap: sender==recipient");
        require(expiresAt > now, "SafeSwap: already expired");
        if (token0 == address(0)) {
            require(msg.value == value0.add(fees0), "SafeSwap: value mismatch");
        } else {
            require(msg.value == fees0, "SafeSwap: value mismatch");
        }

        bytes32 id = keccak256(
            abi.encode(
                msg.sender,
                to,
                token0,
                value0,
                fees0,
                token1,
                value1,
                fees1,
                secretHash
            )
        );
        require(s_swaps[id] == 0, "SafeSwap: request exist");
        s_swaps[id] =
            uint256(expiresAt) +
            uint256(availableAt << 64) +
            (uint256(autoRetrieveFees) << 128);
        emit TimedDeposited(
            msg.sender,
            to,
            token0,
            value0,
            fees0,
            token1,
            value1,
            fees1,
            secretHash,
            availableAt,
            expiresAt,
            autoRetrieveFees
        );
    }

    /** @notice Retrieve - gives the functionallity of the undo
                after the sender sends the deposit he can undo it (for what ever reason)
                until the recipient didnt approved the swap (swap function below)
        @param to: address of the recipient
        @param token0: the address of the token he is sending to the recipient
        @param value0: the amount being sent to the recipient side in the selected token in token0
        @param fees0: the amount of fees the he needs to pay for the swap
        @param token1: the address of the token he is recieving from the recipient
        @param value1: the amount being sent to him by the recipient in the selected token in token1
        @param fees1: the amount of fees the recipient needs to pay for the swap
        @param secretHash: a hash of the secret
     */
    function retrieve(
        address to,
        address token0,
        uint256 value0,
        uint256 fees0,
        address token1,
        uint256 value1,
        uint256 fees1,
        bytes32 secretHash
    ) external {
        bytes32 id = keccak256(
            abi.encode(
                msg.sender,
                to,
                token0,
                value0,
                fees0,
                token1,
                value1,
                fees1,
                secretHash
            )
        );
        require(s_swaps[id] > 0, "SafeSwap: request not exist");
        delete s_swaps[id];
        uint256 valueToSend;
        if (token0 == address(0)) {
            valueToSend = value0.add(fees0);
        } else {
            valueToSend = fees0;
        }
        msg.sender.transfer(valueToSend);
        emit Retrieved(msg.sender, to, id, valueToSend);
    }

    /** @notice Swap - the recipient side approves the info sent by the sender.
                once this function is submitted successuly the swap is made
        @param from: address of the recipient
        @param token0: the address of the token he is sending to the recipient
        @param value0: the amount being sent to the recipient side in the selected token in token0
        @param fees0: the amount of fees the he needs to pay for the swap
        @param token1: the address of the token he is recieving from the recipient
        @param value1: the amount being sent to him by the recipient in the selected token in token1
        @param fees1: the amount of fees the recipient needs to pay for the swap
        @param secretHash: a hash of the secret
     */
    function swap(
        address payable from,
        address token0,
        uint256 value0,
        uint256 fees0,
        address token1,
        uint256 value1,
        uint256 fees1,
        bytes32 secretHash,
        bytes calldata secret
    )
        external payable
    {
        bytes32 id = keccak256(
            abi.encode(
                from,
                msg.sender,
                token0,
                value0,
                fees0,
                token1,
                value1,
                fees1,
                secretHash
            )
        );
        uint256 tr = s_swaps[id];
        require(tr > 0, "SafeSwap: request not exist");
        require(uint64(tr) > now, "SafeSwap: expired");
        require(uint64(tr >> 64) <= now, "SafeSwap: not available yet");
        require(keccak256(secret) == secretHash, "SafeSwap: wrong secret");
        delete s_swaps[id];
        s_fees = s_fees.add(fees0).add(fees1);
        if (token0 == address(0)) {
            msg.sender.transfer(value0);
        } else {
            IERC20(token0).safeTransferFrom(from, msg.sender, value0);
        }
        if (token1 == address(0)) {
            require(msg.value == value1.add(fees1), "SafeSwap: value mismatch");
            from.transfer(value1);
        } else {
            require(msg.value == fees1, "SafeSwap: value mismatch");
            IERC20(token1).safeTransferFrom(msg.sender, from, value1);
        }
        emit Swapped(from, msg.sender, id, token0, value0, token1, value1);
    }

    /** @notice autoRetrieve - gives the functionallity of the undo with addittion of automation.
                after the sender sends the deposit he can undo it (for what ever reason)
                until the recipient didnt approved the swap (swap function below)
                the autoRetrieve automatically retrieves the funds when a time that was set by the sender is met
        @param from: address of the recipient
        @param to: address of the recipient
        @param token0: the address of the token he is sending to the recipient
        @param value0: the amount being sent to the recipient side in the selected token in token0
        @param fees0: the amount of fees the he needs to pay for the swap
        @param token1: the address of the token he is recieving from the recipient
        @param value1: the amount being sent to him by the recipient in the selected token in token1
        @param fees1: the amount of fees the recipient needs to pay for the swap
        @param secretHash: a hash of the secret
     */
    function autoRetrieve(
        address payable from,
        address to,
        address token0,
        uint256 value0,
        uint256 fees0,
        address token1,
        uint256 value1,
        uint256 fees1,
        bytes32 secretHash
    )
        external
        onlyActivator()
    {
        bytes32 id = keccak256(
            abi.encode(
                from,
                to,
                token0,
                value0,
                fees0,
                token1,
                value1,
                fees1,
                secretHash
            )
        );
        uint256 tr = s_swaps[id];
        require(tr > 0, "SafeSwap: request not exist");
        require(uint64(tr) <= now, "SafeSwap: not expired");
        delete s_swaps[id];
        s_fees = s_fees + (tr >> 128); // autoRetreive fees
        uint256 valueToRetrieve;
        if (token0 == address(0)) {
            valueToRetrieve = value0.add(fees0).sub(tr >> 128);
        } else {
            valueToRetrieve = fees0.sub(tr >> 128);
        }
        from.transfer(valueToRetrieve);
        emit Retrieved(from, to, id, valueToRetrieve);
    }

    // ------------------------------- ERC-721 -------------------------------

    /** @notice depositERC721  - safe swap function that the sender side fills with all the relevet information for the swap
                this function deels with Ether and token721 swaps
        @param to: address of the recipient
        @param token0: the address of the token he is sending to the recipient
        @param value0: in case of Ether  - the amount being sent to the recipient side in the selected token in token0
                       in case of token721 - it's the tokenId of the token721
        @param tokenData0: data on the token Id (only in token721)
        @param fees0: the amount of fees the he needs to pay for the swap
        @param token1: the address of the token he is recieving from the recipient
        @param value1: in case of Ether  - the amount being sent to the recipient side in the selected token in token1
                       in case of token721 - it's the tokenId of the token721
        @param tokenData1: data on the token Id (only in token721)
        @param fees1: the amount of fees the recipient needs to pay for the swap
        @param secretHash: a hash of the secret
 */
    function depositERC721(
        address payable to,
        address token0,
        uint256 value0, //in case of ether it's a value, in case of 721 it's tokenId
        bytes calldata tokenData0,
        uint256 fees0,
        address token1,
        uint256 value1, //in case of ether it's a value, in case of 721 it's tokenId
        bytes calldata tokenData1,
        uint256 fees1,
        bytes32 secretHash
    )
        external payable
    {
        if (token0 == address(0)) {
            //eth to 721
            require(token0 != token1, "SafeSwap: try to swap ether and ether");
            require(msg.value == value0.add(fees0), "SafeSwap: value mismatch");
            require(value1 > 0, "SafeSwap: no token id");
        } else if (token1 == address(0)) {
            //721 to eth
            require(msg.value == fees0, "SafeSwap: value mismatch");
            require(value0 > 0, "SafeSwap: no token id");
        } else {
            //721 to 721
            require(msg.value == fees0, "SafeSwap: value mismatch");
            require(value0 > 0, "SafeSwap: no token id");
            require(value1 > 0, "SafeSwap: no token id");
        }
        require(to != msg.sender, "SafeSwap: sender==recipient");
        bytes32 id = keccak256(
            abi.encode(
                msg.sender,
                to,
                token0,
                value0,
                tokenData0,
                fees0,
                token1,
                value1,
                tokenData1,
                fees1,
                secretHash
            )
        );
        require(s_swaps[id] == 0, "SafeSwap: request exist");
        s_swaps[id] = 0xffffffffffffffff; // expiresAt: max, AvailableAt: 0, autoRetrieveFees: 0
        emit ERC721Deposited(
            msg.sender,
            to,
            token0,
            value0,
            fees0,
            token1,
            value1,
            fees1,
            secretHash
        );
    }

    /** @notice swapERC721 - the recipient side, besically approves the info sent by the sender.
                once this function is submitted successuly the swap is made
        @param from: address of the recipient
        @param info: a struct (SwapErc721Struct) defimed above containing the following params:
                token0: the address of the token he is sending to the recipient
                value0: in case of Ether  - the amount being sent to the recipient side in the selected token in token0
                        in case of token721 - it's the tokenId of the token721
                tokenData0: data on the token Id (only in token721)
                fees0: the amount of fees the he needs to pay for the swap
                token1: the address of the token he is recieving from the recipient
                value1: in case of Ether  - the amount being sent to the recipient side in the selected token in token1
                        in case of token721 - it's the tokenId of the token721
                tokenData1: data on the token Id (only in token721)
                fees1: the amount of fees the recipient needs to pay for the swap
                secretHash: a hash of the secret
        @param secret: secret made up of passcode, private salt and public salt
     */
    function swapERC721(
        address payable from,
        SwapERC721Info memory info,
        bytes calldata secret
    )
        external payable
    {
        bytes32 id = keccak256(
            abi.encode(
                from,
                msg.sender,
                info.token0,
                info.value0,
                info.tokenData0,
                info.fees0,
                info.token1,
                info.value1,
                info.tokenData1,
                info.fees1,
                info.secretHash
            )
        );
        uint256 tr = s_swaps[id];
        require(tr > 0, "SafeSwap: request not exist");
        require(uint64(tr) > now, "SafeSwap: expired");
        require(uint64(tr >> 64) <= now, "SafeSwap: not available yet");
        require(keccak256(secret) == info.secretHash, "SafeSwap: wrong secret");
        delete s_swaps[id];
        s_fees = s_fees.add(info.fees0).add(info.fees1);
        if (info.token0 == address(0)) {
            //ether to 721
            msg.sender.transfer(info.value0);
        } else {
            IERC721(info.token0).safeTransferFrom(
                from,
                msg.sender,
                info.value0,
                info.tokenData0
            );
        }
        if (info.token1 == address(0)) {
            //721 to ether
            require(
                msg.value == info.value1.add(info.fees1),
                "SafeSwap: value mismatch"
            );
            from.transfer(info.value1);
        } else {
            require(msg.value == info.fees1, "SafeSwap: value mismatch");
            IERC721(info.token1).safeTransferFrom(
                msg.sender,
                from,
                info.value1,
                info.tokenData1
            );
        }
        emit ERC721Swapped(
            from,
            msg.sender,
            info.token0,
            info.value0,
            info.token1,
            info.value1,
            id
        );
    }

    /** @notice retrieveERC721 - gives the functionallity of the undo for swaps containing ERC721 tokens
                after the sender sends the deposit he can undo it (for what ever reason)
                until the recipient didnt approved the swap (swap function below)
        @param  to: address of the recipient
        @param  info: a struct (SwapRetrieveERC721) defimed above containing the following params:
                    to: address of the recipient
                    token0: the address of the token he is sending to the recipient
                    value0: in case of Ether  - the amount being sent to the recipient side in the selected token in token0
                            in case of token721 - it's the tokenId of the token721
                    tokenData0: data on the token Id (only in token721)
                    fees0: the amount of fees the he needs to pay for the swap
                    token1: the address of the token he is recieving from the recipient
                    value1: in case of Ether  - the amount being sent to the recipient side in the selected token in token1
                            in case of token721 - it's the tokenId of the token721
                    tokenData1: data on the token Id (only in token721)
                    fees1: the amount of fees the recipient needs to pay for the swap
                    secretHash: a hash of the secret
     */
    function retrieveERC721(address to, SwapERC721Info memory info) external {
        bytes32 id = keccak256(
            abi.encode(
                msg.sender,
                to,
                info.token0,
                info.value0,
                info.tokenData0,
                info.fees0,
                info.token1,
                info.value1,
                info.tokenData1,
                info.fees1,
                info.secretHash
            )
        );
        require(s_swaps[id] > 0, "SafeSwap: request not exist");
        delete s_swaps[id];
        uint256 valueToSend;
        if (info.token0 == address(0)) {
            valueToSend = info.value0.add(info.fees0);
        } else {
            valueToSend = info.fees0;
        }
        msg.sender.transfer(valueToSend);
        if (info.token0 == address(0)) {
            emit Retrieved(msg.sender, to, id, valueToSend);
        } else {
            emit ERC721Retrieved(info.token0, msg.sender, to, id, info.value0);
        }
    }

    /** @notice autoRetrieveERC721 - gives the functionallity of the undo for swaps containing ERC721 tokens with addittion of automation.
                after the sender sends the deposit he can undo it (for what ever reason)
                until the recipient didnt approved the swap (swap function below)
        @param  from: address of the recipient
        @param  to: address of the recipient
        @param  info: a struct (SwapRetrieveERC721) defimed above containing the following params:
                    to: address of the recipient
                    token0: the address of the token he is sending to the recipient
                    value0: in case of Ether  - the amount being sent to the recipient side in the selected token in token0
                            in case of token721 - it's the tokenId of the token721
                    tokenData0: data on the token Id (only in token721)
                    fees0: the amount of fees the he needs to pay for the swap
                    token1: the address of the token he is recieving from the recipient
                    value1: in case of Ether  - the amount being sent to the recipient side in the selected token in token1
                            in case of token721 - it's the tokenId of the token721
                    tokenData1: data on the token Id (only in token721)
                    fees1: the amount of fees the recipient needs to pay for the swap
                    secretHash: a hash of the secret
     */
    function autoRetrieveERC721(address payable from, address to, SwapERC721Info memory info)
        external
        onlyActivator()
    {
        bytes32 id = keccak256(
            abi.encode(
                from,
                to,
                info.token0,
                info.value0,
                info.tokenData0,
                info.fees0,
                info.token1,
                info.value1,
                info.tokenData1,
                info.fees1,
                info.secretHash
            )
        );
        uint256 tr = s_swaps[id];
        require(tr > 0, "SafeSwap: request not exist");
        require(uint64(tr) <= now, "SafeSwap: not expired");
        delete s_swaps[id];
        s_fees = s_fees + (tr >> 128); // autoRetreive fees
        uint256 valueToRetrieve;
        if (info.token0 == address(0)) {
            valueToRetrieve = info.value0.add(info.fees0).sub(tr >> 128);
        } else {
            valueToRetrieve = info.fees0.sub(tr >> 128);
        }
        from.transfer(valueToRetrieve);
        if (info.token0 == address(0)) {
            emit Retrieved(from, to, id, valueToRetrieve);
        } else {
            emit ERC721Retrieved(info.token0, from, to, id, info.value0);
        }
    }

    /** @notice timedDepositERC721 - handles deposits for ERC721 tokens with an addition that has a timer in seconds
        @param  to: address of the recipient
        @param  info: a struct (SwapRetrieveERC721) defimed above containing the following params:
                    to: address of the recipient
                    token0: the address of the token he is sending to the recipient
                    value0: in case of Ether  - the amount being sent to the recipient side in the selected token in token0
                            in case of token721 - it's the tokenId of the token721
                    tokenData0: data on the token Id (only in token721)
                    fees0: the amount of fees the he needs to pay for the swap
                    token1: the address of the token he is recieving from the recipient
                    value1: in case of Ether  - the amount being sent to the recipient side in the selected token in token1
                            in case of token721 - it's the tokenId of the token721
                    tokenData1: data on the token Id (only in token721)
                    fees1: the amount of fees the recipient needs to pay for the swap
                    secretHash: a hash of the secret
        @param availableAt: sets a start time in seconds for when the deposite can happen
        @param expiresAt: sets an end time in seconds for when the deposite can happen
        @param autoRetrieveFees: the amount of fees that will be collected from the sender in case of retrieve
     */
    function timedDepositERC721(
        address to,
        SwapERC721Info memory info,
        uint64 availableAt,
        uint64 expiresAt,
        uint128 autoRetrieveFees
    )
        external payable
    {
        if (info.token0 == address(0)) {
            //eth to 721
            require(
                info.token0 != info.token1,
                "SafeSwap: try to swap ether and ether"
            );
            require(
                msg.value == info.value0.add(info.fees0),
                "SafeSwap: value mismatch"
            );
            require(info.value1 > 0, "SafeSwap: no token id");
        } else if (info.token1 == address(0)) {
            //721 to eth
            require(msg.value == info.fees0, "SafeSwap: value mismatch");
            require(info.value0 > 0, "SafeSwap: no token id");
        } else {
            //721 to 721
            require(msg.value == info.fees0, "SafeSwap: value mismatch");
            require(info.value0 > 0, "SafeSwap: no token id");
            require(info.value1 > 0, "SafeSwap: no token id");
        }
        require(
            info.fees0 >= autoRetrieveFees,
            "SafeSwap: autoRetrieveFees exeed fees"
        );
        require(to != msg.sender, "SafeSwap: sender==recipient");
        require(expiresAt > now, "SafeSwap: already expired");
        bytes32 id = keccak256(
            abi.encode(
                msg.sender,
                to,
                info.token0,
                info.value0,
                info.tokenData0,
                info.fees0,
                info.token1,
                info.value1,
                info.tokenData1,
                info.fees1,
                info.secretHash
            )
        );
        require(s_swaps[id] == 0, "SafeSwap: request exist");
        s_swaps[id] =
            uint256(expiresAt) +
            (uint256(availableAt) << 64) +
            (uint256(autoRetrieveFees) << 128);
        emit ERC721TimedDeposited(
            msg.sender,
            to,
            info.token0,
            info.value0,
            info.fees0,
            info.token1,
            info.value1,
            info.fees1,
            info.secretHash,
            availableAt,
            expiresAt,
            autoRetrieveFees
        );
    }

    // ----------------------- Hidden ETH / ERC-20 / ERC-721 -----------------------

    /** @notice hiddenRetrieve - an abillity to retrive (undo) without exposing the info of the sender
        @param  id1: a hash of the info being hided (sender address, token exc...)
        @param  value: the amount being sent to the recipient side in the selected token
     */
    function hiddenRetrieve(bytes32 id1, uint256 value) external {
        bytes32 id = keccak256(abi.encode(msg.sender, value, id1));
        require(s_hswaps[id] > 0, "SafeSwap: request not exist");
        delete s_hswaps[id];
        msg.sender.transfer(value);
        emit HRetrieved(msg.sender, id1, value);
    }

    /** @notice hiddenAutoRetrieve - an abillity to retrive (undo) without exposing the info of the sender
                with the addition of the automation abillity
        @param  from: the address of the sender
        @param  id1: a hash of the info being hided
        @param  value: the amount being sent to the recipient side in the selected token
     */
    function hiddenAutoRetrieve(
        address payable from,
        bytes32 id1,
        uint256 value
    )
        external
        onlyActivator()
    {
        bytes32 id = keccak256(abi.encode(from, value, id1));
        uint256 tr = s_hswaps[id];
        require(tr > 0, "SafeSwap: request not exist");
        require(uint64(tr) <= now, "SafeSwap: not expired");
        delete s_hswaps[id];
        s_fees = s_fees + (tr >> 128);
        uint256 toRetrieve = value.sub(tr >> 128);
        from.transfer(toRetrieve);
        emit HRetrieved(from, id1, toRetrieve);
    }

    /** @notice hiddenDeposit - an ability to deposit without exposing the trx details
        @param  id1: a hash of the info being hided (sender address, token exc...)
     */
    function hiddenDeposit(bytes32 id1) external payable {
        bytes32 id = keccak256(abi.encode(msg.sender, msg.value, id1));
        require(s_hswaps[id] == 0, "SafeSwap: request exist");
        s_hswaps[id] = 0xffffffffffffffff;
        emit HDeposited(msg.sender, msg.value, id1);
    }

    /** @notice hiddenTimedDeposit - an ability to deposit without exposing the trx details
                with an addition that has a timer in seconds
        @param  id1: a hash of the info being hided (sender address, token exc...)
        @param availableAt: sets a start time in seconds for when the deposite can happen
        @param expiresAt: sets an end time in seconds for when the deposite can happen
        @param autoRetrieveFees: the amount of fees that will be collected from the sender in case of retrieve
     */
    function hiddenTimedDeposit(
        bytes32 id1,
        uint64 availableAt,
        uint64 expiresAt,
        uint128 autoRetrieveFees
    )
        external payable
    {
        require(
            msg.value >= autoRetrieveFees,
            "SafeSwap: autoRetrieveFees exeed value"
        );
        bytes32 id = keccak256(abi.encode(msg.sender, msg.value, id1));
        require(s_hswaps[id] == 0, "SafeSwap: request exist");
        require(expiresAt > now, "SafeSwap: already expired");
        s_hswaps[id] =
            uint256(expiresAt) +
            (uint256(availableAt) << 64) +
            (uint256(autoRetrieveFees) << 128);
        emit HTimedDeposited(
            msg.sender,
            msg.value,
            id1,
            availableAt,
            expiresAt,
            autoRetrieveFees
        );
    }

    /** @notice hiddenSwap - an ability to swap without exposing the trx details
        @param  from: address of the recipient
        @param  info: a struct (SwapRetrieveERC721) defimed above containing the following params:
                    to: address of the recipient
                    token0: the address of the token he is sending to the recipient
                    value0: in case of Ether  - the amount being sent to the recipient side in the selected token in token0
                            in case of token721 - it's the tokenId of the token721
                    tokenData0: data on the token Id (only in token721)
                    fees0: the amount of fees the he needs to pay for the swap
                    token1: the address of the token he is recieving from the recipient
                    value1: in case of Ether  - the amount being sent to the recipient side in the selected token in token1
                            in case of token721 - it's the tokenId of the token721
                    tokenData1: data on the token Id (only in token721)
                    fees1: the amount of fees the recipient needs to pay for the swap
                    secretHash: a hash of the secret
        @param  secret: secret made up of passcode, private salt and public salt
     */
    function hiddenSwap(
        address payable from,
        SwapInfo memory info,
        bytes calldata secret
    )
        external payable
    {
        bytes32 id1 = keccak256(
            abi.encode(
                HIDDEN_SWAP_TYPEHASH,
                from,
                msg.sender,
                info.token0,
                info.value0,
                info.fees0,
                info.token1,
                info.value1,
                info.fees1,
                info.secretHash
            )
        );
        bytes32 id = keccak256(
            abi.encode(from, info.token0 == address(0) ? info.value0.add(info.fees0): info.fees0, id1)
        );
        uint256 tr = s_hswaps[id];
        require(tr > 0, "SafeSwap: request not exist");
        require(uint64(tr) > now, "SafeSwap: expired");
        require(uint64(tr >> 64) <= now, "SafeSwap: not available yet");
        require(keccak256(secret) == info.secretHash, "SafeSwap: wrong secret");
        delete s_hswaps[id];
        s_fees = s_fees.add(info.fees0).add(info.fees1);
        if (info.token0 == address(0)) {
            msg.sender.transfer(info.value0);
        } else {
            IERC20(info.token0).safeTransferFrom(from, msg.sender, info.value0);
        }
        if (info.token1 == address(0)) {
            require(
                msg.value == info.value1.add(info.fees1),
                "SafeSwap: value mismatch"
            );
            from.transfer(info.value1);
        } else {
            require(msg.value == info.fees1, "SafeSwap: value mismatch");
            IERC20(info.token1).safeTransferFrom(msg.sender, from, info.value1);
        }
        emit HSwapped(
            from,
            msg.sender,
            id1,
            info.token0,
            info.value0,
            info.token1,
            info.value1
        );
    }

    /** @notice hiddenSwapERC721 - an ability to swap without exposing the trx details for ERC721 tokens
        @param  from: address of the recipient
        @param  info: a struct (SwapRetrieveERC721) defimed above containing the following params:
                    to: address of the recipient
                    token0: the address of the token he is sending to the recipient
                    value0: in case of Ether  - the amount being sent to the recipient side in the selected token in token0
                            in case of token721 - it's the tokenId of the token721
                    tokenData0: data on the token Id (only in token721)
                    fees0: the amount of fees the he needs to pay for the swap
                    token1: the address of the token he is recieving from the recipient
                    value1: in case of Ether  - the amount being sent to the recipient side in the selected token in token1
                            in case of token721 - it's the tokenId of the token721
                    tokenData1: data on the token Id (only in token721)
                    fees1: the amount of fees the recipient needs to pay for the swap
                    secretHash: a hash of the secret
        @param  secret: secret made up of passcode, private salt and public salt
     */
    function hiddenSwapERC721(
        address payable from,
        SwapERC721Info memory info,
        bytes calldata secret

    )
        external payable
    {
        bytes32 id1 = _calcHiddenERC712Id1(from, info);
        bytes32 id = keccak256(
            abi.encode(from, info.token0 == address(0) ? info.value0.add(info.fees0): info.fees0, id1)
        );
        uint256 tr = s_hswaps[id];
        require(tr > 0, "SafeSwap: request not exist");
        require(uint64(tr) > now, "SafeSwap: expired");
        require(uint64(tr >> 64) <= now, "SafeSwap: not available yet");
        require(keccak256(secret) == info.secretHash, "SafeSwap: wrong secret");
        delete s_hswaps[id];
        s_fees = s_fees.add(info.fees0).add(info.fees1);
        if (info.token0 == address(0)) {
            //ether to 721
            msg.sender.transfer(info.value0);
        } else {
            IERC721(info.token0).safeTransferFrom(
                from,
                msg.sender,
                info.value0,
                info.tokenData0
            );
        }
        if (info.token1 == address(0)) {
            //721 to ether
            require(
                msg.value == info.value1.add(info.fees1),
                "SafeSwap: value mismatch"
            );
            from.transfer(info.value1);
        } else {
            require(msg.value == info.fees1, "SafeSwap: value mismatch");
            IERC721(info.token1).safeTransferFrom(
                msg.sender,
                from,
                info.value1,
                info.tokenData1
            );
        }
        emit HERC721Swapped(
            from,
            msg.sender,
            id1,
            info.token0,
            info.value0,
            info.token1,
            info.value1
        );
    }

    /** @notice _calcHiddenERC712Id1 - private view function that calculates the id of the hidden ERC721 token swap
        @param  from: address of the recipient
        @param  info: a struct (SwapRetrieveERC721) defimed above containing the following params:
    */
    function _calcHiddenERC712Id1(address from, SwapERC721Info memory info)
        private
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    HIDDEN_ERC721_SWAP_TYPEHASH,
                    from,
                    msg.sender,
                    info.token0,
                    info.value0,
                    info.tokenData0,
                    info.fees0,
                    info.token1,
                    info.value1,
                    info.tokenData1,
                    info.fees1,
                    info.secretHash
                )
            );
    }
}