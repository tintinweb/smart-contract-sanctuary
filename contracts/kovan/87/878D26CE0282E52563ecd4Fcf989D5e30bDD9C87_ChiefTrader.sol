// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
// OpenZeppelin Contracts v4.4.0 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
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
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: None MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";

interface IDefaultAccessControl is IAccessControlEnumerable {
    /// @notice Checks that the address is contract admin.
    /// @param who Address to check
    /// @return `true` if who is admin, `false` otherwise
    function isAdmin(address who) external view returns (bool);
}

// SPDX-License-Identifier: None MIT
pragma solidity 0.8.9;

import "./IDefaultAccessControl.sol";

interface IProtocolGovernance is IDefaultAccessControl {
    /// @notice CommonLibrary protocol params.
    /// @param permissionless If `true` anyone can spawn vaults, o/w only Protocol Governance Admin
    /// @param maxTokensPerVault Max different token addresses that could be managed by the protocol
    /// @param governanceDelay The delay (in secs) that must pass before setting new pending params to commiting them
    /// @param protocolTreasury Protocol treasury address for collecting management fees
    struct Params {
        bool permissionless;
        uint256 maxTokensPerVault;
        uint256 governanceDelay;
        address protocolTreasury;
    }

    // -------------------  PUBLIC, VIEW  -------------------

    /// @notice Addresses allowed to claim liquidity mining rewards from.
    function claimAllowlist() external view returns (address[] memory);

    /// @notice Pending addresses to be added to claimAllowlist.
    function pendingClaimAllowlistAdd() external view returns (address[] memory);

    /// @notice Addresses of tokens allowed for vaults.
    function tokenWhitelist() external view returns (address[] memory);

    /// @notice Pending addresses to be added to tokenWhitelist.
    function pendingTokenWhitelistAdd() external view returns (address[] memory);

    /// @notice Addresses allowed to claim liquidity mining rewards from.
    function vaultGovernances() external view returns (address[] memory);

    /// @notice Pending addresses to be added to vaultGovernances.
    function pendingVaultGovernancesAdd() external view returns (address[] memory);

    /// @notice Check if address is allowed to claim.
    function isAllowedToClaim(address addr) external view returns (bool);

    /// @notice Check if address is an allowed (whitelisted) token.
    function isAllowedToken(address addr) external view returns (bool);

    /// @notice Check if address has ever been allowed (whitelisted) token.
    function isEverAllowedToken(address addr) external view returns (bool);

    /// @notice Check if address is a registered vault governance.
    function isVaultGovernance(address addr) external view returns (bool);

    /// @notice If `false` only admins can deploy new vaults, o/w anyone can deploy a new vault.
    function permissionless() external view returns (bool);

    /// @notice Max different ERC20 token addresses that could be managed by the protocol.
    function maxTokensPerVault() external view returns (uint256);

    /// @notice The delay for committing any governance params.
    function governanceDelay() external view returns (uint256);

    /// @notice The address of the protocol treasury.
    function protocolTreasury() external view returns (address);

    // -------------------  PUBLIC, MUTATING, GOVERNANCE, DELAY  -------------------

    /// @notice Set new pending params.
    /// @param newParams newParams to set
    function setPendingParams(Params memory newParams) external;

    /// @notice Stage addresses for claim allow list.
    /// @param addresses Addresses to add
    function setPendingClaimAllowlistAdd(address[] calldata addresses) external;

    /// @notice Stage addresses for token whitelist.
    /// @param addresses Addresses to add
    function setPendingTokenWhitelistAdd(address[] calldata addresses) external;

    /// @notice Stage addresses for vault governances.
    /// @param addresses Addresses to add
    function setPendingVaultGovernancesAdd(address[] calldata addresses) external;

    // -------------------  PUBLIC, MUTATING, GOVERNANCE, IMMEDIATE  -------------------

    /// @notice Commit pending params.
    function commitParams() external;

    /// @notice Commit pending ClaimAllowlistAdd params.
    function commitClaimAllowlistAdd() external;

