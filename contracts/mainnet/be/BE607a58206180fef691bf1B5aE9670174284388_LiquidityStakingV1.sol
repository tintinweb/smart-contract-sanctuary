// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import './Context.sol';
import './Strings.sol';
import './ERC165.sol';

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
  function hasRole(bytes32 role, address account) external view returns (bool);

  function getRoleAdmin(bytes32 role) external view returns (bytes32);

  function grantRole(bytes32 role, address account) external;

  function revokeRole(bytes32 role, address account) external;

  function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
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
abstract contract AccessControlUpgradeable is Context, IAccessControlUpgradeable, ERC165 {
  struct RoleData {
    mapping(address => bool) members;
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
   * @dev Modifier that checks that an account has a specific role. Reverts
   * with a standardized message including the required role.
   *
   * The format of the revert reason is given by the following regular expression:
   *
   *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
   *
   * _Available since v4.1._
   */
  modifier onlyRole(bytes32 role) {
    _checkRole(role, _msgSender());
    _;
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return
      interfaceId == type(IAccessControlUpgradeable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev Returns `true` if `account` has been granted `role`.
   */
  function hasRole(bytes32 role, address account) public view override returns (bool) {
    return _roles[role].members[account];
  }

  /**
   * @dev Revert with a standard message if `account` is missing `role`.
   *
   * The format of the revert reason is given by the following regular expression:
   *
   *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
   */
  function _checkRole(bytes32 role, address account) internal view {
    if (!hasRole(role, account)) {
      revert(
        string(
          abi.encodePacked(
            'AccessControl: account ',
            Strings.toHexString(uint160(account), 20),
            ' is missing role ',
            Strings.toHexString(uint256(role), 32)
          )
        )
      );
    }
  }

  /**
   * @dev Returns the admin role that controls `role`. See {grantRole} and
   * {revokeRole}.
   *
   * To change a role's admin, use {_setRoleAdmin}.
   */
  function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
  function grantRole(bytes32 role, address account)
    public
    virtual
    override
    onlyRole(getRoleAdmin(role))
  {
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
  function revokeRole(bytes32 role, address account)
    public
    virtual
    override
    onlyRole(getRoleAdmin(role))
  {
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
  function renounceRole(bytes32 role, address account) public virtual override {
    require(account == _msgSender(), 'AccessControl: can only renounce roles for self');

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
    emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
    _roles[role].adminRole = adminRole;
  }

  function _grantRole(bytes32 role, address account) private {
    if (!hasRole(role, account)) {
      _roles[role].members[account] = true;
      emit RoleGranted(role, account, _msgSender());
    }
  }

  function _revokeRole(bytes32 role, address account) private {
    if (hasRole(role, account)) {
      _roles[role].members[account] = false;
      emit RoleRevoked(role, account, _msgSender());
    }
  }

  uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

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
pragma solidity 0.7.5;

/**
 * @dev String operations.
 */
library Strings {
  bytes16 private constant alphabet = '0123456789abcdef';

  /**
   * @dev Converts a `uint256` to its ASCII `string` decimal representation.
   */
  function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT licence
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

    if (value == 0) {
      return '0';
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }

  /**
   * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
   */
  function toHexString(uint256 value) internal pure returns (string memory) {
    if (value == 0) {
      return '0x00';
    }
    uint256 temp = value;
    uint256 length = 0;
    while (temp != 0) {
      length++;
      temp >>= 8;
    }
    return toHexString(value, length);
  }

  /**
   * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
   */
  function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
    bytes memory buffer = new bytes(2 * length + 2);
    buffer[0] = '0';
    buffer[1] = 'x';
    for (uint256 i = 2 * length + 1; i > 1; --i) {
      buffer[i] = alphabet[value & 0xf];
      value >>= 4;
    }
    require(value == 0, 'Strings: hex length insufficient');
    return string(buffer);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import './IERC165.sol';

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IERC165).interfaceId;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.5;
pragma abicoder v2;

import {
  AccessControlUpgradeable
} from '../../../dependencies/open-zeppelin/AccessControlUpgradeable.sol';
import { ReentrancyGuard } from '../../../utils/ReentrancyGuard.sol';
import { VersionedInitializable } from '../../../utils/VersionedInitializable.sol';
import { LS1Types } from '../lib/LS1Types.sol';

/**
 * @title LS1Storage
 * @author dYdX
 *
 * @dev Storage contract. Contains or inherits from all contract with storage.
 */
abstract contract LS1Storage is
  AccessControlUpgradeable,
  ReentrancyGuard,
  VersionedInitializable
{
  // ============ Epoch Schedule ============

  /// @dev The parameters specifying the function from timestamp to epoch number.
  LS1Types.EpochParameters internal _EPOCH_PARAMETERS_;

  /// @dev The period of time at the end of each epoch in which withdrawals cannot be requested.
  ///  We also restrict other changes which could affect borrowers' repayment plans, such as
  ///  modifications to the epoch schedule, or to borrower allocations.
  uint256 internal _BLACKOUT_WINDOW_;

  // ============ Staked Token ERC20 ============

  mapping(address => mapping(address => uint256)) internal _ALLOWANCES_;

  // ============ Rewards Accounting ============

  /// @dev The emission rate of rewards.
  uint256 internal _REWARDS_PER_SECOND_;

  /// @dev The cumulative rewards earned per staked token. (Shared storage slot.)
  uint224 internal _GLOBAL_INDEX_;

  /// @dev The timestamp at which the global index was last updated. (Shared storage slot.)
  uint32 internal _GLOBAL_INDEX_TIMESTAMP_;

  /// @dev The value of the global index when the user's staked balance was last updated.
  mapping(address => uint256) internal _USER_INDEXES_;

  /// @dev The user's accrued, unclaimed rewards (as of the last update to the user index).
  mapping(address => uint256) internal _USER_REWARDS_BALANCES_;

  /// @dev The value of the global index at the end of a given epoch.
  mapping(uint256 => uint256) internal _EPOCH_INDEXES_;

  // ============ Staker Accounting ============

  /// @dev The active balance by staker.
  mapping(address => LS1Types.StoredBalance) internal _ACTIVE_BALANCES_;

  /// @dev The total active balance of stakers.
  LS1Types.StoredBalance internal _TOTAL_ACTIVE_BALANCE_;

  /// @dev The inactive balance by staker.
  mapping(address => LS1Types.StoredBalance) internal _INACTIVE_BALANCES_;

  /// @dev The total inactive balance of stakers. Note: The shortfallCounter field is unused.
  LS1Types.StoredBalance internal _TOTAL_INACTIVE_BALANCE_;

  /// @dev Information about shortfalls that have occurred.
  LS1Types.Shortfall[] internal _SHORTFALLS_;

  // ============ Borrower Accounting ============

  /// @dev The units allocated to each borrower.
  /// @dev Values are represented relative to total allocation, i.e. as hundredeths of a percent.
  ///  Also, the total of the values contained in the mapping must always equal the total
  ///  allocation (i.e. must sum to 10,000).
  mapping(address => LS1Types.StoredAllocation) internal _BORROWER_ALLOCATIONS_;

  /// @dev The token balance currently borrowed by the borrower.
  mapping(address => uint256) internal _BORROWED_BALANCES_;

  /// @dev The total token balance currently borrowed by borrowers.
  uint256 internal _TOTAL_BORROWED_BALANCE_;

  /// @dev Indicates whether a borrower is restricted from new borrowing.
  mapping(address => bool) internal _BORROWER_RESTRICTIONS_;

  // ============ Debt Accounting ============

  /// @dev The debt balance owed to each staker.
  mapping(address => uint256) internal _STAKER_DEBT_BALANCES_;

  /// @dev The debt balance by borrower.
  mapping(address => uint256) internal _BORROWER_DEBT_BALANCES_;

  /// @dev The total debt balance of borrowers.
  uint256 internal _TOTAL_BORROWER_DEBT_BALANCE_;

  /// @dev The total debt amount repaid and not yet withdrawn.
  uint256 internal _TOTAL_DEBT_AVAILABLE_TO_WITHDRAW_;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.5;
pragma abicoder v2;

/**
 * @title ReentrancyGuard
 * @author dYdX
 *
 * @dev Updated ReentrancyGuard library designed to be used with Proxy Contracts.
 */
abstract contract ReentrancyGuard {
  uint256 private constant NOT_ENTERED = 1;
  uint256 private constant ENTERED = uint256(int256(-1));

  uint256 private _STATUS_;

  constructor()
    internal
  {
    _STATUS_ = NOT_ENTERED;
  }

  modifier nonReentrant() {
    require(_STATUS_ != ENTERED, 'ReentrancyGuard: reentrant call');
    _STATUS_ = ENTERED;
    _;
    _STATUS_ = NOT_ENTERED;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;

/**
 * @title VersionedInitializable
 * @author Aave, inspired by the OpenZeppelin Initializable contract
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 *
 */
abstract contract VersionedInitializable {
    /**
   * @dev Indicates that the contract has been initialized.
   */
    uint256 internal lastInitializedRevision = 0;

   /**
   * @dev Modifier to use in the initializer function of a contract.
   */
    modifier initializer() {
        uint256 revision = getRevision();
        require(revision > lastInitializedRevision, "Contract instance has already been initialized");

        lastInitializedRevision = revision;

        _;

    }

    /// @dev returns the revision number of the contract.
    /// Needs to be defined in the inherited class as a constant.
    function getRevision() internal pure virtual returns(uint256);


    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.5;
pragma abicoder v2;

/**
 * @title LS1Types
 * @author dYdX
 *
 * @dev Structs used by the LiquidityStaking contract.
 */
library LS1Types {
  /**
   * @dev The parameters used to convert a timestamp to an epoch number.
   */
  struct EpochParameters {
    uint128 interval;
    uint128 offset;
  }

  /**
   * @dev The parameters representing a shortfall event.
   *
   * @param  index  Fraction of inactive funds converted into debt, scaled by SHORTFALL_INDEX_BASE.
   * @param  epoch  The epoch in which the shortfall occurred.
   */
  struct Shortfall {
    uint16 epoch; // Note: Supports at least 1000 years given min epoch length of 6 days.
    uint224 index; // Note: Save on contract bytecode size by reusing uint224 instead of uint240.
  }

  /**
   * @dev A balance, possibly with a change scheduled for the next epoch.
   *  Also includes cached index information for inactive balances.
   *
   * @param  currentEpoch         The epoch in which the balance was last updated.
   * @param  currentEpochBalance  The balance at epoch `currentEpoch`.
   * @param  nextEpochBalance     The balance at epoch `currentEpoch + 1`.
   * @param  shortfallCounter     Incrementing counter of the next shortfall index to be applied.
   */
  struct StoredBalance {
    uint16 currentEpoch; // Supports at least 1000 years given min epoch length of 6 days.
    uint112 currentEpochBalance;
    uint112 nextEpochBalance;
    uint16 shortfallCounter; // Only for staker inactive balances. At most one shortfall per epoch.
  }

  /**
   * @dev A borrower allocation, possibly with a change scheduled for the next epoch.
   */
  struct StoredAllocation {
    uint16 currentEpoch; // Note: Supports at least 1000 years given min epoch length of 6 days.
    uint120 currentEpochAllocation;
    uint120 nextEpochAllocation;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { SafeMath } from '../../../dependencies/open-zeppelin/SafeMath.sol';
import { Math } from '../../../utils/Math.sol';
import { LS1Types } from '../lib/LS1Types.sol';
import { LS1Storage } from './LS1Storage.sol';

/**
 * @title LS1Getters
 * @author dYdX
 *
 * @dev Some external getter functions.
 */
abstract contract LS1Getters is
  LS1Storage
{
  using SafeMath for uint256;

  // ============ External Functions ============

  /**
   * @notice The token balance currently borrowed by the borrower.
   *
   * @param  borrower  The borrower whose balance to query.
   *
   * @return The number of tokens borrowed.
   */
  function getBorrowedBalance(
    address borrower
  )
    external
    view
    returns (uint256)
  {
    return _BORROWED_BALANCES_[borrower];
  }

  /**
   * @notice The total token balance borrowed by borrowers.
   *
   * @return The number of tokens borrowed.
   */
  function getTotalBorrowedBalance()
    external
    view
    returns (uint256)
  {
    return _TOTAL_BORROWED_BALANCE_;
  }

  /**
   * @notice The debt balance owed by the borrower.
   *
   * @param  borrower  The borrower whose balance to query.
   *
   * @return The number of tokens owed.
   */
  function getBorrowerDebtBalance(
    address borrower
  )
    external
    view
    returns (uint256)
  {
    return _BORROWER_DEBT_BALANCES_[borrower];
  }

  /**
   * @notice The total debt balance owed by borrowers.
   *
   * @return The number of tokens owed.
   */
  function getTotalBorrowerDebtBalance()
    external
    view
    returns (uint256)
  {
    return _TOTAL_BORROWER_DEBT_BALANCE_;
  }

  /**
   * @notice The total debt repaid by borrowers and available for stakers to withdraw.
   *
   * @return The number of tokens available.
   */
  function getTotalDebtAvailableToWithdraw()
    external
    view
    returns (uint256)
  {
    return _TOTAL_DEBT_AVAILABLE_TO_WITHDRAW_;
  }

  /**
   * @notice Check whether a borrower is restricted from new borrowing.
   *
   * @param  borrower  The borrower to check.
   *
   * @return Boolean `true` if the borrower is restricted, otherwise `false`.
   */
  function isBorrowingRestrictedForBorrower(
    address borrower
  )
    external
    view
    returns (bool)
  {
    return _BORROWER_RESTRICTIONS_[borrower];
  }

  /**
   * @notice The parameters specifying the function from timestamp to epoch number.
   *
   * @return The parameters struct with `interval` and `offset` fields.
   */
  function getEpochParameters()
    external
    view
    returns (LS1Types.EpochParameters memory)
  {
    return _EPOCH_PARAMETERS_;
  }

  /**
   * @notice The period of time at the end of each epoch in which withdrawals cannot be requested.
   *
   *  Other changes which could affect borrowers' repayment plans are also restricted during
   *  this period.
   */
  function getBlackoutWindow()
    external
    view
    returns (uint256)
  {
    return _BLACKOUT_WINDOW_;
  }

  /**
   * @notice Get information about a shortfall that occurred.
   *
   * @param  shortfallCounter  The array index for the shortfall event to look up.
   *
   * @return Struct containing the epoch and shortfall index value.
   */
  function getShortfall(
    uint256 shortfallCounter
  )
    external
    view
    returns (LS1Types.Shortfall memory)
  {
    return _SHORTFALLS_[shortfallCounter];
  }

  /**
   * @notice Get the number of shortfalls that have occurred.
   *
   * @return The number of shortfalls that have occurred.
   */
  function getShortfallCount()
    external
    view
    returns (uint256)
  {
    return _SHORTFALLS_.length;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

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
    require(c >= a, 'SafeMath: addition overflow');

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
    return sub(a, b, 'SafeMath: subtraction overflow');
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
  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
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
    require(c / a == b, 'SafeMath: multiplication overflow');

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
    return div(a, b, 'SafeMath: division by zero');
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
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
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
    return mod(a, b, 'SafeMath: modulo by zero');
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
  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { SafeMath } from '../dependencies/open-zeppelin/SafeMath.sol';

/**
 * @title Math
 * @author dYdX
 *
 * @dev Library for non-standard Math functions.
 */
library Math {
  using SafeMath for uint256;

  // ============ Library Functions ============

  /**
   * @dev Return `ceil(numerator / denominator)`.
   */
  function divRoundUp(
    uint256 numerator,
    uint256 denominator
  )
    internal
    pure
    returns (uint256)
  {
    if (numerator == 0) {
      // SafeMath will check for zero denominator
      return SafeMath.div(0, denominator);
    }
    return numerator.sub(1).div(denominator).add(1);
  }

  /**
   * @dev Returns the minimum between a and b.
   */
  function min(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (uint256)
  {
    return a < b ? a : b;
  }

  /**
   * @dev Returns the maximum between a and b.
   */
  function max(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (uint256)
  {
    return a > b ? a : b;
  }
}

// SPDX-License-Identifier: Apache-2.0
//
// Contracts by dYdX Foundation. Individual files are released under different licenses.
//
// https://dydx.community
// https://github.com/dydxfoundation/governance-contracts

pragma solidity 0.7.5;
pragma abicoder v2;

import { IERC20 } from '../../interfaces/IERC20.sol';
import { LS1Admin } from './impl/LS1Admin.sol';
import { LS1Borrowing } from './impl/LS1Borrowing.sol';
import { LS1DebtAccounting } from './impl/LS1DebtAccounting.sol';
import { LS1ERC20 } from './impl/LS1ERC20.sol';
import { LS1Failsafe } from './impl/LS1Failsafe.sol';
import { LS1Getters } from './impl/LS1Getters.sol';
import { LS1Operators } from './impl/LS1Operators.sol';

/**
 * @title LiquidityStakingV1
 * @author dYdX
 *
 * @notice Contract for staking tokens, which may then be borrowed by pre-approved borrowers.
 *
 *  NOTE: Most functions will revert if epoch zero has not started.
 */
contract LiquidityStakingV1 is
  LS1Borrowing,
  LS1DebtAccounting,
  LS1Admin,
  LS1Operators,
  LS1Getters,
  LS1Failsafe
{
  // ============ Constructor ============

  constructor(
    IERC20 stakedToken,
    IERC20 rewardsToken,
    address rewardsTreasury,
    uint256 distributionStart,
    uint256 distributionEnd
  )
    LS1Borrowing(stakedToken, rewardsToken, rewardsTreasury, distributionStart, distributionEnd)
  {}

  // ============ External Functions ============

  function initialize(
    uint256 interval,
    uint256 offset,
    uint256 blackoutWindow
  )
    external
    initializer
  {
    __LS1Roles_init();
    __LS1EpochSchedule_init(interval, offset, blackoutWindow);
    __LS1Rewards_init();
    __LS1BorrowerAllocations_init();
  }

  // ============ Internal Functions ============

  /**
   * @dev Returns the revision of the implementation contract.
   *
   * @return The revision number.
   */
  function getRevision()
    internal
    pure
    override
    returns (uint256)
  {
    return 1;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { SafeMath } from '../../../dependencies/open-zeppelin/SafeMath.sol';
import { LS1Types } from '../lib/LS1Types.sol';
import { SafeCast } from '../lib/SafeCast.sol';
import { LS1Borrowing } from './LS1Borrowing.sol';

/**
 * @title LS1Admin
 * @author dYdX
 *
 * @dev Admin-only functions.
 */
abstract contract LS1Admin is
  LS1Borrowing
{
  using SafeCast for uint256;
  using SafeMath for uint256;

  // ============ External Functions ============

  /**
   * @notice Set the parameters defining the function from timestamp to epoch number.
   *
   *  The formula used is `n = floor((t - b) / a)` where:
   *    - `n` is the epoch number
   *    - `t` is the timestamp (in seconds)
   *    - `b` is a non-negative offset, indicating the start of epoch zero (in seconds)
   *    - `a` is the length of an epoch, a.k.a. the interval (in seconds)
   *
   *  Reverts if epoch zero already started, and the new parameters would change the current epoch.
   *  Reverts if epoch zero has not started, but would have had started under the new parameters.
   *  Reverts if the new interval is less than twice the blackout window.
   *
   * @param  interval  The length `a` of an epoch, in seconds.
   * @param  offset    The offset `b`, i.e. the start of epoch zero, in seconds.
   */
  function setEpochParameters(
    uint256 interval,
    uint256 offset
  )
    external
    onlyRole(EPOCH_PARAMETERS_ROLE)
    nonReentrant
  {
    if (!hasEpochZeroStarted()) {
      require(block.timestamp < offset, 'LS1Admin: Started epoch zero');
      _setEpochParameters(interval, offset);
      return;
    }

    // Require that we are not currently in a blackout window.
    require(
      !inBlackoutWindow(),
      'LS1Admin: Blackout window'
    );

    // We must settle the total active balance to ensure the index is recorded at the epoch
    // boundary as needed, before we make any changes to the epoch formula.
    _settleTotalActiveBalance();

    // Update the epoch parameters. Require that the current epoch number is unchanged.
    uint256 originalCurrentEpoch = getCurrentEpoch();
    _setEpochParameters(interval, offset);
    uint256 newCurrentEpoch = getCurrentEpoch();
    require(originalCurrentEpoch == newCurrentEpoch, 'LS1Admin: Changed epochs');

    // Require that the new parameters don't put us in a blackout window.
    require(!inBlackoutWindow(), 'LS1Admin: End in blackout window');
  }

  /**
   * @notice Set the blackout window, during which one cannot request withdrawals of staked funds.
   */
  function setBlackoutWindow(
    uint256 blackoutWindow
  )
    external
    onlyRole(EPOCH_PARAMETERS_ROLE)
    nonReentrant
  {
    require(
      !inBlackoutWindow(),
      'LS1Admin: Blackout window'
    );
    _setBlackoutWindow(blackoutWindow);

    // Require that the new parameters don't put us in a blackout window.
    require(!inBlackoutWindow(), 'LS1Admin: End in blackout window');
  }

  /**
   * @notice Set the emission rate of rewards.
   *
   * @param  emissionPerSecond  The new number of rewards tokens given out per second.
   */
  function setRewardsPerSecond(
    uint256 emissionPerSecond
  )
    external
    onlyRole(REWARDS_RATE_ROLE)
    nonReentrant
  {
    uint256 totalStaked = 0;
    if (hasEpochZeroStarted()) {
      // We must settle the total active balance to ensure the index is recorded at the epoch
      // boundary as needed, before we make any changes to the emission rate.
      totalStaked = _settleTotalActiveBalance();
    }
    _setRewardsPerSecond(emissionPerSecond, totalStaked);
  }

  /**
   * @notice Change the allocations of certain borrowers. Can be used to add and remove borrowers.
   *  Increases take effect in the next epoch, but decreases will restrict borrowing immediately.
   *  This function cannot be called during the blackout window.
   *
   * @param  borrowers       Array of borrower addresses.
   * @param  newAllocations  Array of new allocations per borrower, as hundredths of a percent.
   */
  function setBorrowerAllocations(
    address[] calldata borrowers,
    uint256[] calldata newAllocations
  )
    external
    onlyRole(BORROWER_ADMIN_ROLE)
    nonReentrant
  {
    require(borrowers.length == newAllocations.length, 'LS1Admin: Params length mismatch');
    require(
      !inBlackoutWindow(),
      'LS1Admin: Blackout window'
    );
    _setBorrowerAllocations(borrowers, newAllocations);
  }

  function setBorrowingRestriction(
    address borrower,
    bool isBorrowingRestricted
  )
    external
    onlyRole(BORROWER_ADMIN_ROLE)
    nonReentrant
  {
    _setBorrowingRestriction(borrower, isBorrowingRestricted);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { SafeERC20 } from '../../../dependencies/open-zeppelin/SafeERC20.sol';
import { SafeMath } from '../../../dependencies/open-zeppelin/SafeMath.sol';
import { IERC20 } from '../../../interfaces/IERC20.sol';
import { Math } from '../../../utils/Math.sol';
import { LS1Types } from '../lib/LS1Types.sol';
import { SafeCast } from '../lib/SafeCast.sol';
import { LS1BorrowerAllocations } from './LS1BorrowerAllocations.sol';
import { LS1Staking } from './LS1Staking.sol';

/**
 * @title LS1Borrowing
 * @author dYdX
 *
 * @dev External functions for borrowers. See LS1BorrowerAllocations for details on
 *  borrower accounting.
 */
abstract contract LS1Borrowing is
  LS1Staking,
  LS1BorrowerAllocations
{
  using SafeCast for uint256;
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  // ============ Events ============

  event Borrowed(
    address indexed borrower,
    uint256 amount,
    uint256 newBorrowedBalance
  );

  event RepaidBorrow(
    address indexed borrower,
    address sender,
    uint256 amount,
    uint256 newBorrowedBalance
  );

  event RepaidDebt(
    address indexed borrower,
    address sender,
    uint256 amount,
    uint256 newDebtBalance
  );

  // ============ Constructor ============

  constructor(
    IERC20 stakedToken,
    IERC20 rewardsToken,
    address rewardsTreasury,
    uint256 distributionStart,
    uint256 distributionEnd
  )
    LS1Staking(stakedToken, rewardsToken, rewardsTreasury, distributionStart, distributionEnd)
  {}

  // ============ External Functions ============

  /**
   * @notice Borrow staked funds.
   *
   * @param  amount  The token amount to borrow.
   */
  function borrow(
    uint256 amount
  )
    external
    nonReentrant
  {
    require(amount > 0, 'LS1Borrowing: Cannot borrow zero');

    address borrower = msg.sender;

    // Revert if the borrower is restricted.
    require(!_BORROWER_RESTRICTIONS_[borrower], 'LS1Borrowing: Restricted');

    // Get contract available amount and revert if there is not enough to withdraw.
    uint256 totalAvailableForBorrow = getContractBalanceAvailableToBorrow();
    require(
      amount <= totalAvailableForBorrow,
      'LS1Borrowing: Amount > available'
    );

    // Get new net borrow and revert if it is greater than the allocated balance for new borrowing.
    uint256 newBorrowedBalance = _BORROWED_BALANCES_[borrower].add(amount);
    require(
      newBorrowedBalance <= _getAllocatedBalanceForNewBorrowing(borrower),
      'LS1Borrowing: Amount > allocated'
    );

    // Update storage.
    _BORROWED_BALANCES_[borrower] = newBorrowedBalance;
    _TOTAL_BORROWED_BALANCE_ = _TOTAL_BORROWED_BALANCE_.add(amount);

    // Transfer token to the borrower.
    STAKED_TOKEN.safeTransfer(borrower, amount);

    emit Borrowed(borrower, amount, newBorrowedBalance);
  }

  /**
   * @notice Repay borrowed funds for the specified borrower. Reverts if repay amount exceeds
   *  borrowed amount.
   *
   * @param  borrower  The borrower on whose behalf to make a repayment.
   * @param  amount    The amount to repay.
   */
  function repayBorrow(
    address borrower,
    uint256 amount
  )
    external
    nonReentrant
  {
    require(amount > 0, 'LS1Borrowing: Cannot repay zero');

    uint256 oldBorrowedBalance = _BORROWED_BALANCES_[borrower];
    require(amount <= oldBorrowedBalance, 'LS1Borrowing: Repay > borrowed');
    uint256 newBorrowedBalance = oldBorrowedBalance.sub(amount);

    // Update storage.
    _BORROWED_BALANCES_[borrower] = newBorrowedBalance;
    _TOTAL_BORROWED_BALANCE_ = _TOTAL_BORROWED_BALANCE_.sub(amount);

    // Transfer token from the sender.
    STAKED_TOKEN.safeTransferFrom(msg.sender, address(this), amount);

    emit RepaidBorrow(borrower, msg.sender, amount, newBorrowedBalance);
  }

  /**
   * @notice Repay a debt amount owed by a borrower.
   *
   * @param  borrower  The borrower whose debt to repay.
   * @param  amount    The amount to repay.
   */
  function repayDebt(
    address borrower,
    uint256 amount
  )
    external
    nonReentrant
  {
    require(amount > 0, 'LS1Borrowing: Cannot repay zero');

    uint256 oldDebtAmount = _BORROWER_DEBT_BALANCES_[borrower];
    require(amount <= oldDebtAmount, 'LS1Borrowing: Repay > debt');
    uint256 newDebtBalance = oldDebtAmount.sub(amount);

    // Update storage.
    _BORROWER_DEBT_BALANCES_[borrower] = newDebtBalance;
    _TOTAL_BORROWER_DEBT_BALANCE_ = _TOTAL_BORROWER_DEBT_BALANCE_.sub(amount);
    _TOTAL_DEBT_AVAILABLE_TO_WITHDRAW_ = _TOTAL_DEBT_AVAILABLE_TO_WITHDRAW_.add(amount);

    // Transfer token from the sender.
    STAKED_TOKEN.safeTransferFrom(msg.sender, address(this), amount);

    emit RepaidDebt(borrower, msg.sender, amount, newDebtBalance);
  }

  /**
   * @notice Get the max additional amount that the borrower can borrow.
   *
   * @return The max additional amount that the borrower can borrow right now.
   */
  function getBorrowableAmount(
    address borrower
  )
    external
    view
    returns (uint256)
  {
    if (_BORROWER_RESTRICTIONS_[borrower]) {
      return 0;
    }

    // Get the remaining unused allocation for the borrower.
    uint256 oldBorrowedBalance = _BORROWED_BALANCES_[borrower];
    uint256 borrowerAllocatedBalance = _getAllocatedBalanceForNewBorrowing(borrower);
    if (borrowerAllocatedBalance <= oldBorrowedBalance) {
      return 0;
    }
    uint256 borrowerRemainingAllocatedBalance = borrowerAllocatedBalance.sub(oldBorrowedBalance);

    // Don't allow new borrowing to take out funds that are reserved for debt or inactive balances.
    // Typically, this will not be the limiting factor, but it can be.
    uint256 totalAvailableForBorrow = getContractBalanceAvailableToBorrow();

    return Math.min(borrowerRemainingAllocatedBalance, totalAvailableForBorrow);
  }

  // ============ Public Functions ============

  /**
   * @notice Get the funds currently available in the contract for borrowing.
   *
   * @return The amount of non-debt, non-inactive funds in the contract.
   */
  function getContractBalanceAvailableToBorrow()
    public
    view
    returns (uint256)
  {
    uint256 availableStake = getContractBalanceAvailableToWithdraw();
    uint256 inactiveBalance = getTotalInactiveBalanceCurrentEpoch();
    // Note: The funds available to withdraw may be less than the inactive balance.
    if (availableStake <= inactiveBalance) {
      return 0;
    }
    return availableStake.sub(inactiveBalance);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { SafeERC20 } from '../../../dependencies/open-zeppelin/SafeERC20.sol';
import { SafeMath } from '../../../dependencies/open-zeppelin/SafeMath.sol';
import { IERC20 } from '../../../interfaces/IERC20.sol';
import { Math } from '../../../utils/Math.sol';
import { LS1Types } from '../lib/LS1Types.sol';
import { LS1BorrowerAllocations } from './LS1BorrowerAllocations.sol';

/**
 * @title LS1DebtAccounting
 * @author dYdX
 *
 * @dev Allows converting an overdue balance into "debt", which is accounted for separately from
 *  the staked and borrowed balances. This allows the system to rebalance/restabilize itself in the
 *  case where a borrower fails to return borrowed funds on time.
 *
 *  The shortfall debt calculation is as follows:
 *
 *    - Let A be the total active balance.
 *    - Let B be the total borrowed balance.
 *    - Let X be the total inactive balance.
 *    - Then, a shortfall occurs if at any point B > A.
 *    - The shortfall debt amount is `D = B - A`
 *    - The borrowed balances are decreased by `B_new = B - D`
 *    - The inactive balances are decreased by `X_new = X - D`
 *    - The shortfall index is recorded as `Y = X_new / X`
 *    - The borrower and staker debt balances are increased by `D`
 *
 *  Note that `A + X >= B` (The active and inactive balances are at least the borrowed balance.)
 *  This implies that `X >= D` (The inactive balance is always at least the shortfall debt.)
 */
abstract contract LS1DebtAccounting is
  LS1BorrowerAllocations
{
  using SafeERC20 for IERC20;
  using SafeMath for uint256;
  using Math for uint256;

  // ============ Events ============

  event ConvertedInactiveBalancesToDebt(
    uint256 shortfallAmount,
    uint256 shortfallIndex,
    uint256 newInactiveBalance
  );

  event DebtMarked(
    address indexed borrower,
    uint256 amount,
    uint256 newBorrowedBalance,
    uint256 newDebtBalance
  );

  // ============ External Functions ============

  /**
   * @notice Restrict a borrower from borrowing. The borrower must have exceeded their borrowing
   *  allocation. Can be called by anyone.
   *
   *  Unlike markDebt(), this function can be called even if the contract in TOTAL is not insolvent.
   */
  function restrictBorrower(
    address borrower
  )
    external
    nonReentrant
  {
    require(
      isBorrowerOverdue(borrower),
      'LS1DebtAccounting: Borrower not overdue'
    );
    _setBorrowingRestriction(borrower, true);
  }

  /**
   * @notice Convert the shortfall amount between the active and borrowed balances into “debt.”
   *
   *  The function determines the size of the debt, and then does the following:
   *   - Assign the debt to borrowers, taking the same amount out of their borrowed balance.
   *   - Impose borrow restrictions on borrowers to whom the debt was assigned.
   *   - Socialize the loss pro-rata across inactive balances. Each balance with a loss receives
   *     an equal amount of debt balance that can be withdrawn as debts are repaid.
   *
   * @param  borrowers  A list of borrowers who are responsible for the full shortfall amount.
   *
   * @return The shortfall debt amount.
   */
  function markDebt(
    address[] calldata borrowers
  )
    external
    nonReentrant
    returns (uint256)
  {
    // The debt is equal to the difference between the total active and total borrowed balances.
    uint256 totalActiveCurrent = getTotalActiveBalanceCurrentEpoch();
    uint256 totalBorrowed = _TOTAL_BORROWED_BALANCE_;
    require(totalBorrowed > totalActiveCurrent, 'LS1DebtAccounting: No shortfall');
    uint256 shortfallDebt = totalBorrowed.sub(totalActiveCurrent);

    // Attribute debt to borrowers.
    _attributeDebtToBorrowers(shortfallDebt, totalActiveCurrent, borrowers);

    // Apply the debt to inactive balances, moving the same amount into users debt balances.
    _convertInactiveBalanceToDebt(shortfallDebt);

    return shortfallDebt;
  }

  // ============ Public Functions ============

  /**
   * @notice Whether the borrower is overdue on a payment, and is currently subject to having their
   *  borrowing rights revoked.
   *
   * @param  borrower  The borrower to check.
   */
  function isBorrowerOverdue(
    address borrower
  )
    public
    view
    returns (bool)
  {
    uint256 allocatedBalance = getAllocatedBalanceCurrentEpoch(borrower);
    uint256 borrowedBalance = _BORROWED_BALANCES_[borrower];
    return borrowedBalance > allocatedBalance;
  }

  // ============ Private Functions ============

  /**
   * @dev Helper function to partially or fully convert inactive balances to debt.
   *
   * @param  shortfallDebt  The shortfall amount: borrowed balances less active balances.
   */
  function _convertInactiveBalanceToDebt(
    uint256 shortfallDebt
  )
    private
  {
    // Get the total inactive balance.
    uint256 oldInactiveBalance = getTotalInactiveBalanceCurrentEpoch();

    // Calculate the index factor for the shortfall.
    uint256 newInactiveBalance = 0;
    uint256 shortfallIndex = 0;
    if (oldInactiveBalance > shortfallDebt) {
      newInactiveBalance = oldInactiveBalance.sub(shortfallDebt);
      shortfallIndex = SHORTFALL_INDEX_BASE.mul(newInactiveBalance).div(oldInactiveBalance);
    }

    // Get the shortfall amount applied to inactive balances.
    uint256 shortfallAmount = oldInactiveBalance.sub(newInactiveBalance);

    // Apply the loss. This moves the debt from stakers' inactive balances to their debt balances.
    _applyShortfall(shortfallAmount, shortfallIndex);
    emit ConvertedInactiveBalancesToDebt(shortfallAmount, shortfallIndex, newInactiveBalance);
  }

  /**
   * @dev Helper function to attribute debt to borrowers, adding it to their debt balances.
   *
   * @param  shortfallDebt       The shortfall amount: borrowed balances less active balances.
   * @param  totalActiveCurrent  The total active balance for the current epoch.
   * @param  borrowers           A list of borrowers responsible for the full shortfall amount.
   */
  function _attributeDebtToBorrowers(
    uint256 shortfallDebt,
    uint256 totalActiveCurrent,
    address[] calldata borrowers
  ) private {
    // Find borrowers to attribute the total debt amount to. The sum of all borrower shortfalls is
    // always at least equal to the overall shortfall, so it is always possible to specify a list
    // of borrowers whose excess borrows cover the full shortfall amount.
    //
    // Denominate values in “points” scaled by TOTAL_ALLOCATION to avoid rounding.
    uint256 debtToBeAttributedPoints = shortfallDebt.mul(TOTAL_ALLOCATION);
    uint256 shortfallDebtAfterRounding = 0;
    for (uint256 i = 0; i < borrowers.length; i++) {
      address borrower = borrowers[i];
      uint256 borrowedBalanceTokenAmount = _BORROWED_BALANCES_[borrower];
      uint256 borrowedBalancePoints = borrowedBalanceTokenAmount.mul(TOTAL_ALLOCATION);
      uint256 allocationPoints = getAllocationFractionCurrentEpoch(borrower);
      uint256 allocatedBalancePoints = totalActiveCurrent.mul(allocationPoints);

      // Skip this borrower if they have not exceeded their allocation.
      if (borrowedBalancePoints <= allocatedBalancePoints) {
        continue;
      }

      // Calculate the borrower's debt, and limit to the remaining amount to be allocated.
      uint256 borrowerDebtPoints = borrowedBalancePoints.sub(allocatedBalancePoints);
      borrowerDebtPoints = Math.min(borrowerDebtPoints, debtToBeAttributedPoints);

      // Move the debt from the borrowers' borrowed balance to the debt balance. Rounding may occur
      // when converting from “points” to tokens. We round up to ensure the final borrowed balance
      // is not greater than the allocated balance.
      uint256 borrowerDebtTokenAmount = borrowerDebtPoints.divRoundUp(TOTAL_ALLOCATION);
      uint256 newDebtBalance = _BORROWER_DEBT_BALANCES_[borrower].add(borrowerDebtTokenAmount);
      uint256 newBorrowedBalance = borrowedBalanceTokenAmount.sub(borrowerDebtTokenAmount);
      _BORROWER_DEBT_BALANCES_[borrower] = newDebtBalance;
      _BORROWED_BALANCES_[borrower] = newBorrowedBalance;
      emit DebtMarked(borrower, borrowerDebtTokenAmount, newBorrowedBalance, newDebtBalance);
      shortfallDebtAfterRounding = shortfallDebtAfterRounding.add(borrowerDebtTokenAmount);

      // Restrict the borrower from further borrowing.
      _setBorrowingRestriction(borrower, true);

      // Update the remaining amount to allocate.
      debtToBeAttributedPoints = debtToBeAttributedPoints.sub(borrowerDebtPoints);

      // Exit early if all debt was allocated.
      if (debtToBeAttributedPoints == 0) {
        break;
      }
    }

    // Require the borrowers to cover the full debt amount. This should always be possible.
    require(
      debtToBeAttributedPoints == 0,
      'LS1DebtAccounting: Borrowers do not cover the shortfall'
    );

    // Move the debt from the total borrowed balance to the total debt balance.
    _TOTAL_BORROWED_BALANCE_ = _TOTAL_BORROWED_BALANCE_.sub(shortfallDebtAfterRounding);
    _TOTAL_BORROWER_DEBT_BALANCE_ = _TOTAL_BORROWER_DEBT_BALANCE_.add(shortfallDebtAfterRounding);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { SafeMath } from '../../../dependencies/open-zeppelin/SafeMath.sol';
import { IERC20Detailed } from '../../../interfaces/IERC20Detailed.sol';
import { LS1Types } from '../lib/LS1Types.sol';
import { LS1StakedBalances } from './LS1StakedBalances.sol';

/**
 * @title LS1ERC20
 * @author dYdX
 *
 * @dev ERC20 interface for staked tokens. Allows a user with an active stake to transfer their
 *  staked tokens to another user, even if they would otherwise be restricted from withdrawing.
 */
abstract contract LS1ERC20 is
  LS1StakedBalances,
  IERC20Detailed
{
  using SafeMath for uint256;

  // ============ External Functions ============

  function name()
    external
    pure
    override
    returns (string memory)
  {
    return 'dYdX Staked USDC';
  }

  function symbol()
    external
    pure
    override
    returns (string memory)
  {
    return 'stkUSDC';
  }

  function decimals()
    external
    pure
    override
    returns (uint8)
  {
    return 6;
  }

  /**
   * @notice Get the total supply of `STAKED_TOKEN` staked to the contract.
   *  This value is calculated from adding the active + inactive balances of
   *  this current epoch.
   *
   * @return The total staked balance of this contract.
   */
  function totalSupply()
    external
    view
    override
    returns (uint256)
  {
    return getTotalActiveBalanceCurrentEpoch() + getTotalInactiveBalanceCurrentEpoch();
  }

  /**
   * @notice Get the current balance of `STAKED_TOKEN` the user has staked to the contract.
   *  This value includes the users active + inactive balances, but note that only
   *  their active balance in the next epoch is transferable.
   *
   * @param  account  The account to get the balance of.
   *
   * @return The user's balance.
   */
  function balanceOf(
    address account
  )
    external
    view
    override
    returns (uint256)
  {
    return getActiveBalanceCurrentEpoch(account) + getInactiveBalanceCurrentEpoch(account);
  }

  function transfer(
    address recipient,
    uint256 amount
  )
    external
    override
    nonReentrant
    returns (bool)
  {
    _transfer(msg.sender, recipient, amount);
    return true;
  }

  function allowance(
    address owner,
    address spender
  )
    external
    view
    override
    returns (uint256)
  {
    return _ALLOWANCES_[owner][spender];
  }

  function approve(
    address spender,
    uint256 amount
  )
    external
    override
    returns (bool)
  {
    _approve(msg.sender, spender, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  )
    external
    override
    nonReentrant
    returns (bool)
  {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      msg.sender,
      _ALLOWANCES_[sender][msg.sender].sub(amount, 'LS1ERC20: transfer amount exceeds allowance')
    );
    return true;
  }

  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    external
    returns (bool)
  {
    _approve(msg.sender, spender, _ALLOWANCES_[msg.sender][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    external
    returns (bool)
  {
    _approve(
      msg.sender,
      spender,
      _ALLOWANCES_[msg.sender][spender].sub(
        subtractedValue,
        'LS1ERC20: Decreased allowance below zero'
      )
    );
    return true;
  }

  // ============ Internal Functions ============

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  )
    internal
  {
    require(sender != address(0), 'LS1ERC20: Transfer from address(0)');
    require(recipient != address(0), 'LS1ERC20: Transfer to address(0)');
    require(
      getTransferableBalance(sender) >= amount,
      'LS1ERC20: Transfer exceeds next epoch active balance'
    );

    _transferCurrentAndNextActiveBalance(sender, recipient, amount);
    emit Transfer(sender, recipient, amount);
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  )
    internal
  {
    require(owner != address(0), 'LS1ERC20: Approve from address(0)');
    require(spender != address(0), 'LS1ERC20: Approve to address(0)');

    _ALLOWANCES_[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { SafeMath } from '../../../dependencies/open-zeppelin/SafeMath.sol';
import { IERC20 } from '../../../interfaces/IERC20.sol';
import { LS1Types } from '../lib/LS1Types.sol';
import { SafeCast } from '../lib/SafeCast.sol';
import { LS1StakedBalances } from './LS1StakedBalances.sol';

/**
 * @title LS1Failsafe
 * @author dYdX
 *
 * @dev Functions for recovering from very unlikely edge cases.
 */
abstract contract LS1Failsafe is
  LS1StakedBalances
{
  using SafeCast for uint256;
  using SafeMath for uint256;

  /**
   * @notice Settle the sender's inactive balance up to the specified epoch. This allows the
   *  balance to be settled while putting an upper bound on the gas expenditure per function call.
   *  This is unlikely to be needed in practice.
   *
   * @param  maxEpoch  The epoch to settle the sender's inactive balance up to.
   */
  function failsafeSettleUserInactiveBalanceToEpoch(
    uint256 maxEpoch
  )
    external
    nonReentrant
  {
    address staker = msg.sender;
    _failsafeSettleUserInactiveBalance(staker, maxEpoch);
  }

  /**
   * @notice Sets the sender's inactive balance to zero. This allows for recovery from a situation
   *  where the gas cost to settle the balance is higher than the value of the balance itself.
   *  We provide this function as an alternative to settlement, since the gas cost for settling an
   *  inactive balance is unbounded (except in that it may grow at most linearly with the number of
   *  epochs that have passed).
   */
  function failsafeDeleteUserInactiveBalance()
    external
    nonReentrant
  {
    address staker = msg.sender;
    _failsafeDeleteUserInactiveBalance(staker);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { SafeMath } from '../../../dependencies/open-zeppelin/SafeMath.sol';
import { LS1Staking } from './LS1Staking.sol';

/**
 * @title LS1Operators
 * @author dYdX
 *
 * @dev Actions which may be called by authorized operators, nominated by the contract owner.
 *
 *  There are three types of operators. These should be smart contracts, which can be used to
 *  provide additional functionality to users:
 *
 *  STAKE_OPERATOR_ROLE:
 *
 *    This operator is allowed to request withdrawals and withdraw funds on behalf of stakers. This
 *    role could be used by a smart contract to provide a staking interface with additional
 *    features, for example, optional lock-up periods that pay out additional rewards (from a
 *    separate rewards pool).
 *
 *  CLAIM_OPERATOR_ROLE:
 *
 *    This operator is allowed to claim rewards on behalf of stakers. This role could be used by a
 *    smart contract to provide an interface for claiming rewards from multiple incentive programs
 *    at once.
 *
 *  DEBT_OPERATOR_ROLE:
 *
 *    This operator is allowed to decrease staker and borrower debt balances. Typically, each change
 *    to a staker debt balance should be offset by a corresponding change in a borrower debt
 *    balance, but this is not strictly required. This role could used by a smart contract to
 *    tokenize debt balances or to provide a pro-rata distribution to debt holders, for example.
 */
abstract contract LS1Operators is
  LS1Staking
{
  using SafeMath for uint256;

  // ============ Events ============

  event OperatorStakedFor(
    address indexed staker,
    uint256 amount,
    address operator
  );

  event OperatorWithdrawalRequestedFor(
    address indexed staker,
    uint256 amount,
    address operator
  );

  event OperatorWithdrewStakeFor(
    address indexed staker,
    address recipient,
    uint256 amount,
    address operator
  );

  event OperatorClaimedRewardsFor(
    address indexed staker,
    address recipient,
    uint256 claimedRewards,
    address operator
  );

  event OperatorDecreasedStakerDebt(
    address indexed staker,
    uint256 amount,
    uint256 newDebtBalance,
    address operator
  );

  event OperatorDecreasedBorrowerDebt(
    address indexed borrower,
    uint256 amount,
    uint256 newDebtBalance,
    address operator
  );

  // ============ External Functions ============

  /**
   * @notice Request a withdrawal on behalf of a staker.
   *
   *  Reverts if we are currently in the blackout window.
   *
   * @param  staker  The staker whose stake to request a withdrawal for.
   * @param  amount  The amount to move from the active to the inactive balance.
   */
  function requestWithdrawalFor(
    address staker,
    uint256 amount
  )
    external
    onlyRole(STAKE_OPERATOR_ROLE)
    nonReentrant
  {
    _requestWithdrawal(staker, amount);
    emit OperatorWithdrawalRequestedFor(staker, amount, msg.sender);
  }

  /**
   * @notice Withdraw a staker's stake, and send to the specified recipient.
   *
   * @param  staker     The staker whose stake to withdraw.
   * @param  recipient  The address that should receive the funds.
   * @param  amount     The amount to withdraw from the staker's inactive balance.
   */
  function withdrawStakeFor(
    address staker,
    address recipient,
    uint256 amount
  )
    external
    onlyRole(STAKE_OPERATOR_ROLE)
    nonReentrant
  {
    _withdrawStake(staker, recipient, amount);
    emit OperatorWithdrewStakeFor(staker, recipient, amount, msg.sender);
  }

  /**
   * @notice Claim rewards on behalf of a staker, and send them to the specified recipient.
   *
   * @param  staker     The staker whose rewards to claim.
   * @param  recipient  The address that should receive the funds.
   *
   * @return The number of rewards tokens claimed.
   */
  function claimRewardsFor(
    address staker,
    address recipient
  )
    external
    onlyRole(CLAIM_OPERATOR_ROLE)
    nonReentrant
    returns (uint256)
  {
    uint256 rewards = _settleAndClaimRewards(staker, recipient); // Emits an event internally.
    emit OperatorClaimedRewardsFor(staker, recipient, rewards, msg.sender);
    return rewards;
  }

  /**
   * @notice Decreased the balance recording debt owed to a staker.
   *
   * @param  staker  The staker whose balance to decrease.
   * @param  amount  The amount to decrease the balance by.
   *
   * @return The new debt balance.
   */
  function decreaseStakerDebt(
    address staker,
    uint256 amount
  )
    external
    onlyRole(DEBT_OPERATOR_ROLE)
    nonReentrant
    returns (uint256)
  {
    uint256 oldDebtBalance = _settleStakerDebtBalance(staker);
    uint256 newDebtBalance = oldDebtBalance.sub(amount);
    _STAKER_DEBT_BALANCES_[staker] = newDebtBalance;
    emit OperatorDecreasedStakerDebt(staker, amount, newDebtBalance, msg.sender);
    return newDebtBalance;
  }

  /**
   * @notice Decreased the balance recording debt owed by a borrower.
   *
   * @param  borrower  The borrower whose balance to decrease.
   * @param  amount    The amount to decrease the balance by.
   *
   * @return The new debt balance.
   */
  function decreaseBorrowerDebt(
    address borrower,
    uint256 amount
  )
    external
    onlyRole(DEBT_OPERATOR_ROLE)
    nonReentrant
    returns (uint256)
  {
    uint256 newDebtBalance = _BORROWER_DEBT_BALANCES_[borrower].sub(amount);
    _BORROWER_DEBT_BALANCES_[borrower] = newDebtBalance;
    _TOTAL_BORROWER_DEBT_BALANCE_ = _TOTAL_BORROWER_DEBT_BALANCE_.sub(amount);
    emit OperatorDecreasedBorrowerDebt(borrower, amount, newDebtBalance, msg.sender);
    return newDebtBalance;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.5;
pragma abicoder v2;

/**
 * @title SafeCast
 * @author dYdX
 *
 * @dev Methods for downcasting unsigned integers, reverting on overflow.
 */
library SafeCast {

  /**
   * @dev Downcast to a uint16, reverting on overflow.
   */
  function toUint16(
    uint256 a
  )
    internal
    pure
    returns (uint16)
  {
    uint16 b = uint16(a);
    require(uint256(b) == a, 'SafeCast: toUint16 overflow');
    return b;
  }

  /**
   * @dev Downcast to a uint32, reverting on overflow.
   */
  function toUint32(
    uint256 a
  )
    internal
    pure
    returns (uint32)
  {
    uint32 b = uint32(a);
    require(uint256(b) == a, 'SafeCast: toUint32 overflow');
    return b;
  }

  /**
   * @dev Downcast to a uint112, reverting on overflow.
   */
  function toUint112(
    uint256 a
  )
    internal
    pure
    returns (uint112)
  {
    uint112 b = uint112(a);
    require(uint256(b) == a, 'SafeCast: toUint112 overflow');
    return b;
  }

  /**
   * @dev Downcast to a uint120, reverting on overflow.
   */
  function toUint120(
    uint256 a
  )
    internal
    pure
    returns (uint120)
  {
    uint120 b = uint120(a);
    require(uint256(b) == a, 'SafeCast: toUint120 overflow');
    return b;
  }

  /**
   * @dev Downcast to a uint128, reverting on overflow.
   */
  function toUint128(
    uint256 a
  )
    internal
    pure
    returns (uint128)
  {
    uint128 b = uint128(a);
    require(uint256(b) == a, 'SafeCast: toUint128 overflow');
    return b;
  }

  /**
   * @dev Downcast to a uint224, reverting on overflow.
   */
  function toUint224(
    uint256 a
  )
    internal
    pure
    returns (uint224)
  {
    uint224 b = uint224(a);
    require(uint256(b) == a, 'SafeCast: toUint224 overflow');
    return b;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import { IERC20 } from '../../interfaces/IERC20.sol';
import { SafeMath } from './SafeMath.sol';
import { Address } from './Address.sol';

/**
 * @title SafeERC20
 * @dev From https://github.com/OpenZeppelin/openzeppelin-contracts
 * Wrappers around ERC20 operations that throw on failure (when the token
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
    callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      'SafeERC20: approve from non-zero to non-zero allowance'
    );
    callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function callOptionalReturn(IERC20 token, bytes memory data) private {
    require(address(token).isContract(), 'SafeERC20: call to non-contract');

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = address(token).call(data);
    require(success, 'SafeERC20: low-level call failed');

    if (returndata.length > 0) {
      // Return data is optional
      // solhint-disable-next-line max-line-length
      require(abi.decode(returndata, (bool)), 'SafeERC20: ERC20 operation did not succeed');
    }
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { SafeERC20 } from '../../../dependencies/open-zeppelin/SafeERC20.sol';
import { SafeMath } from '../../../dependencies/open-zeppelin/SafeMath.sol';
import { IERC20 } from '../../../interfaces/IERC20.sol';
import { Math } from '../../../utils/Math.sol';
import { LS1Types } from '../lib/LS1Types.sol';
import { SafeCast } from '../lib/SafeCast.sol';
import { LS1StakedBalances } from './LS1StakedBalances.sol';

/**
 * @title LS1BorrowerAllocations
 * @author dYdX
 *
 * @dev Gives a set of addresses permission to withdraw staked funds.
 *
 *  The amount that can be withdrawn depends on a borrower's allocation percentage and the total
 *  available funds. Both the allocated percentage and total available funds can change, at
 *  predefined times specified by LS1EpochSchedule.
 *
 *  If a borrower's borrowed balance is greater than their allocation at the start of the next epoch
 *  then they are expected and trusted to return the difference before the start of that epoch.
 */
abstract contract LS1BorrowerAllocations is
  LS1StakedBalances
{
  using SafeCast for uint256;
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  // ============ Constants ============

  /// @notice The total units to be allocated.
  uint256 public constant TOTAL_ALLOCATION = 1e4;

  // ============ Events ============

  event ScheduledBorrowerAllocationChange(
    address indexed borrower,
    uint256 oldAllocation,
    uint256 newAllocation,
    uint256 epochNumber
  );

  event BorrowingRestrictionChanged(
    address indexed borrower,
    bool isBorrowingRestricted
  );

  // ============ Initializer ============

  function __LS1BorrowerAllocations_init()
    internal
  {
    _BORROWER_ALLOCATIONS_[address(0)] = LS1Types.StoredAllocation({
      currentEpoch: 0,
      currentEpochAllocation: TOTAL_ALLOCATION.toUint120(),
      nextEpochAllocation: TOTAL_ALLOCATION.toUint120()
    });
  }

  // ============ Public Functions ============

  /**
   * @notice Get the borrower allocation for the current epoch.
   *
   * @param  borrower  The borrower to get the allocation for.
   *
   * @return The borrower's current allocation in hundreds of a percent.
   */
  function getAllocationFractionCurrentEpoch(
    address borrower
  )
    public
    view
    returns (uint256)
  {
    return uint256(_loadBorrowerAllocation(borrower).currentEpochAllocation);
  }

  /**
   * @notice Get the borrower allocation for the next epoch.
   *
   * @param  borrower  The borrower to get the allocation for.
   *
   * @return The borrower's next allocation in hundreds of a percent.
   */
  function getAllocationFractionNextEpoch(
    address borrower
  )
    public
    view
    returns (uint256)
  {
    return uint256(_loadBorrowerAllocation(borrower).nextEpochAllocation);
  }

  /**
   * @notice Get the allocated borrowable token balance of a borrower for the current epoch.
   *
   *  This is the amount which a borrower can be penalized for exceeding.
   *
   * @param  borrower  The borrower to get the allocation for.
   *
   * @return The token amount allocated to the borrower for the current epoch.
   */
  function getAllocatedBalanceCurrentEpoch(
    address borrower
  )
    public
    view
    returns (uint256)
  {
    uint256 allocation = getAllocationFractionCurrentEpoch(borrower);
    uint256 availableTokens = getTotalActiveBalanceCurrentEpoch();
    return availableTokens.mul(allocation).div(TOTAL_ALLOCATION);
  }

  /**
   * @notice Preview the allocated balance of a borrower for the next epoch.
   *
   * @param  borrower  The borrower to get the allocation for.
   *
   * @return The anticipated token amount allocated to the borrower for the next epoch.
   */
  function getAllocatedBalanceNextEpoch(
    address borrower
  )
    public
    view
    returns (uint256)
  {
    uint256 allocation = getAllocationFractionNextEpoch(borrower);
    uint256 availableTokens = getTotalActiveBalanceNextEpoch();
    return availableTokens.mul(allocation).div(TOTAL_ALLOCATION);
  }

  // ============ Internal Functions ============

  /**
   * @dev Change the allocations of certain borrowers.
   */
  function _setBorrowerAllocations(
    address[] calldata borrowers,
    uint256[] calldata newAllocations
  )
    internal
  {
    // These must net out so that the total allocation is unchanged.
    uint256 oldAllocationSum = 0;
    uint256 newAllocationSum = 0;

    for (uint256 i = 0; i < borrowers.length; i++) {
      address borrower = borrowers[i];
      uint256 newAllocation = newAllocations[i];

      // Get the old allocation.
      LS1Types.StoredAllocation memory allocationStruct = _loadBorrowerAllocation(borrower);
      uint256 oldAllocation = uint256(allocationStruct.currentEpochAllocation);

      // Update the borrower's next allocation.
      allocationStruct.nextEpochAllocation = newAllocation.toUint120();

      // If epoch zero hasn't started, update current allocation as well.
      uint256 epochNumber = 0;
      if (hasEpochZeroStarted()) {
        epochNumber = uint256(allocationStruct.currentEpoch).add(1);
      } else {
        allocationStruct.currentEpochAllocation = newAllocation.toUint120();
      }

      // Commit the new allocation.
      _BORROWER_ALLOCATIONS_[borrower] = allocationStruct;
      emit ScheduledBorrowerAllocationChange(borrower, oldAllocation, newAllocation, epochNumber);

      // Record totals.
      oldAllocationSum = oldAllocationSum.add(oldAllocation);
      newAllocationSum = newAllocationSum.add(newAllocation);
    }

    // Require the total allocated units to be unchanged.
    require(
      oldAllocationSum == newAllocationSum,
      'LS1BorrowerAllocations: Invalid'
    );
  }

  /**
   * @dev Restrict a borrower from further borrowing.
   */
  function _setBorrowingRestriction(
    address borrower,
    bool isBorrowingRestricted
  )
    internal
  {
    bool oldIsBorrowingRestricted = _BORROWER_RESTRICTIONS_[borrower];
    if (oldIsBorrowingRestricted != isBorrowingRestricted) {
      _BORROWER_RESTRICTIONS_[borrower] = isBorrowingRestricted;
      emit BorrowingRestrictionChanged(borrower, isBorrowingRestricted);
    }
  }

  /**
   * @dev Get the allocated balance that the borrower can make use of for new borrowing.
   *
   * @return The amount that the borrower can borrow up to.
   */
  function _getAllocatedBalanceForNewBorrowing(
    address borrower
  )
    internal
    view
    returns (uint256)
  {
    // Use the smaller of the current and next allocation fractions, since if a borrower's
    // allocation was just decreased, we should take that into account in limiting new borrows.
    uint256 currentAllocation = getAllocationFractionCurrentEpoch(borrower);
    uint256 nextAllocation = getAllocationFractionNextEpoch(borrower);
    uint256 allocation = Math.min(currentAllocation, nextAllocation);

    // If we are in the blackout window, use the next active balance. Otherwise, use current.
    // Note that the next active balance is never greater than the current active balance.
    uint256 availableTokens;
    if (inBlackoutWindow()) {
      availableTokens = getTotalActiveBalanceNextEpoch();
    } else {
      availableTokens = getTotalActiveBalanceCurrentEpoch();
    }
    return availableTokens.mul(allocation).div(TOTAL_ALLOCATION);
  }

  // ============ Private Functions ============

  function _loadBorrowerAllocation(
    address borrower
  )
    private
    view
    returns (LS1Types.StoredAllocation memory)
  {
    LS1Types.StoredAllocation memory allocation = _BORROWER_ALLOCATIONS_[borrower];

    // Ignore rollover logic before epoch zero.
    if (hasEpochZeroStarted()) {
      uint256 currentEpoch = getCurrentEpoch();
      if (currentEpoch > uint256(allocation.currentEpoch)) {
        // Roll the allocation forward.
        allocation.currentEpoch = currentEpoch.toUint16();
        allocation.currentEpochAllocation = allocation.nextEpochAllocation;
      }
    }

    return allocation;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { SafeERC20 } from '../../../dependencies/open-zeppelin/SafeERC20.sol';
import { SafeMath } from '../../../dependencies/open-zeppelin/SafeMath.sol';
import { IERC20 } from '../../../interfaces/IERC20.sol';
import { Math } from '../../../utils/Math.sol';
import { LS1Types } from '../lib/LS1Types.sol';
import { LS1ERC20 } from './LS1ERC20.sol';
import { LS1StakedBalances } from './LS1StakedBalances.sol';

/**
 * @title LS1Staking
 * @author dYdX
 *
 * @dev External functions for stakers. See LS1StakedBalances for details on staker accounting.
 */
abstract contract LS1Staking is
  LS1StakedBalances,
  LS1ERC20
{
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  // ============ Events ============

  event Staked(
    address indexed staker,
    address spender,
    uint256 amount
  );

  event WithdrawalRequested(
    address indexed staker,
    uint256 amount
  );

  event WithdrewStake(
    address indexed staker,
    address recipient,
    uint256 amount
  );

  event WithdrewDebt(
    address indexed staker,
    address recipient,
    uint256 amount,
    uint256 newDebtBalance
  );

  // ============ Constants ============

  IERC20 public immutable STAKED_TOKEN;

  // ============ Constructor ============

  constructor(
    IERC20 stakedToken,
    IERC20 rewardsToken,
    address rewardsTreasury,
    uint256 distributionStart,
    uint256 distributionEnd
  )
    LS1StakedBalances(rewardsToken, rewardsTreasury, distributionStart, distributionEnd)
  {
    STAKED_TOKEN = stakedToken;
  }

  // ============ External Functions ============

  /**
   * @notice Deposit and stake funds. These funds are active and start earning rewards immediately.
   *
   * @param  amount  The amount to stake.
   */
  function stake(
    uint256 amount
  )
    external
    nonReentrant
  {
    _stake(msg.sender, amount);
  }

  /**
   * @notice Deposit and stake on behalf of another address.
   *
   * @param  staker  The staker who will receive the stake.
   * @param  amount  The amount to stake.
   */
  function stakeFor(
    address staker,
    uint256 amount
  )
    external
    nonReentrant
  {
    _stake(staker, amount);
  }

  /**
   * @notice Request to withdraw funds. Starting in the next epoch, the funds will be “inactive”
   *  and available for withdrawal. Inactive funds do not earn rewards.
   *
   *  Reverts if we are currently in the blackout window.
   *
   * @param  amount  The amount to move from the active to the inactive balance.
   */
  function requestWithdrawal(
    uint256 amount
  )
    external
    nonReentrant
  {
    _requestWithdrawal(msg.sender, amount);
  }

  /**
   * @notice Withdraw the sender's inactive funds, and send to the specified recipient.
   *
   * @param  recipient  The address that should receive the funds.
   * @param  amount     The amount to withdraw from the sender's inactive balance.
   */
  function withdrawStake(
    address recipient,
    uint256 amount
  )
    external
    nonReentrant
  {
    _withdrawStake(msg.sender, recipient, amount);
  }

  /**
   * @notice Withdraw the max available inactive funds, and send to the specified recipient.
   *
   *  This is less gas-efficient than querying the max via eth_call and calling withdrawStake().
   *
   * @param  recipient  The address that should receive the funds.
   *
   * @return The withdrawn amount.
   */
  function withdrawMaxStake(
    address recipient
  )
    external
    nonReentrant
    returns (uint256)
  {
    uint256 amount = getStakeAvailableToWithdraw(msg.sender);
    _withdrawStake(msg.sender, recipient, amount);
    return amount;
  }

  /**
   * @notice Withdraw a debt amount owed to the sender, and send to the specified recipient.
   *
   * @param  recipient  The address that should receive the funds.
   * @param  amount     The token amount to withdraw from the sender's debt balance.
   */
  function withdrawDebt(
    address recipient,
    uint256 amount
  )
    external
    nonReentrant
  {
    _withdrawDebt(msg.sender, recipient, amount);
  }

  /**
   * @notice Withdraw the max available debt amount.
   *
   *  This is less gas-efficient than querying the max via eth_call and calling withdrawDebt().
   *
   * @param  recipient  The address that should receive the funds.
   *
   * @return The withdrawn amount.
   */
  function withdrawMaxDebt(
    address recipient
  )
    external
    nonReentrant
    returns (uint256)
  {
    uint256 amount = getDebtAvailableToWithdraw(msg.sender);
    _withdrawDebt(msg.sender, recipient, amount);
    return amount;
  }

  /**
   * @notice Settle and claim all rewards, and send them to the specified recipient.
   *
   *  Call this function with eth_call to query the claimable rewards balance.
   *
   * @param  recipient  The address that should receive the funds.
   *
   * @return The number of rewards tokens claimed.
   */
  function claimRewards(
    address recipient
  )
    external
    nonReentrant
    returns (uint256)
  {
    return _settleAndClaimRewards(msg.sender, recipient); // Emits an event internally.
  }

  // ============ Public Functions ============

  /**
   * @notice Get the amount of stake available to withdraw taking into account the contract balance.
   *
   * @param  staker  The address whose balance to check.
   *
   * @return The staker's stake amount that is inactive and available to withdraw.
   */
  function getStakeAvailableToWithdraw(
    address staker
  )
    public
    view
    returns (uint256)
  {
    // Note that the next epoch inactive balance is always at least that of the current epoch.
    uint256 stakerBalance = getInactiveBalanceCurrentEpoch(staker);
    uint256 totalStakeAvailable = getContractBalanceAvailableToWithdraw();
    return Math.min(stakerBalance, totalStakeAvailable);
  }

  /**
   * @notice Get the funds currently available in the contract for staker withdrawals.
   *
   * @return The amount of non-debt funds in the contract.
   */
  function getContractBalanceAvailableToWithdraw()
    public
    view
    returns (uint256)
  {
    uint256 contractBalance = STAKED_TOKEN.balanceOf(address(this));
    uint256 availableDebtBalance = _TOTAL_DEBT_AVAILABLE_TO_WITHDRAW_;
    return contractBalance.sub(availableDebtBalance); // Should never underflow.
  }

  /**
   * @notice Get the amount of debt available to withdraw.
   *
   * @param  staker  The address whose balance to check.
   *
   * @return The debt amount that can be withdrawn.
   */
  function getDebtAvailableToWithdraw(
    address staker
  )
    public
    view
    returns (uint256)
  {
    // Note that `totalDebtAvailable` should never be less than the contract token balance.
    uint256 stakerDebtBalance = getStakerDebtBalance(staker);
    uint256 totalDebtAvailable = _TOTAL_DEBT_AVAILABLE_TO_WITHDRAW_;
    return Math.min(stakerDebtBalance, totalDebtAvailable);
  }

  // ============ Internal Functions ============

  function _stake(
    address staker,
    uint256 amount
  )
    internal
  {
    // Increase current and next active balance.
    _increaseCurrentAndNextActiveBalance(staker, amount);

    // Transfer token from the sender.
    STAKED_TOKEN.safeTransferFrom(msg.sender, address(this), amount);

    emit Staked(staker, msg.sender, amount);
    emit Transfer(address(0), msg.sender, amount);
  }

  function _requestWithdrawal(
    address staker,
    uint256 amount
  )
    internal
  {
    require(
      !inBlackoutWindow(),
      'LS1Staking: Withdraw requests restricted in the blackout window'
    );

    // Get the staker's requestable amount and revert if there is not enough to request withdrawal.
    uint256 requestableBalance = getActiveBalanceNextEpoch(staker);
    require(
      amount <= requestableBalance,
      'LS1Staking: Withdraw request exceeds next active balance'
    );

    // Move amount from active to inactive in the next epoch.
    _moveNextBalanceActiveToInactive(staker, amount);

    emit WithdrawalRequested(staker, amount);
  }

  function _withdrawStake(
    address staker,
    address recipient,
    uint256 amount
  )
    internal
  {
    // Get contract available amount and revert if there is not enough to withdraw.
    uint256 totalStakeAvailable = getContractBalanceAvailableToWithdraw();
    require(
      amount <= totalStakeAvailable,
      'LS1Staking: Withdraw exceeds amount available in the contract'
    );

    // Get staker withdrawable balance and revert if there is not enough to withdraw.
    uint256 withdrawableBalance = getInactiveBalanceCurrentEpoch(staker);
    require(
      amount <= withdrawableBalance,
      'LS1Staking: Withdraw exceeds inactive balance'
    );

    // Decrease the staker's current and next inactive balance. Reverts if balance is insufficient.
    _decreaseCurrentAndNextInactiveBalance(staker, amount);

    // Transfer token to the recipient.
    STAKED_TOKEN.safeTransfer(recipient, amount);

    emit Transfer(msg.sender, address(0), amount);
    emit WithdrewStake(staker, recipient, amount);
  }

  // ============ Private Functions ============

  function _withdrawDebt(
    address staker,
    address recipient,
    uint256 amount
  )
    private
  {
    // Get old amounts and revert if there is not enough to withdraw.
    uint256 oldDebtBalance = _settleStakerDebtBalance(staker);
    require(
      amount <= oldDebtBalance,
      'LS1Staking: Withdraw debt exceeds debt owed'
    );
    uint256 oldDebtAvailable = _TOTAL_DEBT_AVAILABLE_TO_WITHDRAW_;
    require(
      amount <= oldDebtAvailable,
      'LS1Staking: Withdraw debt exceeds amount available'
    );

    // Caculate updated amounts and update storage.
    uint256 newDebtBalance = oldDebtBalance.sub(amount);
    uint256 newDebtAvailable = oldDebtAvailable.sub(amount);
    _STAKER_DEBT_BALANCES_[staker] = newDebtBalance;
    _TOTAL_DEBT_AVAILABLE_TO_WITHDRAW_ = newDebtAvailable;

    // Transfer token to the recipient.
    STAKED_TOKEN.safeTransfer(recipient, amount);

    emit WithdrewDebt(staker, recipient, amount, newDebtBalance);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

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
    assembly {
      codehash := extcodehash(account)
    }
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
    require(address(this).balance >= amount, 'Address: insufficient balance');

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{value: amount}('');
    require(success, 'Address: unable to send value, recipient may have reverted');
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { SafeMath } from '../../../dependencies/open-zeppelin/SafeMath.sol';
import { IERC20 } from '../../../interfaces/IERC20.sol';
import { LS1Types } from '../lib/LS1Types.sol';
import { SafeCast } from '../lib/SafeCast.sol';
import { LS1Rewards } from './LS1Rewards.sol';

/**
 * @title LS1StakedBalances
 * @author dYdX
 *
 * @dev Accounting of staked balances.
 *
 *  NOTE: Internal functions may revert if epoch zero has not started.
 *
 *  STAKED BALANCE ACCOUNTING:
 *
 *   A staked balance is in one of two states:
 *     - active: Available for borrowing; earning staking rewards; cannot be withdrawn by staker.
 *     - inactive: Unavailable for borrowing; does not earn rewards; can be withdrawn by the staker.
 *
 *   A staker may have a combination of active and inactive balances. The following operations
 *   affect staked balances as follows:
 *     - deposit:            Increase active balance.
 *     - request withdrawal: At the end of the current epoch, move some active funds to inactive.
 *     - withdraw:           Decrease inactive balance.
 *     - transfer:           Move some active funds to another staker.
 *
 *   To encode the fact that a balance may be scheduled to change at the end of a certain epoch, we
 *   store each balance as a struct of three fields: currentEpoch, currentEpochBalance, and
 *   nextEpochBalance. Also, inactive user balances make use of the shortfallCounter field as
 *   described below.
 *
 *  INACTIVE BALANCE ACCOUNTING:
 *
 *   Inactive funds may be subject to pro-rata socialized losses in the event of a shortfall where
 *   a borrower is late to pay back funds that have been requested for withdrawal. We track losses
 *   via indexes. Each index represents the fraction of inactive funds that were converted into
 *   debt during a given shortfall event. Each staker inactive balance stores a cached shortfall
 *   counter, representing the number of shortfalls that occurred in the past relative to when the
 *   balance was last updated.
 *
 *   Any losses incurred by an inactive balance translate into an equal credit to that staker's
 *   debt balance. See LS1DebtAccounting for more info about how the index is calculated.
 *
 *  REWARDS ACCOUNTING:
 *
 *   Active funds earn rewards for the period of time that they remain active. This means, after
 *   requesting a withdrawal of some funds, those funds will continue to earn rewards until the end
 *   of the epoch. For example:
 *
 *     epoch: n        n + 1      n + 2      n + 3
 *            |          |          |          |
 *            +----------+----------+----------+-----...
 *               ^ t_0: User makes a deposit.
 *                          ^ t_1: User requests a withdrawal of all funds.
 *                                  ^ t_2: The funds change state from active to inactive.
 *
 *   In the above scenario, the user would earn rewards for the period from t_0 to t_2, varying
 *   with the total staked balance in that period. If the user only request a withdrawal for a part
 *   of their balance, then the remaining balance would continue earning rewards beyond t_2.
 *
 *   User rewards must be settled via LS1Rewards any time a user's active balance changes. Special
 *   attention is paid to the the epoch boundaries, where funds may have transitioned from active
 *   to inactive.
 *
 *  SETTLEMENT DETAILS:
 *
 *   Internally, this module uses the following types of operations on stored balances:
 *     - Load:            Loads a balance, while applying settlement logic internally to get the
 *                        up-to-date result. Returns settlement results without updating state.
 *     - Store:           Stores a balance.
 *     - Load-for-update: Performs a load and applies updates as needed to rewards or debt balances.
 *                        Since this is state-changing, it must be followed by a store operation.
 *     - Settle:          Performs load-for-update and store operations.
 *
 *   This module is responsible for maintaining the following invariants to ensure rewards are
 *   calculated correctly:
 *     - When an active balance is loaded for update, if a rollover occurs from one epoch to the
 *       next, the rewards index must be settled up to the boundary at which the rollover occurs.
 *     - Because the global rewards index is needed to update the user rewards index, the total
 *       active balance must be settled before any staker balances are settled or loaded for update.
 *     - A staker's balance must be settled before their rewards are settled.
 */
abstract contract LS1StakedBalances is
  LS1Rewards
{
  using SafeCast for uint256;
  using SafeMath for uint256;

  // ============ Constants ============

  uint256 internal constant SHORTFALL_INDEX_BASE = 1e36;

  // ============ Events ============

  event ReceivedDebt(
    address indexed staker,
    uint256 amount,
    uint256 newDebtBalance
  );

  // ============ Constructor ============

  constructor(
    IERC20 rewardsToken,
    address rewardsTreasury,
    uint256 distributionStart,
    uint256 distributionEnd
  )
    LS1Rewards(rewardsToken, rewardsTreasury, distributionStart, distributionEnd)
  {}

  // ============ Public Functions ============

  /**
   * @notice Get the current active balance of a staker.
   */
  function getActiveBalanceCurrentEpoch(
    address staker
  )
    public
    view
    returns (uint256)
  {
    if (!hasEpochZeroStarted()) {
      return 0;
    }
    (LS1Types.StoredBalance memory balance, , , ) = _loadActiveBalance(_ACTIVE_BALANCES_[staker]);
    return uint256(balance.currentEpochBalance);
  }

  /**
   * @notice Get the next epoch active balance of a staker.
   */
  function getActiveBalanceNextEpoch(
    address staker
  )
    public
    view
    returns (uint256)
  {
    if (!hasEpochZeroStarted()) {
      return 0;
    }
    (LS1Types.StoredBalance memory balance, , , ) = _loadActiveBalance(_ACTIVE_BALANCES_[staker]);
    return uint256(balance.nextEpochBalance);
  }

  /**
   * @notice Get the current total active balance.
   */
  function getTotalActiveBalanceCurrentEpoch()
    public
    view
    returns (uint256)
  {
    if (!hasEpochZeroStarted()) {
      return 0;
    }
    (LS1Types.StoredBalance memory balance, , , ) = _loadActiveBalance(_TOTAL_ACTIVE_BALANCE_);
    return uint256(balance.currentEpochBalance);
  }

  /**
   * @notice Get the next epoch total active balance.
   */
  function getTotalActiveBalanceNextEpoch()
    public
    view
    returns (uint256)
  {
    if (!hasEpochZeroStarted()) {
      return 0;
    }
    (LS1Types.StoredBalance memory balance, , , ) = _loadActiveBalance(_TOTAL_ACTIVE_BALANCE_);
    return uint256(balance.nextEpochBalance);
  }

  /**
   * @notice Get the current inactive balance of a staker.
   * @dev The balance is converted via the index to token units.
   */
  function getInactiveBalanceCurrentEpoch(
    address staker
  )
    public
    view
    returns (uint256)
  {
    if (!hasEpochZeroStarted()) {
      return 0;
    }
    (LS1Types.StoredBalance memory balance, ) =
      _loadUserInactiveBalance(_INACTIVE_BALANCES_[staker]);
    return uint256(balance.currentEpochBalance);
  }

  /**
   * @notice Get the next epoch inactive balance of a staker.
   * @dev The balance is converted via the index to token units.
   */
  function getInactiveBalanceNextEpoch(
    address staker
  )
    public
    view
    returns (uint256)
  {
    if (!hasEpochZeroStarted()) {
      return 0;
    }
    (LS1Types.StoredBalance memory balance, ) =
      _loadUserInactiveBalance(_INACTIVE_BALANCES_[staker]);
    return uint256(balance.nextEpochBalance);
  }

  /**
   * @notice Get the current total inactive balance.
   */
  function getTotalInactiveBalanceCurrentEpoch()
    public
    view
    returns (uint256)
  {
    if (!hasEpochZeroStarted()) {
      return 0;
    }
    LS1Types.StoredBalance memory balance = _loadTotalInactiveBalance(_TOTAL_INACTIVE_BALANCE_);
    return uint256(balance.currentEpochBalance);
  }

  /**
   * @notice Get the next epoch total inactive balance.
   */
  function getTotalInactiveBalanceNextEpoch()
    public
    view
    returns (uint256)
  {
    if (!hasEpochZeroStarted()) {
      return 0;
    }
    LS1Types.StoredBalance memory balance = _loadTotalInactiveBalance(_TOTAL_INACTIVE_BALANCE_);
    return uint256(balance.nextEpochBalance);
  }

  /**
   * @notice Get a staker's debt balance, after accounting for unsettled shortfalls.
   *  Note that this does not modify _STAKER_DEBT_BALANCES_, so the debt balance must still be
   *  settled before it can be withdrawn.
   *
   * @param  staker  The staker to get the balance of.
   *
   * @return The settled debt balance.
   */
  function getStakerDebtBalance(
    address staker
  )
    public
    view
    returns (uint256)
  {
    if (!hasEpochZeroStarted()) {
      return 0;
    }
    (, uint256 newDebtAmount) = _loadUserInactiveBalance(_INACTIVE_BALANCES_[staker]);
    return _STAKER_DEBT_BALANCES_[staker].add(newDebtAmount);
  }

  /**
   * @notice Get the current transferable balance for a user. The user can
   *  only transfer their balance that is not currently inactive or going to be
   *  inactive in the next epoch. Note that this means the user's transferable funds
   *  are their active balance of the next epoch.
   *
   * @param  account  The account to get the transferable balance of.
   *
   * @return The user's transferable balance.
   */
  function getTransferableBalance(
    address account
  )
    public
    view
    returns (uint256)
  {
    return getActiveBalanceNextEpoch(account);
  }

  // ============ Internal Functions ============

  function _increaseCurrentAndNextActiveBalance(
    address staker,
    uint256 amount
  )
    internal
  {
    // Always settle total active balance before settling a staker active balance.
    uint256 oldTotalBalance = _increaseCurrentAndNextBalances(address(0), true, amount);
    uint256 oldUserBalance = _increaseCurrentAndNextBalances(staker, true, amount);

    // When an active balance changes at current timestamp, settle rewards to the current timestamp.
    _settleUserRewardsUpToNow(staker, oldUserBalance, oldTotalBalance);
  }

  function _moveNextBalanceActiveToInactive(
    address staker,
    uint256 amount
  )
    internal
  {
    // Decrease the active balance for the next epoch.
    // Always settle total active balance before settling a staker active balance.
    _decreaseNextBalance(address(0), true, amount);
    _decreaseNextBalance(staker, true, amount);

    // Increase the inactive balance for the next epoch.
    _increaseNextBalance(address(0), false, amount);
    _increaseNextBalance(staker, false, amount);

    // Note that we don't need to settle rewards since the current active balance did not change.
  }

  function _transferCurrentAndNextActiveBalance(
    address sender,
    address recipient,
    uint256 amount
  )
    internal
  {
    // Always settle total active balance before settling a staker active balance.
    uint256 totalBalance = _settleTotalActiveBalance();

    // Move current and next active balances from sender to recipient.
    uint256 oldSenderBalance = _decreaseCurrentAndNextBalances(sender, true, amount);
    uint256 oldRecipientBalance = _increaseCurrentAndNextBalances(recipient, true, amount);

    // When an active balance changes at current timestamp, settle rewards to the current timestamp.
    _settleUserRewardsUpToNow(sender, oldSenderBalance, totalBalance);
    _settleUserRewardsUpToNow(recipient, oldRecipientBalance, totalBalance);
  }

  function _decreaseCurrentAndNextInactiveBalance(
    address staker,
    uint256 amount
  )
    internal
  {
    // Decrease the inactive balance for the next epoch.
    _decreaseCurrentAndNextBalances(address(0), false, amount);
    _decreaseCurrentAndNextBalances(staker, false, amount);

    // Note that we don't settle rewards since active balances are not affected.
  }

  function _settleTotalActiveBalance()
    internal
    returns (uint256)
  {
    return _settleBalance(address(0), true);
  }

  function _settleStakerDebtBalance(
    address staker
  )
    internal
    returns (uint256)
  {
    // Settle the inactive balance to settle any new debt.
    _settleBalance(staker, false);

    // Return the settled debt balance.
    return _STAKER_DEBT_BALANCES_[staker];
  }

  function _settleAndClaimRewards(
    address staker,
    address recipient
  )
    internal
    returns (uint256)
  {
    // Always settle total active balance before settling a staker active balance.
    uint256 totalBalance = _settleTotalActiveBalance();

    // Always settle staker active balance before settling staker rewards.
    uint256 userBalance = _settleBalance(staker, true);

    // Settle rewards balance since we want to claim the full accrued amount.
    _settleUserRewardsUpToNow(staker, userBalance, totalBalance);

    // Claim rewards balance.
    return _claimRewards(staker, recipient);
  }

  function _applyShortfall(
    uint256 shortfallAmount,
    uint256 shortfallIndex
  )
    internal
  {
    // Decrease the total inactive balance.
    _decreaseCurrentAndNextBalances(address(0), false, shortfallAmount);

    _SHORTFALLS_.push(LS1Types.Shortfall({
      epoch: getCurrentEpoch().toUint16(),
      index: shortfallIndex.toUint224()
    }));
  }

  /**
   * @dev Does the same thing as _settleBalance() for a user inactive balance, but limits
   *  the epoch we progress to, in order that we can put an upper bound on the gas expenditure of
   *  the function. See LS1Failsafe.
   */
  function _failsafeSettleUserInactiveBalance(
    address staker,
    uint256 maxEpoch
  )
    internal
  {
    LS1Types.StoredBalance storage balancePtr = _getBalancePtr(staker, false);
    LS1Types.StoredBalance memory balance =
      _failsafeLoadUserInactiveBalanceForUpdate(balancePtr, staker, maxEpoch);
    _storeBalance(balancePtr, balance);
  }

  /**
   * @dev Sets the user inactive balance to zero. See LS1Failsafe.
   *
   *  Since the balance will never be settled, the staker loses any debt balance that they would
   *  have otherwise been entitled to from shortfall losses.
   *
   *  Also note that we don't update the total inactive balance, but this is fine.
   */
  function _failsafeDeleteUserInactiveBalance(
    address staker
  )
    internal
  {
    LS1Types.StoredBalance storage balancePtr = _getBalancePtr(staker, false);
    LS1Types.StoredBalance memory balance =
      LS1Types.StoredBalance({
        currentEpoch: 0,
        currentEpochBalance: 0,
        nextEpochBalance: 0,
        shortfallCounter: 0
      });
    _storeBalance(balancePtr, balance);
  }

  // ============ Private Functions ============

  /**
   * @dev Load a balance for update and then store it.
   */
  function _settleBalance(
    address maybeStaker,
    bool isActiveBalance
  )
    private
    returns (uint256)
  {
    LS1Types.StoredBalance storage balancePtr = _getBalancePtr(maybeStaker, isActiveBalance);
    LS1Types.StoredBalance memory balance =
      _loadBalanceForUpdate(balancePtr, maybeStaker, isActiveBalance);

    uint256 currentBalance = uint256(balance.currentEpochBalance);

    _storeBalance(balancePtr, balance);
    return currentBalance;
  }

  /**
   * @dev Settle a balance while applying an increase.
   */
  function _increaseCurrentAndNextBalances(
    address maybeStaker,
    bool isActiveBalance,
    uint256 amount
  )
    private
    returns (uint256)
  {
    LS1Types.StoredBalance storage balancePtr = _getBalancePtr(maybeStaker, isActiveBalance);
    LS1Types.StoredBalance memory balance =
      _loadBalanceForUpdate(balancePtr, maybeStaker, isActiveBalance);

    uint256 originalCurrentBalance = uint256(balance.currentEpochBalance);
    balance.currentEpochBalance = originalCurrentBalance.add(amount).toUint112();
    balance.nextEpochBalance = uint256(balance.nextEpochBalance).add(amount).toUint112();

    _storeBalance(balancePtr, balance);
    return originalCurrentBalance;
  }

  /**
   * @dev Settle a balance while applying a decrease.
   */
  function _decreaseCurrentAndNextBalances(
    address maybeStaker,
    bool isActiveBalance,
    uint256 amount
  )
    private
    returns (uint256)
  {
    LS1Types.StoredBalance storage balancePtr = _getBalancePtr(maybeStaker, isActiveBalance);
    LS1Types.StoredBalance memory balance =
      _loadBalanceForUpdate(balancePtr, maybeStaker, isActiveBalance);

    uint256 originalCurrentBalance = uint256(balance.currentEpochBalance);
    balance.currentEpochBalance = originalCurrentBalance.sub(amount).toUint112();
    balance.nextEpochBalance = uint256(balance.nextEpochBalance).sub(amount).toUint112();

    _storeBalance(balancePtr, balance);
    return originalCurrentBalance;
  }

  /**
   * @dev Settle a balance while applying an increase.
   */
  function _increaseNextBalance(
    address maybeStaker,
    bool isActiveBalance,
    uint256 amount
  )
    private
  {
    LS1Types.StoredBalance storage balancePtr = _getBalancePtr(maybeStaker, isActiveBalance);
    LS1Types.StoredBalance memory balance =
      _loadBalanceForUpdate(balancePtr, maybeStaker, isActiveBalance);

    balance.nextEpochBalance = uint256(balance.nextEpochBalance).add(amount).toUint112();

    _storeBalance(balancePtr, balance);
  }

  /**
   * @dev Settle a balance while applying a decrease.
   */
  function _decreaseNextBalance(
    address maybeStaker,
    bool isActiveBalance,
    uint256 amount
  )
    private
  {
    LS1Types.StoredBalance storage balancePtr = _getBalancePtr(maybeStaker, isActiveBalance);
    LS1Types.StoredBalance memory balance =
      _loadBalanceForUpdate(balancePtr, maybeStaker, isActiveBalance);

    balance.nextEpochBalance = uint256(balance.nextEpochBalance).sub(amount).toUint112();

    _storeBalance(balancePtr, balance);
  }

  function _getBalancePtr(
    address maybeStaker,
    bool isActiveBalance
  )
    private
    view
    returns (LS1Types.StoredBalance storage)
  {
    // Active.
    if (isActiveBalance) {
      if (maybeStaker != address(0)) {
        return _ACTIVE_BALANCES_[maybeStaker];
      }
      return _TOTAL_ACTIVE_BALANCE_;
    }

    // Inactive.
    if (maybeStaker != address(0)) {
      return _INACTIVE_BALANCES_[maybeStaker];
    }
    return _TOTAL_INACTIVE_BALANCE_;
  }

  /**
   * @dev Load a balance for updating.
   *
   *  IMPORTANT: This function modifies state, and so the balance MUST be stored afterwards.
   *    - For active balances: if a rollover occurs, rewards are settled to the epoch boundary.
   *    - For inactive user balances: if a shortfall occurs, the user's debt balance is increased.
   *
   * @param  balancePtr       A storage pointer to the balance.
   * @param  maybeStaker      The user address, or address(0) to update total balance.
   * @param  isActiveBalance  Whether the balance is an active balance.
   */
  function _loadBalanceForUpdate(
    LS1Types.StoredBalance storage balancePtr,
    address maybeStaker,
    bool isActiveBalance
  )
    private
    returns (LS1Types.StoredBalance memory)
  {
    // Active balance.
    if (isActiveBalance) {
      (
        LS1Types.StoredBalance memory balance,
        uint256 beforeRolloverEpoch,
        uint256 beforeRolloverBalance,
        bool didRolloverOccur
      ) = _loadActiveBalance(balancePtr);
      if (didRolloverOccur) {
        // Handle the effect of the balance rollover on rewards. We must partially settle the index
        // up to the epoch boundary where the change in balance occurred. We pass in the balance
        // from before the boundary.
        if (maybeStaker == address(0)) {
          // If it's the total active balance...
          _settleGlobalIndexUpToEpoch(beforeRolloverBalance, beforeRolloverEpoch);
        } else {
          // If it's a user active balance...
          _settleUserRewardsUpToEpoch(maybeStaker, beforeRolloverBalance, beforeRolloverEpoch);
        }
      }
      return balance;
    }

    // Total inactive balance.
    if (maybeStaker == address(0)) {
      return _loadTotalInactiveBalance(balancePtr);
    }

    // User inactive balance.
    (LS1Types.StoredBalance memory balance, uint256 newStakerDebt) =
      _loadUserInactiveBalance(balancePtr);
    if (newStakerDebt != 0) {
      uint256 newDebtBalance = _STAKER_DEBT_BALANCES_[maybeStaker].add(newStakerDebt);
      _STAKER_DEBT_BALANCES_[maybeStaker] = newDebtBalance;
      emit ReceivedDebt(maybeStaker, newStakerDebt, newDebtBalance);
    }
    return balance;
  }

  function _loadActiveBalance(
    LS1Types.StoredBalance storage balancePtr
  )
    private
    view
    returns (
      LS1Types.StoredBalance memory,
      uint256,
      uint256,
      bool
    )
  {
    LS1Types.StoredBalance memory balance = balancePtr;

    // Return these as they may be needed for rewards settlement.
    uint256 beforeRolloverEpoch = uint256(balance.currentEpoch);
    uint256 beforeRolloverBalance = uint256(balance.currentEpochBalance);
    bool didRolloverOccur = false;

    // Roll the balance forward if needed.
    uint256 currentEpoch = getCurrentEpoch();
    if (currentEpoch > uint256(balance.currentEpoch)) {
      didRolloverOccur = balance.currentEpochBalance != balance.nextEpochBalance;

      balance.currentEpoch = currentEpoch.toUint16();
      balance.currentEpochBalance = balance.nextEpochBalance;
    }

    return (balance, beforeRolloverEpoch, beforeRolloverBalance, didRolloverOccur);
  }

  function _loadTotalInactiveBalance(
    LS1Types.StoredBalance storage balancePtr
  )
    private
    view
    returns (LS1Types.StoredBalance memory)
  {
    LS1Types.StoredBalance memory balance = balancePtr;

    // Roll the balance forward if needed.
    uint256 currentEpoch = getCurrentEpoch();
    if (currentEpoch > uint256(balance.currentEpoch)) {
      balance.currentEpoch = currentEpoch.toUint16();
      balance.currentEpochBalance = balance.nextEpochBalance;
    }

    return balance;
  }

  function _loadUserInactiveBalance(
    LS1Types.StoredBalance storage balancePtr
  )
    private
    view
    returns (LS1Types.StoredBalance memory, uint256)
  {
    LS1Types.StoredBalance memory balance = balancePtr;
    uint256 currentEpoch = getCurrentEpoch();

    // If there is no non-zero balance, sync the epoch number and shortfall counter and exit.
    // Note: Next inactive balance is always >= current, so we only need to check next.
    if (balance.nextEpochBalance == 0) {
      balance.currentEpoch = currentEpoch.toUint16();
      balance.shortfallCounter = _SHORTFALLS_.length.toUint16();
      return (balance, 0);
    }

    // Apply any pending shortfalls that don't affect the “next epoch” balance.
    uint256 newStakerDebt;
    (balance, newStakerDebt) = _applyShortfallsToBalance(balance);

    // Roll the balance forward if needed.
    if (currentEpoch > uint256(balance.currentEpoch)) {
      balance.currentEpoch = currentEpoch.toUint16();
      balance.currentEpochBalance = balance.nextEpochBalance;

      // Check for more shortfalls affecting the “next epoch” and beyond.
      uint256 moreNewStakerDebt;
      (balance, moreNewStakerDebt) = _applyShortfallsToBalance(balance);
      newStakerDebt = newStakerDebt.add(moreNewStakerDebt);
    }

    return (balance, newStakerDebt);
  }

  function _applyShortfallsToBalance(
    LS1Types.StoredBalance memory balance
  )
    private
    view
    returns (LS1Types.StoredBalance memory, uint256)
  {
    // Get the cached and global shortfall counters.
    uint256 shortfallCounter = uint256(balance.shortfallCounter);
    uint256 globalShortfallCounter = _SHORTFALLS_.length;

    // If the counters are in sync, then there is nothing to do.
    if (shortfallCounter == globalShortfallCounter) {
      return (balance, 0);
    }

    // Get the balance params.
    uint16 cachedEpoch = balance.currentEpoch;
    uint256 oldCurrentBalance = uint256(balance.currentEpochBalance);

    // Calculate the new balance after applying shortfalls.
    //
    // Note: In theory, this while-loop may render an account's funds inaccessible if there are
    // too many shortfalls, and too much gas is required to apply them all. This is very unlikely
    // to occur in practice, but we provide _failsafeLoadUserInactiveBalance() just in case to
    // ensure recovery is possible.
    uint256 newCurrentBalance = oldCurrentBalance;
    while (shortfallCounter < globalShortfallCounter) {
      LS1Types.Shortfall memory shortfall = _SHORTFALLS_[shortfallCounter];

      // Stop applying shortfalls if they are in the future relative to the balance current epoch.
      if (shortfall.epoch > cachedEpoch) {
        break;
      }

      // Update the current balance to reflect the shortfall.
      uint256 shortfallIndex = uint256(shortfall.index);
      newCurrentBalance = newCurrentBalance.mul(shortfallIndex).div(SHORTFALL_INDEX_BASE);

      // Increment the staker's shortfall counter.
      shortfallCounter = shortfallCounter.add(1);
    }

    // Calculate the loss.
    // If the loaded balance is stored, this amount must be added to the staker's debt balance.
    uint256 newStakerDebt = oldCurrentBalance.sub(newCurrentBalance);

    // Update the balance.
    balance.currentEpochBalance = newCurrentBalance.toUint112();
    balance.nextEpochBalance = uint256(balance.nextEpochBalance).sub(newStakerDebt).toUint112();
    balance.shortfallCounter = shortfallCounter.toUint16();
    return (balance, newStakerDebt);
  }

  /**
   * @dev Store a balance.
   */
  function _storeBalance(
    LS1Types.StoredBalance storage balancePtr,
    LS1Types.StoredBalance memory balance
  )
    private
  {
    // Note: This should use a single `sstore` when compiler optimizations are enabled.
    balancePtr.currentEpoch = balance.currentEpoch;
    balancePtr.currentEpochBalance = balance.currentEpochBalance;
    balancePtr.nextEpochBalance = balance.nextEpochBalance;
    balancePtr.shortfallCounter = balance.shortfallCounter;
  }

  /**
   * @dev Does the same thing as _loadBalanceForUpdate() for a user inactive balance, but limits
   *  the epoch we progress to, in order that we can put an upper bound on the gas expenditure of
   *  the function. See LS1Failsafe.
   */
  function _failsafeLoadUserInactiveBalanceForUpdate(
    LS1Types.StoredBalance storage balancePtr,
    address staker,
    uint256 maxEpoch
  )
    private
    returns (LS1Types.StoredBalance memory)
  {
    LS1Types.StoredBalance memory balance = balancePtr;

    // Validate maxEpoch.
    uint256 currentEpoch = getCurrentEpoch();
    uint256 cachedEpoch = uint256(balance.currentEpoch);
    require(
      maxEpoch >= cachedEpoch && maxEpoch <= currentEpoch,
      'LS1StakedBalances: maxEpoch'
    );

    // Apply any pending shortfalls that don't affect the “next epoch” balance.
    uint256 newStakerDebt;
    (balance, newStakerDebt) = _applyShortfallsToBalance(balance);

    // Roll the balance forward if needed.
    if (maxEpoch > cachedEpoch) {
      balance.currentEpoch = maxEpoch.toUint16(); // Use maxEpoch instead of currentEpoch.
      balance.currentEpochBalance = balance.nextEpochBalance;

      // Check for more shortfalls affecting the “next epoch” and beyond.
      uint256 moreNewStakerDebt;
      (balance, moreNewStakerDebt) = _applyShortfallsToBalance(balance);
      newStakerDebt = newStakerDebt.add(moreNewStakerDebt);
    }

    // Apply debt if needed.
    if (newStakerDebt != 0) {
      uint256 newDebtBalance = _STAKER_DEBT_BALANCES_[staker].add(newStakerDebt);
      _STAKER_DEBT_BALANCES_[staker] = newDebtBalance;
      emit ReceivedDebt(staker, newStakerDebt, newDebtBalance);
    }
    return balance;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { SafeERC20 } from '../../../dependencies/open-zeppelin/SafeERC20.sol';
import { SafeMath } from '../../../dependencies/open-zeppelin/SafeMath.sol';
import { IERC20 } from '../../../interfaces/IERC20.sol';
import { Math } from '../../../utils/Math.sol';
import { SafeCast } from '../lib/SafeCast.sol';
import { LS1EpochSchedule } from './LS1EpochSchedule.sol';

/**
 * @title LS1Rewards
 * @author dYdX
 *
 * @dev Manages the distribution of token rewards.
 *
 *  Rewards are distributed continuously. After each second, an account earns rewards `r` according
 *  to the following formula:
 *
 *      r = R * s / S
 *
 *  Where:
 *    - `R` is the rewards distributed globally each second, also called the “emission rate.”
 *    - `s` is the account's staked balance in that second (technically, it is measured at the
 *      end of the second)
 *    - `S` is the sum total of all staked balances in that second (again, measured at the end of
 *      the second)
 *
 *  The parameter `R` can be configured by the contract owner. For every second that elapses,
 *  exactly `R` tokens will accrue to users, save for rounding errors, and with the exception that
 *  while the total staked balance is zero, no tokens will accrue to anyone.
 *
 *  The accounting works as follows: A global index is stored which represents the cumulative
 *  number of rewards tokens earned per staked token since the start of the distribution.
 *  The value of this index increases over time, and there are two factors affecting the rate of
 *  increase:
 *    1) The emission rate (in the numerator)
 *    2) The total number of staked tokens (in the denominator)
 *
 *  Whenever either factor changes, in some timestamp T, we settle the global index up to T by
 *  calculating the increase in the index since the last update using the OLD values of the factors:
 *
 *    indexDelta = timeDelta * emissionPerSecond * INDEX_BASE / totalStaked
 *
 *  Where `INDEX_BASE` is a scaling factor used to allow more precision in the storage of the index.
 *
 *  For each user we store an accrued rewards balance, as well as a user index, which is a cache of
 *  the global index at the time that the user's accrued rewards balance was last updated. Then at
 *  any point in time, a user's claimable rewards are represented by the following:
 *
 *    rewards = _USER_REWARDS_BALANCES_[user] + userStaked * (
 *                settledGlobalIndex - _USER_INDEXES_[user]
 *              ) / INDEX_BASE
 */
abstract contract LS1Rewards is
  LS1EpochSchedule
{
  using SafeERC20 for IERC20;
  using SafeCast for uint256;
  using SafeMath for uint256;

  // ============ Constants ============

  /// @dev Additional precision used to represent the global and user index values.
  uint256 private constant INDEX_BASE = 10**18;

  /// @notice The rewards token.
  IERC20 public immutable REWARDS_TOKEN;

  /// @notice Address to pull rewards from. Must have provided an allowance to this contract.
  address public immutable REWARDS_TREASURY;

  /// @notice Start timestamp (inclusive) of the period in which rewards can be earned.
  uint256 public immutable DISTRIBUTION_START;

  /// @notice End timestamp (exclusive) of the period in which rewards can be earned.
  uint256 public immutable DISTRIBUTION_END;

  // ============ Events ============

  event RewardsPerSecondUpdated(
    uint256 emissionPerSecond
  );

  event GlobalIndexUpdated(
    uint256 index
  );

  event UserIndexUpdated(
    address indexed user,
    uint256 index,
    uint256 unclaimedRewards
  );

  event ClaimedRewards(
    address indexed user,
    address recipient,
    uint256 claimedRewards
  );

  // ============ Constructor ============

  constructor(
    IERC20 rewardsToken,
    address rewardsTreasury,
    uint256 distributionStart,
    uint256 distributionEnd
  ) {
    require(distributionEnd >= distributionStart, 'LS1Rewards: Invalid parameters');
    REWARDS_TOKEN = rewardsToken;
    REWARDS_TREASURY = rewardsTreasury;
    DISTRIBUTION_START = distributionStart;
    DISTRIBUTION_END = distributionEnd;
  }

  // ============ External Functions ============

  /**
   * @notice The current emission rate of rewards.
   *
   * @return The number of rewards tokens issued globally each second.
   */
  function getRewardsPerSecond()
    external
    view
    returns (uint256)
  {
    return _REWARDS_PER_SECOND_;
  }

  // ============ Internal Functions ============

  /**
   * @dev Initialize the contract.
   */
  function __LS1Rewards_init()
    internal
  {
    _GLOBAL_INDEX_TIMESTAMP_ = Math.max(block.timestamp, DISTRIBUTION_START).toUint32();
  }

  /**
   * @dev Set the emission rate of rewards.
   *
   *  IMPORTANT: Do not call this function without settling the total staked balance first, to
   *  ensure that the index is settled up to the epoch boundaries.
   *
   * @param  emissionPerSecond  The new number of rewards tokens to give out each second.
   * @param  totalStaked        The total staked balance.
   */
  function _setRewardsPerSecond(
    uint256 emissionPerSecond,
    uint256 totalStaked
  )
    internal
  {
    _settleGlobalIndexUpToNow(totalStaked);
    _REWARDS_PER_SECOND_ = emissionPerSecond;
    emit RewardsPerSecondUpdated(emissionPerSecond);
  }

  /**
   * @dev Claim tokens, sending them to the specified recipient.
   *
   *  Note: In order to claim all accrued rewards, the total and user staked balances must first be
   *  settled before calling this function.
   *
   * @param  user       The user's address.
   * @param  recipient  The address to send rewards to.
   *
   * @return The number of rewards tokens claimed.
   */
  function _claimRewards(
    address user,
    address recipient
  )
    internal
    returns (uint256)
  {
    uint256 accruedRewards = _USER_REWARDS_BALANCES_[user];
    _USER_REWARDS_BALANCES_[user] = 0;
    REWARDS_TOKEN.safeTransferFrom(REWARDS_TREASURY, recipient, accruedRewards);
    emit ClaimedRewards(user, recipient, accruedRewards);
    return accruedRewards;
  }

  /**
   * @dev Settle a user's rewards up to the latest global index as of `block.timestamp`. Triggers a
   *  settlement of the global index up to `block.timestamp`. Should be called with the OLD user
   *  and total balances.
   *
   * @param  user         The user's address.
   * @param  userStaked   Tokens staked by the user during the period since the last user index
   *                      update.
   * @param  totalStaked  Total tokens staked by all users during the period since the last global
   *                      index update.
   *
   * @return The user's accrued rewards, including past unclaimed rewards.
   */
  function _settleUserRewardsUpToNow(
    address user,
    uint256 userStaked,
    uint256 totalStaked
  )
    internal
    returns (uint256)
  {
    uint256 globalIndex = _settleGlobalIndexUpToNow(totalStaked);
    return _settleUserRewardsUpToIndex(user, userStaked, globalIndex);
  }

  /**
   * @dev Settle a user's rewards up to an epoch boundary. Should be used to partially settle a
   *  user's rewards if their balance was known to have changed on that epoch boundary.
   *
   * @param  user         The user's address.
   * @param  userStaked   Tokens staked by the user. Should be accurate for the time period
   *                      since the last update to this user and up to the end of the
   *                      specified epoch.
   * @param  epochNumber  Settle the user's rewards up to the end of this epoch.
   *
   * @return The user's accrued rewards, including past unclaimed rewards, up to the end of the
   *  specified epoch.
   */
  function _settleUserRewardsUpToEpoch(
    address user,
    uint256 userStaked,
    uint256 epochNumber
  )
    internal
    returns (uint256)
  {
    uint256 globalIndex = _EPOCH_INDEXES_[epochNumber];
    return _settleUserRewardsUpToIndex(user, userStaked, globalIndex);
  }

  /**
   * @dev Settle the global index up to the end of the given epoch.
   *
   *  IMPORTANT: This function should only be called under conditions which ensure the following:
   *    - `epochNumber` < the current epoch number
   *    - `_GLOBAL_INDEX_TIMESTAMP_ < settleUpToTimestamp`
   *    - `_EPOCH_INDEXES_[epochNumber] = 0`
   */
  function _settleGlobalIndexUpToEpoch(
    uint256 totalStaked,
    uint256 epochNumber
  )
    internal
    returns (uint256)
  {
    uint256 settleUpToTimestamp = getStartOfEpoch(epochNumber.add(1));

    uint256 globalIndex = _settleGlobalIndexUpToTimestamp(totalStaked, settleUpToTimestamp);
    _EPOCH_INDEXES_[epochNumber] = globalIndex;
    return globalIndex;
  }

  // ============ Private Functions ============

  function _settleGlobalIndexUpToNow(
    uint256 totalStaked
  )
    private
    returns (uint256)
  {
    return _settleGlobalIndexUpToTimestamp(totalStaked, block.timestamp);
  }

  /**
   * @dev Helper function which settles a user's rewards up to a global index. Should be called
   *  any time a user's staked balance changes, with the OLD user and total balances.
   *
   * @param  user            The user's address.
   * @param  userStaked      Tokens staked by the user during the period since the last user index
   *                         update.
   * @param  newGlobalIndex  The new index value to bring the user index up to.
   *
   * @return The user's accrued rewards, including past unclaimed rewards.
   */
  function _settleUserRewardsUpToIndex(
    address user,
    uint256 userStaked,
    uint256 newGlobalIndex
  )
    private
    returns (uint256)
  {
    uint256 oldAccruedRewards = _USER_REWARDS_BALANCES_[user];
    uint256 oldUserIndex = _USER_INDEXES_[user];

    if (oldUserIndex == newGlobalIndex) {
      return oldAccruedRewards;
    }

    uint256 newAccruedRewards;
    if (userStaked == 0) {
      // Note: Even if the user's staked balance is zero, we still need to update the user index.
      newAccruedRewards = oldAccruedRewards;
    } else {
      // Calculate newly accrued rewards since the last update to the user's index.
      uint256 indexDelta = newGlobalIndex.sub(oldUserIndex);
      uint256 accruedRewardsDelta = userStaked.mul(indexDelta).div(INDEX_BASE);
      newAccruedRewards = oldAccruedRewards.add(accruedRewardsDelta);

      // Update the user's rewards.
      _USER_REWARDS_BALANCES_[user] = newAccruedRewards;
    }

    // Update the user's index.
    _USER_INDEXES_[user] = newGlobalIndex;
    emit UserIndexUpdated(user, newGlobalIndex, newAccruedRewards);
    return newAccruedRewards;
  }

  /**
   * @dev Updates the global index, reflecting cumulative rewards given out per staked token.
   *
   * @param  totalStaked          The total staked balance, which should be constant in the interval
   *                              (_GLOBAL_INDEX_TIMESTAMP_, settleUpToTimestamp).
   * @param  settleUpToTimestamp  The timestamp up to which to settle rewards. It MUST satisfy
   *                              `settleUpToTimestamp <= block.timestamp`.
   *
   * @return The new global index.
   */
  function _settleGlobalIndexUpToTimestamp(
    uint256 totalStaked,
    uint256 settleUpToTimestamp
  )
    private
    returns (uint256)
  {
    uint256 oldGlobalIndex = uint256(_GLOBAL_INDEX_);

    // The goal of this function is to calculate rewards earned since the last global index update.
    // These rewards are earned over the time interval which is the intersection of the intervals
    // [_GLOBAL_INDEX_TIMESTAMP_, settleUpToTimestamp] and [DISTRIBUTION_START, DISTRIBUTION_END].
    //
    // We can simplify a bit based on the assumption:
    //   `_GLOBAL_INDEX_TIMESTAMP_ >= DISTRIBUTION_START`
    //
    // Get the start and end of the time interval under consideration.
    uint256 intervalStart = uint256(_GLOBAL_INDEX_TIMESTAMP_);
    uint256 intervalEnd = Math.min(settleUpToTimestamp, DISTRIBUTION_END);

    // Return early if the interval has length zero (incl. case where intervalEnd < intervalStart).
    if (intervalEnd <= intervalStart) {
      return oldGlobalIndex;
    }

    // Note: If we reach this point, we must update _GLOBAL_INDEX_TIMESTAMP_.

    uint256 emissionPerSecond = _REWARDS_PER_SECOND_;

    if (emissionPerSecond == 0 || totalStaked == 0) {
      // Ensure a log is emitted if the timestamp changed, even if the index does not change.
      _GLOBAL_INDEX_TIMESTAMP_ = intervalEnd.toUint32();
      emit GlobalIndexUpdated(oldGlobalIndex);
      return oldGlobalIndex;
    }

    // Calculate the change in index over the interval.
    uint256 timeDelta = intervalEnd.sub(intervalStart);
    uint256 indexDelta = timeDelta.mul(emissionPerSecond).mul(INDEX_BASE).div(totalStaked);

    // Calculate, update, and return the new global index.
    uint256 newGlobalIndex = oldGlobalIndex.add(indexDelta);

    // Update storage. (Shared storage slot.)
    _GLOBAL_INDEX_TIMESTAMP_ = intervalEnd.toUint32();
    _GLOBAL_INDEX_ = newGlobalIndex.toUint224();

    emit GlobalIndexUpdated(newGlobalIndex);
    return newGlobalIndex;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { SafeMath } from '../../../dependencies/open-zeppelin/SafeMath.sol';
import { LS1Types } from '../lib/LS1Types.sol';
import { SafeCast } from '../lib/SafeCast.sol';
import { LS1Roles } from './LS1Roles.sol';

/**
 * @title LS1EpochSchedule
 * @author dYdX
 *
 * @dev Defines a function from block timestamp to epoch number.
 *
 *  The formula used is `n = floor((t - b) / a)` where:
 *    - `n` is the epoch number
 *    - `t` is the timestamp (in seconds)
 *    - `b` is a non-negative offset, indicating the start of epoch zero (in seconds)
 *    - `a` is the length of an epoch, a.k.a. the interval (in seconds)
 *
 *  Note that by restricting `b` to be non-negative, we limit ourselves to functions in which epoch
 *  zero starts at a non-negative timestamp.
 *
 *  The recommended epoch length and blackout window are 28 and 7 days respectively; however, these
 *  are modifiable by the admin, within the specified bounds.
 */
abstract contract LS1EpochSchedule is
  LS1Roles
{
  using SafeCast for uint256;
  using SafeMath for uint256;

  // ============ Constants ============

  /// @dev Minimum blackout window. Note: The min epoch length is twice the current blackout window.
  uint256 private constant MIN_BLACKOUT_WINDOW = 3 days;

  /// @dev Maximum epoch length. Note: The max blackout window is half the current epoch length.
  uint256 private constant MAX_EPOCH_LENGTH = 92 days; // Approximately one quarter year.

  // ============ Events ============

  event EpochParametersChanged(
    LS1Types.EpochParameters epochParameters
  );

  event BlackoutWindowChanged(
    uint256 blackoutWindow
  );

  // ============ Initializer ============

  function __LS1EpochSchedule_init(
    uint256 interval,
    uint256 offset,
    uint256 blackoutWindow
  )
    internal
  {
    require(
      block.timestamp < offset,
      'LS1EpochSchedule: Epoch zero must be in future'
    );

    // Don't use _setBlackoutWindow() since the interval is not set yet and validation would fail.
    _BLACKOUT_WINDOW_ = blackoutWindow;
    emit BlackoutWindowChanged(blackoutWindow);

    _setEpochParameters(interval, offset);
  }

  // ============ Public Functions ============

  /**
   * @notice Get the epoch at the current block timestamp.
   *
   *  NOTE: Reverts if epoch zero has not started.
   *
   * @return The current epoch number.
   */
  function getCurrentEpoch()
    public
    view
    returns (uint256)
  {
    (uint256 interval, uint256 offsetTimestamp) = _getIntervalAndOffsetTimestamp();
    return offsetTimestamp.div(interval);
  }

  /**
   * @notice Get the time remaining in the current epoch.
   *
   *  NOTE: Reverts if epoch zero has not started.
   *
   * @return The number of seconds until the next epoch.
   */
  function getTimeRemainingInCurrentEpoch()
    public
    view
    returns (uint256)
  {
    (uint256 interval, uint256 offsetTimestamp) = _getIntervalAndOffsetTimestamp();
    uint256 timeElapsedInEpoch = offsetTimestamp.mod(interval);
    return interval.sub(timeElapsedInEpoch);
  }

  /**
   * @notice Given an epoch number, get the start of that epoch. Calculated as `t = (n * a) + b`.
   *
   * @return The timestamp in seconds representing the start of that epoch.
   */
  function getStartOfEpoch(
    uint256 epochNumber
  )
    public
    view
    returns (uint256)
  {
    LS1Types.EpochParameters memory epochParameters = _EPOCH_PARAMETERS_;
    uint256 interval = uint256(epochParameters.interval);
    uint256 offset = uint256(epochParameters.offset);
    return epochNumber.mul(interval).add(offset);
  }

  /**
   * @notice Check whether we are at or past the start of epoch zero.
   *
   * @return Boolean `true` if the current timestamp is at least the start of epoch zero,
   *  otherwise `false`.
   */
  function hasEpochZeroStarted()
    public
    view
    returns (bool)
  {
    LS1Types.EpochParameters memory epochParameters = _EPOCH_PARAMETERS_;
    uint256 offset = uint256(epochParameters.offset);
    return block.timestamp >= offset;
  }

  /**
   * @notice Check whether we are in a blackout window, where withdrawal requests are restricted.
   *  Note that before epoch zero has started, there are no blackout windows.
   *
   * @return Boolean `true` if we are in a blackout window, otherwise `false`.
   */
  function inBlackoutWindow()
    public
    view
    returns (bool)
  {
    return hasEpochZeroStarted() && getTimeRemainingInCurrentEpoch() <= _BLACKOUT_WINDOW_;
  }

  // ============ Internal Functions ============

  function _setEpochParameters(
    uint256 interval,
    uint256 offset
  )
    internal
  {
    _validateParamLengths(interval, _BLACKOUT_WINDOW_);
    LS1Types.EpochParameters memory epochParameters =
      LS1Types.EpochParameters({interval: interval.toUint128(), offset: offset.toUint128()});
    _EPOCH_PARAMETERS_ = epochParameters;
    emit EpochParametersChanged(epochParameters);
  }

  function _setBlackoutWindow(
    uint256 blackoutWindow
  )
    internal
  {
    _validateParamLengths(uint256(_EPOCH_PARAMETERS_.interval), blackoutWindow);
    _BLACKOUT_WINDOW_ = blackoutWindow;
    emit BlackoutWindowChanged(blackoutWindow);
  }

  // ============ Private Functions ============

  /**
   * @dev Helper function to read params from storage and apply offset to the given timestamp.
   *
   *  NOTE: Reverts if epoch zero has not started.
   *
   * @return The length of an epoch, in seconds.
   * @return The start of epoch zero, in seconds.
   */
  function _getIntervalAndOffsetTimestamp()
    private
    view
    returns (uint256, uint256)
  {
    LS1Types.EpochParameters memory epochParameters = _EPOCH_PARAMETERS_;
    uint256 interval = uint256(epochParameters.interval);
    uint256 offset = uint256(epochParameters.offset);

    require(block.timestamp >= offset, 'LS1EpochSchedule: Epoch zero has not started');

    uint256 offsetTimestamp = block.timestamp.sub(offset);
    return (interval, offsetTimestamp);
  }

  /**
   * @dev Helper for common validation: verify that the interval and window lengths are valid.
   */
  function _validateParamLengths(
    uint256 interval,
    uint256 blackoutWindow
  )
    private
    pure
  {
    require(
      blackoutWindow.mul(2) <= interval,
      'LS1EpochSchedule: Blackout window can be at most half the epoch length'
    );
    require(
      blackoutWindow >= MIN_BLACKOUT_WINDOW,
      'LS1EpochSchedule: Blackout window too large'
    );
    require(
      interval <= MAX_EPOCH_LENGTH,
      'LS1EpochSchedule: Epoch length too small'
    );
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { LS1Storage } from './LS1Storage.sol';

/**
 * @title LS1Roles
 * @author dYdX
 *
 * @dev Defines roles used in the LiquidityStakingV1 contract. The hierarchy of roles and powers
 *  of each role are described below.
 *
 *  Roles:
 *
 *    OWNER_ROLE
 *      | -> May add or remove users from any of the below roles it manages.
 *      |
 *      +-- EPOCH_PARAMETERS_ROLE
 *      |     -> May set epoch parameters such as the interval, offset, and blackout window.
 *      |
 *      +-- REWARDS_RATE_ROLE
 *      |     -> May set the emission rate of rewards.
 *      |
 *      +-- BORROWER_ADMIN_ROLE
 *      |     -> May set borrower allocations and allow/restrict borrowers from borrowing.
 *      |
 *      +-- CLAIM_OPERATOR_ROLE
 *      |     -> May claim rewards on behalf of a user.
 *      |
 *      +-- STAKE_OPERATOR_ROLE
 *      |     -> May manipulate user's staked funds (e.g. perform withdrawals on behalf of a user).
 *      |
 *      +-- DEBT_OPERATOR_ROLE
 *           -> May decrease borrow debt and decrease staker debt.
 */
abstract contract LS1Roles is
  LS1Storage
{
  bytes32 public constant OWNER_ROLE = keccak256('OWNER_ROLE');
  bytes32 public constant EPOCH_PARAMETERS_ROLE = keccak256('EPOCH_PARAMETERS_ROLE');
  bytes32 public constant REWARDS_RATE_ROLE = keccak256('REWARDS_RATE_ROLE');
  bytes32 public constant BORROWER_ADMIN_ROLE = keccak256('BORROWER_ADMIN_ROLE');
  bytes32 public constant CLAIM_OPERATOR_ROLE = keccak256('CLAIM_OPERATOR_ROLE');
  bytes32 public constant STAKE_OPERATOR_ROLE = keccak256('STAKE_OPERATOR_ROLE');
  bytes32 public constant DEBT_OPERATOR_ROLE = keccak256('DEBT_OPERATOR_ROLE');

  function __LS1Roles_init() internal {
    // Assign roles to the sender.
    //
    // The DEBT_OPERATOR_ROLE, STAKE_OPERATOR_ROLE, and CLAIM_OPERATOR_ROLE roles are not
    // initially assigned. These can be assigned to other smart contracts to provide additional
    // functionality for users.
    _setupRole(OWNER_ROLE, msg.sender);
    _setupRole(EPOCH_PARAMETERS_ROLE, msg.sender);
    _setupRole(REWARDS_RATE_ROLE, msg.sender);
    _setupRole(BORROWER_ADMIN_ROLE, msg.sender);

    // Set OWNER_ROLE as the admin of all roles.
    _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
    _setRoleAdmin(EPOCH_PARAMETERS_ROLE, OWNER_ROLE);
    _setRoleAdmin(REWARDS_RATE_ROLE, OWNER_ROLE);
    _setRoleAdmin(BORROWER_ADMIN_ROLE, OWNER_ROLE);
    _setRoleAdmin(CLAIM_OPERATOR_ROLE, OWNER_ROLE);
    _setRoleAdmin(STAKE_OPERATOR_ROLE, OWNER_ROLE);
    _setRoleAdmin(DEBT_OPERATOR_ROLE, OWNER_ROLE);
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;

import { IERC20 } from './IERC20.sol';

/**
 * @dev Interface for ERC20 including metadata
 **/
interface IERC20Detailed is IERC20 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}