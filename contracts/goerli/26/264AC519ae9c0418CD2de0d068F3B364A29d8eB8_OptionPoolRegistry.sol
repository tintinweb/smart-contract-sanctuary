pragma solidity 0.8.4;

import "../interfaces/IConfigurationManager.sol";
import "../interfaces/IOptionPoolRegistry.sol";

/**
 * @title OptionPoolRegistry
 * @author Pods Finance
 * @notice Tracks the OptionAMMPool instances associated with Options
 */
contract OptionPoolRegistry is IOptionPoolRegistry {
    IConfigurationManager public immutable configurationManager;

    mapping(address => address) private _registry;

    constructor(IConfigurationManager _configurationManager) public {
        configurationManager = _configurationManager;
    }

    modifier onlyAMMFactory {
        require(
            msg.sender == configurationManager.getAMMFactory(),
            "OptionPoolRegistry: caller is not current AMMFactory"
        );
        _;
    }

    /**
     * @notice Returns the address of a previously created pool
     *
     * @dev If the pool is not registered it will return address(0)
     *
     * @param option The address of option token
     * @return The address of the pool
     */
    function getPool(address option) external override view returns (address) {
        return _registry[option];
    }

    /**
     * @notice Register a pool for a given option
     *
     * @param option The address of option token
     * @param pool The address of OptionAMMPool
     */
    function setPool(address option, address pool) external override onlyAMMFactory {
        _registry[option] = pool;
        emit PoolSet(msg.sender, option, pool);
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity >=0.6.12;

interface IConfigurationManager {
    function setParameter(bytes32 name, uint256 value) external;

    function setEmergencyStop(address emergencyStop) external;

    function setPricingMethod(address pricingMethod) external;

    function setIVGuesser(address ivGuesser) external;

    function setIVProvider(address ivProvider) external;

    function setPriceProvider(address priceProvider) external;

    function setCapProvider(address capProvider) external;

    function setAMMFactory(address ammFactory) external;

    function setOptionFactory(address optionFactory) external;

    function setOptionHelper(address optionHelper) external;

    function setOptionPoolRegistry(address optionPoolRegistry) external;

    function getParameter(bytes32 name) external view returns (uint256);

    function owner() external view returns (address);

    function getEmergencyStop() external view returns (address);

    function getPricingMethod() external view returns (address);

    function getIVGuesser() external view returns (address);

    function getIVProvider() external view returns (address);

    function getPriceProvider() external view returns (address);

    function getCapProvider() external view returns (address);

    function getAMMFactory() external view returns (address);

    function getOptionFactory() external view returns (address);

    function getOptionHelper() external view returns (address);

    function getOptionPoolRegistry() external view returns (address);
}

pragma solidity >=0.6.12;

interface IOptionPoolRegistry {
    event PoolSet(address indexed factory, address indexed option, address pool);

    function getPool(address option) external view returns (address);

    function setPool(address option, address pool) external;
}