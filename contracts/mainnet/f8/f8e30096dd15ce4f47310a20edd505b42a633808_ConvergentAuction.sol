// File: openzeppelin-solidity/contracts/utils/EnumerableSet.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// File: openzeppelin-solidity/contracts/utils/Address.sol


pragma solidity ^0.6.2;

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

// File: openzeppelin-solidity/contracts/GSN/Context.sol


pragma solidity ^0.6.0;

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

// File: openzeppelin-solidity/contracts/access/AccessControl.sol


pragma solidity ^0.6.0;




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

// File: openzeppelin-solidity/contracts/math/SafeMath.sol


pragma solidity ^0.6.0;

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

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol


pragma solidity ^0.6.0;

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

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol


pragma solidity ^0.6.0;




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

// File: contracts/ConvergentAuction.sol


pragma solidity ^0.6.12;





interface SupportsWhitelisting {
  function addToWhiteList(address account) external;
}

contract ConvergentAuction is AccessControl, SupportsWhitelisting {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bytes32 private constant WHITELIST = keccak256("WHITELIST"); // whitelist role
    bytes32 private constant WHITELIST_ADMIN = keccak256("WHITELIST_ADMIN"); // whitelist admin role

    uint256 private constant price_external_multiplier = 100; // price we recieve is multiplied by 100, which allows 2 decimals
    uint256 private constant price_internal_multiplier = 1;
    uint256 private constant price_divisor = 100; 

    uint256 private constant at_unit = 1_000_000; // unit of auctioned token, 6 decimals
    uint256 private constant pt_unit = 1_000_000; // unit of payment token, 6 decimals

    uint private constant dayish = 86400; 
    
    uint256 public min_price; // Minimal price
    uint256 private max_price; // Maximal price
    uint256 private constant min_amount = 10 * at_unit;
    uint256 private constant tokens_for_sale = 211_500 * at_unit;

    // each point allows increase by 0.1% of the original_price
    uint[5] daily_increase_points = [
        900,
        700,
        500,
        300,
        100
    ];

    address private _owner;
    uint public _start_time;
    bool private _threshold_finalized = false;
    uint private _distributed_count = 0;
    IERC20 public auctioned_token;
    IERC20 public payment_token;
    uint256 public threshold_price;
    uint256 public threshold_ratio; // execution ration for bids exactly at threshold_price, should be divided by 1000

    struct Bid {
        address bid_address;
        uint64 amount;
        uint16 original_price;
        uint16 price;
        uint32 last_update;
        uint8 day_of_auction;
        uint16 points_used;
        bool distributed;
    }
    
    Bid[] private _bids;    
    mapping (address => uint) private bid_indices; // index in _bids array plus one

    modifier whenAuctionGoing() {
        require(isInSubmissionPhase() || isInBiddingPhase(), "auction is not going");
        _;
    }

    modifier whenAuctionEnded() {
        require(auctionEnded(), "auction is still on going");
        _;
    }

    modifier isThresholdFinalized() {
        require(_threshold_finalized == true, "auction threshold was not finalized yet");
        _;
    }

    event WhitelistAdded(address indexed account);
    event ThresholdSet(uint256 price, uint256 ratio);
    event BidCreated(address indexed account, uint256 amount, uint256 price);
    event BidUpdated(address indexed account, uint256 amount, uint256 price);

    // compute amount of payment tokens corresponding to purchase of amount of auctioned tokens at price
    // we assume that price was multiplied by price_external_multiplier by the front-end
    function compute_payment(uint256 amount, uint256 price) internal pure returns (uint256) {
       return amount.mul(price).mul(price_internal_multiplier).div(price_divisor);
    }

    constructor(address owner, address wl_admin, uint _min_price, uint start_time, IERC20 a_token, IERC20 p_token) public {
        // make sure that unit scaling is consistent
        // for 1 unit of auctioned token and price of 1 (which is scaled by price_external_multiplier) we should get 1 unit of payment unit
        require(compute_payment(at_unit, price_external_multiplier) == pt_unit, "units not consistent");
        require(start_time >= block.timestamp, "start time should be in the future time");

        min_price = _min_price;
        max_price = _min_price.mul(100);
        
        _owner = owner;
        _setupRole(DEFAULT_ADMIN_ROLE, owner); // owner can change wl admin list via grantRole/revokeRole
        _setRoleAdmin(WHITELIST, WHITELIST_ADMIN); // accounts with WHITELIST_ADMIN role will be able to add accounts to WHITELIST role
        _setupRole(WHITELIST_ADMIN, wl_admin); // start with one whitelist admin
        _start_time = start_time;
        auctioned_token = a_token;
        payment_token = p_token;
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

    function isInSubmissionPhase() public view returns (bool) {
        return (block.timestamp >= _start_time && block.timestamp <= _start_time + (2 * dayish));
    }

    function isInBiddingPhase() public view returns (bool) {
        return (block.timestamp > _start_time + (2 * dayish) && block.timestamp <= _start_time + (7 * dayish));
    }

    function auctionEnded() public view returns (bool) {
        return block.timestamp > _start_time + (7 * dayish);
    }

    /**
     * @dev admin can add a specific address to white list address
     */
    function addToWhiteList(address account) external override {
        // caller must have WHITELIST_ADMIN role
        grantRole(WHITELIST, account);
        emit WhitelistAdded(account);
    }
    
    function create_bid(uint64 amount, uint16 price) external whenAuctionGoing {
        address _sender = _msgSender();
        // verify that auction token was already fully deposited into the smart contract
        if (_bids.length == 0) {
            require(auctioned_token.balanceOf(address(this)) >= tokens_for_sale, 'auction token was not deposited enough');
        }
        // only white list address can join the auction
        require(hasRole(WHITELIST, _sender), "AccessControl: only white list address can join the auction");
        // check bidding submission is still allowed
        require(isInSubmissionPhase(), "submission time is over");
        // check parameter sanity
        require(bid_indices[_sender] == 0, "bidder already exists");
        require(price >= min_price && price <= max_price, "bidding price is out of range");
        require(amount >= min_amount, "too small amount");

        Bid storage bid = _bids.push();
        bid.bid_address = _sender;
        bid.amount = amount;
        bid.original_price = price;
        bid.price = price;
        bid.last_update = uint32(block.timestamp);
        // the rest of fields are zero-initialized
        bid_indices[_sender] = _bids.length; // note: starting from 1
        payment_token.safeTransferFrom(_sender, address(this), compute_payment(amount, price));
        emit BidCreated(_sender, amount, price);
    }

    // this function is called only from the client 
    function max_price_increase_allowed(address bidder) external view returns (uint256) {
        require(bid_indices[bidder] > 0, "bid does not exist");
        Bid storage bid = _bids[bid_indices[bidder] - 1];
        if (isInBiddingPhase()) {
            uint8 day_of_auction = uint8((block.timestamp - _start_time) / dayish);
            uint points_used = 0;
            uint this_day_increase_points = daily_increase_points[day_of_auction-2];
            
            if (bid.day_of_auction == day_of_auction) {
              points_used = bid.points_used;
            }

            if (points_used >= this_day_increase_points) {
              return bid.price;
            }
            uint points_usable = this_day_increase_points - points_used - 1; // we remove 1 point to compensate for different rounding

            uint calc_max_price = ((points_usable.mul(bid.original_price)).div(1000)).add(bid.price);
            
            if (calc_max_price <= max_price)
              return calc_max_price;
            else
              return max_price;
        } else {
          return max_price;
        }

    }
    
    function update_bid(uint64 amount, uint16 price) external whenAuctionGoing {
        address _sender = _msgSender();
        require(bid_indices[_sender] > 0, "bid does not exist");
        Bid storage bid = _bids[bid_indices[_sender] - 1];
        // updating bid can't be more often than once an hour
        require(block.timestamp - bid.last_update >= (dayish/24), "updating bid can't be more often than once an hour");
        bid.last_update = uint32(block.timestamp);
        // sanity check
        require(price <= max_price, "bidding price is out of range");
        require(price >= bid.price, "new price must be greater or equal to current price");
        require(amount >= min_amount, "too small amount");
        
        uint256 old_collateral = compute_payment(bid.amount, bid.price);
        uint256 new_collateral = compute_payment(amount, price);
        require(new_collateral >= old_collateral, "collateral cannot be decreased");

        // restrict update amount & price after 2 days of the submission phase
        if (isInBiddingPhase()) {
            require(price > bid.price, "new price must be greater than current price");
            require(amount <= bid.amount, "new amount must be less than or equal to current amount");
            uint8 day_of_auction = uint8((block.timestamp - _start_time) / dayish);
            if (bid.day_of_auction < day_of_auction) { // reset points_used on new day 
                bid.day_of_auction = day_of_auction;
                bid.points_used = 0;
            }

            // how many increase points are needed for this price increase?
            uint points_needed =  uint(price - bid.price).mul(1000).div( bid.original_price );
            uint points_this_day = daily_increase_points[day_of_auction-2];
            
            require(  points_needed.add( bid.points_used ) <=  points_this_day,
                      "price is over maximum daily price increment allowance");
            bid.points_used = uint16(bid.points_used + points_needed); // overflow is impossible
        } else if (isInSubmissionPhase()) {
            // update original_price also
            bid.original_price = price;
        }

        // first two days have no restriction on price increase
        bid.amount = amount;
        bid.price = price;

        if (new_collateral > old_collateral) {
            payment_token.safeTransferFrom(_sender, address(this), new_collateral.sub(old_collateral));
        }
        emit BidUpdated(_sender, amount, price);
    }

    /**
     * @dev get bid detail of the specific address
     */
    function getBid(address addr) external view returns (address, uint256, uint256, uint256, uint, uint, uint, bool) {
        Bid memory bid = _bids[bid_indices[addr] - 1];
        return (bid.bid_address, 
                bid.amount, 
                bid.original_price, 
                bid.price, 
                bid.last_update, 
                bid.day_of_auction,
                bid.points_used, 
                bid.distributed);
    }

    /**
     * @dev return array of bids (bid_address, amount, price) joining in the auction to calculate threshold price and threshold ratio off-chain
     */
    function getBids(uint from, uint count) external view returns (address[] memory, uint256[] memory, uint256[] memory)
    {
        uint length = from + count;
        require(from >= 0 && from < _bids.length && count > 0 && length <= _bids.length, "index out of range");
        address[] memory addresses = new address[](count);
        uint256[] memory amounts = new uint256[](count);
        uint256[] memory prices = new uint256[](count);
        uint j = 0;
        for (uint i = from; i < length; i++) {
            Bid storage bid = _bids[i];
            addresses[j] = bid.bid_address;
            amounts[j] = bid.amount;
            prices[j] = bid.price;
            j++;
        }
        return (addresses, amounts, prices);
    }
    
    function getBidsExtra(uint from, uint count) external view
      returns (uint[] memory original_price, uint[] memory last_update, uint[] memory day_of_auction,
               uint[] memory points_used, bool[] memory distributed)
    {
        uint length = from + count;
        original_price = new uint[](count);
        last_update = new uint[](count);
        day_of_auction = new uint[](count);
        points_used = new uint[](count);
        distributed = new bool[](count);
        
        require(from >= 0 && from < _bids.length && count > 0 && length <= _bids.length, "index out of range");
        uint j = 0;
        for (uint i = from; i < length; i++) {
            Bid storage bid = _bids[i];
            original_price[j] = bid.original_price;
            last_update[j] = bid.last_update;
            day_of_auction[j] = bid.day_of_auction;
            points_used[j] = bid.points_used;
            distributed[j] = bid.distributed;
            j++;
        }
    }

    /**
     * @dev return the total number of bids
     */
    function getBidCount() external view returns (uint) {
        return _bids.length;
    }

    /**
     * @dev contract owner can set temporarily current threshold price and ratio.
     * Do not allow to reset threshold price and ratio when the auction already ended.
     */
    function setThreshold(uint256 price, uint256 ratio) external onlyOwner whenAuctionEnded {
        require(_threshold_finalized == false, "threshold already finalized");
        require(price >= min_price && price <= max_price, 'threshold price is out of range');
        require(ratio >= 0 && ratio <= 1000, 'threshold ratio is out of range');
        require(_distributed_count == 0); // if we started "distributing" before setThreshold via returnCollateral, the auction is considered failed, and cannot be finalized.
        threshold_price = price;
        threshold_ratio = ratio;
        _threshold_finalized = true;
        emit ThresholdSet(price, ratio);
    }

    function distributeTokens(address addr) public isThresholdFinalized {
        require(bid_indices[addr] > 0);
        Bid storage bid = _bids[bid_indices[addr] - 1];
        require(bid.distributed == false);
        bid.distributed = true;
        _distributed_count++;
        if (bid.price >= threshold_price) {
            uint256 b_amount = bid.amount;
            if (bid.price == threshold_price && threshold_ratio != 1000) {
                // reduce bought amount using ratio
                b_amount = b_amount.mul(threshold_ratio).div(1000);
            }
            
            uint256 unused_collateral = compute_payment(bid.amount, bid.price).sub(compute_payment(b_amount, threshold_price));
            if (unused_collateral > 0) {
                payment_token.safeTransfer(addr, unused_collateral);
            }
            auctioned_token.safeTransfer(addr, b_amount);
        } else {
            // bid haven't won, just return the collateral
            payment_token.safeTransfer(addr, compute_payment(bid.amount, bid.price));
        }
    }

    function distributeTokensMulti(uint from, uint count) external isThresholdFinalized {
        for (uint i = from; i < from + count; i++) {
            Bid storage bid = _bids[i];
            
            address addr = bid.bid_address;
            if (addr != address(0x0) && !bid.distributed)
              distributeTokens(addr);
       }
    }

    function returnCollateral(address addr) external whenAuctionEnded {
        require(block.timestamp > _start_time + (10 * dayish), "funds are still locked for auction");
        require(_threshold_finalized == false, "auction threshold was already set to proceed");
        require(bid_indices[addr] > 0);
        Bid storage bid = _bids[bid_indices[addr] - 1];
        require(bid.distributed == false);
        bid.distributed = true;
        _distributed_count++;
        payment_token.safeTransfer(addr, compute_payment(bid.amount, bid.price));
    }

    /**
     * @dev owner should be able to withdraw proceedings
     */
    function withdraw(address addr) external onlyOwner whenAuctionEnded {
        require(_distributed_count >= _bids.length, "still not fully distribute token for the bidders");
        payment_token.safeTransfer(addr, payment_token.balanceOf(address(this)));
        auctioned_token.safeTransfer(addr, auctioned_token.balanceOf(address(this)));
    }
}