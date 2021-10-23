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