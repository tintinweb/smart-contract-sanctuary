/**
 *Submitted for verification at Etherscan.io on 2021-02-08
*/

// File: @openzeppelin/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

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

// File: @openzeppelin/contracts/utils/EnumerableSet.sol



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

// File: @openzeppelin/contracts/utils/Address.sol



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

// File: @openzeppelin/contracts/GSN/Context.sol



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

// File: @openzeppelin/contracts/access/AccessControl.sol



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

// File: solidity/contracts/utility/interfaces/IOwned.sol


pragma solidity 0.6.12;

/*
    Owned contract interface
*/
interface IOwned {
    // this function isn't since the compiler emits automatically generated getter functions as external
    function owner() external view returns (address);

    function transferOwnership(address _newOwner) external;

    function acceptOwnership() external;
}

// File: solidity/contracts/converter/interfaces/IConverterAnchor.sol


pragma solidity 0.6.12;


/*
    Converter Anchor interface
*/
interface IConverterAnchor is IOwned {

}

// File: solidity/contracts/token/interfaces/IERC20Token.sol


pragma solidity 0.6.12;

/*
    ERC20 Standard Token interface
*/
interface IERC20Token {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256);

    function allowance(address _owner, address _spender) external view returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool);

    function approve(address _spender, uint256 _value) external returns (bool);
}

// File: solidity/contracts/liquidity-protection/interfaces/ILiquidityProtectionEventsSubscriber.sol


pragma solidity 0.6.12;



/**
 * @dev Liquidity protection events subscriber interface
 */
interface ILiquidityProtectionEventsSubscriber {
    function onAddingLiquidity(
        address provider,
        IConverterAnchor poolAnchor,
        IERC20Token reserveToken,
        uint256 poolAmount,
        uint256 reserveAmount
    ) external;

    function onRemovingLiquidity(
        uint256 id,
        address provider,
        IConverterAnchor poolAnchor,
        IERC20Token reserveToken,
        uint256 poolAmount,
        uint256 reserveAmount
    ) external;
}

// File: solidity/contracts/liquidity-protection/interfaces/ILiquidityProtectionSettings.sol


pragma solidity 0.6.12;




/*
    Liquidity Protection Store Settings interface
*/
interface ILiquidityProtectionSettings {
    function isPoolWhitelisted(IConverterAnchor poolAnchor) external view returns (bool);

    function poolWhitelist() external view returns (address[] memory);

    function subscribers() external view returns (address[] memory);

    function isPoolSupported(IConverterAnchor poolAnchor) external view returns (bool);

    function minNetworkTokenLiquidityForMinting() external view returns (uint256);

    function defaultNetworkTokenMintingLimit() external view returns (uint256);

    function networkTokenMintingLimits(IConverterAnchor poolAnchor) external view returns (uint256);

    function addLiquidityDisabled(IConverterAnchor poolAnchor, IERC20Token reserveToken) external view returns (bool);

    function minProtectionDelay() external view returns (uint256);

    function maxProtectionDelay() external view returns (uint256);

    function minNetworkCompensation() external view returns (uint256);

    function lockDuration() external view returns (uint256);

    function averageRateMaxDeviation() external view returns (uint32);
}

// File: solidity/contracts/converter/interfaces/IConverter.sol


pragma solidity 0.6.12;




/*
    Converter interface
*/
interface IConverter is IOwned {
    function converterType() external pure returns (uint16);

    function anchor() external view returns (IConverterAnchor);

    function isActive() external view returns (bool);

    function targetAmountAndFee(
        IERC20Token _sourceToken,
        IERC20Token _targetToken,
        uint256 _amount
    ) external view returns (uint256, uint256);

    function convert(
        IERC20Token _sourceToken,
        IERC20Token _targetToken,
        uint256 _amount,
        address _trader,
        address payable _beneficiary
    ) external payable returns (uint256);

    function conversionFee() external view returns (uint32);

    function maxConversionFee() external view returns (uint32);

    function reserveBalance(IERC20Token _reserveToken) external view returns (uint256);

    receive() external payable;