    /// @notice Commit pending tokenWhitelistAdd params.
    function commitTokenWhitelistAdd() external;

    /// @notice Commit pending VaultGovernancesAdd params.
    function commitVaultGovernancesAdd() external;

    /// @notice Remove from claim allow list immediately.
    function removeFromClaimAllowlist(address addr) external;

    /// @notice Remove from token whitelist immediately.
    function removeFromTokenWhitelist(address addr) external;

    /// @notice Remove from vault governances immediately.
    function removeFromVaultGovernances(address addr) external;
}

// SPDX-License-Identifier: None
pragma solidity =0.8.9;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../interfaces/IProtocolGovernance.sol";
import "./interfaces/ITrader.sol";
import "./interfaces/IChiefTrader.sol";
import "./libraries/TraderExceptionsLibrary.sol";

/// @notice Main contract that allows trading of ERC20 tokens on different Dexes
/// @dev This contract contains several subtraders that can be used for trading ERC20 tokens.
/// Examples of subtraders are UniswapV3, UniswapV2, SushiSwap, Curve, etc.
contract ChiefTrader is ERC165, IChiefTrader, ITrader {
    IProtocolGovernance public immutable protocolGovernance;
    address[] internal _traders;
    mapping(address => bool) public addedTraders;

    constructor(address _protocolGovernance) {
        protocolGovernance = IProtocolGovernance(_protocolGovernance);
    }

    /// @inheritdoc IChiefTrader
    function tradersCount() external view returns (uint256) {
        return _traders.length;
    }

    /// @inheritdoc IChiefTrader
    function getTrader(uint256 _index) external view returns (address) {
        return _traders[_index];
    }

    /// @inheritdoc IChiefTrader
    function traders() external view returns (address[] memory) {
        return _traders;
    }

    /// @inheritdoc IChiefTrader
    function addTrader(address traderAddress) external {
        _requireProtocolAdmin();
        require(traderAddress != address(this), TraderExceptionsLibrary.RECURRENCE_EXCEPTION);
        require(!addedTraders[traderAddress], TraderExceptionsLibrary.TRADER_ALREADY_REGISTERED_EXCEPTION);
        require(ERC165(traderAddress).supportsInterface(type(ITrader).interfaceId));
        require(!ERC165(traderAddress).supportsInterface(type(IChiefTrader).interfaceId));
        _traders.push(traderAddress);
        addedTraders[traderAddress] = true;
        emit AddedTrader(_traders.length - 1, traderAddress);
    }

    /// @inheritdoc ITrader
    function swapExactInput(
        uint256 traderId,
        uint256 amount,
        address,
        PathItem[] calldata path,
        bytes calldata options
    ) external returns (uint256) {
        require(traderId < _traders.length, TraderExceptionsLibrary.TRADER_NOT_FOUND_EXCEPTION);
        _requireAllowedTokens(path);
        address traderAddress = _traders[traderId];
        address recipient = msg.sender;
        return ITrader(traderAddress).swapExactInput(0, amount, recipient, path, options);
    }

    /// @inheritdoc ITrader
    function swapExactOutput(
        uint256 traderId,
        uint256 amount,
        address,
        PathItem[] calldata path,
        bytes calldata options
    ) external returns (uint256) {
        require(traderId < _traders.length, TraderExceptionsLibrary.TRADER_NOT_FOUND_EXCEPTION);
        _requireAllowedTokens(path);
        address traderAddress = _traders[traderId];
        address recipient = msg.sender;
        return ITrader(traderAddress).swapExactOutput(0, amount, recipient, path, options);
    }

    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return (interfaceId == this.supportsInterface.selector ||
            interfaceId == type(ITrader).interfaceId ||
            interfaceId == type(IChiefTrader).interfaceId);
    }

    function _requireAllowedTokens(PathItem[] memory path) internal view {
        IProtocolGovernance pg = protocolGovernance;
        for (uint256 i = 1; i < path.length; ++i)
            require(
                pg.isAllowedToken(path[i].token0) && pg.isAllowedToken(path[i].token1),
                TraderExceptionsLibrary.TOKEN_NOT_ALLOWED_EXCEPTION
            );
        if (path.length > 0)
            require(pg.isAllowedToken(path[0].token1), TraderExceptionsLibrary.TOKEN_NOT_ALLOWED_EXCEPTION);
    }

    function _requireProtocolAdmin() internal view {
        require(protocolGovernance.isAdmin(msg.sender), TraderExceptionsLibrary.PROTOCOL_ADMIN_REQUIRED_EXCEPTION);
    }

    event AddedTrader(uint256 indexed traderId, address traderAddress);
}

