// SPDX-License-Identifier: MIT

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
     * If the calling account had been granted `role`, emits a {RoleRevoked}
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

import {OrderBookLogic} from "./lib/OrderBookLogic.sol";
import {WadRayMath} from "./lib/WadRayMath.sol";

import "./PoolSettingsManager.sol";
import "./extensions/AaveILendingPool.sol";
import "./lib/Types.sol";
import "./lib/Errors.sol";

import "./interfaces/IBorrowPool.sol";

contract BorrowPool is Initializable, IBorrowPool, PoolSettingsManager {
  using OrderBookLogic for Types.Pool;
  using WadRayMath for uint256;

  function initialize(
    ILendingPool _aaveLendingPool // beta
  ) public initializer {
    yieldProvider = _aaveLendingPool;
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setRoleAdmin(BORROWER_ROLE, GOVERNANCE_ROLE);
  }

  // VIEW METHODS

  function getTickLiquidityRatio(bytes32 borrower, uint256 rate) public view override returns (uint256) {
    return pools[borrower].ticks[rate].jellyFiLiquidityRatio;
  }

  function getTickAmounts(string calldata borrower, uint256 rate)
    public
    view
    override
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    Types.Tick storage tick = pools[keccak256(abi.encode(borrower))].ticks[rate];
    return (tick.adjustedTotalAmount, tick.adjustedRemainingAmount, tick.bondsQuantity);
  }

  function getPoolState(bytes32 borrower)
    external
    view
    override
    returns (
      uint256 averageBorrowRate,
      uint256 totalBonds,
      uint256 availableDeposits
    )
  {
    Types.Pool storage pool = pools[borrower];
    Types.PoolParameters storage parameters = pools[borrower].parameters;
    uint256 rate = parameters.MIN_RATE;
    uint256 totalAmount = 0;
    uint256 amountWeightedRate = 0;
    totalBonds = pool.state.bondsIssuedQuantity;

    for (rate; rate != parameters.MAX_RATE + parameters.RATE_SPACING; rate += parameters.RATE_SPACING) {
      amountWeightedRate += pool.ticks[rate].bondsQuantity * rate;
      totalAmount += pool.ticks[rate].bondsQuantity;
      // no need to iterate over ticks further if all ticks with bonds have been covered
      if (totalAmount >= totalBonds) break;
      rate += parameters.RATE_SPACING;
    }
    averageBorrowRate = amountWeightedRate / totalAmount;
    availableDeposits = pool.state.totalNormalizedDeposits - totalBonds;
  }

  struct DepositContext {
    uint256 adjustedAmount;
    bool approval;
    bool transferFrom;
  }

  // LENDER METHODS
  function deposit(
    uint256 normalizedAmount,
    uint256 rate,
    bytes32 borrower,
    address underlyingToken,
    address sender
  ) public override whenNotPaused onlyRole(POSITION_ROLE) onlyActiveOrderBook(borrower) returns (uint256) {
    Types.Pool storage pool = pools[borrower];
    DepositContext memory ctx;

    require(underlyingToken == pool.parameters.UNDERLYING_TOKEN, Errors.BP_UNMATCHED_TOKEN);
    require(rate >= pool.parameters.MIN_RATE, Errors.BP_OUT_OF_BOUND_MIN_RATE);
    require(rate <= pool.parameters.MAX_RATE, Errors.BP_OUT_OF_BOUND_MAX_RATE);
    require(rate % pool.parameters.RATE_SPACING == 0, Errors.BP_RATE_SPACING);
    require(
      pool.state.totalNormalizedDeposits + normalizedAmount < pool.parameters.MAX_TOKEN_DEPOSIT,
      Errors.BP_DEPOSIT_MAX_TOKEN_DEPOSIT_EXCEEDED
    );

    pool.initializeTick(rate);
    ctx.adjustedAmount = pool.depositToTick(rate, normalizedAmount);

    ctx.approval = IERC20Upgradeable(underlyingToken).approve(address(yieldProvider), normalizedAmount);
    require(ctx.approval, Errors.BP_YIELD_PROVIDER_APPROVAL_FOR_TOKEN);
    ctx.transferFrom = IERC20Upgradeable(underlyingToken).transferFrom(sender, address(this), normalizedAmount);
    require(ctx.transferFrom, Errors.BP_TOKEN_TRANSFER_FROM_LENDER);

    yieldProvider.deposit(address(underlyingToken), normalizedAmount, address(this), 0);

    return ctx.adjustedAmount;
  }

  struct WithdrawContext {
    uint256 remainingBondsQuantity;
    uint256 depositAmountToWithdraw;
    uint256 normalisedDepositedAmountToWithdraw;
  }

  function withdraw(
    address to,
    uint256 adjustedAmount,
    uint256 rate,
    bytes32 borrower
  )
    public
    override
    whenNotPaused
    onlyRole(POSITION_ROLE)
    onlyActiveOrderBook(borrower)
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    Types.Pool storage pool = pools[borrower];
    WithdrawContext memory ctx;

    (ctx.remainingBondsQuantity, ctx.depositAmountToWithdraw) = pool.computeWithdrawRepartitionForTick(
      rate,
      adjustedAmount
    );
    require(ctx.depositAmountToWithdraw > 0, Errors.BP_NO_DEPOSIT_TO_WITHDRAW);
    ctx.normalisedDepositedAmountToWithdraw = pool.withdrawDepositedAmountForTick(rate, ctx.depositAmountToWithdraw); // TODO #87 : uint256 normalisedDepositedAmountToWithdraw => returned value of withdrawDepositedAmountForTick

    yieldProvider.withdraw(pool.parameters.UNDERLYING_TOKEN, ctx.normalisedDepositedAmountToWithdraw, to);

    emit Withdraw(to, adjustedAmount, rate);

    return (ctx.depositAmountToWithdraw, ctx.remainingBondsQuantity, pool.state.currentMaturity);
  }

  function updateRate(
    uint256 adjustedAmount,
    bytes32 borrower,
    uint256 oldRate,
    uint256 newRate
  ) public override whenNotPaused onlyRole(POSITION_ROLE) returns (uint256) {
    Types.Pool storage pool = pools[borrower];

    // cannot update rate when being borrowed
    require(newRate >= pool.parameters.MIN_RATE, Errors.BP_OUT_OF_BOUND_MIN_RATE);
    require(newRate <= pool.parameters.MAX_RATE, Errors.BP_OUT_OF_BOUND_MAX_RATE);
    require(newRate % pool.parameters.RATE_SPACING == 0, Errors.BP_RATE_SPACING);

    pool.initializeTick(newRate);

    uint256 normalizedAmount = pool.withdrawDepositedAmountForTick(oldRate, adjustedAmount);
    uint256 newAdjustedAmount = pool.depositToTick(newRate, normalizedAmount);

    emit UpdateRate(adjustedAmount, oldRate, newRate);

    return newAdjustedAmount;
  }

  // BORROWER METHODS
  function borrow(address to, uint256 normalizedBorrowedAmount)
    external
    override
    whenNotPaused
    onlyRole(BORROWER_ROLE)
  {
    bytes32 borrower = borrowerAuthorizedAddresses[_msgSender()];
    Types.Pool storage pool = pools[borrower];

    require(pool.state.currentMaturity == 0, "loan already ongoing");
    require(normalizedBorrowedAmount <= pool.state.totalNormalizedDeposits, Errors.BP_BORROW_OUT_OF_BOUND_AMOUNT);
    require(block.timestamp > pool.state.nextLoanMinStart, Errors.BP_BORROW_MATURITY_EXPIRED);

    pool.state.currentMaturity = block.timestamp + pool.parameters.LOAN_DURATION;

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
    pool.state.higherInterestRate = currentInterestRate;

    yieldProvider.withdraw(pool.parameters.UNDERLYING_TOKEN, normalizedBorrowedAmount, to);

    emit Borrow(borrower, normalizedBorrowedAmount, pool.state.currentMaturity);
  }

  function repay() external override whenNotPaused onlyRole(BORROWER_ROLE) {
    Types.Pool storage orderBook = pools[borrowerAuthorizedAddresses[_msgSender()]];
    require(orderBook.state.currentMaturity > 0, Errors.BP_REPAY_NO_ACTIVE_LOAN);
    require(orderBook.state.currentMaturity <= block.timestamp, Errors.BP_REPAY_AT_MATURITY_ONLY);

    uint256 normalizedRepayAmount = orderBook.state.bondsIssuedQuantity;
    uint256 currentInterestRate = orderBook.state.higherInterestRate;

    while (currentInterestRate >= orderBook.state.lowerInterestRate) {
      orderBook.repayForTick(currentInterestRate);
      currentInterestRate -= orderBook.parameters.RATE_SPACING;
    }

    // set global data for next loan
    orderBook.state.nextLoanMinStart = orderBook.state.currentMaturity + orderBook.parameters.COOLDOWN_PERIOD;
    orderBook.state.currentMaturity = 0;
    orderBook.state.higherInterestRate = 0;

    IERC20Upgradeable underlyingToken = IERC20Upgradeable(orderBook.parameters.UNDERLYING_TOKEN);
    bool approval = IERC20Upgradeable(orderBook.parameters.UNDERLYING_TOKEN).approve(
      address(yieldProvider),
      normalizedRepayAmount
    );
    require(approval, Errors.BP_YIELD_PROVIDER_APPROVAL_FOR_TOKEN);
    bool transferFrom = IERC20Upgradeable(underlyingToken).transferFrom(
      _msgSender(),
      address(this),
      normalizedRepayAmount
    );
    require(transferFrom, Errors.BP_TOKEN_TRANSFER_FROM_BORROWER);
    yieldProvider.deposit(address(underlyingToken), normalizedRepayAmount, address(this), 0);

    emit Repay(_msgSender(), normalizedRepayAmount, orderBook.state.currentMaturity);
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

import "./interfaces/IGovernanceActions.sol";

contract PoolSettingsManager is AccessControlUpgradeable, PausableUpgradeable, IGovernanceActions {
  // contract roles
  bytes32 public constant BORROWER_ROLE = keccak256("BORROWER_ROLE");
  bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
  bytes32 public constant POSITION_ROLE = keccak256("POSITION_ROLE");

  // borrowers management
  mapping(address => bytes32) public borrowerAuthorizedAddresses;

  // interest rate order book
  mapping(bytes32 => Types.Pool) public pools;

  // yield provider contract interface
  ILendingPool public yieldProvider;

  // BORROWER MANAGEMENT

  function isOrderBookActive(bytes32 borrower) external view override returns (bool) {
    return pools[borrower].parameters.RATE_SPACING > 0;
  }

  modifier onlyActiveOrderBook(bytes32 borrower) {
    require(pools[borrower].parameters.RATE_SPACING > 0, Errors.PSM_ORDERBOOK_NOT_ACTIVE);
    _;
  }

  /**
   * @dev Creates a new orderbook
   * @param borrower The borrower that will interact with lenders in this orderbook
   * @param underlyingToken A supported-by-Aave token
   **/
  function createNewOrderbook(
    string calldata borrower,
    address underlyingToken,
    uint256 minRate,
    uint256 maxRate,
    uint256 rateSpacing,
    uint256 maxTokenDeposit,
    uint256 loanDuration,
    uint256 cooldownPeriod
  ) external override onlyRole(GOVERNANCE_ROLE) {
    bytes32 borrowerHash = keccak256(abi.encode(borrower));
    require(pools[borrowerHash].parameters.RATE_SPACING == 0, Errors.PSM_ORDERBOOK_ALREADY_SET_FOR_BORROWER);
    DataTypes.ReserveData memory reserveData = yieldProvider.getReserveData(underlyingToken);
    require(reserveData.id > 0, Errors.PSM_ORDERBOOK_TOKEN_NOT_SUPPORTED);

    // initialise order book state and parameters
    pools[borrowerHash].parameters = Types.PoolParameters({
      UNDERLYING_TOKEN: underlyingToken,
      YIELD_PROVIDER: yieldProvider,
      MIN_RATE: minRate,
      MAX_RATE: maxRate,
      RATE_SPACING: rateSpacing,
      MAX_TOKEN_DEPOSIT: maxTokenDeposit,
      LOAN_DURATION: loanDuration,
      COOLDOWN_PERIOD: cooldownPeriod
    });

    emit OrderBookCreated(borrowerHash);
  }

  function allow(address borrowerAddress, string calldata borrower)
    external
    override
    onlyRole(GOVERNANCE_ROLE)
    onlyActiveOrderBook(keccak256(abi.encode(borrower)))
  {
    grantRole(BORROWER_ROLE, borrowerAddress);
    borrowerAuthorizedAddresses[borrowerAddress] = keccak256(abi.encode(borrower));
  }

  function disallow(address borrowerAddress, string calldata borrower)
    external
    override
    onlyRole(GOVERNANCE_ROLE)
    onlyActiveOrderBook(keccak256(abi.encode(borrower)))
  {
    require(
      borrowerAuthorizedAddresses[borrowerAddress] == keccak256(abi.encode(borrower)),
      Errors.PSM_DISALLOW_UNMATCHED_BORROWER
    );
    revokeRole(BORROWER_ROLE, borrowerAddress);
    delete borrowerAuthorizedAddresses[borrowerAddress];
  }

  // POOL PARAMETERS MANAGEMENT

  function setMinRate(uint256 minRate, bytes32 borrower)
    external
    override
    onlyRole(GOVERNANCE_ROLE)
    onlyActiveOrderBook(borrower)
  {
    require(minRate < pools[borrower].parameters.MAX_RATE, Errors.PSM_OUT_OF_BOUND_MIN_RATE);
    require(minRate % pools[borrower].parameters.RATE_SPACING == 0, Errors.PSM_RATE_SPACING_COMPLIANCE);
    pools[borrower].parameters.MIN_RATE = minRate;
    if (pools[borrower].state.lowerInterestRate < minRate) {
      pools[borrower].state.lowerInterestRate = minRate;
    }
  }

  function setMaxRate(uint256 maxRate, bytes32 borrower)
    external
    override
    onlyRole(GOVERNANCE_ROLE)
    onlyActiveOrderBook(borrower)
  {
    require(maxRate > pools[borrower].parameters.MIN_RATE, Errors.PSM_OUT_OF_BOUND_MAX_RATE);
    require(maxRate % pools[borrower].parameters.RATE_SPACING == 0, Errors.PSM_RATE_SPACING_COMPLIANCE);
    pools[borrower].parameters.MAX_RATE = maxRate;
  }

  function setMaxTokenDeposit(uint256 maxTokenDeposit, bytes32 borrower)
    external
    override
    onlyRole(GOVERNANCE_ROLE)
    onlyActiveOrderBook(borrower)
  {
    pools[borrower].parameters.MAX_TOKEN_DEPOSIT = maxTokenDeposit;
  }

  function setCooldownPeriod(uint256 cooldownPeriod, bytes32 borrower)
    external
    override
    onlyRole(GOVERNANCE_ROLE)
    onlyActiveOrderBook(borrower)
  {
    pools[borrower].parameters.COOLDOWN_PERIOD = cooldownPeriod;
  }

  // EMERGENCY FREEZE
  function freezePool() external override onlyRole(GOVERNANCE_ROLE) {
    _pause();
  }

  function unfreezePool() external override onlyRole(GOVERNANCE_ROLE) {
    _unpause();
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

import "../extensions/AaveILendingPool.sol";

interface IBorrowPool {
  event Borrow(bytes32 indexed borrower, uint256 amount, uint256 maturity);
  event Repay(address indexed borrower, uint256 amount, uint256 maturity);
  event Withdraw(address indexed lender, uint256 amount, uint256 rate);
  event Sell(address indexed lender, uint256 bondsQuantity, uint256 originRate, uint256 targetRate);
  event Liquidate(
    address indexed lender,
    uint256 amount,
    uint256 bondsQuantity,
    uint256 originRate,
    uint256 targetRate
  );
  event UpdateRate(uint256 amount, uint256 oldRate, uint256 newRate);

  function getTickLiquidityRatio(bytes32 borrower, uint256 rate) external view returns (uint256);

  function getTickAmounts(string calldata borrower, uint256 rate)
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    );

  function getPoolState(bytes32 borrower)
    external
    view
    returns (
      uint256 averageBorrowRate,
      uint256 totalBonds,
      uint256 availableDeposits
    );

  /**
   * @notice Deposits the input amount with the yield provider and stores the bid in the order book
   * @dev Deposit funds from a lender position
   * Initializes the target tick if it is the first time it is used
   * @param normalizedAmount The amount to deposit
   * @param rate The rate at which the bond order bid is placed
   * @param borrower The identifier of the borrower
   * @param underlyingToken The ERC20 interfact of the asset that is deposited
   * @param sender The address of the EOA/Contract that deposits the funds
   * @return Adjusted amount for the newly created position
   **/
  function deposit(
    uint256 normalizedAmount,
    uint256 rate,
    bytes32 borrower,
    address underlyingToken,
    address sender
  ) external returns (uint256);

  /**
   * @notice Withdraws the deposited amount with the yield provider
   * @dev Withdraw funds from a lender position
   * withdraws the yield provider deposited part of the position
   * bonds purchased with the position will remain
   * @param to The address of the position owner
   * @param adjustedAmount The full balance of the position
   * @param rate The rate at which the position bids for bonds
   * @param borrower The identifier of the borrower
   * @return depositAmountToWithdraw, the amount that gets withdawn
   * @return remainingBondsQuantity, the amount of bonds that remain in the Position
   * @return currentMaturity, the maturity of the bonds at the time of the withdrawal
   **/
  function withdraw(
    address to,
    uint256 adjustedAmount,
    uint256 rate,
    bytes32 borrower
  )
    external
    returns (
      uint256,
      uint256,
      uint256
    );

  /**
   * @notice Uppdates the old and new tick state
   * @dev Update a position's rate
   * Can only be updated if the position has no bonds
   * @param adjustedAmount The full balance of the position
   * @param borrower The identifier of the borrower
   * @param oldRate The current rate of the position
   * @param newRate The new rate of the position
   * @return  oldToNewAdjustedAmount, the updated amount of tokens of the position,
   * adjusted to the new tick's global liquidity ratio
   **/
  function updateRate(
    uint256 adjustedAmount,
    bytes32 borrower,
    uint256 oldRate,
    uint256 newRate
  ) external returns (uint256);

  /**
   * @notice Sells bonds at optimal rates given current order book state
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IGovernanceActions {
  event OrderBookCreated(bytes32 borrowerHash);

  ///@dev Check if a borrower is set as active on the Pool
  function isOrderBookActive(bytes32 borrower) external view returns (bool);

  /// @dev Add a new borrower to the Pool
  /// The calling address must have GOVERNANCE_ROLE role
  function createNewOrderbook(
    string calldata borrower,
    address underlyingToken,
    uint256 minRate,
    uint256 maxRate,
    uint256 rateSpacing,
    uint256 maxTokenDeposit,
    uint256 loanDuration,
    uint256 cooldownPeriod
  ) external;

  /// @dev Allow a new addres for the target borrower
  /// The calling address must have GOVERNANCE_ROLE role, and be BORROWER_ROLE role admin
  function allow(address borrowerAddress, string calldata borrower) external;

  /// @dev Disallow a new addres for the target borrower
  /// The calling address must have GOVERNANCE_ROLE role, and be BORROWER_ROLE role admin
  function disallow(address borrowerAddress, string calldata borrower) external;

  /// @dev Set the minimum interest rate for the target borrower's order book
  function setMinRate(uint256 minRate, bytes32 borrower) external;

  /// @dev Set the maximum interest rate for the target borrower's order book
  function setMaxRate(uint256 maxRate, bytes32 borrower) external;

  /// @dev Set the maximum amount of tokens that can be deposited in the target borrower's pool
  function setMaxTokenDeposit(uint256 maxTokenDeposit, bytes32 borrower) external;

  /// @dev Set the order book cooldown period
  function setCooldownPeriod(uint256 cooldownPeriod, bytes32 borrower) external;

  /// @dev Freeze all actions for users
  function freezePool() external;

  /// @dev Unfreeze all frozen actions
  function unfreezePool() external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

library Errors {
  // *** Contract Specific Errors ***
  // BorrowPool
  string public constant BP_UNMATCHED_TOKEN = "1"; // "Token/Asset provided does not match the underlying token of the order book";
  string public constant BP_OUT_OF_BOUND_MIN_RATE = "2"; // "Rate provided is lower than minimum rate of the order book"
  string public constant BP_OUT_OF_BOUND_MAX_RATE = "3"; // "Rate provided is greater than maximum rate of the order book"
  string public constant BP_RATE_SPACING = "4"; // "Decimals of rate provided do not comply with rate spacing of the order book"
  string public constant BP_DEPOSIT_MAX_TOKEN_DEPOSIT_EXCEEDED = "5"; // "Amount provided is too big, exceeding order book's capacity"
  string public constant BP_YIELD_PROVIDER_APPROVAL_FOR_TOKEN = "6"; // "An error occurred during yield provider approval for underlying token";
  string public constant BP_TOKEN_TRANSFER_FROM_LENDER = "7"; // "An error occurred during the transfer of the underlying token from lender to JellyFi BorrowPool";
  string public constant BP_WITHDRAW_NO_MATCH_FOR_BOND_RESALE = "8"; // "There is no match for bonds resale, the lender cannot withdraw their loaned position";
  string public constant BP_RATE_UPDATE_POSITION_BORROWED = "9"; // "Users cannot update the rate of a position that is already borrowed";
  string public constant BP_BORROW_OUT_OF_BOUND_AMOUNT = "10"; // "Amount provided is greater than available amount, action cannot be performed";
  string public constant BP_BORROW_MATURITY_EXPIRED = "11"; // "Maturity has expired, action cannot be performed";
  string public constant BP_REPAY_NO_ACTIVE_LOAN = "12"; // "No active loan to be repaid, action cannot be performed";
  string public constant BP_NO_BONDS_FOR_RESELL = "24"; // "Sender has no bonds to resell";
  string public constant BP_NOT_ENOUGH_DEPOSIT_FOR_BUY_BACK = "25"; // "Target tick has not enough deposit to buy bonds back";
  string public constant BP_WITHDRAW_UNMATCHED_POSITION = "26"; // "Withdraw to exit an unmateched position";
  string public constant BP_BORROW_UNSUFFICIENT_BORROWABLE_AMOUNT_WITHIN_BRACKETS = "27"; // "Amount provided is greater than available amount within min rate and max rate brackets";
  string public constant BP_REMAINING_DEPOSIT_IN_TICK = "28"; // "Remaining deposit";
  string public constant BP_NO_DEPOSIT_TO_WITHDRAW = "29"; // "Deposited amount non-borrowed equals to zero";
  string public constant BP_TOKEN_TRANSFER_FROM_BORROWER = "30"; // "An error occurred during the transfer of the underlying token from borrower to JellyFi BorrowPool";
  string public constant BP_REPAY_AT_MATURITY_ONLY = "31"; // "Maturity has not been reached yet, action cannot be performed";
  string public constant BP_BORROW_COOLDOWN_PERIOD_NOT_OVER = "32"; // "Cooldown period after a repayment is not over";

  // PoolSettingsManager
  string public constant PSM_ORDERBOOK_NOT_ACTIVE = "13"; // "Order Book for targeted borrower is not active";
  string public constant PSM_ORDERBOOK_ALREADY_SET_FOR_BORROWER = "14"; // "Targeted borrower is already set for another order book";
  string public constant PSM_ORDERBOOK_TOKEN_NOT_SUPPORTED = "15"; // "Underlying token is not supported by the yield provider";
  string public constant PSM_DISALLOW_UNMATCHED_BORROWER = "16"; // "Revoking the wrong borrower as the provided borrower does not match the provided address";
  string public constant PSM_OUT_OF_BOUND_MIN_RATE = "17"; // "Min Rate must be lower than Max Rate ";
  string public constant PSM_OUT_OF_BOUND_MAX_RATE = "18"; // "Max Rate must be greater than Min Rate ";
  string public constant PSM_RATE_SPACING_TIMING_ISSUE_LOAN = "19"; // "A loan already exist, setting rate spacing afterwards might block the pool, action is denied";
  string public constant PSM_RATE_SPACING_TIMING_ISSUE_DEPOSIT = "24"; // "A deposit has been already made, setting rate spacing afterwards might break the pool, action is denied";
  string public constant PSM_RATE_SPACING_COMPLIANCE = "25"; // "Provided rate must be compliant with rate spacing";
  // Position
  string public constant POS_MGMT_ONLY_OWNER = "20"; // "Only the owner of the position token can manage it (update rate, withdraw)";

  //*** Library Specific Errors ***
  // OrderBookLogic
  // WadRayMath
  string public constant MATH_MULTIPLICATION_OVERFLOW = "21";
  string public constant MATH_ADDITION_OVERFLOW = "22";
  string public constant MATH_DIVISION_BY_ZERO = "23";
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import {Rounding} from "./Rounding.sol";
import {WadRayMath} from "./WadRayMath.sol";

import "./Types.sol";
import "./Errors.sol";
import "../extensions/AaveILendingPool.sol";

library OrderBookLogic {
  using OrderBookLogic for Types.Pool;
  using Rounding for uint256;
  using WadRayMath for uint256;

  uint256 public constant SECONDS_PER_YEAR = 365 days;
  uint256 public constant ONE = 1e18; // WadRayMath.wad();

  /**
   * @dev Initiliazes the tick by setting all properties to an initial state
   * Called for a new deposit and rate update when the rate provided has no tick initialized yet
   * Depending on the rate provided, lowerInterestRate's value might be updated with the rate
   **/
  function initializeTick(Types.Pool storage orderBook, uint256 rate) internal {
    Types.Tick storage tick = orderBook.ticks[rate];
    // set base data for tick if not initialised
    if (tick.adjustedTotalAmount == 0) {
      tick.yieldProviderLiquidityRatio = orderBook
        .parameters
        .YIELD_PROVIDER
        .getReserveNormalizedIncome(address(orderBook.parameters.UNDERLYING_TOKEN))
        .rayToWad();
      tick.jellyFiLiquidityRatio = tick.yieldProviderLiquidityRatio;

      // update lowest interest rate to start iteration on future borrowings
      if ((orderBook.state.lowerInterestRate == 0) || (rate < orderBook.state.lowerInterestRate)) {
        orderBook.state.lowerInterestRate = rate;
      }
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
  ) internal returns (uint256) {
    Types.Tick storage tick = pool.ticks[rate];

    pool.updateLiquidityRatiosWithYieldProviderInterests(rate);

    uint256 adjustedAmount = normalizedAmount.wadDiv(tick.jellyFiLiquidityRatio);
    tick.adjustedTotalAmount += adjustedAmount;
    tick.adjustedRemainingAmount += adjustedAmount;
    pool.state.totalNormalizedDeposits += normalizedAmount;

    if (pool.state.lowerInterestRate > rate) {
      pool.state.lowerInterestRate = rate;
    }

    return adjustedAmount;
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

    if (tick.adjustedRemainingAmount.wadMul(tick.jellyFiLiquidityRatio) > normalizedRemainingAmount) {
      normalizedUsedAmount = normalizedRemainingAmount;
    } else {
      normalizedUsedAmount = tick.adjustedRemainingAmount.wadMul(tick.jellyFiLiquidityRatio).round();
    }
    uint256 bondsPurchasePrice = getTickBondPrice(rate, pool.parameters.LOAN_DURATION);
    bondsPurchasedQuantity = normalizedUsedAmount.wadDiv(bondsPurchasePrice).round();
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

    pool.updateLiquidityRatiosWithYieldProviderInterests(rate);

    // update global state for tick and order book
    tick.bondsQuantity += bondsIssuedQuantity;
    tick.adjustedRemainingAmount -= normalizedUsedAmountForPurchase.wadDiv(tick.jellyFiLiquidityRatio);
    pool.state.bondsIssuedQuantity += bondsIssuedQuantity;
    pool.state.totalNormalizedDeposits -= normalizedUsedAmountForPurchase;
  }

  /**
   * @dev Computes how the position is split between deposit and bonds
   * The deposited part will then be withdrawn from the yield provider
   * The bonds will have to be resold against the order book
   **/
  function computeWithdrawRepartitionForTick(
    Types.Pool storage pool,
    uint256 rate,
    uint256 adjustedAmount
  ) internal returns (uint256, uint256) {
    Types.Tick storage tick = pool.ticks[rate];

    pool.updateLiquidityRatiosWithYieldProviderInterests(rate);

    uint256 adjustedAmountUsedForBondsIssuance = adjustedAmount
      .wadMul(tick.adjustedTotalAmount - tick.adjustedRemainingAmount)
      .wadDiv(tick.adjustedTotalAmount);

    uint256 bondsQuantityToSell;
    if (tick.adjustedTotalAmount > tick.adjustedRemainingAmount) {
      bondsQuantityToSell = tick
        .bondsQuantity
        .wadMul(adjustedAmountUsedForBondsIssuance)
        .wadDiv(tick.adjustedTotalAmount - tick.adjustedRemainingAmount)
        .round();
    }
    uint256 depositAmountToWithdraw = (adjustedAmount - adjustedAmountUsedForBondsIssuance).round();

    return (bondsQuantityToSell, depositAmountToWithdraw);
  }

  /**
   * @dev Updates tick data after a withdrawal consisting of only amount deposited to yield provider
   **/
  function withdrawDepositedAmountForTick(
    Types.Pool storage pool,
    uint256 rate,
    uint256 depositAmountToWithdraw
  ) internal returns (uint256) {
    Types.Tick storage tick = pool.ticks[rate];

    tick.adjustedTotalAmount = tick.adjustedTotalAmount.roundApproxSub(depositAmountToWithdraw);
    tick.adjustedRemainingAmount = tick.adjustedRemainingAmount.roundApproxSub(depositAmountToWithdraw);

    uint256 normalizedDepositedAmountToWithdraw = depositAmountToWithdraw.wadMul(tick.jellyFiLiquidityRatio);
    pool.state.totalNormalizedDeposits = pool.state.totalNormalizedDeposits.roundApproxSub(
      normalizedDepositedAmountToWithdraw
    );

    // update lowerInterestRate if necessary
    if ((rate == pool.state.lowerInterestRate) && tick.adjustedRemainingAmount == 0 && tick.bondsQuantity == 0) {
      uint256 nextRate = rate + pool.parameters.RATE_SPACING;
      while (
        (nextRate <= pool.parameters.MAX_RATE) &&
        (pool.ticks[nextRate].adjustedRemainingAmount == 0) &&
        (tick.bondsQuantity == 0)
      ) {
        nextRate += pool.parameters.RATE_SPACING;
      }
      if (nextRate > pool.parameters.MAX_RATE) {
        pool.state.lowerInterestRate = 0;
      } else {
        pool.state.lowerInterestRate = nextRate;
      }
    }

    return normalizedDepositedAmountToWithdraw;
  }

  /**
   * @dev Updates tick data after a repayment
   **/
  function repayForTick(Types.Pool storage pool, uint256 rate) internal {
    Types.Tick storage tick = pool.ticks[rate];

    if (tick.bondsQuantity > 0) {
      pool.updateLiquidityRatiosWithYieldProviderInterests(rate);

      uint256 adjustedRepaidAmount = tick.bondsQuantity.wadDiv(tick.jellyFiLiquidityRatio);
      tick.adjustedRemainingAmount += adjustedRepaidAmount;
      tick.adjustedTotalAmount += adjustedRepaidAmount;
      pool.state.totalNormalizedDeposits += tick.bondsQuantity;

      // update liquidity ratio with interests from bond repayment
      uint256 bondPaidInterests = tick.bondsQuantity - tick.normalizedLoanedAmount;
      tick.jellyFiLiquidityRatio += bondPaidInterests.wadDiv(tick.adjustedTotalAmount).round();

      // update orderbook bonds emitted
      pool.state.bondsIssuedQuantity = pool.state.bondsIssuedQuantity.roundApproxSub(tick.bondsQuantity);

      // reset tick loan data
      tick.bondsQuantity = 0;
    }
  }

  /**
   * @dev Includes last interests paid by yield provider into liquidity ratios
   * Aave liquidity ratio being in ray, a conversion to was is necessary
   * Updates global deposited amount in consequence
   **/
  function updateLiquidityRatiosWithYieldProviderInterests(Types.Pool storage orderBook, uint256 rate) internal {
    Types.Tick storage tick = orderBook.ticks[rate];

    uint256 newYieldProviderLiquidityRatio = orderBook
      .parameters
      .YIELD_PROVIDER
      .getReserveNormalizedIncome(address(orderBook.parameters.UNDERLYING_TOKEN))
      .rayToWad();
    uint256 yieldProviderLiquidityRatioIncrease = newYieldProviderLiquidityRatio - tick.yieldProviderLiquidityRatio;

    // update liquidity ratios in tick
    tick.jellyFiLiquidityRatio += yieldProviderLiquidityRatioIncrease;
    tick.yieldProviderLiquidityRatio = newYieldProviderLiquidityRatio;

    // global deposited amount
    orderBook.state.totalNormalizedDeposits += tick
      .adjustedRemainingAmount
      .wadMul(yieldProviderLiquidityRatioIncrease)
      .round();
  }

  function getTickBondPrice(uint256 rate, uint256 loanDuration) public pure returns (uint256) {
    uint256 taylor = ONE + (rate * loanDuration) / SECONDS_PER_YEAR;
    uint256 tickPrice = ONE.wadDiv(taylor);
    return tickPrice;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "./Errors.sol";

/**
 * @title Rounding library
 * @author JellyFi
 * @dev Rounding utilities to reduce precision loss when doing wad ray math operations
 **/

library Rounding {
  using Rounding for uint256;

  uint256 internal constant DEFAULT_PRECISION = 1e3;
  uint256 internal constant DEFAULT_THRESHOLD = 1e10;

  function approx(uint256 amount, uint256 target) internal pure returns (uint256) {
    if (amount - target < DEFAULT_THRESHOLD) {
      return target;
    }
    return amount;
  }

  function round(uint256 amount) internal pure returns (uint256) {
    return (amount / DEFAULT_PRECISION) * DEFAULT_PRECISION;
  }

  function roundApproxSub(uint256 base, uint256 sub) internal pure returns (uint256) {
    if (sub > base) {
      return (sub - base).round().approx(0);
    }
    return (base - sub).round().approx(0);
  }

  function approxSub(uint256 base, uint256 sub) internal pure returns (uint256) {
    if (sub > base) {
      return (sub - base).approx(0);
    }
    return (base - sub).approx(0);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "../extensions/AaveILendingPool.sol";

library Types {
  struct Tick {
    uint256 bondsQuantity;
    uint256 adjustedRemainingAmount;
    uint256 adjustedTotalAmount;
    uint256 normalizedLoanedAmount;
    uint256 yieldProviderLiquidityRatio;
    uint256 jellyFiLiquidityRatio;
  }

  struct PoolParameters {
    address UNDERLYING_TOKEN;
    ILendingPool YIELD_PROVIDER;
    uint256 MIN_RATE;
    uint256 MAX_RATE;
    uint256 RATE_SPACING;
    uint256 MAX_TOKEN_DEPOSIT;
    uint256 LOAN_DURATION;
    uint256 COOLDOWN_PERIOD;
  }

  struct PoolState {
    uint256 bondsIssuedQuantity;
    uint256 totalNormalizedDeposits;
    uint256 currentMaturity;
    uint256 lowerInterestRate;
    uint256 higherInterestRate;
    uint256 nextLoanMinStart;
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