    function transferAnchorOwnership(address _newOwner) external;

    function acceptAnchorOwnership() external;

    function setConversionFee(uint32 _conversionFee) external;

    function withdrawTokens(
        IERC20Token _token,
        address _to,
        uint256 _amount
    ) external;

    function withdrawETH(address payable _to) external;

    function addReserve(IERC20Token _token, uint32 _ratio) external;

    // deprecated, backward compatibility
    function token() external view returns (IConverterAnchor);

    function transferTokenOwnership(address _newOwner) external;

    function acceptTokenOwnership() external;

    function connectors(IERC20Token _address)
        external
        view
        returns (
            uint256,
            uint32,
            bool,
            bool,
            bool
        );

    function getConnectorBalance(IERC20Token _connectorToken) external view returns (uint256);

    function connectorTokens(uint256 _index) external view returns (IERC20Token);

    function connectorTokenCount() external view returns (uint16);

    /**
     * @dev triggered when the converter is activated
     *
     * @param _type        converter type
     * @param _anchor      converter anchor
     * @param _activated   true if the converter was activated, false if it was deactivated
     */
    event Activation(uint16 indexed _type, IConverterAnchor indexed _anchor, bool indexed _activated);

    /**
     * @dev triggered when a conversion between two tokens occurs
     *
     * @param _fromToken       source ERC20 token
     * @param _toToken         target ERC20 token
     * @param _trader          wallet that initiated the trade
     * @param _amount          input amount in units of the source token
     * @param _return          output amount minus conversion fee in units of the target token
     * @param _conversionFee   conversion fee in units of the target token
     */
    event Conversion(
        IERC20Token indexed _fromToken,
        IERC20Token indexed _toToken,
        address indexed _trader,
        uint256 _amount,
        uint256 _return,
        int256 _conversionFee
    );

    /**
     * @dev triggered when the rate between two tokens in the converter changes
     * note that the event might be dispatched for rate updates between any two tokens in the converter
     *
     * @param  _token1 address of the first token
     * @param  _token2 address of the second token
     * @param  _rateN  rate of 1 unit of `_token1` in `_token2` (numerator)
     * @param  _rateD  rate of 1 unit of `_token1` in `_token2` (denominator)
     */
    event TokenRateUpdate(IERC20Token indexed _token1, IERC20Token indexed _token2, uint256 _rateN, uint256 _rateD);

    /**
     * @dev triggered when the conversion fee is updated
     *
     * @param  _prevFee    previous fee percentage, represented in ppm
     * @param  _newFee     new fee percentage, represented in ppm
     */
    event ConversionFeeUpdate(uint32 _prevFee, uint32 _newFee);
}

// File: solidity/contracts/converter/interfaces/IConverterRegistry.sol


pragma solidity 0.6.12;



interface IConverterRegistry {
    function getAnchorCount() external view returns (uint256);

    function getAnchors() external view returns (address[] memory);

    function getAnchor(uint256 _index) external view returns (IConverterAnchor);

    function isAnchor(address _value) external view returns (bool);

    function getLiquidityPoolCount() external view returns (uint256);

    function getLiquidityPools() external view returns (address[] memory);

    function getLiquidityPool(uint256 _index) external view returns (IConverterAnchor);

    function isLiquidityPool(address _value) external view returns (bool);

    function getConvertibleTokenCount() external view returns (uint256);

    function getConvertibleTokens() external view returns (address[] memory);

    function getConvertibleToken(uint256 _index) external view returns (IERC20Token);

    function isConvertibleToken(address _value) external view returns (bool);

    function getConvertibleTokenAnchorCount(IERC20Token _convertibleToken) external view returns (uint256);

    function getConvertibleTokenAnchors(IERC20Token _convertibleToken) external view returns (address[] memory);

    function getConvertibleTokenAnchor(IERC20Token _convertibleToken, uint256 _index)
        external
        view
        returns (IConverterAnchor);

    function isConvertibleTokenAnchor(IERC20Token _convertibleToken, address _value) external view returns (bool);
}

// File: solidity/contracts/utility/Owned.sol


pragma solidity 0.6.12;