// SPDX-License-Identifier: None MIT

pragma solidity =0.8.9;

import "../../interfaces/IProtocolGovernance.sol";

interface IChiefTrader {
    /// @notice ProtocolGovernance
    /// @return the address of the protocol governance contract
    function protocolGovernance() external view returns (IProtocolGovernance);

    /// @notice Count of traders
    function tradersCount() external view returns (uint256);

    /// @notice Get the address of the trader at index
    /// @param _index The index of the trader
    function getTrader(uint256 _index) external view returns (address);

    /// @notice Get all registered traders
    function traders() external view returns (address[] memory);

    /// @notice Add new trader
    /// @param traderAddress the address of the trader
    function addTrader(address traderAddress) external;
}

// SPDX-License-Identifier: None MIT
pragma solidity =0.8.9;

// When trading from a smart contract, the most important thing to keep in mind is that
// access to an external price source is required. Without this, trades can be frontrun for considerable loss.

interface ITrader {
    /// @notice Trade path element
    /// @param token0 The token to be sold
    /// @param token1 The token to be bought
    /// @param options Protocol-specific options
    struct PathItem {
        address token0;
        address token1;
        bytes options;
    }

    /// @notice Swap exact amount of input tokens for output tokens
    /// @param traderId Trader ID (used only by Chief trader)
    /// @param amount Amount of the input tokens to spend
    /// @param recipient Address of the recipient (not used by Chief trader)
    /// @param path Trade path PathItem[]
    /// @param options Protocol-speceific options
    /// @return amountOut Amount of the output tokens received
    function swapExactInput(
        uint256 traderId,
        uint256 amount,
        address recipient,
        PathItem[] memory path,
        bytes memory options
    ) external returns (uint256 amountOut);

    /// @notice Swap exact amount of input tokens for output tokens
    /// @param traderId Trader ID (used only by Chief trader)
    /// @param amount Amount of the output tokens to receive
    /// @param recipient Address of the recipient (not used by Chief trader)
    /// @param path Trade path PathItem[]
    /// @param options Protocol-speceific options
    /// @return amountIn of the input tokens spent
    function swapExactOutput(
        uint256 traderId,
        uint256 amount,
        address recipient,
        PathItem[] memory path,
        bytes memory options
    ) external returns (uint256 amountIn);
}

// SPDX-License-Identifier: None
pragma solidity =0.8.9;

library TraderExceptionsLibrary {
    string constant PROTOCOL_ADMIN_REQUIRED_EXCEPTION = "PA";
    string constant TRADER_ALREADY_REGISTERED_EXCEPTION = "TE";
    string constant TRADER_NOT_FOUND_EXCEPTION = "UT";
    string constant TRADE_FAILED_EXCEPTION = "TF";
    string constant VAULT_NOT_FOUND_EXCEPTION = "VF";
    string constant VAULT_TOKEN_REQUIRED_EXCEPTION = "VT";
    string constant AT_LEAST_STRATEGY_REQUIRED_EXCEPTION = "SR";
    string constant INVALID_TRADE_PATH_EXCEPTION = "TP";
    string constant RECURRENCE_EXCEPTION = "RE";
    string constant TOKEN_NOT_ALLOWED_EXCEPTION = "TA";
}