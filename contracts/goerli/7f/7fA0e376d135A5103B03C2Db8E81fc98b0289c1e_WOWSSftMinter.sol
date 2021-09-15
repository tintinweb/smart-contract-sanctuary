// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import '../utils/EnumerableSet.sol';
import '../utils/Address.sol';
import '../utils/Context.sol';

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

  mapping(bytes32 => RoleData) private _roles;

  bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

  /**
   * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
   *
   * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
   * {RoleAdminChanged} not being emitted signaling this.
   *
   * _Available since v3.1._
   */
  event RoleAdminChanged(
    bytes32 indexed role,
    bytes32 indexed previousAdminRole,
    bytes32 indexed newAdminRole
  );

  /**
   * @dev Emitted when `account` is granted `role`.
   *
   * `sender` is the account that originated the contract call, an admin role
   * bearer except when using {_setupRole}.
   */
  event RoleGranted(
    bytes32 indexed role,
    address indexed account,
    address indexed sender
  );

  /**
   * @dev Emitted when `account` is revoked `role`.
   *
   * `sender` is the account that originated the contract call:
   *   - if using `revokeRole`, it is the admin role bearer
   *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
   */
  event RoleRevoked(
    bytes32 indexed role,
    address indexed account,
    address indexed sender
  );

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
  function getRoleMember(bytes32 role, uint256 index)
    public
    view
    returns (address)
  {
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
    require(
      hasRole(_roles[role].adminRole, _msgSender()),
      'AccessControl: sender must be an admin to grant'
    );

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
    require(
      hasRole(_roles[role].adminRole, _msgSender()),
      'AccessControl: sender must be an admin to revoke'
    );

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
    require(
      account == _msgSender(),
      'AccessControl: can only renounce roles for self'
    );

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT AND Apache-2.0

pragma solidity 0.7.6;

/**
 * Utility library of inline functions on addresses
 */
library Address {
  // Default hash for EOA accounts returned by extcodehash
  bytes32 internal constant ACCOUNT_HASH =
    0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract.
   * @param _address address of the account to check
   * @return Whether the target address is a contract
   */
  function isContract(address _address) internal view returns (bool) {
    bytes32 codehash;

    // Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address or if it has a non-zero code hash or account hash
    // solhint-disable-next-line no-inline-assembly
    assembly {
      codehash := extcodehash(_address)
    }
    return (codehash != 0x0 && codehash != ACCOUNT_HASH);
  }

  /**
   * @dev Performs a Solidity function call using a low level `call`.
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
   */
  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(isContract(target), 'Address: No contract');

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.call(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
   * but performing a delegate call.
   */
  function functionDelegateCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(isContract(target), 'Address: No contract');

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.delegatecall(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  function _verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) private pure returns (bytes memory) {
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

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

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

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

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
  function _contains(Set storage set, bytes32 value)
    private
    view
    returns (bool)
  {
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
    require(set._values.length > index, 'EnumerableSet: index out of bounds');
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
  function remove(Bytes32Set storage set, bytes32 value)
    internal
    returns (bool)
  {
    return _remove(set._inner, value);
  }

  /**
   * @dev Returns true if the value is in the set. O(1).
   */
  function contains(Bytes32Set storage set, bytes32 value)
    internal
    view
    returns (bool)
  {
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
  function at(Bytes32Set storage set, uint256 index)
    internal
    view
    returns (bytes32)
  {
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
  function remove(AddressSet storage set, address value)
    internal
    returns (bool)
  {
    return _remove(set._inner, bytes32(uint256(uint160(value))));
  }

  /**
   * @dev Returns true if the value is in the set. O(1).
   */
  function contains(AddressSet storage set, address value)
    internal
    view
    returns (bool)
  {
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
  function at(AddressSet storage set, uint256 index)
    internal
    view
    returns (address)
  {
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
  function contains(UintSet storage set, uint256 value)
    internal
    view
    returns (bool)
  {
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
  function at(UintSet storage set, uint256 index)
    internal
    view
    returns (uint256)
  {
    return uint256(_at(set._inner, index));
  }
}

// SPDX-License-Identifier: MIT AND Apache-2.0

pragma solidity 0.7.6;

import '../interfaces/IERC20.sol';
import '../utils/SafeMath.sol';
import '../utils/Address.sol';

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

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.transfer.selector, to, value)
    );
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
    );
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
    // solhint-disable-next-line max-line-length
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      'SafeERC20: approve from non-zero to non-zero allowance'
    );
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, value)
    );
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
    );
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender).sub(value);
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
    );
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

    bytes memory returndata = address(token).functionCall(
      data,
      'SafeERC20: low-level call failed'
    );
    if (returndata.length > 0) {
      // Return data is optional
      // solhint-disable-next-line max-line-length
      require(
        abi.decode(returndata, (bool)),
        'SafeERC20: ERC20 operation did not succeed'
      );
    }
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
  /**
   * @dev Multiplies two unsigned integers, reverts on overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, 'SafeMath#mul: OVERFLOW');

    return c;
  }

  /**
   * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, 'SafeMath#div: DIVISION_BY_ZERO');
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, 'SafeMath#sub: UNDERFLOW');
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Adds two unsigned integers, reverts on overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath#add: OVERFLOW');

    return c;
  }

  /**
   * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
   * reverts when dividing by zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, 'SafeMath#mod: DIVISION_BY_ZERO');
    return a % b;
  }
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See LICENSE.txt for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

/**
 * @dev Interface to C-folio item contracts
 */
interface IBooster {
  /**
   * @dev return current rewardHandler
   */
  function rewardHandler() external view returns (address);

