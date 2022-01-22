// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.0;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {IAddressesProvider} from "./IAddressesProvider.sol";
import "../proxy/Proxiable.sol";

/**
 * @title AddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * @author Dakra-Mystic
 **/
contract AddressesProvider is
    IAddressesProvider,
    Proxiable,
    OwnableUpgradeable
{
    mapping(bytes32 => address) private _addresses;

    bytes32 private constant PRICE_ORACLE = "PRICE_ORACLE";
    bytes32 private constant AMM_DATA_PROVIDER = "AMM_DATA_PROVIDER";
    bytes32 private constant SERIES_CONTROLLER = "SERIES_CONTROLLER";
    bytes32 private constant VOLATILITY_ORACLE = "VOLATILITY_ORACLE";
    bytes32 private constant BLACKSCHOLES = "BLACKSCHOLES";
    bytes32 private constant AIRSWAP_LIGHT = "AIRSWAP_LIGHT";
    bytes32 private constant AMM_FACTORY = "AMM_FACTORY";
    bytes32 private constant DIRECT_BUY_MANAGER = "DIRECT_BUY_MANAGER";
    bytes32 private constant WTOKEN_VAULT = "WTOKEN_VAULT";
    bytes32 private constant AMM_CONFIG = "AMM_CONFIG";

    ///////////////////// MUTATING FUNCTIONS /////////////////////

    /// @notice Perform inherited contracts' initializations
    function __AddressessProvider_init() external initializer {
        __Ownable_init_unchained();
    }

    /// @notice update the logic contract for this proxy contract
    /// @param _newImplementation the address of the new AddressesProvider implementation
    /// @dev only the admin address may call this function
    function updateImplementation(address _newImplementation)
        external
        onlyOwner
    {
        require(
            _newImplementation != address(0x0),
            "Invalid _newImplementation address"
        );
        _updateCodeAddress(_newImplementation);
    }

    /**
     * @dev Sets an address for an id replacing the address saved in the addresses map
     * IMPORTANT Use this function carefully, as it will do a hard replacement
     * @param id The id
     * @param newAddress The address to set
     */
    function setAddress(bytes32 id, address newAddress)
        external
        override
        onlyOwner
    {
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
     * @dev The functions below are getters/setters of addresses that are outside the context
     * of the protocol hence the upgradable proxy pattern is not used
     **/

    function getPriceOracle() external view override returns (address) {
        return getAddress(PRICE_ORACLE);
    }

    function setPriceOracle(address priceOracle) external override onlyOwner {
        _addresses[PRICE_ORACLE] = priceOracle;
        emit PriceOracleUpdated(priceOracle);
    }

    function getAmmDataProvider() external view override returns (address) {
        return getAddress(AMM_DATA_PROVIDER);
    }

    function setAmmDataProvider(address ammDataProvider)
        external
        override
        onlyOwner
    {
        _addresses[AMM_DATA_PROVIDER] = ammDataProvider;
        emit AmmDataProviderUpdated(ammDataProvider);
    }

    function getSeriesController() external view override returns (address) {
        return getAddress(SERIES_CONTROLLER);
    }

    function setSeriesController(address seriesController)
        external
        override
        onlyOwner
    {
        _addresses[SERIES_CONTROLLER] = seriesController;
        emit SeriesControllerUpdated(seriesController);
    }

    function getVolatilityOracle() external view override returns (address) {
        return getAddress(VOLATILITY_ORACLE);
    }

    function setVolatilityOracle(address volatilityOracle)
        external
        override
        onlyOwner
    {
        _addresses[VOLATILITY_ORACLE] = volatilityOracle;
        emit VolatilityOracleUpdated(volatilityOracle);
    }

    function getBlackScholes() external view override returns (address) {
        return getAddress(BLACKSCHOLES);
    }

    function setBlackScholes(address blackScholes) external override onlyOwner {
        _addresses[BLACKSCHOLES] = blackScholes;
        emit BlackScholesUpdated(blackScholes);
    }

    function getAirswapLight() external view override returns (address) {
        return getAddress(AIRSWAP_LIGHT);
    }

    function setAirswapLight(address airswapLight) external override onlyOwner {
        _addresses[AIRSWAP_LIGHT] = airswapLight;
        emit AirswapLightUpdated(airswapLight);
    }

    function getAmmFactory() external view override returns (address) {
        return getAddress(AMM_FACTORY);
    }

    function setAmmFactory(address ammFactory) external override onlyOwner {
        _addresses[AMM_FACTORY] = ammFactory;
        emit AmmFactoryUpdated(ammFactory);
    }

    function getDirectBuyManager() external view override returns (address) {
        return getAddress(DIRECT_BUY_MANAGER);
    }

    function setDirectBuyManager(address directBuyManager)
        external
        override
        onlyOwner
    {
        _addresses[DIRECT_BUY_MANAGER] = directBuyManager;
        emit DirectBuyManagerUpdated(directBuyManager);
    }

    function getWTokenVault() external view override returns (address) {
        return getAddress(WTOKEN_VAULT);
    }

    function setWTokenVault(address wTokenVault) external override onlyOwner {
        _addresses[WTOKEN_VAULT] = wTokenVault;
        emit WTokenVaultUpdated(wTokenVault);
    }

    function getAmmConfig() external view override returns (address) {
        return getAddress(AMM_CONFIG);
    }

    function setAmmConfig(address ammConfig) external override onlyOwner {
        _addresses[AMM_CONFIG] = ammConfig;
        emit AmmConfigUpdated(ammConfig);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.0;

/**
 * @title IAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * @author Dakra-Mystic
 **/
interface IAddressesProvider {
    event ConfigurationAdminUpdated(address indexed newAddress);
    event EmergencyAdminUpdated(address indexed newAddress);
    event PriceOracleUpdated(address indexed newAddress);
    event AmmDataProviderUpdated(address indexed newAddress);
    event SeriesControllerUpdated(address indexed newAddress);
    event LendingRateOracleUpdated(address indexed newAddress);
    event DirectBuyManagerUpdated(address indexed newAddress);
    event ProxyCreated(bytes32 id, address indexed newAddress);
    event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);
    event VolatilityOracleUpdated(address indexed newAddress);
    event BlackScholesUpdated(address indexed newAddress);
    event AirswapLightUpdated(address indexed newAddress);
    event AmmFactoryUpdated(address indexed newAddress);    
    event WTokenVaultUpdated(address indexed newAddress);
    event AmmConfigUpdated(address indexed newAddress);

    function setAddress(bytes32 id, address newAddress) external;

    function getAddress(bytes32 id) external view returns (address);

    function getPriceOracle() external view returns (address);

    function setPriceOracle(address priceOracle) external;

    function getAmmDataProvider() external view returns (address);

    function setAmmDataProvider(address ammDataProvider) external;

    function getSeriesController() external view returns (address);

    function setSeriesController(address seriesController) external;

    function getVolatilityOracle() external view returns (address);

    function setVolatilityOracle(address volatilityOracle) external;

    function getBlackScholes() external view returns (address);

    function setBlackScholes(address blackScholes) external;

    function getAirswapLight() external view returns (address);

    function setAirswapLight(address airswapLight) external;

    function getAmmFactory() external view returns (address);

    function setAmmFactory(address ammFactory) external;

    function getDirectBuyManager() external view returns (address);

    function setDirectBuyManager(address directBuyManager) external;

    function getWTokenVault() external view returns (address);

    function setWTokenVault(address wTokenVault) external;

    function getAmmConfig() external view returns (address);

    function setAmmConfig(address ammConfig) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.0;

contract Proxiable {
    // Code position in storage is keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"
    uint256 constant PROXY_MEM_SLOT =
        0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7;

    event CodeAddressUpdated(address newAddress);

    function _updateCodeAddress(address newAddress) internal {
        require(
            bytes32(PROXY_MEM_SLOT) == Proxiable(newAddress).proxiableUUID(),
            "Not compatible"
        );
        assembly {
            // solium-disable-line
            sstore(PROXY_MEM_SLOT, newAddress)
        }

        emit CodeAddressUpdated(newAddress);
    }

    function getLogicAddress() public view returns (address logicAddress) {
        assembly {
            // solium-disable-line
            logicAddress := sload(PROXY_MEM_SLOT)
        }
    }

    function proxiableUUID() public pure returns (bytes32) {
        return bytes32(PROXY_MEM_SLOT);
    }
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