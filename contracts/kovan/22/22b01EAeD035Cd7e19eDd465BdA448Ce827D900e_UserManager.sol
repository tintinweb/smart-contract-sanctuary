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
// OpenZeppelin Contracts v4.4.0 (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal initializer {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
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
// OpenZeppelin Contracts v4.4.0 (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal initializer {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
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
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
// OpenZeppelin Contracts v4.4.0 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
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

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/**
 * @title Controller component
 * @dev For easy access to any core components
 */
abstract contract Controller is Initializable, UUPSUpgradeable, AccessControlUpgradeable {
    bytes32 public constant ROLE_ADMIN = keccak256("ROLE_ADMIN");

    mapping(address => address) private _admins;
    // slither-disable-next-line uninitialized-state
    bool private _paused;
    // slither-disable-next-line uninitialized-state
    address public pauseGuardian;

    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Controller: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Controller: not paused");
        _;
    }

    modifier onlyAdmin() {
        require(hasRole(ROLE_ADMIN, msg.sender), "Controller: not admin");
        _;
    }

    modifier onlyGuardian() {
        require(pauseGuardian == msg.sender, "Controller: caller does not have the guardian role");
        _;
    }

    //When using minimal deploy, do not call initialize directly during deploy, because msg.sender is the proxyFactory address, and you need to call it manually
    function __Controller_init(address admin_) public initializer {
        require(admin_ != address(0), "Controller: address zero");
        _paused = false;
        _admins[admin_] = admin_;
        __UUPSUpgradeable_init();
        _setupRole(ROLE_ADMIN, admin_);
        pauseGuardian = admin_;
    }

    function _authorizeUpgrade(address) internal view override onlyAdmin {}

    /**
     * @dev Check if the address provided is the admin
     * @param account Account address
     */
    function isAdmin(address account) public view returns (bool) {
        return hasRole(ROLE_ADMIN, account);
    }

    /**
     * @dev Add a new admin account
     * @param account Account address
     */
    function addAdmin(address account) public onlyAdmin {
        require(account != address(0), "Controller: address zero");
        require(_admins[account] == address(0), "Controller: admin already existed");

        _admins[account] = account;
        _setupRole(ROLE_ADMIN, account);
    }

    /**
     * @dev Set pauseGuardian account
     * @param account Account address
     */
    function setGuardian(address account) public onlyAdmin {
        pauseGuardian = account;
    }

    /**
     * @dev Renouce the admin from the sender's address
     */
    function renounceAdmin() public {
        renounceRole(ROLE_ADMIN, msg.sender);
        delete _admins[msg.sender];
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() public onlyGuardian whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public onlyGuardian whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    uint256[50] private ______gap;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

/**
 *  @title AssetManager Interface
 *  @dev Manage the token balances staked by the users and deposited by admins, and invest tokens to the integrated underlying lending protocols.
 */
interface IAssetManager {
    /**
     *  @dev Returns the balance of asset manager, plus the total amount of tokens deposited to all the underlying lending protocols.
     *  @param tokenAddress ERC20 token address
     *  @return Lending pool balance
     */
    function getPoolBalance(address tokenAddress) external view returns (uint256);

    /**
     *  @dev Returns the amount of the lending pool balance minus the amount of total staked.
     *  @param tokenAddress ERC20 token address
     *  @return Amount can be borrowed
     */
    function getLoanableAmount(address tokenAddress) external view returns (uint256);

    /**
     *  @dev Get the total amount of tokens deposited to all the integrated underlying protocols without side effects.
     *  @param tokenAddress ERC20 token address
     *  @return Total market balance
     */
    function totalSupply(address tokenAddress) external returns (uint256);

    /**
     *  @dev Get the total amount of tokens deposited to all the integrated underlying protocols, but without side effects. Safe to call anytime, but may not get the most updated number for the current block. Call totalSupply() for that purpose.
     *  @param tokenAddress ERC20 token address
     *  @return Total market balance
     */
    function totalSupplyView(address tokenAddress) external view returns (uint256);

    /**
     *  @dev Check if there is an underlying protocol available for the given ERC20 token.
     *  @param tokenAddress ERC20 token address
     *  @return Whether is supported
     */
    function isMarketSupported(address tokenAddress) external view returns (bool);

    /**
     *  @dev Deposit tokens to AssetManager, and those tokens will be passed along to adapters to deposit to integrated asset protocols if any is available.
     *  @param token ERC20 token address
     *  @param amount Deposit amount, in wei
     *  @return Deposited amount
     */
    function deposit(address token, uint256 amount) external returns (bool);

    /**
     *  @dev Withdraw from AssetManager
     *  @param token ERC20 token address
     *  @param account User address
     *  @param amount Withdraw amount, in wei
     *  @return Withdraw amount
     */
    function withdraw(
        address token,
        address account,
        uint256 amount
    ) external returns (bool);

    /**
     *  @dev Add a new ERC20 token to support in AssetManager
     *  @param tokenAddress ERC20 token address
     */
    function addToken(address tokenAddress) external;

    /**
     *  @dev Remove a ERC20 token to support in AssetManager
     *  @param tokenAddress ERC20 token address
     */
    function removeToken(address tokenAddress) external;

    /**
     *  @dev Add a new adapter for the underlying lending protocol
     *  @param adapterAddress adapter address
     */
    function addAdapter(address adapterAddress) external;

    /**
     *  @dev Remove a adapter for the underlying lending protocol
     *  @param adapterAddress adapter address
     */
    function removeAdapter(address adapterAddress) external;

    /**
     *  @dev For a give token set allowance for all integrated money markets
     *  @param tokenAddress ERC20 token address
     */
    function approveAllMarketsMax(address tokenAddress) external;

    /**
     *  @dev For a give moeny market set allowance for all underlying tokens
     *  @param adapterAddress Address of adaptor for money market
     */
    function approveAllTokensMax(address adapterAddress) external;

    /**
     *  @dev Set withdraw sequence
     *  @param newSeq priority sequence of money market indices to be used while withdrawing
     */
    function changeWithdrawSequence(uint256[] calldata newSeq) external;

    /**
     *  @dev Rebalance the tokens between integrated lending protocols
     *  @param tokenAddress ERC20 token address
     *  @param percentages Proportion
     */
    function rebalance(address tokenAddress, uint256[] calldata percentages) external;

    /**
     *  @dev Claim the tokens left on AssetManager balance, in case there are tokens get stuck here.
     *  @param tokenAddress ERC20 token address
     *  @param recipient Recipient address
     */
    function claimTokens(address tokenAddress, address recipient) external;

    /**
     *  @dev Claim the tokens stuck in the integrated adapters
     *  @param index MoneyMarkets array index
     *  @param tokenAddress ERC20 token address
     *  @param recipient Recipient address
     */
    function claimTokensFromAdapter(
        uint256 index,
        address tokenAddress,
        address recipient
    ) external;

    /**
     *  @dev Get the number of supported underlying protocols.
     *  @return MoneyMarkets length
     */
    function moneyMarketsCount() external view returns (uint256);

    /**
     *  @dev Get the count of supported tokens
     *  @return Number of supported tokens
     */
    function supportedTokensCount() external view returns (uint256);

    /**
     *  @dev Get the supported lending protocol
     *  @param tokenAddress ERC20 token address
     *  @param marketId MoneyMarkets array index
     *  @return tokenSupply
     */
    function getMoneyMarket(address tokenAddress, uint256 marketId) external view returns (uint256, uint256);

    /**
     *  @dev debt write off
     *  @param tokenAddress ERC20 token address
     *  @param amount WriteOff amount
     */
    function debtWriteOff(address tokenAddress, uint256 amount) external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

/**
 * @title Comptroller Interface
 * @dev Work with UnionToken and UserManager to calculate the Union rewards based on the staking info from UserManager, and be ready to support multiple UserManagers for various tokens when we support multiple assets.
 */
interface IComptroller {
    /**
     *  @dev Get the reward multipier based on the account status
     *  @param account Account address
     *  @return Multiplier number (in wei)
     */
    function getRewardsMultiplier(address account, address token) external view returns (uint256);

    /**
     *  @dev Withdraw rewards
     *  @return Amount of rewards
     */
    function withdrawRewards(address sender, address token) external returns (uint256);

    function addFrozenCoinAge(
        address staker,
        address token,
        uint256 lockedStake,
        uint256 lastRepay
    ) external;

    function updateTotalStaked(address token, uint256 totalStaked) external returns (bool);

    /**
     *  @dev Calculate unclaimed rewards based on blocks
     *  @param account User address
     *  @param futureBlocks Number of blocks in the future
     *  @return Unclaimed rewards
     */
    function calculateRewardsByBlocks(
        address account,
        address token,
        uint256 futureBlocks
    ) external view returns (uint256);

    /**
     *  @dev Calculate currently unclaimed rewards
     *  @param account Account address
     *  @return Unclaimed rewards
     */
    function calculateRewards(address account, address token) external view returns (uint256);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

/**
 * @title CreditLimitModel Interface
 *  @dev Calculate the user's credit line based on the trust he receives from the vouchees.
 */
interface ICreditLimitModel {
    struct LockedInfo {
        address staker;
        uint256 vouchingAmount;
        uint256 lockedAmount;
        uint256 availableStakingAmount;
    }

    function isCreditLimitModel() external pure returns (bool);

    function effectiveNumber() external returns (uint256);

    /**
     * @notice Calculates the staker locked amount
     * @return Member credit limit
     */
    function getLockedAmount(
        LockedInfo[] calldata vouchAmountList,
        address staker,
        uint256 amount,
        bool isIncrease
    ) external pure returns (uint256);

    /**
     * @notice Calculates the member credit limit by vouchs
     * @return Member credit limit
     */
    function getCreditLimit(uint256[] calldata vouchs) external view returns (uint256);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

interface IDai {
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

/**
 *  @title UToken Interface
 *  @dev Union members can borrow and repay thru this component.
 */
interface IUToken {
    /**
     *  @dev Returns the remaining amount that can be borrowed from the market.
     *  @return Remaining total amount
     */
    function getRemainingDebtCeiling() external view returns (uint256);

    /**
     *  @dev Get the borrowed principle
     *  @param account Member address
     *  @return Borrowed amount
     */
    function getBorrowed(address account) external view returns (uint256);

    /**
     *  @dev Get the last repay block
     *  @param account Member address
     *  @return Block number
     */
    function getLastRepay(address account) external view returns (uint256);

    /**
     *  @dev Get member interest index
     *  @param account Member address
     *  @return Interest index
     */
    function getInterestIndex(address account) external view returns (uint256);

    /**
     *  @dev Check if the member's loan is overdue
     *  @param account Member address
     *  @return Check result
     */
    function checkIsOverdue(address account) external view returns (bool);

    /**
     *  @dev Get the borrowing interest rate per block
     *  @return Borrow rate
     */
    function borrowRatePerBlock() external view returns (uint256);

    /**
     *  @dev Get the origination fee
     *  @param amount Amount to be calculated
     *  @return Handling fee
     */
    function calculatingFee(uint256 amount) external view returns (uint256);

    /**
     *  @dev Calculating member's borrowed interest
     *  @param account Member address
     *  @return Interest amount
     */
    function calculatingInterest(address account) external view returns (uint256);

    /**
     *  @dev Get a member's current owed balance, including the principle and interest but without updating the user's states.
     *  @param account Member address
     *  @return Borrowed amount
     */
    function borrowBalanceView(address account) external view returns (uint256);

    /**
     *  @dev Change loan origination fee value
     *  Accept claims only from the admin
     *  @param originationFee_ Fees deducted for each loan transaction
     */
    function setOriginationFee(uint256 originationFee_) external;

    /**
     *  @dev Update the market debt ceiling to a fixed amount, for example, 1 billion DAI etc.
     *  Accept claims only from the admin
     *  @param debtCeiling_ The debt limit for the whole system
     */
    function setDebtCeiling(uint256 debtCeiling_) external;

    /**
     *  @dev Update the max loan size
     *  Accept claims only from the admin
     *  @param maxBorrow_ Max loan amount per user
     */
    function setMaxBorrow(uint256 maxBorrow_) external;

    /**
     *  @dev Update the minimum loan size
     *  Accept claims only from the admin
     *  @param minBorrow_ Minimum loan amount per user
     */
    function setMinBorrow(uint256 minBorrow_) external;

    /**
     *  @dev Change loan overdue duration, based on the number of blocks
     *  Accept claims only from the admin
     *  @param overdueBlocks_ Maximum late repayment block. The number of arrivals is a default
     */
    function setOverdueBlocks(uint256 overdueBlocks_) external;

    /**
     *  @dev Change to a different interest rate model
     *  Accept claims only from the admin
     *  @param newInterestRateModel New interest rate model address
     */
    function setInterestRateModel(address newInterestRateModel) external;

    function setReserveFactor(uint256 reserveFactorMantissa_) external;

    function supplyRatePerBlock() external returns (uint256);

    function accrueInterest() external returns (bool);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function mint(uint256 mintAmount) external;

    function redeem(uint256 redeemTokens) external;

    function redeemUnderlying(uint256 redeemAmount) external;

    function addReserves(uint256 addAmount) external;

    function removeReserves(address receiver, uint256 reduceAmount) external;

    /**
     *  @dev Borrowing from the market
     *  Accept claims only from the member
     *  Borrow amount must in the range of creditLimit, minLoan, debtCeiling and not overdue
     *  @param amount Borrow amount
     */
    function borrow(uint256 amount) external;

    /**
     *  @dev Repay the loan
     *  Accept claims only from the member
     *  Updated member lastPaymentEpoch only when the repayment amount is greater than interest
     *  @param amount Repay amount
     */
    function repayBorrow(uint256 amount) external;

    /**
     *  @dev Repay the loan
     *  Accept claims only from the member
     *  Updated member lastPaymentEpoch only when the repayment amount is greater than interest
     *  @param borrower Borrower address
     *  @param amount Repay amount
     */
    function repayBorrowBehalf(address borrower, uint256 amount) external;

    /**
     *  @dev Update borrower overdue info
     *  @param account Borrower address
     */
    function updateOverdueInfo(address account) external;

    /**
     *  @dev debt write off
     *  @param borrower Borrower address
     *  @param amount WriteOff amount
     */
    function debtWriteOff(address borrower, uint256 amount) external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

/**
 * @title UnionToken Interface
 * @dev Mint and distribute UnionTokens.
 */
interface IUnionToken {
    /**
     *  @dev Get total supply
     *  @return Total supply
     */
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function mint(address account, uint256 amount) external returns (bool);

    /**
     *  @dev Determine the prior number of votes for an account as of a block number. Block number must be a finalized block or else this function will revert to prevent misinformation.
     *  @param account The address of the account to check
     *  @param blockNumber The block number to get the vote balance at
     *  @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint256);

    /**
     *  @dev Allows to spend owner's Union tokens by the specified spender.
     *  The function can be called by anyone, but requires having allowance parameters
     *  signed by the owner according to EIP712.
     *  @param owner The owner's address, cannot be zero address.
     *  @param spender The spender's address, cannot be zero address.
     *  @param value The allowance amount, in wei.
     *  @param deadline The allowance expiration date (unix timestamp in UTC).
     *  @param v A final byte of signature (ECDSA component).
     *  @param r The first 32 bytes of signature (ECDSA component).
     *  @param s The second 32 bytes of signature (ECDSA component).
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function burnFrom(address account, uint256 amount) external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

/**
 * @title UserManager Interface
 * @dev Manages the Union members credit lines, and their vouchees and borrowers info.
 */
interface IUserManager {
    /**
     *  @dev Check if the account is a valid member
     *  @param account Member address
     *  @return Address whether is member
     */
    function checkIsMember(address account) external view returns (bool);

    /**
     *  @dev Get member borrowerAddresses
     *  @param account Member address
     *  @return Address array
     */
    function getBorrowerAddresses(address account) external view returns (address[] memory);

    /**
     *  @dev Get member stakerAddresses
     *  @param account Member address
     *  @return Address array
     */
    function getStakerAddresses(address account) external view returns (address[] memory);

    /**
     *  @dev Get member backer asset
     *  @param account Member address
     *  @param borrower Borrower address
     *  @return Trust amount, vouch amount, and locked stake amount
     */
    function getBorrowerAsset(address account, address borrower)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    /**
     *  @dev Get member stakers asset
     *  @param account Member address
     *  @param staker Staker address
     *  @return Vouch amount and lockedStake
     */
    function getStakerAsset(address account, address staker)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    /**
     *  @dev Get the member's available credit line
     *  @param account Member address
     *  @return Limit
     */
    function getCreditLimit(address account) external view returns (int256);

    function totalStaked() external view returns (uint256);

    function totalFrozen() external view returns (uint256);

    function getFrozenCoinAge(address staker, uint256 pastBlocks) external view returns (uint256);

    /**
     *  @dev Add a new member
     *  Accept claims only from the admin
     *  @param account Member address
     */
    function addMember(address account) external;

    /**
     *  @dev Update the trust amount for exisitng members.
     *  @param borrower Borrower address
     *  @param trustAmount Trust amount
     */
    function updateTrust(address borrower, uint256 trustAmount) external;

    /**
     *  @dev Apply for membership, and burn UnionToken as application fees
     *  @param newMember New member address
     */
    function registerMember(address newMember) external;

    /**
     *  @dev Stop vouch for other member.
     *  @param staker Staker address
     *  @param account Account address
     */
    function cancelVouch(address staker, address account) external;

    /**
     *  @dev Change the credit limit model
     *  Accept claims only from the admin
     *  @param newCreditLimitModel New credit limit model address
     */
    function setCreditLimitModel(address newCreditLimitModel) external;

    /**
     *  @dev Get the user's locked stake from all his backed loans
     *  @param staker Staker address
     *  @return LockedStake
     */
    function getTotalLockedStake(address staker) external view returns (uint256);

    /**
     *  @dev Get staker's defaulted / frozen staked token amount
     *  @param staker Staker address
     *  @return Frozen token amount
     */
    function getTotalFrozenAmount(address staker) external view returns (uint256);

    /**
     *  @dev Update userManager locked info
     *  @param borrower Borrower address
     *  @param amount Borrow or repay amount(Including previously accrued interest)
     *  @param isBorrow True is borrow, false is repay
     */
    function updateLockedData(
        address borrower,
        uint256 amount,
        bool isBorrow
    ) external;

    /**
     *  @dev Get the user's deposited stake amount
     *  @param account Member address
     *  @return Deposited stake amount
     */
    function getStakerBalance(address account) external view returns (uint256);

    /**
     *  @dev Stake
     *  @param amount Amount
     */
    function stake(uint256 amount) external;

    /**
     *  @dev Unstake
     *  @param amount Amount
     */
    function unstake(uint256 amount) external;

    /**
     *  @dev Update total frozen
     *  @param account borrower address
     *  @param isOverdue account is overdue
     */
    function updateTotalFrozen(address account, bool isOverdue) external;

    function batchUpdateTotalFrozen(address[] calldata account, bool[] calldata isOverdue) external;

    /**
     *  @dev Repay user's loan overdue, called only from the lending market
     *  @param account User address
     *  @param lastRepay Last repay block number
     */
    function repayLoanOverdue(
        address account,
        address token,
        uint256 lastRepay
    ) external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../Controller.sol";
import "../interfaces/IAssetManager.sol";
import "../interfaces/ICreditLimitModel.sol";
import "../interfaces/IUserManager.sol";
import "../interfaces/IComptroller.sol";
import "../interfaces/IUnionToken.sol";
import "../interfaces/IDai.sol";
import "../interfaces/IUToken.sol";

/**
 * @title UserManager Contract
 * @dev Manages the Union members credit lines, and their vouchees and borrowers info.
 */
contract UserManager is Controller, IUserManager, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct Member {
        bool isMember;
        CreditLine creditLine;
    }

    //address: member address, uint256: trustAmount
    struct CreditLine {
        mapping(address => uint256) borrowers;
        address[] borrowerAddresses;
        mapping(address => uint256) stakers;
        address[] stakerAddresses;
        mapping(address => uint256) lockedAmount;
    }

    struct TrustInfo {
        address[] stakerAddresses;
        address[] borrowerAddresses;
        uint256 effectiveCount;
        address staker;
        uint256 vouchingAmount;
        uint256 stakingAmount;
        uint256 availableStakingAmount;
        uint256 lockedStake;
        uint256 totalLockedStake;
    }

    uint256 public constant MAX_TRUST_LIMIT = 100;
    uint256 public maxStakeAmount;
    address public stakingToken;
    address public unionToken;
    address public assetManager;
    IUToken public uToken;
    ICreditLimitModel public creditLimitModel;
    IComptroller public comptroller;
    uint256 public newMemberFee; // New member application fee

    // slither-disable-next-line constable-states
    uint256 public override totalStaked;
    // slither-disable-next-line constable-states
    uint256 public override totalFrozen;
    mapping(address => Member) private members;
    // slither-disable-next-line uninitialized-state
    mapping(address => uint256) public stakers; //1 user address 2 amount
    mapping(address => uint256) public memberFrozen; //1 user address 2 frozen amount

    error AddressZero();
    error AmountZero();
    error ErrorData();
    error AuthFailed();
    error NotCreditLimitModel();
    error ErrorSelfVouching();
    error MaxTrustLimitReached();
    error TrustAmountTooLarge();
    error LockedStakeNonZero();
    error NoExistingMember();
    error NotEnoughStakers();
    error StakeLimitReached();
    error AssetManagerDepositFailed();
    error AssetManagerWithdrawFailed();
    error InsufficientBalance();
    error ExceedsTotalStaked();
    error NotOverdue();
    error ExceedsLocked();
    error ExceedsTotalFrozen();
    error LengthNotMatch();
    error ErrorTotalStake();

    modifier onlyMember(address account) {
        if (!checkIsMember(account)) revert AuthFailed();
        _;
    }

    modifier onlyMarketOrAdmin() {
        if (address(uToken) != msg.sender && !isAdmin(msg.sender)) revert AuthFailed();
        _;
    }

    /**
     *  @dev Update new credit limit model event
     *  @param newCreditLimitModel New credit limit model address
     */
    event LogNewCreditLimitModel(address newCreditLimitModel);

    /**
     *  @dev Add new member event
     *  @param member New member address
     */
    event LogAddMember(address member);

    /**
     *  @dev Update vouch for existing member event
     *  @param staker Trustee address
     *  @param borrower The address gets vouched for
     *  @param trustAmount Vouch amount
     */
    event LogUpdateTrust(address indexed staker, address indexed borrower, uint256 trustAmount);

    /**
     *  @dev New member application event
     *  @param account New member's voucher address
     *  @param borrower New member address
     */
    event LogRegisterMember(address indexed account, address indexed borrower);

    /**
     *  @dev Cancel vouching for other member event
     *  @param account New member's voucher address
     *  @param borrower The address gets vouched for
     */
    event LogCancelVouch(address indexed account, address indexed borrower);

    /**
     *  @dev Stake event
     *  @param account The staker's address
     *  @param amount The amount of tokens to stake
     */
    event LogStake(address indexed account, uint256 amount);

    /**
     *  @dev Unstake event
     *  @param account The staker's address
     *  @param amount The amount of tokens to unstake
     */
    event LogUnstake(address indexed account, uint256 amount);

    /**
     *  @dev DebtWriteOff event
     *  @param staker The staker's address
     *  @param borrower The borrower's address
     *  @param amount The amount of write off
     */
    event LogDebtWriteOff(address indexed staker, address indexed borrower, uint256 amount);

    /**
     *  @dev set utoken address
     *  @param uToken new uToken address
     */
    event LogSetUToken(address uToken);

    /**
     *  @dev set new member fee
     *  @param oldMemberFee old member fee
     *  @param newMemberFee new member fee
     */
    event LogSetNewMemberFee(uint256 oldMemberFee, uint256 newMemberFee);

    event LogSetMaxStakeAmount(uint256 oldMaxStakeAmount, uint256 newMaxStakeAmount);

    function __UserManager_init(
        address assetManager_,
        address unionToken_,
        address stakingToken_,
        address creditLimitModel_,
        address comptroller_,
        address admin_
    ) public initializer {
        Controller.__Controller_init(admin_);
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        _setCreditLimitModel(creditLimitModel_);
        comptroller = IComptroller(comptroller_);
        assetManager = assetManager_;
        unionToken = unionToken_;
        stakingToken = stakingToken_;
        newMemberFee = 10**18; // Set the default membership fee
        maxStakeAmount = 5000e18;
    }

    function setMaxStakeAmount(uint256 maxStakeAmount_) public onlyAdmin {
        uint256 oldMaxStakeAmount = maxStakeAmount;
        maxStakeAmount = maxStakeAmount_;
        emit LogSetMaxStakeAmount(oldMaxStakeAmount, maxStakeAmount);
    }

    function setUToken(address uToken_) public onlyAdmin {
        if (uToken_ == address(0)) revert AddressZero();
        uToken = IUToken(uToken_);
        emit LogSetUToken(uToken_);
    }

    function setNewMemberFee(uint256 amount) public onlyAdmin {
        uint256 oldMemberFee = newMemberFee;
        newMemberFee = amount;
        emit LogSetNewMemberFee(oldMemberFee, newMemberFee);
    }

    /**
     *  @dev Change the credit limit model
     *  Accept claims only from the admin
     *  @param newCreditLimitModel New credit limit model address
     */
    function setCreditLimitModel(address newCreditLimitModel) public override onlyAdmin {
        if (newCreditLimitModel == address(0)) revert AddressZero();
        _setCreditLimitModel(newCreditLimitModel);
    }

    function _setCreditLimitModel(address newCreditLimitModel) private {
        if (!ICreditLimitModel(newCreditLimitModel).isCreditLimitModel()) revert NotCreditLimitModel();

        creditLimitModel = ICreditLimitModel(newCreditLimitModel);

        emit LogNewCreditLimitModel(newCreditLimitModel);
    }

    /**
     *  @dev Check if the account is a valid member
     *  @param account Member address
     *  @return Address whether is member
     */
    function checkIsMember(address account) public view override returns (bool) {
        return members[account].isMember;
    }

    /**
     *  @dev Get member borrowerAddresses
     *  @param account Member address
     *  @return Address array
     */
    function getBorrowerAddresses(address account) public view override returns (address[] memory) {
        return members[account].creditLine.borrowerAddresses;
    }

    /**
     *  @dev Get member stakerAddresses
     *  @param account Member address
     *  @return Address array
     */
    function getStakerAddresses(address account) public view override returns (address[] memory) {
        return members[account].creditLine.stakerAddresses;
    }

    /**
     *  @dev Get member backer asset
     *  @param account Member address
     *  @param borrower Borrower address
     *  @return trustAmount vouchingAmount lockedStake. Trust amount, vouch amount, and locked stake amount
     */
    function getBorrowerAsset(address account, address borrower)
        public
        view
        override
        returns (
            uint256 trustAmount,
            uint256 vouchingAmount,
            uint256 lockedStake
        )
    {
        trustAmount = members[account].creditLine.borrowers[borrower];
        lockedStake = getLockedStake(account, borrower);
        vouchingAmount = getVouchingAmount(account, borrower);
    }

    /**
     *  @dev Get member stakers asset
     *  @param account Member address
     *  @param staker Staker address
     *  @return trustAmount lockedStake vouchingAmount. Vouch amount and lockedStake
     */
    function getStakerAsset(address account, address staker)
        public
        view
        override
        returns (
            uint256 trustAmount,
            uint256 vouchingAmount,
            uint256 lockedStake
        )
    {
        trustAmount = members[account].creditLine.stakers[staker];
        lockedStake = getLockedStake(staker, account);
        vouchingAmount = getVouchingAmount(staker, account);
    }

    /**
     *  @dev Get staker locked stake for a borrower
     *  @param staker Staker address
     *  @param borrower Borrower address
     *  @return LockedStake
     */
    function getLockedStake(address staker, address borrower) public view returns (uint256) {
        return members[staker].creditLine.lockedAmount[borrower];
    }

    /**
     *  @dev Get the user's locked stake from all his backed loans
     *  @param staker Staker address
     *  @return LockedStake
     */
    function getTotalLockedStake(address staker) public view override returns (uint256) {
        uint256 totalLockedStake = 0;
        uint256 stakingAmount = stakers[staker];
        address[] memory borrowerAddresses = members[staker].creditLine.borrowerAddresses;
        address borrower;
        uint256 addressesLength = borrowerAddresses.length;
        for (uint256 i = 0; i < addressesLength; i++) {
            borrower = borrowerAddresses[i];
            totalLockedStake += getLockedStake(staker, borrower);
        }

        if (stakingAmount >= totalLockedStake) {
            return totalLockedStake;
        } else {
            return stakingAmount;
        }
    }

    /**
     *  @dev Get staker's defaulted / frozen staked token amount
     *  @param staker Staker address
     *  @return Frozen token amount
     */
    function getTotalFrozenAmount(address staker) public view override returns (uint256) {
        TrustInfo memory trustInfo;
        uint256 totalFrozenAmount = 0;
        trustInfo.borrowerAddresses = members[staker].creditLine.borrowerAddresses;
        trustInfo.stakingAmount = stakers[staker];

        address borrower;
        uint256 addressLength = trustInfo.borrowerAddresses.length;
        for (uint256 i = 0; i < addressLength; i++) {
            borrower = trustInfo.borrowerAddresses[i];
            if (uToken.checkIsOverdue(borrower)) {
                totalFrozenAmount += getLockedStake(staker, borrower);
            }
        }

        if (trustInfo.stakingAmount >= totalFrozenAmount) {
            return totalFrozenAmount;
        } else {
            return trustInfo.stakingAmount;
        }
    }

    /**
     *  @dev Get the member's available credit line
     *  @param borrower Member address
     *  @return Credit line amount
     */
    function getCreditLimit(address borrower) public view override returns (int256) {
        TrustInfo memory trustInfo;
        trustInfo.stakerAddresses = members[borrower].creditLine.stakerAddresses;
        // Get the number of effective vouchee, first
        trustInfo.effectiveCount = 0;
        uint256 stakerAddressesLength = trustInfo.stakerAddresses.length;
        uint256[] memory limits = new uint256[](stakerAddressesLength);

        for (uint256 i = 0; i < stakerAddressesLength; i++) {
            trustInfo.staker = trustInfo.stakerAddresses[i];

            trustInfo.stakingAmount = stakers[trustInfo.staker];

            trustInfo.vouchingAmount = getVouchingAmount(trustInfo.staker, borrower);

            //A vouchingAmount value of 0 means that the amount of stake is 0 or trust is 0. In this case, this data is not used to calculate the credit limit
            if (trustInfo.vouchingAmount > 0) {
                //availableStakingAmount is staker‘s free stake amount
                trustInfo.borrowerAddresses = getBorrowerAddresses(trustInfo.staker);

                trustInfo.availableStakingAmount = trustInfo.stakingAmount;
                uint256 totalLockedStake = getTotalLockedStake(trustInfo.staker);
                if (trustInfo.stakingAmount <= totalLockedStake) {
                    trustInfo.availableStakingAmount = 0;
                } else {
                    trustInfo.availableStakingAmount = trustInfo.stakingAmount - totalLockedStake;
                }

                trustInfo.lockedStake = getLockedStake(trustInfo.staker, borrower);

                if (trustInfo.vouchingAmount < trustInfo.lockedStake) revert ErrorData();

                //The actual effective guarantee amount cannot exceed availableStakingAmount,
                if (trustInfo.vouchingAmount >= trustInfo.availableStakingAmount + trustInfo.lockedStake) {
                    limits[trustInfo.effectiveCount] = trustInfo.availableStakingAmount;
                } else {
                    if (trustInfo.vouchingAmount <= trustInfo.lockedStake) {
                        limits[trustInfo.effectiveCount] = 0;
                    } else {
                        limits[trustInfo.effectiveCount] = trustInfo.vouchingAmount - trustInfo.lockedStake;
                    }
                }
                trustInfo.effectiveCount += 1;
            }
        }

        uint256[] memory creditlimits = new uint256[](trustInfo.effectiveCount);
        for (uint256 j = 0; j < trustInfo.effectiveCount; j++) {
            creditlimits[j] = limits[j];
        }

        return int256(creditLimitModel.getCreditLimit(creditlimits)) - int256(uToken.calculatingInterest(borrower));
    }

    /**
     *  @dev Get vouching amount
     *  @param staker Staker address
     *  @param borrower Borrower address
     */
    function getVouchingAmount(address staker, address borrower) public view returns (uint256) {
        uint256 totalStake = stakers[staker];
        uint256 trustAmount = members[borrower].creditLine.stakers[staker];
        return trustAmount > totalStake ? totalStake : trustAmount;
    }

    /**
     *  @dev Get the user's deposited stake amount
     *  @param account Member address
     *  @return Deposited stake amount
     */
    function getStakerBalance(address account) public view override returns (uint256) {
        return stakers[account];
    }

    /**
     *  @dev Add member
     *  Accept claims only from the admin
     *  @param account Member address
     */
    function addMember(address account) public override onlyAdmin {
        members[account].isMember = true;
        emit LogAddMember(account);
    }

    /**
     *  @dev Update the trust amount for exisitng members.
     *  @param borrower_ Account address
     *  @param trustAmount Trust amount
     */
    function updateTrust(address borrower_, uint256 trustAmount)
        external
        override
        onlyMember(msg.sender)
        whenNotPaused
    {
        if (borrower_ == address(0)) revert AddressZero();
        address borrower = borrower_;

        TrustInfo memory trustInfo;
        trustInfo.staker = msg.sender;
        if (trustInfo.staker == borrower) revert ErrorSelfVouching();
        if (
            members[borrower].creditLine.stakerAddresses.length >= MAX_TRUST_LIMIT ||
            members[trustInfo.staker].creditLine.borrowerAddresses.length >= MAX_TRUST_LIMIT
        ) revert MaxTrustLimitReached();
        trustInfo.borrowerAddresses = members[trustInfo.staker].creditLine.borrowerAddresses;
        trustInfo.stakerAddresses = members[borrower].creditLine.stakerAddresses;
        trustInfo.lockedStake = getLockedStake(trustInfo.staker, borrower);

        if (trustAmount < trustInfo.lockedStake) revert TrustAmountTooLarge();
        uint256 borrowerCount = members[trustInfo.staker].creditLine.borrowerAddresses.length;
        bool borrowerExist = false;
        for (uint256 i = 0; i < borrowerCount; i++) {
            if (trustInfo.borrowerAddresses[i] == borrower) {
                borrowerExist = true;
                break;
            }
        }

        uint256 stakerCount = members[borrower].creditLine.stakerAddresses.length;
        bool stakerExist = false;
        for (uint256 i = 0; i < stakerCount; i++) {
            if (trustInfo.stakerAddresses[i] == trustInfo.staker) {
                stakerExist = true;
                break;
            }
        }

        if (!borrowerExist) {
            members[trustInfo.staker].creditLine.borrowerAddresses.push(borrower);
        }

        if (!stakerExist) {
            members[borrower].creditLine.stakerAddresses.push(trustInfo.staker);
        }

        members[trustInfo.staker].creditLine.borrowers[borrower] = trustAmount;
        members[borrower].creditLine.stakers[trustInfo.staker] = trustAmount;
        emit LogUpdateTrust(trustInfo.staker, borrower, trustAmount);
    }

    /**
     *  @dev Stop vouch for other member.
     *  @param staker Staker address
     *  @param borrower borrower address
     */
    function cancelVouch(address staker, address borrower) external override onlyMember(msg.sender) whenNotPaused {
        if (msg.sender != staker && msg.sender != borrower) revert AuthFailed();
        if (getLockedStake(staker, borrower) != 0) revert LockedStakeNonZero();
        uint256 stakerCount = members[borrower].creditLine.stakerAddresses.length;
        bool stakerExist = false;
        uint256 stakerIndex = 0;
        for (uint256 i = 0; i < stakerCount; i++) {
            if (members[borrower].creditLine.stakerAddresses[i] == staker) {
                stakerExist = true;
                stakerIndex = i;
                break;
            }
        }

        uint256 borrowerCount = members[staker].creditLine.borrowerAddresses.length;
        bool borrowerExist = false;
        uint256 borrowerIndex = 0;
        for (uint256 i = 0; i < borrowerCount; i++) {
            if (members[staker].creditLine.borrowerAddresses[i] == borrower) {
                borrowerExist = true;
                borrowerIndex = i;
                break;
            }
        }

        //delete address
        if (borrowerExist) {
            members[staker].creditLine.borrowerAddresses[borrowerIndex] = members[staker].creditLine.borrowerAddresses[
                borrowerCount - 1
            ];
            members[staker].creditLine.borrowerAddresses.pop();
        }

        if (stakerExist) {
            members[borrower].creditLine.stakerAddresses[stakerIndex] = members[borrower].creditLine.stakerAddresses[
                stakerCount - 1
            ];
            members[borrower].creditLine.stakerAddresses.pop();
        }

        delete members[staker].creditLine.borrowers[borrower];
        delete members[borrower].creditLine.stakers[staker];

        emit LogCancelVouch(staker, borrower);
    }

    function registerMemberWithPermit(
        address newMember,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public whenNotPaused {
        IUnionToken unionTokenContract = IUnionToken(unionToken);
        unionTokenContract.permit(msg.sender, address(this), value, deadline, v, r, s);
        registerMember(newMember);
    }

    /**
     *  @dev Apply for membership, and burn UnionToken as application fees
     *  @param newMember New member address
     */
    function registerMember(address newMember) public override whenNotPaused {
        if (checkIsMember(newMember)) revert NoExistingMember();

        IUnionToken unionTokenContract = IUnionToken(unionToken);
        uint256 effectiveStakerNumber = 0;
        address stakerAddress;
        uint256 addressesLength = members[newMember].creditLine.stakerAddresses.length;
        for (uint256 i = 0; i < addressesLength; i++) {
            stakerAddress = members[newMember].creditLine.stakerAddresses[i];
            if (checkIsMember(stakerAddress) && getVouchingAmount(stakerAddress, newMember) > 0)
                effectiveStakerNumber += 1;
        }

        if (effectiveStakerNumber < creditLimitModel.effectiveNumber()) revert NotEnoughStakers();

        members[newMember].isMember = true;

        unionTokenContract.burnFrom(msg.sender, newMemberFee);

        emit LogRegisterMember(msg.sender, newMember);
    }

    function updateLockedData(
        address borrower,
        uint256 amount,
        bool isBorrow
    ) external override onlyMarketOrAdmin {
        TrustInfo memory trustInfo;
        trustInfo.stakerAddresses = members[borrower].creditLine.stakerAddresses;

        ICreditLimitModel.LockedInfo[] memory lockedInfoList = new ICreditLimitModel.LockedInfo[](
            trustInfo.stakerAddresses.length
        );
        uint256 addressesLength = trustInfo.stakerAddresses.length;
        for (uint256 i = 0; i < addressesLength; i++) {
            ICreditLimitModel.LockedInfo memory lockedInfo;

            trustInfo.staker = trustInfo.stakerAddresses[i];
            trustInfo.stakingAmount = stakers[trustInfo.staker];
            trustInfo.vouchingAmount = getVouchingAmount(trustInfo.staker, borrower);

            trustInfo.totalLockedStake = getTotalLockedStake(trustInfo.staker);
            if (trustInfo.stakingAmount <= trustInfo.totalLockedStake) {
                trustInfo.availableStakingAmount = 0;
            } else {
                trustInfo.availableStakingAmount = trustInfo.stakingAmount - trustInfo.totalLockedStake;
            }

            lockedInfo.staker = trustInfo.staker;
            lockedInfo.vouchingAmount = trustInfo.vouchingAmount;
            lockedInfo.lockedAmount = getLockedStake(trustInfo.staker, borrower);
            lockedInfo.availableStakingAmount = trustInfo.availableStakingAmount;

            lockedInfoList[i] = lockedInfo;
        }

        uint256 lockedInfoListLength = lockedInfoList.length;
        for (uint256 i = 0; i < lockedInfoListLength; i++) {
            members[lockedInfoList[i].staker].creditLine.lockedAmount[borrower] = creditLimitModel.getLockedAmount(
                lockedInfoList,
                lockedInfoList[i].staker,
                amount,
                isBorrow
            );
        }
    }

    /**
     *  @dev Stake
     *  @param amount Amount
     */
    function stake(uint256 amount) public override whenNotPaused nonReentrant {
        IERC20Upgradeable erc20Token = IERC20Upgradeable(stakingToken);

        comptroller.withdrawRewards(msg.sender, stakingToken);

        uint256 balance = stakers[msg.sender];

        if (balance + amount > maxStakeAmount) revert StakeLimitReached();

        stakers[msg.sender] = balance + amount;
        totalStaked += amount;

        erc20Token.safeTransferFrom(msg.sender, address(this), amount);
        erc20Token.safeApprove(assetManager, 0);
        erc20Token.safeApprove(assetManager, amount);

        if (!IAssetManager(assetManager).deposit(stakingToken, amount)) revert AssetManagerDepositFailed();
        emit LogStake(msg.sender, amount);
    }

    /**
     *  @dev stakeWithPermit
     *  @param amount Amount
     */
    function stakeWithPermit(
        uint256 amount,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public whenNotPaused {
        IDai erc20Token = IDai(stakingToken);
        erc20Token.permit(msg.sender, address(this), nonce, expiry, true, v, r, s);

        stake(amount);
    }

    /**
     *  @dev Unstake
     *  @param amount Amount
     */
    function unstake(uint256 amount) external override whenNotPaused nonReentrant {
        IERC20Upgradeable erc20Token = IERC20Upgradeable(stakingToken);
        uint256 stakingAmount = stakers[msg.sender];

        if (stakingAmount - getTotalLockedStake(msg.sender) < amount) revert InsufficientBalance();

        comptroller.withdrawRewards(msg.sender, stakingToken);

        stakers[msg.sender] = stakingAmount - amount;
        totalStaked -= amount;

        if (!IAssetManager(assetManager).withdraw(stakingToken, address(this), amount))
            revert AssetManagerWithdrawFailed();

        erc20Token.safeTransfer(msg.sender, amount);

        emit LogUnstake(msg.sender, amount);
    }

    function withdrawRewards() external whenNotPaused nonReentrant {
        comptroller.withdrawRewards(msg.sender, stakingToken);
    }

    /**
     *  @dev Repay user's loan overdue, called only from the lending market
     *  @param account User address
     *  @param token The asset token repaying to
     *  @param lastRepay Last repay block number
     */
    function repayLoanOverdue(
        address account,
        address token,
        uint256 lastRepay
    ) external override whenNotPaused onlyMarketOrAdmin {
        address[] memory stakerAddresses = getStakerAddresses(account);
        uint256 addressesLength;
        for (uint256 i = 0; i < addressesLength; i++) {
            address staker = stakerAddresses[i];
            (, , uint256 lockedStake) = getStakerAsset(account, staker);

            comptroller.addFrozenCoinAge(staker, token, lockedStake, lastRepay);
        }
    }

    //Only supports sumOfTrust
    function debtWriteOff(address borrower, uint256 amount) public {
        if (amount == 0) revert AmountZero();
        if (amount > totalStaked) revert ExceedsTotalStaked();
        if (!uToken.checkIsOverdue(borrower)) revert NotOverdue();

        uint256 lockedAmount = getLockedStake(msg.sender, borrower);
        if (amount > lockedAmount) revert ExceedsLocked();

        _updateTotalFrozen(borrower, true);
        if (amount > totalFrozen) revert ExceedsTotalFrozen();

        comptroller.withdrawRewards(msg.sender, stakingToken);

        //The borrower is still overdue, do not call comptroller.addFrozenCoinAge

        stakers[msg.sender] -= amount;
        totalStaked -= amount;
        totalFrozen -= amount;
        if (memberFrozen[borrower] >= amount) {
            memberFrozen[borrower] -= amount;
        } else {
            memberFrozen[borrower] = 0;
        }
        members[msg.sender].creditLine.lockedAmount[borrower] = lockedAmount - amount;
        uint256 trustAmount = members[msg.sender].creditLine.borrowers[borrower];
        uint256 newTrustAmount = trustAmount - amount;
        members[msg.sender].creditLine.borrowers[borrower] = newTrustAmount;
        members[borrower].creditLine.stakers[msg.sender] = newTrustAmount;
        IAssetManager(assetManager).debtWriteOff(stakingToken, amount);
        uToken.debtWriteOff(borrower, amount);
        emit LogDebtWriteOff(msg.sender, borrower, amount);
    }

    /**
     *  @dev Update total frozen
     *  @param account borrower address
     *  @param isOverdue account is overdue
     */
    function updateTotalFrozen(address account, bool isOverdue) external override onlyMarketOrAdmin whenNotPaused {
        if (totalStaked < totalFrozen) revert ErrorTotalStake();
        uint256 effectiveTotalStaked = totalStaked - totalFrozen;
        comptroller.updateTotalStaked(stakingToken, effectiveTotalStaked);
        _updateTotalFrozen(account, isOverdue);
    }

    function batchUpdateTotalFrozen(address[] calldata accounts, bool[] calldata isOverdues)
        external
        override
        onlyMarketOrAdmin
        whenNotPaused
    {
        if (accounts.length != isOverdues.length) revert LengthNotMatch();
        if (totalStaked < totalFrozen) revert ErrorTotalStake();
        uint256 effectiveTotalStaked = totalStaked - totalFrozen;
        comptroller.updateTotalStaked(stakingToken, effectiveTotalStaked);
        for (uint256 i = 0; i < accounts.length; i++) {
            if (accounts[i] != address(0)) _updateTotalFrozen(accounts[i], isOverdues[i]);
        }
    }

    function _updateTotalFrozen(address account, bool isOverdue) private {
        if (isOverdue) {
            //isOverdue = true, user overdue needs to increase totalFrozen

            //The sum of the locked amount of all stakers on this borrower, which is the frozen amount that needs to be updated
            uint256 amount;
            for (uint256 i = 0; i < members[account].creditLine.stakerAddresses.length; i++) {
                address staker = members[account].creditLine.stakerAddresses[i];
                uint256 lockedStake = getLockedStake(staker, account);
                amount += lockedStake;
            }

            if (memberFrozen[account] == 0) {
                //I haven’t updated the frozen amount about this borrower before, just increase the amount directly
                totalFrozen += amount;
            } else {
                //I have updated the frozen amount of this borrower before. After increasing the amount, subtract the previously increased value to avoid repeated additions.
                totalFrozen = totalFrozen + amount - memberFrozen[account];
            }
            //Record the increased value of this borrower this time
            memberFrozen[account] = amount;
        } else {
            //isOverdue = false, the user loan needs to reduce the number of frozen last time to return to normal
            if (totalFrozen > memberFrozen[account]) {
                //Minus the frozen amount added last time
                totalFrozen -= memberFrozen[account];
            } else {
                totalFrozen = 0;
            }
            memberFrozen[account] = 0;
        }
    }

    function getFrozenCoinAge(address staker, uint256 pastBlocks) public view override returns (uint256) {
        uint256 totalFrozenCoinAge = 0;

        address[] memory borrowerAddresses = getBorrowerAddresses(staker);
        uint256 addressLength = borrowerAddresses.length;
        for (uint256 i = 0; i < addressLength; i++) {
            address borrower = borrowerAddresses[i];
            uint256 blocks = block.number - uToken.getLastRepay(borrower);
            if (uToken.checkIsOverdue(borrower)) {
                (, , uint256 lockedStake) = getStakerAsset(borrower, staker);

                if (pastBlocks >= blocks) {
                    totalFrozenCoinAge = totalFrozenCoinAge + (lockedStake * blocks);
                } else {
                    totalFrozenCoinAge = totalFrozenCoinAge + (lockedStake * pastBlocks);
                }
            }
        }

        return totalFrozenCoinAge;
    }
}