  /**
   * @dev return current sftHolder
   */
  function sftHolder() external view returns (address);

  /**
   * @dev Return information about the reward state in Booster
   *
   * @param tokenIds The SFT or TF tokenId
   *
   * @return locked The total amounts locked
   * @return pending The pending amounts claimable
   * @return apr The APR of this lock pool
   * @return secsLeft Numbers of seconds until unlock, or -1 if unlocked
   */
  function getRewardInfo(uint256[] calldata tokenIds)
    external
    view
    returns (
      uint256[] memory locked,
      uint256[] memory pending,
      uint256[] memory apr,
      uint256[] memory secsLeft
    );

  /**
   * @dev Create a booster pool from v1 specs
   *
   * @param tokenId The SFT tokenId
   * @param data list of uint256's: total, pending, provided, apr, end, fee
   */
  function migrateCreatePool(uint256 tokenId, bytes memory data)
    external
    returns (bytes memory rData);

  /**
   * @dev Handles farm distribution, only callable from controller
   *
   * If recipient is booster contract, amount is temporarily stored and locked
   * in a second call.
   *
   * @param farm The reward farm that the call originates from
   * @param recipient The recipient of the rewards
   * @param amount The amount to distribute
   * @param fee The fee in 6 decimal notation
   */
  function distributeFromFarm(
    address farm,
    address recipient,
    uint256 amount,
    uint32 fee
  ) external;

  /**
   * @dev Locks temporary tokens owned by recipient for a specific duration
   * of seconds.
   *
   * @param recipient The recipient of the rewards
   * @param lockPeriod The lock period in seconds
   */
  function lock(address recipient, uint256 lockPeriod) external;

  /**
   * @dev Claim rewards either into wallet or re-lock them
   *
   * @param sftTokenId The tokenId that manages the rewards
   * @param reLock True to re-lock existing rewards to earn more
   */
  function claimRewards(uint256 sftTokenId, bool reLock) external;

  /**
   * @dev Set sftHolder contract which is deployed after Booster
   */
  function setSftHolder(address sftHolder_) external;

  /**
   * @dev Set reward handler in case it will be upgraded
   */
  function setRewardHandler(address rewardHandler_) external;
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See LICENSE.txt for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import '../../token/interfaces/ICFolioItemCallback.sol';

/**
 * @dev Interface to C-folio item contracts
 */
interface ICFolioItemHandler is ICFolioItemCallback {
  /**
   * @dev Called when a SFT tokens grade needs re-evaluation
   *
   * @param tokenId The ERC-1155 token ID. Rate is in 1E6 convention: 1E6 = 100%
   * @param newRate The new value rate
   */
  function sftUpgrade(uint256 tokenId, uint32 newRate) external;

  //////////////////////////////////////////////////////////////////////////////
  // Asset access
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Adds investments into a cFolioItem SFT
   *
   * Transfers amounts of assets from users wallet to the contract. In general,
   * an Approval call is required before the function is called.
   *
   * @param from must be msg.sender for calls not from sftMinter
   * @param baseTokenId cFolio tokenId, must be unlocked, or -1
   * @param tokenId cFolioItem tokenId, must be unlocked if not in unlocked cFolio
   * @param amounts Investment amounts, implementation specific
   */
  function deposit(
    address from,
    uint256 baseTokenId,
    uint256 tokenId,
    uint256[] calldata amounts
  ) external;

  /**
   * @dev Removes investments from a cFolioItem SFT
   *
   * Withdrawn token are transfered back to msg.sender.
   *
   * @param baseTokenId cFolio tokenId, must be unlocked, or -1
   * @param tokenId cFolioItem tokenId, must be unlocked if not in unlocked cFolio
   * @param amounts Investment amounts, implementation specific
   */
  function withdraw(
    uint256 baseTokenId,
    uint256 tokenId,
    uint256[] calldata amounts
  ) external;

  /**
   * @dev Update investment values from sidechain
   *
   * Must be called from a registered root tunnel
   *
   * @param tokenId cFolioItem tokenId
   * @param amounts Investment amounts, implementation specific
   */
  function update(uint256 tokenId, uint256[] calldata amounts) external;

  /**
   * @dev Get the rewards collected by an SFT base card
   *
   * Calls only allowed from sftMinter.
   *
   * @param owner The owner of the NFT token
   * @param recipient Recipient of the rewards (- fees)
   * @param tokenId SFT base card tokenId, must be unlocked
   */
  function getRewards(
    address owner,
    address recipient,
    uint256 tokenId
  ) external;

  /**
   * @dev Get amounts (handler specific) for a cfolioItem
   *
   * @param cfolioItem address of CFolioItem contract
   */
  function getAmounts(address cfolioItem)
    external
    view
    returns (uint256[] memory);

  /**
   * @dev Get information obout the rewardFarm
   *
   * @param tokenIds List of basecard tokenIds
   * @return bytes of uint256[]: total, rewardDur, rewardRateForDur, [share, earned]
   */
  function getRewardInfo(uint256[] calldata tokenIds)
    external
    view
    returns (bytes memory);
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See LICENSE.txt for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

// BOIS feature bitmask
uint256 constant LEVEL2BOIS = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000000000000000000000000F;
uint256 constant LEVEL2WOLF = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000000000000000000000000F0;

interface ISFTEvaluator {
  /**
   * @dev Returns the reward in 1e6 factor notation (1e6 = 100%)
   */
  function rewardRate(uint256 sftTokenId) external view returns (uint32);

