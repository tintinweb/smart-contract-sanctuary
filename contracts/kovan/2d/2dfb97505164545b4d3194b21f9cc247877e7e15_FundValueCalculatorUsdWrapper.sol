/**
 *Submitted for verification at Etherscan.io on 2021-11-25
*/

// SPDX-License-Identifier: GPL-3.0

// File: contracts/IDispatcher.sol

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity ^0.8.2;

/// @title IDispatcher Interface
/// @author Enzyme Council <[email protected]>
interface IDispatcher {
    function cancelMigration(address _vaultProxy, bool _bypassFailure) external;

    function claimOwnership() external;

    function deployVaultProxy(
        address _vaultLib,
        address _owner,
        address _vaultAccessor,
        string calldata _fundName
    ) external returns (address vaultProxy_);

    function executeMigration(address _vaultProxy, bool _bypassFailure)
        external;

    function getCurrentFundDeployer()
        external
        view
        returns (address currentFundDeployer_);

    function getFundDeployerForVaultProxy(address _vaultProxy)
        external
        view
        returns (address fundDeployer_);

    function getMigrationRequestDetailsForVaultProxy(address _vaultProxy)
        external
        view
        returns (
            address nextFundDeployer_,
            address nextVaultAccessor_,
            address nextVaultLib_,
            uint256 executableTimestamp_
        );

    function getMigrationTimelock()
        external
        view
        returns (uint256 migrationTimelock_);

    function getNominatedOwner()
        external
        view
        returns (address nominatedOwner_);

    function getOwner() external view returns (address owner_);

    function getSharesTokenSymbol()
        external
        view
        returns (string memory sharesTokenSymbol_);

    function getTimelockRemainingForMigrationRequest(address _vaultProxy)
        external
        view
        returns (uint256 secondsRemaining_);

    function hasExecutableMigrationRequest(address _vaultProxy)
        external
        view
        returns (bool hasExecutableRequest_);

    function hasMigrationRequest(address _vaultProxy)
        external
        view
        returns (bool hasMigrationRequest_);

    function removeNominatedOwner() external;

    function setCurrentFundDeployer(address _nextFundDeployer) external;

    function setMigrationTimelock(uint256 _nextTimelock) external;

    function setNominatedOwner(address _nextNominatedOwner) external;

    function setSharesTokenSymbol(string calldata _nextSymbol) external;

    function signalMigration(
        address _vaultProxy,
        address _nextVaultAccessor,
        address _nextVaultLib,
        bool _bypassFailure
    ) external;
}

// File: contracts/IFundValueCalculator.sol

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity ^0.8.2;

/// @title IFundValueCalculator interface
/// @author Enzyme Council <[email protected]>
interface IFundValueCalculator {
    function calcGav(address _vaultProxy)
        external
        returns (address denominationAsset_, uint256 gav_);

    function calcGavInAsset(address _vaultProxy, address _quoteAsset)
        external
        returns (uint256 gav_);

    function calcGrossShareValue(address _vaultProxy)
        external
        returns (address denominationAsset_, uint256 grossShareValue_);

    function calcGrossShareValueInAsset(
        address _vaultProxy,
        address _quoteAsset
    ) external returns (uint256 grossShareValue_);

    function calcNav(address _vaultProxy)
        external
        returns (address denominationAsset_, uint256 nav_);

    function calcNavInAsset(address _vaultProxy, address _quoteAsset)
        external
        returns (uint256 nav_);

    function calcNetShareValue(address _vaultProxy)
        external
        returns (address denominationAsset_, uint256 netShareValue_);

    function calcNetShareValueInAsset(address _vaultProxy, address _quoteAsset)
        external
        returns (uint256 netShareValue_);

    function calcNetValueForSharesHolder(
        address _vaultProxy,
        address _sharesHolder
    ) external returns (address denominationAsset_, uint256 netValue_);

    function calcNetValueForSharesHolderInAsset(
        address _vaultProxy,
        address _sharesHolder,
        address _quoteAsset
    ) external returns (uint256 netValue_);
}

