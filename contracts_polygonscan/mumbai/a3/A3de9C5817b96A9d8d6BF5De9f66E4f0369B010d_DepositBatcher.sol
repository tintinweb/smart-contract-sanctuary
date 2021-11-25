pragma solidity ^0.8.8;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IDepositBatcher.sol";
import "./interfaces/IProtocol.sol";
import "./lib/DepositBatcherLib.sol";
import "./tunnel/FxBaseChildTunnel.sol";
import {DepositBatch, PurchaseChannel} from "./type/Batch.sol";
import {DepositData, MintedData} from "./type/Tunnel.sol";
import {Errors} from "./lib/helpers/Error.sol";

contract DepositBatcher is
    Initializable,
    IDepositBatcher,
    FxBaseChildTunnel,
    ReentrancyGuardUpgradeable,
    AccessControlUpgradeable
{
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");

    using DepositBatcherLib for DepositBatch;
    mapping(uint256 => DepositBatch) private _batch;
    mapping(address => mapping(uint256 => PurchaseChannel)) private _channel;
    mapping(address => uint256) private _channelCount;

    IERC20L2 private _usdc;
    IL2Factory private _factory;
    IWhitelist private _whitelist;
    uint256 private _currentBatch;

    modifier onlyWhitelisted() {
        require(
            _whitelist.whitelisted(_msgSender()),
            Errors.AC_USER_NOT_WHITELISTED
        );
        _;
    }

    function initialize(
        address admin,
        address usdcAddress,
        address factoryAddress,
        address whitelistAddress,
        address fxChild
    ) public virtual initializer {
        _usdc = IERC20L2(usdcAddress);
        _factory = IL2Factory(factoryAddress);
        _whitelist = IWhitelist(whitelistAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        FxBaseChildTunnel.setInitialParams(fxChild);
    }

    function mint(
        bytes32[] memory protocols,
        uint256[] memory amounts,
        uint256 total
    ) public virtual override onlyWhitelisted nonReentrant returns (bool) {
        address user = _msgSender();
        bool result;

        require(_usdc.balanceOf(user) >= total, Errors.VL_INSUFFICIENT_BALANCE);
        require(
            _usdc.allowance(user, address(this)) >= total,
            Errors.VL_INSUFFICIENT_ALLOWANCE
        );
        _usdc.transferFrom(user, address(this), total);

        for (uint256 i = 0; i < protocols.length; i++) {
            address _protocolAddress = _factory.fetchProtocolAddressL2(
                protocols[i]
            );
            if (_protocolAddress != address(0)) {
                result = instantMint(
                    user,
                    protocols[i],
                    amounts[i],
                    _protocolAddress
                );
            } else {
                result = batch(user, protocols[i], amounts[i]);
            }
        }

        return result;
    }

    function batch(
        address user,
        bytes32 protocol,
        uint256 amount
    ) internal virtual returns (bool) {
        bool update = _batch[_currentBatch].insert(user, protocol, amount);
        emit Batched(user, protocol, amount, _currentBatch);
        return update;
    }

    function instantMint(
        address user,
        bytes32 protocol,
        uint256 amount,
        address protocolAddress
    ) internal virtual returns (bool) {
        _usdc.transfer(protocolAddress, amount);
        uint256 minted = IProtocol(protocolAddress).mintProtocolToken(
            user,
            amount
        );
        emit Minted(user, protocol, amount, minted, _currentBatch);
        return true;
    }

    function execute()
        public
        virtual
        override
        onlyRole(GOVERNOR_ROLE)
        returns (bool)
    {
        uint256 batchId = _currentBatch;
        DepositBatch storage b = _batch[_currentBatch];
        require(b.status == BatchStatus.LIVE, Errors.VL_BATCH_NOT_ELLIGIBLE);

        DepositData memory tunneldata;

        uint256[] memory amounts = new uint256[](b.protocols.length);

        for (uint256 i = 0; i < b.protocols.length; i++) {
            amounts[i] = b.tokens[b.protocols[i]];
        }

        tunneldata.batchId = batchId;
        tunneldata.protocols = b.protocols;
        tunneldata.amounts = amounts;

        b.status = BatchStatus.BATCHED;
        _currentBatch += 1;

        _usdc.withdraw(b.total);
        _sendMessageToRoot(abi.encode(tunneldata));

        return true;
    }

    function createPurchaseChannel(
        uint256[] memory amounts,
        bytes32[] memory protocols,
        uint256 totalPerTenure,
        uint256 tenures,
        uint256 frequency
    ) public virtual override onlyWhitelisted nonReentrant returns (uint256) {
        address user = _msgSender();
        _channelCount[user] = _channelCount[user] + 1;

        _channel[user][_channelCount[user]] = PurchaseChannel(
            amounts,
            protocols,
            totalPerTenure,
            tenures,
            0,
            frequency,
            0
        );

        return _channelCount[user];
    }

    function executePurchaseChannel(address user, uint256 channelId)
        public
        virtual
        override
        onlyRole(GOVERNOR_ROLE)
        nonReentrant
        returns (bool)
    {
        require(
            channelId <= _channelCount[user],
            Errors.VL_NONEXISTENT_CHANNEL
        );

        PurchaseChannel storage channel = _channel[user][channelId];
        require(channel.completed < channel.tenures, Errors.VL_INVALID_CHANNEL);
        require(
            channel.lastPurchase + channel.frequency < block.timestamp,
            Errors.VL_INVALID_RECURRING_PURCHASE
        );

        require(
            _usdc.balanceOf(address(this)) >=
                _batch[_currentBatch].total + channel.totalPerTenure,
            Errors.VL_USDC_NOT_ARRIVED
        );

        bool result;

        for (uint256 i = 0; i < channel.protocols.length; i++) {
            address _protocolAddress = _factory.fetchProtocolAddressL2(
                channel.protocols[i]
            );
            if (_protocolAddress != address(0)) {
                result = instantMint(
                    user,
                    channel.protocols[i],
                    channel.amounts[i],
                    _protocolAddress
                );
            } else {
                result = batch(user, channel.protocols[i], channel.amounts[i]);
            }
        }

        channel.completed += 1;
        channel.lastPurchase = block.timestamp;
        return true;
    }

    function cancelPurchaseChannel(uint256 channelId)
        public
        virtual
        override
        onlyWhitelisted
        nonReentrant
        returns (bool)
    {
        address user = _msgSender();
        require(
            channelId <= _channelCount[user],
            Errors.VL_NONEXISTENT_CHANNEL
        );

        PurchaseChannel storage channel = _channel[user][channelId];
        require(channel.completed < channel.tenures, Errors.VL_INVALID_CHANNEL);

        channel.completed = channel.tenures;
        return true;
    }

    function usdc() public view virtual override returns (IERC20L2) {
        return _usdc;
    }

    function factory() public view virtual override returns (IL2Factory) {
        return _factory;
    }

    function whitelist() public view override returns (IWhitelist) {
        return _whitelist;
    }

    function currentBatch() public view override returns (uint256) {
        return _currentBatch;
    }

    function fetchPurchaseChannel(address user, uint256 channelId)
        public
        view
        override
        returns (PurchaseChannel memory)
    {
        return _channel[user][channelId];
    }

    function fetchUserDeposit(
        bytes32 protocol,
        uint256 batchId,
        address user
    ) public view override returns (uint256) {
        DepositBatch storage b = _batch[batchId];
        return b.individualUser[protocol][user];
    }

    function fetchUsersInBatch(bytes32 protocol, uint256 batchId)
        public
        view
        returns (address[] memory)
    {
        DepositBatch storage b = _batch[batchId];
        return b.users[protocol];
    }

    function fetchTotalDepositInBatch(bytes32 protocol, uint256 batchId)
        public
        view
        returns (uint256)
    {
        DepositBatch storage b = _batch[batchId];
        return b.tokens[protocol];
    }

    function fetchProtocolsInBatch(uint256 batchId)
        public
        view
        returns (bytes32[] memory)
    {
        DepositBatch storage b = _batch[batchId];
        return b.protocols;
    }

    function fetchBatchStatus(uint256 batchId)
        public
        view
        override
        returns (BatchStatus)
    {
        DepositBatch storage b = _batch[batchId];
        return b.status;
    }

    function _processMessageFromRoot(
        uint256 _stateId,
        address _sender,
        bytes memory _data
    ) internal override nonReentrant validateSender(_sender) {
        MintedData memory data = abi.decode(_data, (MintedData));
        DepositBatch storage b = _batch[data.batchId];

        require(
            b.status == BatchStatus.BATCHED,
            Errors.AC_BATCH_ALREADY_PROCESSED
        );

        for (uint256 i = 0; i < b.protocols.length; i++) {
            bytes32 protocol = b.protocols[i];
            address tokenAddress = _factory
                .fetchProtocolInfo(protocol)
                .tokenAddressL2;
            for (uint256 j = 0; j < b.users[protocol].length; j++) {
                address user = b.users[protocol][j];

                uint256 percent = (b.individualUser[protocol][user] * 10**18) /
                    b.tokens[protocol];
                uint256 value = percent * data.tokens[i];
                IERC20(tokenAddress).transfer(user, value);
            }
        }

        b.status = BatchStatus.DISTRIBUTED;
    }

    function mockProcessMessageFromRoot(
        address sender,
        uint256[] memory tokens,
        uint256 batchId
    ) public virtual {
        MintedData memory data = MintedData(batchId, tokens);
        _processMessageFromRoot(0, sender, abi.encode(data));
    }
}

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
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
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
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
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

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/whitelist/IWhitelist.sol";
import "../interfaces/factory/IL2Factory.sol";
import {BatchStatus, PurchaseChannel} from "../type/Batch.sol";

interface IERC20L2 is IERC20 {
    function withdraw(uint256 amount) external;
}

interface IDepositBatcher {
    event Batched(
        address user,
        bytes32 protocol,
        uint256 amount,
        uint256 batchId
    );

    event Minted(
        address user,
        bytes32 protocol,
        uint256 amount,
        uint256 minted,
        uint256 batchId
    );

    function mint(
        bytes32[] memory protocols,
        uint256[] memory amounts,
        uint256 total
    ) external returns (bool);

    function createPurchaseChannel(
        uint256[] memory amounts,
        bytes32[] memory protocols,
        uint256 totalPerTenure,
        uint256 tenures,
        uint256 frequency
    ) external returns (uint256);

    function executePurchaseChannel(address user, uint256 channelId)
        external
        returns (bool);

    function cancelPurchaseChannel(uint256 channelId) external returns (bool);

    function execute() external returns (bool);

    function usdc() external view returns (IERC20L2);

    function factory() external view returns (IL2Factory);

    function whitelist() external view returns (IWhitelist);

    function currentBatch() external view returns (uint256);

    function fetchPurchaseChannel(address user, uint256 channelId)
        external
        view
        returns (PurchaseChannel memory);

    function fetchUserDeposit(
        bytes32 protocol,
        uint256 batchId,
        address user
    ) external view returns (uint256);

    function fetchBatchStatus(uint256 batchId)
        external
        view
        returns (BatchStatus);
}

pragma solidity ^0.8.8;

interface IProtocol {
    function mintProtocolToken(address user, uint256 amount)
        external
        returns (uint256);

    function redeemProtocolToken(address user, uint256 amount)
        external
        returns (uint256);
}

pragma solidity ^0.8.8;

import {DepositBatch} from "../type/Batch.sol";
import {Errors} from "./helpers/Error.sol";

library DepositBatcherLib {
    function insert(
        DepositBatch storage self,
        address user,
        bytes32 protocol,
        uint256 amount
    ) internal returns (bool) {
        if (!self.created[protocol]) {
            self.protocols.push(protocol);
            self.created[protocol] = true;
        }

        if (self.individualUser[protocol][user] == 0) {
            self.users[protocol].push(user);
        }

        self.tokens[protocol] += amount;
        self.individualUser[protocol][user] += amount;
        self.total += amount;
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external;
}

/**
 * @notice Mock child tunnel contract to receive and send message from L2
 */
abstract contract FxBaseChildTunnel is IFxMessageProcessor, Initializable {
    // fx child
    address public fxChild;

    // fx root tunnel
    address public fxRootTunnel;

    // MessageTunnel on L1 will get data from this event
    event MessageSent(bytes message);

    // Sender must be fxRootTunnel in case of ERC20 tunnel
    modifier validateSender(address sender) {
        require(
            sender == fxRootTunnel,
            "FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT"
        );
        _;
    }

    // set fxRootTunnel if not set already
    function setFxRootTunnel(address _fxRootTunnel) external {
        require(
            fxRootTunnel == address(0x0),
            "FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET"
        );
        fxRootTunnel = _fxRootTunnel;
    }

    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external override {
        require(msg.sender == fxChild, "FxBaseChildTunnel: INVALID_SENDER");
        _processMessageFromRoot(stateId, rootMessageSender, data);
    }

    function setInitialParams(address _fxChild) public virtual initializer {
        fxChild = _fxChild;
    }

    /**
     * @notice Emit message that can be received on Root Tunnel
     * @dev Call the internal function when need to emit message
     * @param message bytes message that will be sent to Root Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToRoot(bytes memory message) internal {
        emit MessageSent(message);
    }

    /**
     * @notice Process message received from Root Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param stateId unique state id
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory message
    ) internal virtual;
}

pragma solidity ^0.8.8;

enum BatchStatus {
    LIVE,
    BATCHED,
    DISTRIBUTED
}

struct DepositBatch {
    bytes32[] protocols;
    uint256 total;
    BatchStatus status;
    mapping(bytes32 => bool) created;
    mapping(bytes32 => uint256) tokens;
    mapping(bytes32 => address[]) users;
    mapping(bytes32 => mapping(address => uint256)) individualUser;
}

struct WithdrawBatch {
    bytes32[] protocols;
    BatchStatus status;
    mapping(bytes32 => bool) created;
    mapping(bytes32 => uint256) tokens;
    mapping(bytes32 => address[]) users;
    mapping(bytes32 => mapping(address => uint256)) individualUser;
}

struct PurchaseChannel {
    uint256[] amounts;
    bytes32[] protocols;
    uint256 totalPerTenure;
    uint256 tenures;
    uint256 completed;
    uint256 frequency;
    uint256 lastPurchase;
}

pragma solidity ^0.8.8;

struct DepositData {
    uint256 batchId;
    bytes32[] protocols;
    uint256[] amounts;
}

struct RedemptionData {
    uint256 batchId;
    bytes32[] protocols;
    uint256[] amounts;
}

struct MintedData {
    uint256 batchId;
    uint256[] tokens;
}

struct RedeemedData {
    uint256 batchId;
    bytes32[] protocols;
    uint256[] amounts;
}

struct FactoryData {
    bytes32 protocolName;
    address tokenAddressL1;
    address tokenAddressL2;
    address protocolAddressL1;
    address protocolAddressL2;
    address stablecoinL1;
    address stablecoinL2;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Errors library
 * @author SmartDefi
 * @dev Error messages prefix glossary:
 *  - VL = ValidationLogic
 *  - AC = AccessContract
 */

library Errors {
    string public constant VL_INVALID_DEPOSIT = "1"; // 'The sum of deposits in each protocol should be equal to the total'
    string public constant VL_INSUFFICIENT_BALANCE = "2"; // 'The user doesn't have enough balance of tokens'

    string public constant VL_INSUFFICIENT_ALLOWANCE = "3"; // 'The spender doesn't have enough allowance of tokens'
    string public constant VL_BATCH_NOT_ELLIGIBLE = "4"; // The current batch Id doesn't have the ability for current operation
    string public constant VL_INVALID_PROTOCOL = "5"; // The protocol address is not found in factory.
    string public constant VL_ZERO_ADDRESS = "6"; // 'The sum of deposits in each protocol should be equal to the total'

    string public constant AC_USER_NOT_WHITELISTED = "7"; // 'The sum of deposits in each protocol should be equal to the total'
    string public constant AC_INVALID_GOVERNOR = "8"; // The caller is not governor of the whitelist contract.
    string public constant AC_INVALID_ROUTER = "9"; // The caller is not a valid router contract.
    string public constant AC_BATCH_ALREADY_PROCESSED = "10"; // The caller is not a valid router contract.

    string public constant VL_NONEXISTENT_CHANNEL = "11"; // 'The recurring payment channel is not yet created.'
    string public constant VL_INVALID_CHANNEL = "12"; // 'The channel is invalid for this operation'
    string public constant VL_USDC_NOT_ARRIVED = "13"; // 'The usdc for recurring channel is not available'
    string public constant VL_INVALID_RECURRING_PURCHASE = "14"; // 'User tried to do recurring purchase less than the frequency of time.'
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

pragma solidity ^0.8.8;

/**
 * @dev interface for whitelisting contract.
 * [TIP]: Only whitelisted addresses can mint from SD contracts.
 */

interface IWhitelist {
    /**
     * @dev whitelist the `user` for using SD contracts.
     * @param user represents EOA/SC to be whitelisted.
     * @return bool representing the status of whitelisting.
     *
     * [TIP]: user cannot be zero address.
     */
    function whitelist(address user) external returns (bool);

    /**
     * @dev blacklists the `user` from using SD contracts.
     * @param user represents the EOA/SC to be blacklisted.
     * @return bool representing the status of blacklisting process.
     * [TIP]: user should be whitelisted before and cannot be a zero address.
     */
    function blacklist(address user) external returns (bool);

    /**
     * @dev can check the status of whitelisting of an EOA/SC address.
     * @return bool representing the status of whitelisitng.
     * [TIP]:
     * true - address is whitelisted and can purchase tokens.
     * false - prevented from sale.
     */
    function whitelisted(address user) external view returns (bool);
}

pragma solidity ^0.8.8;

import {FactoryData} from "../../type/Tunnel.sol";

interface IL2Factory {
    event ProtocolUpdated(
        bytes32 protocolName,
        address protocolAddressL1,
        address protocolAddressL2,
        address tokenAddressL1,
        address tokenAddressL2,
        address stablecoinL1,
        address stablecoinL2
    );

    function fetchProtocolInfo(bytes32 protocolName)
        external
        view
        returns (FactoryData memory);

    function fetchProtocolAddressL2(bytes32 protocolName)
        external
        view
        returns (address);

    function fetchTokenAddressL2(bytes32 protocolName)
        external
        view
        returns (address);
}