  /**
   * @dev Calculate the current reward rate, and notify TFC in case of change
   *
   * Optional revert on unchange to save gas on external calls.
   */
  function setRewardRate(uint256 tokenId, bool revertUnchanged) external;
}

/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import '../../0xerc1155/access/AccessControl.sol';
import '../../0xerc1155/interfaces/IERC20.sol';
import '../../0xerc1155/utils/SafeERC20.sol';
import '../../0xerc1155/utils/Context.sol';

import './interfaces/IWOWSSftMinter.sol';

import '../booster/interfaces/IBooster.sol';
import '../cfolio/interfaces/ICFolioItemHandler.sol';
import '../cfolio/interfaces/ISFTEvaluator.sol';
import '../investment/interfaces/IRewardHandler.sol';
import '../token/interfaces/ITradeFloor.sol';
import '../token/interfaces/IWOWSCryptofolio.sol';
import '../token/interfaces/IWOWSERC1155.sol';
import '../utils/AddressBook.sol';
import '../utils/interfaces/IAddressRegistry.sol';
import '../utils/TokenIds.sol';

contract WOWSSftMinter is Context, AccessControl, IWOWSSftMinter {
  using TokenIds for uint256;
  using SafeERC20 for IERC20;

  //////////////////////////////////////////////////////////////////////////////
  // CONSTANTS
  //////////////////////////////////////////////////////////////////////////////

  bytes32 public constant CUSTOM_MINTER_ROLE = bytes32('CUSTOM_MINTER');

  //////////////////////////////////////////////////////////////////////////////
  // State
  //////////////////////////////////////////////////////////////////////////////

  // CFolio NFTs (baseCards)

  // PricePerlevel, customLevel start at 0xFF
  struct BaseLevelData {
    uint16 cap;
    uint256 price;
  }

  // BaseCard Info per level
  mapping(uint16 => BaseLevelData) private _baseLevelData;
  mapping(uint24 => uint16) private _baseCardsMinted;
  uint256 public nextCustomCardId;

  // CFolioItem
  struct CFolioItemSft {
    uint256 handlerId;
    uint256 price;
    uint128 numMinted;
    uint128 maxMintable;
  }
  mapping(uint256 => CFolioItemSft) private cfolioItemSfts; // C-folio type to c-folio data
  ICFolioItemHandler[] private cfolioItemHandlers;
  uint256 public nextCFolioItemNft;

  // The ERC1155 contract we are minting from
  IWOWSERC1155 private immutable _sftContract;

  // WOWS token contract
  IERC20 private immutable _wowsToken;

  // Booster
  IBooster private immutable _booster;

  // Reward handler which distributes WOWS
  IRewardHandler public rewardHandler;

  // TradeFloor Proxy contract
  address public tradeFloor;

  // SFTEvaluator to store the cfolioItemType
  ISFTEvaluator public sftEvaluator;

  // SFTEvaluator to store the cfolioItemType
  address public childTunnel;

  // 1.0 of the rewards go to distribution
  uint32 private constant ALL = 1 * 1e6;

  //////////////////////////////////////////////////////////////////////////////
  // Events
  //////////////////////////////////////////////////////////////////////////////

  // Emitted when constructor is called
  event Constructed(address wowsToken, address sftHolder, address booster);

  // Emitted if a new SFT is minted
  event Mint(
    address indexed recipient,
    uint256 tokenId,
    uint256 price,
    uint256 cfolioType
  );

  // Emitted if base mint specifications (e.g. limits / price) have changed
  event BaseSpecChanged(uint256[] ids);

  // Emitted if cFolio mint specifications (e.g. limits / price) have changed
  event CFolioSpecChanged(uint256[] ids);

  // Emitted if the contract gets destroyed
  event Destruct();

  //////////////////////////////////////////////////////////////////////////////
  // Modifier
  //////////////////////////////////////////////////////////////////////////////

  modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'WM: Only admin');
    _;
  }

