// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./libraries/Common.sol";

import "./interfaces/IProtocolGovernance.sol";
import "./interfaces/ILpIssuerGovernance.sol";
import "./interfaces/ILpIssuer.sol";
import "./VaultGovernance.sol";

/// @notice Governance that manages all Lp Issuers params and can deploy a new LpIssuer Vault.
contract LpIssuerGovernance is ILpIssuerGovernance, VaultGovernance {
    /// @notice Creates a new contract.
    /// @param internalParams_ Initial Internal Params
    constructor(InternalParams memory internalParams_) VaultGovernance(internalParams_) {}

    /// @inheritdoc IVaultGovernance
    function strategyTreasury(uint256) external pure override(IVaultGovernance, VaultGovernance) returns (address) {
        return address(0);
    }

    /// @notice Strategy Params, i.e. Params that could be changed by Strategy or Protocol Governance immediately.
    /// @param nft Nft of the vault
    function strategyParams(uint256 nft) external view returns (StrategyParams memory) {
        if (_strategyParams[nft].length == 0) {
            return StrategyParams({tokenLimitPerAddress: 0});
        }
        return abi.decode(_strategyParams[nft], (StrategyParams));
    }

    /// @notice Stage Strategy Params.
    /// @param nft Nft of the vault
    /// @param params New params
    function setDelayedStrategyParams(uint256 nft, StrategyParams calldata params) external {
        _stageDelayedStrategyParams(nft, abi.encode(params));
        emit SetStrategyParams(tx.origin, msg.sender, nft, params);
    }

    function setStrategyParams(uint256 nft, StrategyParams calldata params) external {
        _setStrategyParams(nft, abi.encode(params));
    }

    /// @notice Deploy a new vault.
    /// @param vaultTokens ERC20 tokens under vault management
    /// @param options Abi encoded uint256 - an nfts of the gateway subvault. It is required that nft subvault is approved by the caller to this address and that it is a gateway vault
    /// @return vault Address of the new vault
    /// @return nft Nft of the vault in the vault registry
    function deployVault(
        address[] memory vaultTokens,
        bytes memory options,
        address
    ) public override(VaultGovernance, IVaultGovernance) returns (IVault vault, uint256 nft) {
        (uint256 subvaultNft, string memory name, string memory symbol) = abi.decode(
            options,
            (uint256, string, string)
        );
        (vault, nft) = super.deployVault(vaultTokens, abi.encode(name, symbol), msg.sender);
        // TODO - add IERC165 check of the subvault interface == gateway vault interface
        IVaultRegistry registry = _internalParams.registry;
        ILpIssuer(address(vault)).addSubvault(subvaultNft);
        registry.transferFrom(msg.sender, address(vault), subvaultNft);
    }

    /// @notice Emitted when new StrategyParams are set.
    /// @param origin Origin of the transaction
    /// @param sender Sender of the transaction
    /// @param nft VaultRegistry NFT of the vault
    /// @param params New params that are set
    event SetStrategyParams(address indexed origin, address indexed sender, uint256 indexed nft, StrategyParams params);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/IProtocolGovernance.sol";
import "./interfaces/IVaultGovernance.sol";

/// @notice Internal contract for managing different params.
/// @dev The contract should be overriden by the concrete VaultGovernance,
/// define different params structs and use abi.decode / abi.encode to serialize
/// to bytes in this contract. It also should emit events on params change.
abstract contract VaultGovernance is IVaultGovernance {
    InternalParams internal _internalParams;
    InternalParams private _stagedInternalParams;
    uint256 internal _internalParamsTimestamp;

    mapping(uint256 => bytes) internal _delayedStrategyParams;
    mapping(uint256 => bytes) internal _stagedDelayedStrategyParams;
    mapping(uint256 => uint256) internal _delayedStrategyParamsTimestamp;

    bytes internal _delayedProtocolParams;
    bytes internal _stagedDelayedProtocolParams;
    uint256 internal _delayedProtocolParamsTimestamp;

    mapping(uint256 => bytes) internal _strategyParams;
    bytes internal _protocolParams;

    IVaultFactory public factory;
    bool public initialized;

    /// @notice Creates a new contract.
    /// @param internalParams_ Initial Internal Params
    constructor(InternalParams memory internalParams_) {
        _internalParams = internalParams_;
    }

    // -------------------  PUBLIC, VIEW  -------------------

    /// @inheritdoc IVaultGovernance
    function delayedStrategyParamsTimestamp(uint256 nft) external view returns (uint256) {
        return _delayedStrategyParamsTimestamp[nft];
    }

    /// @inheritdoc IVaultGovernance
    function delayedProtocolParamsTimestamp() external view returns (uint256) {
        return _delayedProtocolParamsTimestamp;
    }

    /// @inheritdoc IVaultGovernance
    function internalParamsTimestamp() external view returns (uint256) {
        return _internalParamsTimestamp;
    }

    /// @inheritdoc IVaultGovernance
    function internalParams() external view returns (InternalParams memory) {
        return _internalParams;
    }

    /// @inheritdoc IVaultGovernance
    function stagedInternalParams() external view returns (InternalParams memory) {
        return _stagedInternalParams;
    }

    /// @inheritdoc IVaultGovernance
    function strategyTreasury(uint256 nft) external view virtual returns (address);

    // -------------------  PUBLIC, MUTATING  -------------------

    /// @inheritdoc IVaultGovernance
    function initialize(IVaultFactory factory_) external {
        require(!initialized, "INIT");
        factory = factory_;
        initialized = true;
    }

    /// @inheritdoc IVaultGovernance
    function deployVault(
        address[] memory vaultTokens,
        bytes memory options,
        address owner
    ) public virtual returns (IVault vault, uint256 nft) {
        require(initialized, "INIT");
        IProtocolGovernance protocolGovernance = IProtocolGovernance(_internalParams.protocolGovernance);
        require(protocolGovernance.permissionless() || protocolGovernance.isAdmin(msg.sender), "POA");
        vault = factory.deployVault(vaultTokens, options);
        nft = _internalParams.registry.registerVault(address(vault), owner);
        vault.initialize(nft);
        emit DeployedVault(tx.origin, msg.sender, vaultTokens, options, owner, address(vault), nft);
    }

    /// @inheritdoc IVaultGovernance
    function stageInternalParams(InternalParams memory newParams) external {
        _requireProtocolAdmin();
        _stagedInternalParams = newParams;
        _internalParamsTimestamp = block.timestamp + _internalParams.protocolGovernance.governanceDelay();
        emit StagedInternalParams(tx.origin, msg.sender, newParams, _internalParamsTimestamp);
    }

    /// @inheritdoc IVaultGovernance
    function commitInternalParams() external {
        _requireProtocolAdmin();
        require(_internalParamsTimestamp > 0, "NULL");
        require(block.timestamp >= _internalParamsTimestamp, "TS");
        _internalParams = _stagedInternalParams;
        delete _internalParamsTimestamp;
        emit CommitedInternalParams(tx.origin, msg.sender, _internalParams);
    }

    // -------------------  INTERNAL  -------------------

    /// @notice Set Delayed Strategy Params
    /// @param nft Nft of the vault
    /// @param params New params
    function _stageDelayedStrategyParams(uint256 nft, bytes memory params) internal {
        _requireAtLeastStrategy(nft);
        _stagedDelayedStrategyParams[nft] = params;
        uint256 delayFactor = _delayedStrategyParams[nft].length == 0 ? 0 : 1;
        _delayedStrategyParamsTimestamp[nft] =
            block.timestamp +
            _internalParams.protocolGovernance.governanceDelay() *
            delayFactor;
    }

    /// @notice Commit Delayed Strategy Params
    function _commitDelayedStrategyParams(uint256 nft) internal {
        _requireAtLeastStrategy(nft);
        require(_delayedStrategyParamsTimestamp[nft] > 0, "NULL");
        require(block.timestamp >= _delayedStrategyParamsTimestamp[nft], "TS");
        _delayedStrategyParams[nft] = _stagedDelayedStrategyParams[nft];
        delete _delayedStrategyParamsTimestamp[nft];
    }

    /// @notice Set Delayed Protocol Params
    /// @param params New params
    function _stageDelayedProtocolParams(bytes memory params) internal {
        _requireProtocolAdmin();
        uint256 delayFactor = _delayedProtocolParams.length == 0 ? 0 : 1;
        _stagedDelayedProtocolParams = params;
        _delayedProtocolParamsTimestamp =
            block.timestamp +
            _internalParams.protocolGovernance.governanceDelay() *
            delayFactor;
    }

    /// @notice Commit Delayed Protocol Params
    function _commitDelayedProtocolParams() internal {
        _requireProtocolAdmin();
        require(_delayedProtocolParamsTimestamp > 0, "NULL");
        require(block.timestamp >= _delayedProtocolParamsTimestamp, "TS");
        _delayedProtocolParams = _stagedDelayedProtocolParams;
        delete _delayedProtocolParamsTimestamp;
    }

    /// @notice Set immediate strategy params
    /// @dev Should require nft > 0
    /// @param nft Nft of the vault
    /// @param params New params
    function _setStrategyParams(uint256 nft, bytes memory params) internal {
        _requireAtLeastStrategy(nft);
        _strategyParams[nft] = params;
    }

    /// @notice Set immediate protocol params
    /// @param params New params
    function _setProtocolParams(bytes memory params) internal {
        _requireProtocolAdmin();
        _protocolParams = params;
    }

    function _requireAtLeastStrategy(uint256 nft) internal view {
        require(
            (_internalParams.protocolGovernance.isAdmin(msg.sender) ||
                _internalParams.registry.getApproved(nft) == msg.sender),
            "RST"
        );
    }

    function _requireProtocolAdmin() internal view {
        require(_internalParams.protocolGovernance.isAdmin(msg.sender), "ADM");
    }

    /// @notice Emitted when InternalParams are staged for commit
    /// @param origin Origin of the transaction
    /// @param sender Sender of the transaction
    /// @param params New params that were staged for commit
    /// @param when When the params could be committed
    event StagedInternalParams(address indexed origin, address indexed sender, InternalParams params, uint256 when);

    /// @notice Emitted when InternalParams are staged for commit
    /// @param origin Origin of the transaction
    /// @param sender Sender of the transaction
    /// @param params New params that were staged for commit
    event CommitedInternalParams(address indexed origin, address indexed sender, InternalParams params);

    /// @notice Emitted when New Vault is deployed
    /// @param origin Origin of the transaction
    /// @param sender Sender of the transaction
    /// @param vaultTokens Vault tokens for this vault
    /// @param options Options for deploy. The details of the options structure are specified in subcontracts
    /// @param owner Owner of the VaultRegistry NFT for this vault
    /// @param vaultAddress Address of the new Vault
    /// @param vaultNft VaultRegistry NFT for the new Vault
    event DeployedVault(
        address indexed origin,
        address indexed sender,
        address[] vaultTokens,
        bytes options,
        address owner,
        address vaultAddress,
        uint256 vaultNft
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";

interface IDefaultAccessControl is IAccessControlEnumerable {
    /// @notice Checks that the address is contract admin.
    /// @param who Address to check
    /// @return `true` if who is admin, `false` otherwise
    function isAdmin(address who) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IVault.sol";

interface ILpIssuer {
    /// @notice VaultRegistry NFT for this vault
    function nft() external view returns (uint256);

    /// @notice Nft of the underlying vault.
    function subvaultNft() external view returns (uint256);

    /// @notice Adds subvault nft to the vault.
    /// @dev Can be called only once.
    /// @param nft Subvault nft to add
    function addSubvault(uint256 nft) external;

    /// @notice Initialize contract with vault nft
    /// @param nft VaultRegistry NFT for this vault
    function initialize(uint256 nft) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IVaultGovernance.sol";

interface ILpIssuerGovernance is IVaultGovernance {
    /// @notice Params that could be changed by Strategy or Protocol Governance with Protocol Governance delay.
    /// @param tokenLimitPerAddress Reference to address that will collect strategy fees
    struct StrategyParams {
        uint256 tokenLimitPerAddress;
    }

    /// @notice Strategy Params.
    /// @param nft VaultRegistry NFT of the vault
    function strategyParams(uint256 nft) external view returns (StrategyParams memory);

    /// @notice Set Strategy params, i.e. Params that could be changed by Strategy or Protocol Governance immediately.
    /// @param nft Nft of the vault
    /// @param params New params
    function setStrategyParams(uint256 nft, StrategyParams calldata params) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IDefaultAccessControl.sol";
import "./IVaultRegistry.sol";

interface IProtocolGovernance is IDefaultAccessControl {
    /// @notice Common protocol params.
    /// @param permissionless If `true` anyone can spawn vaults, o/w only Protocol Governance Admin
    /// @param maxTokensPerVault Max different token addresses that could be managed by the protocol
    /// @param governanceDelay The delay (in secs) that must pass before setting new pending params to commiting them
    struct Params {
        bool permissionless;
        uint256 maxTokensPerVault;
        uint256 governanceDelay;
    }

    // -------------------  PUBLIC, VIEW  -------------------

    /// @notice Addresses allowed to claim liquidity mining rewards from.
    function claimAllowlist() external view returns (address[] memory);

    /// @notice Pending addresses to be added to claimAllowlist.
    function pendingClaimAllowlistAdd() external view returns (address[] memory);

    /// @notice Addresses allowed to claim liquidity mining rewards from.
    function vaultGovernances() external view returns (address[] memory);

    /// @notice Pending addresses to be added to vaultGovernances.
    function pendingVaultGovernancesAdd() external view returns (address[] memory);

    /// @notice Check if address is allowed to claim.
    function isAllowedToClaim(address addr) external view returns (bool);

    /// @notice Check if address is a registered vault governance.
    function isVaultGovernance(address addr) external view returns (bool);

    /// @notice If `false` only admins can deploy new vaults, o/w anyone can deploy a new vault.
    function permissionless() external view returns (bool);

    /// @notice Max different ERC20 token addresses that could be managed by the protocol.
    function maxTokensPerVault() external view returns (uint256);

    /// @notice The delay for committing any governance params.
    function governanceDelay() external view returns (uint256);

    // -------------------  PUBLIC, MUTATING, GOVERNANCE, DELAY  -------------------

    /// @notice Set new pending params.
    /// @param newParams newParams to set
    function setPendingParams(Params memory newParams) external;

    /// @notice Stage addresses for claim allow list.
    /// @param addresses Addresses to add
    function setPendingClaimAllowlistAdd(address[] calldata addresses) external;

    /// @notice Stage addresses for vault governances.
    /// @param addresses Addresses to add
    function setPendingVaultGovernancesAdd(address[] calldata addresses) external;

    // -------------------  PUBLIC, MUTATING, GOVERNANCE, IMMEDIATE  -------------------

    /// @notice Commit pending params.
    function commitParams() external;

    /// @notice Commit pending ClaimAllowlistAdd params.
    function commitClaimAllowlistAdd() external;

    /// @notice Commit pending VaultGovernancesAdd params.
    function commitVaultGovernancesAdd() external;

    /// @notice Remove from claim allow list immediately.
    function removeFromClaimAllowlist(address addr) external;

    /// @notice Remove from vault governances immediately.
    function removeFromVaultGovernances(address addr) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IVaultGovernance.sol";

interface IVault {
    /// @notice VaultRegistry NFT for this vault
    function nft() external view returns (uint256);

    /// @notice Address of the Vault Governance for this contract.
    function vaultGovernance() external view returns (IVaultGovernance);

    /// @notice ERC20 tokens under Vault management.
    function vaultTokens() external view returns (address[] memory);

    /// @notice Total value locked for this contract.
    /// @dev Generally it is the underlying token value of this contract in some
    /// other DeFi protocol. For example, for USDC Yearn Vault this would be total USDC balance that could be withdrawn for Yearn to this contract.
    /// @return tokenAmounts Total available balances for multiple tokens (nth tokenAmount corresponds to nth token in vaultTokens)
    function tvl() external view returns (uint256[] memory tokenAmounts);

    /// @notice Initialize contract with vault nft
    /// @param nft VaultRegistry NFT for this vault
    function initialize(uint256 nft) external;

    /// @notice Pushes tokens on the vault balance to the underlying protocol. For example, for Yearn this operation will take USDC from
    /// the contract balance and convert it to yUSDC.
    /// @dev Can only be called but Vault Owner or Strategy. Vault owner is the owner of NFT for this vault in VaultManager.
    /// Strategy is approved address for the vault NFT.
    ///
    /// Tokens **must** be a subset of Vault Tokens. However, the convention is that if tokenAmount == 0 it is the same as token is missing.
    ///
    /// Also notice that this operation doesn't guarantee that tokenAmounts will be invested in full.
    /// @param tokens Tokens to push
    /// @param tokenAmounts Amounts of tokens to push
    /// @param options Additional options that could be needed for some vaults. E.g. for Uniswap this could be `deadline` param. For the exact bytes structure see concrete vault descriptions
    /// @return actualTokenAmounts The amounts actually invested. It could be less than tokenAmounts (but not higher)
    function push(
        address[] memory tokens,
        uint256[] memory tokenAmounts,
        bytes memory options
    ) external returns (uint256[] memory actualTokenAmounts);

    /// @notice The same as `push` method above but transfers tokens to vault balance prior to calling push.
    /// After the `push` it returns all the leftover tokens back (`push` method doesn't guarantee that tokenAmounts will be invested in full).
    /// @param tokens Tokens to push
    /// @param tokenAmounts Amounts of tokens to push
    /// @param options Additional options that could be needed for some vaults. E.g. for Uniswap this could be `deadline` param. For the exact bytes structure see concrete vault descriptions
    /// @return actualTokenAmounts The amounts actually invested. It could be less than tokenAmounts (but not higher)
    function transferAndPush(
        address from,
        address[] memory tokens,
        uint256[] memory tokenAmounts,
        bytes memory options
    ) external returns (uint256[] memory actualTokenAmounts);

    /// @notice Pulls tokens from the underlying protocol to the `to` address.
    /// For example, for Yearn this operation will take yUSDC from
    /// the Yearn protocol, convert it to USDC and send to `to` address.
    /// @dev Can only be called but Vault Owner or Strategy. Vault owner is the owner of NFT for this vault in VaultManager.
    /// Strategy is approved address for the vault NFT. There's a subtle difference however - while vault owner
    /// can pull the tokens to any address, Strategy can only pull to other vault in the Vault System (a set of vaults united by the Gateway Vault)
    ///
    /// Tokens **must** be a subset of Vault Tokens. However, the convention is that if tokenAmount == 0 it is the same as token is missing.
    ///
    /// Also notice that this operation doesn't guarantee that tokenAmounts will be invested in full.
    /// @param to Address to receive the tokens
    /// @param tokens Tokens to pull
    /// @param tokenAmounts Amounts of tokens to pull
    /// @param options Additional options that could be needed for some vaults. E.g. for Uniswap this could be `deadline` param. For the exact bytes structure see concrete vault descriptions
    /// @return actualTokenAmounts The amounts actually withdrawn. It could be less than tokenAmounts (but not higher)
    function pull(
        address to,
        address[] memory tokens,
        uint256[] memory tokenAmounts,
        bytes memory options
    ) external returns (uint256[] memory actualTokenAmounts);

    /// @notice This method is for claiming accidentally accumulated tokens on the contact's balance.
    /// @dev Can only be called by Protocol Governance.
    /// @param to Address that will receive the tokens
    /// @param tokens Tokens to claim. Each token must be other than those in vaultTokens
    function reclaimTokens(address to, address[] memory tokens) external;

    /// @notice Claim liquidity mining rewards.
    /// @dev Can only be called by Vault Owner or Strategy. Vault owner is the owner of NFT for this vault in VaultManager.
    /// Strategy is approved address for the vault NFT.
    ///
    /// Since this method allows sending arbitrary transactions, the destinations of the calls
    /// are whitelisted by Protocol Governance.
    /// @param from Address of the reward pool
    /// @param data Abi encoded call to the `from` address
    function claimRewards(address from, bytes memory data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IVaultGovernance.sol";
import "./IVault.sol";

interface IVaultFactory {
    /// @notice Deploy a new vault.
    /// @param vaultTokens ERC20 tokens under vault management
    /// @param options Reserved additional deploy options. Should be 0x0
    function deployVault(address[] memory vaultTokens, bytes memory options) external returns (IVault vault);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IProtocolGovernance.sol";
import "./IVaultRegistry.sol";
import "./IVaultFactory.sol";
import "./IVault.sol";

interface IVaultGovernance {
    /// @notice Internal references of the contract.
    /// @param protocolGovernance Reference to Protocol Governance
    /// @param registry Reference to Vault Registry
    struct InternalParams {
        IProtocolGovernance protocolGovernance;
        IVaultRegistry registry;
    }

    // -------------------  PUBLIC, VIEW  -------------------

    /// @notice Checks if contract is initialized.
    /// @dev Uninitialized contracts cannot deploy vaults
    function initialized() external view returns (bool);

    /// @notice Vault factory for this Vault Governance.
    function factory() external view returns (IVaultFactory);

    /// @notice Timestamp in unix time seconds after which staged Delayed Strategy Params could be committed.
    /// @param nft Nft of the vault
    function delayedStrategyParamsTimestamp(uint256 nft) external view returns (uint256);

    /// @notice Timestamp in unix time seconds after which staged Delayed Protocol Params could be committed.
    function delayedProtocolParamsTimestamp() external view returns (uint256);

    /// @notice Timestamp in unix time seconds after which staged Internal Params could be committed.
    function internalParamsTimestamp() external view returns (uint256);

    /// @notice Internal Params of the contract.
    function internalParams() external view returns (InternalParams memory);

    /// @notice Staged new Internal Params.
    /// @dev The Internal Params could be committed after internalParamsTimestamp
    function stagedInternalParams() external view returns (InternalParams memory);

    /// @notice Reference to Strategy Treasury address.
    /// @param nft Nft of the vault
    function strategyTreasury(uint256 nft) external view returns (address);

    // -------------------  PUBLIC, MUTATING  -------------------

    /// @notice Instantly initialize governance with factory.
    /// @dev Can only be called by initial deployer and only once.
    /// Required to be called before any function starts working.
    /// @param factory new factory
    function initialize(IVaultFactory factory) external;

    /// @notice Deploy a new vault.
    /// @param vaultTokens ERC20 tokens under vault management
    /// @param options Reserved additional deploy options. Should be 0x0.
    /// @param owner Owner of the registry vault nft
    /// @return vault Address of the new vault
    /// @return nft Nft of the vault in the vault registry
    function deployVault(
        address[] memory vaultTokens,
        bytes memory options,
        address owner
    ) external returns (IVault vault, uint256 nft);

    /// @notice Stage new Internal Params.
    /// @param newParams New Internal Params
    function stageInternalParams(InternalParams memory newParams) external;

    /// @notice Commit staged Internal Params.
    function commitInternalParams() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IProtocolGovernance.sol";
import "./IVaultFactory.sol";
import "./IVaultGovernance.sol";

interface IVaultRegistry is IERC721 {
    /// @notice Get Vault for the giver NFT ID.
    /// @param nftId NFT ID
    /// @return vault Address of the Vault contract
    function vaultForNft(uint256 nftId) external view returns (address vault);

    /// @notice Get NFT ID for given Vault contract address.
    /// @param vault Address of the Vault contract
    /// @return nftId NFT ID
    function nftForVault(address vault) external view returns (uint256 nftId);

    /// @notice Register new Vault and mint NFT.
    /// @param vault address of the vault
    /// @param owner owner of the NFT
    /// @return nft Nft minted for the given Vault
    function registerVault(address vault, address owner) external returns (uint256 nft);

    /// @notice Number of Vaults registered.
    function vaultsCount() external view returns (uint256);

    /// @notice All Vaults registered.
    function vaults() external view returns (address[] memory);

    /// @notice Address of the ProtocolGovernance.
    function protocolGovernance() external view returns (IProtocolGovernance);

    /// @notice Address of the staged ProtocolGovernance.
    function stagedProtocolGovernance() external view returns (IProtocolGovernance);

    /// @notice Minimal timestamp when staged ProtocolGovernance can be applied.
    function stagedProtocolGovernanceTimestamp() external view returns (uint256);

    /// @notice Stage new ProtocolGovernance.
    /// @param newProtocolGovernance new ProtocolGovernance
    function stageProtocolGovernance(IProtocolGovernance newProtocolGovernance) external;

    /// @notice Comit new ProtocolGovernance.
    function commitStagedProtocolGovernance() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/// @notice Common shared utilities
library Common {
    uint256 constant DENOMINATOR = 10**9;

    /// @notice Sort addresses using bubble sort. The sorting is done in-place.
    /// @param arr Array of addresses
    function bubbleSort(address[] memory arr) internal pure {
        uint256 l = arr.length;
        for (uint256 i = 0; i < l; i++) {
            for (uint256 j = i + 1; j < l; j++) {
                if (arr[i] > arr[j]) {
                    address temp = arr[i];
                    arr[i] = arr[j];
                    arr[j] = temp;
                }
            }
        }
    }

    /// @notice Checks if array of addresses is sorted and all adresses are unique
    /// @param tokens A set of addresses to check
    /// @return `true` if all addresses are sorted and unique, `false` otherwise
    function isSortedAndUnique(address[] memory tokens) internal pure returns (bool) {
        if (tokens.length < 2) {
            return true;
        }
        for (uint256 i = 0; i < tokens.length - 1; i++) {
            if (tokens[i] >= tokens[i + 1]) {
                return false;
            }
        }
        return true;
    }

    /// @dev
    /// Requires both sets of tokens to be sorted. When tokens are not sorted, it's undefined behavior.
    /// If there is a token in tokensToProject that is not part of tokens and corresponding tokenAmountsToProject > 0, reverts.
    /// Zero token amount is eqiuvalent to missing token
    function projectTokenAmounts(
        address[] memory tokens,
        address[] memory tokensToProject,
        uint256[] memory tokenAmountsToProject
    ) internal pure returns (uint256[] memory) {
        uint256[] memory res = new uint256[](tokens.length);
        uint256 t = 0;
        uint256 tp = 0;
        while ((t < tokens.length) && (tp < tokensToProject.length)) {
            if (tokens[t] < tokensToProject[tp]) {
                res[t] = 0;
                t++;
            } else if (tokens[t] > tokensToProject[tp]) {
                if (tokenAmountsToProject[tp] == 0) {
                    tp++;
                } else {
                    revert("TPS");
                }
            } else {
                res[t] = tokenAmountsToProject[tp];
                t++;
                tp++;
            }
        }
        while (t < tokens.length) {
            res[t] = 0;
            t++;
        }
        return res;
    }

    /// @notice Splits each amount of n tokens from `amounts` into k vaults according to `weights`.
    /// @dev Requires tokens and tokenAmounts to be vector of size n and delegatedTokenAmounts to be k x n matrix
    /// so that delegatedTokenAmounts[i] is a vector of size n
    /// norm is a vector 1 x k
    /// the error is up to k tokens due to rounding
    /// @param amounts Amounts to split, vector n x 1
    /// @param weights Weights of the split, matrix n x k, weights[i] is vector n x 1.
    /// Weights do not need to sum to 1 in each column, but they will be normalized on split.
    function splitAmounts(uint256[] memory amounts, uint256[][] memory weights)
        internal
        pure
        returns (uint256[][] memory)
    {
        uint256 k = weights.length;
        require(k > 0, "KGT0");
        uint256 n = amounts.length;
        require(n > 0, "NGT0");
        uint256[] memory weightsNorm = new uint256[](n);
        for (uint256 i = 0; i < k; i++) {
            require(weights[i].length == n, "NV");
        }
        for (uint256 j = 0; j < n; j++) {
            weightsNorm[j] = 0;
            for (uint256 i = 0; i < k; i++) {
                weightsNorm[j] += weights[i][j];
            }
        }
        uint256[][] memory res = new uint256[][](k);
        for (uint256 i = 0; i < k; i++) {
            res[i] = new uint256[](n);
            for (uint256 j = 0; j < n; j++) {
                if (weightsNorm[j] == 0) {
                    res[i][j] = amounts[j] / k;
                } else {
                    res[i][j] = (amounts[j] * weights[i][j]) / weightsNorm[j];
                }
            }
        }
        return res;
    }

    /// @notice Determines if a given address is a contract address
    /// @param addr Address to check
    /// @return `true` if the address is a contract address, `false` otherwise
    function isContract(address addr) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(addr)
        }
        return (size > 0);
    }

    function _isSubsetOf(
        address[] memory tokens,
        address[] memory tokensToCheck,
        address[] memory amountsToCheck
    ) internal {
        // TODO: implement or remove
    }
}