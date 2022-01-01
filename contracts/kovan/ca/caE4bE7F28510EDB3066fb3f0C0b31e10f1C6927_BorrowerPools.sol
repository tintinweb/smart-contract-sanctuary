// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
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
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
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
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
     * bearer except when using {AccessControl-_setupRole}.
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
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

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
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

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
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
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
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
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
            return "0x00";
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
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import {PoolLogic} from "./lib/PoolLogic.sol";
import {WadRayMath} from "./lib/WadRayMath.sol";

import "./PoolsSettingsManager.sol";
import "./extensions/AaveILendingPool.sol";
import "./lib/Types.sol";
import "./lib/Errors.sol";

import "./interfaces/IBorrowerPools.sol";

contract BorrowerPools is Initializable, IBorrowerPools, PoolsSettingsManager {
  using PoolLogic for Types.Pool;
  using WadRayMath for uint256;

  function initialize(
    ILendingPool _aaveLendingPool // beta
  ) public initializer {
    yieldProvider = _aaveLendingPool;
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setRoleAdmin(BORROWER_ROLE, GOVERNANCE_ROLE);
  }

  // VIEW METHODS
  function getTickLiquidityRatio(bytes32 borrower, uint256 rate) public view override returns (uint256 liquidityRatio) {
    liquidityRatio = pools[borrower].ticks[rate].jellyFiLiquidityRatio;
  }

  function getTickAmounts(bytes32 borrower, uint256 rate)
    public
    view
    override
    returns (
      uint256 adjustedTotalAmount,
      uint256 adjustedRemainingAmount,
      uint256 bondsQuantity,
      uint256 adjustedPendingAmount,
      uint256 jellyFiLiquidityRatio,
      uint256 accruedFees
    )
  {
    Types.Tick storage tick = pools[borrower].ticks[rate];
    return (
      tick.adjustedTotalAmount,
      tick.adjustedRemainingAmount,
      tick.bondsQuantity,
      tick.adjustedPendingAmount,
      tick.jellyFiLiquidityRatio,
      tick.accruedFees
    );
  }

  function getPoolState(bytes32 borrower)
    external
    view
    override
    returns (
      uint256 averageBorrowRate,
      uint256 totalBorrowed,
      uint256 normalizedAvailableDeposits,
      uint256 adjustedPendingDeposits
    )
  {
    Types.Pool storage pool = pools[borrower];
    Types.PoolParameters storage parameters = pools[borrower].parameters;
    uint256 rate = parameters.MIN_RATE;
    uint256 totalAmount = 0;
    uint256 amountWeightedRate = 0;
    totalBorrowed = pool.state.normalizedBorrowedAmount;
    adjustedPendingDeposits = 0;

    // for (rate; rate != parameters.MAX_RATE + parameters.RATE_SPACING; rate += parameters.RATE_SPACING) {
    //   amountWeightedRate += pool.ticks[rate].normalizedLoanedAmount * rate;
    //   totalAmount += pool.ticks[rate].normalizedLoanedAmount;
    //   adjustedPendingDeposits += pool.ticks[rate].adjustedPendingAmount;
    // }
    // if (totalAmount == 0) {
    //   return (0, 0, pool.state.normalizedAvailableDeposits, 0);
    // }
    // normalizedAvailableDeposits = pool.state.normalizedAvailableDeposits;
    // averageBorrowRate = amountWeightedRate / totalAmount;
    return (0, 0, 0, 0);
  }

  function getAmountRepartition(
    bytes32 borrower,
    uint256 rate,
    uint256 adjustedAmount,
    uint256 bondsIssuanceIndex
  ) external view override returns (uint256 bondsQuantity, uint256 normalizedDepositedAmount) {
    Types.Pool storage pool = pools[borrower];
    Types.Tick storage tick = pool.ticks[rate];

    if (bondsIssuanceIndex > tick.currentBondsIssuanceIndex) {
      uint256 yieldProviderLiquidityRatio = pool.parameters.YIELD_PROVIDER.getReserveNormalizedIncome(
        address(pool.parameters.UNDERLYING_TOKEN)
      );
      return (0, adjustedAmount.rayMul(yieldProviderLiquidityRatio));
    }

    uint256 adjustedDepositedAmount;
    (bondsQuantity, adjustedDepositedAmount) = pool.computeAmountRepartitionForTick(
      rate,
      adjustedAmount,
      bondsIssuanceIndex
    );

    (uint256 jellyFiLiquidityRatio, uint256 accruedFees) = pool.peekFeesForTick(rate);
    uint256 accruedFeesShare = pool.peekAccruedFeesShare(rate, adjustedDepositedAmount, accruedFees);
    normalizedDepositedAmount = adjustedDepositedAmount.rayMul(jellyFiLiquidityRatio) + accruedFeesShare;
  }

  function getTickBondPrice(uint256 rate, uint256 loanDuration) public pure returns (uint256 price) {
    price = uint256(1e18).wadDiv(1e18 + (rate * loanDuration) / 365 days);
  }

  // LENDER METHODS
  function deposit(
    uint256 normalizedAmount,
    uint256 rate,
    bytes32 borrower,
    address underlyingToken,
    address sender
  )
    public
    override
    whenNotPaused
    whenNotDefaulted(borrower)
    onlyRole(POSITION_ROLE)
    onlyActivePool(borrower)
    returns (uint256 adjustedAmount, uint256 bondsIssuanceIndex)
  {
    Types.Pool storage pool = pools[borrower];

    require(underlyingToken == pool.parameters.UNDERLYING_TOKEN, Errors.BP_UNMATCHED_TOKEN);
    require(rate >= pool.parameters.MIN_RATE, Errors.BP_OUT_OF_BOUND_MIN_RATE);
    require(rate <= pool.parameters.MAX_RATE, Errors.BP_OUT_OF_BOUND_MAX_RATE);
    require(rate % pool.parameters.RATE_SPACING == 0, Errors.BP_RATE_SPACING);

    pool.initializeTick(rate);
    (adjustedAmount, bondsIssuanceIndex) = pool.depositToTick(rate, normalizedAmount);
    pool.depositToYieldProvider(sender, normalizedAmount, yieldProvider);
  }

  struct WithdrawContext {
    uint256 remainingBondsQuantity;
    uint256 depositAmountToWithdraw;
    uint256 normalisedDepositedAmountToWithdraw;
  }

  function withdraw(WithdrawParams calldata params)
    public
    override
    whenNotPaused
    onlyRole(POSITION_ROLE)
    onlyActivePool(params.borrower)
    returns (
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    Types.Pool storage pool = pools[params.borrower];
    WithdrawContext memory ctx;

    require(
      params.bondsIssuanceIndex <= (pool.ticks[params.rate].currentBondsIssuanceIndex + 1),
      Errors.BP_BOND_ISSUANCE_ID_TOO_HIGH
    );
    bool isPendingDeposit = params.bondsIssuanceIndex > pool.ticks[params.rate].currentBondsIssuanceIndex;
    require(
      (!(isPendingDeposit) && pool.ticks[params.rate].adjustedRemainingAmount > 0) ||
        (isPendingDeposit && pool.ticks[params.rate].adjustedPendingAmount > 0),
      Errors.BP_TARGET_BOND_ISSUANCE_INDEX_EMPTY
    );

    (ctx.remainingBondsQuantity, ctx.depositAmountToWithdraw) = pool.computeAmountRepartitionForTick(
      params.rate,
      params.adjustedAmount,
      params.bondsIssuanceIndex
    );
    require(ctx.depositAmountToWithdraw > 0, Errors.BP_NO_DEPOSIT_TO_WITHDRAW);
    ctx.normalisedDepositedAmountToWithdraw = pool.withdrawDepositedAmountForTick(
      params.rate,
      ctx.depositAmountToWithdraw,
      params.bondsIssuanceIndex
    );

    yieldProvider.withdraw(pool.parameters.UNDERLYING_TOKEN, ctx.normalisedDepositedAmountToWithdraw, params.owner);

    return (
      ctx.depositAmountToWithdraw,
      ctx.remainingBondsQuantity,
      pool.state.currentMaturity,
      ctx.normalisedDepositedAmountToWithdraw
    );
  }

  function updateRate(
    uint256 adjustedAmount,
    bytes32 borrower,
    uint256 oldRate,
    uint256 newRate,
    uint256 oldBondsIssuanceIndex
  )
    public
    override
    whenNotPaused
    onlyRole(POSITION_ROLE)
    returns (uint256 newAdjustedAmount, uint256 newBondsIssuanceIndex)
  {
    Types.Pool storage pool = pools[borrower];

    // cannot update rate when being borrowed
    require(
      (oldBondsIssuanceIndex > pool.ticks[oldRate].currentBondsIssuanceIndex) || (pool.state.currentMaturity == 0),
      Errors.BP_LOAN_ALREADY_ONGOING
    );
    require(newRate >= pool.parameters.MIN_RATE, Errors.BP_OUT_OF_BOUND_MIN_RATE);
    require(newRate <= pool.parameters.MAX_RATE, Errors.BP_OUT_OF_BOUND_MAX_RATE);
    require(newRate % pool.parameters.RATE_SPACING == 0, Errors.BP_RATE_SPACING);

    pool.initializeTick(newRate);

    uint256 normalizedAmount = pool.withdrawDepositedAmountForTick(oldRate, adjustedAmount, oldBondsIssuanceIndex);
    (newAdjustedAmount, newBondsIssuanceIndex) = pool.depositToTick(newRate, normalizedAmount);
  }

  // BORROWER METHODS
  function topUpMaintenanceFees(uint256 amount) external override whenNotPaused onlyRole(BORROWER_ROLE) {
    Types.Pool storage pool = pools[borrowerAuthorizedAddresses[_msgSender()]];
    pool.depositToYieldProvider(_msgSender(), amount, yieldProvider);

    pool.topUpMaintenanceFees(amount);

    emit TopUpMaintenanceFees(borrowerAuthorizedAddresses[_msgSender()], amount);
  }

  function borrow(address to, uint256 normalizedBorrowedAmount)
    external
    override
    whenNotPaused
    whenNotDefaulted(0)
    onlyRole(BORROWER_ROLE)
  {
    bytes32 borrower = borrowerAuthorizedAddresses[_msgSender()];
    Types.Pool storage pool = pools[borrower];

    require(
      normalizedBorrowedAmount <= pool.parameters.MAX_BORROWABLE_AMOUNT,
      Errors.BP_BORROW_MAX_BORROWABLE_AMOUNT_EXCEEDED
    );
    require(pool.state.currentMaturity == 0, Errors.BP_LOAN_ALREADY_ONGOING);
    require(normalizedBorrowedAmount <= pool.state.normalizedAvailableDeposits, Errors.BP_BORROW_OUT_OF_BOUND_AMOUNT);
    require(block.timestamp >= pool.state.nextLoanMinStart, Errors.BP_BORROW_COOLDOWN_PERIOD_NOT_OVER);

    uint256 remainingAmount = normalizedBorrowedAmount;
    uint256 currentInterestRate = pool.state.lowerInterestRate - pool.parameters.RATE_SPACING;

    while (remainingAmount > 0 && currentInterestRate < pool.parameters.MAX_RATE) {
      currentInterestRate += pool.parameters.RATE_SPACING;
      if (pool.ticks[currentInterestRate].adjustedRemainingAmount > 0) {
        (uint256 bondsPurchasedQuantity, uint256 normalizedUsedAmountForPurchase) = pool
          .getBondsIssuanceParametersForTick(currentInterestRate, remainingAmount);
        pool.addBondsToTick(currentInterestRate, bondsPurchasedQuantity, normalizedUsedAmountForPurchase);

        remainingAmount -= normalizedUsedAmountForPurchase;
      }
    }
    require(remainingAmount == 0, Errors.BP_BORROW_UNSUFFICIENT_BORROWABLE_AMOUNT_WITHIN_BRACKETS);

    // pool global state update
    pool.state.currentMaturity = block.timestamp + pool.parameters.LOAN_DURATION;
    pool.state.normalizedBorrowedAmount = normalizedBorrowedAmount;

    yieldProvider.withdraw(pool.parameters.UNDERLYING_TOKEN, normalizedBorrowedAmount, to);

    emit Borrow(borrower, normalizedBorrowedAmount);
  }

  function repay() external override whenNotPaused whenNotDefaulted(0) onlyRole(BORROWER_ROLE) {
    bytes32 borrower = borrowerAuthorizedAddresses[_msgSender()];
    Types.Pool storage pool = pools[borrower];
    require(pool.state.currentMaturity > 0, Errors.BP_REPAY_NO_ACTIVE_LOAN);
    require(pool.state.currentMaturity <= block.timestamp, Errors.BP_REPAY_AT_MATURITY_ONLY);

    uint256 normalizedRepayAmount = pool.state.bondsIssuedQuantity;
    uint256 lateRepayFeePerBond;
    if (block.timestamp > pool.state.currentMaturity + pool.parameters.LATE_REPAY_THRESHOLD) {
      normalizedRepayAmount += pool.parameters.LATE_REPAY_FEE;
      lateRepayFeePerBond = pool.parameters.LATE_REPAY_FEE.wadDiv(pool.state.bondsIssuedQuantity);
    }

    uint256 currentInterestRate = pool.state.lowerInterestRate;
    while (currentInterestRate <= pool.parameters.MAX_RATE) {
      pool.repayForTick(currentInterestRate, lateRepayFeePerBond);
      pool.acceptPendingDepositsForTick(currentInterestRate);
      currentInterestRate += pool.parameters.RATE_SPACING;
    }

    pool.depositToYieldProvider(_msgSender(), normalizedRepayAmount, yieldProvider);

    if (block.timestamp > (pool.state.currentMaturity + pool.parameters.LATE_REPAY_THRESHOLD)) {
      emit LateRepay(borrower, normalizedRepayAmount, pool.state.normalizedAvailableDeposits);
    } else {
      emit Repay(borrower, normalizedRepayAmount, pool.state.normalizedAvailableDeposits);
    }

    // set global data for next loan
    pool.state.nextLoanMinStart = pool.state.currentMaturity + pool.parameters.COOLDOWN_PERIOD;
    pool.state.currentMaturity = 0;
    pool.state.normalizedBorrowedAmount = 0;
  }

  // PUBLIC METHODS
  function collectFeesForTick(bytes32 borrower, uint256 rate) external override whenNotPaused {
    Types.Pool storage pool = pools[borrower];
    pool.collectFeesForTick(rate);
  }

  function collectFees(bytes32 borrower) external override whenNotPaused {
    Types.Pool storage pool = pools[borrower];
    uint256 currentInterestRate = pool.state.lowerInterestRate - pool.parameters.RATE_SPACING;
    while (currentInterestRate < pool.parameters.MAX_RATE) {
      currentInterestRate += pool.parameters.RATE_SPACING;
      pool.collectFeesForTick(currentInterestRate);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import {WadRayMath} from "./lib/WadRayMath.sol";

import "./extensions/AaveILendingPool.sol";
import "./lib/Types.sol";
import "./lib/Errors.sol";

import "./interfaces/IBorrowerManagement.sol";
import "./interfaces/IPoolsParametersManagement.sol";

contract PoolsSettingsManager is
  AccessControlUpgradeable,
  PausableUpgradeable,
  IBorrowerManagement,
  IPoolsParametersManagement
{
  // contract roles
  bytes32 public constant BORROWER_ROLE = keccak256("BORROWER_ROLE");
  bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
  bytes32 public constant POSITION_ROLE = keccak256("POSITION_ROLE");

  // borrowers maintenance
  mapping(address => bytes32) public borrowerAuthorizedAddresses;

  // interest rate pool
  mapping(bytes32 => Types.Pool) public pools;

  // yield provider contract interface
  ILendingPool public yieldProvider;

  // BORROWER MANAGEMENT

  modifier onlyActivePool(bytes32 borrower) {
    require(pools[borrower].parameters.RATE_SPACING > 0, Errors.PSM_POOL_NOT_ACTIVE);
    _;
  }

  /**
   * @dev Creates a new pool
   * @param borrower The borrower that will interact with lenders in this pool
   * @param underlyingToken A supported-by-Aave token
   **/
  function createNewPool(
    bytes32 borrower,
    address underlyingToken,
    uint256 minRate,
    uint256 maxRate,
    uint256 rateSpacing,
    uint256 maxBorrowableAmount,
    uint256 loanDuration,
    uint256 distributionRate,
    uint256 cooldownPeriod,
    uint256 lateRepayThreshold,
    uint256 lateRepayFee
  ) external override onlyRole(GOVERNANCE_ROLE) {
    require(pools[borrower].parameters.RATE_SPACING == 0, Errors.PSM_POOL_ALREADY_SET_FOR_BORROWER);
    DataTypes.ReserveData memory reserveData = yieldProvider.getReserveData(underlyingToken);
    require(reserveData.id > 0, Errors.PSM_POOL_TOKEN_NOT_SUPPORTED);

    // initialise pool state and parameters
    pools[borrower].parameters = Types.PoolParameters({
      BORROWER_HASH: borrower,
      UNDERLYING_TOKEN: underlyingToken,
      YIELD_PROVIDER: yieldProvider,
      MIN_RATE: minRate,
      MAX_RATE: maxRate,
      RATE_SPACING: rateSpacing,
      MAX_BORROWABLE_AMOUNT: maxBorrowableAmount,
      LOAN_DURATION: loanDuration,
      MGT_FEE_DISTRIBUTION_RATE: distributionRate,
      COOLDOWN_PERIOD: cooldownPeriod,
      LATE_REPAY_THRESHOLD: lateRepayThreshold,
      LATE_REPAY_FEE: lateRepayFee
    });

    emit PoolCreated(
      borrower,
      underlyingToken,
      minRate,
      maxRate,
      maxBorrowableAmount,
      loanDuration,
      distributionRate,
      cooldownPeriod,
      lateRepayThreshold
    );
  }

  function allow(address borrowerAddress, bytes32 borrowerHash)
    external
    override
    onlyRole(GOVERNANCE_ROLE)
    onlyActivePool(borrowerHash)
  {
    grantRole(BORROWER_ROLE, borrowerAddress);

    borrowerAuthorizedAddresses[borrowerAddress] = borrowerHash;

    emit BorrowerAllowed(borrowerAddress, borrowerHash);
  }

  function disallow(address borrowerAddress, bytes32 borrower)
    external
    override
    onlyRole(GOVERNANCE_ROLE)
    onlyActivePool(borrower)
  {
    require(borrowerAuthorizedAddresses[borrowerAddress] == borrower, Errors.PSM_DISALLOW_UNMATCHED_BORROWER);
    revokeRole(BORROWER_ROLE, borrowerAddress);
    delete borrowerAuthorizedAddresses[borrowerAddress];

    emit BorrowerDisallowed(borrowerAddress, borrower);
  }

  function setDefault(bytes32 borrower) external override onlyRole(GOVERNANCE_ROLE) {
    Types.Pool storage pool = pools[borrower];
    pool.state.defaulted = true;

    emit Default(borrower);
  }

  // POOL PARAMETERS MANAGEMENT

  function setMinRate(uint256 minRate, bytes32 borrower)
    external
    override
    onlyRole(GOVERNANCE_ROLE)
    onlyActivePool(borrower)
  {
    require(minRate < pools[borrower].parameters.MAX_RATE, Errors.PSM_OUT_OF_BOUND_MIN_RATE);
    require(minRate % pools[borrower].parameters.RATE_SPACING == 0, Errors.PSM_RATE_SPACING_COMPLIANCE);
    pools[borrower].parameters.MIN_RATE = minRate;

    emit SetMinRate(minRate, borrower);
  }

  function setMaxRate(uint256 maxRate, bytes32 borrower)
    external
    override
    onlyRole(GOVERNANCE_ROLE)
    onlyActivePool(borrower)
  {
    require(maxRate > pools[borrower].parameters.MIN_RATE, Errors.PSM_OUT_OF_BOUND_MAX_RATE);
    require(maxRate % pools[borrower].parameters.RATE_SPACING == 0, Errors.PSM_RATE_SPACING_COMPLIANCE);
    pools[borrower].parameters.MAX_RATE = maxRate;

    emit SetMaxRate(maxRate, borrower);
  }

  function setMaxBorrowableAmount(uint256 maxBorrowableAmount, bytes32 borrower)
    external
    override
    onlyRole(GOVERNANCE_ROLE)
    onlyActivePool(borrower)
  {
    pools[borrower].parameters.MAX_BORROWABLE_AMOUNT = maxBorrowableAmount;

    emit SetMaxBorrowableAmount(maxBorrowableAmount, borrower);
  }

  function setMaintenanceFeeDistributionRate(uint256 distributionRate, bytes32 borrower)
    external
    override
    onlyRole(GOVERNANCE_ROLE)
    onlyActivePool(borrower)
  {
    pools[borrower].parameters.MGT_FEE_DISTRIBUTION_RATE = distributionRate;

    emit SetMaintenanceFeeDistributionRate(distributionRate, borrower);
  }

  function setCooldownPeriod(uint256 cooldownPeriod, bytes32 borrower)
    external
    override
    onlyRole(GOVERNANCE_ROLE)
    onlyActivePool(borrower)
  {
    pools[borrower].parameters.COOLDOWN_PERIOD = cooldownPeriod;

    emit SetCooldownPeriod(cooldownPeriod, borrower);
  }

  function setLateRepayThreshold(uint256 lateRepayThreshold, bytes32 borrower)
    external
    override
    onlyRole(GOVERNANCE_ROLE)
    onlyActivePool(borrower)
  {
    pools[borrower].parameters.LATE_REPAY_THRESHOLD = lateRepayThreshold;

    emit SetLateRepayThreshold(lateRepayThreshold, borrower);
  }

  function setLateRepayFee(uint256 lateRepayFee, bytes32 borrower)
    external
    override
    onlyRole(GOVERNANCE_ROLE)
    onlyActivePool(borrower)
  {
    pools[borrower].parameters.LATE_REPAY_FEE = lateRepayFee;

    emit SetLateRepayFee(lateRepayFee, borrower);
  }

  // EMERGENCY FREEZE
  function freezePool() external override onlyRole(GOVERNANCE_ROLE) {
    _pause();
  }

  function unfreezePool() external override onlyRole(GOVERNANCE_ROLE) {
    _unpause();
  }

  // SIGNAL DEFAULT
  modifier whenNotDefaulted(bytes32 borrower) {
    if (borrower == 0) {
      borrower = borrowerAuthorizedAddresses[_msgSender()];
    }
    Types.Pool storage pool = pools[borrower];
    require(!pool.state.defaulted, Errors.PSM_POOL_DEFAULTED);
    _;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

library DataTypes {
  // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: Reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60-63: reserved
    //bit 64-79: reserve factor
    uint256 data;
  }

  struct UserConfigurationMap {
    uint256 data;
  }

  enum InterestRateMode {
    NONE,
    STABLE,
    VARIABLE
  }
}

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
interface ILendingPoolAddressesProvider {
  event MarketIdSet(string newMarketId);
  event LendingPoolUpdated(address indexed newAddress);
  event ConfigurationAdminUpdated(address indexed newAddress);
  event EmergencyAdminUpdated(address indexed newAddress);
  event LendingPoolConfiguratorUpdated(address indexed newAddress);
  event LendingPoolCollateralManagerUpdated(address indexed newAddress);
  event PriceOracleUpdated(address indexed newAddress);
  event LendingRateOracleUpdated(address indexed newAddress);
  event ProxyCreated(bytes32 id, address indexed newAddress);
  event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

  function getMarketId() external view returns (string memory);

  function setMarketId(string calldata marketId) external;

  function setAddress(bytes32 id, address newAddress) external;

  function setAddressAsProxy(bytes32 id, address impl) external;

  function getAddress(bytes32 id) external view returns (address);

  function getLendingPool() external view returns (address);

  function setLendingPoolImpl(address pool) external;

  function getLendingPoolConfigurator() external view returns (address);

  function setLendingPoolConfiguratorImpl(address configurator) external;

  function getLendingPoolCollateralManager() external view returns (address);

  function setLendingPoolCollateralManager(address manager) external;

  function getPoolAdmin() external view returns (address);

  function setPoolAdmin(address admin) external;

  function getEmergencyAdmin() external view returns (address);

  function setEmergencyAdmin(address admin) external;

  function getPriceOracle() external view returns (address);

  function setPriceOracle(address priceOracle) external;

  function getLendingRateOracle() external view returns (address);

  function setLendingRateOracle(address lendingRateOracle) external;
}

interface ILendingPool {
  /**
   * @dev Emitted on deposit()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the deposit
   * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
   * @param amount The amount deposited
   * @param referral The referral code used
   **/
  event Deposit(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on withdraw()
   * @param reserve The address of the underlyng asset being withdrawn
   * @param user The address initiating the withdrawal, owner of aTokens
   * @param to Address that will receive the underlying
   * @param amount The amount to be withdrawn
   **/
  event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

  /**
   * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
   * @param reserve The address of the underlying asset being borrowed
   * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
   * initiator of the transaction on flashLoan()
   * @param onBehalfOf The address that will be getting the debt
   * @param amount The amount borrowed out
   * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
   * @param borrowRate The numeric rate at which the user has borrowed
   * @param referral The referral code used
   **/
  event Borrow(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint256 borrowRateMode,
    uint256 borrowRate,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on repay()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The beneficiary of the repayment, getting his debt reduced
   * @param repayer The address of the user initiating the repay(), providing the funds
   * @param amount The amount repaid
   **/
  event Repay(address indexed reserve, address indexed user, address indexed repayer, uint256 amount);

  /**
   * @dev Emitted on swapBorrowRateMode()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user swapping his rate mode
   * @param rateMode The rate mode that the user wants to swap to
   **/
  event Swap(address indexed reserve, address indexed user, uint256 rateMode);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on rebalanceStableBorrowRate()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user for which the rebalance has been executed
   **/
  event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on flashLoan()
   * @param target The address of the flash loan receiver contract
   * @param initiator The address initiating the flash loan
   * @param asset The address of the asset being flash borrowed
   * @param amount The amount flash borrowed
   * @param premium The fee flash borrowed
   * @param referralCode The referral code used
   **/
  event FlashLoan(
    address indexed target,
    address indexed initiator,
    address indexed asset,
    uint256 amount,
    uint256 premium,
    uint16 referralCode
  );

  /**
   * @dev Emitted when the pause is triggered.
   */
  event Paused();

  /**
   * @dev Emitted when the pause is lifted.
   */
  event Unpaused();

  /**
   * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
   * LendingPoolCollateral manager using a DELEGATECALL
   * This allows to have the events in the generated ABI for LendingPool.
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
   * @param liquidator The address of the liquidator
   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  event LiquidationCall(
    address indexed collateralAsset,
    address indexed debtAsset,
    address indexed user,
    uint256 debtToCover,
    uint256 liquidatedCollateralAmount,
    address liquidator,
    bool receiveAToken
  );

  /**
   * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
   * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
   * the event will actually be fired by the LendingPool contract. The event is therefore replicated here so it
   * gets added to the LendingPool ABI
   * @param reserve The address of the underlying asset of the reserve
   * @param liquidityRate The new liquidity rate
   * @param stableBorrowRate The new stable borrow rate
   * @param variableBorrowRate The new variable borrow rate
   * @param liquidityIndex The new liquidity index
   * @param variableBorrowIndex The new variable borrow index
   **/
  event ReserveDataUpdated(
    address indexed reserve,
    uint256 liquidityRate,
    uint256 stableBorrowRate,
    uint256 variableBorrowRate,
    uint256 liquidityIndex,
    uint256 variableBorrowIndex
  );

  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

  /**
   * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
   * corresponding debt token (StableDebtToken or VariableDebtToken)
   * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
   *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
   * @param asset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   **/
  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external;

  /**
   * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
   * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @return The final amount repaid
   **/
  function repay(
    address asset,
    uint256 amount,
    uint256 rateMode,
    address onBehalfOf
  ) external returns (uint256);

  /**
   * @dev Allows a borrower to swap his debt between stable and variable mode, or viceversa
   * @param asset The address of the underlying asset borrowed
   * @param rateMode The rate mode that the user wants to swap to
   **/
  function swapBorrowRateMode(address asset, uint256 rateMode) external;

  /**
   * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
   * - Users can be rebalanced if the following conditions are satisfied:
   *     1. Usage ratio is above 95%
   *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
   *        borrowed at a stable rate and depositors are not earning enough
   * @param asset The address of the underlying asset borrowed
   * @param user The address of the user to be rebalanced
   **/
  function rebalanceStableBorrowRate(address asset, address user) external;

  /**
   * @dev Allows depositors to enable/disable a specific deposited asset as collateral
   * @param asset The address of the underlying asset deposited
   * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
   **/
  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

  /**
   * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
   * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
   *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256 debtToCover,
    bool receiveAToken
  ) external;

  /**
   * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
   * For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
   * @param assets The addresses of the assets being flash-borrowed
   * @param amounts The amounts amounts being flash-borrowed
   * @param modes Types of the debt to open if the flash loan is not returned:
   *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
   *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata modes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  ) external;

  /**
   * @dev Returns the user account data across all the reserves
   * @param user The address of the user
   * @return totalCollateralETH the total collateral in ETH of the user
   * @return totalDebtETH the total debt in ETH of the user
   * @return availableBorrowsETH the borrowing power left of the user
   * @return currentLiquidationThreshold the liquidation threshold of the user
   * @return ltv the loan to value of the user
   * @return healthFactor the current health factor of the user
   **/
  function getUserAccountData(address user)
    external
    view
    returns (
      uint256 totalCollateralETH,
      uint256 totalDebtETH,
      uint256 availableBorrowsETH,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    );

  function initReserve(
    address reserve,
    address aTokenAddress,
    address stableDebtAddress,
    address variableDebtAddress,
    address interestRateStrategyAddress
  ) external;

  function setReserveInterestRateStrategyAddress(address reserve, address rateStrategyAddress) external;

  function setConfiguration(address reserve, uint256 configuration) external;

  /**
   * @dev Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   **/
  function getConfiguration(address asset) external view returns (DataTypes.ReserveConfigurationMap memory);

  /**
   * @dev Returns the configuration of the user across all the reserves
   * @param user The user address
   * @return The configuration of the user
   **/
  function getUserConfiguration(address user) external view returns (DataTypes.UserConfigurationMap memory);

  /**
   * @dev Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset) external view returns (uint256);

  /**
   * @dev Returns the normalized variable debt per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
  function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

  /**
   * @dev Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state of the reserve
   **/
  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromAfter,
    uint256 balanceToBefore
  ) external;

  function getReservesList() external view returns (address[] memory);

  function getAddressesProvider() external view returns (ILendingPoolAddressesProvider);

  function setPause(bool val) external;

  function paused() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IBorrowerManagement {
  event PoolCreated(
    bytes32 borrower,
    address underlyingToken,
    uint256 minRate,
    uint256 maxRate,
    uint256 maxBorrowableAmount,
    uint256 loanDuration,
    uint256 maintenanceFeeRate,
    uint256 cooldownPeriod,
    uint256 lateRepayThreshold
  );
  event BorrowerAllowed(address borrowerAddress, bytes32 borrowerHash);
  event BorrowerDisallowed(address borrowerAddress, bytes32 borrowerHash);
  event Default(bytes32 borrower);

  /// @dev Add a new borrower to the Pool
  /// The calling address must have GOVERNANCE_ROLE role
  function createNewPool(
    bytes32 borrower,
    address underlyingToken,
    uint256 minRate,
    uint256 maxRate,
    uint256 rateSpacing,
    uint256 maxTokenDeposit,
    uint256 loanDuration,
    uint256 distributionRate,
    uint256 cooldownPeriod,
    uint256 lateRepayThreshold,
    uint256 lateRepayFee
  ) external;

  /// @dev Allow a new addres for the target borrower
  /// The calling address must have GOVERNANCE_ROLE role, and be BORROWER_ROLE role admin
  function allow(address borrowerAddress, bytes32 borrower) external;

  /// @dev Disallow a new addres for the target borrower
  /// The calling address must have GOVERNANCE_ROLE role, and be BORROWER_ROLE role admin
  function disallow(address borrowerAddress, bytes32 borrower) external;

  /// @dev Put the target pool in a default state
  /// Stops deposits, borrowings and repays, erases bonds
  function setDefault(bytes32 borrower) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../extensions/AaveILendingPool.sol";
import "../lib/Types.sol";

interface IBorrowerPools {
  event Borrow(bytes32 indexed borrower, uint256 amount);
  event Repay(bytes32 indexed borrower, uint256 amount, uint256 normalizedDepositsAfterRepay);
  event LateRepay(bytes32 indexed borrower, uint256 amount, uint256 normalizedDepositsAfterRepay);
  event TopUpMaintenanceFees(bytes32 borrower, uint256 amount);
  // The below events and enums are being used in the PoolLogic library
  // The same way that libraries don't have storage, they don't have an event log
  // Hence event logs will be saved in the calling contract
  // For the contract abi to reflect this and be used by offchain libraries,
  // we define these events and enums in the contract itself as well
  event TickBorrowUpdate(
    bytes32 borrower,
    uint256 rate,
    uint256 adjustedRemainingAmountReduction,
    uint256 loanedAmount,
    uint256 jellyFiLiquidityRatio
  );

  event TickInitialized(bytes32 borrower, uint256 rate, uint256 jellyFiLiquidityRatio);
  event TickLoanDeposit(bytes32 borrower, uint256 rate, uint256 adjustedPendingDeposit, uint256 jellyFiLiquidityRatio);
  event TickNoLoanDeposit(
    bytes32 borrower,
    uint256 rate,
    uint256 adjustedAvailableDeposit,
    uint256 jellyFiLiquidityRatio
  );
  event TickBorrow(
    bytes32 borrower,
    uint256 rate,
    uint256 adjustedRemainingAmountReduction,
    uint256 loanedAmount,
    uint256 jellyFiLiquidityRatio
  );
  event TickNoLoanWithdraw(
    bytes32 borrower,
    uint256 rate,
    uint256 adjustedAmountToWithdraw,
    uint256 jellyFiLiquidityRatio
  );
  event TickLoanWithdraw(
    bytes32 borrower,
    uint256 rate,
    uint256 adjustedAmountToWithdraw,
    uint256 jellyFiLiquidityRatio
  );
  event TickPendingDeposit(bytes32 borrower, uint256 rate, uint256 adjustedPendingAmount);
  event TickRepay(bytes32 borrower, uint256 rate, uint256 newAdjustedRemainingAmount, uint256 jellyFiLiquidityRatio);

  function getTickLiquidityRatio(bytes32 borrower, uint256 rate) external view returns (uint256 liquidityRatio);

  function getTickAmounts(bytes32 borrower, uint256 rate)
    external
    view
    returns (
      uint256 adjustedTotalAmount,
      uint256 adjustedRemainingAmount,
      uint256 bondsQuantity,
      uint256 adjustedPendingAmount,
      uint256 jellyFiLiquidityRatio,
      uint256 accruedFees
    );

  function getPoolState(bytes32 borrower)
    external
    view
    returns (
      uint256 averageBorrowRate,
      uint256 totalBorrowed,
      uint256 normalizedAvailableDeposits,
      uint256 adjustedPendingDeposits
    );

  /**
   * @notice Determines the repartition of an amount between bonds and deposited amount
   * @param borrower The identifier of the borrower
   * @param rate The rate at which the bond order bid is placed
   * @param adjustedAmount Adjusted amount to compute the repartition for
   * @param bondsIssuanceIndex Index that indicates when the deposit was done
   * @return bondsQuantity bonds quantity within the position
   * @return normalizedDepositedAmount normalized amount deposited on yield provider
   **/
  function getAmountRepartition(
    bytes32 borrower,
    uint256 rate,
    uint256 adjustedAmount,
    uint256 bondsIssuanceIndex
  ) external view returns (uint256 bondsQuantity, uint256 normalizedDepositedAmount);

  /**
   * @notice Deposits the input amount with the yield provider and stores the bid in the pool
   * @dev Deposit funds from a lender position
   * Initializes the target tick if it is the first time it is used
   * @param normalizedAmount The amount to deposit
   * @param rate The rate at which the bond order bid is placed
   * @param borrower The identifier of the borrower
   * @param underlyingToken The ERC20 interfact of the asset that is deposited
   * @param sender The address of the EOA/Contract that deposits the funds
   * @return adjustedAmount adjusted amount after deposit
   **/
  function deposit(
    uint256 normalizedAmount,
    uint256 rate,
    bytes32 borrower,
    address underlyingToken,
    address sender
  ) external returns (uint256 adjustedAmount, uint256 bondsIssuanceIndex);

  struct WithdrawParams {
    address owner; // The address of the position owner
    uint256 adjustedAmount; // The full balance of the position
    uint256 rate; // The rate at which the position bids for bonds
    uint256 bondsIssuanceIndex; // The index that determines when the position was created
    bytes32 borrower; // The identifier of the borrower
  }

  /**
   * @notice Withdraws the deposited amount with the yield provider
   * @dev Withdraw funds from a lender position
   * withdraws the yield provider deposited part of the position
   * bonds purchased with the position will remain
   * @param params params is a WithdrawParams object
   * @return depositAmountToWithdraw the amount that gets withdawn
   * @return remainingBondsQuantity the amount of bonds that remain in the Position
   * @return currentMaturity the maturity of the bonds at the time of the withdrawal
   * @return normalisedAmountToWithdraw the maturity of the bonds at the time of the withdrawal
   **/
  function withdraw(WithdrawParams calldata params)
    external
    returns (
      uint256 depositAmountToWithdraw,
      uint256 remainingBondsQuantity,
      uint256 currentMaturity,
      uint256 normalisedAmountToWithdraw
    );

  /**
   * @notice Uppdates the old and new tick state
   * @dev Update a position's rate
   * Can only be updated if the position has no bonds
   * @param adjustedAmount The full balance of the position
   * @param borrower The identifier of the borrower
   * @param oldRate The current rate of the position
   * @param newRate The new rate of the position
   * @param oldBondsIssuanceIndex The current issuance index of the position
   * @return newAdjustedAmount updated amount of tokens of the position, adjusted to the new tick's global liquidity ratio
   * @return newBondsIssuanceIndex new bonds issuance index
   **/
  function updateRate(
    uint256 adjustedAmount,
    bytes32 borrower,
    uint256 oldRate,
    uint256 newRate,
    uint256 oldBondsIssuanceIndex
  ) external returns (uint256 newAdjustedAmount, uint256 newBondsIssuanceIndex);

  /**
   * @notice Top Up maintenance fees
   * @dev Add amount to the maintenance fees reserve
   * @param normalizedAmount Amount of token set aside for maintenance fees use
   **/
  function topUpMaintenanceFees(uint256 normalizedAmount) external;

  /**
   * @notice Sells bonds at optimal rates given current pool state
   * @dev Borrow tokens from the pool
   * Iteration over all ticks to convert deposited capacity into bonds
   * Calling the function without a pre existing loan will open a new loan
   * Calling the function with a pre existing loan will emit additional bonds for the current loan
   * @param to The address to which the borrowed funds should be sent
   * @param amount The actual amount of tokens  that will end up in the borrower's account after the sale
   **/
  function borrow(
    address to,
    uint256 amount // actual amount sent after the borrow, not a bonds quantity
  ) external;

  /**
   * @notice Repays the the outstanding bonds
   * @dev Repay a current loan
   * Iteration over all ticks to repay the bonds issued during the loan
   * Deposits the proceeds with the yield provider
   **/
  function repay() external;

  /**
   * @notice Collect yield provider fees as well as maintenance fees for the target rate
   * @dev Updates liquidity ratio for the target rate
   **/
  function collectFeesForTick(bytes32 borrower, uint256 rate) external;

  /**
   * @notice Collect yield provider fees as well as maintenance fees for the whole pool
   * @dev Updates liquidity ratio for the target rate
   * Iterates over all pool initialized ticks
   **/
  function collectFees(bytes32 borrower) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IPoolsParametersManagement {
  event SetMinRate(uint256 minRate, bytes32 borrowerHash);
  event SetMaxRate(uint256 maxRate, bytes32 borrowerHash);
  event SetMaxBorrowableAmount(uint256 maxTokenDeposit, bytes32 borrowerHash);
  event SetMaintenanceFeeDistributionRate(uint256 distributionRate, bytes32 borrowerHash);
  event SetCooldownPeriod(uint256 cooldownPeriod, bytes32 borrowerHash);
  event SetLateRepayThreshold(uint256 lateRepayThreshold, bytes32 borrowerHash);
  event SetLateRepayFee(uint256 lateRepayFee, bytes32 borrowerHash);

  /// @dev Set the minimum interest rate for the target borrower's order book
  function setMinRate(uint256 minRate, bytes32 borrower) external;

  /// @dev Set the maximum interest rate for the target borrower's order book
  function setMaxRate(uint256 maxRate, bytes32 borrower) external;

  /// @dev Set the maximum amount of tokens that can be borrowed in the target pool
  function setMaxBorrowableAmount(uint256 maxTokenDeposit, bytes32 borrower) external;

  /// @dev Set the order book maintenance fee rate
  function setMaintenanceFeeDistributionRate(uint256 distributionRate, bytes32 borrower) external;

  /// @dev Set the order book cooldown period
  function setCooldownPeriod(uint256 cooldownPeriod, bytes32 borrower) external;

  /// @dev Set the order book late repay threshold
  function setLateRepayThreshold(uint256 lateRepayThreshold, bytes32 borrower) external;

  /// @dev Set the order book late repay fee
  function setLateRepayFee(uint256 lateRepayFee, bytes32 borrower) external;

  /// @dev Freeze all actions for users
  function freezePool() external;

  /// @dev Unfreeze all frozen actions
  function unfreezePool() external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

library Errors {
  //*** Library Specific Errors ***
  // WadRayMath
  string public constant MATH_MULTIPLICATION_OVERFLOW = "1";
  string public constant MATH_ADDITION_OVERFLOW = "2";
  string public constant MATH_DIVISION_BY_ZERO = "3";

  // *** Contract Specific Errors ***
  // BorrowerPools
  string public constant BP_UNMATCHED_TOKEN = "4"; // "Token/Asset provided does not match the underlying token of the pool";
  string public constant BP_OUT_OF_BOUND_MIN_RATE = "5"; // "Rate provided is lower than minimum rate of the pool"
  string public constant BP_OUT_OF_BOUND_MAX_RATE = "6"; // "Rate provided is greater than maximum rate of the pool"
  string public constant BP_RATE_SPACING = "7"; // "Decimals of rate provided do not comply with rate spacing of the pool"
  string public constant BP_BORROW_MAX_BORROWABLE_AMOUNT_EXCEEDED = "8"; // "Amount borrowed is too big, exceeding borrowable capacity"
  string public constant BP_YIELD_PROVIDER_APPROVAL_FOR_TOKEN = "9"; // "An error occurred during yield provider approval for underlying token";
  string public constant BP_BORROW_OUT_OF_BOUND_AMOUNT = "10"; // "Amount provided is greater than available amount, action cannot be performed";
  string public constant BP_REPAY_NO_ACTIVE_LOAN = "11"; // "No active loan to be repaid, action cannot be performed";
  string public constant BP_BORROW_UNSUFFICIENT_BORROWABLE_AMOUNT_WITHIN_BRACKETS = "12"; // "Amount provided is greater than available amount within min rate and max rate brackets";
  string public constant BP_NO_DEPOSIT_TO_WITHDRAW = "13"; // "Deposited amount non-borrowed equals to zero";
  string public constant BP_TOKEN_TRANSFER = "14"; // "An error occurred during the transfer of the underlying token from user to JellyFi BorrowPool";
  string public constant BP_REPAY_AT_MATURITY_ONLY = "15"; // "Maturity has not been reached yet, action cannot be performed";
  string public constant BP_BORROW_COOLDOWN_PERIOD_NOT_OVER = "16"; // "Cooldown period after a repayment is not over";
  string public constant BP_TARGET_BOND_ISSUANCE_INDEX_EMPTY = "17"; // "Target bond issuance index has no amount to withdraw";
  string public constant BP_BOND_ISSUANCE_ID_TOO_HIGH = "18"; // "Bond issuance id is too high";
  string public constant BP_LOAN_ALREADY_ONGOING = "19"; // "There's already a loan ongoing";

  // PoolSettingsManager
  string public constant PSM_POOL_NOT_ACTIVE = "20"; // "Pool for targeted borrower is not active";
  string public constant PSM_POOL_ALREADY_SET_FOR_BORROWER = "21"; // "Targeted borrower is already set for another pool";
  string public constant PSM_POOL_TOKEN_NOT_SUPPORTED = "22"; // "Underlying token is not supported by the yield provider";
  string public constant PSM_DISALLOW_UNMATCHED_BORROWER = "23"; // "Revoking the wrong borrower as the provided borrower does not match the provided address";
  string public constant PSM_OUT_OF_BOUND_MIN_RATE = "24"; // "Min Rate must be lower than Max Rate ";
  string public constant PSM_OUT_OF_BOUND_MAX_RATE = "25"; // "Max Rate must be greater than Min Rate ";
  string public constant PSM_RATE_SPACING_COMPLIANCE = "26"; // "Provided rate must be compliant with rate spacing";
  string public constant PSM_POOL_DEFAULTED = "27"; // "Pool Defaulted";

  // Position
  string public constant POS_MGMT_ONLY_OWNER = "28"; // "Only the owner of the position token can manage it (update rate, withdraw)";
  string public constant POS_POSITION_ONLY_IN_BONDS = "29"; // "Cannot withdraw a position that's only in bonds";
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import {Rounding} from "./Rounding.sol";
import {WadRayMath} from "./WadRayMath.sol";

import "./Types.sol";
import "./Errors.sol";
import "../extensions/AaveILendingPool.sol";

library PoolLogic {
  enum BalanceUpdateType {
    INCREASE,
    DECREASE
  }
  event TickInitialized(bytes32 borrower, uint256 rate, uint256 jellyFiLiquidityRatio);
  event TickLoanDeposit(bytes32 borrower, uint256 rate, uint256 adjustedPendingDeposit, uint256 jellyFiLiquidityRatio);
  event TickNoLoanDeposit(
    bytes32 borrower,
    uint256 rate,
    uint256 adjustedPendingDeposit,
    uint256 jellyFiLiquidityRatio
  );
  event TickBorrow(
    bytes32 borrower,
    uint256 rate,
    uint256 adjustedRemainingAmountReduction,
    uint256 loanedAmount,
    uint256 jellyFiLiquidityRatio
  );
  event TickNoLoanWithdraw(
    bytes32 borrower,
    uint256 rate,
    uint256 adjustedAmountToWithdraw,
    uint256 jellyFiLiquidityRatio
  );
  event TickLoanWithdraw(
    bytes32 borrower,
    uint256 rate,
    uint256 adjustedAmountToWithdraw,
    uint256 jellyFiLiquidityRatio
  );
  event TickPendingDeposit(bytes32 borrower, uint256 rate, uint256 adjustedPendingAmount);
  event TickRepay(bytes32 borrower, uint256 rate, uint256 newAdjustedRemainingAmount, uint256 jellyFiLiquidityRatio);

  using PoolLogic for Types.Pool;
  using Rounding for uint256;
  using WadRayMath for uint256;

  uint256 public constant SECONDS_PER_YEAR = 365 days;
  uint256 public constant WAD = 1e18;
  uint256 public constant RAY = 1e27;

  /**
   * @dev Getter for the multiplier allowing a conversion between pending and deposited
   * amounts for the target bonds issuance index
   **/
  function getBondIssuanceMultiplierForTick(
    Types.Pool storage pool,
    uint256 rate,
    uint256 bondsIssuanceIndex
  ) internal view returns (uint256 returnBondsIssuanceMultiplier) {
    Types.Tick storage tick = pool.ticks[rate];
    returnBondsIssuanceMultiplier = tick.bondsIssuanceIndexMultiplier[bondsIssuanceIndex];
    if (returnBondsIssuanceMultiplier == 0) {
      returnBondsIssuanceMultiplier = RAY;
    }
  }

  /**
   * @dev Get share of accumulated fees from stored current tick state
   **/
  function getAccruedFeesShare(
    Types.Pool storage pool,
    uint256 rate,
    uint256 adjustedAmount
  ) internal view returns (uint256 accruedFeesShare) {
    Types.Tick storage tick = pool.ticks[rate];
    accruedFeesShare = tick.accruedFees.wadMul(adjustedAmount).wadDiv(tick.adjustedRemainingAmount);
  }

  /**
   * @dev Get share of accumulated fees from estimated current tick state
   **/
  function peekAccruedFeesShare(
    Types.Pool storage pool,
    uint256 rate,
    uint256 adjustedAmount,
    uint256 accruedFees
  ) internal view returns (uint256 accruedFeesShare) {
    Types.Tick storage tick = pool.ticks[rate];
    if (tick.adjustedRemainingAmount == 0) {
      return 0;
    }
    accruedFeesShare = accruedFees.wadMul(adjustedAmount).wadDiv(tick.adjustedRemainingAmount);
  }

  /**
   * @dev Initiliazes the tick by setting all properties to an initial state
   * Called for a new deposit and rate update when the rate provided has no tick initialized yet
   * Depending on the rate provided, lowerInterestRate's value might be updated with the rate
   **/
  function initializeTick(Types.Pool storage pool, uint256 rate) internal {
    Types.Tick storage tick = pool.ticks[rate];
    // set base data for tick if not initialised
    if (tick.adjustedTotalAmount == 0) {
      // TODO set initialized variable
      tick.yieldProviderLiquidityRatio = pool.parameters.YIELD_PROVIDER.getReserveNormalizedIncome(
        address(pool.parameters.UNDERLYING_TOKEN)
      );
      tick.jellyFiLiquidityRatio = tick.yieldProviderLiquidityRatio;
      tick.lastFeeDistributionTimestamp = block.timestamp;

      // update lowest interest rate to start iteration on future borrowings
      if ((pool.state.lowerInterestRate == 0) || (rate < pool.state.lowerInterestRate)) {
        pool.state.lowerInterestRate = rate;
      }
      emit TickInitialized(pool.parameters.BORROWER_HASH, rate, tick.yieldProviderLiquidityRatio);
    }
  }

  /**
   * @dev Deposit to a target tick
   * Updates tick data
   **/
  function depositToTick(
    Types.Pool storage pool,
    uint256 rate,
    uint256 normalizedAmount
  ) internal returns (uint256 adjustedAmount, uint256 returnBondsIssuanceIndex) {
    Types.Tick storage tick = pool.ticks[rate];

    pool.collectFeesForTick(rate);

    // if there is an ongoing loan, the deposited amount goes to the pending
    // quantity and will be considered for next loan
    if (pool.state.currentMaturity > 0) {
      adjustedAmount = normalizedAmount.rayDiv(tick.yieldProviderLiquidityRatio);
      tick.adjustedPendingAmount += adjustedAmount;
      returnBondsIssuanceIndex = tick.currentBondsIssuanceIndex + 1;
      emit TickLoanDeposit(pool.parameters.BORROWER_HASH, rate, adjustedAmount, tick.jellyFiLiquidityRatio);
    }
    // if there is no ongoing loan, the deposited amount goes to total and remaining
    // amount and can be borrowed instantaneously
    else {
      adjustedAmount = normalizedAmount.rayDiv(tick.jellyFiLiquidityRatio).rayDiv(
        pool.getBondIssuanceMultiplierForTick(rate, tick.currentBondsIssuanceIndex)
      );
      tick.adjustedTotalAmount += adjustedAmount;
      tick.adjustedRemainingAmount += adjustedAmount;
      returnBondsIssuanceIndex = tick.currentBondsIssuanceIndex;
      pool.state.normalizedAvailableDeposits += normalizedAmount;
      emit TickNoLoanDeposit(pool.parameters.BORROWER_HASH, rate, adjustedAmount, tick.jellyFiLiquidityRatio);
    }
    if ((pool.state.lowerInterestRate == 0) || (rate < pool.state.lowerInterestRate)) {
      pool.state.lowerInterestRate = rate;
    }
  }

  /**
   * @dev Computes the quantity of bonds purchased, and the equivalent adjusted deposit amount used for the issuance
   **/
  function getBondsIssuanceParametersForTick(
    Types.Pool storage pool,
    uint256 rate,
    uint256 normalizedRemainingAmount
  ) internal view returns (uint256 bondsPurchasedQuantity, uint256 normalizedUsedAmount) {
    Types.Tick storage tick = pool.ticks[rate];

    if (tick.adjustedRemainingAmount.rayMul(tick.jellyFiLiquidityRatio) > normalizedRemainingAmount) {
      normalizedUsedAmount = normalizedRemainingAmount;
    } else {
      normalizedUsedAmount = tick.adjustedRemainingAmount.rayMul(tick.jellyFiLiquidityRatio);
    }
    uint256 bondsPurchasePrice = getTickBondPrice(rate, pool.parameters.LOAN_DURATION);
    bondsPurchasedQuantity = normalizedUsedAmount.wadDiv(bondsPurchasePrice);
  }

  /**
   * @dev Makes all the state changes necessary to add bonds to a tick
   * Updates tick data and conversion data
   **/
  function addBondsToTick(
    Types.Pool storage pool,
    uint256 rate,
    uint256 bondsIssuedQuantity,
    uint256 normalizedUsedAmountForPurchase
  ) internal {
    Types.Tick storage tick = pool.ticks[rate];

    pool.collectFeesForTick(rate);

    // update global state for tick and pool
    tick.bondsQuantity += bondsIssuedQuantity;
    uint256 adjustedAmountForPurchase = normalizedUsedAmountForPurchase.rayDiv(tick.jellyFiLiquidityRatio);
    tick.adjustedRemainingAmount -= adjustedAmountForPurchase;
    tick.normalizedLoanedAmount += normalizedUsedAmountForPurchase;
    // emit event with tick updates
    emit TickBorrow(
      pool.parameters.BORROWER_HASH,
      rate,
      adjustedAmountForPurchase,
      normalizedUsedAmountForPurchase,
      tick.jellyFiLiquidityRatio
    );
    pool.state.bondsIssuedQuantity += bondsIssuedQuantity;
    pool.state.normalizedAvailableDeposits -= normalizedUsedAmountForPurchase;
  }

  /**
   * @dev Computes how the position is split between deposit and bonds
   **/
  function computeAmountRepartitionForTick(
    Types.Pool storage pool,
    uint256 rate,
    uint256 adjustedAmount,
    uint256 bondsIssuanceIndex
  ) internal view returns (uint256 bondsQuantity, uint256 adjustedDepositedAmount) {
    Types.Tick storage tick = pool.ticks[rate];

    if (bondsIssuanceIndex > tick.currentBondsIssuanceIndex) {
      return (0, adjustedAmount);
    }

    adjustedAmount = adjustedAmount.rayMul(pool.getBondIssuanceMultiplierForTick(rate, bondsIssuanceIndex));
    uint256 adjustedAmountUsedForBondsIssuance;
    if (tick.adjustedTotalAmount > 0) {
      adjustedAmountUsedForBondsIssuance = adjustedAmount
        .wadMul(tick.adjustedTotalAmount - tick.adjustedRemainingAmount)
        .wadDiv(tick.adjustedTotalAmount + tick.adjustedWithdrawnAmount);
    }

    if (tick.adjustedTotalAmount > tick.adjustedRemainingAmount) {
      bondsQuantity = tick.bondsQuantity.wadMul(adjustedAmountUsedForBondsIssuance).wadDiv(
        tick.adjustedTotalAmount - tick.adjustedRemainingAmount
      );
    }
    adjustedDepositedAmount = (adjustedAmount - adjustedAmountUsedForBondsIssuance);
  }

  /**
   * @dev Updates tick data after a withdrawal consisting of only amount deposited to yield provider
   **/
  function withdrawDepositedAmountForTick(
    Types.Pool storage pool,
    uint256 rate,
    uint256 adjustedAmountToWithdraw,
    uint256 bondsIssuanceIndex
  ) internal returns (uint256 normalizedAmountToWithdraw) {
    Types.Tick storage tick = pool.ticks[rate];

    pool.collectFeesForTick(rate);

    if (bondsIssuanceIndex <= tick.currentBondsIssuanceIndex) {
      uint256 feesShareToWithdraw = pool.getAccruedFeesShare(rate, adjustedAmountToWithdraw);
      tick.accruedFees -= feesShareToWithdraw;
      tick.adjustedTotalAmount -= adjustedAmountToWithdraw;
      tick.adjustedRemainingAmount -= adjustedAmountToWithdraw;
      normalizedAmountToWithdraw = adjustedAmountToWithdraw.rayMul(tick.jellyFiLiquidityRatio) + feesShareToWithdraw;
      pool.state.normalizedAvailableDeposits -= normalizedAmountToWithdraw.round();
      // register withdrawn amount from partially matched positions
      // to maintain the proportion of bonds in each subsequent position the same
      if (tick.bondsQuantity > 0) {
        tick.adjustedWithdrawnAmount += adjustedAmountToWithdraw;
      }
      emit TickLoanWithdraw(pool.parameters.BORROWER_HASH, rate, adjustedAmountToWithdraw, tick.jellyFiLiquidityRatio);
    } else {
      tick.adjustedPendingAmount -= adjustedAmountToWithdraw;
      // TODO branch not covered
      normalizedAmountToWithdraw = adjustedAmountToWithdraw.rayMul(tick.yieldProviderLiquidityRatio);
      emit TickNoLoanWithdraw(
        pool.parameters.BORROWER_HASH,
        rate,
        adjustedAmountToWithdraw,
        tick.jellyFiLiquidityRatio
      );
    }

    // update lowerInterestRate if necessary
    if ((rate == pool.state.lowerInterestRate) && tick.adjustedTotalAmount == 0) {
      uint256 nextRate = rate + pool.parameters.RATE_SPACING;
      while (nextRate <= pool.parameters.MAX_RATE && pool.ticks[nextRate].adjustedTotalAmount == 0) {
        nextRate += pool.parameters.RATE_SPACING;
      }
      if (nextRate >= pool.parameters.MAX_RATE) {
        pool.state.lowerInterestRate = 0;
      } else {
        pool.state.lowerInterestRate = nextRate;
      }
    }
  }

  /**
   * @dev Updates tick data after a repayment
   **/
  function repayForTick(
    Types.Pool storage pool,
    uint256 rate,
    uint256 lateRepayFeePerBond
  ) internal {
    Types.Tick storage tick = pool.ticks[rate];

    if (tick.bondsQuantity > 0) {
      pool.collectFeesForTick(rate);

      // update liquidity ratio with interests from bonds, yield provider and maintenance fees
      // includes late repay fees if applicable
      uint256 bondPaidInterests = tick.bondsQuantity - tick.normalizedLoanedAmount;
      uint256 lateRepayFees = tick.bondsQuantity.wadMul(lateRepayFeePerBond);
      tick.jellyFiLiquidityRatio += (tick.accruedFees + bondPaidInterests + lateRepayFees)
        .wadDiv(tick.adjustedTotalAmount)
        .wadToRay();

      // update global pool state
      pool.state.bondsIssuedQuantity -= tick.bondsQuantity;
      pool.state.normalizedAvailableDeposits += tick.bondsQuantity + tick.bondsQuantity.wadMul(lateRepayFeePerBond);

      // update tick amounts
      tick.bondsQuantity = 0;
      tick.adjustedWithdrawnAmount = 0;
      tick.normalizedLoanedAmount = 0;
      tick.accruedFees = 0;
      tick.adjustedRemainingAmount = tick.adjustedTotalAmount;
      emit TickRepay(pool.parameters.BORROWER_HASH, rate, tick.adjustedTotalAmount, tick.jellyFiLiquidityRatio);
    }
  }

  /**
   * @dev Updates tick data after a repayment
   **/
  function acceptPendingDepositsForTick(Types.Pool storage pool, uint256 rate) internal {
    Types.Tick storage tick = pool.ticks[rate];

    if (tick.adjustedPendingAmount > 0) {
      pool.collectFeesForTick(rate);

      // include pending deposit amount into tick excluding them from bonds interest from current issuance
      tick.currentBondsIssuanceIndex += 1;
      tick.bondsIssuanceIndexMultiplier[tick.currentBondsIssuanceIndex] = RAY
        .rayMul(tick.yieldProviderLiquidityRatio)
        .rayDiv(tick.jellyFiLiquidityRatio);
      uint256 adjustedPendingAmount = tick.adjustedPendingAmount.rayMul(
        tick.bondsIssuanceIndexMultiplier[tick.currentBondsIssuanceIndex]
      );

      // update global pool state
      pool.state.normalizedAvailableDeposits += tick.adjustedPendingAmount.rayMul(tick.yieldProviderLiquidityRatio);

      // update tick amounts
      tick.adjustedTotalAmount += adjustedPendingAmount;
      tick.adjustedRemainingAmount = tick.adjustedTotalAmount;
      tick.adjustedPendingAmount = 0;
      emit TickPendingDeposit(pool.parameters.BORROWER_HASH, rate, adjustedPendingAmount);
    }
  }

  /**
   * @dev Top up maintenance fees for later distribution
   **/
  function topUpMaintenanceFees(Types.Pool storage pool, uint256 normalizedAmount) internal {
    pool.state.remainingMaintenanceFeesReserve += normalizedAmount;
  }

  /**
   * @dev Includes last interests paid by yield provider into liquidity ratios
   * Aave liquidity ratio being in ray, a conversion to was is necessary
   * Updates global deposited amount in consequence
   **/
  function collectFeesForTick(Types.Pool storage pool, uint256 rate) internal {
    Types.Tick storage tick = pool.ticks[rate];
    if (tick.adjustedRemainingAmount > 0 && tick.lastFeeDistributionTimestamp < block.timestamp) {
      // compute yield provider fees impact
      uint256 newYieldProviderLiquidityRatio = pool.parameters.YIELD_PROVIDER.getReserveNormalizedIncome(
        address(pool.parameters.UNDERLYING_TOKEN)
      );
      uint256 yieldProviderLiquidityRatioIncrease = newYieldProviderLiquidityRatio - tick.yieldProviderLiquidityRatio;

      // compute maintenance fees impact
      uint256 addedMaintenanceFee = (pool.parameters.MGT_FEE_DISTRIBUTION_RATE *
        (block.timestamp - tick.lastFeeDistributionTimestamp))
        .wadMul(pool.parameters.MAX_BORROWABLE_AMOUNT - pool.state.normalizedBorrowedAmount)
        .wadDiv(pool.parameters.MAX_BORROWABLE_AMOUNT)
        .wadMul(tick.adjustedRemainingAmount.rayMul(tick.jellyFiLiquidityRatio))
        .wadDiv(pool.state.normalizedAvailableDeposits);
      if (addedMaintenanceFee > pool.state.remainingMaintenanceFeesReserve) {
        addedMaintenanceFee = pool.state.remainingMaintenanceFeesReserve;
        pool.state.remainingMaintenanceFeesReserve = 0;
      } else {
        pool.state.remainingMaintenanceFeesReserve -= addedMaintenanceFee;
      }

      // no ongoing loan, all deposited amount get the yield provider and maintenance fees
      if (pool.state.currentMaturity == 0) {
        tick.jellyFiLiquidityRatio +=
          yieldProviderLiquidityRatioIncrease +
          addedMaintenanceFee.wadToRay().wadDiv(tick.adjustedRemainingAmount);
      }
      // ongoing loan, fees accrued are calculated separately, global liquidity ratio will be updated at repay time
      else {
        tick.accruedFees +=
          tick.adjustedRemainingAmount.rayMul(yieldProviderLiquidityRatioIncrease) +
          addedMaintenanceFee;
      }

      // update checkpoint data
      tick.yieldProviderLiquidityRatio = newYieldProviderLiquidityRatio;
      tick.lastFeeDistributionTimestamp = block.timestamp;

      // update global deposited amount
      pool.state.normalizedAvailableDeposits +=
        addedMaintenanceFee +
        tick.adjustedRemainingAmount.rayMul(yieldProviderLiquidityRatioIncrease);
    }
  }

  /**
   * @dev Peek updated liquidity ratio and accrued fess for the target tick
   **/
  function peekFeesForTick(Types.Pool storage pool, uint256 rate)
    internal
    view
    returns (uint256 jellyFiLiquidityRatio, uint256 accruedFees)
  {
    Types.Tick storage tick = pool.ticks[rate];

    jellyFiLiquidityRatio = tick.jellyFiLiquidityRatio;
    accruedFees = tick.accruedFees;

    if (tick.adjustedRemainingAmount > 0) {
      // compute yield provider fees impact
      uint256 newYieldProviderLiquidityRatio = pool.parameters.YIELD_PROVIDER.getReserveNormalizedIncome(
        address(pool.parameters.UNDERLYING_TOKEN)
      );
      uint256 yieldProviderLiquidityRatioIncrease = newYieldProviderLiquidityRatio - tick.yieldProviderLiquidityRatio;

      // compute maintenance fees impact
      uint256 addedMaintenanceFee = (pool.parameters.MGT_FEE_DISTRIBUTION_RATE *
        (block.timestamp - tick.lastFeeDistributionTimestamp))
        .wadMul(tick.adjustedRemainingAmount.rayMul(tick.jellyFiLiquidityRatio))
        .wadDiv(pool.state.normalizedAvailableDeposits);
      if (addedMaintenanceFee > pool.state.remainingMaintenanceFeesReserve) {
        addedMaintenanceFee = pool.state.remainingMaintenanceFeesReserve;
      }

      // no ongoing loan, all deposited amount get the yield provider and maintenance fees
      if (pool.state.currentMaturity == 0) {
        jellyFiLiquidityRatio +=
          yieldProviderLiquidityRatioIncrease +
          addedMaintenanceFee.wadToRay().wadDiv(tick.adjustedRemainingAmount);
      }
      // ongoing loan, fees accrued are calculated separately, global liquidity ratio will be updated at repay time
      else {
        accruedFees += tick.adjustedRemainingAmount.rayMul(yieldProviderLiquidityRatioIncrease) + addedMaintenanceFee;
      }
    }
  }

  function getTickBondPrice(uint256 rate, uint256 loanDuration) public pure returns (uint256 price) {
    price = WAD.wadDiv(WAD + (rate * loanDuration) / SECONDS_PER_YEAR);
  }

  function depositToYieldProvider(
    Types.Pool storage pool,
    address from,
    uint256 normalizedAmount,
    ILendingPool yieldProvider
  ) internal {
    IERC20Upgradeable underlyingToken = IERC20Upgradeable(pool.parameters.UNDERLYING_TOKEN);
    bool approval = IERC20Upgradeable(pool.parameters.UNDERLYING_TOKEN).approve(
      address(yieldProvider),
      normalizedAmount
    );
    require(approval, Errors.BP_YIELD_PROVIDER_APPROVAL_FOR_TOKEN);
    bool transferFrom = IERC20Upgradeable(underlyingToken).transferFrom(from, address(this), normalizedAmount);
    require(transferFrom, Errors.BP_TOKEN_TRANSFER);
    yieldProvider.deposit(address(underlyingToken), normalizedAmount, address(this), 0);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

/**
 * @title Rounding library
 * @author JellyFi
 * @dev Rounding utilities to mitigate precision loss when doing wad ray math operations
 **/

library Rounding {
  using Rounding for uint256;

  uint256 internal constant PRECISION = 1e3;

  function round(uint256 amount) internal pure returns (uint256) {
    return (amount / PRECISION) * PRECISION;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "../extensions/AaveILendingPool.sol";

library Types {
  struct PositionDetails {
    uint256 adjustedBalance;
    uint256 rate;
    bytes32 borrower;
    address underlyingToken;
    uint256 remainingBonds;
    uint256 bondsMaturity;
    uint256 bondsIssuanceIndex;
  }

  struct Tick {
    uint256 currentBondsIssuanceIndex;
    mapping(uint256 => uint256) bondsIssuanceIndexMultiplier;
    uint256 bondsQuantity;
    uint256 adjustedTotalAmount;
    uint256 adjustedRemainingAmount;
    uint256 adjustedWithdrawnAmount;
    uint256 adjustedPendingAmount;
    uint256 normalizedLoanedAmount;
    uint256 lastFeeDistributionTimestamp;
    uint256 yieldProviderLiquidityRatio;
    uint256 jellyFiLiquidityRatio;
    uint256 accruedFees;
  }

  struct PoolParameters {
    bytes32 BORROWER_HASH;
    address UNDERLYING_TOKEN;
    ILendingPool YIELD_PROVIDER;
    uint256 MIN_RATE;
    uint256 MAX_RATE;
    uint256 RATE_SPACING;
    uint256 MAX_BORROWABLE_AMOUNT;
    uint256 LOAN_DURATION;
    uint256 COOLDOWN_PERIOD;
    uint256 MGT_FEE_DISTRIBUTION_RATE;
    uint256 LATE_REPAY_THRESHOLD;
    uint256 LATE_REPAY_FEE;
  }

  struct PoolState {
    bool defaulted;
    uint256 bondsIssuedQuantity;
    uint256 normalizedBorrowedAmount;
    uint256 normalizedAvailableDeposits;
    uint256 currentMaturity;
    uint256 lowerInterestRate;
    uint256 nextLoanMinStart;
    uint256 remainingMaintenanceFeesReserve;
  }

  struct Pool {
    bool initialized;
    PoolParameters parameters;
    PoolState state;
    mapping(uint256 => Tick) ticks;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "./Errors.sol";

/**
 * @title WadRayMath library
 * @author Aave
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 **/

library WadRayMath {
  uint256 internal constant WAD = 1e18;
  uint256 internal constant halfWAD = WAD / 2;

  uint256 internal constant RAY = 1e27;
  uint256 internal constant halfRAY = RAY / 2;

  uint256 internal constant WAD_RAY_RATIO = 1e9;

  /**
   * @return One ray, 1e27
   **/
  function ray() internal pure returns (uint256) {
    return RAY;
  }

  /**
   * @return One wad, 1e18
   **/

  function wad() internal pure returns (uint256) {
    return WAD;
  }

  /**
   * @return Half ray, 1e27/2
   **/
  function halfRay() internal pure returns (uint256) {
    return halfRAY;
  }

  /**
   * @return Half ray, 1e18/2
   **/
  function halfWad() internal pure returns (uint256) {
    return halfWAD;
  }

  /**
   * @dev Multiplies two wad, rounding half up to the nearest wad
   * @param a Wad
   * @param b Wad
   * @return The result of a*b, in wad
   **/
  function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }

    require(a <= (type(uint256).max - halfWAD) / b, Errors.MATH_MULTIPLICATION_OVERFLOW);

    return (a * b + halfWAD) / WAD;
  }

  /**
   * @dev Divides two wad, rounding half up to the nearest wad
   * @param a Wad
   * @param b Wad
   * @return The result of a/b, in wad
   **/
  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, Errors.MATH_DIVISION_BY_ZERO);
    uint256 halfB = b / 2;

    require(a <= (type(uint256).max - halfB) / WAD, Errors.MATH_MULTIPLICATION_OVERFLOW);

    return (a * WAD + halfB) / b;
  }

  /**
   * @dev Multiplies two ray, rounding half up to the nearest ray
   * @param a Ray
   * @param b Ray
   * @return The result of a*b, in ray
   **/
  function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }

    require(a <= (type(uint256).max - halfRAY) / b, Errors.MATH_MULTIPLICATION_OVERFLOW);

    return (a * b + halfRAY) / RAY;
  }

  /**
   * @dev Divides two ray, rounding half up to the nearest ray
   * @param a Ray
   * @param b Ray
   * @return The result of a/b, in ray
   **/
  function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, Errors.MATH_DIVISION_BY_ZERO);
    uint256 halfB = b / 2;

    require(a <= (type(uint256).max - halfB) / RAY, Errors.MATH_MULTIPLICATION_OVERFLOW);

    return (a * RAY + halfB) / b;
  }

  /**
   * @dev Casts ray down to wad
   * @param a Ray
   * @return a casted to wad, rounded half up to the nearest wad
   **/
  function rayToWad(uint256 a) internal pure returns (uint256) {
    uint256 halfRatio = WAD_RAY_RATIO / 2;
    uint256 result = halfRatio + a;
    require(result >= halfRatio, Errors.MATH_ADDITION_OVERFLOW);

    return result / WAD_RAY_RATIO;
  }

  /**
   * @dev Converts wad up to ray
   * @param a Wad
   * @return a converted in ray
   **/
  function wadToRay(uint256 a) internal pure returns (uint256) {
    uint256 result = a * WAD_RAY_RATIO;
    require(result / WAD_RAY_RATIO == a, Errors.MATH_MULTIPLICATION_OVERFLOW);
    return result;
  }
}