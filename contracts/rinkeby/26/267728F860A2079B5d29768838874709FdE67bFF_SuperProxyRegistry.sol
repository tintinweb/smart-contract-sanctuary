// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.8;

import "../proxy/ProxyRegistry.sol";

/**
  @title A fully-implemented proxy registry contract.
  @author Protinam, Project Wyvern
  @author Tim Clancy
  @author Rostislav Khlebnikov

  This contract was originally developed by Project Wyvern
  (https://github.com/ProjectWyvern/) where it currently enjoys great success as
  the primary exchange contract for OpenSea. It has been modified to support a
  more modern version of Solidity with associated best practices. The
  documentation has also been improved to provide more clarity.
*/
contract SuperProxyRegistry is ProxyRegistry {

  /// The public name of this registry.
  string public constant name = "Super Proxy Registry";

  /**
    A flag to debounce whether or not the initial authorized caller has been
    set.
  */
  bool public initialCallerSet = false;

  /**
    Call ProxyRegistryConstructor
   */
  constructor () ProxyRegistry(){}

  /**
    Allow the owner of this registry to grant immediate authorization to a
    single address for calling proxies in this registry. This is to avoid
    waiting for the `DELAY_PERIOD` otherwise specified for further caller
    additions.

    @param _initial The initial caller authorized to operate in this registry.
  */
  function grantInitialAuthentication(address _initial) external onlyOwner {
    require(!initialCallerSet,
      "WyvernProxyRegistry: the initial caller has already been specified");
    initialCallerSet = true;
    authorizedCallers[_initial] = true;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./AuthenticatedProxy.sol";
import "../interfaces/IProxyRegistry.sol";

/**
  @title A proxy registry contract.
  @author Protinam, Project Wyvern
  @author Tim Clancy
  @author Rostislav Khlebnikov

  This contract was originally developed by Project Wyvern
  (https://github.com/ProjectWyvern/) where it currently enjoys great success as
  a component of the primary exchange contract for OpenSea. It has been modified
  to support a more modern version of Solidity with associated best practices.
  The documentation has also been improved to provide more clarity.
*/
contract ProxyRegistry is IProxyRegistry, Ownable {

  /**
    Each `OwnableDelegateProxy` contract ultimately dictates its implementation
    details elsewhere, to `delegateProxyImplementation`.
  */
  address public delegateProxyImplementation;

  /**
    This mapping relates an addresses to its own personal `OwnableDelegateProxy`
    which allow it to proxy functionality to the various callers contained in
    `authorizedCallers`.
  */
  mapping(address => address) public proxies;

  /**
    This mapping relates addresses which are pending access to the registry to
    the timestamp where they began the `startGrantAuthentication` process.
  */
  mapping(address => uint256) public pendingCallers;

  /**
    This mapping relates an address to a boolean specifying whether or not it is
    allowed to call the `OwnableDelegateProxy` for any given address in the
    `proxies` mapping.
  */
  mapping(address => bool) public authorizedCallers;

  /**
    A delay period which must elapse before adding an authenticated contract to
    the registry, thus allowing it to call the `OwnableDelegateProxy` for an
    address in the `proxies` mapping.

    This `ProxyRegistry` contract was designed with the intent to be owned by a
    DAO, so this delay mitigates a particular class of attack against an owning
    DAO. If at any point the value of assets accessible to the
    `OwnableDelegateProxy` contracts exceeded the cost of gaining control of the
    DAO, a malicious but rational attacker could spend (potentially
    considerable) resources to then have access to all `OwnableDelegateProxy`
    contracts via a malicious contract upgrade. This delay period renders this
    attack ineffective by granting time for addresses to remove assets from
    compromised `OwnableDelegateProxy` contracts.
  */
  uint256 public DELAY_PERIOD = 2 weeks;

    /**
    Construct this registry by specifying the initial implementation of all
    `OwnableDelegateProxy` contracts that are registered by users. This registry
    will use `AuthenticatedProxy` as its initial implementation.
  */
  constructor() {
    delegateProxyImplementation = address(new AuthenticatedProxy());
  }

  /**
    Allow the `ProxyRegistry` owner to begin the process of enabling access to
    the registry for the unauthenticated address `_unauthenticated`. Once the
    grant authentication process has begun, it is subject to the `DELAY_PERIOD`
    before the authentication process may conclude. Once concluded, the new
    address `_unauthenticated` will have access to the registry.

    This `ProxyRegistry` contract was designed with the intent to be owned by a
    DAO, so this function serves as an important timelock in the governance
    process.

    @param _unauthenticated The new address to grant access to the registry.
  */
  function startGrantAuthentication(address _unauthenticated) external
    onlyOwner {
    require(!authorizedCallers[_unauthenticated],
      "ProxyRegistry: this address is already an authorized caller");
    require(pendingCallers[_unauthenticated] == 0,
      "ProxyRegistry: this address is already pending authentication");
    pendingCallers[_unauthenticated] = block.timestamp;
  }

  /**
    Allow the `ProxyRegistry` owner to end the process of enabling access to the
    registry for the unauthenticated address `_unauthenticated`. If the required
    `DELAY_PERIOD` has passed, then the new address `_unauthenticated` will have
    access to the registry.

    @param _unauthenticated The new address to grant access to the registry.
  */
  function endGrantAuthentication(address _unauthenticated) external onlyOwner {
    require(!authorizedCallers[_unauthenticated],
      "ProxyRegistry: this address is already an authorized caller");
    require(pendingCallers[_unauthenticated] != 0,
      "ProxyRegistry: this address has not yet started authentication");
    require((pendingCallers[_unauthenticated] + DELAY_PERIOD) < block.timestamp,
      "ProxyRegistry: this address has not yet cleared the timelock");
    pendingCallers[_unauthenticated] = 0;
    authorizedCallers[_unauthenticated] = true;
  }

  /**
    Allow the owner of the `ProxyRegistry` to immediately revoke authorization
    to call proxies from the specified address.

    @param _caller The address to revoke authentication from.
  */
  function revokeAuthentication(address _caller) external onlyOwner {
    authorizedCallers[_caller] = false;
  }

  /**
    Enables an address to register its own proxy contract with this registry.

    @return The new `OwnableMutableDelegateProxy` contract with its
      `delegateProxyImplementation` implementation.
  */
  function registerProxy() external returns (address) {
    require(address(proxies[_msgSender()]) == address(0),
      "ProxyRegistry: you have already registered a proxy");

    // Construct the new `OwnableDelegateProxy` with this registry's initial
    // implementation and call said implementation's "initialize" function.
    OwnableMutableDelegateProxy proxy = new OwnableMutableDelegateProxy(
      _msgSender(), 
      delegateProxyImplementation,
      abi.encodeWithSignature("initialize(address)", address(this))
    );
    address proxyAddr = address(proxy);
    proxies[_msgSender()] = proxyAddr;
    return proxyAddr;
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./TokenRecipient.sol";
import "../interfaces/IProxyRegistry.sol";

/**
  @title An ownable call-delegating proxy which can receive tokens and only make
    calls against contracts that have been approved by a `ProxyRegistry`.
  @author Protinam, Project Wyvern
  @author Tim Clancy

  This contract was originally developed by Project Wyvern
  (https://github.com/ProjectWyvern/) where it currently enjoys great success as
  a component of the primary exchange contract for OpenSea. It has been modified
  to support a more modern version of Solidity with associated best practices.
  The documentation has also been improved to provide more clarity.
*/
contract AuthenticatedProxy is Ownable, TokenRecipient {

  /// Whether or not this proxy is initialized. It may only be initialized once.
  bool public initialized = false;

  /// The associated `ProxyRegistry` contract with authentication information.
  address public registry;

  /// Whether or not access has been revoked.
  bool public revoked;

  /**
    An enumerable type for selecting the method by which we would like to
    perform a call in the `proxy` function.

    @param Call This call type specifies that we perform a direct call.
    @param DelegateCall This call type can be used to automatically transfer
      multiple assets owned by the proxy contract with one order.
  */
  enum CallType {
    Call,
    DelegateCall
  }

  /**
    An event fired when the proxy contract's access is revoked or unrevoked.

    @param revoked The status of the revocation call; true if access is
    revoked and false if access is unrevoked.
  */
  event Revoked(bool revoked);

  /**
    Initialize this authenticated proxy for its owner against a specified
    `ProxyRegistry`. The registry controls the eligible targets.

    @param _registry The registry to create this proxy against.
  */
  function initialize(address _registry) external {
    require(!initialized,
      "AuthenticatedProxy: this proxy may only be initialized once");
    initialized = true;
    registry = _registry;
  }

  /**
    Allow the owner of this proxy to set the revocation flag. This permits them
    to revoke access from the associated `ProxyRegistry` if needed.
  */
  function setRevoke(bool revoke) external onlyOwner {
    revoked = revoke;
    emit Revoked(revoke);
  }

  /**
    Trigger this proxy to call a specific address with the provided data. The
    proxy may perform a direct or a delegate call. This proxy can only be called
    by the owner, or on behalf of the owner by a caller authorized by the
    registry. Unless the user has revoked access to the registry, that is.

    @param _target The target address to make the call to.
    @param _type The type of call to make: direct or delegated.
    @param _data The call data to send to `_target`.
    @return Whether or not the call succeeded.
  */
  function call(address _target, CallType _type, bytes calldata _data) public
    returns (bool) {
    require(_msgSender() == owner()
      || (!revoked && IProxyRegistry(registry).authorizedCallers(_msgSender())),
      "AuthenticatedProxy: not owner, not authorized by an unrevoked registry");

    // The call is authorized to be performed, now select a type and return.
    if (_type == CallType.Call) {
      (bool success, ) = _target.call(_data);
      return success;
    } else if (_type == CallType.DelegateCall) {
      (bool success, ) = _target.delegatecall(_data);
      return success;
    }
    return false;
  }

  /**
    Trigger this proxy to call a specific address with the provided data and
    require success. Otherwise identical to `call()`.

    @param _target The target address to make the call to.
    @param _type The type of call to make: direct or delegated.
    @param _data The call data to send to `_target`.
  */
  function callAssert(address _target, CallType _type, bytes calldata _data)
    external {
    require(call(_target, _type, _data),
      "AuthenticatedProxy: the asserted call did not succeed");
  }
}

pragma solidity ^0.8.8;

import "../proxy/OwnableMutableDelegateProxy.sol";

/**
 * @title ProxyRegistry Interface
 * @author Rostislav Khlebnikov
 */
interface IProxyRegistry {

    /// returns address of  current valid implementation of delegate proxy.
    function delegateProxyImplementation() external view returns (address);

    /**
        Returns address of a proxy which was registered for the user address before listing NFTs.
        @param owner address of NFTs lister.
     */
    function proxies(address owner) external view returns (address);

    /**
        Returns true if `caller` to the proxy registry is eligible and registered.
        @param caller address of the caller.
     */
    function authorizedCallers(address caller) external view returns (bool);

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
  @title A contract which may receive Ether and tokens.
  @author Protinam, Project Wyvern
  @author Tim Clancy

  This contract was originally developed by Project Wyvern
  (https://github.com/ProjectWyvern/) where it currently enjoys great success as
  a component of the exchange used by OpenSea. It has been modified to support a
  more modern version of Solidity with associated best practices. The
  documentation has also been improved to provide more clarity.
*/
contract TokenRecipient is Context {

  /**
    An event emitted when this contract receives Ether.

    @param sender The sender of the received Ether.
    @param amount The amount of Ether received.
  */
  event ReceivedEther(address indexed sender, uint256 amount);

  /**
    An event emitted when this contract receives ERC-20 tokens.

    @param from The sender of the tokens.
    @param value The amount of token received.
    @param token The address of the token received.
    @param extraData Any extra data associated with the transfer.
  */
  event ReceivedTokens(address indexed from, uint256 value,
    address indexed token, bytes extraData);

  /**
    Receive tokens from address `_from` and emit an event.

    @param _from The address from which tokens are transferred.
    @param _value The amount of tokens to transfer.
    @param _token The address of the tokens to receive.
    @param _extraData Any additional data with this token receipt to emit.
  */
  function receiveApproval(address _from, uint256 _value, address _token,
    bytes calldata _extraData) external {
    bool transferSuccess = IERC20(_token).transferFrom(_from, address(this),
      _value);
    require(transferSuccess,
      "TokenRecipient: failed to transfer tokens from ERC-20");
    emit ReceivedTokens(_from, _value, _token, _extraData);
  }

  /**
    Receive Ether and emit an event.
  */
  receive() external virtual payable {
    emit ReceivedEther(_msgSender(), msg.value);
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./OwnableDelegateProxy.sol";

/**
  @title A call-delegating proxy whose owner may mutate its target.
  @author Protinam, Project Wyvern
  @author Tim Clancy

  This contract was originally developed by Project Wyvern
  (https://github.com/ProjectWyvern/) where it currently enjoys great success as
  a component of the primary exchange contract for OpenSea. It has been modified
  to support a more modern version of Solidity with associated best practices.
  The documentation has also been improved to provide more clarity.
*/
contract OwnableMutableDelegateProxy is OwnableDelegateProxy {

  /// The ERC-897 proxy type: this proxy is mutable.
  uint256 public override constant proxyType = 2;

  /**
    This event is emitted each time the target of this proxy is changed.

    @param previousTarget The previous target of this proxy.
    @param newTarget The new target of this proxy.
  */
  event TargetChanged(address indexed previousTarget,
    address indexed newTarget);

  /**
    Construct this delegate proxy with an owner, initial target, and an initial
    call sent to the target.

    @param _owner The address which should own this proxy.
    @param _target The initial target of this proxy.
    @param _data The initial call to delegate to `_target`.
  */
  constructor (address _owner, address _target, bytes memory _data)
    OwnableDelegateProxy(_owner, _target, _data) { }

  /**
    Allows the owner of this proxy to change the proxy's current target.

    @param _target The new target of this proxy.
  */
  function changeTarget(address _target) public onlyOwner {
    require(proxyType == 2,
      "OwnableDelegateProxy: cannot retarget an immutable proxy");
    require(target != _target,
      "OwnableDelegateProxy: cannot retarget to the current target");
    address oldTarget = target;
    target = _target;

    // Emit an event that this proxy's target has been changed.
    emit TargetChanged(oldTarget, _target);
  }

  /**
    Allows the owner of this proxy to change the proxy's current target and
    immediately delegate a call to the new target.

    @param _target The new target of this proxy.
    @param _data A call to delegate to `_target`.
  */
  function changeTargetAndCall(address _target, bytes calldata _data) external
    onlyOwner {
    changeTarget(_target);
    (bool success, ) = address(this).delegatecall(_data);
    require(success,
      "OwnableDelegateProxy: the call to the new target must succeed");
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./DelegateProxy.sol";

/**
  @title A call-delegating proxy with an owner.
  @author Protinam, Project Wyvern
  @author Tim Clancy
  @author Rostislav Khlebnikov

  This contract was originally developed by Project Wyvern
  (https://github.com/ProjectWyvern/) where it currently enjoys great success as
  a component of the primary exchange contract for OpenSea. It has been modified
  to support a more modern version of Solidity with associated best practices.
  The documentation has also been improved to provide more clarity.

  July 19th, 2021.
*/
abstract contract OwnableDelegateProxy is Ownable, DelegateProxy {

  // Shows if user proxy was initialized
  bool public initialized;
  /// escape slot to match AuthenticatedProxy storage uint8(bool)+uint184 = 192 bits, so target (160 bits) can't be put in this storage slot
  uint184 internal escape;
  /// The address of the proxy's current target.
  address public target;

  /**
    Construct this delegate proxy with an owner, initial target, and an initial
    call sent to the target.

    @param _owner The address which should own this proxy.
    @param _target The initial target of this proxy.
    @param _data The initial call to delegate to `_target`.
  */
  constructor(address _owner, address _target, bytes memory _data) {

    // Do not perform a redundant ownership transfer if the deployer should
    // remain as the owner of this contract.
    if (_owner != owner()) {
      transferOwnership(_owner);
    }
    target = _target;

    // Immediately delegate a call to the initial implementation and require it
    // to succeed. This is often used to trigger some kind of initialization
    // function on the target.
    (bool success, ) = _target.delegatecall(_data);
    require(success,
      "OwnableDelegateProxy: the initial call to target must succeed");
  }

  /**
    Return the current address where all calls to this proxy are delegated. If
    `proxyType()` returns `1`, ERC-897 dictates that this address MUST not
    change.

    @return The current address where calls to this proxy are delegated.
  */
  function implementation() public override view returns (address) {
    return target;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

/**
  @title A basic call-delegating proxy contract which is compliant with the
    current draft version of ERC-897.
  @author Facu Spagnuolo, OpenZeppelin
  @author Protinam, Project Wyvern
  @author Tim Clancy

  This contract was originally developed by OpenZeppelin, then used by
  Project Wyvern (https://github.com/ProjectWyvern/) where it currently enjoys
  great success as a component of the OpenSea exchange system. It has been
  modified to support a more modern version of Solidity with associated best
  practices. The documentation has also been improved to provide more clarity.

  July 19th, 2021.
*/
abstract contract DelegateProxy {

  /**
    The ERC-897 specification seeks to standardize a system of proxy types.

    @return proxyTypeId The type of this proxy. A return value of `1` indicates that this is
      a strictly-forwarding proxy pointed to an unchanging address. A return
      value of `2` indicates that this proxy is upgradeable. The implementation
      address may change at any time based on some arbitrary external logic.
  */
  function proxyType() external virtual pure returns (uint256 proxyTypeId);

  /**
    Return the current address where all calls to this proxy are delegated. If
    `proxyType()` returns `1`, ERC-897 dictates that this address MUST not
    change.

    @return The current address where calls to this proxy are delegated.
  */
  function implementation() public virtual view returns (address);

  /**
    This payable fallback function exists to automatically delegate all calls to
    this proxy to the contract specified from `implementation()`. Anything
    returned from the delegated call will also be returned here.
  */
  fallback() external virtual payable {
    address target = implementation();
    require(target != address(0));

    // Perform the actual call delegation using Yul.
    assembly {
      let ptr := mload(0x40)
      calldatacopy(ptr, 0, calldatasize())
      let result := delegatecall(gas(), target, ptr, calldatasize(), 0, 0)
      let size := returndatasize()
      returndatacopy(ptr, 0, size)

      switch result
      case 0 { revert(ptr, size) }
      default { return(ptr, size) }
    }
  }
}