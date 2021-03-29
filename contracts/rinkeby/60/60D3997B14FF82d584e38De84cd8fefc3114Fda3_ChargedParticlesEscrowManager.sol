/**
 *Submitted for verification at Etherscan.io on 2021-03-29
*/

pragma solidity 0.6.10;
// SPDX-License-Identifier: MIT
/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
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
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
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
 *     require(hasRole(MY_ROLE, _msgSender()));
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
 */
abstract contract AccessControlUpgradeSafe is Initializable, ContextUpgradeSafe {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {


    }

    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
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

    uint256[49] private __gap;
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
contract ReentrancyGuardUpgradeSafe is Initializable {
    bool private _notEntered;


    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {


        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;

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
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }

    uint256[49] private __gap;
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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
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



// IChargedParticlesEscrow.sol -- Interest-bearing NFTs
// Copyright (c) 2019, 2020 Rob Secord <robsecord.eth>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.




/**
 * @notice Interface for the Charged Particles Escrow
 */
interface IChargedParticlesEscrowManager {

    function isAssetPairEnabled(string calldata _assetPairId) external view returns (bool);
    function getAssetPairsCount() external view returns (uint);
    function getAssetPairByIndex(uint _index) external view returns (string calldata);
    function getAssetTokenEscrow(string calldata _assetPairId) external view returns (address);
    function getAssetTokenAddress(string calldata _assetPairId) external view returns (address);
    function getInterestTokenAddress(string calldata _assetPairId) external view returns (address);

    function getUUID(address _contractAddress, uint256 _id) external pure returns (uint256);
    //function getAssetMinDeposit(address _contractAddress) external view returns (uint256);
    //function getAssetMaxDeposit(address _contractAddress) external view returns (uint256);
    function getFeesForDeposit(address _contractAddress, uint256 _interestTokenAmount) external view returns (uint256, uint256);
    function getFeeForDeposit(address _contractAddress, uint256 _interestTokenAmount) external view returns (uint256);

    //function setDischargeApproval(address _contractAddress, uint256 _tokenId, address _operator) external;
    //function isApprovedForDischarge(address _contractAddress, uint256 _tokenId, address _operator) external view returns (bool);

    function baseParticleMass(address _contractAddress, uint256 _tokenId, string calldata _assetPairId) external view returns (uint256);
   // function currentParticleCharge(address _contractAddress, uint256 _tokenId, string calldata _assetPairId) external returns (uint256);

    /***********************************|
    |     Register Contract Settings    |
    |(For External Contract Integration)|
    |__________________________________*/

    function isContractOwner(address _account, address _contract) external view returns (bool);
    function registerContractType(address _contractAddress) external;
    //function registerContractSettingReleaseBurn(address _contractAddress, bool _releaseRequiresBurn) external;
    function registerContractSettingAssetPair(address _contractAddress, string calldata _assetPairId) external;
   // function registerContractSettingDepositFee(address _contractAddress, uint256 _depositFee) external;
    function registerContractSettingMinDeposit(address _contractAddress, uint256 _minDeposit) external;
    function registerContractSettingMaxDeposit(address _contractAddress, uint256 _maxDeposit) external;

    //function withdrawContractFees(address _contractAddress, address _receiver, string calldata _assetPairId) external;

    /***********************************|
    |          Particle Charge          |
    |__________________________________*/

    function energizeParticle(
        address _contractAddress,
        uint256 _tokenId,
        string calldata _assetPairId,
        uint256 _assetAmount
    ) external;

    // function dischargeParticle(
    //     address _receiver,
    //     address _contractAddress,
    //     uint256 _tokenId,
    //     string calldata _assetPairId
    // ) external returns (uint256, uint256);

    // function dischargeParticleAmount(
    //     address _receiver,
    //     address _contractAddress,
    //     uint256 _tokenId,
    //     string calldata _assetPairId,
    //     uint256 _assetAmount
    // ) external returns (uint256, uint256);

    function releaseParticle(
        address _receiver,
        address _contractAddress,
        uint256 _tokenId,
        string calldata _assetPairId
    ) external returns (uint256);

    function finalizeRelease(
        address _receiver,
        address _contractAddress,
        uint256 _tokenId,
        string calldata _assetPairId
    ) external returns (uint256);
}



// IParticleManager.sol -- Charged Particles
// Copyright (c) 2019, 2020 Rob Secord <robsecord.eth>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.



interface IParticleManager {
    function contractOwner() external view returns (address);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}



// INucleus.sol -- Charged Particles
// Copyright (c) 2019, 2020 Rob Secord <robsecord.eth>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.



/**
 * @title Particle Escrow interface
 * @dev The base escrow for underlying assets attached to Charged Particles
 */
interface IEscrow {
    //
    // Must override:
    //
    function isPaused() external view returns (bool);
    function baseParticleMass(uint256 _tokenUuid) external view returns (uint256);
    //function currentParticleCharge(uint256 _tokenUuid) external returns (uint256);
    function energizeParticle(address _contractAddress, uint256 _tokenUuid, uint256 _assetAmount) external returns (uint256);

    //function dischargeParticle(address _receiver, uint256 _tokenUuid) external returns (uint256, uint256);
    //function dischargeParticleAmount(address _receiver, uint256 _tokenUuid, uint256 _assetAmount) external returns (uint256, uint256);

    function releaseParticle(address _receiver, uint256 _tokenUuid) external returns (uint256);

    //function withdrawFees(address _contractAddress, address _receiver) external returns (uint256);

    // 
    // Inherited from EscrowBase:
    //
    function getAssetTokenAddress() external view returns (address);
    function getInterestTokenAddress() external view returns (address);
}



// Common.sol -- Charged Particles
// Copyright (c) 2019, 2020 Rob Secord <robsecord.eth>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.




/**
 * @notice Common Vars for Charged Particles
 */
contract Common {
    
    uint256 constant internal DEPOSIT_FEE_MODIFIER = 1e4;   // 10000  (100%)
    uint256 constant internal MAX_CUSTOM_DEPOSIT_FEE = 5e3; // 5000   (50%)
    uint256 constant internal MIN_DEPOSIT_FEE = 1e6;        // 1000000 (0.000000000001 ETH  or  1000000 WEI)

    bytes32 constant public ROLE_DAO_GOV = keccak256("ROLE_DAO_GOV");
    bytes32 constant public ROLE_MAINTAINER = keccak256("ROLE_MAINTAINER");

    // Fungibility-Type Flags
    uint256 constant internal TYPE_MASK = uint256(uint128(~0)) << 128;  
    uint256 constant internal NF_INDEX_MASK = uint128(~0);
    uint256 constant internal TYPE_NF_BIT = 1 << 255;

    // Interface Signatures
    bytes4 constant internal INTERFACE_SIGNATURE_ERC165 = 0x01ffc9a7;
    bytes4 constant internal INTERFACE_SIGNATURE_ERC721 = 0x80ac58cd;
    bytes4 constant internal INTERFACE_SIGNATURE_ERC1155 = 0xd9b67a26;
    bytes4 constant internal ERC1155_RECEIVED_VALUE = 0xf23a6e61;
    bytes4 constant internal ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;

}



// ChargedParticlesEscrowManager.sol -- Charged Particles
// Copyright (c) 2019, 2020 Rob Secord <robsecord.eth>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.



















/**
 * @notice Charged Particles Escrow Contract
 */
contract ChargedParticlesEscrowManager is IChargedParticlesEscrowManager, Initializable, AccessControlUpgradeSafe, ReentrancyGuardUpgradeSafe, Common {
    using SafeMath for uint256;

    //
    // Particle Terminology
    //
    //   Particle               - Non-fungible Token
    //   Plasma                 - Fungible Token
    //   Mass                   - Underlying Asset of a Token (ex; DAI)
    //   Charge                 - Accrued Interest on the Underlying Asset of a Token
    //   Charged Particle       - A Token that has a Mass and a Positive Charge
    //   Neutral Particle       - A Token that has a Mass and No Charge
    //   Energize / Recharge    - Deposit of an Underlying Asset into a Token
    //   Discharge              - Withdraw the Accrued Interest of a Token leaving the Particle with its initial Mass
    //   Release                - Withdraw the Underlying Asset & Accrued Interest of a Token leaving the Particle with No Mass
    //                              - Released Tokens are either Burned/Destroyed or left in their Original State as an NFT
    //

    // Asset-Pair-IDs
    string[] internal assetPairs;
    // mapping (string => bool) internal assetPairEnabled;
    mapping (string => IEscrow) internal assetPairEscrow;

    //     TokenUUID => Operator Approval per Token
    mapping (uint256 => address) internal tokenDischargeApprovals;

    //     TokenUUID => Token Release Operator
    mapping (uint256 => address) internal assetToBeReleasedBy;

    // Optional Limits set by Owner of External Token Contracts;
    //  - Any user can add any ERC721 or ERC1155 token as a Charged Particle without Limits,
    //    unless the Owner of the ERC721 or ERC1155 token contract registers the token here
    //    and sets the Custom Limits for their token(s)

    //DELETABLE
    //      Contract => Has this contract address been Registered with Custom Limits?
    mapping (address => bool) internal customRegisteredContract;

    
    //      Contract => Does the Release-Action require the Charged Particle Token to be burned first?
    mapping (address => bool) internal customReleaseRequiresBurn;

    //      Contract => Specific Asset-Pair that is allowed (otherwise, any Asset-Pair is allowed)
    mapping (address => string) internal customAssetPairId;

    //      Contract => Deposit Fees to be earned for Contract Owner
    mapping (address => uint256) internal customAssetDepositFee;

    //      Contract => Allowed Limit of Asset Token [min, max]
    mapping (address => uint256) internal customAssetDepositMin;
    mapping (address => uint256) internal customAssetDepositMax;

    // To "Energize" Particles of any Type, there is a Deposit Fee, which is
    //  a small percentage of the Interest-bearing Asset of the token immediately after deposit.
    //  A value of "50" here would represent a Fee of 0.5% of the Funding Asset ((50 / 10000) * 100)
    //    This allows a fee as low as 0.01%  (value of "1")
    //  This means that a brand new particle would have 99.5% of its "Mass" and 0% of its "Charge".
    //    As the "Charge" increases over time, the particle will fill up the "Mass" to 100% and then
    //    the "Charge" will start building up.  Essentially, only a small portion of the interest
    //    is used to pay the deposit fee.  The particle will be in "cool-down" mode until the "Mass"
    //    of the particle returns to 100% (this should be a relatively short period of time).
    //    When the particle reaches 100% "Mass" or more it can be "Released" (or burned) to reclaim the underlying
    //    asset + interest.  Since the "Mass" will be back to 100%, "Releasing" will yield at least 100%
    //    of the underlying asset back to the owner (plus any interest accrued, the "charge").
    uint256 public depositFee;

    // Contract Version
    bytes16 public version;

    //
    // Modifiers
    //

    // Throws if called by any account other than the Charged Particles DAO contract.
    modifier onlyDao() {
        require(hasRole(ROLE_DAO_GOV, msg.sender), "CPEM: INVALID_DAO");
        _;
    }

    // Throws if called by any account other than the Charged Particles Maintainer.
    modifier onlyMaintainer() {
        require(hasRole(ROLE_MAINTAINER, msg.sender), "CPEM: INVALID_MAINTAINER");
        _;
    }

    //
    // Events
    //

    event RegisterParticleContract(
        address indexed _contractAddress
    );
    event DischargeApproval(
        address indexed _contractAddress,
        uint256 indexed _tokenId,
        address indexed _owner,
        address _operator
    );
    event EnergizedParticle(
        address indexed _contractAddress,
        uint256 indexed _tokenId,
        string _assetPairId,
        uint256 _assetBalance
    );
    event DischargedParticle(
        address indexed _contractAddress,
        uint256 indexed _tokenId,
        address indexed _receiver,
        string _assetPairId,
        uint256 _receivedAmount,
        uint256 _interestBalance
    );
    event ReleasedParticle(
        address indexed _contractAddress,
        uint256 indexed _tokenId,
        address indexed _receiver,
        string _assetPairId,
        uint256 _receivedAmount
    );
    event FeesWithdrawn(
        address indexed _contractAddress,
        address indexed _receiver,
        string _assetPairId,
        uint256 _interestAmoount
    );

    /***********************************|
    |          Initialization           |
    |__________________________________*/

    function initialize() public initializer {
        __ReentrancyGuard_init();
        __AccessControl_init();

        _setupRole(ROLE_DAO_GOV, msg.sender);
        _setRoleAdmin(ROLE_DAO_GOV, ROLE_DAO_GOV);

        _setupRole(ROLE_MAINTAINER, msg.sender);
        _setRoleAdmin(ROLE_MAINTAINER, ROLE_DAO_GOV);

        version = "v0.4.2";
    }

    /***********************************|
    |         Particle Physics          |
    |__________________________________*/

    function isAssetPairEnabled(string calldata _assetPairId) external override view returns (bool) {
        return _isAssetPairEnabled(_assetPairId);
    }

    function getAssetPairsCount() external override view returns (uint) {
        return assetPairs.length;
    }

    function getAssetPairByIndex(uint _index) external override view returns (string memory) {
        require(_index >= 0 && _index < assetPairs.length, "CPEM: INVALID_INDEX");
        return assetPairs[_index];
    }

    function getAssetTokenEscrow(string calldata _assetPairId) external override view returns (address) {
        require(_isAssetPairEnabled(_assetPairId), "CPEM: INVALID_ASSET_PAIR");
        return address(assetPairEscrow[_assetPairId]);
    }

    function getAssetTokenAddress(string calldata _assetPairId) external override view returns (address) {
        return _getAssetTokenAddress(_assetPairId);
    }

    //DELETE
    function getInterestTokenAddress(string calldata _assetPairId) external override view returns (address) {
        return _getInterestTokenAddress(_assetPairId);
    }

    function getUUID(address _contractAddress, uint256 _id) external override pure returns (uint256) {
        return _getUUID(_contractAddress, _id);
    }

    // //DELETE SINCE WE DON"T WANT TO UPPER OR LOWER LIMITS
    // function getAssetMinDeposit(address _contractAddress) external override view returns (uint256) {
    //     return customAssetDepositMin[_contractAddress];
    // }

    // function getAssetMaxDeposit(address _contractAddress) external override view returns (uint256) {
    //     return customAssetDepositMax[_contractAddress];
    // }

    //DELETE
    // /**
    //  * @notice Sets an Operator as Approved to Discharge a specific Token
    //  *    This allows an operator to release the interest-portion only
    //  * @param _contractAddress  The Address to the Contract of the Token
    //  * @param _tokenId          The ID of the Token
    //  * @param _operator         The Address of the Operator to Approve
    //  */
    // function setDischargeApproval(address _contractAddress, uint256 _tokenId, address _operator) external override {
    //     IParticleManager _tokenInterface = IParticleManager(_contractAddress);
    //     address _tokenOwner = _tokenInterface.ownerOf(_tokenId);
    //     require(_operator != _tokenOwner, "CPEM: CANNOT_BE_SELF");
    //     require(msg.sender == _tokenOwner || _tokenInterface.isApprovedForAll(_tokenOwner, msg.sender), "CPEM: NOT_OPERATOR");

    //     uint256 _tokenUuid = _getUUID(_contractAddress, _tokenId);
    //     tokenDischargeApprovals[_tokenUuid] = _operator;
    //     emit DischargeApproval(_contractAddress, _tokenId, _tokenOwner, _operator);
    // }

    // //DELETE
    // /**
    //  * @notice Gets the Approved Discharge-Operator of a specific Token
    //  * @param _contractAddress  The Address to the Contract of the Token
    //  * @param _tokenId          The ID of the Token
    //  * @param _operator         The Address of the Operator to check
    //  * @return  True if the _operator is Approved
    //  */
    // function isApprovedForDischarge(address _contractAddress, uint256 _tokenId, address _operator) external override view returns (bool) {
    //     uint256 _tokenUuid = _getUUID(_contractAddress, _tokenId);
    //     return tokenDischargeApprovals[_tokenUuid] == _operator;
    // }

    //DELETE
    /**
     * @notice Calculates the amount of Fees to be paid for a specific deposit amount
     *   Fees are calculated in Interest-Token as they are the type collected for Fees
     * @param _contractAddress      The Address to the Contract of the Token
     * @param _interestTokenAmount  The Amount of Interest-Token to calculate Fees on
     * @return  The amount of base fees and the amount of custom/creator fees
     */
    function getFeesForDeposit(
        address _contractAddress,
        uint256 _interestTokenAmount
    )
        external
        override
        view
        returns (uint256, uint256)
    {
        return _getFeesForDeposit(_contractAddress, _interestTokenAmount);
    }

    // //DELETE
    /**
     * @notice Calculates the Total Fee to be paid for a specific deposit amount
     *   Fees are calculated in Interest-Token as they are the type collected for Fees
     * @param _contractAddress      The Address to the Contract of the Token
     * @param _interestTokenAmount  The Amount of Interest-Token to calculate Fees on
     * @return  The total amount of base fees plus the amount of custom/creator fees
     */
    function getFeeForDeposit(
        address _contractAddress,
        uint256 _interestTokenAmount
    )
        external
        override
        view
        returns (uint256)
    {
        (uint256 _depositFee, uint256 _customFee) = _getFeesForDeposit(_contractAddress, _interestTokenAmount);
        return _depositFee.add(_customFee);
    }

    //OK
    /**
     * @notice Gets the Amount of Asset Tokens that have been Deposited into the Particle
     *    representing the Mass of the Particle.
     * @param _contractAddress  The Address to the External Contract of the Token
     * @param _tokenId          The ID of the Token within the External Contract
     * @param _assetPairId      The Asset-Pair ID to check the Asset balance of
     * @return  The Amount of underlying Assets held within the Token
     */
    function baseParticleMass(address _contractAddress, uint256 _tokenId, string calldata _assetPairId) external override view returns (uint256) {
        return _baseParticleMass(_contractAddress, _tokenId, _assetPairId);
    }

    // //DELETE
    // /**
    //  * @notice Gets the amount of Interest that the Particle has generated representing
    //  *    the Charge of the Particle
    //  * @param _contractAddress  The Address to the External Contract of the Token
    //  * @param _tokenId          The ID of the Token within the External Contract
    //  * @param _assetPairId      The Asset-Pair ID to check the Asset balance of
    //  * @return  The amount of interest the Token has generated (in Asset Token)
    //  */
    // function currentParticleCharge(address _contractAddress, uint256 _tokenId, string calldata _assetPairId) external override returns (uint256) {
    //     return _currentParticleCharge(_contractAddress, _tokenId, _assetPairId);
    // }

    /***********************************|
    |     Register Contract Settings    |
    |(For External Contract Integration)|
    |__________________________________*/

    /**
     * @notice Checks if an Account is the Owner of a Contract
     *    When Custom Contracts are registered, only the "owner" or operator of the Contract
     *    is allowed to register them and define custom rules for how their tokens are "Charged".
     *    Otherwise, any token can be "Charged" according to the default rules of Charged Particles.
     * @param _account   The Account to check if it is the Owner of the specified Contract
     * @param _contract  The Address to the External Contract to check
     * @return True if the _account is the Owner of the _contract
     */
    function isContractOwner(address _account, address _contract) external override view returns (bool) {
        return _isContractOwner(_account, _contract);
    }

    /**
     * @notice Registers a external ERC-721 Contract in order to define Custom Rules for Tokens
     * @param _contractAddress  The Address to the External Contract of the Token
     */
    function registerContractType(address _contractAddress) external override onlyDao {
        // Check Token Interface to ensure compliance
        // IERC165 _tokenInterface = IERC165(_contractAddress);
        // bool _is721 = _tokenInterface.supportsInterface(INTERFACE_SIGNATURE_ERC721);
        // bool _is1155 = _tokenInterface.supportsInterface(INTERFACE_SIGNATURE_ERC1155);
        // require(_is721 || _is1155, "CPEM: INVALID_INTERFACE");

        // Check Contract Owner to prevent random people from setting Limits
        // require(_isContractOwner(msg.sender, _contractAddress), "CPEM: NOT_OWNER");

        // Contract Registered!
        customRegisteredContract[_contractAddress] = true;

        emit RegisterParticleContract(_contractAddress);
    }

    // //DELETE
    // /**
    //  * @notice Registers the "Release-Burn" Custom Rule on an external ERC-721 Token Contract
    //  *   When enabled, tokens that are "Charged" will require the Token to be Burned before
    //  *   the underlying asset is Released.
    //  * @param _contractAddress       The Address to the External Contract of the Token
    //  * @param _releaseRequiresBurn   True if the External Contract requires tokens to be Burned before Release
    //  */
    // function registerContractSettingReleaseBurn(address _contractAddress, bool _releaseRequiresBurn) external override {
    //     require(customRegisteredContract[_contractAddress], "CPEM: UNREGISTERED");
    //     require(_isContractOwner(msg.sender, _contractAddress), "CPEM: NOT_OWNER");
    //     require(bytes(customAssetPairId[_contractAddress]).length > 0, "CPEM: REQUIRES_SINGLE_ASSET_PAIR");

    //     customReleaseRequiresBurn[_contractAddress] = _releaseRequiresBurn;
    // }

    //DELETE
    /**
     * @notice Registers the "Asset-Pair" Custom Rule on an external ERC-721 Token Contract
     *   The Asset-Pair Rule defines which Asset-Token & Interest-bearing Token Pair can be used to
     *   "Charge" the Token.  If not set, any enabled Asset-Pair can be used.
     * @param _contractAddress  The Address to the External Contract of the Token
     * @param _assetPairId      The Asset-Pair required for Energizing a Token; otherwise Any Asset-Pair is allowed
     */
    function registerContractSettingAssetPair(address _contractAddress, string calldata _assetPairId) external override {
        require(customRegisteredContract[_contractAddress], "CPEM: UNREGISTERED");
        require(_isContractOwner(msg.sender, _contractAddress), "CPEM: NOT_OWNER");

        if (bytes(_assetPairId).length > 0) {
            require(_isAssetPairEnabled(_assetPairId), "CPEM: INVALID_ASSET_PAIR");
        } else {
            require(customReleaseRequiresBurn[_contractAddress] != true, "CPEM: CANNOT_REQUIRE_RELEASE_BURN");
        }

        customAssetPairId[_contractAddress] = _assetPairId;
    }

    // //DELETE
    // /**
    //  * @notice Registers the "Deposit Fee" Custom Rule on an external ERC-721 Token Contract
    //  *    When set, every Token of the Custom ERC-721 Contract that is "Energized" pays a Fee to the
    //  *    Contract Owner denominated in the Interest-bearing Token of the Asset-Pair
    //  * @param _contractAddress  The Address to the External Contract of the Token
    //  * @param _depositFee       The Deposit Fee as a Percentage represented as 10000 = 100%
    //  *    A value of "50" would represent a Fee of 0.5% of the Funding Asset ((50 / 10000) * 100)
    //  *    This allows a fee as low as 0.01%  (value of "1")
    //  */
    // function registerContractSettingDepositFee(address _contractAddress, uint256 _depositFee) external override {
    //     require(customRegisteredContract[_contractAddress], "CPEM: UNREGISTERED");
    //     require(_isContractOwner(msg.sender, _contractAddress), "CPEM: NOT_OWNER");
    //     require(_depositFee <= MAX_CUSTOM_DEPOSIT_FEE, "CPEM: AMOUNT_INVALID");

    //     customAssetDepositFee[_contractAddress] = _depositFee;
    // }

    //DELETE
    /**
     * @notice Registers the "Minimum Deposit Amount" Custom Rule on an external ERC-721 Token Contract
     *    When set, every Token of the Custom ERC-721 Contract must be "Energized" with at least this
     *    amount of Asset Token.
     * @param _contractAddress  The Address to the External Contract of the Token
     * @param _minDeposit       The Minimum Deposit required for a Token
     */
    function registerContractSettingMinDeposit(address _contractAddress, uint256 _minDeposit) external override {
        require(customRegisteredContract[_contractAddress], "CPEM: UNREGISTERED");
        require(_isContractOwner(msg.sender, _contractAddress), "CPEM: NOT_OWNER");
        require(_minDeposit == 0 || _minDeposit > MIN_DEPOSIT_FEE, "CPEM: AMOUNT_INVALID");

        customAssetDepositMin[_contractAddress] = _minDeposit;
    }

    //DELETE
    /**
     * @notice Registers the "Maximum Deposit Amount" Custom Rule on an external ERC-721 Token Contract
     *    When set, every Token of the Custom ERC-721 Contract must be "Energized" with at most this
     *    amount of Asset Token.
     * @param _contractAddress  The Address to the External Contract of the Token
     * @param _maxDeposit       The Maximum Deposit allowed for a Token
     */
    function registerContractSettingMaxDeposit(address _contractAddress, uint256 _maxDeposit) external override {
        require(customRegisteredContract[_contractAddress], "CPEM: UNREGISTERED");
        require(_isContractOwner(msg.sender, _contractAddress), "CPEM: NOT_OWNER");

        customAssetDepositMax[_contractAddress] = _maxDeposit;
    }


    /***********************************|
    |           Collect Fees            |
    |__________________________________*/
    // //DELETE
    // /**
    //  * @notice Allows External Contract Owners to withdraw any Custom Fees earned
    //  * @param _contractAddress  The Address to the External Contract to withdraw Collected Fees for
    //  * @param _receiver         The Address of the Receiver of the Collected Fees
    //  * @param _assetPairId      The Asset-Pair ID to Withdraw Fees for
    //  */
    // function withdrawContractFees(address _contractAddress, address _receiver, string calldata _assetPairId) external override nonReentrant {
    //     require(customRegisteredContract[_contractAddress], "CPEM: UNREGISTERED");
    //     require(_isContractOwner(msg.sender, _contractAddress), "CPEM: NOT_OWNER");
    //     require(_isAssetPairEnabled(_assetPairId), "CPEM: INVALID_ASSET_PAIR");

    //     uint256 _interestAmount = assetPairEscrow[_assetPairId].withdrawFees(_contractAddress, _receiver);
    //     emit FeesWithdrawn(_contractAddress, _receiver, _assetPairId, _interestAmount);
    // }

    /***********************************|
    |        Energize Particles         |
    |__________________________________*/

    /**
     * @notice Fund Particle with Asset Token
     *    Must be called by the Owner providing the Asset
     *    Owner must Approve THIS contract as Operator of Asset
     *
     * NOTE: DO NOT Energize an ERC20 Token, as anyone who holds any amount
     *       of the same ERC20 token could discharge or release the funds.
     *       All holders of the ERC20 token would essentially be owners of the Charged Particle.
     *
     * @param _contractAddress  The Address to the Contract of the Token to Energize
     * @param _tokenId          The ID of the Token to Energize
     * @param _assetPairId      The Asset-Pair to Energize the Token with
     * @param _assetAmount      The Amount of Asset Token to Energize the Token with
     
     */
    function energizeParticle(
        address _contractAddress,
        uint256 _tokenId,
        string calldata _assetPairId,
        uint256 _assetAmount
    )
        external
        override
        nonReentrant
        //returns (uint256)
    {
        require(_isAssetPairEnabled(_assetPairId), "CPEM: INVALID_ASSET_PAIR");
        require(customRegisteredContract[_contractAddress], "CPEM: UNREGISTERED");

        // Get Escrow for Asset
        IEscrow _assetPairEscrow = assetPairEscrow[_assetPairId];
        
        // Get Token UUID & Balance
        uint256 _typeId = _tokenId;
        if (_tokenId & TYPE_NF_BIT == TYPE_NF_BIT) {
            _typeId = _tokenId & TYPE_MASK;
        }
        uint256 _tokenUuid = _getUUID(_contractAddress, _tokenId);
        uint256 _existingBalance = _assetPairEscrow.baseParticleMass(_tokenUuid);
       // console.log(_existingBalance, 'before balance');
        uint256 _newBalance = _assetAmount.add(_existingBalance);
       // console.log(_newBalance, 'updated balance');

        //DELETE THIS PART PROBABLY (all if)
        // Validate Custom Contract Settings
        // Valid Asset-Pair?
        if (bytes(customAssetPairId[_contractAddress]).length > 0) {
            require(keccak256(abi.encodePacked(customAssetPairId[_contractAddress])) == keccak256(abi.encodePacked(_assetPairId)), "CPEM: INVALID_ASSET_PAIR");
        }

        // Valid Amount?
        if (customAssetDepositMin[_contractAddress] > 0) {
            require(_newBalance >= customAssetDepositMin[_contractAddress], "CPEM: INSUFF_DEPOSIT");
        }

        if (customAssetDepositMax[_contractAddress] > 0) {
            require(_newBalance <= customAssetDepositMax[_contractAddress], "CPEM: INSUFF_DEPOSIT");
        }

        // Transfer Asset Token from Caller to Contract
        _collectAssetToken(msg.sender, _assetPairId, _assetAmount);

        // Collect Asset Token (reverts on fail)
        _assetPairEscrow.energizeParticle(_contractAddress, _tokenUuid, _assetAmount);

        emit EnergizedParticle(_contractAddress, _tokenId, _assetPairId, _newBalance);

        // Return amount of Interest-bearing Token energized
        //return _interestAmount;
    }

    /***********************************|
    |        Discharge Particles        |
    |__________________________________*/
    // //DELETE
    // /**
    //  * @notice Allows the owner or operator of the Token to collect or transfer the interest generated
    //  *         from the token without removing the underlying Asset that is held within the token.
    //  * @param _receiver         The Address to Receive the Discharged Asset Tokens
    //  * @param _contractAddress  The Address to the Contract of the Token to Discharge
    //  * @param _tokenId          The ID of the Token to Discharge
    //  * @param _assetPairId      The Asset-Pair to Discharge from the Token
    //  * @return  Two values; 1: Amount of Asset Token Received, 2: Remaining Charge of the Token
    //  */
    // function dischargeParticle(
    //     address _receiver,
    //     address _contractAddress,
    //     uint256 _tokenId,
    //     string calldata _assetPairId
    // )
    //     external
    //     override
    //     nonReentrant
    //     returns (uint256, uint256)
    // {
    //     uint256 _tokenUuid = _getUUID(_contractAddress, _tokenId);
    //     return assetPairEscrow[_assetPairId].dischargeParticle(_receiver, _tokenUuid);
    // }

    // //DELETE
    // /**
    //  * @notice Allows the owner or operator of the Token to collect or transfer a specific amount the interest
    //  *         generated from the token without removing the underlying Asset that is held within the token.
    //  * @param _receiver         The Address to Receive the Discharged Asset Tokens
    //  * @param _contractAddress  The Address to the Contract of the Token to Discharge
    //  * @param _tokenId          The ID of the Token to Discharge
    //  * @param _assetPairId      The Asset-Pair to Discharge from the Token
    //  * @param _assetAmount      The specific amount of Asset Token to Discharge from the Token
    //  * @return  Two values; 1: Amount of Asset Token Received, 2: Remaining Charge of the Token
    //  */
    // function dischargeParticleAmount(
    //     address _receiver,
    //     address _contractAddress,
    //     uint256 _tokenId,
    //     string calldata _assetPairId,
    //     uint256 _assetAmount
    // )
    //     external
    //     override
    //     nonReentrant
    //     returns (uint256, uint256)
    // {
    //     uint256 _tokenUuid = _getUUID(_contractAddress, _tokenId);
    //     return assetPairEscrow[_assetPairId].dischargeParticleAmount(_receiver, _tokenUuid, _assetAmount);
    // }

    /***********************************|
    |         Release Particles         |
    |__________________________________*/

    // MODIFY IT, REMOVE THE INTEREST PART
    /**
     * @notice Releases the Full amount of Asset + Interest held within the Particle by Asset-Pair
     *    Tokens that require Burn before Release MUST call "finalizeRelease" after Burning the Token.
     *    In such cases, the Order of Operations should be:
     *       1. call "releaseParticle"
     *       2. Burn Token
     *       3. call "finalizeRelease"
     *    This should be done in a single, atomic transaction
     *
     * @param _receiver         The Address to Receive the Released Asset Tokens
     * @param _contractAddress  The Address to the Contract of the Token to Release
     * @param _tokenId          The ID of the Token to Release
     * @param _assetPairId      The Asset-Pair to Release from the Token
     * @return  The Total Amount of Asset Token Released including all converted Interest
     */
    function releaseParticle(
        address _receiver,
        address _contractAddress,
        uint256 _tokenId,
        string calldata _assetPairId
    )
        external
        override
        nonReentrant
        returns (uint256)
    {
        require(_isAssetPairEnabled(_assetPairId), "CPEM: INVALID_ASSET_PAIR");
        require(_baseParticleMass(_contractAddress, _tokenId, _assetPairId) > 0, "CPEM: INSUFF_MASS");
        IParticleManager _tokenInterface = IParticleManager(_contractAddress);

        // Validate Token Owner/Operator
        address _tokenOwner = _tokenInterface.ownerOf(_tokenId);
        require((_tokenOwner == msg.sender) || _tokenInterface.isApprovedForAll(_tokenOwner, msg.sender), "CPEM: NOT_OPERATOR");

        // REMOVE THIS PART IF
        // Validate Token Burn before Release
        bool requiresBurn;
        if (customRegisteredContract[_contractAddress]) {
            // Does Release Require Token Burn first?
            if (customReleaseRequiresBurn[_contractAddress]) {
                requiresBurn = true;
            }
        }

        uint256 _tokenUuid = _getUUID(_contractAddress, _tokenId);
        if (requiresBurn) {
            assetToBeReleasedBy[_tokenUuid] = msg.sender;
            return 0; // Need to call "finalizeRelease" next, in order to prove token-burn
        }

        // Release Particle to Receiver
        return assetPairEscrow[_assetPairId].releaseParticle(_receiver, _tokenUuid);
    }

    /**
     * @notice Finalizes the Release of a Particle when that Particle requires Burn before Release
     * @param _receiver         The Address to Receive the Released Asset Tokens
     * @param _contractAddress  The Address to the Contract of the Token to Release
     * @param _tokenId          The ID of the Token to Release
     * @param _assetPairId      The Asset-Pair to Release from the Token
     * @return  The Total Amount of Asset Token Released including all converted Interest
     */
    function finalizeRelease(
        address _receiver,
        address _contractAddress,
        uint256 _tokenId,
        string calldata _assetPairId
    )
        external
        override
        returns (uint256)
    {
        IParticleManager _tokenInterface = IParticleManager(_contractAddress);
        uint256 _tokenUuid = _getUUID(_contractAddress, _tokenId);
        address releaser = assetToBeReleasedBy[_tokenUuid];

        // Validate Release Operator
        require(releaser == msg.sender, "CPEM: NOT_RELEASE_OPERATOR");

        // Validate Token Burn
        address _tokenOwner = _tokenInterface.ownerOf(_tokenId);
        require(_tokenOwner == address(0x0), "CPEM: INVALID_BURN");

        // Release Particle to Receiver
        assetToBeReleasedBy[_tokenUuid] = address(0x0);
        return assetPairEscrow[_assetPairId].releaseParticle(_receiver, _tokenUuid);
    }


    /***********************************|
    |          Only Admin/DAO           |
    |__________________________________*/
    
    // REMOVE
    /**
     * @dev Setup the Base Deposit Fee for the Escrow
     */
    function setDepositFee(uint256 _depositFee) external onlyDao {
        depositFee = _depositFee;
    }

    
    /**
     * @dev Register Contracts for Asset/Interest Pairs
     */
    function registerAssetPair(string calldata _assetPairId, address _escrow) external onlyMaintainer {
        // Validate Escrow
        IEscrow _newEscrow = IEscrow(_escrow);
        require(_newEscrow.isPaused() != true, "CPEM: INVALID_ESCROW");

        // Register Pair
        assetPairs.push(_assetPairId);
        assetPairEscrow[_assetPairId] = _newEscrow;

        // Infinite approve the Escrow
        _getAssetToken(_assetPairId).approve(_escrow, uint256(-1));
    }

    /**
     * @dev Disable a specific Asset-Pair
     */
    function disableAssetPair(string calldata _assetPairId) external onlyMaintainer {
        require(_isAssetPairEnabled(_assetPairId), "CPEM: INVALID_ASSET_PAIR");

        assetPairEscrow[_assetPairId] = IEscrow(address(0x0));
    }

    function enableDao(address _dao) external onlyDao {
        grantRole(ROLE_DAO_GOV, _dao);
        // DAO must assign a Maintainer

        if (hasRole(ROLE_DAO_GOV, msg.sender)) {
            renounceRole(ROLE_DAO_GOV, msg.sender);
        }
        if (hasRole(ROLE_MAINTAINER, msg.sender)) {
            renounceRole(ROLE_MAINTAINER, msg.sender);
        }
    }

    /***********************************|
    |         Private Functions         |
    |__________________________________*/

    function _isAssetPairEnabled(string calldata _assetPairId) internal view returns (bool) {
        return (address(assetPairEscrow[_assetPairId]) != address(0x0));
    }
    function _getAssetTokenAddress(string calldata _assetPairId) internal view returns (address) {
        require(_isAssetPairEnabled(_assetPairId), "CPEM: INVALID_ASSET_PAIR");
        return assetPairEscrow[_assetPairId].getAssetTokenAddress();
    }

    // REMOVE
    function _getInterestTokenAddress(string calldata _assetPairId) internal view returns (address) {
        require(_isAssetPairEnabled(_assetPairId), "CPEM: INVALID_ASSET_PAIR");
        return assetPairEscrow[_assetPairId].getInterestTokenAddress();
    }

    function _getUUID(address _contractAddress, uint256 _id) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(_contractAddress, _id)));
    }

    /**
     * @notice Checks if an Account is the Owner of a Contract
     *    When Custom Contracts are registered, only the "owner" or operator of the Contract
     *    is allowed to register them and define custom rules for how their tokens are "Charged".
     *    Otherwise, any token can be "Charged" according to the default rules of Charged Particles.
     * @param _account   The Account to check if it is the Owner of the specified Contract
     * @param _contract  The Address to the External Contract to check
     * @return True if the _account is the Owner of the _contract
     */
    function _isContractOwner(address _account, address _contract) internal view returns (bool) {
        address _contractOwner = IParticleManager(_contract).contractOwner();
        return _contractOwner != address(0x0) && _contractOwner == _account;
    }

    // REMOVE
    /**
     * @dev Calculates the amount of Fees to be paid for a specific deposit amount
     *   Fees are calculated in Interest-Token as they are the type collected for Fees
     * @param _contractAddress      The Address to the Contract of the Token
     * @param _interestTokenAmount  The Amount of Interest-Token to calculate Fees on
     * @return  The amount of base fees and the amount of custom/creator fees
     */
    function _getFeesForDeposit(
        address _contractAddress,
        uint256 _interestTokenAmount
    )
        internal
        view
        returns (uint256, uint256)
    {
        uint256 _depositFee;
        uint256 _customFee;

        if (depositFee > 0) {
            _depositFee = _interestTokenAmount.mul(depositFee).div(DEPOSIT_FEE_MODIFIER);
        }

        uint256 _customFeeSetting = customAssetDepositFee[_contractAddress];
        if (_customFeeSetting > 0) {
            _customFee = _interestTokenAmount.mul(_customFeeSetting).div(DEPOSIT_FEE_MODIFIER);
        }

        return (_depositFee, _customFee);
    }

    function _getAssetToken(string calldata _assetPairId) internal view returns (IERC20) {
        address _assetTokenAddress = _getAssetTokenAddress(_assetPairId);
        return IERC20(_assetTokenAddress);
    }

    /**
     * @dev Collects the Required Asset Token from the users wallet
     * @param _from         The owner address to collect the Assets from
     * @param _assetPairId  The ID of the Asset-Pair that the Particle will use for the Underlying Assets
     * @param _assetAmount  The Amount of Asset Tokens to Collect
     */
    function _collectAssetToken(address _from, string calldata _assetPairId, uint256 _assetAmount) internal {
        IERC20 _assetToken = _getAssetToken(_assetPairId);

        uint256 _userAssetBalance = _assetToken.balanceOf(_from);
        require(_assetAmount <= _userAssetBalance, "CPEM: INSUFF_ASSETS");
        // Be sure to Approve this Contract to transfer your Asset Token
        require(_assetToken.transferFrom(_from, address(this), _assetAmount), "CPEM: TRANSFER_FAILED");
    }

    /**
     * @dev Gets the Amount of Asset Tokens that have been Deposited into the Particle
     *    representing the Mass of the Particle.
     * @param _contractAddress  The Address to the External Contract of the Token
     * @param _tokenId          The ID of the Token within the External Contract
     * @param _assetPairId      The Asset-Pair ID to check the Asset balance of
     * @return  The Amount of underlying Assets held within the Token
     */
    function _baseParticleMass(address _contractAddress, uint256 _tokenId, string calldata _assetPairId) internal view returns (uint256) {
        require(_isAssetPairEnabled(_assetPairId), "CPEM: INVALID_ASSET_PAIR");

        uint256 _tokenUuid = _getUUID(_contractAddress, _tokenId);
        return assetPairEscrow[_assetPairId].baseParticleMass(_tokenUuid);
    }

    // //DELETE
    // /**
    //  * @dev Gets the amount of Interest that the Particle has generated representing
    //  *    the Charge of the Particle
    //  * @param _contractAddress  The Address to the External Contract of the Token
    //  * @param _tokenId          The ID of the Token within the External Contract
    //  * @param _assetPairId      The Asset-Pair ID to check the Asset balance of
    //  * @return  The amount of interest the Token has generated (in Asset Token)
    //  */
    // function _currentParticleCharge(address _contractAddress, uint256 _tokenId, string calldata _assetPairId) internal returns (uint256) {
    //     require(_isAssetPairEnabled(_assetPairId), "CPEM: INVALID_ASSET_PAIR");

    //     uint256 _tokenUuid = _getUUID(_contractAddress, _tokenId);
    //     return assetPairEscrow[_assetPairId].currentParticleCharge(_tokenUuid);
    // }
}