// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;


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

interface IERC20 {
    
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function transfer(address to, uint value) external returns (bool);

    function approve(address spender, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);
}

contract LnAdmin {
    address public admin;
    address public candidate;

    constructor(address _admin) public {
        require(_admin != address(0), "admin address cannot be 0");
        admin = _admin;
        emit AdminChanged(address(0), _admin);
    }

    function setCandidate(address _candidate) external onlyAdmin {
        address old = candidate;
        candidate = _candidate;
        emit candidateChanged( old, candidate);
    }

    function becomeAdmin( ) external {
        require( msg.sender == candidate, "Only candidate can become admin");
        address old = admin;
        admin = candidate;
        emit AdminChanged( old, admin ); 
    }

    modifier onlyAdmin {
        require( (msg.sender == admin), "Only the contract admin can perform this action");
        _;
    }

    event candidateChanged(address oldCandidate, address newCandidate );
    event AdminChanged(address oldAdmin, address newAdmin);
}


library SafeDecimalMath {
    using SafeMath for uint;

    uint8 public constant decimals = 18;
    uint8 public constant highPrecisionDecimals = 27;

    uint public constant UNIT = 10**uint(decimals);

    uint public constant PRECISE_UNIT = 10**uint(highPrecisionDecimals);
    uint private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR = 10**uint(highPrecisionDecimals - decimals);

    function unit() external pure returns (uint) {
        return UNIT;
    }

    function preciseUnit() external pure returns (uint) {
        return PRECISE_UNIT;
    }

    function multiplyDecimal(uint x, uint y) internal pure returns (uint) {
        
        return x.mul(y) / UNIT;
    }

    function _multiplyDecimalRound(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        
        uint quotientTimesTen = x.mul(y) / (precisionUnit / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    function multiplyDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
        return _multiplyDecimalRound(x, y, PRECISE_UNIT);
    }

    function multiplyDecimalRound(uint x, uint y) internal pure returns (uint) {
        return _multiplyDecimalRound(x, y, UNIT);
    }

    function divideDecimal(uint x, uint y) internal pure returns (uint) {
        
        return x.mul(UNIT).div(y);
    }

    function _divideDecimalRound(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        uint resultTimesTen = x.mul(precisionUnit * 10).div(y);

        if (resultTimesTen % 10 >= 5) {
            resultTimesTen += 10;
        }

        return resultTimesTen / 10;
    }

    function divideDecimalRound(uint x, uint y) internal pure returns (uint) {
        return _divideDecimalRound(x, y, UNIT);
    }

    function divideDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
        return _divideDecimalRound(x, y, PRECISE_UNIT);
    }

    function decimalToPreciseDecimal(uint i) internal pure returns (uint) {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

    function preciseDecimalToDecimal(uint i) internal pure returns (uint) {
        uint quotientTimesTen = i / (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }
}


interface ILinearStaking {
    function staking(uint256 amount) external returns (bool);
    function cancelStaking(uint256 amount) external returns (bool);
    function claim() external returns (bool);
    function stakingBalanceOf(address account) external view returns(uint256);
}

contract LnLinearStakingStorage is LnAdmin {
    using SafeMath for uint256;

    LnAccessControl public accessCtrl;

    bytes32 public constant DATA_ACCESS_ROLE = "LinearStakingStorage";

    struct StakingData {
        uint256 amount;
        uint256 staketime;
    }

    mapping (address => StakingData[]) public stakesdata;
    mapping (uint256 => uint256) public weeksTotal; // week staking amount

    uint256 public stakingStartTime = 1600329600; // TODO: UTC or UTC+8
    uint256 public stakingEndTime = 1605168000;
    uint256 public totalWeekNumber = 8;
    uint256 public weekRewardAmount = 18750000e18;

    constructor(address _admin, address _accessCtrl) public LnAdmin(_admin) {
        accessCtrl = LnAccessControl(_accessCtrl);
    }

    modifier OnlyLinearStakingStorageRole(address _address) {
        require(accessCtrl.hasRole(DATA_ACCESS_ROLE, _address), "Only Linear Staking Storage Role");
        _;
    }

    function setAccessControl(address _accessCtrl) external onlyAdmin {
        accessCtrl = LnAccessControl(_accessCtrl);
    }

    function weekTotalStaking() public view returns (uint256[] memory) {
        uint256[] memory totals = new uint256[](totalWeekNumber);
        for (uint256 i=0; i< totalWeekNumber; i++) {
            uint256 delta = weeksTotal[i];
            if (i == 0) {
                totals[i] = delta;
            } else {
                
                totals[i] = totals[i-1].add(delta);
            }
        }
        return totals;
    }

    function getStakesdataLength(address account) external view returns(uint256) {
        return stakesdata[account].length;
    }

    function getStakesDataByIndex(address account, uint256 index) external view returns(uint256, uint256) {
        return (stakesdata[account][index].amount, stakesdata[account][index].staketime);
    }

    function stakingBalanceOf(address account) external view returns(uint256) {
        uint256 total = 0;
        StakingData[] memory stakes = stakesdata[account];
        for (uint256 i=0; i < stakes.length; i++) {
            total = total.add(stakes[i].amount);
        }
        return total;
    }

    function requireInStakingPeriod() external view {
        require(stakingStartTime < block.timestamp, "Staking not start");
        require(block.timestamp < stakingEndTime, "Staking stage has end.");
    }

    function requireStakingEnd() external view {
        require(block.timestamp > stakingEndTime, "Need wait to staking end");
    }

    function PushStakingData(address account, uint256 amount, uint256 staketime) external OnlyLinearStakingStorageRole(msg.sender) {
        LnLinearStakingStorage.StakingData memory data = LnLinearStakingStorage.StakingData({
            amount: amount,
            staketime: staketime
        });
        stakesdata[account].push(data);
    }

    function StakingDataAdd(address account, uint256 index, uint256 amount) external OnlyLinearStakingStorageRole(msg.sender) {
        stakesdata[account][index].amount = stakesdata[account][index].amount.add(amount);
    }

    function StakingDataSub(address account, uint256 index, uint256 amount) external OnlyLinearStakingStorageRole(msg.sender) {
        stakesdata[account][index].amount = stakesdata[account][index].amount.sub(amount, "StakingDataSub sub overflow");
    }

    function DeleteStakesData(address account) external OnlyLinearStakingStorageRole(msg.sender) {
        delete stakesdata[account];
    }

    function PopStakesData(address account) external OnlyLinearStakingStorageRole(msg.sender) {
        stakesdata[account].pop();
    }

    function AddWeeksTotal(uint256 staketime, uint256 amount) external OnlyLinearStakingStorageRole(msg.sender) {
        uint256 weekNumber = staketime.sub(stakingStartTime, "AddWeeksTotal sub overflow") / 1 weeks;
        weeksTotal[weekNumber] = weeksTotal[weekNumber].add(amount);
    }

    function SubWeeksTotal(uint256 staketime, uint256 amount) external OnlyLinearStakingStorageRole(msg.sender) {
        uint256 weekNumber = staketime.sub(stakingStartTime, "SubWeeksTotal weekNumber sub overflow") / 1 weeks;
        weeksTotal[weekNumber] = weeksTotal[weekNumber].sub(amount, "SubWeeksTotal weeksTotal sub overflow");
    }

    function setWeekRewardAmount(uint256 _weekRewardAmount) external onlyAdmin {
        weekRewardAmount = _weekRewardAmount;
    }

    function setStakingPeriod(uint _stakingStartTime, uint _stakingEndTime) external onlyAdmin {
        require(_stakingEndTime > _stakingStartTime);

        stakingStartTime = _stakingStartTime;
        stakingEndTime = _stakingEndTime;

        totalWeekNumber = stakingEndTime.sub(stakingStartTime, "setStakingPeriod totalWeekNumber sub overflow") / 1 weeks;
        if (stakingEndTime.sub(stakingStartTime, "setStakingPeriod stakingEndTime sub overflow") % 1 weeks != 0) {
            totalWeekNumber = totalWeekNumber.add(1);
        }
    }
}

contract LnLinearStaking is LnAdmin, Pausable, ILinearStaking {
    using SafeMath for uint256;

    IERC20 public linaToken; // lina token proxy address
    LnLinearStakingStorage public stakingStorage;
    
    constructor(
        address _admin,
        address _linaToken,
        address _storage
    ) public LnAdmin(_admin) {
        linaToken = IERC20(_linaToken);
        stakingStorage = LnLinearStakingStorage(_storage);
    }

    function setLinaToken(address _linaToken) external onlyAdmin {
        linaToken = IERC20(_linaToken);
    }

    function setPaused(bool _paused) external onlyAdmin {
        if (_paused) {
            _pause();
        } else {
            _unpause();
        }
    }

    //////////////////////////////////////////////////////
    event Staking(address indexed who, uint256 value, uint staketime);
    event CancelStaking(address indexed who, uint256 value);
    event Claim(address indexed who, uint256 rewardval, uint256 totalStaking);

    uint256 public accountStakingListLimit = 50;
    uint256 public minStakingAmount = 1e18; // 1 token
    uint256 public constant PRECISION_UINT = 1e23;

    function setLinaTokenAddress(address _token) external onlyAdmin {
        linaToken = IERC20(_token);
    }

    function setStakingListLimit(uint256 _limit) external onlyAdmin {
        accountStakingListLimit = _limit;
    }

    function setMinStakingAmount(uint256 _minStakingAmount) external onlyAdmin {
        minStakingAmount = _minStakingAmount;
    }

    function stakingBalanceOf(address account) external override view returns(uint256) {
        return stakingStorage.stakingBalanceOf(account);
    }

    function getStakesdataLength(address account) external view returns(uint256) {
        return stakingStorage.getStakesdataLength(account);
    }
    //--------------------------------------------------------

    function staking(uint256 amount) public whenNotPaused override returns (bool) {
        stakingStorage.requireInStakingPeriod();

        require(amount >= minStakingAmount, "Staking amount too small.");
        require(stakingStorage.getStakesdataLength(msg.sender) < accountStakingListLimit, "Staking list out of limit.");

        //linaToken.burn(msg.sender, amount);
        linaToken.transferFrom(msg.sender, address(this), amount);
     
        stakingStorage.PushStakingData(msg.sender, amount, block.timestamp);
        stakingStorage.AddWeeksTotal(block.timestamp, amount);

        emit Staking(msg.sender, amount, block.timestamp);
        return true;
    }

    function cancelStaking(uint256 amount) public whenNotPaused override returns (bool) {
        stakingStorage.requireInStakingPeriod();

        require(amount > 0, "Invalid amount.");

        uint256 returnToken = amount;
        for (uint256 i = stakingStorage.getStakesdataLength(msg.sender); i >= 1 ; i--) {
            (uint256 stakingAmount, uint256 staketime) = stakingStorage.getStakesDataByIndex(msg.sender, i-1);
            if (amount >= stakingAmount) {
                amount = amount.sub(stakingAmount, "cancelStaking sub overflow");
                
                stakingStorage.PopStakesData(msg.sender);
                stakingStorage.SubWeeksTotal(staketime, stakingAmount);
            } else {
                stakingStorage.StakingDataSub(msg.sender, i-1, amount);
                stakingStorage.SubWeeksTotal(staketime, amount);

                amount = 0;
            }
            if (amount == 0) break;
        }
        require(amount == 0, "Cancel amount too big then staked.");

        //linaToken.mint(msg.sender, returnToken);
        linaToken.transfer(msg.sender, returnToken);

        emit CancelStaking(msg.sender, returnToken);

        return true;
    }

    // claim reward
    // Note: 需要提前提前把奖励token转进来
    function claim() public whenNotPaused override returns (bool) {
        stakingStorage.requireStakingEnd();

        require(stakingStorage.getStakesdataLength(msg.sender) > 0, "Nothing to claim");

        uint256 totalWeekNumber = stakingStorage.totalWeekNumber();

        uint256 totalStaking = 0;
        uint256 totalReward = 0;

        uint256[] memory finalTotals = stakingStorage.weekTotalStaking();
        for (uint256 i=0; i < stakingStorage.getStakesdataLength(msg.sender); i++) {
            (uint256 stakingAmount, uint256 staketime) = stakingStorage.getStakesDataByIndex(msg.sender, i);
            uint256 stakedWeedNumber = staketime.sub(stakingStorage.stakingStartTime(), "claim sub overflow") / 1 weeks;

            totalStaking = totalStaking.add(stakingAmount);
            
            uint256 reward = 0;
            for (uint256 j=stakedWeedNumber; j < totalWeekNumber; j++) {
                reward = reward.add( stakingAmount.mul(PRECISION_UINT).div(finalTotals[j]) ); //move .mul(weekRewardAmount) to next line.
            }
            reward = reward.mul(stakingStorage.weekRewardAmount()).div(PRECISION_UINT);

            totalReward = totalReward.add( reward );
        }

        stakingStorage.DeleteStakesData(msg.sender);
        
        //linaToken.mint(msg.sender, totalStaking.add(totalReward) );
        linaToken.transfer(msg.sender, totalStaking.add(totalReward) );

        emit Claim(msg.sender, totalReward, totalStaking);
        return true;
    }
}


// example:
//LnAccessControl accessCtrl = LnAccessControl(addressStorage.getAddress("LnAccessControl"));
//require(accessCtrl.hasRole(accessCtrl.DEBT_SYSTEM(), _address), "Need debt system access role");

// contract access control
contract LnAccessControl is AccessControl {
    using Address for address;

    // -------------------------------------------------------
    // role type
    bytes32 public constant ISSUE_ASSET_ROLE = ("ISSUE_ASSET"); //keccak256
    bytes32 public constant BURN_ASSET_ROLE = ("BURN_ASSET");

    bytes32 public constant DEBT_SYSTEM = ("LnDebtSystem");
    // -------------------------------------------------------
    constructor(address admin) public {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function IsAdmin(address _address) public view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _address);
    }

    function SetAdmin(address _address) public returns (bool) {
        require(IsAdmin(msg.sender), "Only admin");

        _setupRole(DEFAULT_ADMIN_ROLE, _address);
    }

    // -------------------------------------------------------
    // this func need admin role. grantRole and revokeRole need admin role
    function SetRoles(bytes32 roleType, address[] calldata addresses, bool[] calldata setTo) external {
        require(IsAdmin(msg.sender), "Only admin");

        _setRoles(roleType, addresses, setTo);
    }

    function _setRoles(bytes32 roleType, address[] calldata addresses, bool[] calldata setTo) private {
        require(addresses.length == setTo.length, "parameter address length not eq");

        for (uint256 i=0; i < addresses.length; i++) {
            //require(addresses[i].isContract(), "Role address need contract only");
            if (setTo[i]) {
                grantRole(roleType, addresses[i]);
            } else {
                revokeRole(roleType, addresses[i]);
            }
        }
    }

    // function SetRoles(bytes32 roleType, address[] calldata addresses, bool[] calldata setTo) public {
    //     _setRoles(roleType, addresses, setTo);
    // }

    // Issue burn
    function SetIssueAssetRole(address[] calldata issuer, bool[] calldata setTo) public {
        _setRoles(ISSUE_ASSET_ROLE, issuer, setTo);
    }

    function SetBurnAssetRole(address[] calldata burner, bool[] calldata setTo) public {
        _setRoles(BURN_ASSET_ROLE, burner, setTo);
    }
    
    //
    function SetDebtSystemRole(address[] calldata _address, bool[] calldata _setTo) public {
        _setRoles(DEBT_SYSTEM, _address, _setTo);
    }
}


abstract contract LnOperatorModifier is LnAdmin {
    
    address public operator;

    constructor(address _operator) internal {
        require(admin != address(0), "admin must be set");

        operator = _operator;
        emit OperatorUpdated(_operator);
    }

    function setOperator(address _opperator) external onlyAdmin {
        operator = _opperator;
        emit OperatorUpdated(_opperator);
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "Only operator can perform this action");
        _;
    }

    event OperatorUpdated(address operator);
}


