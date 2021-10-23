/// @author Hapi Finance Team
/// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";
import "./Registry.sol";

/**
 * @title Proxy
 * @dev Gives the possibility to delegate any call to a foreign implementation.
 */
contract WillProxy is Proxy {
    /**
     * @dev Storage slot with the address of the current Registry.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _REGISTRY_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /** @notice initializes the proxy with a registry
     * @param registry registry location to get implementations
     */
    constructor(address registry) payable {
        StorageSlot.getAddressSlot(_REGISTRY_SLOT).value = registry;
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = msg.sender;
    }

    /**
     * @dev returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation()
        internal
        view
        virtual
        override
        returns (address impl)
    {
        address registryAddress = StorageSlot
            .getAddressSlot(_REGISTRY_SLOT)
            .value;
        Registry registry = Registry(registryAddress);

        // Call the registry to get the implementation of the caller
        try registry.getImplementation(msg.sender) returns (address _impl) {
            return _impl;
        } catch {
            return address(0);
        }
    }

    /** @notice Upgrades user to the latest version
     */
    function upgrade() public {
        address registryAddress = StorageSlot
            .getAddressSlot(_REGISTRY_SLOT)
            .value;
        Registry registry = Registry(registryAddress);

        try registry.upgrade(msg.sender) {
            return;
        } catch {
            return;
        }
    }

    /** @notice Upgrades user to the specified version
     * @param version implementation version to set
     */
    function upgradeToVersion(uint256 version) public {
        address registryAddress = StorageSlot
            .getAddressSlot(_REGISTRY_SLOT)
            .value;
        Registry registry = Registry(registryAddress);

        try registry.upgradeToVersion(msg.sender, version) {
            return;
        } catch {
            return;
        }
    }

    /** @notice Gets implementation address for user
     * @return address of the implementation version for the user
     */
    function getImplementation() public view returns (address) {
        address registryAddress = StorageSlot
            .getAddressSlot(_REGISTRY_SLOT)
            .value;
        Registry registry = Registry(registryAddress);

        try registry.getImplementation(msg.sender) returns (address _impl) {
            return _impl;
        } catch {
            return address(0);
        }
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
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
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
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
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

/// @author Hapi Finance Team
/// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";

/** @title Will */
contract Registry is Ownable {
    // If the Registry has been set up yet
    bool _initialized;

    // Proxy contract address to verify calls
    address public proxy;

    // Contracts containing implementation logic
    address[] public implementations;

    // What implementation version each user is running on
    mapping(address => uint256) versions;

    /// Constructor
    constructor() Ownable() {
        // Start with address 0 as v0 - as that is the base for the mapping
        implementations.push(address(0));
        proxy = address(0);
        _initialized = false;
    }

    /// View functions

    /** @notice Gets the implementation for the given sender
     * @dev If version for sender is 0, send latest implementation.
     * @param sender the sender of the call to the proxy
     * @return address of the implementation version for the sender
     */
    function getImplementation(address sender)
        public
        view
        onlyProxy
        initialized
        returns (address)
    {
        uint256 version = versions[sender];
        if (version == 0) {
            version = implementations.length - 1;
        }
        return implementations[version];
    }

    /** @notice Gets the latest implementation contract
     * @return address of the latest implementation contract
     */
    function getLatestImplementation()
        public
        view
        initialized
        returns (address)
    {
        return implementations[implementations.length - 1];
    }

    /** @notice Gets implementation for user, for admin/notification usage. limited to owner
     * @dev If version for sender is 0, send latest implementation.
     * @param user the user whose implementation to look up
     * @return address of the implementation version for the user
     */
    function getImplementationForUser(address user)
        public
        view
        onlyOwner
        initialized
        returns (address)
    {
        uint256 version = versions[user];
        if (version == 0) {
            version = implementations.length - 1;
        }
        return implementations[version];
    }

    /// Update functions

    /** @notice initializes registry once and only once
     * @param newProxy The address of the new proxy contract
     * @param implementation The address of the initial implementation
     */
    function initialize(address newProxy, address implementation)
        public
        onlyOwner
    {
        require(
            _initialized == false,
            "Initialize may only be called once to ensure the proxy can never be switched."
        );
        proxy = newProxy;
        implementations.push(implementation);
        _initialized = true;
    }

    /** @notice Updates the implementation
     * @param newImplementation The address of the new implementation contract
     */
    function register(address newImplementation) public onlyOwner initialized {
        implementations.push(newImplementation);
    }

    /** @notice Upgrades the sender's contract to the latest implementation
     * @param sender the sender of the call to the proxy
     */
    function upgrade(address sender) public onlyProxy initialized {
        versions[sender] = implementations.length - 1;
    }

    /** @notice Upgrades the sender's contract to the latest implementation
     * @param sender the sender of the call to the proxy
     * @param version the version of the implementation to upgrade to
     */
    function upgradeToVersion(address sender, uint256 version)
        public
        onlyProxy
        initialized
    {
        versions[sender] = version;
    }

    /// Modifiers

    /** @notice Restricts method to be called only by the proxy
     */
    modifier onlyProxy() {
        require(
            msg.sender == proxy,
            "This method is restricted to the proxy. Ensure initialize has been called, and you are calling from the proxy."
        );
        _;
    }

    /** @notice Restricts method to be called only once initialized
     */
    modifier initialized() {
        require(
            _initialized == true,
            "Please initialize this contract first by calling 'initialize()'"
        );
        _;
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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}