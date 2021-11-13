// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

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
    // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
    // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
    // for accounts without code, i.e. `keccak256('')`
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      codehash := extcodehash(account)
    }
    return (codehash != accountHash && codehash != 0x0);
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
    require(address(this).balance >= amount, 'Address: insufficient balance');

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{value: amount}('');
    require(success, 'Address: unable to send value, recipient may have reverted');
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import './Context.sol';

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
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), 'Ownable: caller is not the owner');
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
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

import './Proxy.sol';
import '../contracts/Address.sol';

/**
 * @title BaseUpgradeabilityProxy
 * @dev This contract implements a proxy that allows to change the
 * implementation address to which it will delegate.
 * Such a change is called an implementation upgrade.
 */
contract BaseUpgradeabilityProxy is Proxy {
  /**
   * @dev Emitted when the implementation is upgraded.
   * @param implementation Address of the new implementation.
   */
  event Upgraded(address indexed implementation);

  /**
   * @dev Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 internal constant IMPLEMENTATION_SLOT =
    0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  /**
   * @dev Returns the current implementation.
   * @return impl Address of the current implementation
   */
  function _implementation() internal view override returns (address impl) {
    bytes32 slot = IMPLEMENTATION_SLOT;
    //solium-disable-next-line
    assembly {
      impl := sload(slot)
    }
  }

  /**
   * @dev Upgrades the proxy to a new implementation.
   * @param newImplementation Address of the new implementation.
   */
  function _upgradeTo(address newImplementation) internal {
    _setImplementation(newImplementation);
    emit Upgraded(newImplementation);
  }

  /**
   * @dev Sets the implementation address of the proxy.
   * @param newImplementation Address of the new implementation.
   */
  function _setImplementation(address newImplementation) internal {
    require(
      Address.isContract(newImplementation),
      'Cannot set a proxy implementation to a non-contract address'
    );

    bytes32 slot = IMPLEMENTATION_SLOT;

    //solium-disable-next-line
    assembly {
      sstore(slot, newImplementation)
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

import './BaseUpgradeabilityProxy.sol';

/**
 * @title InitializableUpgradeabilityProxy
 * @dev Extends BaseUpgradeabilityProxy with an initializer for initializing
 * implementation and init data.
 */
contract InitializableUpgradeabilityProxy is BaseUpgradeabilityProxy {
  /**
   * @dev Contract initializer.
   * @param _logic Address of the initial implementation.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  function initialize(address _logic, bytes memory _data) public payable {
    require(_implementation() == address(0));
    assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1));
    _setImplementation(_logic);
    if (_data.length > 0) {
      (bool success, ) = _logic.delegatecall(_data);
      require(success);
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

/**
 * @title Proxy
 * @dev Implements delegation of calls to other contracts, with proper
 * forwarding of return values and bubbling of failures.
 * It defines a fallback function that delegates all calls to the address
 * returned by the abstract _implementation() internal function.
 */
abstract contract Proxy {
  /**
   * @dev Fallback function.
   * Will run if no other function in the contract matches the call data.
   * Implemented entirely in `_fallback`.
   */
  fallback() external payable {
    _fallback();
  }

  /**
   * @return The Address of the implementation.
   */
  function _implementation() internal view virtual returns (address);

  /**
   * @dev Delegates execution to an implementation contract.
   * This is a low level function that doesn't return to its internal call site.
   * It will return to the external caller whatever the implementation returns.
   * @param implementation Address to delegate.
   */
  function _delegate(address implementation) internal {
    //solium-disable-next-line
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
   * @dev Function that is run as the first thing in the fallback function.
   * Can be redefined in derived contracts to add functionality.
   * Redefinitions must call super._willFallback().
   */
  function _willFallback() internal virtual {}

  /**
   * @dev fallback implementation.
   * Extracted to enable manual triggering.
   */
  function _fallback() internal {
    _willFallback();
    _delegate(_implementation());
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

/**
 * @title IPoolAddressesProvider
 * @author Aave
 * @notice Defines the basic interface for a Pool Addresses Provider.
 **/
interface IPoolAddressesProvider {
  event MarketIdSet(string newMarketId);
  event PoolUpdated(address indexed newAddress);
  event PoolConfiguratorUpdated(address indexed newAddress);
  event PriceOracleUpdated(address indexed newAddress);
  event ACLManagerUpdated(address indexed newAddress);
  event ACLAdminUpdated(address indexed newAddress);
  event PriceOracleSentinelUpdated(address indexed newAddress);
  event ProxyCreated(bytes32 id, address indexed newAddress);
  event BridgeAccessControlUpdated(address indexed newAddress);
  event PoolDataProviderUpdated(address indexed newAddress);
  event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

  /**
   * @notice Returns the id of the Aave market to which this contract points to
   * @return The market id
   **/
  function getMarketId() external view returns (string memory);

  /**
   * @notice Allows to set the market which this PoolAddressesProvider represents
   * @param marketId The market id
   */
  function setMarketId(string calldata marketId) external;

  /**
   * @notice Sets an address for an id replacing the address saved in the addresses map
   * @dev IMPORTANT Use this function carefully, as it will do a hard replacement
   * @param id The id
   * @param newAddress The address to set
   */
  function setAddress(bytes32 id, address newAddress) external;

  /**
   * @notice General function to update the implementation of a proxy registered with
   * certain `id`. If there is no proxy registered, it will instantiate one and
   * set as implementation the `impl`
   * @dev IMPORTANT Use this function carefully, only for ids that don't have an explicit
   * setter function, in order to avoid unexpected consequences
   * @param id The id
   * @param impl The address of the new implementation
   */
  function setAddressAsProxy(bytes32 id, address impl) external;

  /**
   * @notice Returns an address by id
   * @return The address
   */
  function getAddress(bytes32 id) external view returns (address);

  /**
   * @notice Returns the address of the Pool proxy
   * @return The Pool proxy address
   **/
  function getPool() external view returns (address);

  /**
   * @notice Updates the implementation of the Pool, or creates the proxy
   * setting the new `pool` implementation on the first time calling it
   * @param pool The new Pool implementation
   **/
  function setPoolImpl(address pool) external;

  /**
   * @notice Returns the address of the PoolConfigurator proxy
   * @return The PoolConfigurator proxy address
   **/
  function getPoolConfigurator() external view returns (address);

  /**
   * @notice Updates the implementation of the PoolConfigurator, or creates the proxy
   * setting the new `configurator` implementation on the first time calling it
   * @param configurator The new PoolConfigurator implementation
   **/
  function setPoolConfiguratorImpl(address configurator) external;

  function getPriceOracle() external view returns (address);

  function setPriceOracle(address priceOracle) external;

  /**
   * @notice Returns the address of the ACL manager proxy
   * @return The ACLManager proxy address
   */
  function getACLManager() external view returns (address);

  /**
   * @notice Updates the address of the ACLManager
   * @param aclManager The address of the new ACLManager
   **/
  function setACLManager(address aclManager) external;

  /**
   * @notice Returns the address of the ACL admin
   * @return The address of the ACL admin
   */
  function getACLAdmin() external view returns (address);

  /**
   * @notice Updates the address of the ACL admin
   * @param aclAdmin The address of the new ACL admin
   */
  function setACLAdmin(address aclAdmin) external;

  /**
   * @notice Returns the address of the PriceOracleSentinel
   * @return The PriceOracleSentinel address
   */
  function getPriceOracleSentinel() external view returns (address);

  /**
   * @notice Updates the address of the PriceOracleSentinel
   * @param oracleSentinel The address of the new PriceOracleSentinel
   **/
  function setPriceOracleSentinel(address oracleSentinel) external;

  /**
   * @notice Updates the address of the DataProvider
   * @param dataProvider The address of the new DataProvider
   **/
  function setPoolDataProvider(address dataProvider) external;

  /**
   * @notice Returns the address of the DataProvider
   * @return The DataProvider address
   */
  function getPoolDataProvider() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

import {Ownable} from '../../dependencies/openzeppelin/contracts/Ownable.sol';
import {InitializableImmutableAdminUpgradeabilityProxy} from '../libraries/aave-upgradeability/InitializableImmutableAdminUpgradeabilityProxy.sol';
import {IPoolAddressesProvider} from '../../interfaces/IPoolAddressesProvider.sol';

/**
 * @title PoolAddressesProvider
 * @author Aave
 * @notice Main registry of addresses part of or connected to the protocol, including permissioned roles
 * @dev Acts as factory of proxies and admin of those, so with right to change its implementations
 * @dev Owned by the Aave Governance
 **/
contract PoolAddressesProvider is Ownable, IPoolAddressesProvider {
  string private _marketId;
  mapping(bytes32 => address) private _addresses;

  bytes32 private constant POOL = 'POOL';
  bytes32 private constant POOL_CONFIGURATOR = 'POOL_CONFIGURATOR';
  bytes32 private constant PRICE_ORACLE = 'PRICE_ORACLE';
  bytes32 private constant ACL_MANAGER = 'ACL_MANAGER';
  bytes32 private constant ACL_ADMIN = 'ACL_ADMIN';
  bytes32 private constant PRICE_ORACLE_SENTINEL = 'PRICE_ORACLE_SENTINEL';
  bytes32 private constant DATA_PROVIDER = 'DATA_PROVIDER';

  constructor(string memory marketId) {
    _setMarketId(marketId);
  }

  /// @inheritdoc IPoolAddressesProvider
  function getMarketId() external view override returns (string memory) {
    return _marketId;
  }

  /// @inheritdoc IPoolAddressesProvider
  function setMarketId(string memory marketId) external override onlyOwner {
    _setMarketId(marketId);
  }

  /// @inheritdoc IPoolAddressesProvider
  function setAddressAsProxy(bytes32 id, address implementationAddress)
    external
    override
    onlyOwner
  {
    _updateImpl(id, implementationAddress);
    emit AddressSet(id, implementationAddress, true);
  }

  /// @inheritdoc IPoolAddressesProvider
  function setAddress(bytes32 id, address newAddress) external override onlyOwner {
    _addresses[id] = newAddress;
    emit AddressSet(id, newAddress, false);
  }

  /// @inheritdoc IPoolAddressesProvider
  function getAddress(bytes32 id) public view override returns (address) {
    return _addresses[id];
  }

  /// @inheritdoc IPoolAddressesProvider
  function getPool() external view override returns (address) {
    return getAddress(POOL);
  }

  /// @inheritdoc IPoolAddressesProvider
  function setPoolImpl(address pool) external override onlyOwner {
    _updateImpl(POOL, pool);
    emit PoolUpdated(pool);
  }

  /// @inheritdoc IPoolAddressesProvider
  function getPoolConfigurator() external view override returns (address) {
    return getAddress(POOL_CONFIGURATOR);
  }

  /// @inheritdoc IPoolAddressesProvider
  function setPoolConfiguratorImpl(address configurator) external override onlyOwner {
    _updateImpl(POOL_CONFIGURATOR, configurator);
    emit PoolConfiguratorUpdated(configurator);
  }

  function getPriceOracle() external view override returns (address) {
    return getAddress(PRICE_ORACLE);
  }

  function setPriceOracle(address priceOracle) external override onlyOwner {
    _addresses[PRICE_ORACLE] = priceOracle;
    emit PriceOracleUpdated(priceOracle);
  }

  /// @inheritdoc IPoolAddressesProvider
  function getACLManager() external view override returns (address) {
    return getAddress(ACL_MANAGER);
  }

  /// @inheritdoc IPoolAddressesProvider
  function setACLManager(address aclManager) external override onlyOwner {
    _addresses[ACL_MANAGER] = aclManager;
    emit ACLManagerUpdated(aclManager);
  }

  /// @inheritdoc IPoolAddressesProvider
  function getACLAdmin() external view override returns (address) {
    return getAddress(ACL_ADMIN);
  }

  /// @inheritdoc IPoolAddressesProvider
  function setACLAdmin(address aclAdmin) external override onlyOwner {
    _addresses[ACL_ADMIN] = aclAdmin;
    emit ACLAdminUpdated(aclAdmin);
  }

  /// @inheritdoc IPoolAddressesProvider
  function setPriceOracleSentinel(address oracleSentinel) external override onlyOwner {
    _addresses[PRICE_ORACLE_SENTINEL] = oracleSentinel;
    emit PriceOracleSentinelUpdated(oracleSentinel);
  }

  /// @inheritdoc IPoolAddressesProvider
  function getPriceOracleSentinel() external view override returns (address) {
    return getAddress(PRICE_ORACLE_SENTINEL);
  }

  /// @inheritdoc IPoolAddressesProvider
  function setPoolDataProvider(address dataProvider) external override onlyOwner {
    _addresses[DATA_PROVIDER] = dataProvider;
    emit PoolDataProviderUpdated(dataProvider);
  }

  /// @inheritdoc IPoolAddressesProvider
  function getPoolDataProvider() external view override returns (address) {
    return getAddress(DATA_PROVIDER);
  }

  /**
   * @notice Internal function to update the implementation of a specific proxied component of the protocol
   * @dev If there is no proxy registered in the given `id`, it creates the proxy setting `newAdress`
   *   as implementation and calls the initialize() function on the proxy
   * @dev If there is already a proxy registered, it just updates the implementation to `newAddress` and
   *   calls the initialize() function via upgradeToAndCall() in the proxy
   * @param id The id of the proxy to be updated
   * @param newAddress The address of the new implementation
   **/
  function _updateImpl(bytes32 id, address newAddress) internal {
    address payable proxyAddress = payable(_addresses[id]);

    InitializableImmutableAdminUpgradeabilityProxy proxy = InitializableImmutableAdminUpgradeabilityProxy(
        proxyAddress
      );
    bytes memory params = abi.encodeWithSignature('initialize(address)', address(this));

    if (proxyAddress == address(0)) {
      proxy = new InitializableImmutableAdminUpgradeabilityProxy(address(this));
      _addresses[id] = address(proxy);
      proxy.initialize(newAddress, params);
      emit ProxyCreated(id, address(proxy));
    } else {
      proxy.upgradeToAndCall(newAddress, params);
    }
  }

  function _setMarketId(string memory marketId) internal {
    _marketId = marketId;
    emit MarketIdSet(marketId);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

import {BaseUpgradeabilityProxy} from '../../../dependencies/openzeppelin/upgradeability/BaseUpgradeabilityProxy.sol';

/**
 * @title BaseImmutableAdminUpgradeabilityProxy
 * @author Aave, inspired by the OpenZeppelin upgradeability proxy pattern
 * @notice This contract combines an upgradeability proxy with an authorization
 * mechanism for administrative tasks.
 * @dev The admin role is stored in an immutable, which helps saving transactions costs
 * All external functions in this contract must be guarded by the
 * `ifAdmin` modifier. See ethereum/solidity#3864 for a Solidity
 * feature proposal that would enable this to be done automatically.
 */
contract BaseImmutableAdminUpgradeabilityProxy is BaseUpgradeabilityProxy {
  address immutable ADMIN;

  constructor(address admin) {
    ADMIN = admin;
  }

  modifier ifAdmin() {
    if (msg.sender == ADMIN) {
      _;
    } else {
      _fallback();
    }
  }

  /**
   * @notice Return the admin address
   * @return The address of the proxy admin.
   */
  function admin() external ifAdmin returns (address) {
    return ADMIN;
  }

  /**
   * @notice Return the implementation address
   * @return The address of the implementation.
   */
  function implementation() external ifAdmin returns (address) {
    return _implementation();
  }

  /**
   * @notice Upgrade the backing implementation of the proxy.
   * @dev Only the admin can call this function.
   * @param newImplementation The address of the new implementation.
   */
  function upgradeTo(address newImplementation) external ifAdmin {
    _upgradeTo(newImplementation);
  }

  /**
   * @notice Upgrade the backing implementation of the proxy and call a function
   * on the new implementation.
   * @dev This is useful to initialize the proxied contract.
   * @param newImplementation The address of the new implementation.
   * @param data Data to send as msg.data in the low level call.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   */
  function upgradeToAndCall(address newImplementation, bytes calldata data)
    external
    payable
    ifAdmin
  {
    _upgradeTo(newImplementation);
    (bool success, ) = newImplementation.delegatecall(data);
    require(success);
  }

  /**
   * @notice Only fall back when the sender is not the admin.
   */
  function _willFallback() internal virtual override {
    require(msg.sender != ADMIN, 'Cannot call fallback function from the proxy admin');
    super._willFallback();
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

import {InitializableUpgradeabilityProxy} from '../../../dependencies/openzeppelin/upgradeability/InitializableUpgradeabilityProxy.sol';
import {Proxy} from '../../../dependencies/openzeppelin/upgradeability/Proxy.sol';
import {BaseImmutableAdminUpgradeabilityProxy} from './BaseImmutableAdminUpgradeabilityProxy.sol';

/**
 * @title InitializableAdminUpgradeabilityProxy
 * @author Aave
 * @dev Extends BaseAdminUpgradeabilityProxy with an initializer function
 */
contract InitializableImmutableAdminUpgradeabilityProxy is
  BaseImmutableAdminUpgradeabilityProxy,
  InitializableUpgradeabilityProxy
{
  constructor(address admin) BaseImmutableAdminUpgradeabilityProxy(admin) {}

  /// @inheritdoc BaseImmutableAdminUpgradeabilityProxy
  function _willFallback() internal override(BaseImmutableAdminUpgradeabilityProxy, Proxy) {
    BaseImmutableAdminUpgradeabilityProxy._willFallback();
  }
}