contract LnRewardCalculator {
    using SafeMath for uint256;

    struct UserInfo {
        uint256 reward;
        uint256 amount;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        uint256 amount;
        uint256 lastRewardBlock;
        uint256 accRewardPerShare;
    }

    uint256 public rewardPerBlock;

    PoolInfo public mPoolInfo;
    mapping(address => UserInfo) public userInfo;

    uint256 public startBlock;
    uint256 public remainReward;
    uint256 public accReward;

    constructor(uint256 _rewardPerBlock, uint256 _startBlock) public {
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        mPoolInfo.lastRewardBlock = startBlock;
    }

    function _calcReward(uint256 curBlock, address _user)
        internal
        view
        returns (uint256)
    {
        PoolInfo storage pool = mPoolInfo;
        UserInfo storage user = userInfo[_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 lpSupply = pool.amount;
        if (curBlock > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = curBlock.sub(
                pool.lastRewardBlock,
                "cr curBlock sub overflow"
            );
            uint256 curReward = multiplier.mul(rewardPerBlock);
            accRewardPerShare = accRewardPerShare.add(
                curReward.mul(1e20).div(lpSupply)
            );
        }
        uint256 newReward = user.amount.mul(accRewardPerShare).div(1e20).sub(
            user.rewardDebt,
            "cr newReward sub overflow"
        );
        return newReward.add(user.reward);
    }

    function rewardOf(address _user) public view returns (uint256) {
        return userInfo[_user].reward;
    }

    function amount() public view returns (uint256) {
        return mPoolInfo.amount;
    }

    function amountOf(address _user) public view returns (uint256) {
        return userInfo[_user].amount;
    }

    function getUserInfo(address _user)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (
            userInfo[_user].reward,
            userInfo[_user].amount,
            userInfo[_user].rewardDebt
        );
    }

    function getPoolInfo()
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (
            mPoolInfo.amount,
            mPoolInfo.lastRewardBlock,
            mPoolInfo.accRewardPerShare
        );
    }

    function _update(uint256 curBlock) internal {
        PoolInfo storage pool = mPoolInfo;
        if (curBlock <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.amount;
        if (lpSupply == 0) {
            pool.lastRewardBlock = curBlock;
            return;
        }
        uint256 multiplier = curBlock.sub(
            pool.lastRewardBlock,
            "_update curBlock sub overflow"
        );
        uint256 curReward = multiplier.mul(rewardPerBlock);

        remainReward = remainReward.add(curReward);
        accReward = accReward.add(curReward);

        pool.accRewardPerShare = pool.accRewardPerShare.add(
            curReward.mul(1e20).div(lpSupply)
        );
        pool.lastRewardBlock = curBlock;
    }

    function _deposit(
        uint256 curBlock,
        address _addr,
        uint256 _amount
    ) internal {
        PoolInfo storage pool = mPoolInfo;
        UserInfo storage user = userInfo[_addr];
        _update(curBlock);
        if (user.amount > 0) {
            uint256 pending = user
                .amount
                .mul(pool.accRewardPerShare)
                .div(1e20)
                .sub(user.rewardDebt, "_deposit pending sub overflow");
            if (pending > 0) {
                reward(user, pending);
            }
        }
        if (_amount > 0) {
            user.amount = user.amount.add(_amount);
            pool.amount = pool.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e20);
    }

    function _withdraw(
        uint256 curBlock,
        address _addr,
        uint256 _amount
    ) internal {
        PoolInfo storage pool = mPoolInfo;
        UserInfo storage user = userInfo[_addr];
        require(user.amount >= _amount, "_withdraw: not good");
        _update(curBlock);
        uint256 pending = user.amount.mul(pool.accRewardPerShare).div(1e20).sub(
            user.rewardDebt,
            "_withdraw pending sub overflow"
        );
        if (pending > 0) {
            reward(user, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(
                _amount,
                "_withdraw user.amount sub overflow"
            );
            pool.amount = pool.amount.sub(
                _amount,
                "_withdraw pool.amount sub overflow"
            );
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e20);
    }

    function reward(UserInfo storage user, uint256 _amount) internal {
        if (_amount > remainReward) {
            _amount = remainReward;
        }
        remainReward = remainReward.sub(
            _amount,
            "reward remainReward sub overflow"
        );
        user.reward = user.reward.add(_amount);
    }

    function _claim(address _addr) internal {
        UserInfo storage user = userInfo[_addr];
        if (user.reward > 0) {
            user.reward = 0;
        }
    }
}

contract LnRewardCalculatorTest is LnRewardCalculator {
    constructor(uint256 _rewardPerBlock, uint256 _startBlock)
        public
        LnRewardCalculator(_rewardPerBlock, _startBlock)
    {}

    function deposit(
        uint256 curBlock,
        address _addr,
        uint256 _amount
    ) public {
        _deposit(curBlock, _addr, _amount);
    }

    function withdraw(
        uint256 curBlock,
        address _addr,
        uint256 _amount
    ) public {
        _withdraw(curBlock, _addr, _amount);
    }

    function calcReward(uint256 curBlock, address _user)
        public
        view
        returns (uint256)
    {
        return _calcReward(curBlock, _user);
    }
}

contract LnSimpleStaking is
    LnAdmin,
    Pausable,
    ILinearStaking,
    LnRewardCalculator
{
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;

    IERC20 public linaToken; // lina token proxy address
    LnLinearStakingStorage public stakingStorage;
    uint256 public mEndBlock;
    address public mOldStaking;
    uint256 public mOldAmount;
    uint256 public mWidthdrawRewardFromOldStaking;

    uint256 public claimRewardLockTime = 1620806400; // 2021-5-12

    address public mTargetAddress;
    uint256 public mTransLockTime;

    mapping(address => uint256) public mOldReward;

    constructor(
        address _admin,
        address _linaToken,
        address _storage,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _endBlock
    ) public LnAdmin(_admin) LnRewardCalculator(_rewardPerBlock, _startBlock) {
        linaToken = IERC20(_linaToken);
        stakingStorage = LnLinearStakingStorage(_storage);
        mEndBlock = _endBlock;
    }

    function setLinaToken(address _linaToken) external onlyAdmin {
        linaToken = IERC20(_linaToken);
    }

    function setPaused(bool _paused) external onlyAdmin {
        if (_paused) {
            _pause();
        } else {
            _unpause();
        }
    }

    //////////////////////////////////////////////////////
    event Staking(address indexed who, uint256 value, uint256 staketime);
    event CancelStaking(address indexed who, uint256 value);
    event Claim(address indexed who, uint256 rewardval, uint256 totalStaking);
    event TransLock(address target, uint256 time);

    uint256 public accountStakingListLimit = 50;
    uint256 public minStakingAmount = 1e18; // 1 token
    uint256 public constant PRECISION_UINT = 1e23;

    function setStakingListLimit(uint256 _limit) external onlyAdmin {
        accountStakingListLimit = _limit;
    }

    function setMinStakingAmount(uint256 _minStakingAmount) external onlyAdmin {
        minStakingAmount = _minStakingAmount;
    }

    function stakingBalanceOf(address account)
        external
        override
        view
        returns (uint256)
    {
        uint256 stakingBalance = super.amountOf(account).add(
            stakingStorage.stakingBalanceOf(account)
        );
        return stakingBalance;
    }

    function getStakesdataLength(address account)
        external
        view
        returns (uint256)
    {
        return stakingStorage.getStakesdataLength(account);
    }

    //--------------------------------------------------------

    function migrationsOldStaking(
        address contractAddr,
        uint256 amount,
        uint256 blockNb
    ) public onlyAdmin {
        super._deposit(blockNb, contractAddr, amount);
        mOldStaking = contractAddr;
        mOldAmount = amount;
    }

    function staking(uint256 amount)
        public
        override
        whenNotPaused
        returns (bool)
    {
        stakingStorage.requireInStakingPeriod();

        require(amount >= minStakingAmount, "Staking amount too small.");
        //require(stakingStorage.getStakesdataLength(msg.sender) < accountStakingListLimit, "Staking list out of limit.");

        linaToken.transferFrom(msg.sender, address(this), amount);

        uint256 blockNb = block.number;
        if (blockNb > mEndBlock) {
            blockNb = mEndBlock;
        }
        super._deposit(blockNb, msg.sender, amount);

        emit Staking(msg.sender, amount, block.timestamp);

        return true;
    }

    function _widthdrawFromOldStaking(address _addr, uint256 amount) internal {
        uint256 blockNb = block.number;
        if (blockNb > mEndBlock) {
            blockNb = mEndBlock;
        }

        uint256 oldStakingAmount = super.amountOf(mOldStaking);
        super._withdraw(blockNb, mOldStaking, amount);
        // sub already withraw reward, then cal portion
        uint256 reward = super
            .rewardOf(mOldStaking)
            .sub(
            mWidthdrawRewardFromOldStaking,
            "_widthdrawFromOldStaking reward sub overflow"
        )
            .mul(amount)
            .mul(1e20)
            .div(oldStakingAmount)
            .div(1e20);
        mWidthdrawRewardFromOldStaking = mWidthdrawRewardFromOldStaking.add(
            reward
        );
        mOldReward[_addr] = mOldReward[_addr].add(reward);
    }

    function _cancelStaking(address user, uint256 amount) internal {
        uint256 blockNb = block.number;
        if (blockNb > mEndBlock) {
            blockNb = mEndBlock;
        }

        uint256 returnAmount = amount;
        uint256 newAmount = super.amountOf(user);
        if (newAmount >= amount) {
            super._withdraw(blockNb, user, amount);
            amount = 0;
        } else {
            if (newAmount > 0) {
                super._withdraw(blockNb, user, newAmount);
                amount = amount.sub(
                    newAmount,
                    "_cancelStaking amount sub overflow"
                );
            }

            for (
                uint256 i = stakingStorage.getStakesdataLength(user);
                i >= 1;
                i--
            ) {
                (uint256 stakingAmount, uint256 staketime) = stakingStorage
                    .getStakesDataByIndex(user, i - 1);
                if (amount >= stakingAmount) {
                    amount = amount.sub(
                        stakingAmount,
                        "_cancelStaking amount sub overflow"
                    );

                    stakingStorage.PopStakesData(user);
                    stakingStorage.SubWeeksTotal(staketime, stakingAmount);
                    _widthdrawFromOldStaking(user, stakingAmount);
                } else {
                    stakingStorage.StakingDataSub(user, i - 1, amount);
                    stakingStorage.SubWeeksTotal(staketime, amount);
                    _widthdrawFromOldStaking(user, amount);

                    amount = 0;
                }
                if (amount == 0) break;
            }
        }

        // cancel as many as possible, not fail, that waste gas
        //require(amount == 0, "Cancel amount too big then staked.");

        linaToken.transfer(msg.sender, returnAmount.sub(amount));
    }

    function cancelStaking(uint256 amount)
        public
        override
        whenNotPaused
        returns (bool)
    {
        //stakingStorage.requireInStakingPeriod();

        require(amount > 0, "Invalid amount.");

        _cancelStaking(msg.sender, amount);

        emit CancelStaking(msg.sender, amount);

        return true;
    }

    function getTotalReward(uint256 blockNb, address _user)
        public
        view
        returns (uint256 total)
    {
        if (blockNb > mEndBlock) {
            blockNb = mEndBlock;
        }

        // 这里奖励分成了三部分
        // 1,已经从旧奖池中cancel了的
        // 2,还在旧奖池中的
        // 3，在新奖池中的
        total = mOldReward[_user];
        uint256 iMyOldStaking = 0;
        for (
            uint256 i = 0;
            i < stakingStorage.getStakesdataLength(_user);
            i++
        ) {
            (uint256 stakingAmount, ) = stakingStorage.getStakesDataByIndex(
                _user,
                i
            );
            iMyOldStaking = iMyOldStaking.add(stakingAmount);
        }
        if (iMyOldStaking > 0) {
            uint256 oldStakingAmount = super.amountOf(mOldStaking);
            uint256 iReward2 = super
                ._calcReward(blockNb, mOldStaking)
                .sub(
                mWidthdrawRewardFromOldStaking,
                "getTotalReward iReward2 sub overflow"
            )
                .mul(iMyOldStaking)
                .div(oldStakingAmount);
            total = total.add(iReward2);
        }

        uint256 reward3 = super._calcReward(blockNb, _user);
        total = total.add(reward3);
    }

    // claim reward
    // Note: 需要提前提前把奖励token转进来
    function claim() public override whenNotPaused returns (bool) {
        //stakingStorage.requireStakingEnd();
        require(
            block.timestamp > claimRewardLockTime,
            "Not time to claim reward"
        );

        uint256 iMyOldStaking = stakingStorage.stakingBalanceOf(msg.sender);
        uint256 iAmount = super.amountOf(msg.sender);
        _cancelStaking(msg.sender, iMyOldStaking.add(iAmount));

        uint256 iReward = getTotalReward(mEndBlock, msg.sender);

        _claim(msg.sender);
        mOldReward[msg.sender] = 0;
        linaToken.transfer(msg.sender, iReward);

        emit Claim(msg.sender, iReward, iMyOldStaking.add(iAmount));
        return true;
    }

    function setRewardLockTime(uint256 newtime) public onlyAdmin {
        claimRewardLockTime = newtime;
    }

    function calcReward(uint256 curBlock, address _user)
        public
        view
        returns (uint256)
    {
        return _calcReward(curBlock, _user);
    }

    function setTransLock(address target, uint256 locktime) public onlyAdmin {
        require(
            locktime >= now + 2 days,
            "locktime need larger than cur time 2 days"
        );
        mTargetAddress = target;
        mTransLockTime = locktime;

        emit TransLock(mTargetAddress, mTransLockTime);
    }

    function transTokens(uint256 amount) public onlyAdmin {
        require(mTransLockTime > 0, "mTransLockTime not set");
        require(now > mTransLockTime, "Pls wait to unlock time");
        linaToken.transfer(mTargetAddress, amount);
    }
}

contract HelperPushStakingData is LnAdmin {
    constructor(address _admin) public LnAdmin(_admin) {}

    function pushStakingData(
        address _storage,
        address[] calldata account,
        uint256[] calldata amount,
        uint256[] calldata staketime
    ) external {
        require(account.length > 0, "array length zero");
        require(account.length == amount.length, "array length not eq");
        require(account.length == staketime.length, "array length not eq");

        LnLinearStakingStorage stakingStorage = LnLinearStakingStorage(
            _storage
        );
        for (uint256 i = 0; i < account.length; i++) {
            stakingStorage.PushStakingData(account[i], amount[i], staketime[i]);
            stakingStorage.AddWeeksTotal(staketime[i], amount[i]);
        }
    }

    //unstaking.
}

contract MultiSigForTransferFunds {
    mapping(address => uint256) public mAdmins;
    uint256 public mConfirmNumb;
    uint256 public mProposalNumb;
    uint256 public mAmount;
    LnSimpleStaking public mStaking;
    address[] public mAdminArr;
    uint256 public mTransLockTime;

    constructor(
        address[] memory _addr,
        uint256 iConfirmNumb,
        LnSimpleStaking _staking
    ) public {
        for (uint256 i = 0; i < _addr.length; ++i) {
            mAdmins[_addr[i]] = 1;
        }
        mConfirmNumb = iConfirmNumb;
        mProposalNumb = 0;
        mStaking = _staking;
        mAdminArr = _addr;
    }

    function becomeAdmin(address target) external {
        LnAdmin(target).becomeAdmin();
    }

    function setTransLock(
        address target,
        uint256 locktime,
        uint256 amount
    ) public {
        require(mAdmins[msg.sender] == 1, "not in admin list or set state");
        _reset();
        mStaking.setTransLock(target, locktime);
        mAmount = amount;
        mProposalNumb = 1;
        mAdmins[msg.sender] = 2; //

        mTransLockTime = locktime;
    }

    // call this when the locktime expired
    function confirmTransfer() public {
        require(mAdmins[msg.sender] == 1, "not in admin list or set state");
        mProposalNumb = mProposalNumb + 1;
        mAdmins[msg.sender] = 2;
    }

    function doTransfer() public {
        require(mTransLockTime > 0, "mTransLockTime not set");
        require(now > mTransLockTime, "Pls wait to unlock time");
        require(mProposalNumb >= mConfirmNumb, "need more confirm");

        _reset();
        mStaking.transTokens(mAmount);
    }

    function _reset() internal {
        mProposalNumb = 0;
        mTransLockTime = 0;
        // reset
        for (uint256 i = 0; i < mAdminArr.length; ++i) {
            mAdmins[mAdminArr[i]] = 1;
        }
    }
}

contract LnSimpleStakingExtension is
    LnAdmin,
    Pausable,
    ILinearStaking,
    LnRewardCalculator
{
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;

    IERC20 public linaToken; // lina token proxy address
    LnLinearStakingStorage public stakingStorage;
    uint256 public mEndBlock;
    address public mOldStaking;
    uint256 public mOldAmount;
    uint256 public mWidthdrawRewardFromOldStaking;

    uint256 public claimRewardLockTime = 1620806400; // 2021-5-12

    address public mTargetAddress;
    uint256 public mTransLockTime;

    LnSimpleStaking public mOldSimpleStaking;
    bool public requireSync = false;

    mapping(address => uint256) public mOldReward;
    mapping(address => bool) public syncUserInfo;

    constructor(
        address _admin,
        address _linaToken,
        address _storage,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _endBlock,
        address _mOldSimpleStaking
    ) public LnAdmin(_admin) LnRewardCalculator(_rewardPerBlock, _startBlock) {
        linaToken = IERC20(_linaToken);
        stakingStorage = LnLinearStakingStorage(_storage);
        mEndBlock = _endBlock;
        if (_mOldSimpleStaking != address(0)) {
            mOldSimpleStaking = LnSimpleStaking(_mOldSimpleStaking);
            (
                mPoolInfo.amount,
                ,
                mPoolInfo.accRewardPerShare
            ) = mOldSimpleStaking.getPoolInfo();
            requireSync = true;
        }
    }

    function setLinaToken(address _linaToken) external onlyAdmin {
        linaToken = IERC20(_linaToken);
    }

    function setPaused(bool _paused) external onlyAdmin {
        if (_paused) {
            _pause();
        } else {
            _unpause();
        }
    }

    //////////////////////////////////////////////////////
    event Staking(address indexed who, uint256 value, uint256 staketime);
    event CancelStaking(address indexed who, uint256 value);
    event Claim(address indexed who, uint256 rewardval, uint256 totalStaking);
    event TransLock(address target, uint256 time);

    uint256 public accountStakingListLimit = 50;
    uint256 public minStakingAmount = 1e18; // 1 token
    uint256 public constant PRECISION_UINT = 1e23;

    function setStakingListLimit(uint256 _limit) external onlyAdmin {
        accountStakingListLimit = _limit;
    }

    function setMinStakingAmount(uint256 _minStakingAmount) external onlyAdmin {
        minStakingAmount = _minStakingAmount;
    }

    function stakingBalanceOf(address account)
        external
        override
        view
        returns (uint256)
    {
        uint256 stakingBalance = super.amountOf(account).add(
            stakingStorage.stakingBalanceOf(account)
        );
        
        if (!syncUserInfo[msg.sender]) {
            uint256 oldAmoutOf = mOldSimpleStaking.amountOf(account);
            stakingBalance = stakingBalance.add(oldAmoutOf);
        }

        
        return stakingBalance;
    }

    function getStakesdataLength(address account)
        external
        view
        returns (uint256)
    {
        return stakingStorage.getStakesdataLength(account);
    }

    function setEndBlock(uint256 _newEndBlock) external onlyAdmin {
        require(
            _newEndBlock > mEndBlock,
            "new endBlock less than old endBlock."
        );
        mEndBlock = _newEndBlock;
    }

    function syncUserInfoData(address _user) internal {
        if (requireSync && !syncUserInfo[_user]) {
            (
                userInfo[_user].reward,
                userInfo[_user].amount,
                userInfo[_user].rewardDebt
            ) = mOldSimpleStaking.getUserInfo(_user);
            syncUserInfo[_user] = true;
        }
    }

    //--------------------------------------------------------

    function migrationsOldStaking(
        address contractAddr,
        uint256 amount,
        uint256 blockNb
    ) public onlyAdmin {
        super._deposit(blockNb, contractAddr, amount);
        mOldStaking = contractAddr;
        mOldAmount = amount;
    }

    function staking(uint256 amount)
        public
        override
        whenNotPaused
        returns (bool)
    {
        // stakingStorage.requireInStakingPeriod();
        // require(
        //     syncUserInfo[msg.sender],
        //     "sync is required before perform action."
        // );

        if (!syncUserInfo[msg.sender]) {
            syncUserInfoData(msg.sender);
        }

        require(amount >= minStakingAmount, "Staking amount too small.");
        //require(stakingStorage.getStakesdataLength(msg.sender) < accountStakingListLimit, "Staking list out of limit.");

        linaToken.transferFrom(msg.sender, address(this), amount);

        uint256 blockNb = block.number;
        if (blockNb > mEndBlock) {
            blockNb = mEndBlock;
        }
        super._deposit(blockNb, msg.sender, amount);

        emit Staking(msg.sender, amount, block.timestamp);

        return true;
    }

    function _widthdrawFromOldStaking(address _addr, uint256 amount) internal {
        uint256 blockNb = block.number;
        if (blockNb > mEndBlock) {
            blockNb = mEndBlock;
        }

        uint256 oldStakingAmount = super.amountOf(mOldStaking);
        super._withdraw(blockNb, mOldStaking, amount);
        // sub already withraw reward, then cal portion
        uint256 reward = super
            .rewardOf(mOldStaking)
            .sub(
            mWidthdrawRewardFromOldStaking,
            "_widthdrawFromOldStaking reward sub overflow"
        )
            .mul(amount)
            .mul(1e20)
            .div(oldStakingAmount)
            .div(1e20);
        mWidthdrawRewardFromOldStaking = mWidthdrawRewardFromOldStaking.add(
            reward
        );
        mOldReward[_addr] = mOldReward[_addr].add(reward);
    }

    function _cancelStaking(address user, uint256 amount) internal {
        uint256 blockNb = block.number;
        if (blockNb > mEndBlock) {
            blockNb = mEndBlock;
        }

        uint256 returnAmount = amount;
        uint256 newAmount = super.amountOf(user);
        if (newAmount >= amount) {
            super._withdraw(blockNb, user, amount);
            amount = 0;
        } else {
            if (newAmount > 0) {
                super._withdraw(blockNb, user, newAmount);
                amount = amount.sub(
                    newAmount,
                    "_cancelStaking amount sub overflow"
                );
            }

            for (
                uint256 i = stakingStorage.getStakesdataLength(user);
                i >= 1;
                i--
            ) {
                (uint256 stakingAmount, uint256 staketime) = stakingStorage
                    .getStakesDataByIndex(user, i - 1);
                if (amount >= stakingAmount) {
                    amount = amount.sub(
                        stakingAmount,
                        "_cancelStaking amount sub overflow"
                    );

                    stakingStorage.PopStakesData(user);
                    stakingStorage.SubWeeksTotal(staketime, stakingAmount);
                    _widthdrawFromOldStaking(user, stakingAmount);
                } else {
                    stakingStorage.StakingDataSub(user, i - 1, amount);
                    stakingStorage.SubWeeksTotal(staketime, amount);
                    _widthdrawFromOldStaking(user, amount);

                    amount = 0;
                }
                if (amount == 0) break;
            }
        }

        // cancel as many as possible, not fail, that waste gas
        //require(amount == 0, "Cancel amount too big then staked.");

        linaToken.transfer(msg.sender, returnAmount.sub(amount));
    }

    function cancelStaking(uint256 amount)
        public
        override
        whenNotPaused
        returns (bool)
    {
        // require(
        //     syncUserInfo[msg.sender],
        //     "sync is required before perform action."
        // );

        if (!syncUserInfo[msg.sender]) {
            syncUserInfoData(msg.sender);
        }

        //stakingStorage.requireInStakingPeriod();
        require(amount > 0, "Invalid amount.");

        _cancelStaking(msg.sender, amount);

        emit CancelStaking(msg.sender, amount);

        return true;
    }

    function getTotalReward(uint256 blockNb, address _user)
        public
        view
        returns (uint256 total)
    {
        if (!syncUserInfo[msg.sender]) {
            total = _getTotalRewardNotSync(blockNb, _user);
        } else {
            total = _getTotalReward(blockNb, _user);
        }
    }

    function _getTotalReward(uint256 blockNb, address _user)
        internal 
        view
        returns (uint256 total)
    {
        if (blockNb > mEndBlock) {
            blockNb = mEndBlock;
        }

        // 这里奖励分成了三部分
        // 1,已经从旧奖池中cancel了的
        // 2,还在旧奖池中的
        // 3，在新奖池中的
        total = mOldReward[_user];
        uint256 iMyOldStaking = 0;
        for (
            uint256 i = 0;
            i < stakingStorage.getStakesdataLength(_user);
            i++
        ) {
            (uint256 stakingAmount, ) = stakingStorage.getStakesDataByIndex(
                _user,
                i
            );
            iMyOldStaking = iMyOldStaking.add(stakingAmount);
        }
        if (iMyOldStaking > 0) {
            uint256 oldStakingAmount = super.amountOf(mOldStaking);
            uint256 iReward2 = super
                ._calcReward(blockNb, mOldStaking)
                .sub(
                mWidthdrawRewardFromOldStaking,
                "getTotalReward iReward2 sub overflow"
            )
                .mul(iMyOldStaking)
                .div(oldStakingAmount);
            total = total.add(iReward2);
        }

        uint256 reward3 = super._calcReward(blockNb, _user);
        total = total.add(reward3);
    }


    function _getTotalRewardNotSync(uint256 blockNb, address _user)
        internal 
        view
        returns (uint256 total)
    {
        if (blockNb > mEndBlock) {
            blockNb = mEndBlock;
        }

        // rely on the old simplestaking contract
        uint256 oldTotalReward = 0;
        oldTotalReward = mOldSimpleStaking.getTotalReward(blockNb, _user);
        total = total.add(oldTotalReward);

        uint256 reward3 = super._calcReward(blockNb, _user);
        total = total.add(reward3);
    }

    // claim reward
    // Note: 需要提前提前把奖励token转进来
    function claim() public override whenNotPaused returns (bool) {
        //stakingStorage.requireStakingEnd()
        // require(
        //     syncUserInfo[msg.sender],
        //     "sync is required before perform action."
        // );

        if (!syncUserInfo[msg.sender]) {
            syncUserInfoData(msg.sender);
        }

        require(
            block.timestamp > claimRewardLockTime,
            "Not time to claim reward"
        );

        uint256 iMyOldStaking = stakingStorage.stakingBalanceOf(msg.sender);
        uint256 iAmount = super.amountOf(msg.sender);
        _cancelStaking(msg.sender, iMyOldStaking.add(iAmount));

        uint256 iReward = getTotalReward(mEndBlock, msg.sender);

        _claim(msg.sender);
        mOldReward[msg.sender] = 0;
        linaToken.transfer(msg.sender, iReward);

        emit Claim(msg.sender, iReward, iMyOldStaking.add(iAmount));
        return true;
    }

    function setRewardLockTime(uint256 newtime) public onlyAdmin {
        claimRewardLockTime = newtime;
    }

    function calcReward(uint256 curBlock, address _user)
        public
        view
        returns (uint256)
    {
        return _calcRewardWithViewSimpleAmount(curBlock, _user);
    }

    // This is copied particularly for catering the amount when user not sync
    function _calcRewardWithViewSimpleAmount(uint256 curBlock, address _user)
        internal
        view
        returns (uint256)
    {
        PoolInfo storage pool = mPoolInfo;
        UserInfo storage user = userInfo[_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 lpSupply = pool.amount;
        if (curBlock > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = curBlock.sub(
                pool.lastRewardBlock,
                "cr curBlock sub overflow"
            );
            uint256 curReward = multiplier.mul(rewardPerBlock);
            accRewardPerShare = accRewardPerShare.add(
                curReward.mul(1e20).div(lpSupply)
            );
        }

        // Only logic added for old simpleStaking
        uint256 ssReward;
        uint256 ssAmount;
        uint256 ssRewardDebt;
        (ssReward, ssAmount, ssRewardDebt) = mOldSimpleStaking.getUserInfo(
            _user
        );
        ssAmount = ssAmount.add(user.amount);
        ssRewardDebt = ssRewardDebt.add(user.rewardDebt);
        ssReward = ssReward.add(user.reward);

        // uint256 newReward = user.amount.mul(accRewardPerShare).div(1e20).sub(
        uint256 newReward = ssAmount.mul(accRewardPerShare).div(1e20).sub(
            ssRewardDebt,
            "cr newReward sub overflow"
        );
        return newReward.add(ssReward);
    }

    function setTransLock(address target, uint256 locktime) public onlyAdmin {
        require(
            locktime >= now + 2 days,
            "locktime need larger than cur time 2 days"
        );
        mTargetAddress = target;
        mTransLockTime = locktime;

        emit TransLock(mTargetAddress, mTransLockTime);
    }

    function transTokens(uint256 amount) public onlyAdmin {
        require(mTransLockTime > 0, "mTransLockTime not set");
        require(now > mTransLockTime, "Pls wait to unlock time");
        linaToken.transfer(mTargetAddress, amount);
    }
}