pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title Smart contract for the MeebitsDAO delegation. Based off of Gnosis Deelgate Registry.
 * @author maikir
 */

contract MeebitsDAODelegation is
    Initializable,
    Ownable
{

    // Using these events it is possible to process the events to build up reverse lookups.
    // The indeces allow it to be very partial about how to build this lookup (e.g. only for a specific delegate).
    event SetDelegate(address indexed delegator, address indexed delegate);
    event ClearDelegate(address indexed delegator, address indexed delegate);

    /**
     * @notice The first key is the delegator and the value is the address of the delegate.
     */
    mapping (address => address) public delegation;

    /**
     * @dev Sets a delegate for the msg.sender
     * @param delegate the address of the delegate
     */
    function setDelegate(address delegate)
        public
    {
        require (
            delegate != msg.sender,
            "Can't delegate to self"
        );
        require (
            delegate != address(0),
            "Can't delegate to 0x0"
        );
        address currentDelegate = delegation[msg.sender];
        require (
            delegate != currentDelegate,
            "Already delegated to this address"
        );
        // Update delegation mapping
        delegation[msg.sender] = delegate;

        if (currentDelegate != address(0)) {
            emit ClearDelegate(msg.sender, currentDelegate);
        }

        emit SetDelegate(msg.sender, delegate);
    }

    /**
     * @dev Clears a delegate for the msg.sender
     */
    function clearDelegate()
        public
    {
        address currentDelegate = delegation[msg.sender];
        require (
            currentDelegate != address(0),
            "No delegate set"
        );

        // Update delegation mapping
        delegation[msg.sender] = address(0);

        emit ClearDelegate(msg.sender, currentDelegate);
    }

    function getCurrentDelegate()
        external
        view
        returns (address)
    {
        address currentDelegate = delegation[msg.sender];
        require (
            currentDelegate != address(0),
            "No delegate set"
        );
        return currentDelegate;
    }

    /**
     * @dev Override function for setting a delegate for the delegator. Only callable by the owner.
     * @param delegator the address of the delegator
     * @param delegate the address of the delegate
     */

    function overrideSetDelegate(address delegator, address delegate)
        public
        onlyOwner
    {
        require (
            delegate != delegator,
            "Can't delegate to self"
        );
        require (
            delegate != address(0),
            "Can't delegate to 0x0"
        );
        address currentDelegate = delegation[delegator];
        require (
            delegate != currentDelegate,
            "Already delegated to this address"
        );

        // Update delegation mapping
        delegation[delegator] = delegate;

        if (currentDelegate != address(0)) {
            emit ClearDelegate(delegator, currentDelegate);
        }

        emit SetDelegate(delegator, delegate);
    }

    /**
     * @dev Override function for clearing a delegate for the delegator. Only callable by the owner.
     * @param delegator the address of the delegator
     */

    function overrideClearDelegate(address delegator)
        public
        onlyOwner
    {
        address currentDelegate = delegation[delegator];
        require (
            currentDelegate != address(0),
            "No delegate set"
        );

        // Update delegation mapping
        delegation[delegator] = address(0);

        emit ClearDelegate(delegator, currentDelegate);
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