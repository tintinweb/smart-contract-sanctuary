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
pragma experimental ABIEncoderV2;

import {
  AccessControlUpgradeable
} from '../../../dependencies/open-zeppelin/AccessControlUpgradeable.sol';
import { IERC20 } from '../../../interfaces/IERC20.sol';
import { IRewardsOracle } from '../../../interfaces/IRewardsOracle.sol';
import { ReentrancyGuard } from '../../../utils/ReentrancyGuard.sol';
import { VersionedInitializable } from '../../../utils/VersionedInitializable.sol';
import { MD1Types } from '../lib/MD1Types.sol';

/**
 * @title MD1Storage
 * @author dYdX
 *
 * @dev Storage contract. Contains or inherits from all contract with storage.
 */
abstract contract MD1Storage is
  AccessControlUpgradeable,
  ReentrancyGuard,
  VersionedInitializable
{
  // ============ Configuration ============

  /// @dev The oracle which provides Merkle root updates.
  IRewardsOracle internal _REWARDS_ORACLE_;

  /// @dev The IPNS name to which trader and market maker exchange statistics are published.
  string internal _IPNS_NAME_;

  /// @dev Period of time after the epoch end after which the new epoch exchange statistics should
  ///  be available on IPFS via the IPNS name. This can be used as a trigger for “keepers” who are
  ///  incentivized to call the proposeRoot() and updateRoot() functions as needed.
  uint256 internal _IPFS_UPDATE_PERIOD_;

  /// @dev Max rewards distributed per epoch as market maker incentives.
  uint256 internal _MARKET_MAKER_REWARDS_AMOUNT_;

  /// @dev Max rewards distributed per epoch as trader incentives.
  uint256 internal _TRADER_REWARDS_AMOUNT_;

  /// @dev Parameter affecting the calculation of trader rewards. This is a value
  ///  between 0 and 1, represented here in units out of 10^18.
  uint256 internal _TRADER_SCORE_ALPHA_;

  // ============ Epoch Schedule ============

  /// @dev The parameters specifying the function from timestamp to epoch number.
  MD1Types.EpochParameters internal _EPOCH_PARAMETERS_;

  // ============ Root Updates ============

  /// @dev The active Merkle root and associated parameters.
  MD1Types.MerkleRoot internal _ACTIVE_ROOT_;

  /// @dev The proposed Merkle root and associated parameters.
  MD1Types.MerkleRoot internal _PROPOSED_ROOT_;

  /// @dev The time at which the proposed root may become active.
  uint256 internal _WAITING_PERIOD_END_;

  /// @dev Whether root updates are currently paused.
  bool internal _ARE_ROOT_UPDATES_PAUSED_;

  // ============ Claims ============

  /// @dev Mapping of (user address) => (number of tokens claimed).
  mapping(address => uint256) internal _CLAIMED_;

  /// @dev Whether the user has opted into allowing anyone to trigger a claim on their behalf.
  mapping(address => bool) internal _ALWAYS_ALLOW_CLAIMS_FOR_;
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

interface IRewardsOracle {

  /**
   * @notice Returns the oracle value, agreed upon by all oracle signers. If the signers have not
   *  agreed upon a value, should return zero for all return values.
   *
   * @return  merkleRoot  The Merkle root for the next Merkle distributor update.
   * @return  epoch       The epoch number corresponding to the new Merkle root.
   * @return  ipfsCid     An IPFS CID pointing to the Merkle tree data.
   */
  function read()
    external
    virtual
    view
    returns (bytes32 merkleRoot, uint256 epoch, bytes memory ipfsCid);
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
pragma experimental ABIEncoderV2;

library MD1Types {

  /**
   * @dev The parameters used to convert a timestamp to an epoch number.
   */
  struct EpochParameters {
    uint128 interval;
    uint128 offset;
  }

  /**
   * @dev The parameters related to a certain version of the Merkle root.
   */
  struct MerkleRoot {
    bytes32 merkleRoot;
    uint256 epoch;
    bytes ipfsCid;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import { IRewardsOracle } from '../../../interfaces/IRewardsOracle.sol';
import { MD1Types } from '../lib/MD1Types.sol';
import { MD1Storage } from './MD1Storage.sol';

/**
 * @title MD1Getters
 * @author dYdX
 *
 * @notice Simple getter functions.
 */
abstract contract MD1Getters is
  MD1Storage
{
  /**
   * @notice Get the address of the oracle which provides Merkle root updates.
   *
   * @return The address of the oracle.
   */
  function getRewardsOracle()
    external
    view
    returns (IRewardsOracle)
  {
    return _REWARDS_ORACLE_;
  }

  /**
   * @notice Get the IPNS name to which trader and market maker exchange statistics are published.
   *
   * @return The IPNS name.
   */
  function getIpnsName()
    external
    view
    returns (string memory)
  {
    return _IPNS_NAME_;
  }

  /**
   * @notice Get the period of time after the epoch end after which the new epoch exchange
   *  statistics should be available on IPFS via the IPNS name.
   *
   * @return The IPFS update period, in seconds.
   */
  function getIpfsUpdatePeriod()
    external
    view
    returns (uint256)
  {
    return _IPFS_UPDATE_PERIOD_;
  }

  /**
   * @notice Get the rewards formula parameters.
   *
   * @return Max rewards distributed per epoch as market maker incentives.
   * @return Max rewards distributed per epoch as trader incentives.
   * @return The alpha parameter between 0 and 1, in units out of 10^18.
   */
  function getRewardsParameters()
    external
    view
    returns (uint256, uint256, uint256)
  {
    return (
      _MARKET_MAKER_REWARDS_AMOUNT_,
      _TRADER_REWARDS_AMOUNT_,
      _TRADER_SCORE_ALPHA_
    );
  }

  /**
   * @notice Get the parameters specifying the function from timestamp to epoch number.
   *
   * @return The parameters struct with `interval` and `offset` fields.
   */
  function getEpochParameters()
    external
    view
    returns (MD1Types.EpochParameters memory)
  {
    return _EPOCH_PARAMETERS_;
  }

  /**
   * @notice Get the active Merkle root and associated parameters.
   *
   * @return  merkleRoot  The active Merkle root.
   * @return  epoch       The epoch number corresponding to this Merkle tree.
   * @return  ipfsCid     An IPFS CID pointing to the Merkle tree data.
   */
  function getActiveRoot()
    external
    view
    returns (bytes32 merkleRoot, uint256 epoch, bytes memory ipfsCid)
  {
    merkleRoot = _ACTIVE_ROOT_.merkleRoot;
    epoch = _ACTIVE_ROOT_.epoch;
    ipfsCid = _ACTIVE_ROOT_.ipfsCid;
  }

  /**
   * @notice Get the proposed Merkle root and associated parameters.
   *
   * @return  merkleRoot  The active Merkle root.
   * @return  epoch       The epoch number corresponding to this Merkle tree.
   * @return  ipfsCid     An IPFS CID pointing to the Merkle tree data.
   */
  function getProposedRoot()
    external
    view
    returns (bytes32 merkleRoot, uint256 epoch, bytes memory ipfsCid)
  {
    merkleRoot = _PROPOSED_ROOT_.merkleRoot;
    epoch = _PROPOSED_ROOT_.epoch;
    ipfsCid = _PROPOSED_ROOT_.ipfsCid;
  }

  /**
   * @notice Get the time at which the proposed root may become active.
   *
   * @return The time at which the proposed root may become active, in epoch seconds.
   */
  function getWaitingPeriodEnd()
    external
    view
    returns (uint256)
  {
    return _WAITING_PERIOD_END_;
  }

  /**
   * @notice Check whether root updates are currently paused.
   *
   * @return Boolean `true` if root updates are currently paused, otherwise, `false`.
   */
  function getAreRootUpdatesPaused()
    external
    view
    returns (bool)
  {
    return _ARE_ROOT_UPDATES_PAUSED_;
  }

  /**
   * @notice Get the tokens claimed so far by a given user.
   *
   * @param  user  The address of the user.
   *
   * @return The tokens claimed so far by that user.
   */
  function getClaimed(address user)
    external
    view
    returns (uint256)
  {
    return _CLAIMED_[user];
  }

  /**
   * @notice Check whether the user opted into allowing anyone to trigger a claim on their behalf.
   *
   * @param  user  The address of the user.
   *
   * @return Boolean `true` if any address may trigger claims for the user, otherwise `false`.
   */
  function getAlwaysAllowClaimsFor(address user)
    external
    view
    returns (bool)
  {
    return _ALWAYS_ALLOW_CLAIMS_FOR_[user];
  }
}

// Contracts by dYdX Foundation. Individual files are released under different licenses.
//
// https://dydx.community
// https://github.com/dydxfoundation/governance-contracts
//
// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import { SafeMath } from '../../dependencies/open-zeppelin/SafeMath.sol';
import { Ownable } from '../../dependencies/open-zeppelin/Ownable.sol';
import { MerkleProof } from '../../dependencies/open-zeppelin/MerkleProof.sol';
import { IERC20 } from '../../interfaces/IERC20.sol';
import { IRewardsOracle } from '../../interfaces/IRewardsOracle.sol';
import { MD1Claims } from './impl/MD1Claims.sol';
import { MD1RootUpdates } from './impl/MD1RootUpdates.sol';
import { MD1Configuration } from './impl/MD1Configuration.sol';
import { MD1Getters } from './impl/MD1Getters.sol';

/**
 * @title MerkleDistributorV1
 * @author dYdX
 *
 * @notice Distributes DYDX token rewards according to a Merkle tree of balances. The tree can be
 *  updated periodially with each user's cumulative rewards balance, allowing new rewards to be
 *  distributed to users over time.
 *
 *  An update is performed by setting the proposed Merkle root to the latest value returned by
 *  the oracle contract. The proposed Merkle root can be made active after a waiting period has
 *  elapsed. During the waiting period, dYdX governance has the opportunity to freeze the Merkle
 *  root, in case the proposed root is incorrect or malicious.
 */
contract MerkleDistributorV1 is
  MD1RootUpdates,
  MD1Claims,
  MD1Configuration,
  MD1Getters
{
  // ============ Constructor ============

  constructor(
    address rewardsToken,
    address rewardsTreasury
  )
    MD1Claims(rewardsToken, rewardsTreasury)
    {}

  // ============ External Functions ============

  function initialize(
    address rewardsOracle,
    string calldata ipnsName,
    uint256 ipfsUpdatePeriod,
    uint256 marketMakerRewardsAmount,
    uint256 traderRewardsAmount,
    uint256 traderScoreAlpha,
    uint256 epochInterval,
    uint256 epochOffset
  )
    external
    initializer
  {
    __MD1Roles_init();
    __MD1Configuration_init(
      rewardsOracle,
      ipnsName,
      ipfsUpdatePeriod,
      marketMakerRewardsAmount,
      traderRewardsAmount,
      traderScoreAlpha
    );
    __MD1EpochSchedule_init(epochInterval, epochOffset);
  }

  // ============ Internal Functions ============

  /**
   * @dev Returns the revision of the implementation contract. Used by VersionedInitializable.
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

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import './Context.sol';

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
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
    require(_owner == _msgSender(), 'Ownable: caller is not the owner');
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import { SafeERC20 } from '../../../dependencies/open-zeppelin/SafeERC20.sol';
import { SafeMath } from '../../../dependencies/open-zeppelin/SafeMath.sol';
import { MerkleProof } from '../../../dependencies/open-zeppelin/MerkleProof.sol';
import { IERC20 } from '../../../interfaces/IERC20.sol';
import { MD1Types } from '../lib/MD1Types.sol';
import { MD1Roles } from './MD1Roles.sol';

/**
 * @title MD1Claims
 * @author dYdX
 *
 * @notice Allows rewards to be claimed by providing a Merkle proof of the rewards amount.
 */
abstract contract MD1Claims is
  MD1Roles
{
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  // ============ Constants ============

  /// @notice The token distributed as rewards.
  IERC20 public immutable REWARDS_TOKEN;

  /// @notice Address to pull rewards from. Must have provided an allowance to this contract.
  address public immutable REWARDS_TREASURY;

  // ============ Events ============

  /// @notice Emitted when a user claims rewards.
  event RewardsClaimed(
    address account,
    uint256 amount
  );

  /// @notice Emitted when a user opts into or out of the claim-for allowlist.
  event AlwaysAllowClaimForUpdated(
    address user,
    bool allow
  );

  // ============ Constructor ============

  constructor(
    address rewardsToken,
    address rewardsTreasury
  ) {
    REWARDS_TOKEN = IERC20(rewardsToken);
    REWARDS_TREASURY = rewardsTreasury;
  }

  // ============ External Functions ============

  /**
   * @notice Claim the remaining unclaimed rewards for the sender.
   *
   *  Reverts if the provided Merkle proof is invalid.
   *
   * @param  cumulativeAmount  The total all-time rewards this user has earned.
   * @param  merkleProof       The Merkle proof for the user and cumulative amount.
   *
   * @return The number of rewards tokens claimed.
   */
  function claimRewards(
    uint256 cumulativeAmount,
    bytes32[] calldata merkleProof
  )
    external
    nonReentrant
    returns (uint256)
  {
    return _claimRewards(msg.sender, cumulativeAmount, merkleProof);
  }

  /**
   * @notice Claim the remaining unclaimed rewards for a user, and send them to that user.
   *
   *  The caller must be authorized with CLAIM_OPERATOR_ROLE unless the specified user has opted
   *  into the claim-for allowlist. In any case, rewards are transfered to the original user
   *  specified in the Merkle tree.
   *
   *  Reverts if the provided Merkle proof is invalid.
   *
   * @param  user              Address of the user on whose behalf to trigger a claim.
   * @param  cumulativeAmount  The total all-time rewards this user has earned.
   * @param  merkleProof       The Merkle proof for the user and cumulative amount.
   *
   * @return The number of rewards tokens claimed.
   */
  function claimRewardsFor(
    address user,
    uint256 cumulativeAmount,
    bytes32[] calldata merkleProof
  )
    external
    nonReentrant
    returns (uint256)
  {
    require(
      (
        hasRole(CLAIM_OPERATOR_ROLE, msg.sender) ||
        _ALWAYS_ALLOW_CLAIMS_FOR_[user]
      ),
      'MD1Claims: Do not have permission to claim for this user'
    );
    return _claimRewards(user, cumulativeAmount, merkleProof);
  }

  /**
   * @notice Opt into allowing anyone to claim on the sender's behalf.
   *
   *  Note that this does not affect who receives the funds. The user specified in the Merkle tree
   *  receives those rewards regardless of who issues the claim.
   *
   *  Note that addresses with the CLAIM_OPERATOR_ROLE ignore this allowlist when triggering claims.
   *
   * @param  allow  Whether or not to allow claims on the sender's behalf.
   */
  function setAlwaysAllowClaimsFor(
    bool allow
  )
    external
    nonReentrant
  {
    _ALWAYS_ALLOW_CLAIMS_FOR_[msg.sender] = allow;
    emit AlwaysAllowClaimForUpdated(msg.sender, allow);
  }

  // ============ Internal Functions ============

  /**
   * @notice Claim the remaining unclaimed rewards for a user, and send them to that user.
   *
   *  Reverts if the provided Merkle proof is invalid.
   *
   * @param  user              Address of the user.
   * @param  cumulativeAmount  The total all-time rewards this user has earned.
   * @param  merkleProof       The Merkle proof for the user and cumulative amount.
   *
   * @return The number of rewards tokens claimed.
   */
  function _claimRewards(
    address user,
    uint256 cumulativeAmount,
    bytes32[] calldata merkleProof
  )
    internal
    returns (uint256)
  {
    // Get the active Merkle root.
    bytes32 merkleRoot = _ACTIVE_ROOT_.merkleRoot;

    // Verify the Merkle proof.
    bytes32 node = keccak256(abi.encodePacked(user, cumulativeAmount));
    require(MerkleProof.verify(merkleProof, merkleRoot, node), 'MD1Claims: Invalid Merkle proof');

    // Get the claimable amount.
    //
    // Note: If this reverts, then there was an error in the Merkle tree, since the cumulative
    // amount for a given user should never decrease over time.
    uint256 claimable = cumulativeAmount.sub(_CLAIMED_[user]);

    if (claimable == 0) {
      return 0;
    }

    // Mark the user as having claimed the full amount.
    _CLAIMED_[user] = cumulativeAmount;

    // Send the user the claimable amount.
    REWARDS_TOKEN.safeTransferFrom(REWARDS_TREASURY, user, claimable);

    emit RewardsClaimed(user, claimable);

    return claimable;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import { SafeMath } from '../../../dependencies/open-zeppelin/SafeMath.sol';
import { MerkleProof } from '../../../dependencies/open-zeppelin/MerkleProof.sol';
import { MD1Types } from '../lib/MD1Types.sol';
import { MD1Pausable } from './MD1Pausable.sol';

/**
 * @title MD1RootUpdates
 * @author dYdX
 *
 * @notice Handles updates to the Merkle root.
 */
abstract contract MD1RootUpdates is
  MD1Pausable
{
  using SafeMath for uint256;

  // ============ Constants ============

  /// @notice The waiting period before a proposed Merkle root can become active, in seconds.
  uint256 public constant WAITING_PERIOD = 7 days;

  // ============ Events ============

  /// @notice Emitted when a new Merkle root is proposed and the waiting period begins.
  event RootProposed(
    bytes32 merkleRoot,
    uint256 epoch,
    bytes ipfsCid,
    uint256 waitingPeriodEnd
  );

  /// @notice Emitted when a new Merkle root becomes active.
  event RootUpdated(
    bytes32 merkleRoot,
    uint256 epoch,
    bytes ipfsCid
  );

  // ============ External Functions ============

  /**
   * @notice Set the proposed root parameters to the values returned by the oracle, and start the
   *  waiting period. Anyone may call this function.
   *
   *  Reverts if the oracle root is bytes32(0).
   *  Reverts if the oracle root parameters are equal to the proposed root parameters.
   *  Reverts if the oracle root epoch is not equal to the next root epoch.
   */
  function proposeRoot()
    external
    nonReentrant
  {
    // Read the latest values from the oracle.
    (
      bytes32 merkleRoot,
      uint256 epoch,
      bytes memory ipfsCid
    ) = _REWARDS_ORACLE_.read();

    require(merkleRoot != bytes32(0), 'MD1RootUpdates: Oracle root is zero (unset)');
    require(
      (
        merkleRoot != _PROPOSED_ROOT_.merkleRoot ||
        epoch != _PROPOSED_ROOT_.epoch ||
        keccak256(ipfsCid) != keccak256(_PROPOSED_ROOT_.ipfsCid)
      ),
      'MD1RootUpdates: Oracle root was already proposed'
    );
    require(epoch == getNextRootEpoch(), 'MD1RootUpdates: Oracle epoch is not next root epoch');

    // Set the proposed root and the waiting period for the proposed root to become active.
    _PROPOSED_ROOT_ = MD1Types.MerkleRoot({
      merkleRoot: merkleRoot,
      epoch: epoch,
      ipfsCid: ipfsCid
    });
    uint256 waitingPeriodEnd = block.timestamp.add(WAITING_PERIOD);
    _WAITING_PERIOD_END_ = waitingPeriodEnd;

    emit RootProposed(merkleRoot, epoch, ipfsCid, waitingPeriodEnd);
  }

  /**
   * @notice Set the active root parameters to the proposed root parameters.
   *
   *  Reverts if root updates are paused.
   *  Reverts if the proposed root is bytes32(0).
   *  Reverts if the proposed root epoch is not equal to the next root epoch.
   *  Reverts if the waiting period for the proposed root has not elapsed.
   */
  function updateRoot()
    external
    nonReentrant
    whenNotPaused
  {
    // Get the proposed root parameters.
    bytes32 merkleRoot = _PROPOSED_ROOT_.merkleRoot;
    uint256 epoch = _PROPOSED_ROOT_.epoch;
    bytes memory ipfsCid = _PROPOSED_ROOT_.ipfsCid;

    require(merkleRoot != bytes32(0), 'MD1RootUpdates: Proposed root is zero (unset)');
    require(epoch == getNextRootEpoch(), 'MD1RootUpdates: Proposed epoch is not next root epoch');
    require(
      block.timestamp >= _WAITING_PERIOD_END_,
      'MD1RootUpdates: Waiting period has not elapsed'
    );

    // Set the active root.
    _ACTIVE_ROOT_.merkleRoot = merkleRoot;
    _ACTIVE_ROOT_.epoch = epoch;
    _ACTIVE_ROOT_.ipfsCid = ipfsCid;

    emit RootUpdated(merkleRoot, epoch, ipfsCid);
  }

  /**
   * @notice Returns true if there is a proposed root waiting to become active, the waiting period
   *  for that root has elapsed, and root updates are not paused.
   *
   * @return Boolean `true` if the active root can be updated to the proposed root, else `false`.
   */
  function canUpdateRoot()
    external
    view
    returns (bool)
  {
    return (
      hasPendingRoot() &&
      block.timestamp >= _WAITING_PERIOD_END_ &&
      !_ARE_ROOT_UPDATES_PAUSED_
    );
  }

  // ============ Public Functions ============

  /**
   * @notice Returns true if there is a proposed root waiting to become active. This is the case if
   *  and only if the proposed root is not zero and the proposed root epoch is equal to the next
   *  root epoch.
   */
  function hasPendingRoot()
    public
    view
    returns (bool)
  {
    // Get the proposed parameters.
    bytes32 merkleRoot = _PROPOSED_ROOT_.merkleRoot;
    uint256 epoch = _PROPOSED_ROOT_.epoch;

    if (merkleRoot == bytes32(0)) {
      return false;
    }
    return epoch == getNextRootEpoch();
  }

  /**
   * @notice Get the next root epoch. If the active root is zero, then the next root epoch is zero,
   *  otherwise, it is equal to the active root epoch plus one.
   */
  function getNextRootEpoch()
    public
    view
    returns (uint256)
  {
    bytes32 merkleRoot = _ACTIVE_ROOT_.merkleRoot;

    if (merkleRoot == bytes32(0)) {
      return 0;
    }

    return _ACTIVE_ROOT_.epoch.add(1);
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import { IRewardsOracle } from '../../../interfaces/IRewardsOracle.sol';
import { MD1EpochSchedule } from './MD1EpochSchedule.sol';
import { MD1Roles } from './MD1Roles.sol';
import { MD1Types } from '../lib/MD1Types.sol';

/**
 * @title MD1Configuration
 * @author dYdX
 *
 * @notice Functions for modifying the Merkle distributor rewards configuration.
 *
 *  The more sensitive configuration values, which potentially give full control over the contents
 *  of the Merkle tree, may only be updated by the OWNER_ROLE. Other values may be configured by
 *  the CONFIG_UPDATER_ROLE.
 *
 *  Note that these configuration values are made available externally but are not used internally
 *  within this contract, with the exception of the IPFS update period which is used by
 *  the getIpfsEpoch() function.
 */
abstract contract MD1Configuration is
  MD1EpochSchedule,
  MD1Roles
{
  // ============ Constants ============

  uint256 public constant TRADER_SCORE_ALPHA_BASE = 10 ** 18;

  // ============ Events ============

  event RewardsOracleChanged(
    address rewardsOracle
  );

  event IpnsNameUpdated(
    string ipnsName
  );

  event IpfsUpdatePeriodUpdated(
    uint256 ipfsUpdatePeriod
  );

  event RewardsParametersUpdated(
    uint256 marketMakerRewardsAmount,
    uint256 traderRewardsAmount,
    uint256 traderScoreAlpha
  );

  // ============ Initializer ============

  function __MD1Configuration_init(
    address rewardsOracle,
    string calldata ipnsName,
    uint256 ipfsUpdatePeriod,
    uint256 marketMakerRewardsAmount,
    uint256 traderRewardsAmount,
    uint256 traderScoreAlpha
  )
    internal
  {
    _setRewardsOracle(rewardsOracle);
    _setIpnsName(ipnsName);
    _setIpfsUpdatePeriod(ipfsUpdatePeriod);
    _setRewardsParameters(
      marketMakerRewardsAmount,
      traderRewardsAmount,
      traderScoreAlpha
    );
  }

  // ============ External Functions ============

  /**
   * @notice Set the address of the oracle which provides Merkle root updates.
   *
   * @param  rewardsOracle  The new oracle address.
   */
  function setRewardsOracle(
    address rewardsOracle
  )
    external
    onlyRole(OWNER_ROLE)
    nonReentrant
  {
    _setRewardsOracle(rewardsOracle);
  }

  /**
   * @notice Set the IPNS name to which trader and market maker exchange statistics are published.
   *
   * @param  ipnsName  The new IPNS name.
   */
  function setIpnsName(
    string calldata ipnsName
  )
    external
    onlyRole(OWNER_ROLE)
    nonReentrant
  {
    _setIpnsName(ipnsName);
  }

  /**
   * @notice Set the period of time after the epoch end after which the new epoch exchange
   *  statistics should be available on IPFS via the IPNS name.
   *
   *  This can be used as a trigger for “keepers” who are incentivized to call the proposeRoot()
   *  and updateRoot() functions as needed.
   *
   * @param  ipfsUpdatePeriod  The new IPFS update period, in seconds.
   */
  function setIpfsUpdatePeriod(
    uint256 ipfsUpdatePeriod
  )
    external
    onlyRole(CONFIG_UPDATER_ROLE)
    nonReentrant
  {
    _setIpfsUpdatePeriod(ipfsUpdatePeriod);
  }

  /**
   * @notice Set the rewards formula parameters.
   *
   * @param  marketMakerRewardsAmount  Max rewards distributed per epoch as market maker incentives.
   * @param  traderRewardsAmount       Max rewards distributed per epoch as trader incentives.
   * @param  traderScoreAlpha          The alpha parameter between 0 and 1, in units out of 10^18.
   */
  function setRewardsParameters(
    uint256 marketMakerRewardsAmount,
    uint256 traderRewardsAmount,
    uint256 traderScoreAlpha
  )
    external
    onlyRole(CONFIG_UPDATER_ROLE)
    nonReentrant
  {
    _setRewardsParameters(marketMakerRewardsAmount, traderRewardsAmount, traderScoreAlpha);
  }

  /**
   * @notice Set the parameters defining the function from timestamp to epoch number.
   *
   * @param  interval  The length of an epoch, in seconds.
   * @param  offset    The start of epoch zero, in seconds.
   */
  function setEpochParameters(
    uint256 interval,
    uint256 offset
  )
    external
    onlyRole(CONFIG_UPDATER_ROLE)
    nonReentrant
  {
    _setEpochParameters(interval, offset);
  }

  // ============ Internal Functions ============

  function _setRewardsOracle(
    address rewardsOracle
  )
    internal
  {
    _REWARDS_ORACLE_ = IRewardsOracle(rewardsOracle);
    emit RewardsOracleChanged(rewardsOracle);
  }

  function _setIpnsName(
    string calldata ipnsName
  )
    internal
  {
    _IPNS_NAME_ = ipnsName;
    emit IpnsNameUpdated(ipnsName);
  }

  function _setIpfsUpdatePeriod(
    uint256 ipfsUpdatePeriod
  )
    internal
  {
    _IPFS_UPDATE_PERIOD_ = ipfsUpdatePeriod;
    emit IpfsUpdatePeriodUpdated(ipfsUpdatePeriod);
  }

  function _setRewardsParameters(
    uint256 marketMakerRewardsAmount,
    uint256 traderRewardsAmount,
    uint256 traderScoreAlpha
  )
    internal
  {
    require(
      traderScoreAlpha <= TRADER_SCORE_ALPHA_BASE,
      'MD1Configuration: Invalid traderScoreAlpha'
    );

    _MARKET_MAKER_REWARDS_AMOUNT_ = marketMakerRewardsAmount;
    _TRADER_REWARDS_AMOUNT_ = traderRewardsAmount;
    _TRADER_SCORE_ALPHA_ = traderScoreAlpha;

    emit RewardsParametersUpdated(
      marketMakerRewardsAmount,
      traderRewardsAmount,
      traderScoreAlpha
    );
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import { MD1Storage } from './MD1Storage.sol';

/**
 * @title MD1Roles
 * @author dYdX
 *
 * @notice Defines roles used in the MerkleDistributorV1 contract. The hierarchy of roles and
 *  powers of each role are described below.
 *
 *  Roles:
 *
 *    OWNER_ROLE
 *      | -> May add or remove addresses from any of the below roles it manages.
 *      | -> May update the rewards oracle address.
 *      | -> May update the IPNS name.
 *      |
 *      +-- CONFIG_UPDATER_ROLE
 *      |     -> May update parameters affecting the formulae used to calculate rewards.
 *      |     -> May update the epoch schedule.
 *      |     -> May update the IPFS update period.
 *      |
 *      +-- PAUSER_ROLE
 *      |     -> May pause updates to the Merkle root.
 *      |
 *      +-- UNPAUSER_ROLE
 *      |     -> May unpause updates to the Merkle root.
 *      |
 *      +-- CLAIM_OPERATOR_ROLE
 *            -> May trigger a claim on behalf of a user (but the recipient is always the user).
 */
abstract contract MD1Roles is
  MD1Storage
{
  bytes32 public constant OWNER_ROLE = keccak256('OWNER_ROLE');
  bytes32 public constant CONFIG_UPDATER_ROLE = keccak256('CONFIG_UPDATER_ROLE');
  bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');
  bytes32 public constant UNPAUSER_ROLE = keccak256('UNPAUSER_ROLE');
  bytes32 public constant CLAIM_OPERATOR_ROLE = keccak256('CLAIM_OPERATOR_ROLE');

  function __MD1Roles_init()
    internal
  {
    // Assign the OWNER_ROLE to the sender.
    _setupRole(OWNER_ROLE, msg.sender);

    // Set OWNER_ROLE as the admin of all roles.
    _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
    _setRoleAdmin(CONFIG_UPDATER_ROLE, OWNER_ROLE);
    _setRoleAdmin(PAUSER_ROLE, OWNER_ROLE);
    _setRoleAdmin(UNPAUSER_ROLE, OWNER_ROLE);
    _setRoleAdmin(CLAIM_OPERATOR_ROLE, OWNER_ROLE);
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
pragma experimental ABIEncoderV2;

import { MD1Roles } from './MD1Roles.sol';

/**
 * @title MD1Pausable
 * @author dYdX
 *
 * @notice Allows authorized addresses to pause updates to the Merkle root.
 *
 *  For the Merkle root to be updated, the root must first be set on the oracle contract, then
 *  proposed on this contract, at which point the waiting period begins. During the waiting period,
 *  the root should be verified, and updates should be paused by the PAUSER_ROLE if the root is
 *  found to be incorrect.
 */
abstract contract MD1Pausable is
  MD1Roles
{
  // ============ Events ============

  /// @notice Emitted when root updates are paused.
  event RootUpdatesPaused();

  /// @notice Emitted when root updates are unpaused.
  event RootUpdatesUnpaused();

  // ============ Modifiers ============

  /**
   * @dev Enforce that a function may be called only while root updates are not paused.
   */
  modifier whenNotPaused() {
    require(!_ARE_ROOT_UPDATES_PAUSED_, 'MD1Pausable: Updates paused');
    _;
  }

  /**
   * @dev Enforce that a function may be called only while root updates are paused.
   */
  modifier whenPaused() {
    require(_ARE_ROOT_UPDATES_PAUSED_, 'MD1Pausable: Updates not paused');
    _;
  }

  // ============ External Functions ============

  /**
   * @dev Called by PAUSER_ROLE to prevent proposed Merkle roots from becoming active.
   */
  function pauseRootUpdates()
    onlyRole(PAUSER_ROLE)
    whenNotPaused
    nonReentrant
    external
  {
    _ARE_ROOT_UPDATES_PAUSED_ = true;
    emit RootUpdatesPaused();
  }

  /**
   * @dev Called by UNPAUSER_ROLE to resume allowing proposed Merkle roots to become active.
   */
  function unpauseRootUpdates()
    onlyRole(UNPAUSER_ROLE)
    whenPaused
    nonReentrant
    external
  {
    _ARE_ROOT_UPDATES_PAUSED_ = false;
    emit RootUpdatesUnpaused();
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import { SafeMath } from '../../../dependencies/open-zeppelin/SafeMath.sol';
import { MD1Types } from '../lib/MD1Types.sol';
import { SafeCast } from '../lib/SafeCast.sol';
import { MD1Storage } from './MD1Storage.sol';

/**
 * @title MD1EpochSchedule
 * @author dYdX
 *
 * @dev Defines a function from block timestamp to epoch number.
 *
 *  Note that the current and IPFS epoch numbers are made available externally but are not used
 *  internally within this contract.
 *
 *  The formula used is `n = floor((t - b) / a)` where:
 *    - `n` is the epoch number
 *    - `t` is the timestamp (in seconds)
 *    - `b` is a non-negative offset, indicating the start of epoch zero (in seconds)
 *    - `a` is the length of an epoch, a.k.a. the interval (in seconds)
 */
abstract contract MD1EpochSchedule is
  MD1Storage
{
  using SafeCast for uint256;
  using SafeMath for uint256;

  // ============ Events ============

  event EpochScheduleUpdated(
    MD1Types.EpochParameters epochParameters
  );

  // ============ Initializer ============

  function __MD1EpochSchedule_init(
    uint256 interval,
    uint256 offset
  )
    internal
  {
    _setEpochParameters(interval, offset);
  }

  // ============ External Functions ============

  /**
   * @notice Get the epoch at the current block timestamp.
   *
   *  Reverts if epoch zero has not started.
   *
   * @return The current epoch number.
   */
  function getCurrentEpoch()
    external
    view
    returns (uint256)
  {
    return _getEpochAtTimestamp(
      block.timestamp,
      'MD1EpochSchedule: Epoch zero has not started'
    );
  }

  /**
   * @notice Get the latest epoch number for which we expect to have data available on IPFS.
   *  This is equal to the current epoch number, delayed by the IPFS update period.
   *
   *  Reverts if epoch zero did not begin at least `_IPFS_UPDATE_PERIOD_` seconds ago.
   *
   * @return The latest epoch number for which we expect to have data available on IPFS.
   */
  function getIpfsEpoch()
    external
    view
    returns (uint256)
  {
    return _getEpochAtTimestamp(
      block.timestamp.sub(_IPFS_UPDATE_PERIOD_),
      'MD1EpochSchedule: IPFS epoch zero has not started'
    );
  }

  // ============ Internal Functions ============

  function _getEpochAtTimestamp(
    uint256 timestamp,
    string memory revertReason
  )
    internal
    view
    returns (uint256)
  {
    MD1Types.EpochParameters memory epochParameters = _EPOCH_PARAMETERS_;

    uint256 interval = uint256(epochParameters.interval);
    uint256 offset = uint256(epochParameters.offset);

    require(timestamp >= offset, revertReason);

    return timestamp.sub(offset).div(interval);
  }

  function _setEpochParameters(
    uint256 interval,
    uint256 offset
  )
    internal
  {
    require(interval != 0, 'MD1EpochSchedule: Interval cannot be zero');

    MD1Types.EpochParameters memory epochParameters = MD1Types.EpochParameters({
      interval: interval.toUint128(),
      offset: offset.toUint128()
    });

    _EPOCH_PARAMETERS_ = epochParameters;

    emit EpochScheduleUpdated(epochParameters);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

/**
 * @dev Methods for downcasting unsigned integers, reverting on overflow.
 */
library SafeCast {

  /**
   * @dev Downcast to a uint128, reverting on overflow.
   */
  function toUint128(uint256 a) internal pure returns (uint128) {
    uint128 b = uint128(a);
    require(uint256(b) == a, 'SafeCast: toUint128 overflow');
    return b;
  }
}

