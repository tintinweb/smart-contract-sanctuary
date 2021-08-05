// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import {Ownable} from '../../dependencies/openzeppelin/contracts/Ownable.sol';

import {Initializable} from "../../dependencies/openzeppelin/upgradeability/Initializable.sol";

import {ILendingPoolAddressesProvider} from '../../interfaces/ILendingPoolAddressesProvider.sol';

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
contract LendingPoolAddressesProvider is ILendingPoolAddressesProvider, Initializable {
  string private _marketId;
  mapping(bytes32 => address) private _addresses;

  bytes32 private constant LENDING_POOL = 'LENDING_POOL';
  bytes32 private constant LENDING_POOL_CONFIGURATOR = 'LENDING_POOL_CONFIGURATOR';
  bytes32 private constant POOL_ADMIN = 'POOL_ADMIN';
  bytes32 private constant EMERGENCY_ADMIN = 'EMERGENCY_ADMIN';
  bytes32 private constant LENDING_POOL_COLLATERAL_MANAGER = 'COLLATERAL_MANAGER';
  bytes32 private constant PRICE_ORACLE = 'PRICE_ORACLE';
  bytes32 private constant LENDING_RATE_ORACLE = 'LENDING_RATE_ORACLE';

  address public owner;

  modifier onlyOwner(){
    require(msg.sender == owner, "!owner");
    _;
  }

  function init(
    string memory marketId,
    address _collateralManager,
    address _poolAdmin,
    address _oracle,
    address _lendingPoolConfigurator,
    address _lendingPool
  ) external override initializer {
    owner = msg.sender;
    _setMarketId(marketId);
    _addresses[LENDING_POOL_COLLATERAL_MANAGER] = _collateralManager;
    _addresses[POOL_ADMIN] = _poolAdmin;
    _addresses[PRICE_ORACLE] = _oracle;
    _addresses[LENDING_POOL_CONFIGURATOR] = _lendingPoolConfigurator;
    _addresses[LENDING_POOL] = _lendingPool;
  }

  /**
   * @dev Returns the id of the Aave market to which this contracts points to
   * @return The market id
   **/
  function getMarketId() external view override returns (string memory) {
    return _marketId;
  }

  /**
   * @dev Allows to set the market which this LendingPoolAddressesProvider represents
   * @param marketId The market id
   */
  function setMarketId(string memory marketId) external override onlyOwner {
    _setMarketId(marketId);
  }

  // /**
  //  * @dev General function to update the implementation of a proxy registered with
  //  * certain `id`. If there is no proxy registered, it will instantiate one and
  //  * set as implementation the `implementationAddress`
  //  * IMPORTANT Use this function carefully, only for ids that don't have an explicit
  //  * setter function, in order to avoid unexpected consequences
  //  * @param id The id
  //  * @param implementationAddress The address of the new implementation
  //  */
  // function setAddressAsProxy(bytes32 id, address implementationAddress)
  //   external
  //   override
  //   onlyOwner
  // {
  //   _updateImpl(id, implementationAddress);
  //   emit AddressSet(id, implementationAddress, true);
  // }

  /**
   * @dev Sets an address for an id replacing the address saved in the addresses map
   * IMPORTANT Use this function carefully, as it will do a hard replacement
   * @param id The id
   * @param newAddress The address to set
   */
  function setAddress(bytes32 id, address newAddress) external override onlyOwner {
    _addresses[id] = newAddress;
    emit AddressSet(id, newAddress, false);
  }

  /**
   * @dev Returns an address by id
   * @return The address
   */
  function getAddress(bytes32 id) public view override returns (address) {
    return _addresses[id];
  }

  /**
   * @dev Returns the address of the LendingPool proxy
   * @return The LendingPool proxy address
   **/
  function getLendingPool() external view override returns (address) {
    return getAddress(LENDING_POOL);
  }

  /**
   * @dev Updates the implementation of the LendingPool, or creates the proxy
   * setting the new `pool` implementation on the first time calling it
   * @param pool The new LendingPool implementation
   **/
  function setLendingPool(address pool) external override onlyOwner {
    _addresses[LENDING_POOL] = pool;
    emit LendingPoolUpdated(pool);
  }

  /**
   * @dev Returns the address of the LendingPoolConfigurator proxy
   * @return The LendingPoolConfigurator proxy address
   **/
  function getLendingPoolConfigurator() external view override returns (address) {
    return getAddress(LENDING_POOL_CONFIGURATOR);
  }

  /**
   * @dev Updates the implementation of the LendingPoolConfigurator, or creates the proxy
   * setting the new `configurator` implementation on the first time calling it
   * @param configurator The new LendingPoolConfigurator implementation
   **/
  function setLendingPoolConfigurator(address configurator) external override onlyOwner {
    _addresses[LENDING_POOL_CONFIGURATOR] = configurator;
    emit LendingPoolConfiguratorUpdated(configurator);
  }

  /**
   * @dev Returns the address of the LendingPoolCollateralManager. Since the manager is used
   * through delegateCall within the LendingPool contract, the proxy contract pattern does not work properly hence
   * the addresses are changed directly
   * @return The address of the LendingPoolCollateralManager
   **/

  function getLendingPoolCollateralManager() external view override returns (address) {
    return getAddress(LENDING_POOL_COLLATERAL_MANAGER);
  }

  /**
   * @dev Updates the address of the LendingPoolCollateralManager
   * @param manager The new LendingPoolCollateralManager address
   **/
  function setLendingPoolCollateralManager(address manager) external override onlyOwner {
    _addresses[LENDING_POOL_COLLATERAL_MANAGER] = manager;
    emit LendingPoolCollateralManagerUpdated(manager);
  }

  /**
   * @dev The functions below are getters/setters of addresses that are outside the context
   * of the protocol hence the upgradable proxy pattern is not used
   **/

  function getPoolAdmin() external view override returns (address) {
    return getAddress(POOL_ADMIN);
  }

  function setPoolAdmin(address admin) external override onlyOwner {
    _addresses[POOL_ADMIN] = admin;
    emit ConfigurationAdminUpdated(admin);
  }

  function getEmergencyAdmin() external view override returns (address) {
    return getAddress(EMERGENCY_ADMIN);
  }

  function setEmergencyAdmin(address emergencyAdmin) external override onlyOwner {
    _addresses[EMERGENCY_ADMIN] = emergencyAdmin;
    emit EmergencyAdminUpdated(emergencyAdmin);
  }

  function getPriceOracle() external view override returns (address) {
    return getAddress(PRICE_ORACLE);
  }

  function setPriceOracle(address priceOracle) external override onlyOwner {
    _addresses[PRICE_ORACLE] = priceOracle;
    emit PriceOracleUpdated(priceOracle);
  }

  function getLendingRateOracle() external view override returns (address) {
    return getAddress(LENDING_RATE_ORACLE);
  }

  function setLendingRateOracle(address lendingRateOracle) external override onlyOwner {
    _addresses[LENDING_RATE_ORACLE] = lendingRateOracle;
    emit LendingRateOracleUpdated(lendingRateOracle);
  }

  function _setMarketId(string memory marketId) internal {
    _marketId = marketId;
    emit MarketIdSet(marketId);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
  constructor() internal {
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
pragma solidity >=0.4.24 <0.7.0;

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {
  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(
      initializing || isConstructor() || !initialized,
      'Contract instance has already been initialized'
    );

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    uint256 cs;
    //solium-disable-next-line
    assembly {
      cs := extcodesize(address())
    }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
interface ILendingPoolAddressesProvider {
  event MarketIdSet(string newMarketId);
  event LendingPoolUpdated(address indexed newAddress);
  event ConfigurationAdminUpdated(address indexed newAddress);
  event EmergencyAdminUpdated(address indexed newAddress);
  event LendingPoolConfiguratorUpdated(address indexed newAddress);
  event LendingPoolCollateralManagerUpdated(address indexed newAddress);
  event PriceOracleUpdated(address indexed newAddress);
  event LendingRateOracleUpdated(address indexed newAddress);
  event ProxyCreated(bytes32 id, address indexed newAddress);
  event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

  function init(    
    string memory marketId,
    address _collateralManager,
    address _poolAdmin,
    address _oracle,
    address _lendingPoolConfigurator,
    address _lendingPool) external;

  function getMarketId() external view returns (string memory);

  function setMarketId(string calldata marketId) external;

  function setAddress(bytes32 id, address newAddress) external;

  function getAddress(bytes32 id) external view returns (address);

  function getLendingPool() external view returns (address);

  function setLendingPool(address pool) external;

  function getLendingPoolConfigurator() external view returns (address);

  function setLendingPoolConfigurator(address configurator) external;

  function getLendingPoolCollateralManager() external view returns (address);

  function setLendingPoolCollateralManager(address manager) external;

  function getPoolAdmin() external view returns (address);

  function setPoolAdmin(address admin) external;

  function getEmergencyAdmin() external view returns (address);

  function setEmergencyAdmin(address admin) external;

  function getPriceOracle() external view returns (address);

  function setPriceOracle(address priceOracle) external;

  function getLendingRateOracle() external view returns (address);

  function setLendingRateOracle(address lendingRateOracle) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

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
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}