/**
 * @dev This contract provides support and utilities for contract ownership.
 */
contract Owned is IOwned {
    address public override owner;
    address public newOwner;

    /**
     * @dev triggered when the owner is updated
     *
     * @param _prevOwner previous owner
     * @param _newOwner  new owner
     */
    event OwnerUpdate(address indexed _prevOwner, address indexed _newOwner);

    /**
     * @dev initializes a new Owned instance
     */
    constructor() public {
        owner = msg.sender;
    }

    // allows execution by the owner only
    modifier ownerOnly {
        _ownerOnly();
        _;
    }

    // error message binary size optimization
    function _ownerOnly() internal view {
        require(msg.sender == owner, "ERR_ACCESS_DENIED");
    }

    /**
     * @dev allows transferring the contract ownership
     * the new owner still needs to accept the transfer
     * can only be called by the contract owner
     *
     * @param _newOwner    new contract owner
     */
    function transferOwnership(address _newOwner) public override ownerOnly {
        require(_newOwner != owner, "ERR_SAME_OWNER");
        newOwner = _newOwner;
    }

    /**
     * @dev used by a new owner to accept an ownership transfer
     */
    function acceptOwnership() public override {
        require(msg.sender == newOwner, "ERR_ACCESS_DENIED");
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

// File: solidity/contracts/utility/Utils.sol


pragma solidity 0.6.12;

/**
 * @dev Utilities & Common Modifiers
 */
contract Utils {
    // verifies that a value is greater than zero
    modifier greaterThanZero(uint256 _value) {
        _greaterThanZero(_value);
        _;
    }

    // error message binary size optimization
    function _greaterThanZero(uint256 _value) internal pure {
        require(_value > 0, "ERR_ZERO_VALUE");
    }

    // validates an address - currently only checks that it isn't null
    modifier validAddress(address _address) {
        _validAddress(_address);
        _;
    }

    // error message binary size optimization
    function _validAddress(address _address) internal pure {
        require(_address != address(0), "ERR_INVALID_ADDRESS");
    }

    // verifies that the address is different than this contract address
    modifier notThis(address _address) {
        _notThis(_address);
        _;
    }

    // error message binary size optimization
    function _notThis(address _address) internal view {
        require(_address != address(this), "ERR_ADDRESS_IS_SELF");
    }

    // validates an external address - currently only checks that it isn't null or this
    modifier validExternalAddress(address _address) {
        _validExternalAddress(_address);
        _;
    }

    // error message binary size optimization
    function _validExternalAddress(address _address) internal view {
        require(_address != address(0) && _address != address(this), "ERR_INVALID_EXTERNAL_ADDRESS");
    }
}

// File: solidity/contracts/utility/interfaces/IContractRegistry.sol


pragma solidity 0.6.12;

/*
    Contract Registry interface
*/
interface IContractRegistry {
    function addressOf(bytes32 _contractName) external view returns (address);
}

// File: solidity/contracts/utility/ContractRegistryClient.sol


pragma solidity 0.6.12;




/**
 * @dev This is the base contract for ContractRegistry clients.
 */
contract ContractRegistryClient is Owned, Utils {
    bytes32 internal constant CONTRACT_REGISTRY = "ContractRegistry";
    bytes32 internal constant BANCOR_NETWORK = "BancorNetwork";
    bytes32 internal constant BANCOR_FORMULA = "BancorFormula";
    bytes32 internal constant CONVERTER_FACTORY = "ConverterFactory";
    bytes32 internal constant CONVERSION_PATH_FINDER = "ConversionPathFinder";
    bytes32 internal constant CONVERTER_UPGRADER = "BancorConverterUpgrader";
    bytes32 internal constant CONVERTER_REGISTRY = "BancorConverterRegistry";
    bytes32 internal constant CONVERTER_REGISTRY_DATA = "BancorConverterRegistryData";
    bytes32 internal constant BNT_TOKEN = "BNTToken";
    bytes32 internal constant BANCOR_X = "BancorX";
    bytes32 internal constant BANCOR_X_UPGRADER = "BancorXUpgrader";
    bytes32 internal constant LIQUIDITY_PROTECTION = "LiquidityProtection";

    IContractRegistry public registry; // address of the current contract-registry
    IContractRegistry public prevRegistry; // address of the previous contract-registry
    bool public onlyOwnerCanUpdateRegistry; // only an owner can update the contract-registry

    /**
     * @dev verifies that the caller is mapped to the given contract name
     *
     * @param _contractName    contract name
     */
    modifier only(bytes32 _contractName) {
        _only(_contractName);
        _;
    }

    // error message binary size optimization
    function _only(bytes32 _contractName) internal view {
        require(msg.sender == addressOf(_contractName), "ERR_ACCESS_DENIED");
    }

    /**
     * @dev initializes a new ContractRegistryClient instance
     *
     * @param  _registry   address of a contract-registry contract
     */
    constructor(IContractRegistry _registry) internal validAddress(address(_registry)) {
        registry = IContractRegistry(_registry);
        prevRegistry = IContractRegistry(_registry);
    }

    /**
     * @dev updates to the new contract-registry
     */
    function updateRegistry() public {
        // verify that this function is permitted
        require(msg.sender == owner || !onlyOwnerCanUpdateRegistry, "ERR_ACCESS_DENIED");

        // get the new contract-registry
        IContractRegistry newRegistry = IContractRegistry(addressOf(CONTRACT_REGISTRY));

        // verify that the new contract-registry is different and not zero
        require(newRegistry != registry && address(newRegistry) != address(0), "ERR_INVALID_REGISTRY");

        // verify that the new contract-registry is pointing to a non-zero contract-registry
        require(newRegistry.addressOf(CONTRACT_REGISTRY) != address(0), "ERR_INVALID_REGISTRY");

        // save a backup of the current contract-registry before replacing it
        prevRegistry = registry;

        // replace the current contract-registry with the new contract-registry
        registry = newRegistry;
    }

    /**
     * @dev restores the previous contract-registry
     */
    function restoreRegistry() public ownerOnly {
        // restore the previous contract-registry
        registry = prevRegistry;
    }

    /**
     * @dev restricts the permission to update the contract-registry
     *
     * @param _onlyOwnerCanUpdateRegistry  indicates whether or not permission is restricted to owner only
     */
    function restrictRegistryUpdate(bool _onlyOwnerCanUpdateRegistry) public ownerOnly {
        // change the permission to update the contract-registry
        onlyOwnerCanUpdateRegistry = _onlyOwnerCanUpdateRegistry;
    }

    /**
     * @dev returns the address associated with the given contract name
     *
     * @param _contractName    contract name
     *
     * @return contract address
     */
    function addressOf(bytes32 _contractName) internal view returns (address) {
        return registry.addressOf(_contractName);
    }
}

// File: solidity/contracts/liquidity-protection/LiquidityProtectionSettings.sol


pragma solidity 0.6.12;









/**
 * @dev Liquidity Protection Settings contract
 */
contract LiquidityProtectionSettings is ILiquidityProtectionSettings, AccessControl, ContractRegistryClient {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    // the owner role is used to update the settings
    bytes32 public constant ROLE_OWNER = keccak256("ROLE_OWNER");

    uint32 private constant PPM_RESOLUTION = 1000000;

    IERC20Token private immutable _networkToken;

    // list of whitelisted pools
    EnumerableSet.AddressSet private _poolWhitelist;

    // list of subscribers
    EnumerableSet.AddressSet private _subscribers;

    // network token minting limits
    uint256 private _minNetworkTokenLiquidityForMinting = 1000e18;
    uint256 private _defaultNetworkTokenMintingLimit = 20000e18;
    mapping(IConverterAnchor => uint256) private _networkTokenMintingLimits;

    // permission of adding liquidity for a given reserve on a given pool
    mapping(IConverterAnchor => mapping(IERC20Token => bool)) private _addLiquidityDisabled;

    // number of seconds until any protection is in effect
    uint256 private _minProtectionDelay = 30 days;

    // number of seconds until full protection is in effect
    uint256 private _maxProtectionDelay = 100 days;

    // minimum amount of network tokens that the system can mint as compensation for base token losses
    uint256 private _minNetworkCompensation = 1e16; // = 0.01 network tokens

    // number of seconds from liquidation to full network token release
    uint256 private _lockDuration = 24 hours;

    // maximum deviation of the average rate from the spot rate
    uint32 private _averageRateMaxDeviation = 5000; // PPM units

    /**
     * @dev triggered when the pool whitelist is updated
     *
     * @param poolAnchor    pool anchor
     * @param added         true if the pool was added to the whitelist, false if it was removed
     */
    event PoolWhitelistUpdated(IConverterAnchor indexed poolAnchor, bool added);

    /**
     * @dev triggered when a subscriber is added or removed
     *
     * @param subscriber    subscriber
     * @param added         true if the subscriber was added, false if it was removed
     */
    event SubscriberUpdated(ILiquidityProtectionEventsSubscriber indexed subscriber, bool added);

    /**
     * @dev triggered when the minimum amount of network token liquidity to allow minting is updated
     *
     * @param prevMin   previous minimum amount of network token liquidity for minting
     * @param newMin    new minimum amount of network token liquidity for minting
     */
    event MinNetworkTokenLiquidityForMintingUpdated(uint256 prevMin, uint256 newMin);

    /**
     * @dev triggered when the default network token minting limit is updated
     *
     * @param prevDefault   previous default network token minting limit
     * @param newDefault    new default network token minting limit
     */
    event DefaultNetworkTokenMintingLimitUpdated(uint256 prevDefault, uint256 newDefault);

    /**
     * @dev triggered when a pool network token minting limit is updated
     *
     * @param poolAnchor    pool anchor
     * @param prevLimit     previous limit
     * @param newLimit      new limit
     */
    event NetworkTokenMintingLimitUpdated(IConverterAnchor indexed poolAnchor, uint256 prevLimit, uint256 newLimit);

    /**
     * @dev triggered when the protection delays are updated
     *
     * @param prevMinProtectionDelay    previous seconds until the protection starts
     * @param newMinProtectionDelay     new seconds until the protection starts
     * @param prevMaxProtectionDelay    previous seconds until full protection
     * @param newMaxProtectionDelay     new seconds until full protection
     */
    event ProtectionDelaysUpdated(
        uint256 prevMinProtectionDelay,
        uint256 newMinProtectionDelay,
        uint256 prevMaxProtectionDelay,
        uint256 newMaxProtectionDelay
    );

    /**
     * @dev triggered when the minimum network token compensation is updated
     *
     * @param prevMinNetworkCompensation    previous minimum network token compensation
     * @param newMinNetworkCompensation     new minimum network token compensation
     */
    event MinNetworkCompensationUpdated(uint256 prevMinNetworkCompensation, uint256 newMinNetworkCompensation);

    /**
     * @dev triggered when the network token lock duration is updated
     *
     * @param prevLockDuration  previous network token lock duration, in seconds
     * @param newLockDuration   new network token lock duration, in seconds
     */
    event LockDurationUpdated(uint256 prevLockDuration, uint256 newLockDuration);

    /**
     * @dev triggered when the maximum deviation of the average rate from the spot rate is updated
     *
     * @param prevAverageRateMaxDeviation   previous maximum deviation of the average rate from the spot rate
     * @param newAverageRateMaxDeviation    new maximum deviation of the average rate from the spot rate
     */
    event AverageRateMaxDeviationUpdated(uint32 prevAverageRateMaxDeviation, uint32 newAverageRateMaxDeviation);

    /**
     * @dev triggered when adding liquidity is disabled or enabled for a given reserve on a given pool
     *
     * @param poolAnchor    pool anchor
     * @param reserveToken  reserve token
     * @param disabled      true if disabled, false otherwise
     */
    event AddLiquidityDisabled(IConverterAnchor indexed poolAnchor, IERC20Token indexed reserveToken, bool disabled);

    /**
     * @dev initializes a new LiquidityProtectionSettings contract
     *
     * @param registry  contract registry
     * @param token     the network token
     */
    constructor(IERC20Token token, IContractRegistry registry)
        public
        ContractRegistryClient(registry)
        validAddress(address(token))
        notThis(address(token))
    {
        // set up administrative roles.
        _setRoleAdmin(ROLE_OWNER, ROLE_OWNER);

        // allow the deployer to initially govern the contract.
        _setupRole(ROLE_OWNER, msg.sender);

        _networkToken = token;
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    // error message binary size optimization
    function _onlyOwner() internal view {
        require(hasRole(ROLE_OWNER, msg.sender), "ERR_ACCESS_DENIED");
    }

    // ensures that the portion is valid
    modifier validPortion(uint32 portion) {
        _validPortion(portion);
        _;
    }

    // error message binary size optimization
    function _validPortion(uint32 portion) internal pure {
        require(portion > 0 && portion <= PPM_RESOLUTION, "ERR_INVALID_PORTION");
    }

    /**
     * @dev returns the network token
     *
     * @return the network token
     */
    function networkToken() external view returns (IERC20Token) {
        return _networkToken;
    }

    /**
     * @dev returns the minimum network token liquidity for minting
     *
     * @return the minimum network token liquidity for minting
     */
    function minNetworkTokenLiquidityForMinting() external view override returns (uint256) {
        return _minNetworkTokenLiquidityForMinting;
    }

    /**
     * @dev returns the default network token minting limit
     *
     * @return the default network token minting limit
     */
    function defaultNetworkTokenMintingLimit() external view override returns (uint256) {
        return _defaultNetworkTokenMintingLimit;
    }

    /**
     * @dev returns the network token minting limit for a given pool
     *
     * @param poolAnchor    pool anchor
     * @return the network token minting limit for a given pool
     */
    function networkTokenMintingLimits(IConverterAnchor poolAnchor) external view override returns (uint256) {
        return _networkTokenMintingLimits[poolAnchor];
    }

    /**
     * @dev returns the permission of adding liquidity for a given reserve on a given pool
     *
     * @param poolAnchor    pool anchor
     * @param reserveToken  reserve token
     * @return true if adding liquidity is disabled, false otherwise
     */
    function addLiquidityDisabled(IConverterAnchor poolAnchor, IERC20Token reserveToken)
        external
        view
        override
        returns (bool)
    {
        return _addLiquidityDisabled[poolAnchor][reserveToken];
    }

    /**
     * @dev returns the minimum number of seconds until any protection is in effect
     *
     * @return the minimum number of seconds until any protection is in effect
     */
    function minProtectionDelay() external view override returns (uint256) {
        return _minProtectionDelay;
    }

    /**
     * @dev returns the maximum number of seconds until full protection is in effect
     *
     * @return the maximum number of seconds until full protection is in effect
     */
    function maxProtectionDelay() external view override returns (uint256) {
        return _maxProtectionDelay;
    }

    /**
     * @dev returns the minimum amount of network tokens that the system can mint as compensation for base token losses
     *
     * @return the minimum amount of network tokens that the system can mint as compensation for base token losses
     */
    function minNetworkCompensation() external view override returns (uint256) {
        return _minNetworkCompensation;
    }

    /**
     * @dev returns the number of seconds from liquidation to full network token release
     *
     * @return the number of seconds from liquidation to full network token release
     */
    function lockDuration() external view override returns (uint256) {
        return _lockDuration;
    }

    /**
     * @dev returns the maximum deviation of the average rate from the spot rate
     *
     * @return the maximum deviation of the average rate from the spot rate
     */
    function averageRateMaxDeviation() external view override returns (uint32) {
        return _averageRateMaxDeviation;
    }

    /**
     * @dev adds a pool to the whitelist
     * can only be called by the contract owner
     *
     * @param poolAnchor    pool anchor
     */
    function addPoolToWhitelist(IConverterAnchor poolAnchor)
        external
        onlyOwner
        validAddress(address(poolAnchor))
        notThis(address(poolAnchor))
    {
        require(_poolWhitelist.add(address(poolAnchor)), "ERR_POOL_ALREADY_WHITELISTED");

        emit PoolWhitelistUpdated(poolAnchor, true);
    }

    /**
     * @dev removes a pool from the whitelist
     * can only be called by the contract owner
     *
     * @param poolAnchor    pool anchor
     */
    function removePoolFromWhitelist(IConverterAnchor poolAnchor)
        external
        onlyOwner
        validAddress(address(poolAnchor))
        notThis(address(poolAnchor))
    {
        require(_poolWhitelist.remove(address(poolAnchor)), "ERR_POOL_NOT_WHITELISTED");

        emit PoolWhitelistUpdated(poolAnchor, false);
    }

    /**
     * @dev checks whether a given pool is whitelisted
     *
     * @param poolAnchor    pool anchor
     * @return true if the given pool is whitelisted, false otherwise
     */
    function isPoolWhitelisted(IConverterAnchor poolAnchor) external view override returns (bool) {
        return _poolWhitelist.contains(address(poolAnchor));
    }

    /**
     * @dev returns pools whitelist
     *
     * @return pools whitelist
     */
    function poolWhitelist() external view override returns (address[] memory) {
        uint256 length = _poolWhitelist.length();
        address[] memory list = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            list[i] = _poolWhitelist.at(i);
        }
        return list;
    }

    /**
     * @dev adds a subscriber
     * can only be called by the contract owner
     *
     * @param subscriber    subscriber address
     */
    function addSubscriber(ILiquidityProtectionEventsSubscriber subscriber)
        external
        onlyOwner
        validAddress(address(subscriber))
        notThis(address(subscriber))
    {
        require(_subscribers.add(address(subscriber)), "ERR_SUBSCRIBER_ALREADY_SET");

        emit SubscriberUpdated(subscriber, true);
    }

    /**
     * @dev removes a subscriber
     * can only be called by the contract owner
     *
     * @param subscriber    subscriber address
     */
    function removeSubscriber(ILiquidityProtectionEventsSubscriber subscriber)
        external
        onlyOwner
        validAddress(address(subscriber))
        notThis(address(subscriber))
    {
        require(_subscribers.remove(address(subscriber)), "ERR_INVALID_SUBSCRIBER");

        emit SubscriberUpdated(subscriber, false);
    }

    /**
     * @dev returns subscribers list
     *
     * @return subscribers list
     */
    function subscribers() external view override returns (address[] memory) {
        uint256 length = _subscribers.length();
        address[] memory list = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            list[i] = _subscribers.at(i);
        }
        return list;
    }

    /**
     * @dev updates the minimum amount of network token liquidity to allow minting
     * can only be called by the contract owner
     *
     * @param amount   the minimum amount of network token liquidity to allow minting
     */
    function setMinNetworkTokenLiquidityForMinting(uint256 amount) external onlyOwner() {
        emit MinNetworkTokenLiquidityForMintingUpdated(_minNetworkTokenLiquidityForMinting, amount);

        _minNetworkTokenLiquidityForMinting = amount;
    }

    /**
     * @dev updates the default amount of network token that the system can mint into each pool
     * can only be called by the contract owner
     *
     * @param amount    the default amount of network token that the system can mint into each pool
     */
    function setDefaultNetworkTokenMintingLimit(uint256 amount) external onlyOwner() {
        emit DefaultNetworkTokenMintingLimitUpdated(_defaultNetworkTokenMintingLimit, amount);

        _defaultNetworkTokenMintingLimit = amount;
    }

    /**
     * @dev updates the amount of network tokens that the system can mint into a specific pool
     * can only be called by the contract owner
     *
     * @param poolAnchor    pool anchor
     * @param amount        the amount of network tokens that the system can mint into a specific pool
     */
    function setNetworkTokenMintingLimit(IConverterAnchor poolAnchor, uint256 amount)
        external
        onlyOwner()
        validAddress(address(poolAnchor))
    {
        emit NetworkTokenMintingLimitUpdated(poolAnchor, _networkTokenMintingLimits[poolAnchor], amount);

        _networkTokenMintingLimits[poolAnchor] = amount;
    }

    /**
     * @dev updates the protection delays
     * can only be called by the contract owner
     *
     * @param minDelay   seconds until the protection starts
     * @param maxDelay   seconds until full protection
     */
    function setProtectionDelays(uint256 minDelay, uint256 maxDelay) external onlyOwner() {
        require(minDelay < maxDelay, "ERR_INVALID_PROTECTION_DELAY");

        emit ProtectionDelaysUpdated(_minProtectionDelay, minDelay, _maxProtectionDelay, maxDelay);

        _minProtectionDelay = minDelay;
        _maxProtectionDelay = maxDelay;
    }

    /**
     * @dev updates the minimum amount of network token compensation
     * can only be called by the contract owner
     *
     * @param amount    the minimum amount of network token compensation
     */
    function setMinNetworkCompensation(uint256 amount) external onlyOwner() {
        emit MinNetworkCompensationUpdated(_minNetworkCompensation, amount);

        _minNetworkCompensation = amount;
    }

    /**
     * @dev updates the network token lock duration
     * can only be called by the contract owner
     *
     * @param duration  network token lock duration, in seconds
     */
    function setLockDuration(uint256 duration) external onlyOwner() {
        emit LockDurationUpdated(_lockDuration, duration);

        _lockDuration = duration;
    }

    /**
     * @dev sets the maximum deviation of the average rate from the spot rate
     * can only be called by the contract owner
     *
     * @param deviation maximum deviation of the average rate from the spot rate
     */
    function setAverageRateMaxDeviation(uint32 deviation) external onlyOwner() validPortion(deviation) {
        emit AverageRateMaxDeviationUpdated(_averageRateMaxDeviation, deviation);

        _averageRateMaxDeviation = deviation;
    }

    /**
     * @dev disables or enables adding liquidity for a given reserve on a given pool
     * can only be called by the contract owner
     *
     * @param poolAnchor    pool anchor
     * @param reserveToken  reserve token
     * @param disable       true to disable, false otherwise
     */
    function disableAddLiquidity(
        IConverterAnchor poolAnchor,
        IERC20Token reserveToken,
        bool disable
    ) external onlyOwner() {
        emit AddLiquidityDisabled(poolAnchor, reserveToken, disable);

        _addLiquidityDisabled[poolAnchor][reserveToken] = disable;
    }

    /**
     * @dev checks if protection is supported for the given pool
     * only standard pools are supported (2 reserves, 50%/50% weights)
     * note that the pool should still be whitelisted
     *
     * @param poolAnchor    anchor of the pool
     * @return true if the pool is supported, false otherwise
     */
    function isPoolSupported(IConverterAnchor poolAnchor) external view override returns (bool) {
        IERC20Token tmpNetworkToken = _networkToken;

        // verify that the pool exists in the registry
        IConverterRegistry converterRegistry = IConverterRegistry(addressOf(CONVERTER_REGISTRY));
        require(converterRegistry.isAnchor(address(poolAnchor)), "ERR_INVALID_ANCHOR");

        // get the converter
        IConverter converter = IConverter(payable(poolAnchor.owner()));

        // verify that the converter has 2 reserves
        if (converter.connectorTokenCount() != 2) {
            return false;
        }

        // verify that one of the reserves is the network token
        IERC20Token reserve0Token = converter.connectorTokens(0);
        IERC20Token reserve1Token = converter.connectorTokens(1);
        if (reserve0Token != tmpNetworkToken && reserve1Token != tmpNetworkToken) {
            return false;
        }

        // verify that the reserve weights are exactly 50%/50%
        if (
            converterReserveWeight(converter, reserve0Token) != PPM_RESOLUTION / 2 ||
            converterReserveWeight(converter, reserve1Token) != PPM_RESOLUTION / 2
        ) {
            return false;
        }

        return true;
    }

    // utility to get the reserve weight (including from older converters that don't support the new converterReserveWeight function)
    function converterReserveWeight(IConverter converter, IERC20Token reserveToken) private view returns (uint32) {
        (, uint32 weight, , , ) = converter.connectors(reserveToken);
        return weight;
    }
}