// File: contracts/FundValueCalculatorRouter.sol

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity ^0.8.2;



/// @title FundValueCalculatorRouter Contract
/// @author Enzyme Council <[email protected]>
/// @notice A peripheral contract for routing value calculation requests
/// to the correct FundValueCalculator instance for a particular release
/// @dev These values should generally only be consumed from off-chain,
/// unless you understand how each release interprets each calculation
contract FundValueCalculatorRouter {
    event FundValueCalculatorUpdated(
        address indexed fundDeployer,
        address fundValueCalculator
    );

    address private immutable DISPATCHER;

    mapping(address => address) private fundDeployerToFundValueCalculator;

    constructor(
        address _dispatcher,
        address[] memory _fundDeployers,
        address[] memory _fundValueCalculators
    ) public {
        DISPATCHER = _dispatcher;

        __setFundValueCalculators(_fundDeployers, _fundValueCalculators);
    }

    // EXTERNAL FUNCTIONS

    /// @notice Calculates the GAV for a given fund
    /// @param _vaultProxy The VaultProxy of the fund
    /// @return denominationAsset_ The denomination asset of the fund
    /// @return gav_ The GAV quoted in the denomination asset
    function calcGav(address _vaultProxy)
        external
        returns (address denominationAsset_, uint256 gav_)
    {
        return getFundValueCalculatorForVault(_vaultProxy).calcGav(_vaultProxy);
    }

    /// @notice Calculates the GAV for a given fund, quoted in a given asset
    /// @param _vaultProxy The VaultProxy of the fund
    /// @param _quoteAsset The quote asset
    /// @return gav_ The GAV quoted in _quoteAsset
    function calcGavInAsset(address _vaultProxy, address _quoteAsset)
        external
        returns (uint256 gav_)
    {
        return
            getFundValueCalculatorForVault(_vaultProxy).calcGavInAsset(
                _vaultProxy,
                _quoteAsset
            );
    }

    /// @notice Calculates the gross value of one shares unit (10 ** 18) for a given fund
    /// @param _vaultProxy The VaultProxy of the fund
    /// @return denominationAsset_ The denomination asset of the fund
    /// @return grossShareValue_ The gross share value quoted in the denomination asset
    function calcGrossShareValue(address _vaultProxy)
        external
        returns (address denominationAsset_, uint256 grossShareValue_)
    {
        return
            getFundValueCalculatorForVault(_vaultProxy).calcGrossShareValue(
                _vaultProxy
            );
    }

    /// @notice Calculates the gross value of one shares unit (10 ** 18) for a given fund, quoted in a given asset
    /// @param _vaultProxy The VaultProxy of the fund
    /// @param _quoteAsset The quote asset
    /// @return grossShareValue_ The gross share value quoted in _quoteAsset
    function calcGrossShareValueInAsset(
        address _vaultProxy,
        address _quoteAsset
    ) external returns (uint256 grossShareValue_) {
        return
            getFundValueCalculatorForVault(_vaultProxy)
                .calcGrossShareValueInAsset(_vaultProxy, _quoteAsset);
    }

    /// @notice Calculates the NAV for a given fund
    /// @param _vaultProxy The VaultProxy of the fund
    /// @return denominationAsset_ The denomination asset of the fund
    /// @return nav_ The NAV quoted in the denomination asset
    function calcNav(address _vaultProxy)
        external
        returns (address denominationAsset_, uint256 nav_)
    {
        return getFundValueCalculatorForVault(_vaultProxy).calcNav(_vaultProxy);
    }

    /// @notice Calculates the NAV for a given fund, quoted in a given asset
    /// @param _vaultProxy The VaultProxy of the fund
    /// @param _quoteAsset The quote asset
    /// @return nav_ The NAV quoted in _quoteAsset
    function calcNavInAsset(address _vaultProxy, address _quoteAsset)
        external
        returns (uint256 nav_)
    {
        return
            getFundValueCalculatorForVault(_vaultProxy).calcNavInAsset(
                _vaultProxy,
                _quoteAsset
            );
    }

    /// @notice Calculates the net value of one shares unit (10 ** 18) for a given fund
    /// @param _vaultProxy The VaultProxy of the fund
    /// @return denominationAsset_ The denomination asset of the fund
    /// @return netShareValue_ The net share value quoted in the denomination asset
    function calcNetShareValue(address _vaultProxy)
        external
        returns (address denominationAsset_, uint256 netShareValue_)
    {
        return
            getFundValueCalculatorForVault(_vaultProxy).calcNetShareValue(
                _vaultProxy
            );
    }

    /// @notice Calculates the net value of one shares unit (10 ** 18) for a given fund, quoted in a given asset
    /// @param _vaultProxy The VaultProxy of the fund
    /// @param _quoteAsset The quote asset
    /// @return netShareValue_ The net share value quoted in _quoteAsset
    function calcNetShareValueInAsset(address _vaultProxy, address _quoteAsset)
        external
        returns (uint256 netShareValue_)
    {
        return
            getFundValueCalculatorForVault(_vaultProxy)
                .calcNetShareValueInAsset(_vaultProxy, _quoteAsset);
    }

    /// @notice Calculates the net value of all shares held by a specified account
    /// @param _vaultProxy The VaultProxy of the fund
    /// @param _sharesHolder The account holding shares
    /// @return denominationAsset_ The denomination asset of the fund
    /// @return netValue_ The net value of all shares held by _sharesHolder
    function calcNetValueForSharesHolder(
        address _vaultProxy,
        address _sharesHolder
    ) external returns (address denominationAsset_, uint256 netValue_) {
        return
            getFundValueCalculatorForVault(_vaultProxy)
                .calcNetValueForSharesHolder(_vaultProxy, _sharesHolder);
    }

    /// @notice Calculates the net value of all shares held by a specified account, quoted in a given asset
    /// @param _vaultProxy The VaultProxy of the fund
    /// @param _sharesHolder The account holding shares
    /// @param _quoteAsset The quote asset
    /// @return netValue_ The net value of all shares held by _sharesHolder quoted in _quoteAsset
    function calcNetValueForSharesHolderInAsset(
        address _vaultProxy,
        address _sharesHolder,
        address _quoteAsset
    ) external returns (uint256 netValue_) {
        return
            getFundValueCalculatorForVault(_vaultProxy)
                .calcNetValueForSharesHolderInAsset(
                    _vaultProxy,
                    _sharesHolder,
                    _quoteAsset
                );
    }

    // PUBLIC FUNCTIONS

    /// @notice Gets the FundValueCalculator instance to use for a given fund
    /// @param _vaultProxy The VaultProxy of the fund
    /// @return fundValueCalculatorContract_ The FundValueCalculator instance
    function getFundValueCalculatorForVault(address _vaultProxy)
        public
        view
        returns (IFundValueCalculator fundValueCalculatorContract_)
    {
        address fundDeployer = IDispatcher(DISPATCHER)
            .getFundDeployerForVaultProxy(_vaultProxy);
        require(
            fundDeployer != address(0),
            "getFundValueCalculatorForVault: Invalid _vaultProxy"
        );

        address fundValueCalculator = getFundValueCalculatorForFundDeployer(
            fundDeployer
        );
        require(
            fundValueCalculator != address(0),
            "getFundValueCalculatorForVault: No FundValueCalculator set"
        );

        return IFundValueCalculator(fundValueCalculator);
    }

    ////////////////////////////
    // FUND VALUE CALCULATORS //
    ////////////////////////////

    /// @notice Sets FundValueCalculator instances for a list of FundDeployer instances
    /// @param _fundDeployers The FundDeployer instances
    /// @param _fundValueCalculators The FundValueCalculator instances corresponding
    /// to each instance in _fundDeployers
    function setFundValueCalculators(
        address[] memory _fundDeployers,
        address[] memory _fundValueCalculators
    ) external {
        require(
            msg.sender == IDispatcher(getDispatcher()).getOwner(),
            "Only the Dispatcher owner can call this function"
        );

        __setFundValueCalculators(_fundDeployers, _fundValueCalculators);
    }

    /// @dev Helper to set FundValueCalculator addresses respectively for given FundDeployers
    function __setFundValueCalculators(
        address[] memory _fundDeployers,
        address[] memory _fundValueCalculators
    ) private {
        require(
            _fundDeployers.length == _fundValueCalculators.length,
            "__setFundValueCalculators: Unequal array lengths"
        );

        for (uint256 i; i < _fundDeployers.length; i++) {
            fundDeployerToFundValueCalculator[
                _fundDeployers[i]
            ] = _fundValueCalculators[i];

            emit FundValueCalculatorUpdated(
                _fundDeployers[i],
                _fundValueCalculators[i]
            );
        }
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `DISPATCHER` variable
    /// @return dispatcher_ The `DISPATCHER` variable value
    function getDispatcher() public view returns (address dispatcher_) {
        return DISPATCHER;
    }

    /// @notice Gets the FundValueCalculator address for a given FundDeployer
    /// @param _fundDeployer The FundDeployer for which to get the FundValueCalculator address
    /// @return fundValueCalculator_ The FundValueCalculator address
    function getFundValueCalculatorForFundDeployer(address _fundDeployer)
        public
        view
        returns (address fundValueCalculator_)
    {
        return fundDeployerToFundValueCalculator[_fundDeployer];
    }
}

// File: contracts/FundValueCalculatorUsdWrapper.sol

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity ^0.8.2;


/// @title IChainlinkAggregatorFundValueCalculatorUsdWrapper Interface
/// @author Enzyme Council <[email protected]>
interface IChainlinkAggregatorFundValueCalculatorUsdWrapper {
    function latestRoundData()
        external
        view
        returns (
            uint80,
            int256,
            uint256,
            uint256,
            uint80
        );
}

/// @title FundValueCalculatorUsdWrapper Contract
/// @author Enzyme Council <[email protected]>
/// @notice Wraps the FundValueCalculatorRouter to get fund values with USD as the quote asset
/// @dev USD values are normalized to a precision of 18 decimals.
/// These values should generally only be consumed from off-chain,
/// unless you understand how each release interprets each calculation.
contract FundValueCalculatorUsdWrapper {
    uint256 private constant ETH_USD_AGGREGATOR_DECIMALS = 8;

    address private immutable ETH_USD_AGGREGATOR;
    address private immutable FUND_VALUE_CALCULATOR_ROUTER;
    uint256 private immutable STALE_RATE_THRESHOLD;
    address private immutable WETH_TOKEN;

    constructor(
        address _fundValueCalculatorRouter,
        address _wethToken,
        address _ethUsdAggregator,
        uint256 _staleRateThreshold
    ) {
        ETH_USD_AGGREGATOR = _ethUsdAggregator;
        FUND_VALUE_CALCULATOR_ROUTER = _fundValueCalculatorRouter;
        STALE_RATE_THRESHOLD = _staleRateThreshold;
        WETH_TOKEN = _wethToken;
    }

    // EXTERNAL FUNCTIONS

    /// @notice Calculates the GAV for a given fund in USD
    /// @param _vaultProxy The VaultProxy of the fund
    /// @return gav_ The GAV quoted in USD
    function calcGav(address _vaultProxy) external returns (uint256 gav_) {
        uint256 valueInEth = FundValueCalculatorRouter(
            getFundValueCalculatorRouter()
        ).calcGavInAsset(_vaultProxy, getWethToken());

        return __convertEthToUsd(valueInEth);
    }

    /// @notice Calculates the gross value of one shares unit (10 ** 18) for a given fund in USD
    /// @param _vaultProxy The VaultProxy of the fund
    /// @return grossShareValue_ The gross share value quoted in USD
    function calcGrossShareValue(address _vaultProxy)
        external
        returns (uint256 grossShareValue_)
    {
        uint256 valueInEth = FundValueCalculatorRouter(
            getFundValueCalculatorRouter()
        ).calcGrossShareValueInAsset(_vaultProxy, getWethToken());

        return __convertEthToUsd(valueInEth);
    }

    /// @notice Calculates the NAV for a given fund in USD
    /// @param _vaultProxy The VaultProxy of the fund
    /// @return nav_ The NAV quoted in USD
    function calcNav(address _vaultProxy) external returns (uint256 nav_) {
        uint256 valueInEth = FundValueCalculatorRouter(
            getFundValueCalculatorRouter()
        ).calcNavInAsset(_vaultProxy, getWethToken());

        return __convertEthToUsd(valueInEth);
    }

    /// @notice Calculates the net value of one shares unit (10 ** 18) for a given fund in USD
    /// @param _vaultProxy The VaultProxy of the fund
    /// @return netShareValue_ The net share value quoted in USD
    function calcNetShareValue(address _vaultProxy)
        external
        returns (uint256 netShareValue_)
    {
        uint256 valueInEth = FundValueCalculatorRouter(
            getFundValueCalculatorRouter()
        ).calcNetShareValueInAsset(_vaultProxy, getWethToken());

        return __convertEthToUsd(valueInEth);
    }

    /// @notice Calculates the net value of all shares held by a specified account in USD
    /// @param _vaultProxy The VaultProxy of the fund
    /// @param _sharesHolder The account holding shares
    /// @return netValue_ The net value of all shares held by _sharesHolder quoted in USD
    function calcNetValueForSharesHolder(
        address _vaultProxy,
        address _sharesHolder
    ) external returns (uint256 netValue_) {
        uint256 valueInEth = FundValueCalculatorRouter(
            getFundValueCalculatorRouter()
        ).calcNetValueForSharesHolderInAsset(
                _vaultProxy,
                _sharesHolder,
                getWethToken()
            );

        return __convertEthToUsd(valueInEth);
    }

    /// @dev Helper to convert an ETH amount to USD
    function __convertEthToUsd(uint256 _ethAmount)
        private
        view
        returns (uint256 usdAmount_)
    {
        (
            ,
            int256 usdPerEthRate,
            ,
            uint256 updatedAt,

        ) = getEthUsdAggregatorContract().latestRoundData();
        require(usdPerEthRate > 0, "__convertEthToUsd: Bad ethUsd rate");
        require(
            updatedAt >= block.timestamp - getStaleRateThreshold(),
            "__convertEthToUsd: Stale rate detected"
        );

        return
            (_ethAmount * uint256(usdPerEthRate)) /
            10**ETH_USD_AGGREGATOR_DECIMALS;
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `ETH_USD_AGGREGATOR` variable value
    /// @return ethUsdAggregatorContract_ The `ETH_USD_AGGREGATOR` variable value
    function getEthUsdAggregatorContract()
        public
        view
        returns (
            IChainlinkAggregatorFundValueCalculatorUsdWrapper ethUsdAggregatorContract_
        )
    {
        return
            IChainlinkAggregatorFundValueCalculatorUsdWrapper(
                ETH_USD_AGGREGATOR
            );
    }

    /// @notice Gets the `FUND_VALUE_CALCULATOR_ROUTER` variable
    /// @return fundValueCalculatorRouter_ The `FUND_VALUE_CALCULATOR_ROUTER` variable value
    function getFundValueCalculatorRouter()
        public
        view
        returns (address fundValueCalculatorRouter_)
    {
        return FUND_VALUE_CALCULATOR_ROUTER;
    }

    /// @notice Gets the `STALE_RATE_THRESHOLD` variable value
    /// @return staleRateThreshold_ The `STALE_RATE_THRESHOLD` value
    function getStaleRateThreshold()
        public
        view
        returns (uint256 staleRateThreshold_)
    {
        return STALE_RATE_THRESHOLD;
    }

    /// @notice Gets the `WETH_TOKEN` variable value
    /// @return wethToken_ The `WETH_TOKEN` variable value
    function getWethToken() public view returns (address wethToken_) {
        return WETH_TOKEN;
    }
}