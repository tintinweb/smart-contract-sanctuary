// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
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

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
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
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(account), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )));
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
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
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
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
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(address newImplementation, bytes memory data, bool forceCall) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlot.BooleanSlot storage rollbackTesting = StorageSlot.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            Address.functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature(
                    "upgradeTo(address)",
                    oldImplementation
                )
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _setImplementation(newImplementation);
            emit Upgraded(newImplementation);
        }
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
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
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
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
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(
            Address.isContract(newBeacon),
            "ERC1967: new beacon is not a contract"
        );
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IBeacon.sol";
import "../Proxy.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev This contract implements a proxy that gets the implementation address for each call from a {UpgradeableBeacon}.
 *
 * The beacon address is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
 * conflict with the storage layout of the implementation behind the proxy.
 *
 * _Available since v3.4._
 */
contract BeaconProxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializating the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     */
    constructor(address beacon, bytes memory data) payable {
        assert(_BEACON_SLOT == bytes32(uint256(keccak256("eip1967.proxy.beacon")) - 1));
        _upgradeBeaconToAndCall(beacon, data, false);
    }

    /**
     * @dev Returns the current beacon address.
     */
    function _beacon() internal view virtual returns (address) {
        return _getBeacon();
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    function _implementation() internal view virtual override returns (address) {
        return IBeacon(_getBeacon()).implementation();
    }

    /**
     * @dev Changes the proxy to use a new beacon. Deprecated: see {_upgradeBeaconToAndCall}.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon.
     *
     * Requirements:
     *
     * - `beacon` must be a contract.
     * - The implementation returned by `beacon` must be a contract.
     */
    function _setBeacon(address beacon, bytes memory data) internal virtual {
        _upgradeBeaconToAndCall(beacon, data, false);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IBeacon.sol";
import "../../access/Ownable.sol";
import "../../utils/Address.sol";

/**
 * @dev This contract is used in conjunction with one or more instances of {BeaconProxy} to determine their
 * implementation contract, which is where they will delegate all function calls.
 *
 * An owner is able to change the implementation the beacon points to, thus upgrading the proxies that use this beacon.
 */
contract UpgradeableBeacon is IBeacon, Ownable {
    address private _implementation;

    /**
     * @dev Emitted when the implementation returned by the beacon is changed.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Sets the address of the initial implementation, and the deployer account as the owner who can upgrade the
     * beacon.
     */
    constructor(address implementation_) {
        _setImplementation(implementation_);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function implementation() public view virtual override returns (address) {
        return _implementation;
    }

    /**
     * @dev Upgrades the beacon to a new implementation.
     *
     * Emits an {Upgraded} event.
     *
     * Requirements:
     *
     * - msg.sender must be the owner of the contract.
     * - `newImplementation` must be a contract.
     */
    function upgradeTo(address newImplementation) public virtual onlyOwner {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Sets the implementation contract address for this beacon
     *
     * Requirements:
     *
     * - `newImplementation` must be a contract.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableBeacon: implementation is not a contract");
        _implementation = newImplementation;
    }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

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
library StorageSlot {
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

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

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
pragma solidity =0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

import "./Roadmap.sol";
import "./Voting.sol";

/// @title A factory for roadmap deployment
/// @dev Contains upgradable beacon proxies of other contracts for a Dapp
contract MilestoneBased {
  struct RoadmapInitializationSettings {
    uint256 id;
    IERC20 fundingToken;
    Roadmap.FundsReleaseType fundsReleaseType;
    address admin;
  }

  struct VotingInitializationSettings {
    IVotingStrategy votingStrategy;
    bytes ipfsVotingDetails;
    uint64 votingDuration;
    uint256 minConsensusVotingPower;
  }

  /// @notice Stores the address of an upgradable beacon proxy for a roadmap contract
  /// @return Address of an upgradable beacon proxy for a roadmap contract
  UpgradeableBeacon public immutable roadmapBeacon;
  /// @notice Stores the address of an upgradable beacon proxy for a voting contract
  /// @return Address of an upgradable beacon proxy for a voting contract
  UpgradeableBeacon public immutable votingBeacon;
  /// @notice Stores the refunding address used for roadmaps creation
  /// @return Refunding address used for roadmaps creation
  address public immutable refunding;
  /// @notice Stores if a particular address is a roadmap created by this factory
  /// @return Boolean value which is true if provided address is a roadmap created by this factory
  mapping(address => bool) public isRoadmapByAddress;

  /// @notice Emits on each successful roadmap deployment
  /// @dev Id parameter does not have to be unique
  /// @param id Id passed to a deployment process
  /// @param roadmap Deployed roadmap address
  event RoadmapCreated(uint256 id, address roadmap);

  /// @param _roadmapBeacon Roadmap upgradable beacon proxy address
  /// @param _votingBeacon Voting upgradable beacon proxy address
  constructor(
    UpgradeableBeacon _roadmapBeacon,
    UpgradeableBeacon _votingBeacon,
    address _refunding
  ) {
    roadmapBeacon = _roadmapBeacon;
    votingBeacon = _votingBeacon;
    refunding = _refunding;
  }

  /// @notice Creates a roadmap and a corresponding voting contract by provided parameters
  /// @param roadmapSettings Roadmap settings containing:
  /// uint256 id - id of roadmap to deploy.
  /// address fundingToken - ERC20 contract to be used for a funding functionality.
  /// Roadmap.FundsReleaseType fundsReleaseType - chooses a funds release type logic from a MilestoneStartDate(0), MilestoneEndDate(1) set.
  /// address admin - address of a first admin who is able to withdraw funds from withdrawable milestones.
  /// Can be as an externally owned account address, as a contract address(for example, multi-signature wallet).
  /// @param votingSettings Voting settings containing:
  /// address votingStrategy - IVotingStrategy contract to be used to check vote validity.
  /// bytes ipfsVotingDetails - IPFS hash of complementary voting settings information.
  /// uint256 votingDuration - duration for a voting stage of each proposal, in seconds.
  /// uint256 minConsensusVotingPower - minimal threshold of voting power in a proposal in order for it to be executable.
  function createRoadmap(
    RoadmapInitializationSettings calldata roadmapSettings,
    VotingInitializationSettings calldata votingSettings
  ) external {
    BeaconProxy roadmap = new BeaconProxy(address(roadmapBeacon), "");
    BeaconProxy voting = new BeaconProxy(address(votingBeacon), "");

    Roadmap(address(roadmap)).initialize(
      address(voting),
      refunding,
      roadmapSettings.admin,
      roadmapSettings.fundingToken,
      roadmapSettings.fundsReleaseType
    );

    Voting(address(voting)).initialize(
      address(roadmap),
      votingSettings.votingStrategy,
      votingSettings.ipfsVotingDetails,
      0,
      votingSettings.votingDuration,
      0,
      0,
      votingSettings.minConsensusVotingPower
    );

    isRoadmapByAddress[address(roadmap)] = true;
    emit RoadmapCreated(roadmapSettings.id, address(roadmap));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/// @title Contract for managing milestones and their funding
contract Roadmap is Initializable, AccessControl {
  using SafeERC20 for IERC20;
  // Because we aren't using short time durations for milestones it's safe to compare with block.timestamp in our case
  // solhint-disable not-rely-on-time

  enum FundsReleaseType {
    MilestoneStartDate,
    MilestoneEndDate
  }
  enum State {
    Funding,
    Refunding
  }
  enum VotingStatus {
    Active,
    Suspended,
    Finished
  }

  struct Milestone {
    uint256 amount;
    uint256 withdrawnAmount;
    uint64 startDate;
    uint64 endDate;
    VotingStatus votingStatus;
    bool isCreated;
  }

  /// @notice Stores the admin role key hash that is used for accessing the withdrawal call
  /// @return Bytes representing admin role key hash
  bytes32 public constant ROLE_ADMIN = keccak256("ROLE_ADMIN");

  /// @notice Stores IERC20 compatible contract that is used for funding this roadmap
  /// @return Address of a funding contract
  IERC20 public fundingToken;
  /// @notice Stores voting contract address which has privileged access for some functions of this roadmap
  /// @return Address of a voting contract
  address public voting;
  /// @notice Stores refunding contract address which is used to transfer remaining funds in a case of this roadmap refunding
  /// @return Address of a refunding contract
  address public refunding;
  /// @notice Stores funds release strategy for this roadmap
  /// @return 0 - withdrawal is available after a start timestamp of the milestone.
  /// 1 - withdrawal is available after an end timestamp of the milestone
  FundsReleaseType public fundsReleaseType;
  /// @notice Stores if a roadmap has been refunded
  /// @return 0 - roadmap have not been refunded.
  /// 1 - roadmap is refunded and most operations are blocked.
  State public state;
  /// @notice Stores amount of locked funds for currently added milestones
  /// @return Amount of locked funds for currently added milestones
  uint256 public lockedFunds;
  /// @notice Stores milestone information by a milestone id
  /// @return Milestone information:
  /// uint256 amount - amount of funds reserved for this milestone.
  /// uint256 withdrawnAmount - amount of already withdrawn funds from this milestone
  /// uint64 startDate - Start timestamps of a milestone.
  /// uint64 endDate - End timestamps of a milestone.
  /// VotingStatus votingStatus - current status of a milestone:
  /// 0 - milestone is active.
  /// 1 - milestone had been suspended.
  /// 2 - milestone has been finished by voting.
  /// bool isCreated - has this milestone been created
  mapping(uint256 => Milestone) public milestones;

  /// @notice Emits when the roadmap has been funded
  /// @param sender Address of a funder
  /// @param amount Funds amount
  event Funded(address indexed sender, uint256 amount);
  /// @notice Emits when the roadmap is set to be refunded
  /// @param sender Address of a caller
  /// @param amount Amount of funds refunded
  event Refunded(address indexed sender, uint256 amount);
  /// @notice Emits when funds are withdrawn from the milestone
  /// @param id Milestone id
  /// @param recipient Recipient address for withdrawn funds
  /// @param amount Amount of funds withdrawn
  event Withdrawn(uint256 indexed id, address recipient, uint256 amount);
  /// @notice Emits when refunding address is changed
  /// @param refunding New refunding address
  event RefundingContractChanged(address refunding);
  /// @notice Emits when voting contract is changed
  /// @param voting New voting contract address
  event VotingContractChanged(address voting);
  /// @notice Emits when milestone is added
  /// @param id Id of an added milestone
  /// @param amount Funds amount to be reserved for an added milestone
  /// @param startDate - Start timestamp of an added milestone.
  /// @param endDate - End timestamp of an added milestone.
  event MilestoneAdded(
    uint256 indexed id,
    uint256 amount,
    uint64 startDate,
    uint64 endDate
  );
  /// @notice Emits when milestone information is updated
  /// @param id Id of an updated milestone
  /// @param amount New funds amount to be reserved for an updated milestone
  /// @param startDate - New start timestamp of an updated milestone.
  /// @param endDate - New end timestamp of an updated milestone.
  event MilestoneUpdated(
    uint256 indexed id,
    uint256 amount,
    uint64 startDate,
    uint64 endDate
  );
  /// @notice Emits when milestone is removed
  /// @param id Id of a removed milestone
  event MilestoneRemoved(uint256 indexed id);
  /// @notice Emits when milestone voting is changed
  /// @param id Id of a milestone
  /// @param votingStatus New voting status of a milestone
  event MilestoneVotingStatusUpdated(
    uint256 indexed id,
    VotingStatus votingStatus
  );

  modifier onlyVoter() {
    require(msg.sender == voting, "Caller is not voting contract");
    _;
  }

  modifier onlyAdminOrVoter() {
    if (msg.sender != voting) {
      _checkRole(ROLE_ADMIN, msg.sender);
    }
    _;
  }

  modifier inState(State _state) {
    require(state == _state, "State do not match");
    _;
  }

  function initialize(
    address _voting,
    address _refunding,
    address _admin,
    IERC20 _fundingToken,
    FundsReleaseType _fundsReleaseType
  ) external initializer {
    _setRoleAdmin(ROLE_ADMIN, ROLE_ADMIN);
    _setupRole(ROLE_ADMIN, _admin);

    voting = _voting;
    refunding = _refunding;
    fundingToken = _fundingToken;
    fundsReleaseType = _fundsReleaseType;
  }

  /// @notice Fund this roadmap. Allowance for amount of fund tokens should be set prior to this transaction.
  /// @param _funds Amount of fund tokens
  function fundRoadmap(uint256 _funds) external inState(State.Funding) {
    fundingToken.safeTransferFrom(msg.sender, address(this), _funds);
    emit Funded(msg.sender, _funds);
  }

  /// @notice Withdraw funds from a particular milestone. Can be called by a roadmap admin or via voting
  /// @param _id Id of a milestone to withdraw from
  /// @param _recipient Address to send withdrawn funds
  /// @param _funds Amount of fund tokens to withdraw
  function withdraw(
    uint256 _id,
    address _recipient,
    uint256 _funds
  ) external inState(State.Funding) onlyAdminOrVoter {
    require(
      milestones[_id].votingStatus != VotingStatus.Suspended,
      "Cannot withdraw when milestone is suspended"
    );
    require(
      checkIsMilestoneWithdrawable(_id),
      "Cannot withdraw if voting status is not correct"
    );
    require(
      milestones[_id].amount - milestones[_id].withdrawnAmount >= _funds,
      "Cannot withdraw more than milestone available funds"
    );

    milestones[_id].withdrawnAmount = milestones[_id].withdrawnAmount + _funds;
    lockedFunds -= _funds;
    fundingToken.safeTransfer(_recipient, _funds);
    emit Withdrawn(_id, _recipient, _funds);
  }

  /// @notice Change refunding contract used in this roadmap. Can only be called from a voting contract
  /// @param _refunding New refunding contract address
  function setRefundingContract(address _refunding)
    external
    onlyVoter
    inState(State.Funding)
  {
    require(_refunding != address(0), "Cannot set zero address");
    refunding = _refunding;
    emit RefundingContractChanged(_refunding);
  }

  /// @notice Change voting contract used in this roadmap. Can only be called from a voting contract
  /// @param _voting New voting contract address
  function setVotingContract(address _voting)
    external
    onlyVoter
    inState(State.Funding)
  {
    require(_voting != address(0), "Cannot set zero address");
    voting = _voting;
    emit VotingContractChanged(_voting);
  }

  /// @notice Adds a new milestone. Can only be called from a voting
  /// @param _id Id of a milestone to be added
  /// @param _amount Amount of fund tokens for a milestone to be added
  /// @param _startDate - Start timestamps of a milestone to be added
  /// @param _endDate - End timestamps of a milestone to be added
  function addMilestone(
    uint256 _id,
    uint256 _amount,
    uint64 _startDate,
    uint64 _endDate
  ) external onlyVoter inState(State.Funding) {
    require(!doesMilestoneExist(_id), "Milestone already exists");
    require(
      areDatesCorrect(_startDate, _endDate),
      "Dates can't be zero and end should be later than start"
    );
    require(
      fundingToken.balanceOf(address(this)) >= lockedFunds + _amount,
      "Cannot start milestone if roadmap balance is less than required for milestone"
    );

    milestones[_id].amount = _amount;
    milestones[_id].startDate = _startDate;
    milestones[_id].endDate = _endDate;
    milestones[_id].votingStatus = VotingStatus.Active;
    milestones[_id].isCreated = true;
    lockedFunds += _amount;
    emit MilestoneAdded(_id, _amount, _startDate, _endDate);
  }

  /// @notice Updates information of an already existing milestone. Can only be called from a voting contract
  /// @param _id Id of a milestone to update
  /// @param _amount New amount of reserved fund tokens amount for this milestone
  /// @param _startDate - New start timestamp for this milestone
  /// @param _endDate - New end timestamp for this milestone
  function updateMilestone(
    uint256 _id,
    uint256 _amount,
    uint64 _startDate,
    uint64 _endDate
  ) external onlyVoter inState(State.Funding) {
    require(doesMilestoneExist(_id), "Milestone doesn't exists");
    require(
      !isMilestoneStarted(_id),
      "Cannot update already started milestone"
    );

    require(
      areDatesCorrect(_startDate, _endDate),
      "Dates can't be zero and end should be later than start"
    );

    lockedFunds -= milestones[_id].amount;
    lockedFunds += _amount;
    milestones[_id].amount = _amount;
    milestones[_id].startDate = _startDate;
    milestones[_id].endDate = _endDate;
    emit MilestoneUpdated(_id, _amount, _startDate, _endDate);
  }

  /// @notice Removes milestone from a roadmap. Can only be called from a voting contract
  /// @param _id Id of a milestone to remove
  function removeMilestone(uint256 _id)
    external
    onlyVoter
    inState(State.Funding)
  {
    require(doesMilestoneExist(_id), "Milestone does not exist");
    require(
      !isMilestoneStarted(_id),
      "Cannot remove already started milestone"
    );

    lockedFunds -= milestones[_id].amount;
    delete milestones[_id];
    emit MilestoneRemoved(_id);
  }

  /// @notice Updates voting status of a milestone. Can only be called from a voting contract.
  /// Currently supported transitions of a voting status - Active(0) -> Suspended(1), Active(0) -> Finished(2)
  /// @param _id Id of a milestone to update
  /// @param _votingStatus New voting status for a milestone
  function updateMilestoneVotingStatus(uint256 _id, VotingStatus _votingStatus)
    external
    onlyVoter
    inState(State.Funding)
  {
    require(doesMilestoneExist(_id), "Milestone does not exist");
    require(
      isMilestoneStarted(_id),
      "Cannot update voting status before start date"
    );

    require(
      isVotingStatusTransitionValid(
        milestones[_id].votingStatus,
        _votingStatus
      ),
      "Invalid voting status transition"
    );

    if (_votingStatus == VotingStatus.Suspended)
      lockedFunds -= milestones[_id].amount - milestones[_id].withdrawnAmount;

    milestones[_id].votingStatus = _votingStatus;
    emit MilestoneVotingStatusUpdated(_id, _votingStatus);
  }

  /// @notice Updates roadmap state. Can only be called from a voting contract.
  /// Currently supported transitions of a roadmap state - Funding(1) -> Refunding(0)
  /// @param _state New roadmap state
  function updateRoadmapState(State _state)
    external
    onlyVoter
    inState(State.Funding)
  {
    if (_state == State.Refunding) {
      state = _state;
      uint256 balance = fundingToken.balanceOf(address(this));
      refund(balance);
    }
  }

  /// @notice Check if a particular milestone is withdrawable according to roadmap funds release strategy
  /// @param _id Id of a milestone
  /// @return Boolean representing if a milestone is withdrawable
  function checkIsMilestoneWithdrawable(uint256 _id)
    public
    view
    returns (bool)
  {
    Milestone storage milestone = milestones[_id];

    if (fundsReleaseType == FundsReleaseType.MilestoneStartDate) {
      return milestone.startDate <= block.timestamp;
    } else if (fundsReleaseType == FundsReleaseType.MilestoneEndDate) {
      return milestone.endDate <= block.timestamp;
    }

    return false;
  }

  function doesMilestoneExist(uint256 _id) public view returns (bool) {
    return milestones[_id].isCreated;
  }

  function refund(uint256 _funds) private inState(State.Refunding) {
    fundingToken.safeTransfer(refunding, _funds);
    emit Refunded(msg.sender, _funds);
  }

  function areDatesCorrect(uint64 _startDate, uint64 _endDate)
    private
    pure
    returns (bool)
  {
    return _endDate > _startDate && _startDate > 0;
  }

  function isMilestoneStarted(uint256 _id) private view returns (bool) {
    return milestones[_id].startDate < block.timestamp;
  }

  function isVotingStatusTransitionValid(VotingStatus from, VotingStatus to)
    internal
    pure
    returns (bool)
  {
    return
      (from == VotingStatus.Active && to == VotingStatus.Finished) ||
      (from == VotingStatus.Active && to == VotingStatus.Suspended);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.3;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IVotingStrategy.sol";

/// @title Contract for storing proposals, voting and executing them
contract Voting is Initializable, ReentrancyGuardUpgradeable {
  // Because we aren't using short time durations for milestones it's safe to compare with block.timestamp in our case
  // solhint-disable not-rely-on-time

  struct Option {
    address[] callTargets;
    bytes[] callDataList;
    uint256 votingPower;
    mapping(address => uint256) votingPowerByAddress;
  }

  struct Proposal {
    uint256 createdAt;
    uint256 overallVotingPower;
    uint256 overallVoters;
    Option[] options;
    mapping(address => uint256) selectedOptions;
    bool executed;
  }

  enum ProposalTimeInterval {
    LockBeforeVoting,
    Voting,
    LockBeforeExecution,
    Execution,
    AfterExecution
  }

  /// @notice Stores the duration of an execution stage
  /// @return Seconds that are the duration of an execution stage
  uint256 public constant EXECUTION_DURATION = 7 days;

  /// @notice Stores a voting strategy used to check vote validity
  /// @return Address of a voting strategy used to check vote validity
  IVotingStrategy public votingStrategy;
  /// @notice Stores a ipfs hash containing additional information about this voting
  /// @return Bytes representing the ipfs hash containing additional information about this voting
  bytes public ipfsVotingDetails;
  /// @notice Stores a roadmap this voting is related to
  /// @return Address of a roadmap this voting is related to
  address public roadmap;
  /// @notice Stores duration of a window after the proposal is created before the voting stage starts
  /// @return Seconds that are the duration of a window after the proposal is created before the voting stage starts
  uint64 public timeLockBeforeVoting;
  /// @notice Stores duration of a voting stage
  /// @return Seconds that are the duration of a voting stage
  uint64 public votingDuration;
  /// @notice Stores duration of a window after the voting stage before the execution stage starts
  /// @return Seconds that are the duration of a window after the voting stage before the execution stage starts
  uint64 public timeLockBeforeExecution;
  /// @notice Stores minimal amount of voters in a proposal for it to be executable
  /// @return Minimal amount of voters in a proposal for it to be executable
  uint64 public minConsensusVotersCount;
  /// @notice Stores minimal amount of voting power in a proposal for it to be executable
  /// @return Minimal voting power of voters in a proposal for it to be executable
  uint256 public minConsensusVotingPower;
  /// @notice Stores proposal information by a proposal id
  /// @return Proposal information:
  /// uint256 createdAt - timestamp of a proposal creation time
  /// uint256 overallVotingPower - total voting power in this proposal
  /// uint256 overallVoters - total voters in this proposal
  /// bool executed - if this proposal was already executed
  Proposal[] public proposals;

  /// @notice Emits on each proposal creation
  /// @param id Id of a created proposal
  event ProposalAdded(uint256 indexed id);
  /// @notice Emits on each vote
  /// @param proposalId Id of a voted proposal
  /// @param optionId Id of a voted option
  /// @param voter Address of a voter
  /// @param votingPower Voting power of a vote
  /// @param ipfsHash Ipfs hash with additional information about the vote
  event ProposalVoted(
    uint256 indexed proposalId,
    uint256 indexed optionId,
    address indexed voter,
    uint256 votingPower,
    bytes ipfsHash
  );
  /// @notice Emits on a cancel of the vote
  /// @param proposalId Id of a proposal for the cancelled vote
  /// @param optionId Id of an option for the cancelled vote
  /// @param voter Address of a voter for the cancelled vote
  /// @param votingPower Voting power of a cancelled vote
  event ProposalVoteCancelled(
    uint256 indexed proposalId,
    uint256 indexed optionId,
    address indexed voter,
    uint256 votingPower
  );
  /// @notice Emits on a successful execution of the proposal
  /// @param proposalId Id of an executed proposal
  /// @param optionId Id of an executed option
  event ProposalExecuted(uint256 indexed proposalId, uint256 indexed optionId);

  modifier inProposalTimeInterval(
    uint256 proposalId,
    ProposalTimeInterval timeInterval
  ) {
    require(proposalExists(proposalId), "Proposal does not exists");
    require(
      proposalTimeInterval(proposalId) == timeInterval,
      "Wrong time period"
    );
    _;
  }

  function initialize(
    address _roadmap,
    IVotingStrategy _votingStrategy,
    bytes calldata _ipfsVotingDetails,
    uint64 _timeLockBeforeVoting,
    uint64 _votingDuration,
    uint64 _timeLockBeforeExecution,
    uint64 _minConsensusVotersCount,
    uint256 _minConsensusVotingPower
  ) external initializer {
    __ReentrancyGuard_init();

    roadmap = _roadmap;
    votingStrategy = _votingStrategy;
    ipfsVotingDetails = _ipfsVotingDetails;
    timeLockBeforeVoting = _timeLockBeforeVoting;
    votingDuration = _votingDuration;
    timeLockBeforeExecution = _timeLockBeforeExecution;
    minConsensusVotersCount = _minConsensusVotersCount;
    minConsensusVotingPower = _minConsensusVotingPower;
  }

  /// @notice Creates a proposal
  /// @dev Creates an empty option with id 0, options passed in callTargets and callDataList get indecies equal
  /// to their index in corresponding arrays + 1
  /// @param callTargets List of options each containing addresses which would be used for a call on execution
  /// @param callDataList List of options each containing call data lists which would be used for a call on execution
  function addProposal(
    address[][] calldata callTargets,
    bytes[][] calldata callDataList
  ) external {
    require(
      callTargets.length == callDataList.length,
      "Options array length missmatch"
    );
    uint256 optionsCount = callTargets.length;
    require(optionsCount > 0, "Options are empty");

    Proposal storage proposal = proposals.push();
    proposal.createdAt = block.timestamp;
    proposal.options.push(); // empty option

    for (uint256 i = 0; i < optionsCount; i++) {
      Option storage option = proposal.options.push();
      require(
        callTargets[i].length == callDataList[i].length,
        "Concrete option array length missmatch"
      );
      option.callTargets = callTargets[i];
      for (uint256 j = 0; j < callDataList[i].length; j++) {
        option.callDataList.push(callDataList[i][j]);
      }
    }

    emit ProposalAdded(proposals.length - 1);
  }

  /// @notice Votes for an option in the proposal. Supports revoting if a vote already have been submitted by a caller address
  /// @param proposalId Id of a voted proposal
  /// @param optionId Id of a voted option
  /// @param votingPower Voting power of a vote
  /// @param ipfsHash Ipfs hash with additional information about the vote
  /// @param argumentsU256 Array of uint256 which should be used to pass signature information
  /// @param argumentsB32 Array of bytes32 which should be used to pass signature information
  function vote(
    uint256 proposalId,
    uint256 optionId,
    uint256 votingPower,
    bytes calldata ipfsHash,
    uint256[] calldata argumentsU256,
    bytes32[] calldata argumentsB32
  ) external inProposalTimeInterval(proposalId, ProposalTimeInterval.Voting) {
    require(
      votingStrategy.isValid(
        IVotingStrategy.Vote({
          voter: msg.sender, // shouldn't be removed as it prevents votes reusage by other actors
          roadmap: roadmap,
          proposalId: proposalId,
          optionId: optionId,
          votingPower: votingPower,
          ipfsHash: ipfsHash
        }),
        argumentsU256,
        argumentsB32
      ),
      "Signature is not valid"
    );

    Proposal storage proposal = proposals[proposalId];
    require(optionId < proposal.options.length, "Invalid option id");

    {
      (bool previousVoteExists, uint256 previousOptionId) = getSelectedOption(
        proposal
      );
      require(
        !previousVoteExists || previousOptionId != optionId,
        "Already voted for this option"
      );
      if (previousVoteExists) {
        cancelPreviousVote(proposal, proposalId, previousOptionId);
      }
    }

    setSelectedOption(proposal, optionId);
    proposal.overallVotingPower += votingPower;
    proposal.overallVoters += 1;

    {
      Option storage option = proposal.options[optionId];
      option.votingPower += votingPower;
      option.votingPowerByAddress[msg.sender] = votingPower;
    }

    emit ProposalVoted(proposalId, optionId, msg.sender, votingPower, ipfsHash);
  }

  /// @notice Cancels a vote previously submitted by a caller adress
  /// @param proposalId Id of a proposal to cancel vote for
  function cancelVote(uint256 proposalId)
    external
    inProposalTimeInterval(proposalId, ProposalTimeInterval.Voting)
  {
    Proposal storage proposal = proposals[proposalId];
    (bool exists, uint256 previousOptionId) = getSelectedOption(proposal);
    require(exists, "No vote exists");

    cancelPreviousVote(proposal, proposalId, previousOptionId);
  }

  /// @notice Execute an option in a proposal. Would fail if this option doesn't have a maximum voting power in this proposal
  /// @param proposalId Id of an executed proposal
  /// @param optionId Id of an executed option
  function execute(uint256 proposalId, uint256 optionId)
    external
    nonReentrant
    inProposalTimeInterval(proposalId, ProposalTimeInterval.Execution)
  {
    (bool haveMax, uint256 maxOptionId) = maxVotingPowerOption(proposalId);
    require(
      haveMax && optionId == maxOptionId,
      "Option does not have maximum voting power"
    );

    Proposal storage proposal = proposals[proposalId];
    require(!proposal.executed, "Already executed");
    require(
      proposal.overallVotingPower >= minConsensusVotingPower,
      "Not enough voting power for consensus"
    );
    require(
      proposal.overallVoters >= minConsensusVotersCount,
      "Not enough voters for consensus"
    );
    Option storage option = proposal.options[optionId];

    proposal.executed = true;

    uint256 calls = option.callTargets.length;
    for (uint256 i = 0; i < calls; i++) {
      address callTarget = option.callTargets[i];
      bytes storage callData = option.callDataList[i];
      (bool success, bytes memory data) = callTarget.call(callData); // solhint-disable-line avoid-low-level-calls
      require(success, concatenate("Error in a call: ", getRevertMsg(data)));
    }

    emit ProposalExecuted(proposalId, optionId);
  }

  /// @notice Returns options count for a particular proposal
  /// @param proposalId Id of a proposal
  /// @return Options count
  function getOptionCount(uint256 proposalId) external view returns (uint256) {
    require(proposalExists(proposalId), "Proposal does not exists");
    return proposals[proposalId].options.length;
  }

  /// @notice Returns information about options for a particular proposal
  /// @param proposalId Id of a proposal
  /// @return callTargets List of options addresses which would be used for a call on execution. Option id is index.
  /// @return callDataList List of options call data which would be used for a call on execution. Option id is index.
  /// @return votingPowers List of voting power for options. Option id is index.
  function getOptions(uint256 proposalId)
    external
    view
    returns (
      address[][] memory callTargets,
      bytes[][] memory callDataList,
      uint256[] memory votingPowers
    )
  {
    require(proposalExists(proposalId), "Proposal does not exists");
    Proposal storage proposal = proposals[proposalId];
    uint256 optionsCount = proposal.options.length;
    callTargets = new address[][](optionsCount);
    callDataList = new bytes[][](optionsCount);
    votingPowers = new uint256[](optionsCount);

    for (uint256 i = 0; i < optionsCount; i++) {
      Option storage option = proposal.options[i];
      callTargets[i] = option.callTargets;
      callDataList[i] = option.callDataList;
      votingPowers[i] = option.votingPower;
    }
  }

  /// @notice Returns total count of created proposals
  /// @return Total count of proposals
  function proposalsCount() external view returns (uint256) {
    return proposals.length;
  }

  /// @notice Returns if a particular proposal exists
  /// @param id Id of a proposal
  /// @return True if a proposal exists
  function proposalExists(uint256 id) public view returns (bool) {
    return id < proposals.length;
  }

  /// @notice Returns current time interval for a particular proposal
  /// @param id Id of a proposal
  /// @return Current time interval for a proposal
  function proposalTimeInterval(uint256 id)
    public
    view
    returns (ProposalTimeInterval)
  {
    uint256 timeElapsed = block.timestamp - proposals[id].createdAt;
    if (timeElapsed < timeLockBeforeVoting) {
      return ProposalTimeInterval.LockBeforeVoting;
    }

    timeElapsed -= timeLockBeforeVoting;
    if (timeElapsed < votingDuration) {
      return ProposalTimeInterval.Voting;
    }

    timeElapsed -= votingDuration;
    if (timeElapsed < timeLockBeforeExecution) {
      return ProposalTimeInterval.LockBeforeExecution;
    }

    timeElapsed -= timeLockBeforeExecution;
    if (timeElapsed < EXECUTION_DURATION) {
      return ProposalTimeInterval.Execution;
    } else {
      return ProposalTimeInterval.AfterExecution;
    }
  }

  /// @notice Returns information about option with a maximum voting power for a particular proposal
  /// @param proposalId Id of a proposal
  /// @return haveMax Does such option exists
  /// @return maxOptionId Id of a such option
  function maxVotingPowerOption(uint256 proposalId)
    public
    view
    returns (bool haveMax, uint256 maxOptionId)
  {
    Proposal storage proposal = proposals[proposalId];
    uint256 optionsCount = proposal.options.length;
    uint256 maxVotingPower = 0;
    for (uint256 i = 0; i < optionsCount; i++) {
      Option storage option = proposal.options[i];
      if (option.votingPower > maxVotingPower) {
        maxVotingPower = option.votingPower;
        maxOptionId = i;
        haveMax = true;
      } else if (option.votingPower == maxVotingPower) {
        haveMax = false;
      }
    }
  }

  function getSelectedOption(Proposal storage proposal)
    private
    view
    returns (bool exists, uint256 optionId)
  {
    uint256 stored = proposal.selectedOptions[msg.sender];
    if (stored > 0) {
      return (true, stored - 1);
    } else {
      return (false, 0);
    }
  }

  function setSelectedOption(Proposal storage proposal, uint256 optionId)
    private
  {
    proposal.selectedOptions[msg.sender] = optionId + 1;
  }

  function cancelPreviousVote(
    Proposal storage proposal,
    uint256 proposalId,
    uint256 previousOptionId
  ) private {
    Option storage previousOption = proposal.options[previousOptionId];
    uint256 previousVotingPower = previousOption.votingPowerByAddress[
      msg.sender
    ];
    previousOption.votingPower -= previousVotingPower;
    delete previousOption.votingPowerByAddress[msg.sender];
    delete proposal.selectedOptions[msg.sender];

    proposal.overallVotingPower -= previousVotingPower;
    proposal.overallVoters -= 1;

    emit ProposalVoteCancelled(
      proposalId,
      previousOptionId,
      msg.sender,
      previousVotingPower
    );
  }

  function getRevertMsg(bytes memory returnData)
    internal
    pure
    returns (string memory)
  {
    if (returnData.length < 68) return "Transaction reverted silently";

    // solhint-disable-next-line no-inline-assembly
    assembly {
      returnData := add(returnData, 0x04)
    }
    return abi.decode(returnData, (string));
  }

  function concatenate(string memory a, string memory b)
    internal
    pure
    returns (string memory)
  {
    return string(abi.encodePacked(a, b));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.3;

/// @title Interface for a generic voting strategy contract
interface IVotingStrategy {
  struct Vote {
    address voter;
    address roadmap;
    uint256 proposalId;
    uint256 optionId;
    uint256 votingPower;
    bytes ipfsHash;
  }

  /// @notice Used to get url of signature generation resource
  /// @return String representing signature generation resource url
  function url() external returns (string memory);

  /// @notice Checks validity of a vote signature
  /// @param vote Structure containing vote data which is being signed. Fields:
  /// address voter - address of a voter for this vote
  /// address roadmap - address of a roadmap voting is related to
  /// uint256 proposalId - id of a proposal for this vote
  /// uint256 optionId - id of a option being voted
  /// uint256 votingPower - voting power of this vote
  /// bytes ipfsHash - bytes representing ipfs hash which contains additional information about this vote
  /// @param argumentsU256 Array of uint256 which should be used to pass signature information
  /// @param argumentsB32 Array of bytes32 which should be used to pass signature information
  /// @return True if a signature is valid, false otherwise
  function isValid(
    Vote calldata vote,
    uint256[] calldata argumentsU256,
    bytes32[] calldata argumentsB32
  ) external returns (bool);
}

