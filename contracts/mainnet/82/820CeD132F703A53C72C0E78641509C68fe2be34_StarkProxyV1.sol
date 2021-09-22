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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import {
  AccessControlUpgradeable
} from '../../../dependencies/open-zeppelin/AccessControlUpgradeable.sol';
import { ReentrancyGuard } from '../../../utils/ReentrancyGuard.sol';
import { VersionedInitializable } from '../../../utils/VersionedInitializable.sol';

/**
 * @title SP1Storage
 * @author dYdX
 *
 * @dev Storage contract. Contains or inherits from all contracts with storage.
 */
abstract contract SP1Storage is
  AccessControlUpgradeable,
  ReentrancyGuard,
  VersionedInitializable
{
  // ============ Modifiers ============

  /**
   * @dev Modifier to ensure the STARK key is allowed.
   */
  modifier onlyAllowedKey(
    uint256 starkKey
  ) {
    require(_ALLOWED_STARK_KEYS_[starkKey], 'SP1Storage: STARK key is not on the allowlist');
    _;
  }

  /**
   * @dev Modifier to ensure the recipient is allowed.
   */
  modifier onlyAllowedRecipient(
    address recipient
  ) {
    require(_ALLOWED_RECIPIENTS_[recipient], 'SP1Storage: Recipient is not on the allowlist');
    _;
  }

  // ============ Storage ============

  mapping(uint256 => bool) internal _ALLOWED_STARK_KEYS_;

  mapping(address => bool) internal _ALLOWED_RECIPIENTS_;

  /// @dev Note that withdrawals are always permitted if the amount is in excess of the borrowed
  ///  amount. Also, this approval only applies to the primary ERC20 token, `TOKEN`.
  uint256 internal _APPROVED_AMOUNT_FOR_EXTERNAL_WITHDRAWAL_;

  /// @dev Note that this is different from _IS_BORROWING_RESTRICTED_ in LiquidityStakingV1.
  bool internal _IS_BORROWING_RESTRICTED_;

  /// @dev Mapping from args hash to timestamp.
  mapping(bytes32 => uint256) internal _QUEUED_FORCED_TRADE_TIMESTAMPS_;
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { SafeMath } from '../../../dependencies/open-zeppelin/SafeMath.sol';
import { Math } from '../../../utils/Math.sol';
import { SP1Storage } from './SP1Storage.sol';

/**
 * @title SP1Getters
 * @author dYdX
 *
 * @dev Simple external getter functions.
 */
abstract contract SP1Getters is
  SP1Storage
{
  using SafeMath for uint256;

  // ============ External Functions ============

  /**
   * @notice Check whether a STARK key is on the allowlist for exchange operations.
   *
   * @param  starkKey  The STARK key to check.
   *
   * @return Boolean `true` if the STARK key is allowed, otherwise `false`.
   */
  function isStarkKeyAllowed(
    uint256 starkKey
  )
    external
    view
    returns (bool)
  {
    return _ALLOWED_STARK_KEYS_[starkKey];
  }

  /**
   * @notice Check whether a recipient is on the allowlist to receive withdrawals.
   *
   * @param  recipient  The recipient to check.
   *
   * @return Boolean `true` if the recipient is allowed, otherwise `false`.
   */
  function isRecipientAllowed(
    address recipient
  )
    external
    view
    returns (bool)
  {
    return _ALLOWED_RECIPIENTS_[recipient];
  }

  /**
   * @notice Get the amount approved by the guardian for external withdrawals.
   *  Note that withdrawals are always permitted if the amount is in excess of the borrowed amount.
   *
   * @return The amount approved for external withdrawals.
   */
  function getApprovedAmountForExternalWithdrawal()
    external
    view
    returns (uint256)
  {
    return _APPROVED_AMOUNT_FOR_EXTERNAL_WITHDRAWAL_;
  }

  /**
   * @notice Check whether this borrower contract is restricted from new borrowing, as well as
   *  restricted from depositing borrowed funds to the exchange.
   *
   * @return Boolean `true` if the borrower is restricted, otherwise `false`.
   */
  function isBorrowingRestricted()
    external
    view
    returns (bool)
  {
    return _IS_BORROWING_RESTRICTED_;
  }

  /**
   * @notice Get the timestamp at which a forced trade request was queued.
   *
   * @param  argsHash  The hash of the forced trade request args.
   *
   * @return Timestamp at which the forced trade was queued, or zero, if it was not queued or was
   *  vetoed by the VETO_GUARDIAN_ROLE.
   */
  function getQueuedForcedTradeTimestamp(
    bytes32 argsHash
  )
    external
    view
    returns (uint256)
  {
    return _QUEUED_FORCED_TRADE_TIMESTAMPS_[argsHash];
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

// Contracts by dYdX Foundation. Individual files are released under different licenses.
//
// https://dydx.community
// https://github.com/dydxfoundation/governance-contracts
//
// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.7.5;
pragma abicoder v2;

import { IERC20 } from '../../interfaces/IERC20.sol';
import { ILiquidityStakingV1 } from '../../interfaces/ILiquidityStakingV1.sol';
import { IMerkleDistributorV1 } from '../../interfaces/IMerkleDistributorV1.sol';
import { IStarkPerpetual } from '../../interfaces/IStarkPerpetual.sol';
import { SafeERC20 } from '../../dependencies/open-zeppelin/SafeERC20.sol';
import { SP1Withdrawals } from './impl/SP1Withdrawals.sol';
import { SP1Getters } from './impl/SP1Getters.sol';
import { SP1Guardian } from './impl/SP1Guardian.sol';
import { SP1Owner } from './impl/SP1Owner.sol';

/**
 * @title StarkProxyV1
 * @author dYdX
 *
 * @notice Proxy contract allowing a LiquidityStaking borrower to use borrowed funds (as well as
 *  their own funds, if desired) on the dYdX L2 exchange. Restrictions are put in place to
 *  prevent borrowed funds being used outside the exchange. Furthermore, a guardian address is
 *  specified which has the ability to restrict borrows and make repayments.
 *
 *  Owner actions may be delegated to various roles as defined in SP1Roles. Other actions are
 *  available to guardian roles, to be nominated by dYdX governance.
 */
contract StarkProxyV1 is
  SP1Guardian,
  SP1Owner,
  SP1Withdrawals,
  SP1Getters
{
  using SafeERC20 for IERC20;

  // ============ Constructor ============

  constructor(
    ILiquidityStakingV1 liquidityStaking,
    IStarkPerpetual starkPerpetual,
    IERC20 token,
    IMerkleDistributorV1 merkleDistributor
  )
    SP1Guardian(liquidityStaking, starkPerpetual, token)
    SP1Withdrawals(merkleDistributor)
  {}

  // ============ External Functions ============

  function initialize(address guardian)
    external
    initializer
  {
    __SP1Roles_init(guardian);
    TOKEN.safeApprove(address(LIQUIDITY_STAKING), uint256(-1));
    TOKEN.safeApprove(address(STARK_PERPETUAL), uint256(-1));
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

// SPDX-License-Identifier: MIT
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

/**
 * @title ILiquidityStakingV1
 * @author dYdX
 *
 * @notice Partial interface for LiquidityStakingV1.
 */
interface ILiquidityStakingV1 {

  function getToken() external view virtual returns (address);

  function getBorrowedBalance(address borrower) external view virtual returns (uint256);

  function getBorrowerDebtBalance(address borrower) external view virtual returns (uint256);

  function isBorrowingRestrictedForBorrower(address borrower) external view virtual returns (bool);

  function getTimeRemainingInEpoch() external view virtual returns (uint256);

  function inBlackoutWindow() external view virtual returns (bool);

  // LS1Borrowing
  function borrow(uint256 amount) external virtual;

  function repayBorrow(address borrower, uint256 amount) external virtual;

  function getAllocatedBalanceCurrentEpoch(address borrower)
    external
    view
    virtual
    returns (uint256);

  function getAllocatedBalanceNextEpoch(address borrower) external view virtual returns (uint256);

  function getBorrowableAmount(address borrower) external view virtual returns (uint256);

  // LS1DebtAccounting
  function repayDebt(address borrower, uint256 amount) external virtual;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.5;
pragma abicoder v2;

/**
 * @title IMerkleDistributorV1
 * @author dYdX
 *
 * @notice Partial interface for the MerkleDistributorV1 contract.
 */
interface IMerkleDistributorV1 {

  function getIpnsName()
    external
    virtual
    view
    returns (string memory);

  function getRewardsParameters()
    external
    virtual
    view
    returns (uint256, uint256, uint256);

  function getActiveRoot()
    external
    virtual
    view
    returns (bytes32 merkleRoot, uint256 epoch, bytes memory ipfsCid);

  function getNextRootEpoch()
    external
    virtual
    view
    returns (uint256);

  function claimRewards(
    uint256 cumulativeAmount,
    bytes32[] calldata merkleProof
  )
    external
    returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.5;
pragma abicoder v2;

/**
 * @title IStarkPerpetual
 * @author dYdX
 *
 * @notice Partial interface for the StarkPerpetual contract, for accessing the dYdX L2 exchange.
 * @dev See https://github.com/starkware-libs/starkex-contracts
 */
interface IStarkPerpetual {

  function registerUser(
    address ethKey,
    uint256 starkKey,
    bytes calldata signature
  ) external;

  function deposit(
    uint256 starkKey,
    uint256 assetType,
    uint256 vaultId,
    uint256 quantizedAmount
  ) external;

  function withdraw(uint256 starkKey, uint256 assetType) external;

  function forcedWithdrawalRequest(
    uint256 starkKey,
    uint256 vaultId,
    uint256 quantizedAmount,
    bool premiumCost
  ) external;

  function forcedTradeRequest(
    uint256 starkKeyA,
    uint256 starkKeyB,
    uint256 vaultIdA,
    uint256 vaultIdB,
    uint256 collateralAssetId,
    uint256 syntheticAssetId,
    uint256 amountCollateral,
    uint256 amountSynthetic,
    bool aIsBuyingSynthetic,
    uint256 submissionExpirationTime,
    uint256 nonce,
    bytes calldata signature,
    bool premiumCost
  ) external;

  function mainAcceptGovernance() external;
  function proxyAcceptGovernance() external;

  function mainRemoveGovernor(address governorForRemoval) external;
  function proxyRemoveGovernor(address governorForRemoval) external;

  function registerAssetConfigurationChange(uint256 assetId, bytes32 configHash) external;
  function applyAssetConfigurationChange(uint256 assetId, bytes32 configHash) external;

  function registerGlobalConfigurationChange(bytes32 configHash) external;
  function applyGlobalConfigurationChange(bytes32 configHash) external;

  function getEthKey(uint256 starkKey) external view returns (address);
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { SafeERC20 } from '../../../dependencies/open-zeppelin/SafeERC20.sol';
import { SafeMath } from '../../../dependencies/open-zeppelin/SafeMath.sol';
import { IERC20 } from '../../../interfaces/IERC20.sol';
import { IMerkleDistributorV1 } from '../../../interfaces/IMerkleDistributorV1.sol';
import { IStarkPerpetual } from '../../../interfaces/IStarkPerpetual.sol';
import { SP1Exchange } from './SP1Exchange.sol';

/**
 * @title SP1Withdrawals
 * @author dYdX
 *
 * @dev Actions which may be called only by WITHDRAWAL_OPERATOR_ROLE. Allows for withdrawing
 *  funds from the contract to external addresses that were approved by OWNER_ROLE.
 */
abstract contract SP1Withdrawals is
  SP1Exchange
{
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  // ============ Constants ============

  IMerkleDistributorV1 public immutable MERKLE_DISTRIBUTOR;

  // ============ Events ============

  event ExternalWithdrewToken(
    address recipient,
    uint256 amount
  );

  event ExternalWithdrewOtherToken(
    address token,
    address recipient,
    uint256 amount
  );

  event ExternalWithdrewEther(
    address recipient,
    uint256 amount
  );

  // ============ Constructor ============

  constructor(
    IMerkleDistributorV1 merkleDistributor
  ) {
    MERKLE_DISTRIBUTOR = merkleDistributor;
  }

  // ============ External Functions ============

  /**
   * @notice Claim rewards from the Merkle distributor. They will be held in this contract until
   *  withdrawn by the WITHDRAWAL_OPERATOR_ROLE.
   *
   * @param  cumulativeAmount  The total all-time rewards this contract has earned.
   * @param  merkleProof       The Merkle proof for this contract address and cumulative amount.
   *
   * @return The amount of new reward received.
   */
  function claimRewardsFromMerkleDistributor(
    uint256 cumulativeAmount,
    bytes32[] calldata merkleProof
  )
    external
    nonReentrant
    onlyRole(WITHDRAWAL_OPERATOR_ROLE)
    returns (uint256)
  {
    return MERKLE_DISTRIBUTOR.claimRewards(cumulativeAmount, merkleProof);
  }

  /**
   * @notice Withdraw a token amount in excess of the borrowed balance, or an amount approved by
   *  the GUARDIAN_ROLE.
   *
   *  The contract may hold an excess balance if, for example, additional funds were added by the
   *  contract owner for use with the same exchange account, or if profits were earned from
   *  activity on the exchange.
   *
   * @param  recipient  The recipient to receive tokens. Must be authorized by OWNER_ROLE.
   */
  function externalWithdrawToken(
    address recipient,
    uint256 amount
  )
    external
    nonReentrant
    onlyRole(WITHDRAWAL_OPERATOR_ROLE)
    onlyAllowedRecipient(recipient)
  {
    // If we are approved for the full amount, then skip the borrowed balance check.
    uint256 approvedAmount = _APPROVED_AMOUNT_FOR_EXTERNAL_WITHDRAWAL_;
    if (approvedAmount >= amount) {
      _APPROVED_AMOUNT_FOR_EXTERNAL_WITHDRAWAL_ = approvedAmount.sub(amount);
    } else {
      uint256 owedBalance = getBorrowedAndDebtBalance();
      uint256 tokenBalance = getTokenBalance();
      require(tokenBalance > owedBalance, 'SP1Withdrawals: No withdrawable balance');
      uint256 availableBalance = tokenBalance.sub(owedBalance);
      require(amount <= availableBalance, 'SP1Withdrawals: Amount exceeds withdrawable balance');

      // Always decrease the approval amount.
      _APPROVED_AMOUNT_FOR_EXTERNAL_WITHDRAWAL_ = 0;
    }

    TOKEN.safeTransfer(recipient, amount);
    emit ExternalWithdrewToken(recipient, amount);
  }

  /**
   * @notice Withdraw any ERC20 token balance other than the token used for borrowing.
   *
   * @param  recipient  The recipient to receive tokens. Must be authorized by OWNER_ROLE.
   */
  function externalWithdrawOtherToken(
    address token,
    address recipient,
    uint256 amount
  )
    external
    nonReentrant
    onlyRole(WITHDRAWAL_OPERATOR_ROLE)
    onlyAllowedRecipient(recipient)
  {
    require(
      token != address(TOKEN),
      'SP1Withdrawals: Cannot use this function to withdraw borrowed token'
    );
    IERC20(token).safeTransfer(recipient, amount);
    emit ExternalWithdrewOtherToken(token, recipient, amount);
  }

  /**
   * @notice Withdraw any ether.
   *
   *  Note: The contract is not expected to hold Ether so this is not normally needed.
   *
   * @param  recipient  The recipient to receive Ether. Must be authorized by OWNER_ROLE.
   */
  function externalWithdrawEther(
    address recipient,
    uint256 amount
  )
    external
    nonReentrant
    onlyRole(WITHDRAWAL_OPERATOR_ROLE)
    onlyAllowedRecipient(recipient)
  {
    payable(recipient).transfer(amount);
    emit ExternalWithdrewEther(recipient, amount);
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { SafeMath } from '../../../dependencies/open-zeppelin/SafeMath.sol';
import { IERC20 } from '../../../interfaces/IERC20.sol';
import { ILiquidityStakingV1 } from '../../../interfaces/ILiquidityStakingV1.sol';
import { IStarkPerpetual } from '../../../interfaces/IStarkPerpetual.sol';
import { SP1Borrowing } from './SP1Borrowing.sol';
import { SP1Exchange } from './SP1Exchange.sol';

/**
 * @title SP1Guardian
 * @author dYdX
 *
 * @dev Defines guardian powers, to be owned or delegated by dYdX governance.
 */
abstract contract SP1Guardian is
  SP1Borrowing,
  SP1Exchange
{
  using SafeMath for uint256;

  // ============ Events ============

  event BorrowingRestrictionChanged(
    bool isBorrowingRestricted
  );

  event GuardianVetoedForcedTradeRequest(
    bytes32 argsHash
  );

  event GuardianUpdateApprovedAmountForExternalWithdrawal(
    uint256 amount
  );

  // ============ Constructor ============

  constructor(
    ILiquidityStakingV1 liquidityStaking,
    IStarkPerpetual starkPerpetual,
    IERC20 token
  )
    SP1Borrowing(liquidityStaking, token)
    SP1Exchange(starkPerpetual)
  {}

  // ============ External Functions ============

  /**
   * @notice Approve an additional amount for external withdrawal by WITHDRAWAL_OPERATOR_ROLE.
   *
   * @param  amount  The additional amount to approve for external withdrawal.
   *
   * @return The new amount approved for external withdrawal.
   */
  function increaseApprovedAmountForExternalWithdrawal(
    uint256 amount
  )
    external
    nonReentrant
    onlyRole(GUARDIAN_ROLE)
    returns (uint256)
  {
    uint256 newApprovedAmount = _APPROVED_AMOUNT_FOR_EXTERNAL_WITHDRAWAL_.add(
      amount
    );
    _APPROVED_AMOUNT_FOR_EXTERNAL_WITHDRAWAL_ = newApprovedAmount;
    emit GuardianUpdateApprovedAmountForExternalWithdrawal(newApprovedAmount);
    return newApprovedAmount;
  }

  /**
   * @notice Set the approved amount for external withdrawal to zero.
   *
   * @return The amount that was previously approved for external withdrawal.
   */
  function resetApprovedAmountForExternalWithdrawal()
    external
    nonReentrant
    onlyRole(GUARDIAN_ROLE)
    returns (uint256)
  {
    uint256 previousApprovedAmount = _APPROVED_AMOUNT_FOR_EXTERNAL_WITHDRAWAL_;
    _APPROVED_AMOUNT_FOR_EXTERNAL_WITHDRAWAL_ = 0;
    emit GuardianUpdateApprovedAmountForExternalWithdrawal(0);
    return previousApprovedAmount;
  }

  /**
   * @notice Guardian method to restrict borrowing or depositing borrowed funds to the exchange.
   */
  function guardianSetBorrowingRestriction(
    bool isBorrowingRestricted
  )
    external
    nonReentrant
    onlyRole(GUARDIAN_ROLE)
  {
    _IS_BORROWING_RESTRICTED_ = isBorrowingRestricted;
    emit BorrowingRestrictionChanged(isBorrowingRestricted);
  }

  /**
   * @notice Guardian method to repay this contract's borrowed balance, using this contract's funds.
   *
   * @param  amount  Amount to repay.
   */
  function guardianRepayBorrow(
    uint256 amount
  )
    external
    nonReentrant
    onlyRole(GUARDIAN_ROLE)
  {
    _repayBorrow(amount, true);
  }

  /**
   * @notice Guardian method to repay a debt balance owed by the borrower.
   *
   * @param  amount  Amount to repay.
   */
  function guardianRepayDebt(
    uint256 amount
  )
    external
    nonReentrant
    onlyRole(GUARDIAN_ROLE)
  {
    _repayDebt(amount, true);
  }

  /**
   * @notice Guardian method to trigger a withdrawal. This will transfer funds from StarkPerpetual
   *  to this contract. This requires a (slow) withdrawal from L2 to have been previously processed.
   *
   *  Note: This function is intentionally not protected by the onlyAllowedKey modifier.
   *
   * @return The ERC20 token amount received by this contract.
   */
  function guardianWithdrawFromExchange(
    uint256 starkKey,
    uint256 assetType
  )
    external
    nonReentrant
    onlyRole(GUARDIAN_ROLE)
    returns (uint256)
  {
    return _withdrawFromExchange(starkKey, assetType, true);
  }

  /**
   * @notice Guardian method to trigger a forced withdrawal request.
   *  Reverts if the borrower has no overdue debt.
   *
   *  Note: This function is intentionally not protected by the onlyAllowedKey modifier.
   */
  function guardianForcedWithdrawalRequest(
    uint256 starkKey,
    uint256 vaultId,
    uint256 quantizedAmount,
    bool premiumCost
  )
    external
    nonReentrant
    onlyRole(GUARDIAN_ROLE)
  {
    require(
      getDebtBalance() > 0,
      'SP1Guardian: Cannot call forced action if borrower has no overdue debt'
    );
    _forcedWithdrawalRequest(
      starkKey,
      vaultId,
      quantizedAmount,
      premiumCost,
      true // isGuardianAction
    );
  }

  /**
   * @notice Guardian method to trigger a forced trade request.
   *  Reverts if the borrower has no overdue debt.
   *
   *  Note: This function is intentionally not protected by the onlyAllowedKey modifier.
   */
  function guardianForcedTradeRequest(
    uint256[12] calldata args,
    bytes calldata signature
  )
    external
    nonReentrant
    onlyRole(GUARDIAN_ROLE)
  {
    require(
      getDebtBalance() > 0,
      'SP1Guardian: Cannot call forced action if borrower has no overdue debt'
    );
    _forcedTradeRequest(args, signature, true);
  }

  /**
   * @notice Guardian method to prevent queued forced trade requests from being executed.
   *
   *  May only be called by VETO_GUARDIAN_ROLE.
   *
   * @param  argsHashes  An array of hashes for each forced trade request to veto.
   */
  function guardianVetoForcedTradeRequests(
    bytes32[] calldata argsHashes
  )
    external
    nonReentrant
    onlyRole(VETO_GUARDIAN_ROLE)
  {
    for (uint256 i = 0; i < argsHashes.length; i++) {
      bytes32 argsHash = argsHashes[i];
      _QUEUED_FORCED_TRADE_TIMESTAMPS_[argsHash] = 0;
      emit GuardianVetoedForcedTradeRequest(argsHash);
    }
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { SafeERC20 } from '../../../dependencies/open-zeppelin/SafeERC20.sol';
import { SafeMath } from '../../../dependencies/open-zeppelin/SafeMath.sol';
import { IERC20 } from '../../../interfaces/IERC20.sol';
import { IStarkPerpetual } from '../../../interfaces/IStarkPerpetual.sol';
import { SP1Borrowing } from './SP1Borrowing.sol';
import { SP1Exchange } from './SP1Exchange.sol';

/**
 * @title SP1Owner
 * @author dYdX
 *
 * @dev Actions which may be called only by OWNER_ROLE. These include actions with a larger amount
 *  of control over the funds held by the contract.
 */
abstract contract SP1Owner is
  SP1Borrowing,
  SP1Exchange
{
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  // ============ Constants ============

  /// @notice Time that must elapse before a queued forced trade request can be submitted.
  uint256 public constant FORCED_TRADE_WAITING_PERIOD = 7 days;

  /// @notice Max time that may elapse after the waiting period before a queued forced trade
  ///  request expires.
  uint256 public constant FORCED_TRADE_GRACE_PERIOD = 7 days;

  // ============ Events ============

  event UpdatedStarkKey(
    uint256 starkKey,
    bool isAllowed
  );

  event UpdatedExternalRecipient(
    address recipient,
    bool isAllowed
  );

  event QueuedForcedTradeRequest(
    uint256[12] args,
    bytes32 argsHash
  );

  // ============ External Functions ============

  /**
   * @notice Allow exchange functions to be called for a particular STARK key.
   *
   *  Will revert if the STARK key is not registered to this contract's address on the
   *  StarkPerpetual contract.
   *
   * @param  starkKey  The STARK key to allow.
   */
  function allowStarkKey(
    uint256 starkKey
  )
    external
    nonReentrant
    onlyRole(OWNER_ROLE)
  {
    // This will revert with 'USER_UNREGISTERED' if the STARK key was not registered.
    address ethKey = STARK_PERPETUAL.getEthKey(starkKey);

    // Require the STARK key to be registered to this contract before we allow it to be used.
    require(ethKey == address(this), 'SP1Owner: STARK key not registered to this contract');

    require(!_ALLOWED_STARK_KEYS_[starkKey], 'SP1Owner: STARK key already allowed');
    _ALLOWED_STARK_KEYS_[starkKey] = true;
    emit UpdatedStarkKey(starkKey, true);
  }

  /**
   * @notice Remove a STARK key from the allowed list.
   *
   * @param  starkKey  The STARK key to disallow.
   */
  function disallowStarkKey(
    uint256 starkKey
  )
    external
    nonReentrant
    onlyRole(OWNER_ROLE)
  {
    require(_ALLOWED_STARK_KEYS_[starkKey], 'SP1Owner: STARK key already disallowed');
    _ALLOWED_STARK_KEYS_[starkKey] = false;
    emit UpdatedStarkKey(starkKey, false);
  }

  /**
   * @notice Allow withdrawals of excess funds to be made to a particular recipient.
   *
   * @param  recipient  The recipient to allow.
   */
  function allowExternalRecipient(
    address recipient
  )
    external
    nonReentrant
    onlyRole(OWNER_ROLE)
  {
    require(!_ALLOWED_RECIPIENTS_[recipient], 'SP1Owner: Recipient already allowed');
    _ALLOWED_RECIPIENTS_[recipient] = true;
    emit UpdatedExternalRecipient(recipient, true);
  }

  /**
   * @notice Remove a recipient from the allowed list.
   *
   * @param  recipient  The recipient to disallow.
   */
  function disallowExternalRecipient(
    address recipient
  )
    external
    nonReentrant
    onlyRole(OWNER_ROLE)
  {
    require(_ALLOWED_RECIPIENTS_[recipient], 'SP1Owner: Recipient already disallowed');
    _ALLOWED_RECIPIENTS_[recipient] = false;
    emit UpdatedExternalRecipient(recipient, false);
  }

  /**
   * @notice Set ERC20 token allowance for the exchange contract.
   *
   * @param  token   The ERC20 token to set the allowance for.
   * @param  amount  The new allowance amount.
   */
  function setExchangeContractAllowance(
    address token,
    uint256 amount
  )
    external
    nonReentrant
    onlyRole(OWNER_ROLE)
  {
    // SafeERC20 safeApprove requires setting to zero first.
    IERC20(token).safeApprove(address(STARK_PERPETUAL), 0);
    IERC20(token).safeApprove(address(STARK_PERPETUAL), amount);
  }

  /**
   * @notice Set ERC20 token allowance for the staking contract.
   *
   * @param  token   The ERC20 token to set the allowance for.
   * @param  amount  The new allowance amount.
   */
  function setStakingContractAllowance(
    address token,
    uint256 amount
  )
    external
    nonReentrant
    onlyRole(OWNER_ROLE)
  {
    // SafeERC20 safeApprove requires setting to zero first.
    IERC20(token).safeApprove(address(LIQUIDITY_STAKING), 0);
    IERC20(token).safeApprove(address(LIQUIDITY_STAKING), amount);
  }

  /**
   * @notice Request a forced withdrawal from the exchange.
   *
   * @param  starkKey         The STARK key of the account. Must be authorized by OWNER_ROLE.
   * @param  vaultId          The exchange position ID for the account to deposit to.
   * @param  quantizedAmount  The withdrawal amount denominated in the exchange base units.
   * @param  premiumCost      Whether to pay a higher fee for faster inclusion in certain scenarios.
   */
  function forcedWithdrawalRequest(
    uint256 starkKey,
    uint256 vaultId,
    uint256 quantizedAmount,
    bool premiumCost
  )
    external
    nonReentrant
    onlyRole(OWNER_ROLE)
    onlyAllowedKey(starkKey)
  {
    _forcedWithdrawalRequest(starkKey, vaultId, quantizedAmount, premiumCost, false);
  }

  /**
   * @notice Queue a forced trade request to be submitted after the waiting period.
   *
   * @param  args  Arguments for the forced trade request.
   */
  function queueForcedTradeRequest(
    uint256[12] calldata args
  )
    external
    nonReentrant
    onlyRole(OWNER_ROLE)
  {
    bytes32 argsHash = keccak256(abi.encodePacked(args));
    _QUEUED_FORCED_TRADE_TIMESTAMPS_[argsHash] = block.timestamp;
    emit QueuedForcedTradeRequest(args, argsHash);
  }

  /**
   * @notice Submit a forced trade request that was previously queued.
   *
   * @param  args       Arguments for the forced trade request.
   * @param  signature  The signature of the counterparty to the trade.
   */
  function forcedTradeRequest(
    uint256[12] calldata args,
    bytes calldata signature
  )
    external
    nonReentrant
    onlyRole(OWNER_ROLE)
    onlyAllowedKey(args[0]) // starkKeyA
  {
    bytes32 argsHash = keccak256(abi.encodePacked(args));
    uint256 timestamp = _QUEUED_FORCED_TRADE_TIMESTAMPS_[argsHash];
    require(
      timestamp != 0,
      'SP1Owner: Forced trade not queued or was vetoed'
    );
    uint256 elapsed = block.timestamp.sub(timestamp);
    require(
      elapsed >= FORCED_TRADE_WAITING_PERIOD,
      'SP1Owner: Waiting period has not elapsed for forced trade'
    );
    require(
      elapsed <= FORCED_TRADE_WAITING_PERIOD.add(FORCED_TRADE_GRACE_PERIOD),
      'SP1Owner: Grace period has elapsed for forced trade'
    );
    _QUEUED_FORCED_TRADE_TIMESTAMPS_[argsHash] = 0;
    _forcedTradeRequest(args, signature, false);
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { SafeMath } from '../../../dependencies/open-zeppelin/SafeMath.sol';
import { IERC20 } from '../../../interfaces/IERC20.sol';
import { IStarkPerpetual } from '../../../interfaces/IStarkPerpetual.sol';
import { SP1Balances } from './SP1Balances.sol';

/**
 * @title SP1Exchange
 * @author dYdX
 *
 * @dev Handles calls to the StarkPerpetual contract, for interacting with the dYdX L2 exchange.
 *
 *  Standard exchange operation is handled by EXCHANGE_OPERATOR_ROLE. The “forced” actions can only
 *  be called by the OWNER_ROLE or GUARDIAN_ROLE. Some other functions are also callable by
 *  the GUARDIAN_ROLE.
 *
 *  See SP1Roles, SP1Guardian, SP1Owner, and SP1Withdrawals.
 */
abstract contract SP1Exchange is
  SP1Balances
{
  using SafeMath for uint256;

  // ============ Constants ============

  IStarkPerpetual public immutable STARK_PERPETUAL;

  // ============ Events ============

  event DepositedToExchange(
    uint256 starkKey,
    uint256 starkAssetType,
    uint256 starkVaultId,
    uint256 tokenAmount
  );

  event WithdrewFromExchange(
    uint256 starkKey,
    uint256 starkAssetType,
    uint256 tokenAmount,
    bool isGuardianAction
  );

  /// @dev Limited fields included. Details can be retrieved from Starkware logs if needed.
  event RequestedForcedWithdrawal(
    uint256 starkKey,
    uint256 vaultId,
    bool isGuardianAction
  );

  /// @dev Limited fields included. Details can be retrieved from Starkware logs if needed.
  event RequestedForcedTrade(
    uint256 starkKey,
    uint256 vaultId,
    bool isGuardianAction
  );

  // ============ Constructor ============

  constructor(
    IStarkPerpetual starkPerpetual
  ) {
    STARK_PERPETUAL = starkPerpetual;
  }

  // ============ External Functions ============

  /**
   * @notice Deposit funds to the exchange.
   *
   *  IMPORTANT: The caller is responsible for providing `quantizedAmount` in the right units.
   *             Currently, the exchange collateral is USDC, denominated in ERC20 token units, but
   *             this could change.
   *
   * @param  starkKey         The STARK key of the account. Must be authorized by OWNER_ROLE.
   * @param  assetType        The exchange asset ID for the asset to deposit.
   * @param  vaultId          The exchange position ID for the account to deposit to.
   * @param  quantizedAmount  The deposit amount denominated in the exchange base units.
   *
   * @return The ERC20 token amount spent.
   */
  function depositToExchange(
    uint256 starkKey,
    uint256 assetType,
    uint256 vaultId,
    uint256 quantizedAmount
  )
    external
    nonReentrant
    onlyRole(EXCHANGE_OPERATOR_ROLE)
    onlyAllowedKey(starkKey)
    returns (uint256)
  {
    // Deposit and get the deposited token amount.
    uint256 startingBalance = getTokenBalance();
    STARK_PERPETUAL.deposit(starkKey, assetType, vaultId, quantizedAmount);
    uint256 endingBalance = getTokenBalance();
    uint256 tokenAmount = startingBalance.sub(endingBalance);

    // Disallow depositing borrowed funds to the exchange if the guardian has restricted borrowing.
    if (_IS_BORROWING_RESTRICTED_) {
      require(
        endingBalance >= getBorrowedAndDebtBalance(),
        'SP1Borrowing: Cannot deposit borrowed funds to the exchange while Restricted'
      );
    }

    emit DepositedToExchange(starkKey, assetType, vaultId, tokenAmount);
    return tokenAmount;
  }

  /**
   * @notice Trigger a withdrawal of account funds held in the exchange contract. This can be
   *  called after a (slow) withdrawal has already been processed by the L2 exchange.
   *
   * @param  starkKey   The STARK key of the account. Must be authorized by OWNER_ROLE.
   * @param  assetType  The exchange asset ID for the asset to withdraw.
   *
   * @return The ERC20 token amount received by this contract.
   */
  function withdrawFromExchange(
    uint256 starkKey,
    uint256 assetType
  )
    external
    nonReentrant
    onlyRole(EXCHANGE_OPERATOR_ROLE)
    onlyAllowedKey(starkKey)
    returns (uint256)
  {
    return _withdrawFromExchange(starkKey, assetType, false);
  }

  // ============ Internal Functions ============

  function _withdrawFromExchange(
    uint256 starkKey,
    uint256 assetType,
    bool isGuardianAction
  )
    internal
    returns (uint256)
  {
    uint256 startingBalance = getTokenBalance();
    STARK_PERPETUAL.withdraw(starkKey, assetType);
    uint256 endingBalance = getTokenBalance();
    uint256 tokenAmount = endingBalance.sub(startingBalance);
    emit WithdrewFromExchange(starkKey, assetType, tokenAmount, isGuardianAction);
    return tokenAmount;
  }

  function _forcedWithdrawalRequest(
    uint256 starkKey,
    uint256 vaultId,
    uint256 quantizedAmount,
    bool premiumCost,
    bool isGuardianAction
  )
    internal
  {
    STARK_PERPETUAL.forcedWithdrawalRequest(starkKey, vaultId, quantizedAmount, premiumCost);
    emit RequestedForcedWithdrawal(starkKey, vaultId, isGuardianAction);
  }

  function _forcedTradeRequest(
    uint256[12] calldata args,
    bytes calldata signature,
    bool isGuardianAction
  )
    internal
  {
    // Split into two functions to avoid error 'call stack too deep'.
    if (args[11] != 0) {
      _forcedTradeRequestPremiumCostTrue(args, signature);
    } else {
      _forcedTradeRequestPremiumCostFalse(args, signature);
    }
    emit RequestedForcedTrade(
      args[0], // starkKeyA
      args[2], // vaultIdA
      isGuardianAction
    );
  }

  // ============ Private Functions ============

  // Split into two functions to avoid error 'call stack too deep'.
  function _forcedTradeRequestPremiumCostTrue(
    uint256[12] calldata args,
    bytes calldata signature
  )
    private
  {
    STARK_PERPETUAL.forcedTradeRequest(
      args[0],      // starkKeyA
      args[1],      // starkKeyB
      args[2],      // vaultIdA
      args[3],      // vaultIdB
      args[4],      // collateralAssetId
      args[5],      // syntheticAssetId
      args[6],      // amountCollateral
      args[7],      // amountSynthetic
      args[8] != 0, // aIsBuyingSynthetic
      args[9],      // submissionExpirationTime
      args[10],     // nonce
      signature,
      true          // premiumCost
    );
  }

  // Split into two functions to avoid error 'call stack too deep'.
  function _forcedTradeRequestPremiumCostFalse(
    uint256[12] calldata args,
    bytes calldata signature
  )
    private
  {
    STARK_PERPETUAL.forcedTradeRequest(
      args[0],      // starkKeyA
      args[1],      // starkKeyB
      args[2],      // vaultIdA
      args[3],      // vaultIdB
      args[4],      // collateralAssetId
      args[5],      // syntheticAssetId
      args[6],      // amountCollateral
      args[7],      // amountSynthetic
      args[8] != 0, // aIsBuyingSynthetic
      args[9],      // submissionExpirationTime
      args[10],     // nonce
      signature,
      false         // premiumCost
    );
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { SafeMath } from '../../../dependencies/open-zeppelin/SafeMath.sol';
import { IERC20 } from '../../../interfaces/IERC20.sol';
import { ILiquidityStakingV1 } from '../../../interfaces/ILiquidityStakingV1.sol';
import { Math } from '../../../utils/Math.sol';
import { SP1Roles } from './SP1Roles.sol';

/**
 * @title SP1Balances
 * @author dYdX
 *
 * @dev Contains common constants and functions related to token balances.
 */
abstract contract SP1Balances is
  SP1Roles
{
  using SafeMath for uint256;

  // ============ Constants ============

  IERC20 public immutable TOKEN;

  ILiquidityStakingV1 public immutable LIQUIDITY_STAKING;

  // ============ Constructor ============

  constructor(
    ILiquidityStakingV1 liquidityStaking,
    IERC20 token
  ) {
    LIQUIDITY_STAKING = liquidityStaking;
    TOKEN = token;
  }

  // ============ Public Functions ============

  function getAllocatedBalanceCurrentEpoch()
    public
    view
    returns (uint256)
  {
    return LIQUIDITY_STAKING.getAllocatedBalanceCurrentEpoch(address(this));
  }

  function getAllocatedBalanceNextEpoch()
    public
    view
    returns (uint256)
  {
    return LIQUIDITY_STAKING.getAllocatedBalanceNextEpoch(address(this));
  }

  function getBorrowableAmount()
    public
    view
    returns (uint256)
  {
    if (_IS_BORROWING_RESTRICTED_) {
      return 0;
    }
    return LIQUIDITY_STAKING.getBorrowableAmount(address(this));
  }

  function getBorrowedBalance()
    public
    view
    returns (uint256)
  {
    return LIQUIDITY_STAKING.getBorrowedBalance(address(this));
  }

  function getDebtBalance()
    public
    view
    returns (uint256)
  {
    return LIQUIDITY_STAKING.getBorrowerDebtBalance(address(this));
  }

  function getBorrowedAndDebtBalance()
    public
    view
    returns (uint256)
  {
    return getBorrowedBalance().add(getDebtBalance());
  }

  function getTokenBalance()
    public
    view
    returns (uint256)
  {
    return TOKEN.balanceOf(address(this));
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { SP1Storage } from './SP1Storage.sol';

/**
 * @title SP1Roles
 * @author dYdX
 *
 * @dev Defines roles used in the StarkProxyV1 contract. The hierarchy and powers of each role
 *  are described below. Not all roles need to be used.
 *
 *  Overview:
 *
 *    During operation of this contract, funds will flow between the following three
 *    contracts:
 *
 *        LiquidityStaking <> StarkProxy <> StarkPerpetual
 *
 *    Actions which move fund from left to right are called “open” actions, whereas actions which
 *    move funds from right to left are called “close” actions.
 *
 *    Also note that the “forced” actions (forced trade and forced withdrawal) require special care
 *    since they directly impact the financial risk of positions held on the exchange.
 *
 *  Roles:
 *
 *    GUARDIAN_ROLE
 *      | -> May perform “close” actions as defined above, but “forced” actions can only be taken
 *      |    if the borrower has an outstanding debt balance.
 *      | -> May restrict “open” actions as defined above, except w.r.t. funds in excess of the
 *      |    borrowed balance.
 *      | -> May approve a token amount to be withdrawn externally by the WITHDRAWAL_OPERATOR_ROLE
 *      |    to an allowed address.
 *      |
 *      +-- VETO_GUARDIAN_ROLE
 *            -> May veto forced trade requests initiated by the owner, during the waiting period.
 *
 *    OWNER_ROLE
 *      | -> May add or remove allowed recipients who may receive excess funds.
 *      | -> May add or remove allowed STARK keys for use on the exchange.
 *      | -> May set ERC20 allowances on the LiquidityStakingV1 and StarkPerpetual contracts.
 *      | -> May call the “forced” actions: forcedWithdrawalRequest and forcedTradeRequest.
 *      |
 *      +-- DELEGATION_ADMIN_ROLE
 *            |
 *            +-- BORROWER_ROLE
 *            |     -> May call functions on LiquidityStakingV1: autoPayOrBorrow, borrow, repay,
 *            |        and repayDebt.
 *            |
 *            +-- EXCHANGE_OPERATOR_ROLE
 *            |     -> May call functions on StarkPerpetual: depositToExchange and
 *            |        withdrawFromExchange.
 *            |
 *            +-- WITHDRAWAL_OPERATOR_ROLE
 *                  -> May withdraw funds in excess of the borrowed balance to an allowed recipient.
 */
abstract contract SP1Roles is
  SP1Storage
{
  bytes32 public constant GUARDIAN_ROLE = keccak256('GUARDIAN_ROLE');
  bytes32 public constant VETO_GUARDIAN_ROLE = keccak256('VETO_GUARDIAN_ROLE');
  bytes32 public constant OWNER_ROLE = keccak256('OWNER_ROLE');
  bytes32 public constant DELEGATION_ADMIN_ROLE = keccak256('DELEGATION_ADMIN_ROLE');
  bytes32 public constant BORROWER_ROLE = keccak256('BORROWER_ROLE');
  bytes32 public constant EXCHANGE_OPERATOR_ROLE = keccak256('EXCHANGE_OPERATOR_ROLE');
  bytes32 public constant WITHDRAWAL_OPERATOR_ROLE = keccak256('WITHDRAWAL_OPERATOR_ROLE');

  function __SP1Roles_init(
    address guardian
  )
    internal
  {
    // Assign GUARDIAN_ROLE.
    _setupRole(GUARDIAN_ROLE, guardian);

    // Assign OWNER_ROLE and DELEGATION_ADMIN_ROLE to the sender.
    _setupRole(OWNER_ROLE, msg.sender);
    _setupRole(DELEGATION_ADMIN_ROLE, msg.sender);

    // Set admins for all roles. (Don't use the default admin role.)
    _setRoleAdmin(GUARDIAN_ROLE, GUARDIAN_ROLE);
    _setRoleAdmin(VETO_GUARDIAN_ROLE, GUARDIAN_ROLE);
    _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
    _setRoleAdmin(DELEGATION_ADMIN_ROLE, OWNER_ROLE);
    _setRoleAdmin(BORROWER_ROLE, DELEGATION_ADMIN_ROLE);
    _setRoleAdmin(EXCHANGE_OPERATOR_ROLE, DELEGATION_ADMIN_ROLE);
    _setRoleAdmin(WITHDRAWAL_OPERATOR_ROLE, DELEGATION_ADMIN_ROLE);
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { SafeMath } from '../../../dependencies/open-zeppelin/SafeMath.sol';
import { IERC20 } from '../../../interfaces/IERC20.sol';
import { ILiquidityStakingV1 } from '../../../interfaces/ILiquidityStakingV1.sol';
import { Math } from '../../../utils/Math.sol';
import { SP1Balances } from './SP1Balances.sol';

/**
 * @title SP1Borrowing
 * @author dYdX
 *
 * @dev Handles calls to the LiquidityStaking contract to borrow and repay funds.
 */
abstract contract SP1Borrowing is
  SP1Balances
{
  using SafeMath for uint256;

  // ============ Events ============

  event Borrowed(
    uint256 amount,
    uint256 newBorrowedBalance
  );

  event RepaidBorrow(
    uint256 amount,
    uint256 newBorrowedBalance,
    bool isGuardianAction
  );

  event RepaidDebt(
    uint256 amount,
    uint256 newDebtBalance,
    bool isGuardianAction
  );

  // ============ Constructor ============

  constructor(
    ILiquidityStakingV1 liquidityStaking,
    IERC20 token
  )
    SP1Balances(liquidityStaking, token)
  {}

  // ============ External Functions ============

  /**
   * @notice Automatically repay or borrow to bring borrowed balance to the next allocated balance.
   *  Must be called during the blackout window, to ensure allocated balance will not change before
   *  the start of the next epoch. Reverts if there are insufficient funds to prevent a shortfall.
   *
   *  Can be called with eth_call to view amounts that will be borrowed or repaid.
   *
   * @return The newly borrowed amount.
   * @return The borrow amount repaid.
   * @return The debt amount repaid.
   */
  function autoPayOrBorrow()
    external
    nonReentrant
    onlyRole(BORROWER_ROLE)
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    // Ensure we are in the blackout window.
    require(
      LIQUIDITY_STAKING.inBlackoutWindow(),
      'SP1Borrowing: Auto-pay may only be used during the blackout window'
    );

    // Get the borrowed balance, next allocated balance, and token balance.
    uint256 borrowedBalance = getBorrowedBalance();
    uint256 nextAllocatedBalance = getAllocatedBalanceNextEpoch();
    uint256 tokenBalance = getTokenBalance();

    // Return values.
    uint256 borrowAmount = 0;
    uint256 repayBorrowAmount = 0;
    uint256 repayDebtAmount = 0;

    if (borrowedBalance > nextAllocatedBalance) {
      // Make the necessary repayment due by the end of the current epoch.
      repayBorrowAmount = borrowedBalance.sub(nextAllocatedBalance);
      require(
        tokenBalance >= repayBorrowAmount,
        'SP1Borrowing: Insufficient funds to avoid falling short on repayment'
      );
      _repayBorrow(repayBorrowAmount, false);
    } else {
      // Borrow the max borrowable amount.
      borrowAmount = getBorrowableAmount();
      if (borrowAmount != 0) {
        _borrow(borrowAmount);
      }
    }

    // Finally, use remaining funds to pay any overdue debt.
    uint256 debtBalance = getDebtBalance();
    repayDebtAmount = Math.min(debtBalance, tokenBalance);
    if (repayDebtAmount != 0) {
      _repayDebt(repayDebtAmount, false);
    }

    return (borrowAmount, repayBorrowAmount, repayDebtAmount);
  }

  function borrow(
    uint256 amount
  )
    external
    nonReentrant
    onlyRole(BORROWER_ROLE)
  {
    // Disallow if the guardian has restricted borrowing.
    require(
      !_IS_BORROWING_RESTRICTED_,
      'SP1Borrowing: Cannot borrow while Restricted'
    );

    _borrow(amount);
  }

  function repayBorrow(
    uint256 amount
  )
    external
    nonReentrant
    onlyRole(BORROWER_ROLE)
  {
    _repayBorrow(amount, false);
  }

  function repayDebt(
    uint256 amount
  )
    external
    nonReentrant
    onlyRole(BORROWER_ROLE)
  {
    _repayDebt(amount, false);
  }

  // ============ Internal Functions ============

  function _borrow(
    uint256 amount
  )
    internal
  {
    LIQUIDITY_STAKING.borrow(amount);
    emit Borrowed(amount, getBorrowedBalance());
  }

  function _repayBorrow(
    uint256 amount,
    bool isGovernanceAction
  )
    internal
  {
    LIQUIDITY_STAKING.repayBorrow(address(this), amount);
    emit RepaidBorrow(amount, getBorrowedBalance(), isGovernanceAction);
  }

  function _repayDebt(
    uint256 amount,
    bool isGovernanceAction
  )
    internal
  {
    LIQUIDITY_STAKING.repayDebt(address(this), amount);
    emit RepaidDebt(amount, getDebtBalance(), isGovernanceAction);
  }
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