  modifier onlyCustomMinter() {
    require(
      hasRole(CUSTOM_MINTER_ROLE, _msgSender()),
      'WM: Only custom minter'
    );
    _;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Contruct WOWSSftMinter
   *
   * @param addressRegistry provides all immutables
   */
  constructor(IAddressRegistry addressRegistry) {
    // Access control (need admin for selfDestruct)
    _setupRole(
      DEFAULT_ADMIN_ROLE,
      addressRegistry.getRegistryEntry(AddressBook.ADMIN_ACCOUNT)
    );

    // Set immutable addresses
    address wowsToken = addressRegistry.getRegistryEntry(
      AddressBook.WOWS_TOKEN
    );
    _wowsToken = IERC20(wowsToken);

    address sftHolder = addressRegistry.getRegistryEntry(
      AddressBook.SFT_HOLDER_PROXY
    );
    _sftContract = IWOWSERC1155(sftHolder);

    address booster = addressRegistry.getRegistryEntry(
      AddressBook.WOWS_BOOSTER_PROXY
    );
    _booster = IBooster(booster);

    emit Constructed(wowsToken, sftHolder, booster);
  }

  function initialize(IAddressRegistry addressRegistry) external {
    // Check for single entry
    require(address(rewardHandler) == address(0), 'WM: Already initialized');

    // Initialize state
    _setupRole(
      DEFAULT_ADMIN_ROLE,
      addressRegistry.getRegistryEntry(AddressBook.ADMIN_ACCOUNT)
    );

    rewardHandler = IRewardHandler(
      addressRegistry.getRegistryEntry(AddressBook.REWARD_HANDLER)
    );

    nextCustomCardId = (1 << 32);
    nextCFolioItemNft = (1 << 64);
  }

  //////////////////////////////////////////////////////////////////////////////
  // State modifiers
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Set prices for the given levels
   */
  function setBaseSpec(
    uint16[] calldata levels,
    uint16[] calldata caps,
    uint256[] calldata prices
  ) external onlyAdmin {
    // Validate parameters
    require(
      levels.length == prices.length && levels.length == caps.length,
      'WM: Length mismatch'
    );

    // Update state
    for (uint256 i = 0; i < levels.length; ++i) {
      _baseLevelData[levels[i]].cap = caps[i];
      _baseLevelData[levels[i]].price = prices[i];
    }
  }

  /**
   * @dev Set new reward handler
   *
   * RewardHandler is by concept upgradeable / see investment::Controller.sol.
   */
  function setRewardHandler(IRewardHandler newRewardHandler)
    external
    onlyAdmin
  {
    // Validate parameters
    require(address(newRewardHandler) != address(0), 'WM: Invalid RH');

    // Update state
    rewardHandler = newRewardHandler;
  }

  /**
   * @dev Set Trade Floor
   */
  function setTradeFloor(address tradeFloor_) external onlyAdmin {
    // Validate parameters
    require(tradeFloor_ != address(0), 'WM: Invalid TF');

    // Update state
    tradeFloor = tradeFloor_;
  }

  /**
   * @dev Set SFT evaluator
   */
  function setSFTEvaluator(ISFTEvaluator sftEvaluator_) external onlyAdmin {
    // Validate parameters
    require(address(sftEvaluator_) != address(0), 'WM: Invalid SFTE');

    // Update state
    sftEvaluator = sftEvaluator_;
  }

  /**
   * @dev Set child tunnel
   */
  function setChildTunnel(address childTunnel_) external onlyAdmin {
    // Validate parameters
    require(childTunnel_ != address(0), 'WM: Invalid CT');

    // Update state
    childTunnel = childTunnel_;
  }

  /**
   * @dev Set the limitations, the price and the handlers for CFolioItem SFT's
   */
  function setCFolioSpec(
    uint256[] calldata cFolioTypes,
    address[] calldata handlers,
    uint128[] calldata maxMint,
    uint256[] calldata prices
  ) external onlyAdmin {
    // Validate parameters
    require(
      cFolioTypes.length == handlers.length &&
        handlers.length == maxMint.length &&
        maxMint.length == prices.length,
      'WM: Length mismatch'
    );

    // Update state
    delete (cfolioItemHandlers);

    for (uint256 i = 0; i < cFolioTypes.length; ++i) {
      uint256 j = 0;
      for (; j < cfolioItemHandlers.length; ++j) {
        if (address(cfolioItemHandlers[j]) == handlers[i]) break;
      }

      if (j == cfolioItemHandlers.length) {
        cfolioItemHandlers.push(ICFolioItemHandler(handlers[i]));
      }

      CFolioItemSft storage cfi = cfolioItemSfts[cFolioTypes[i]];
      cfi.handlerId = j;
      cfi.maxMintable = maxMint[i];
      cfi.price = prices[i];
    }
    emit CFolioSpecChanged(cFolioTypes);
  }

  /**
   * @dev upgrades state from an existing WOWSSFTMinter
   */
  function destructContract() external onlyAdmin {
    emit Destruct();

    // Disable high-impact Slither detector "suicidal" here. Slither explains
    // that "WOWSSftMinter.destructContract() allows anyone to destruct the
    // contract", which is not the case due to the {Ownable-onlyOwner} modifier.
    //
    // slither-disable-next-line suicidal
    selfdestruct(_msgSender());
  }

  /**
   * @dev Mint one of our stock card SFTs
   *
   * Approval of WOWS token required before the call.
   */
  function mintWowsSFT(
    address recipient,
    uint8 level,
    uint8 cardId
  ) external {
    // Validate parameters
    require(recipient != address(0), 'WM: Invalid recipient');
    require(childTunnel == address(0), 'WM: Only rootchain');

    // Load state
    uint256 price = _baseLevelData[level].price;
    (uint24 bcmId, uint16 minted) = _getBaseCardsMinted(level, cardId);

    // Validate state
    require(price > 0, 'WM: No price available');
    require(minted < _baseLevelData[level].cap, 'WM: Sold out');

    // Calculate the tokenId
    uint256 baseTokenId = ((uint256(level) << 8) | cardId) << 16;

    _baseCardsMinted[bcmId]++;

    // Update state
    _mint(recipient, baseTokenId + minted, price, 0, '');
  }

  /**
   * @dev Mint a custom token
   *
   * Approval of WOWS token required before the call.
   */
  function mintCustomSFT(address recipient, uint8 level)
    external
    onlyCustomMinter
  {
    // Validate parameters
    require(recipient != address(0), 'WM: Invalid recipient');

    // Load state
    uint256 price = _baseLevelData[uint16(level) << 8].price;

    // Validate state
    require(price > 0, 'WM: No price available');

    // Get the next free mintable custom card Id
    uint256 tokenId = nextCustomCardId++;

    // Custom baseToken only allowed < 64Bit
    require(tokenId.isBaseCard(), 'WM: Max tokenId reached');

    // Set card level
    _sftContract.setCustomCardLevel(tokenId, level);

    // Update state
    _mint(recipient, tokenId, price, 0, '');
  }

  /**
   * @dev Mint a CFolioItem token
   *
   * Approval of WOWS token required before the call.
   *
   * @param cfolioItemType The item type of the SFT
   * @param sftTokenId If <> -1 recipient is the SFT c-folio / handler must be called
   * @param investAmounts Arguments needed for the handler (in general investments).
   * Investments may be zero if the user is just buying an SFT.
   */
  function mintCFolioItemSFT(
    uint256 cfolioItemType,
    uint256 sftTokenId,
    uint256[] calldata investAmounts
  ) external override returns (uint256 tokenId) {
    // Load state
    CFolioItemSft storage sftData = cfolioItemSfts[cfolioItemType];

    // Validate state
    require(sftData.numMinted < sftData.maxMintable, 'WM: Sold out (CFI)');

    // Mint by default to sender
    address recipient = _msgSender();

    if (sftTokenId != uint256(-1)) {
      require(sftTokenId.isBaseCard(), 'WM: Invalid baseId');

      // Get the CFolio contract address, it will be the final recipient
      recipient = _sftContract.tokenIdToAddress(sftTokenId);
      require(recipient != address(0), 'WM: Bad baseId');
    }

    tokenId = nextCFolioItemNft++;
    require(tokenId.isCFolioCard(), 'WM: Invalid cfiId');

    _sftContract.setCFolioItemType(tokenId, cfolioItemType);

    ICFolioItemHandler handler = cfolioItemHandlers[sftData.handlerId];

    // Update state, mint SFT token
    sftData.numMinted += 1;
    _mint(
      recipient,
      tokenId,
      msg.sender == childTunnel ? 0 : sftData.price,
      cfolioItemType,
      abi.encodePacked(handler)
    );

    if (investAmounts.length > 0) {
      handler.deposit(_msgSender(), sftTokenId, tokenId, investAmounts);
    }
  }

  /**
   * @dev Claim rewards from all c-folio farms
   *
   * If lockPeriod > 0, Booster locks the token on behalf of sftToken and
   * provides extra rewards. Otherwise rewards are distributed in
   * rewardHandler.
   *
   * @param sftTokenId Valid SFT tokenId, must not be locked in TF
   * @param lockPeriod Lock time in seconds
   */
  function claimSFTRewards(uint256 sftTokenId, uint256 lockPeriod) external {
    // If lockPeriod > 0 rewards are managed by booster
    address cfolio = _sftContract.tokenIdToAddress(sftTokenId);
    require(cfolio != address(0), 'WM: Invalid cfolio');

    address receiver = lockPeriod > 0 ? cfolio : _msgSender();

    bool[] memory lookup = new bool[](cfolioItemHandlers.length);
    uint256[] memory cfolioItems = _sftContract.getTokenIds(cfolio);
    uint256 cfolioLength = cfolioItems.length;

    for (uint256 i = 0; i < cfolioLength; ++i) {
      // Get the handler of this type
      uint256 handlerId = cfolioItemSfts[
        _sftContract.getCFolioItemType(cfolioItems[i])
      ].handlerId;
      if (!lookup[handlerId]) {
        cfolioItemHandlers[handlerId].getRewards(
          _msgSender(),
          receiver,
          sftTokenId
        );
        lookup[handlerId] = true;
      }
    }

    // In case lockPeriod is set, all rewards are temporarily parked in
    // booster. Lock the parked rewards for the current msg.sender.
    if (lockPeriod > 0) {
      _booster.lock(receiver, lockPeriod);
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  // ERC1155Holder
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev We are a temorary token holder during CFolioToken mint step
   *
   * Only accept ERC1155 tokens during this setup.
   */
  function onERC1155Received(
    address operator,
    address,
    uint256,
    uint256,
    bytes memory
  ) external view returns (bytes4) {
    // Validate state
    require(operator == address(this), 'WM: Not allowed');

    // Call ancestor
    return this.onERC1155Received.selector;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Getters
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Query prices for given levels
   */
  function getBaseSpec(uint8[] calldata levels, uint8[] calldata cardIds)
    external
    view
    returns (
      uint256[] memory prices,
      uint16[] memory numMinted,
      uint16[] memory maxMintable
    )
  {
    require(levels.length == cardIds.length, 'WM: Length mismatch');

    prices = new uint256[](levels.length);
    numMinted = new uint16[](levels.length);
    maxMintable = new uint16[](levels.length);

    for (uint256 i = 0; i < levels.length; ++i) {
      prices[i] = _baseLevelData[levels[i]].price;
      maxMintable[i] = _baseLevelData[levels[i]].cap;
      (, numMinted[i]) = _getBaseCardsMinted(levels[i], cardIds[i]);
    }
  }

  /**
   * @dev retrieve mint information about cfolioItem
   */
  function getCFolioSpec(uint256[] calldata cFolioTypes)
    external
    view
    returns (
      uint256[] memory prices,
      uint128[] memory numMinted,
      uint128[] memory maxMintable
    )
  {
    uint256 length = cFolioTypes.length;
    prices = new uint256[](length);
    numMinted = new uint128[](length);
    maxMintable = new uint128[](length);

    for (uint256 i; i < length; ++i) {
      CFolioItemSft storage cfi = cfolioItemSfts[cFolioTypes[i]];
      prices[i] = cfi.price;
      numMinted[i] = cfi.numMinted;
      maxMintable[i] = cfi.maxMintable;
    }
  }

  /**
   * @dev Get all tokenIds from SFT and TF contract owned by account.
   */
  function getTokenIds(address account)
    external
    view
    returns (uint256[] memory sftTokenIds, uint256[] memory tfTokenIds)
  {
    require(account != address(0), 'Null address');
    sftTokenIds = _sftContract.getTokenIds(account);
    tfTokenIds = ITradeFloor(tradeFloor).getTokenIds(account);
  }

  /**
   * @dev Get underlying information (cFolioItems / value) for given tokenIds.
   *
   * @param tokenIds the tokenIds information should be queried
   * @return result [%,MintTime,NumItems,[tokenId,type,numAssetValues,[assetValue]]]...
   */
  function getTokenInformation(uint256[] calldata tokenIds)
    external
    view
    returns (bytes memory result)
  {
    uint256[] memory cfolioItems;
    uint256[] memory oneCfolioItem = new uint256[](1);
    uint256 cfolioLength;
    uint256 rewardRate;
    uint256 timestamp;

    for (uint256 i = 0; i < tokenIds.length; ++i) {
      if (tokenIds[i].isBaseCard()) {
        // Only main TradeFloor supported
        uint256 sftTokenId = tokenIds[i].toSftTokenId();
        address cfolio = _sftContract.tokenIdToAddress(sftTokenId);
        require(cfolio != address(0), 'WM: Invalid cfi');

        cfolioItems = _sftContract.getTokenIds(cfolio);
        cfolioLength = cfolioItems.length;

        rewardRate = sftEvaluator.rewardRate(tokenIds[i]);
        (timestamp, ) = _sftContract.getTokenData(sftTokenId);
      } else {
        oneCfolioItem[0] = tokenIds[i];
        cfolioLength = 1;
        cfolioItems = oneCfolioItem; // Reference, no copy
        rewardRate = 0;
        timestamp = 0;
      }

      result = abi.encodePacked(result, rewardRate, timestamp, cfolioLength);

      for (uint256 j = 0; j < cfolioLength; ++j) {
        uint256 tokenId = cfolioItems[j];
        uint256 cfolioType = _sftContract.getCFolioItemType(tokenId);
        uint256[] memory amounts;

        address cfolio = _sftContract.tokenIdToAddress(tokenId);
        require(address(cfolio) != address(0), 'WM: Invalid cfi');

        address handler = IWOWSCryptofolio(cfolio).handler();
        amounts = ICFolioItemHandler(handler).getAmounts(cfolio);

        result = abi.encodePacked(
          result,
          cfolioItems[j],
          cfolioType,
          amounts.length,
          amounts
        );
      }
    }
  }

  /**
   * @dev Get CFIItemHandlerRewardInfo and Booster rewardInfo.
   */
  function getRewardInfo(address cfih, uint256[] calldata tokenIds)
    external
    view
    returns (
      bytes memory result,
      uint256[] memory boosterLocked,
      uint256[] memory boosterPending,
      uint256[] memory boosterApr,
      uint256[] memory boosterSecsLeft
    )
  {
    result = ICFolioItemHandler(cfih).getRewardInfo(tokenIds);
    (boosterLocked, boosterPending, boosterApr, boosterSecsLeft) = _booster
      .getRewardInfo(tokenIds);
  }

  /**
   * @dev Get balances of given ERC20 addresses.
   */
  function getErc20Balances(address account, address[] calldata erc20)
    external
    view
    returns (uint256[] memory amounts)
  {
    amounts = new uint256[](erc20.length);
    for (uint256 i = 0; i < erc20.length; ++i)
      amounts[i] = erc20[i] == address(0)
        ? 0
        : IERC20(erc20[i]).balanceOf(account);
  }

  /**
   * @dev Get allowances of given ERC20 addresses.
   */
  function getErc20Allowances(
    address account,
    address[] calldata spender,
    address[] calldata erc20
  ) external view returns (uint256[] memory amounts) {
    // Validate parameters
    require(spender.length == erc20.length, 'Length mismatch');

    amounts = new uint256[](spender.length);
    for (uint256 i = 0; i < spender.length; ++i)
      amounts[i] = erc20[i] == address(0)
        ? 0
        : IERC20(erc20[i]).allowance(account, spender[i]);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Internal functionality
  //////////////////////////////////////////////////////////////////////////////

  function _mint(
    address recipient,
    uint256 tokenId,
    uint256 price,
    uint256 cfolioType,
    bytes memory data
  ) internal {
    // Transfer WOWS from user to reward handler
    if (price > 0)
      _wowsToken.safeTransferFrom(_msgSender(), address(rewardHandler), price);

    // Mint the token
    uint256[] memory tokenIds = new uint256[](1);
    tokenIds[0] = tokenId;
    _sftContract.mintBatch(recipient, tokenIds, data);

    // Distribute the rewards
    if (price > 0) rewardHandler.distribute2(recipient, price, ALL);

    // Log event
    emit Mint(recipient, tokenId, price, cfolioType);
  }

  /**
   * @dev Get the number of cards that have been minted
   *
   * @param level The level of cards to check
   * @param cardId The ID of cards to check
   *
   * @return bcmLevelId the idx for direct access to _baseCardsMinted
   * @return cardsMinted The number of cards that have been minted
   */
  function _getBaseCardsMinted(uint16 level, uint8 cardId)
    private
    view
    returns (uint24 bcmLevelId, uint16 cardsMinted)
  {
    bcmLevelId = (uint24(level) << 8) | cardId;
    cardsMinted = _baseCardsMinted[bcmLevelId];
  }
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See LICENSE.txt for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

/**
 * @dev Interface to WOWS SFT minter item contracts
 */
interface IWOWSSftMinter {
  /**
   * @dev Mint a CFolioItem token
   *
   * Approval of WOWS token required before the call.
   *
   * @param cfolioItemType The item type of the SFT
   * @param sftTokenId If <> -1 recipient is the SFT c-folio / handler must be called
   * @param investAmounts Arguments needed for the handler (in general investments).
   * Investments may be zero if the user is just buying an SFT.
   */
  function mintCFolioItemSFT(
    uint256 cfolioItemType,
    uint256 sftTokenId,
    uint256[] calldata investAmounts
  ) external returns (uint256 tokenId);
}

/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity 0.7.6;

interface IRewardHandler {
  /**
   * @dev Get the amount allocated for the Booster
   *
   * @return The amount which is allocated for the Booster (18 decimals)
   */
  function getBoosterRewards() external view returns (uint256);

  /**
   * @dev Transfer reward and distribute the fee
   *
   * This is the new implementation of distribute() which uses internal fees
   * defined in the {RewardHandler} contract.
   *
   * @param recipient The recipient of the reward
   * @param amount The amount of WOWS to transfer to the recipient
   * @param fee The reward fee in 1e6 factor notation
   */
  function distribute2(
    address recipient,
    uint256 amount,
    uint32 fee
  ) external;

  /**
   * @dev Transfer reward and distribute the fee
   *
   * This is the current implementation, needed for backward compatibility.
   *
   * Current ERC1155Minter and Controller call this function, later
   * reward handler clients should call the the new one with internal
   * fees specified in this contract.
   *
   * uint32 values are in 1e6 factor notation.
   */
  function distribute(
    address recipient,
    uint256 amount,
    uint32 fee,
    uint32 toTeam,
    uint32 toMarketing,
    uint32 toBooster,
    uint32 toRewardPool
  ) external;
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See LICENSE.txt for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

/**
 * @dev Interface to receive callbacks when minted tokens are burnt
 */
interface ICFolioItemCallback {
  /**
   * @dev Called when a TradeFloor CFolioItem is transfered
   *
   * In case of mint `from` is address(0).
   * In case of burn `to` is address(0).
   *
   * cfolioHandlers are passed to let each cfolioHandler filter for its own
   * token. This eliminates the need for creating separate lists.
   *
   * @param from The account sending the token
   * @param to The account receiving the token
   * @param tokenIds The ERC-1155 token IDs
   * @param cfolioHandlers cFolioItem handlers
   */
  function onCFolioItemsTransferedFrom(
    address from,
    address to,
    uint256[] calldata tokenIds,
    address[] calldata cfolioHandlers
  ) external;

  /**
   * @dev Append data we use later for hashing
   *
   * @param cfolioItem The token ID of the c-folio item
   * @param current The current data being hashes
   *
   * @return The current data, with internal data appended
   */
  function appendHash(address cfolioItem, bytes calldata current)
    external
    view
    returns (bytes memory);
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

/**
 * @notice Cryptofolio and tokenId interface
 */
interface ITradeFloor {
  //////////////////////////////////////////////////////////////////////////////
  // Getters
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Return all tokenIds owned by account
   */
  function getTokenIds(address account)
    external
    view
    returns (uint256[] memory);
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

/**
 * @notice Cryptofolio interface
 */
interface IWOWSCryptofolio {
  //////////////////////////////////////////////////////////////////////////////
  // Getter
  //////////////////////////////////////////////////////////////////////////////
  /**
   * @dev Return the handler (CFIH) of the underlying NFT
   */
  function handler() external view returns (address);

  //////////////////////////////////////////////////////////////////////////////
  // State modifiers
  //////////////////////////////////////////////////////////////////////////////
  /**
   * @dev Set the handler of the underlying NFT
   *
   * This function is called during I-NFT setup
   *
   * @param newHandler The new handler of the underlying NFT,
   */
  function setHandler(address newHandler) external;
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

/**
 * @notice Sft holder contract
 */
interface IWOWSERC1155 {
  //////////////////////////////////////////////////////////////////////////////
  // Getters
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Get the token ID of a given address
   *
   * A cross check is required because token ID 0 is valid.
   *
   * @param tokenAddress The address to convert to a token ID
   *
   * @return The token ID on success, or uint256(-1) if `tokenAddress` does not
   * belong to a token ID
   */
  function addressToTokenId(address tokenAddress)
    external
    view
    returns (uint256);

  /**
   * @dev Get the address for a given token ID
   *
   * @param tokenId The token ID to convert
   *
   * @return The address, or address(0) in case the token ID does not belong
   * to an NFT
   */
  function tokenIdToAddress(uint256 tokenId) external view returns (address);

  /**
   * @dev Return the level and the mint timestamp of tokenId
   *
   * @param tokenId The tokenId to query
   *
   * @return mintTimestamp The timestamp token was minted
   * @return level The level token belongs to
   */
  function getTokenData(uint256 tokenId)
    external
    view
    returns (uint64 mintTimestamp, uint8 level);

  /**
   * @dev Return all tokenIds owned by account
   */
  function getTokenIds(address account)
    external
    view
    returns (uint256[] memory);

  /**
   * @dev Returns the cFolioItemType of a given cFolioItem tokenId
   */
  function getCFolioItemType(uint256 tokenId) external view returns (uint256);

  /**
   * @notice Get the balance of an account's Tokens
   * @param owner  The address of the token holder
   * @param tokenId ID of the Token
   * @return The _owner's balance of the token type requested
   */
  function balanceOf(address owner, uint256 tokenId)
    external
    view
    returns (uint256);

  /**
   * @notice Get the balance of multiple account/token pairs
   * @param owners The addresses of the token holders
   * @param tokenIds ID of the Tokens
   * @return       The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
   */
  function balanceOfBatch(
    address[] calldata owners,
    uint256[] calldata tokenIds
  ) external view returns (uint256[] memory);

  //////////////////////////////////////////////////////////////////////////////
  // State modifiers
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @notice Mints tokenIds into 'to' account
   * @dev Emits SftTokenTransfer Event
   *
   * Throws if sender has no MINTER_ROLE
   * 'data' holds the CFolioItemHandler if CFI's are minted
   */
  function mintBatch(
    address to,
    uint256[] calldata tokenIds,
    bytes calldata data
  ) external;

  /**
   * @notice Burns tokenIds owned by 'account'
   * @dev Emits SftTokenTransfer Event
   *
   * Burns all owned CFolioItems
   * Throws if CFolioItems have assets
   */
  function burnBatch(address account, uint256[] calldata tokenIds) external;

  /**
   * @notice Transfers amount of an id from the from address to the 'to' address specified
   * @dev Emits SftTokenTransfer Event
   * Throws if 'to' is the zero address
   * Throws if 'from' is not the current owner
   * If 'to' is a smart contract, ERC1155TokenReceiver interface will checked
   * @param from    Source address
   * @param to      Target address
   * @param tokenId ID of the token type
   * @param amount  Transfered amount
   * @param data    Additional data with no specified format, sent in call to `_to`
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    uint256 amount,
    bytes calldata data
  ) external;

  /**
   * @dev Batch version of {safeTransferFrom}
   */
  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts,
    bytes calldata data
  ) external;

  /**
   * @dev Each custom card has its own level. Level will be used when
   * calculating rewards and raiding power.
   *
   * @param tokenId The ID of the token whose level is being set
   * @param cardLevel The new level of the specified token
   */
  function setCustomCardLevel(uint256 tokenId, uint8 cardLevel) external;

  /**
   * @dev Sets the cfolioItemType of a cfolioItem tokenId, not yet used
   * sftHolder tokenId expected (without hash)
   */
  function setCFolioItemType(uint256 tokenId, uint256 cfolioItemType_) external;

  /**
   * @dev Sets external NFT for display tokenId
   * By default NFT is rendered using our internal metadata
   *
   * Throws if not called from MINTER role
   */
  function setExternalNft(
    uint256 tokenId,
    address externalCollection,
    uint256 externalTokenId
  ) external;

  /**
   * @dev Deletes external NFT settings
   *
   * Throws if not called from MINTER role
   */
  function deleteExternalNft(uint256 tokenId) external;
}

/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

library AddressBook {
  bytes32 public constant DEPLOYER = 'DEPLOYER';
  bytes32 public constant TEAM_WALLET = 'TEAM_WALLET';
  bytes32 public constant MARKETING_WALLET = 'MARKETING_WALLET';
  bytes32 public constant ADMIN_ACCOUNT = 'ADMIN_ACCOUNT';
  bytes32 public constant UNISWAP_V2_ROUTER02 = 'UNISWAP_V2_ROUTER02';
  bytes32 public constant WETH_WOWS_STAKE_FARM = 'WETH_WOWS_STAKE_FARM';
  bytes32 public constant WOWS_TOKEN = 'WOWS_TOKEN';
  bytes32 public constant UNISWAP_V2_PAIR = 'UNISWAP_V2_PAIR';
  bytes32 public constant WOWS_BOOSTER_PROXY = 'WOWS_BOOSTER_PROXY';
  bytes32 public constant REWARD_HANDLER = 'REWARD_HANDLER';
  bytes32 public constant SFT_MINTER_PROXY = 'SFT_MINTER_PROXY';
  bytes32 public constant SFT_HOLDER_PROXY = 'SFT_HOLDER_PROXY';
  bytes32 public constant BOIS_REWARDS = 'BOIS_REWARDS';
  bytes32 public constant WOLVES_REWARDS = 'WOLVES_REWARDS';
  bytes32 public constant SFT_EVALUATOR_PROXY = 'SFT_EVALUATOR_PROXY';
  bytes32 public constant TRADE_FLOOR_PROXY = 'TRADE_FLOOR_PROXY';
  bytes32 public constant CURVE_Y_TOKEN = 'CURVE_Y_TOKEN';
  bytes32 public constant CURVE_Y_DEPOSIT = 'CURVE_Y_DEPOSIT';
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See LICENSE.txt for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

library TokenIds {
  // 128 bit underlying hash
  uint256 public constant HASH_MASK = (1 << 128) - 1;

  function isBaseCard(uint256 tokenId) internal pure returns (bool) {
    return (tokenId & HASH_MASK) < (1 << 64);
  }

  function isStockCard(uint256 tokenId) internal pure returns (bool) {
    return (tokenId & HASH_MASK) < (1 << 32);
  }

  function isCustomCard(uint256 tokenId) internal pure returns (bool) {
    return
      (tokenId & HASH_MASK) >= (1 << 32) && (tokenId & HASH_MASK) < (1 << 64);
  }

  function isCFolioCard(uint256 tokenId) internal pure returns (bool) {
    return
      (tokenId & HASH_MASK) >= (1 << 64) && (tokenId & HASH_MASK) < (1 << 128);
  }

  function toSftTokenId(uint256 tokenId) internal pure returns (uint256) {
    return tokenId & HASH_MASK;
  }

  function maskHash(uint256 tokenId) internal pure returns (uint256) {
    return tokenId & ~HASH_MASK;
  }
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

interface IAddressRegistry {
  /**
   * @dev Set an abitrary key / address pair into the registry
   */
  function setRegistryEntry(bytes32 _key, address _location) external;

  /**
   * @dev Get a registry enty with by key, returns 0 address if not existing
   */
  function getRegistryEntry(bytes32 _key) external view returns (address);
}

{
  "evmVersion": "berlin",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 1000
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}