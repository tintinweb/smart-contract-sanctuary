// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/core/ICoreProperties.sol";
import "../interfaces/core/IContractsRegistry.sol";

import "../helpers/AbstractDependant.sol";
import "./Globals.sol";

contract CoreProperties is ICoreProperties, OwnableUpgradeable {
    CoreParameters public coreParameters;

    function __CoreProperties_init(CoreParameters calldata _coreParameters) external initializer {
        __Ownable_init();

        coreParameters = _coreParameters;
    }

    function setCoreParameters(CoreParameters calldata _coreParameters) external onlyOwner {
        coreParameters = _coreParameters;
    }

    function setMaximumPoolInvestors(uint256 count) external onlyOwner {
        coreParameters.maximumPoolInvestors = count;
    }

    function setMaximumOpenPositions(uint256 count) external onlyOwner {
        coreParameters.maximumOpenPositions = count;
    }

    function setTraderLeverageParams(uint256 threshold, uint256 slope) external onlyOwner {
        coreParameters.leverageThreshold = threshold;
        coreParameters.leverageSlope = slope;
    }

    function setCommissionInitTimestamp(uint256 timestamp) external onlyOwner {
        coreParameters.commissionInitTimestamp = timestamp;
    }

    function setCommissionDurations(uint256[] calldata durations) external onlyOwner {
        coreParameters.commissionDurations = durations;
    }

    function setDEXECommissionPercentages(
        uint256 dexeCommission,
        uint256[] calldata distributionPercentages
    ) external {
        coreParameters.dexeCommissionPercentage = dexeCommission;
        coreParameters.dexeCommissionDistributionPercentages = distributionPercentages;
    }

    function getMaximumPoolInvestors() external view override returns (uint256) {
        return coreParameters.maximumPoolInvestors;
    }

    function getMaximumOpenPositions() external view override returns (uint256) {
        return coreParameters.maximumOpenPositions;
    }

    function getTraderLeverageParams() external view override returns (uint256, uint256) {
        return (coreParameters.leverageThreshold, coreParameters.leverageSlope);
    }

    function getCommissionInitTimestamp() external view override returns (uint256) {
        return coreParameters.commissionInitTimestamp;
    }

    function getCommissionDuration(CommissionPeriod period)
        external
        view
        override
        returns (uint256)
    {
        return coreParameters.commissionDurations[uint256(period)];
    }

    function getDEXECommissionPercentages()
        external
        view
        override
        returns (uint256, uint256[] memory)
    {
        return (
            coreParameters.dexeCommissionPercentage,
            coreParameters.dexeCommissionDistributionPercentages
        );
    }

    function getTraderCommissions() external view override returns (uint256, uint256[] memory) {
        return (coreParameters.minimalTraderCommission, coreParameters.maximalTraderCommissions);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICoreProperties {
    enum CommissionPeriod {
        PERIOD_1,
        PERIOD_2,
        PERIOD_3
    }

    enum CommissionTypes {
        INSURANCE,
        TREASURY,
        DIVIDENDS
    }

    struct CoreParameters {
        uint256 maximumPoolInvestors;
        uint256 maximumOpenPositions;
        uint256 leverageThreshold;
        uint256 leverageSlope;
        uint256 commissionInitTimestamp;
        uint256[] commissionDurations;
        uint256 dexeCommissionPercentage;
        uint256[] dexeCommissionDistributionPercentages;
        uint256 minimalTraderCommission;
        uint256[] maximalTraderCommissions;
    }

    function getMaximumPoolInvestors() external view returns (uint256);

    function getMaximumOpenPositions() external view returns (uint256);

    function getTraderLeverageParams() external view returns (uint256 threshold, uint256 slope);

    function getCommissionInitTimestamp() external view returns (uint256);

    function getCommissionDuration(CommissionPeriod period) external view returns (uint256);

    /// @notice individualPercentages[INSURANCE] - insurance commission
    /// @notice individualPercentages[TREASURY] - treasury commission
    /// @notice individualPercentages[DIVIDENDS] - dividends commission
    function getDEXECommissionPercentages()
        external
        view
        returns (uint256 totalPercentage, uint256[] memory individualPercentages);

    function getTraderCommissions() external view returns (uint256, uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IContractsRegistry {
    function getTraderPoolFactoryContract() external view returns (address);

    function getTraderPoolRegistryContract() external view returns (address);

    function getDEXEContract() external view returns (address);

    function getDAIContract() external view returns (address);

    function getPriceFeedContract() external view returns (address);

    function getUniswapV2RouterContract() external view returns (address);

    function getInsuranceContract() external view returns (address);

    function getTreasuryContract() external view returns (address);

    function getDividendsContract() external view returns (address);

    function getCorePropertiesContract() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/core/IContractsRegistry.sol";

abstract contract AbstractDependant {
    /// @dev keccak256(AbstractDependant.setInjector(address)) - 1
    bytes32 private constant _INJECTOR_SLOT =
        0xd6b8f2e074594ceb05d47c27386969754b6ad0c15e5eb8f691399cd0be980e76;

    modifier onlyInjectorOrZero() {
        address _injector = injector();

        require(_injector == address(0) || _injector == msg.sender, "Dependant: Not an injector");
        _;
    }

    function setInjector(address _injector) external onlyInjectorOrZero {
        bytes32 slot = _INJECTOR_SLOT;

        assembly {
            sstore(slot, _injector)
        }
    }

    /// @dev has to apply onlyInjectorOrZero() modifier
    function setDependencies(IContractsRegistry) external virtual;

    function injector() public view returns (address _injector) {
        bytes32 slot = _INJECTOR_SLOT;

        assembly {
            _injector := sload(slot)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

uint256 constant BLOCKS_PER_DAY = 6450;
uint256 constant SECONDS_IN_DAY = 86400;

uint256 constant SECONDS_IN_MONTH = 30 * 86400;

uint256 constant PERCENTAGE_100 = 10**27;
uint256 constant PRECISION = 10**25;

uint256 constant MAX_UINT = type(uint256).max;

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