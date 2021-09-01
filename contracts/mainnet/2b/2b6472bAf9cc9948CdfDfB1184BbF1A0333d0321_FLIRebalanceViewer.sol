/*
    Copyright 2021 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Math } from "@openzeppelin/contracts/math/Math.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/SafeCast.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { BaseExtension } from "../lib/BaseExtension.sol";
import { IBaseManager } from "../interfaces/IBaseManager.sol";
import { IChainlinkAggregatorV3 } from "../interfaces/IChainlinkAggregatorV3.sol";
import { ILeverageModule } from "../interfaces/ILeverageModule.sol";
import { IProtocolDataProvider } from "../interfaces/IProtocolDataProvider.sol";
import { ISetToken } from "../interfaces/ISetToken.sol";
import { PreciseUnitMath } from "../lib/PreciseUnitMath.sol";
import { StringArrayUtils } from "../lib/StringArrayUtils.sol";


/**
 * @title AaveLeverageStrategyExtension
 * @author Set Protocol
 *
 * Smart contract that enables trustless leverage tokens. This extension is paired with the AaveLeverageModule from Set protocol where module 
 * interactions are invoked via the IBaseManager contract. Any leveraged token can be constructed as long as the collateral and borrow asset 
 * is available on Aave. This extension contract also allows the operator to set an ETH reward to incentivize keepers calling the rebalance
 * function at different leverage thresholds.
 *
 */
contract AaveLeverageStrategyExtension is BaseExtension {
    using Address for address;
    using PreciseUnitMath for uint256;
    using SafeMath for uint256;
    using SafeCast for int256;
    using StringArrayUtils for string[];

    /* ============ Enums ============ */

    enum ShouldRebalance {
        NONE,                   // Indicates no rebalance action can be taken
        REBALANCE,              // Indicates rebalance() function can be successfully called
        ITERATE_REBALANCE,      // Indicates iterateRebalance() function can be successfully called
        RIPCORD                 // Indicates ripcord() function can be successfully called
    }

    /* ============ Structs ============ */

    struct ActionInfo {
        uint256 collateralBalance;                      // Balance of underlying held in Aave in base units (e.g. USDC 10e6)
        uint256 borrowBalance;                          // Balance of underlying borrowed from Aave in base units
        uint256 collateralValue;                        // Valuation in USD adjusted for decimals in precise units (10e18)
        uint256 borrowValue;                            // Valuation in USD adjusted for decimals in precise units (10e18)
        uint256 collateralPrice;                        // Price of collateral in precise units (10e18) from Chainlink
        uint256 borrowPrice;                            // Price of borrow asset in precise units (10e18) from Chainlink
        uint256 setTotalSupply;                         // Total supply of SetToken
    }

     struct LeverageInfo {
        ActionInfo action;
        uint256 currentLeverageRatio;                   // Current leverage ratio of Set
        uint256 slippageTolerance;                      // Allowable percent trade slippage in preciseUnits (1% = 10^16)
        uint256 twapMaxTradeSize;                       // Max trade size in collateral units allowed for rebalance action
        string exchangeName;                            // Exchange to use for trade
    }

    struct ContractSettings {
        ISetToken setToken;                             // Instance of leverage token
        ILeverageModule leverageModule;                 // Instance of Aave leverage module
        IProtocolDataProvider aaveProtocolDataProvider; // Instance of Aave protocol data provider
        IChainlinkAggregatorV3 collateralPriceOracle;   // Chainlink oracle feed that returns prices in 8 decimals for collateral asset
        IChainlinkAggregatorV3 borrowPriceOracle;       // Chainlink oracle feed that returns prices in 8 decimals for borrow asset
        IERC20 targetCollateralAToken;                  // Instance of target collateral aToken asset
        IERC20 targetBorrowDebtToken;                   // Instance of target borrow variable debt token asset
        address collateralAsset;                        // Address of underlying collateral
        address borrowAsset;                            // Address of underlying borrow asset
        uint256 collateralDecimalAdjustment;            // Decimal adjustment for chainlink oracle of the collateral asset. Equal to 28-collateralDecimals (10^18 * 10^18 / 10^decimals / 10^8)
        uint256 borrowDecimalAdjustment;                // Decimal adjustment for chainlink oracle of the borrowing asset. Equal to 28-borrowDecimals (10^18 * 10^18 / 10^decimals / 10^8)
    }

    struct MethodologySettings {
        uint256 targetLeverageRatio;                     // Long term target ratio in precise units (10e18)
        uint256 minLeverageRatio;                        // In precise units (10e18). If current leverage is below, rebalance target is this ratio
        uint256 maxLeverageRatio;                        // In precise units (10e18). If current leverage is above, rebalance target is this ratio
        uint256 recenteringSpeed;                        // % at which to rebalance back to target leverage in precise units (10e18)
        uint256 rebalanceInterval;                       // Period of time required since last rebalance timestamp in seconds
    }

    struct ExecutionSettings {
        uint256 unutilizedLeveragePercentage;            // Percent of max borrow left unutilized in precise units (1% = 10e16)
        uint256 slippageTolerance;                       // % in precise units to price min token receive amount from trade quantities
        uint256 twapCooldownPeriod;                      // Cooldown period required since last trade timestamp in seconds
    }

    struct ExchangeSettings {
        uint256 twapMaxTradeSize;                        // Max trade size in collateral base units
        uint256 exchangeLastTradeTimestamp;              // Timestamp of last trade made with this exchange
        uint256 incentivizedTwapMaxTradeSize;            // Max trade size for incentivized rebalances in collateral base units
        bytes leverExchangeData;                         // Arbitrary exchange data passed into rebalance function for levering up
        bytes deleverExchangeData;                       // Arbitrary exchange data passed into rebalance function for delevering
    }

    struct IncentiveSettings {
        uint256 etherReward;                             // ETH reward for incentivized rebalances
        uint256 incentivizedLeverageRatio;               // Leverage ratio for incentivized rebalances
        uint256 incentivizedSlippageTolerance;           // Slippage tolerance percentage for incentivized rebalances
        uint256 incentivizedTwapCooldownPeriod;          // TWAP cooldown in seconds for incentivized rebalances
    }

    /* ============ Events ============ */

    event Engaged(uint256 _currentLeverageRatio, uint256 _newLeverageRatio, uint256 _chunkRebalanceNotional, uint256 _totalRebalanceNotional);
    event Rebalanced(
        uint256 _currentLeverageRatio,
        uint256 _newLeverageRatio,
        uint256 _chunkRebalanceNotional,
        uint256 _totalRebalanceNotional
    );
    event RebalanceIterated(
        uint256 _currentLeverageRatio,
        uint256 _newLeverageRatio,
        uint256 _chunkRebalanceNotional,
        uint256 _totalRebalanceNotional
    );
    event RipcordCalled(
        uint256 _currentLeverageRatio,
        uint256 _newLeverageRatio,
        uint256 _rebalanceNotional,
        uint256 _etherIncentive
    );
    event Disengaged(uint256 _currentLeverageRatio, uint256 _newLeverageRatio, uint256 _chunkRebalanceNotional, uint256 _totalRebalanceNotional);
    event MethodologySettingsUpdated(
        uint256 _targetLeverageRatio,
        uint256 _minLeverageRatio,
        uint256 _maxLeverageRatio,
        uint256 _recenteringSpeed,
        uint256 _rebalanceInterval
    );
    event ExecutionSettingsUpdated(
        uint256 _unutilizedLeveragePercentage,
        uint256 _twapCooldownPeriod,
        uint256 _slippageTolerance
    );
    event IncentiveSettingsUpdated(
        uint256 _etherReward,
        uint256 _incentivizedLeverageRatio,
        uint256 _incentivizedSlippageTolerance,
        uint256 _incentivizedTwapCooldownPeriod
    );
    event ExchangeUpdated(
        string _exchangeName,
        uint256 twapMaxTradeSize,
        uint256 exchangeLastTradeTimestamp,
        uint256 incentivizedTwapMaxTradeSize,
        bytes leverExchangeData,
        bytes deleverExchangeData
    );
    event ExchangeAdded(
        string _exchangeName,
        uint256 twapMaxTradeSize,
        uint256 exchangeLastTradeTimestamp,
        uint256 incentivizedTwapMaxTradeSize,
        bytes leverExchangeData,
        bytes deleverExchangeData
    );
    event ExchangeRemoved(
        string _exchangeName
    );

    /* ============ Modifiers ============ */

    /**
     * Throws if rebalance is currently in TWAP`
     */
    modifier noRebalanceInProgress() {
        require(twapLeverageRatio == 0, "Rebalance is currently in progress");
        _;
    }

    /* ============ State Variables ============ */

    ContractSettings internal strategy;                             // Struct of contracts used in the strategy (SetToken, price oracles, leverage module etc)
    MethodologySettings internal methodology;                       // Struct containing methodology parameters
    ExecutionSettings internal execution;                           // Struct containing execution parameters
    mapping(string => ExchangeSettings) internal exchangeSettings;  // Mapping from exchange name to exchange settings
    IncentiveSettings internal incentive;                           // Struct containing incentive parameters for ripcord
    string[] public enabledExchanges;                               // Array containing enabled exchanges
    uint256 public twapLeverageRatio;                               // Stored leverage ratio to keep track of target between TWAP rebalances
    uint256 public globalLastTradeTimestamp;                        // Last rebalance timestamp. Current timestamp must be greater than this variable + rebalance interval to rebalance

    /* ============ Constructor ============ */

    /**
     * Instantiate addresses, methodology parameters, execution parameters, and incentive parameters.
     *
     * @param _manager                  Address of IBaseManager contract
     * @param _strategy                 Struct of contract addresses
     * @param _methodology              Struct containing methodology parameters
     * @param _execution                Struct containing execution parameters
     * @param _incentive                Struct containing incentive parameters for ripcord
     * @param _exchangeNames            List of initial exchange names
     * @param _exchangeSettings         List of structs containing exchange parameters for the initial exchanges
     */
    constructor(
        IBaseManager _manager,
        ContractSettings memory _strategy,
        MethodologySettings memory _methodology,
        ExecutionSettings memory _execution,
        IncentiveSettings memory _incentive,
        string[] memory _exchangeNames,
        ExchangeSettings[] memory _exchangeSettings
    )
        public
        BaseExtension(_manager)
    {
        strategy = _strategy;
        methodology = _methodology;
        execution = _execution;
        incentive = _incentive;

        for (uint256 i = 0; i < _exchangeNames.length; i++) {
            _validateExchangeSettings(_exchangeSettings[i]);
            exchangeSettings[_exchangeNames[i]] = _exchangeSettings[i];
            enabledExchanges.push(_exchangeNames[i]);
        }

        _validateNonExchangeSettings(methodology, execution, incentive);
    }

    /* ============ External Functions ============ */

    /**
     * OPERATOR ONLY: Engage to target leverage ratio for the first time. SetToken will borrow debt position from Aave and trade for collateral asset. If target
     * leverage ratio is above max borrow or max trade size, then TWAP is kicked off. To complete engage if TWAP, any valid caller must call iterateRebalance until target
     * is met.
     *
     * @param _exchangeName     the exchange used for trading
     */
    function engage(string memory _exchangeName) external onlyOperator {
        ActionInfo memory engageInfo = _createActionInfo();

        require(engageInfo.setTotalSupply > 0, "SetToken must have > 0 supply");
        require(engageInfo.collateralBalance > 0, "Collateral balance must be > 0");
        require(engageInfo.borrowBalance == 0, "Debt must be 0");

        LeverageInfo memory leverageInfo = LeverageInfo({
            action: engageInfo,
            currentLeverageRatio: PreciseUnitMath.preciseUnit(), // 1x leverage in precise units
            slippageTolerance: execution.slippageTolerance,
            twapMaxTradeSize: exchangeSettings[_exchangeName].twapMaxTradeSize,
            exchangeName: _exchangeName
        });

        // Calculate total rebalance units and kick off TWAP if above max borrow or max trade size
        (
            uint256 chunkRebalanceNotional,
            uint256 totalRebalanceNotional
        ) = _calculateChunkRebalanceNotional(leverageInfo, methodology.targetLeverageRatio, true);

        _lever(leverageInfo, chunkRebalanceNotional);

        _updateRebalanceState(
            chunkRebalanceNotional,
            totalRebalanceNotional,
            methodology.targetLeverageRatio,
            _exchangeName
        );

        emit Engaged(
            leverageInfo.currentLeverageRatio,
            methodology.targetLeverageRatio,
            chunkRebalanceNotional,
            totalRebalanceNotional
        );
    }

    /**
     * ONLY EOA AND ALLOWED CALLER: Rebalance product. If current leverage ratio is between the max and min bounds, then rebalance 
     * can only be called once the rebalance interval has elapsed since last timestamp. If outside the max and min, rebalance can be called anytime to bring leverage
     * ratio back to the max or min bounds. The methodology will determine whether to delever or lever.
     *
     * Note: If the calculated current leverage ratio is above the incentivized leverage ratio or in TWAP then rebalance cannot be called. Instead, you must call
     * ripcord() which is incentivized with a reward in Ether or iterateRebalance().
     *
     * @param _exchangeName     the exchange used for trading
     */
     function rebalance(string memory _exchangeName) external onlyEOA onlyAllowedCaller(msg.sender) {
        LeverageInfo memory leverageInfo = _getAndValidateLeveragedInfo(
            execution.slippageTolerance,
            exchangeSettings[_exchangeName].twapMaxTradeSize,
            _exchangeName
        );

        // use globalLastTradeTimestamps to prevent multiple rebalances being called with different exchanges during the epoch rebalance
        _validateNormalRebalance(leverageInfo, methodology.rebalanceInterval, globalLastTradeTimestamp);
        _validateNonTWAP();

        uint256 newLeverageRatio = _calculateNewLeverageRatio(leverageInfo.currentLeverageRatio);

        (
            uint256 chunkRebalanceNotional,
            uint256 totalRebalanceNotional
        ) = _handleRebalance(leverageInfo, newLeverageRatio);

        _updateRebalanceState(chunkRebalanceNotional, totalRebalanceNotional, newLeverageRatio, _exchangeName);

        emit Rebalanced(
            leverageInfo.currentLeverageRatio,
            newLeverageRatio,
            chunkRebalanceNotional,
            totalRebalanceNotional
        );
    }

    /**
     * ONLY EOA AND ALLOWED CALLER: Iterate a rebalance when in TWAP. TWAP cooldown period must have elapsed. If price moves advantageously, then exit without rebalancing
     * and clear TWAP state. This function can only be called when below incentivized leverage ratio and in TWAP state.
     *
     * @param _exchangeName     the exchange used for trading
     */
    function iterateRebalance(string memory _exchangeName) external onlyEOA onlyAllowedCaller(msg.sender) {
        LeverageInfo memory leverageInfo = _getAndValidateLeveragedInfo(
            execution.slippageTolerance,
            exchangeSettings[_exchangeName].twapMaxTradeSize,
            _exchangeName
        );

        // Use the exchangeLastTradeTimestamp since cooldown periods are measured on a per-exchange basis, allowing it to rebalance multiple time in quick
        // succession with different exchanges
        _validateNormalRebalance(leverageInfo, execution.twapCooldownPeriod, exchangeSettings[_exchangeName].exchangeLastTradeTimestamp);
        _validateTWAP();

        uint256 chunkRebalanceNotional;
        uint256 totalRebalanceNotional;
        if (!_isAdvantageousTWAP(leverageInfo.currentLeverageRatio)) {
            (chunkRebalanceNotional, totalRebalanceNotional) = _handleRebalance(leverageInfo, twapLeverageRatio);
        }

        // If not advantageous, then rebalance is skipped and chunk and total rebalance notional are both 0, which means TWAP state is
        // cleared
        _updateIterateState(chunkRebalanceNotional, totalRebalanceNotional, _exchangeName);

        emit RebalanceIterated(
            leverageInfo.currentLeverageRatio,
            twapLeverageRatio,
            chunkRebalanceNotional,
            totalRebalanceNotional
        );
    }

    /**
     * ONLY EOA: In case the current leverage ratio exceeds the incentivized leverage threshold, the ripcord function can be called by anyone to return leverage ratio
     * back to the max leverage ratio. This function typically would only be called during times of high downside volatility and / or normal keeper malfunctions. The caller
     * of ripcord() will receive a reward in Ether. The ripcord function uses it's own TWAP cooldown period, slippage tolerance and TWAP max trade size which are typically
     * looser than in regular rebalances.
     *
     * @param _exchangeName     the exchange used for trading
     */
    function ripcord(string memory _exchangeName) external onlyEOA {
        LeverageInfo memory leverageInfo = _getAndValidateLeveragedInfo(
            incentive.incentivizedSlippageTolerance,
            exchangeSettings[_exchangeName].incentivizedTwapMaxTradeSize,
            _exchangeName
        );

        // Use the exchangeLastTradeTimestamp so it can ripcord quickly with multiple exchanges
        _validateRipcord(leverageInfo, exchangeSettings[_exchangeName].exchangeLastTradeTimestamp);

        ( uint256 chunkRebalanceNotional, ) = _calculateChunkRebalanceNotional(leverageInfo, methodology.maxLeverageRatio, false);

        _delever(leverageInfo, chunkRebalanceNotional);

        _updateRipcordState(_exchangeName);

        uint256 etherTransferred = _transferEtherRewardToCaller(incentive.etherReward);

        emit RipcordCalled(
            leverageInfo.currentLeverageRatio,
            methodology.maxLeverageRatio,
            chunkRebalanceNotional,
            etherTransferred
        );
    }

    /**
     * OPERATOR ONLY: Return leverage ratio to 1x and delever to repay loan. This can be used for upgrading or shutting down the strategy. SetToken will redeem
     * collateral position and trade for debt position to repay Aave. If the chunk rebalance size is less than the total notional size, then this function will
     * delever and repay entire borrow balance on Aave. If chunk rebalance size is above max borrow or max trade size, then operator must
     * continue to call this function to complete repayment of loan. The function iterateRebalance will not work.
     *
     * Note: Delever to 0 will likely result in additional units of the borrow asset added as equity on the SetToken due to oracle price / market price mismatch
     *
     * @param _exchangeName     the exchange used for trading
     */
    function disengage(string memory _exchangeName) external onlyOperator {
        LeverageInfo memory leverageInfo = _getAndValidateLeveragedInfo(
            execution.slippageTolerance,
            exchangeSettings[_exchangeName].twapMaxTradeSize,
            _exchangeName
        );

        uint256 newLeverageRatio = PreciseUnitMath.preciseUnit();

        (
            uint256 chunkRebalanceNotional,
            uint256 totalRebalanceNotional
        ) = _calculateChunkRebalanceNotional(leverageInfo, newLeverageRatio, false);

        if (totalRebalanceNotional > chunkRebalanceNotional) {
            _delever(leverageInfo, chunkRebalanceNotional);
        } else {
            _deleverToZeroBorrowBalance(leverageInfo, totalRebalanceNotional);
        }

        emit Disengaged(
            leverageInfo.currentLeverageRatio,
            newLeverageRatio,
            chunkRebalanceNotional,
            totalRebalanceNotional
        );
    }

    /**
     * OPERATOR ONLY: Set methodology settings and check new settings are valid. Note: Need to pass in existing parameters if only changing a few settings. Must not be
     * in a rebalance.
     *
     * @param _newMethodologySettings          Struct containing methodology parameters
     */
    function setMethodologySettings(MethodologySettings memory _newMethodologySettings) external onlyOperator noRebalanceInProgress {
        methodology = _newMethodologySettings;

        _validateNonExchangeSettings(methodology, execution, incentive);

        emit MethodologySettingsUpdated(
            methodology.targetLeverageRatio,
            methodology.minLeverageRatio,
            methodology.maxLeverageRatio,
            methodology.recenteringSpeed,
            methodology.rebalanceInterval
        );
    }

    /**
     * OPERATOR ONLY: Set execution settings and check new settings are valid. Note: Need to pass in existing parameters if only changing a few settings. Must not be
     * in a rebalance.
     *
     * @param _newExecutionSettings          Struct containing execution parameters
     */
    function setExecutionSettings(ExecutionSettings memory _newExecutionSettings) external onlyOperator noRebalanceInProgress {
        execution = _newExecutionSettings;

        _validateNonExchangeSettings(methodology, execution, incentive);

        emit ExecutionSettingsUpdated(
            execution.unutilizedLeveragePercentage,
            execution.twapCooldownPeriod,
            execution.slippageTolerance
        );
    }

    /**
     * OPERATOR ONLY: Set incentive settings and check new settings are valid. Note: Need to pass in existing parameters if only changing a few settings. Must not be
     * in a rebalance.
     *
     * @param _newIncentiveSettings          Struct containing incentive parameters
     */
    function setIncentiveSettings(IncentiveSettings memory _newIncentiveSettings) external onlyOperator noRebalanceInProgress {
        incentive = _newIncentiveSettings;

        _validateNonExchangeSettings(methodology, execution, incentive);

        emit IncentiveSettingsUpdated(
            incentive.etherReward,
            incentive.incentivizedLeverageRatio,
            incentive.incentivizedSlippageTolerance,
            incentive.incentivizedTwapCooldownPeriod
        );
    }

    /**
     * OPERATOR ONLY: Add a new enabled exchange for trading during rebalances. New exchanges will have their exchangeLastTradeTimestamp set to 0. Adding
     * exchanges during rebalances is allowed, as it is not possible to enter an unexpected state while doing so.
     *
     * @param _exchangeName         Name of the exchange
     * @param _exchangeSettings     Struct containing exchange parameters
     */
    function addEnabledExchange(
        string memory _exchangeName,
        ExchangeSettings memory _exchangeSettings
    )
        external
        onlyOperator
    {
        require(exchangeSettings[_exchangeName].twapMaxTradeSize == 0, "Exchange already enabled");
        _validateExchangeSettings(_exchangeSettings);

        exchangeSettings[_exchangeName].twapMaxTradeSize = _exchangeSettings.twapMaxTradeSize;
        exchangeSettings[_exchangeName].incentivizedTwapMaxTradeSize = _exchangeSettings.incentivizedTwapMaxTradeSize;
        exchangeSettings[_exchangeName].leverExchangeData = _exchangeSettings.leverExchangeData;
        exchangeSettings[_exchangeName].deleverExchangeData = _exchangeSettings.deleverExchangeData;
        exchangeSettings[_exchangeName].exchangeLastTradeTimestamp = 0;

        enabledExchanges.push(_exchangeName);

        emit ExchangeAdded(
            _exchangeName,
            _exchangeSettings.twapMaxTradeSize,
            _exchangeSettings.exchangeLastTradeTimestamp,
            _exchangeSettings.incentivizedTwapMaxTradeSize,
            _exchangeSettings.leverExchangeData,
            _exchangeSettings.deleverExchangeData
        );
    }

    /**
     * OPERATOR ONLY: Removes an exchange. Reverts if the exchange is not already enabled. Removing exchanges during rebalances is allowed,
     * as it is not possible to enter an unexpected state while doing so.
     *
     * @param _exchangeName     Name of exchange to remove
     */
    function removeEnabledExchange(string memory _exchangeName) external onlyOperator {
        require(exchangeSettings[_exchangeName].twapMaxTradeSize != 0, "Exchange not enabled");

        delete exchangeSettings[_exchangeName];
        enabledExchanges.removeStorage(_exchangeName);

        emit ExchangeRemoved(_exchangeName);
    }

    /**
     * OPERATOR ONLY: Updates the settings of an exchange. Reverts if exchange is not already added. When updating an exchange, exchangeLastTradeTimestamp
     * is preserved. Updating exchanges during rebalances is allowed, as it is not possible to enter an unexpected state while doing so. Note: Need to
     * pass in all existing parameters even if only changing a few settings.
     *
     * @param _exchangeName         Name of the exchange
     * @param _exchangeSettings     Struct containing exchange parameters
     */
    function updateEnabledExchange(
        string memory _exchangeName,
        ExchangeSettings memory _exchangeSettings
    )
        external
        onlyOperator
    {
        require(exchangeSettings[_exchangeName].twapMaxTradeSize != 0, "Exchange not enabled");
        _validateExchangeSettings(_exchangeSettings);

        exchangeSettings[_exchangeName].twapMaxTradeSize = _exchangeSettings.twapMaxTradeSize;
        exchangeSettings[_exchangeName].incentivizedTwapMaxTradeSize = _exchangeSettings.incentivizedTwapMaxTradeSize;
        exchangeSettings[_exchangeName].leverExchangeData = _exchangeSettings.leverExchangeData;
        exchangeSettings[_exchangeName].deleverExchangeData = _exchangeSettings.deleverExchangeData;

        emit ExchangeUpdated(
            _exchangeName,
            _exchangeSettings.twapMaxTradeSize,
            _exchangeSettings.exchangeLastTradeTimestamp,
            _exchangeSettings.incentivizedTwapMaxTradeSize,
            _exchangeSettings.leverExchangeData,
            _exchangeSettings.deleverExchangeData
        );
    }

    /**
     * OPERATOR ONLY: Withdraw entire balance of ETH in this contract to operator. Rebalance must not be in progress
     */
    function withdrawEtherBalance() external onlyOperator noRebalanceInProgress {
        msg.sender.transfer(address(this).balance);
    }

    receive() external payable {}

    /* ============ External Getter Functions ============ */

    /**
     * Get current leverage ratio. Current leverage ratio is defined as the USD value of the collateral divided by the USD value of the SetToken. Prices for collateral
     * and borrow asset are retrieved from the Chainlink Price Oracle.
     *
     * return currentLeverageRatio         Current leverage ratio in precise units (10e18)
     */
    function getCurrentLeverageRatio() public view returns(uint256) {
        ActionInfo memory currentLeverageInfo = _createActionInfo();

        return _calculateCurrentLeverageRatio(currentLeverageInfo.collateralValue, currentLeverageInfo.borrowValue);
    }

    /**
     * Calculates the chunk rebalance size. This can be used by external contracts and keeper bots to calculate the optimal exchange to rebalance with.
     * Note: this function does not take into account timestamps, so it may return a nonzero value even when shouldRebalance would return ShouldRebalance.NONE for
     * all exchanges (since minimum delays have not elapsed)
     *
     * @param _exchangeNames    Array of exchange names to get rebalance sizes for
     *
     * @return sizes            Array of total notional chunk size. Measured in the asset that would be sold
     * @return sellAsset        Asset that would be sold during a rebalance
     * @return buyAsset         Asset that would be purchased during a rebalance
     */
    function getChunkRebalanceNotional(
        string[] calldata _exchangeNames
    )
        external
        view
        returns(uint256[] memory sizes, address sellAsset, address buyAsset)
    {

        uint256 newLeverageRatio;
        uint256 currentLeverageRatio = getCurrentLeverageRatio();
        bool isRipcord = false;

        // if over incentivized leverage ratio, always ripcord
        if (currentLeverageRatio > incentive.incentivizedLeverageRatio) {
            newLeverageRatio = methodology.maxLeverageRatio;
            isRipcord = true;
        // if we are in an ongoing twap, use the cached twapLeverageRatio as our target leverage
        } else if (twapLeverageRatio > 0) {
            newLeverageRatio = twapLeverageRatio;
        // if all else is false, then we would just use the normal rebalance new leverage ratio calculation
        } else {
            newLeverageRatio = _calculateNewLeverageRatio(currentLeverageRatio);
        }

        ActionInfo memory actionInfo = _createActionInfo();
        bool isLever = newLeverageRatio > currentLeverageRatio;

        sizes = new uint256[](_exchangeNames.length);

        for (uint256 i = 0; i < _exchangeNames.length; i++) {
    
            LeverageInfo memory leverageInfo = LeverageInfo({
                action: actionInfo,
                currentLeverageRatio: currentLeverageRatio,
                slippageTolerance: isRipcord ? incentive.incentivizedSlippageTolerance : execution.slippageTolerance,
                twapMaxTradeSize: isRipcord ?
                    exchangeSettings[_exchangeNames[i]].incentivizedTwapMaxTradeSize :
                    exchangeSettings[_exchangeNames[i]].twapMaxTradeSize,
                exchangeName: _exchangeNames[i]
            });

            (uint256 collateralNotional, ) = _calculateChunkRebalanceNotional(leverageInfo, newLeverageRatio, isLever);

            // _calculateBorrowUnits can convert both unit and notional values
            sizes[i] = isLever ? _calculateBorrowUnits(collateralNotional, leverageInfo.action) : collateralNotional;
        }

        sellAsset = isLever ? strategy.borrowAsset : strategy.collateralAsset;
        buyAsset = isLever ? strategy.collateralAsset : strategy.borrowAsset;
    }

    /**
     * Get current Ether incentive for when current leverage ratio exceeds incentivized leverage ratio and ripcord can be called. If ETH balance on the contract is
     * below the etherReward, then return the balance of ETH instead.
     *
     * return etherReward               Quantity of ETH reward in base units (10e18)
     */
    function getCurrentEtherIncentive() external view returns(uint256) {
        uint256 currentLeverageRatio = getCurrentLeverageRatio();

        if (currentLeverageRatio >= incentive.incentivizedLeverageRatio) {
            // If ETH reward is below the balance on this contract, then return ETH balance on contract instead
            return incentive.etherReward < address(this).balance ? incentive.etherReward : address(this).balance;
        } else {
            return 0;
        }
    }

    /**
     * Helper that checks if conditions are met for rebalance or ripcord. Returns an enum with 0 = no rebalance, 1 = call rebalance(), 2 = call iterateRebalance()
     * 3 = call ripcord()
     *
     * @return (string[] memory, ShouldRebalance[] memory)      List of exchange names and a list of enums representing whether that exchange should rebalance
     */
    function shouldRebalance() external view returns(string[] memory, ShouldRebalance[] memory) {
        uint256 currentLeverageRatio = getCurrentLeverageRatio();

        return _shouldRebalance(currentLeverageRatio, methodology.minLeverageRatio, methodology.maxLeverageRatio);
    }

    /**
     * Helper that checks if conditions are met for rebalance or ripcord with custom max and min bounds specified by caller. This function simplifies the
     * logic for off-chain keeper bots to determine what threshold to call rebalance when leverage exceeds max or drops below min. Returns an enum with
     * 0 = no rebalance, 1 = call rebalance(), 2 = call iterateRebalance(), 3 = call ripcord()
     *
     * @param _customMinLeverageRatio          Min leverage ratio passed in by caller
     * @param _customMaxLeverageRatio          Max leverage ratio passed in by caller
     *
     * @return (string[] memory, ShouldRebalance[] memory)      List of exchange names and a list of enums representing whether that exchange should rebalance
     */
    function shouldRebalanceWithBounds(
        uint256 _customMinLeverageRatio,
        uint256 _customMaxLeverageRatio
    )
        external
        view
        returns(string[] memory, ShouldRebalance[] memory)
    {
        require (
            _customMinLeverageRatio <= methodology.minLeverageRatio && _customMaxLeverageRatio >= methodology.maxLeverageRatio,
            "Custom bounds must be valid"
        );

        uint256 currentLeverageRatio = getCurrentLeverageRatio();

        return _shouldRebalance(currentLeverageRatio, _customMinLeverageRatio, _customMaxLeverageRatio);
    }

    /**
     * Gets the list of enabled exchanges
     */
    function getEnabledExchanges() external view returns (string[] memory) {
        return enabledExchanges;
    }

    /**
     * Explicit getter functions for parameter structs are defined as workaround to issues fetching structs that have dynamic types.
     */
    function getStrategy() external view returns (ContractSettings memory) { return strategy; }
    function getMethodology() external view returns (MethodologySettings memory) { return methodology; }
    function getExecution() external view returns (ExecutionSettings memory) { return execution; }
    function getIncentive() external view returns (IncentiveSettings memory) { return incentive; }
    function getExchangeSettings(string memory _exchangeName) external view returns (ExchangeSettings memory) {
        return exchangeSettings[_exchangeName];
    }

    /* ============ Internal Functions ============ */

    /**
     * Calculate notional rebalance quantity, whether to chunk rebalance based on max trade size and max borrow and invoke lever on AaveLeverageModule
     *
     */
     function _lever(
        LeverageInfo memory _leverageInfo,
        uint256 _chunkRebalanceNotional
    )
        internal
    {
        uint256 collateralRebalanceUnits = _chunkRebalanceNotional.preciseDiv(_leverageInfo.action.setTotalSupply);

        uint256 borrowUnits = _calculateBorrowUnits(collateralRebalanceUnits, _leverageInfo.action);

        uint256 minReceiveCollateralUnits = _calculateMinCollateralReceiveUnits(collateralRebalanceUnits, _leverageInfo.slippageTolerance);

        bytes memory leverCallData = abi.encodeWithSignature(
            "lever(address,address,address,uint256,uint256,string,bytes)",
            address(strategy.setToken),
            strategy.borrowAsset,
            strategy.collateralAsset,
            borrowUnits,
            minReceiveCollateralUnits,
            _leverageInfo.exchangeName,
            exchangeSettings[_leverageInfo.exchangeName].leverExchangeData
        );

        invokeManager(address(strategy.leverageModule), leverCallData);
    }

    /**
     * Calculate delever units Invoke delever on AaveLeverageModule.
     */
    function _delever(
        LeverageInfo memory _leverageInfo,
        uint256 _chunkRebalanceNotional
    )
        internal
    {
        uint256 collateralRebalanceUnits = _chunkRebalanceNotional.preciseDiv(_leverageInfo.action.setTotalSupply);

        uint256 minRepayUnits = _calculateMinRepayUnits(collateralRebalanceUnits, _leverageInfo.slippageTolerance, _leverageInfo.action);

        bytes memory deleverCallData = abi.encodeWithSignature(
            "delever(address,address,address,uint256,uint256,string,bytes)",
            address(strategy.setToken),
            strategy.collateralAsset,
            strategy.borrowAsset,
            collateralRebalanceUnits,
            minRepayUnits,
            _leverageInfo.exchangeName,
            exchangeSettings[_leverageInfo.exchangeName].deleverExchangeData
        );

        invokeManager(address(strategy.leverageModule), deleverCallData);
    }

    /**
     * Invoke deleverToZeroBorrowBalance on AaveLeverageModule.
     */
    function _deleverToZeroBorrowBalance(
        LeverageInfo memory _leverageInfo,
        uint256 _chunkRebalanceNotional
    )
        internal
    {
        // Account for slippage tolerance in redeem quantity for the deleverToZeroBorrowBalance function
        uint256 maxCollateralRebalanceUnits = _chunkRebalanceNotional
            .preciseMul(PreciseUnitMath.preciseUnit().add(execution.slippageTolerance))
            .preciseDiv(_leverageInfo.action.setTotalSupply);

        bytes memory deleverToZeroBorrowBalanceCallData = abi.encodeWithSignature(
            "deleverToZeroBorrowBalance(address,address,address,uint256,string,bytes)",
            address(strategy.setToken),
            strategy.collateralAsset,
            strategy.borrowAsset,
            maxCollateralRebalanceUnits,
            _leverageInfo.exchangeName,
            exchangeSettings[_leverageInfo.exchangeName].deleverExchangeData
        );

        invokeManager(address(strategy.leverageModule), deleverToZeroBorrowBalanceCallData);
    }

    /**
     * Check whether to delever or lever based on the current vs new leverage ratios. Used in the rebalance() and iterateRebalance() functions
     *
     * return uint256           Calculated notional to trade
     * return uint256           Total notional to rebalance over TWAP
     */
    function _handleRebalance(LeverageInfo memory _leverageInfo, uint256 _newLeverageRatio) internal returns(uint256, uint256) {
        uint256 chunkRebalanceNotional;
        uint256 totalRebalanceNotional;
        if (_newLeverageRatio < _leverageInfo.currentLeverageRatio) {
            (
                chunkRebalanceNotional,
                totalRebalanceNotional
            ) = _calculateChunkRebalanceNotional(_leverageInfo, _newLeverageRatio, false);

            _delever(_leverageInfo, chunkRebalanceNotional);
        } else {
            (
                chunkRebalanceNotional,
                totalRebalanceNotional
            ) = _calculateChunkRebalanceNotional(_leverageInfo, _newLeverageRatio, true);

            _lever(_leverageInfo, chunkRebalanceNotional);
        }

        return (chunkRebalanceNotional, totalRebalanceNotional);
    }

    /**
     * Create the leverage info struct to be used in internal functions
     *
     * return LeverageInfo                Struct containing ActionInfo and other data
     */
    function _getAndValidateLeveragedInfo(uint256 _slippageTolerance, uint256 _maxTradeSize, string memory _exchangeName) internal view returns(LeverageInfo memory) {
        // Assume if maxTradeSize is 0, then the exchange is not enabled. This is enforced by addEnabledExchange and updateEnabledExchange
        require(_maxTradeSize > 0, "Must be valid exchange");

        ActionInfo memory actionInfo = _createActionInfo();

        require(actionInfo.setTotalSupply > 0, "SetToken must have > 0 supply");
        require(actionInfo.collateralBalance > 0, "Collateral balance must be > 0");
        require(actionInfo.borrowBalance > 0, "Borrow balance must exist");

        // Get current leverage ratio
        uint256 currentLeverageRatio = _calculateCurrentLeverageRatio(
            actionInfo.collateralValue,
            actionInfo.borrowValue
        );

        return LeverageInfo({
            action: actionInfo,
            currentLeverageRatio: currentLeverageRatio,
            slippageTolerance: _slippageTolerance,
            twapMaxTradeSize: _maxTradeSize,
            exchangeName: _exchangeName
        });
    }

    /**
     * Create the action info struct to be used in internal functions
     *
     * return ActionInfo                Struct containing data used by internal lever and delever functions
     */
    function _createActionInfo() internal view returns(ActionInfo memory) {
        ActionInfo memory rebalanceInfo;

        // Calculate prices from chainlink. Chainlink returns prices with 8 decimal places, but we need 36 - underlyingDecimals decimal places.
        // This is so that when the underlying amount is multiplied by the received price, the collateral valuation is normalized to 36 decimals. 
        // To perform this adjustment, we multiply by 10^(36 - 8 - underlyingDecimals)
        int256 rawCollateralPrice = strategy.collateralPriceOracle.latestAnswer();
        rebalanceInfo.collateralPrice = rawCollateralPrice.toUint256().mul(10 ** strategy.collateralDecimalAdjustment);
        int256 rawBorrowPrice = strategy.borrowPriceOracle.latestAnswer();
        rebalanceInfo.borrowPrice = rawBorrowPrice.toUint256().mul(10 ** strategy.borrowDecimalAdjustment);

        rebalanceInfo.collateralBalance = strategy.targetCollateralAToken.balanceOf(address(strategy.setToken));
        rebalanceInfo.borrowBalance = strategy.targetBorrowDebtToken.balanceOf(address(strategy.setToken));
        rebalanceInfo.collateralValue = rebalanceInfo.collateralPrice.preciseMul(rebalanceInfo.collateralBalance);
        rebalanceInfo.borrowValue = rebalanceInfo.borrowPrice.preciseMul(rebalanceInfo.borrowBalance);
        rebalanceInfo.setTotalSupply = strategy.setToken.totalSupply();

        return rebalanceInfo;
    }

    /**
     * Validate non-exchange settings in constructor and setters when updating.
     */
    function _validateNonExchangeSettings(
        MethodologySettings memory _methodology,
        ExecutionSettings memory _execution,
        IncentiveSettings memory _incentive
    )
        internal
        pure
    {
        require (
            _methodology.minLeverageRatio <= _methodology.targetLeverageRatio && _methodology.minLeverageRatio > 0,
            "Must be valid min leverage"
        );
        require (
            _methodology.maxLeverageRatio >= _methodology.targetLeverageRatio,
            "Must be valid max leverage"
        );
        require (
            _methodology.recenteringSpeed <= PreciseUnitMath.preciseUnit() && _methodology.recenteringSpeed > 0,
            "Must be valid recentering speed"
        );
        require (
            _execution.unutilizedLeveragePercentage <= PreciseUnitMath.preciseUnit(),
            "Unutilized leverage must be <100%"
        );
        require (
            _execution.slippageTolerance <= PreciseUnitMath.preciseUnit(),
            "Slippage tolerance must be <100%"
        );
        require (
            _incentive.incentivizedSlippageTolerance <= PreciseUnitMath.preciseUnit(),
            "Incentivized slippage tolerance must be <100%"
        );
        require (
            _incentive.incentivizedLeverageRatio >= _methodology.maxLeverageRatio,
            "Incentivized leverage ratio must be > max leverage ratio"
        );
        require (
            _methodology.rebalanceInterval >= _execution.twapCooldownPeriod,
            "Rebalance interval must be greater than TWAP cooldown period"
        );
        require (
            _execution.twapCooldownPeriod >= _incentive.incentivizedTwapCooldownPeriod,
            "TWAP cooldown must be greater than incentivized TWAP cooldown"
        );
    }

    /**
     * Validate an ExchangeSettings struct when adding or updating an exchange. Does not validate that twapMaxTradeSize < incentivizedMaxTradeSize since
     * it may be useful to disable exchanges for ripcord by setting incentivizedMaxTradeSize to 0.
     */
     function _validateExchangeSettings(ExchangeSettings memory _settings) internal pure {
         require(_settings.twapMaxTradeSize != 0, "Max TWAP trade size must not be 0");
     }

    /**
     * Validate that current leverage is below incentivized leverage ratio and cooldown / rebalance period has elapsed or outsize max/min bounds. Used
     * in rebalance() and iterateRebalance() functions
     */
    function _validateNormalRebalance(LeverageInfo memory _leverageInfo, uint256 _coolDown, uint256 _lastTradeTimestamp) internal view {
        require(_leverageInfo.currentLeverageRatio < incentive.incentivizedLeverageRatio, "Must be below incentivized leverage ratio");
        require(
            block.timestamp.sub(_lastTradeTimestamp) > _coolDown
            || _leverageInfo.currentLeverageRatio > methodology.maxLeverageRatio
            || _leverageInfo.currentLeverageRatio < methodology.minLeverageRatio,
            "Cooldown not elapsed or not valid leverage ratio"
        );
    }

    /**
     * Validate that current leverage is above incentivized leverage ratio and incentivized cooldown period has elapsed in ripcord()
     */
    function _validateRipcord(LeverageInfo memory _leverageInfo, uint256 _lastTradeTimestamp) internal view {
        require(_leverageInfo.currentLeverageRatio >= incentive.incentivizedLeverageRatio, "Must be above incentivized leverage ratio");
        // If currently in the midst of a TWAP rebalance, ensure that the cooldown period has elapsed
        require(_lastTradeTimestamp.add(incentive.incentivizedTwapCooldownPeriod) < block.timestamp, "TWAP cooldown must have elapsed");
    }

    /**
     * Validate TWAP in the iterateRebalance() function
     */
    function _validateTWAP() internal view {
        require(twapLeverageRatio > 0, "Not in TWAP state");
    }

    /**
     * Validate not TWAP in the rebalance() function
     */
    function _validateNonTWAP() internal view {
        require(twapLeverageRatio == 0, "Must call iterate");
    }

    /**
     * Check if price has moved advantageously while in the midst of the TWAP rebalance. This means the current leverage ratio has moved over/under
     * the stored TWAP leverage ratio on lever/delever so there is no need to execute a rebalance. Used in iterateRebalance()
     */
    function _isAdvantageousTWAP(uint256 _currentLeverageRatio) internal view returns (bool) {
        return (
            (twapLeverageRatio < methodology.targetLeverageRatio && _currentLeverageRatio >= twapLeverageRatio)
            || (twapLeverageRatio > methodology.targetLeverageRatio && _currentLeverageRatio <= twapLeverageRatio)
        );
    }

    /**
     * Calculate the current leverage ratio given a valuation of the collateral and borrow asset, which is calculated as collateral USD valuation / SetToken USD valuation
     *
     * return uint256            Current leverage ratio
     */
    function _calculateCurrentLeverageRatio(
        uint256 _collateralValue,
        uint256 _borrowValue
    )
        internal
        pure
        returns(uint256)
    {
        return _collateralValue.preciseDiv(_collateralValue.sub(_borrowValue));
    }

    /**
     * Calculate the new leverage ratio. The methodology reduces the size of each rebalance by weighting
     * the current leverage ratio against the target leverage ratio by the recentering speed percentage. The lower the recentering speed, the slower
     * the leverage token will move towards the target leverage each rebalance.
     *
     * return uint256          New leverage ratio
     */
    function _calculateNewLeverageRatio(uint256 _currentLeverageRatio) internal view returns(uint256) {
        // CLRt+1 = max(MINLR, min(MAXLR, CLRt * (1 - RS) + TLR * RS))
        // a: TLR * RS
        // b: (1- RS) * CLRt
        // c: (1- RS) * CLRt + TLR * RS
        // d: min(MAXLR, CLRt * (1 - RS) + TLR * RS)
        uint256 a = methodology.targetLeverageRatio.preciseMul(methodology.recenteringSpeed);
        uint256 b = PreciseUnitMath.preciseUnit().sub(methodology.recenteringSpeed).preciseMul(_currentLeverageRatio);
        uint256 c = a.add(b);
        uint256 d = Math.min(c, methodology.maxLeverageRatio);
        return Math.max(methodology.minLeverageRatio, d);
    }

    /**
     * Calculate total notional rebalance quantity and chunked rebalance quantity in collateral units.
     *
     * return uint256          Chunked rebalance notional in collateral units
     * return uint256          Total rebalance notional in collateral units
     */
    function _calculateChunkRebalanceNotional(
        LeverageInfo memory _leverageInfo,
        uint256 _newLeverageRatio,
        bool _isLever
    )
        internal
        view
        returns (uint256, uint256)
    {
        // Calculate absolute value of difference between new and current leverage ratio
        uint256 leverageRatioDifference = _isLever ? _newLeverageRatio.sub(_leverageInfo.currentLeverageRatio) : _leverageInfo.currentLeverageRatio.sub(_newLeverageRatio);

        uint256 totalRebalanceNotional = leverageRatioDifference.preciseDiv(_leverageInfo.currentLeverageRatio).preciseMul(_leverageInfo.action.collateralBalance);

        uint256 maxBorrow = _calculateMaxBorrowCollateral(_leverageInfo.action, _isLever);

        uint256 chunkRebalanceNotional = Math.min(Math.min(maxBorrow, totalRebalanceNotional), _leverageInfo.twapMaxTradeSize);

        return (chunkRebalanceNotional, totalRebalanceNotional);
    }

    /**
     * Calculate the max borrow / repay amount allowed in base units for lever / delever. This is due to overcollateralization requirements on
     * assets deposited in lending protocols for borrowing.
     *
     * For lever, max borrow is calculated as:
     * (Net borrow limit in USD - existing borrow value in USD) / collateral asset price adjusted for decimals
     *
     * For delever, max repay is calculated as:
     * Collateral balance in base units * (net borrow limit in USD - existing borrow value in USD) / net borrow limit in USD
     *
     * Net borrow limit for levering is calculated as:
     * The collateral value in USD * Aave collateral factor * (1 - unutilized leverage %)
     *
     * Net repay limit for delevering is calculated as:
     * The collateral value in USD * Aave liquiditon threshold * (1 - unutilized leverage %)
     *
     * return uint256          Max borrow notional denominated in collateral asset
     */
    function _calculateMaxBorrowCollateral(ActionInfo memory _actionInfo, bool _isLever) internal view returns(uint256) {
        
        // Retrieve collateral factor and liquidation threshold for the collateral asset in precise units (1e16 = 1%)
        ( , uint256 maxLtvRaw, uint256 liquidationThresholdRaw, , , , , , ,) = strategy.aaveProtocolDataProvider.getReserveConfigurationData(address(strategy.collateralAsset));

        // Normalize LTV and liquidation threshold to precise units. LTV is measured in 4 decimals in Aave which is why we must multiply by 1e14
        // for example ETH has an LTV value of 8000 which represents 80%
        if (_isLever) {
            uint256 netBorrowLimit = _actionInfo.collateralValue
                .preciseMul(maxLtvRaw.mul(10 ** 14))
                .preciseMul(PreciseUnitMath.preciseUnit().sub(execution.unutilizedLeveragePercentage));

            return netBorrowLimit
                .sub(_actionInfo.borrowValue)
                .preciseDiv(_actionInfo.collateralPrice);
        } else {
            uint256 netRepayLimit = _actionInfo.collateralValue
                .preciseMul(liquidationThresholdRaw.mul(10 ** 14))
                .preciseMul(PreciseUnitMath.preciseUnit().sub(execution.unutilizedLeveragePercentage));

            return _actionInfo.collateralBalance
                .preciseMul(netRepayLimit.sub(_actionInfo.borrowValue))
                .preciseDiv(netRepayLimit);
        }
    }

    /**
     * Derive the borrow units for lever. The units are calculated by the collateral units multiplied by collateral / borrow asset price.
     * Output is measured to borrow unit decimals.
     *
     * return uint256           Position units to borrow
     */
    function _calculateBorrowUnits(uint256 _collateralRebalanceUnits, ActionInfo memory _actionInfo) internal pure returns (uint256) {
        return _collateralRebalanceUnits.preciseMul(_actionInfo.collateralPrice).preciseDiv(_actionInfo.borrowPrice);
    }

    /**
     * Calculate the min receive units in collateral units for lever. Units are calculated as target collateral rebalance units multiplied by slippage tolerance
     * Output is measured in collateral asset decimals.
     *
     * return uint256           Min position units to receive after lever trade
     */
    function _calculateMinCollateralReceiveUnits(uint256 _collateralRebalanceUnits, uint256 _slippageTolerance) internal pure returns (uint256) {
        return _collateralRebalanceUnits.preciseMul(PreciseUnitMath.preciseUnit().sub(_slippageTolerance));
    }

    /**
     * Derive the min repay units from collateral units for delever. Units are calculated as target collateral rebalance units multiplied by slippage tolerance
     * and pair price (collateral oracle price / borrow oracle price). Output is measured in borrow unit decimals.
     *
     * return uint256           Min position units to repay in borrow asset
     */
    function _calculateMinRepayUnits(uint256 _collateralRebalanceUnits, uint256 _slippageTolerance, ActionInfo memory _actionInfo) internal pure returns (uint256) {
        return _collateralRebalanceUnits
            .preciseMul(_actionInfo.collateralPrice)
            .preciseDiv(_actionInfo.borrowPrice)
            .preciseMul(PreciseUnitMath.preciseUnit().sub(_slippageTolerance));
    }

    /**
     * Update last trade timestamp and if chunk rebalance size is less than total rebalance notional, store new leverage ratio to kick off TWAP. Used in
     * the engage() and rebalance() functions
     */
    function _updateRebalanceState(
        uint256 _chunkRebalanceNotional,
        uint256 _totalRebalanceNotional,
        uint256 _newLeverageRatio,
        string memory _exchangeName
    )
        internal
    {

        _updateLastTradeTimestamp(_exchangeName);

        if (_chunkRebalanceNotional < _totalRebalanceNotional) {
            twapLeverageRatio = _newLeverageRatio;
        }
    }

    /**
     * Update last trade timestamp and if chunk rebalance size is equal to the total rebalance notional, end TWAP by clearing state. This function is used
     * in iterateRebalance()
     */
    function _updateIterateState(uint256 _chunkRebalanceNotional, uint256 _totalRebalanceNotional, string memory _exchangeName) internal {

        _updateLastTradeTimestamp(_exchangeName);

        // If the chunk size is equal to the total notional meaning that rebalances are not chunked, then clear TWAP state.
        if (_chunkRebalanceNotional == _totalRebalanceNotional) {
            delete twapLeverageRatio;
        }
    }

    /**
     * Update last trade timestamp and if currently in a TWAP, delete the TWAP state. Used in the ripcord() function.
     */
    function _updateRipcordState(string memory _exchangeName) internal {

        _updateLastTradeTimestamp(_exchangeName);

        // If TWAP leverage ratio is stored, then clear state. This may happen if we are currently in a TWAP rebalance, and the leverage ratio moves above the
        // incentivized threshold for ripcord.
        if (twapLeverageRatio > 0) {
            delete twapLeverageRatio;
        }
    }

    /**
     * Update globalLastTradeTimestamp and exchangeLastTradeTimestamp values. This function updates both the exchange-specific and global timestamp so that the
     * epoch rebalance can use the global timestamp (since the global timestamp is always  equal to the most recently used exchange timestamp). This allows for
     * multiple rebalances to occur simultaneously since only the exchange-specific timestamp is checked for non-epoch rebalances.
     */
     function _updateLastTradeTimestamp(string memory _exchangeName) internal {
        globalLastTradeTimestamp = block.timestamp;
        exchangeSettings[_exchangeName].exchangeLastTradeTimestamp = block.timestamp;
     }

    /**
     * Transfer ETH reward to caller of the ripcord function. If the ETH balance on this contract is less than required
     * incentive quantity, then transfer contract balance instead to prevent reverts.
     *
     * return uint256           Amount of ETH transferred to caller
     */
    function _transferEtherRewardToCaller(uint256 _etherReward) internal returns(uint256) {
        uint256 etherToTransfer = _etherReward < address(this).balance ? _etherReward : address(this).balance;

        msg.sender.transfer(etherToTransfer);

        return etherToTransfer;
    }

    /**
     * Internal function returning the ShouldRebalance enum used in shouldRebalance and shouldRebalanceWithBounds external getter functions
     *
     * return ShouldRebalance         Enum detailing whether to rebalance, iterateRebalance, ripcord or no action
     */
    function _shouldRebalance(
        uint256 _currentLeverageRatio,
        uint256 _minLeverageRatio,
        uint256 _maxLeverageRatio
    )
        internal
        view
        returns(string[] memory, ShouldRebalance[] memory)
    {

        ShouldRebalance[] memory shouldRebalanceEnums = new ShouldRebalance[](enabledExchanges.length);

        for (uint256 i = 0; i < enabledExchanges.length; i++) {
            // If none of the below conditions are satisfied, then should not rebalance
            shouldRebalanceEnums[i] = ShouldRebalance.NONE;

            // If above ripcord threshold, then check if incentivized cooldown period has elapsed
            if (_currentLeverageRatio >= incentive.incentivizedLeverageRatio) {
                if (exchangeSettings[enabledExchanges[i]].exchangeLastTradeTimestamp.add(incentive.incentivizedTwapCooldownPeriod) < block.timestamp) {
                    shouldRebalanceEnums[i] = ShouldRebalance.RIPCORD;
                }
            } else {
                // If TWAP, then check if the cooldown period has elapsed
                if (twapLeverageRatio > 0) {
                    if (exchangeSettings[enabledExchanges[i]].exchangeLastTradeTimestamp.add(execution.twapCooldownPeriod) < block.timestamp) {
                        shouldRebalanceEnums[i] = ShouldRebalance.ITERATE_REBALANCE;
                    }
                } else {
                    // If not TWAP, then check if the rebalance interval has elapsed OR current leverage is above max leverage OR current leverage is below
                    // min leverage
                    if (
                        block.timestamp.sub(globalLastTradeTimestamp) > methodology.rebalanceInterval
                        || _currentLeverageRatio > _maxLeverageRatio
                        || _currentLeverageRatio < _minLeverageRatio
                    ) {
                        shouldRebalanceEnums[i] = ShouldRebalance.REBALANCE;
                    }
                }
            }
        }

        return (enabledExchanges, shouldRebalanceEnums);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;


/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/*
    Copyright 2021 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.6.10;

import { AddressArrayUtils } from "../lib/AddressArrayUtils.sol";
import { IBaseManager } from "../interfaces/IBaseManager.sol";

/**
 * @title BaseExtension
 * @author Set Protocol
 *
 * Abstract class that houses common extension-related state and functions.
 */
abstract contract BaseExtension {
    using AddressArrayUtils for address[];

    /* ============ Events ============ */

    event CallerStatusUpdated(address indexed _caller, bool _status);
    event AnyoneCallableUpdated(bool indexed _status);

    /* ============ Modifiers ============ */

    /**
     * Throws if the sender is not the SetToken operator
     */
    modifier onlyOperator() {
        require(msg.sender == manager.operator(), "Must be operator");
        _;
    }

    /**
     * Throws if the sender is not the SetToken methodologist
     */
    modifier onlyMethodologist() {
        require(msg.sender == manager.methodologist(), "Must be methodologist");
        _;
    }

    /**
     * Throws if caller is a contract, can be used to stop flash loan and sandwich attacks
     */
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "Caller must be EOA Address");
        _;
    }

    /**
     * Throws if not allowed caller
     */
    modifier onlyAllowedCaller(address _caller) {
        require(isAllowedCaller(_caller), "Address not permitted to call");
        _;
    }

    /* ============ State Variables ============ */

    // Instance of manager contract
    IBaseManager public manager;

    // Boolean indicating if anyone can call function
    bool public anyoneCallable;

    // Mapping of addresses allowed to call function
    mapping(address => bool) public callAllowList;

    /* ============ Constructor ============ */

    constructor(IBaseManager _manager) public { manager = _manager; }

    /* ============ External Functions ============ */

    /**
     * OPERATOR ONLY: Toggle ability for passed addresses to call only allowed caller functions
     *
     * @param _callers           Array of caller addresses to toggle status
     * @param _statuses          Array of statuses for each caller
     */
    function updateCallerStatus(address[] calldata _callers, bool[] calldata _statuses) external onlyOperator {
        require(_callers.length == _statuses.length, "Array length mismatch");
        require(_callers.length > 0, "Array length must be > 0");
        require(!_callers.hasDuplicate(), "Cannot duplicate callers");

        for (uint256 i = 0; i < _callers.length; i++) {
            address caller = _callers[i];
            bool status = _statuses[i];
            callAllowList[caller] = status;
            emit CallerStatusUpdated(caller, status);
        }
    }

    /**
     * OPERATOR ONLY: Toggle whether anyone can call function, bypassing the callAllowlist
     *
     * @param _status           Boolean indicating whether to allow anyone call
     */
    function updateAnyoneCallable(bool _status) external onlyOperator {
        anyoneCallable = _status;
        emit AnyoneCallableUpdated(_status);
    }

    /* ============ Internal Functions ============ */

    /**
     * Invoke manager to transfer tokens from manager to other contract.
     *
     * @param _token           Token being transferred from manager contract
     * @param _amount          Amount of token being transferred
     */
    function invokeManagerTransfer(address _token, address _destination, uint256 _amount) internal {
        manager.transferTokens(_token, _destination, _amount);
    }

    /**
     * Invoke call from manager
     *
     * @param _module           Module to interact with
     * @param _encoded          Encoded byte data
     */
    function invokeManager(address _module, bytes memory _encoded) internal {
        manager.interactManager(_module, _encoded);
    }

    /**
     * Determine if passed address is allowed to call function. If anyoneCallable set to true anyone can call otherwise needs to be approved.
     *
     * return bool              Boolean indicating if allowed caller
     */
    function isAllowedCaller(address _caller) internal view virtual returns (bool) {
        return anyoneCallable || callAllowList[_caller];
    }
}

/*
    Copyright 2021 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import { ISetToken } from "./ISetToken.sol";

interface IBaseManager {
    function setToken() external returns(ISetToken);

    function methodologist() external returns(address);

    function operator() external returns(address);

    function interactManager(address _module, bytes calldata _encoded) external;

    function transferTokens(address _token, address _destination, uint256 _amount) external;
}

pragma solidity 0.6.10;

interface IChainlinkAggregatorV3 {
    function latestAnswer() external view returns (int256);
}

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import { ISetToken } from "./ISetToken.sol";

interface ILeverageModule {
    function sync(
        ISetToken _setToken
    ) external;

    function lever(
        ISetToken _setToken,
        address _borrowAsset,
        address _collateralAsset,
        uint256 _borrowQuantity,
        uint256 _minReceiveQuantity,
        string memory _tradeAdapterName,
        bytes memory _tradeData
    ) external;

    function delever(
        ISetToken _setToken,
        address _collateralAsset,
        address _repayAsset,
        uint256 _redeemQuantity,
        uint256 _minRepayQuantity,
        string memory _tradeAdapterName,
        bytes memory _tradeData
    ) external;

    function gulp(
        ISetToken _setToken,
        address _collateralAsset,
        uint256 _minNotionalReceiveQuantity,
        string memory _tradeAdapterName,
        bytes memory _tradeData
    ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

interface IProtocolDataProvider {
  struct TokenData {
    string symbol;
    address tokenAddress;
  }

  function ADDRESSES_PROVIDER() external view returns (address);
  function getAllReservesTokens() external view returns (TokenData[] memory);
  function getAllATokens() external view returns (TokenData[] memory);
  function getReserveConfigurationData(address asset) external view returns (uint256 decimals, uint256 ltv, uint256 liquidationThreshold, uint256 liquidationBonus, uint256 reserveFactor, bool usageAsCollateralEnabled, bool borrowingEnabled, bool stableBorrowRateEnabled, bool isActive, bool isFrozen);
  function getReserveData(address asset) external view returns (uint256 availableLiquidity, uint256 totalStableDebt, uint256 totalVariableDebt, uint256 liquidityRate, uint256 variableBorrowRate, uint256 stableBorrowRate, uint256 averageStableBorrowRate, uint256 liquidityIndex, uint256 variableBorrowIndex, uint40 lastUpdateTimestamp);
  function getUserReserveData(address asset, address user) external view returns (uint256 currentATokenBalance, uint256 currentStableDebt, uint256 currentVariableDebt, uint256 principalStableDebt, uint256 scaledVariableDebt, uint256 stableBorrowRate, uint256 liquidityRate, uint40 stableRateLastUpdated, bool usageAsCollateralEnabled);
  function getReserveTokensAddresses(address asset) external view returns (address aTokenAddress, address stableDebtTokenAddress, address variableDebtTokenAddress);
}

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ISetToken
 * @author Set Protocol
 *
 * Interface for operating with SetTokens.
 */
interface ISetToken is IERC20 {

    /* ============ Enums ============ */

    enum ModuleState {
        NONE,
        PENDING,
        INITIALIZED
    }

    /* ============ Structs ============ */
    /**
     * The base definition of a SetToken Position
     *
     * @param component           Address of token in the Position
     * @param module              If not in default state, the address of associated module
     * @param unit                Each unit is the # of components per 10^18 of a SetToken
     * @param positionState       Position ENUM. Default is 0; External is 1
     * @param data                Arbitrary data
     */
    struct Position {
        address component;
        address module;
        int256 unit;
        uint8 positionState;
        bytes data;
    }

    /**
     * A struct that stores a component's cash position details and external positions
     * This data structure allows O(1) access to a component's cash position units and 
     * virtual units.
     *
     * @param virtualUnit               Virtual value of a component's DEFAULT position. Stored as virtual for efficiency
     *                                  updating all units at once via the position multiplier. Virtual units are achieved
     *                                  by dividing a "real" value by the "positionMultiplier"
     * @param componentIndex            
     * @param externalPositionModules   List of external modules attached to each external position. Each module
     *                                  maps to an external position
     * @param externalPositions         Mapping of module => ExternalPosition struct for a given component
     */
    struct ComponentPosition {
      int256 virtualUnit;
      address[] externalPositionModules;
      mapping(address => ExternalPosition) externalPositions;
    }

    /**
     * A struct that stores a component's external position details including virtual unit and any
     * auxiliary data.
     *
     * @param virtualUnit       Virtual value of a component's EXTERNAL position.
     * @param data              Arbitrary data
     */
    struct ExternalPosition {
      int256 virtualUnit;
      bytes data;
    }


    /* ============ Functions ============ */
    
    function addComponent(address _component) external;
    function removeComponent(address _component) external;
    function editDefaultPositionUnit(address _component, int256 _realUnit) external;
    function addExternalPositionModule(address _component, address _positionModule) external;
    function removeExternalPositionModule(address _component, address _positionModule) external;
    function editExternalPositionUnit(address _component, address _positionModule, int256 _realUnit) external;
    function editExternalPositionData(address _component, address _positionModule, bytes calldata _data) external;

    function invoke(address _target, uint256 _value, bytes calldata _data) external returns(bytes memory);

    function editPositionMultiplier(int256 _newMultiplier) external;

    function mint(address _account, uint256 _quantity) external;
    function burn(address _account, uint256 _quantity) external;

    function lock() external;
    function unlock() external;

    function addModule(address _module) external;
    function removeModule(address _module) external;
    function initializeModule() external;

    function setManager(address _manager) external;

    function manager() external view returns (address);
    function moduleStates(address _module) external view returns (ModuleState);
    function getModules() external view returns (address[] memory);
    
    function getDefaultPositionRealUnit(address _component) external view returns(int256);
    function getExternalPositionRealUnit(address _component, address _positionModule) external view returns(int256);
    function getComponents() external view returns(address[] memory);
    function getExternalPositionModules(address _component) external view returns(address[] memory);
    function getExternalPositionData(address _component, address _positionModule) external view returns(bytes memory);
    function isExternalPositionModule(address _component, address _module) external view returns(bool);
    function isComponent(address _component) external view returns(bool);
    
    function positionMultiplier() external view returns (int256);
    function getPositions() external view returns (Position[] memory);
    function getTotalComponentRealUnits(address _component) external view returns(int256);

    function isInitializedModule(address _module) external view returns(bool);
    function isPendingModule(address _module) external view returns(bool);
    function isLocked() external view returns (bool);
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/math/SignedSafeMath.sol";


/**
 * @title PreciseUnitMath
 * @author Set Protocol
 *
 * Arithmetic for fixed-point numbers with 18 decimals of precision. Some functions taken from
 * dYdX's BaseMath library.
 *
 * CHANGELOG:
 * - 9/21/20: Added safePower function
 */
library PreciseUnitMath {
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    // The number One in precise units.
    uint256 constant internal PRECISE_UNIT = 10 ** 18;
    int256 constant internal PRECISE_UNIT_INT = 10 ** 18;

    // Max unsigned integer value
    uint256 constant internal MAX_UINT_256 = type(uint256).max;
    // Max and min signed integer value
    int256 constant internal MAX_INT_256 = type(int256).max;
    int256 constant internal MIN_INT_256 = type(int256).min;

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function preciseUnit() internal pure returns (uint256) {
        return PRECISE_UNIT;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function preciseUnitInt() internal pure returns (int256) {
        return PRECISE_UNIT_INT;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function maxUint256() internal pure returns (uint256) {
        return MAX_UINT_256;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function maxInt256() internal pure returns (int256) {
        return MAX_INT_256;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function minInt256() internal pure returns (int256) {
        return MIN_INT_256;
    }

    /**
     * @dev Multiplies value a by value b (result is rounded down). It's assumed that the value b is the significand
     * of a number with 18 decimals precision.
     */
    function preciseMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.mul(b).div(PRECISE_UNIT);
    }

    /**
     * @dev Multiplies value a by value b (result is rounded towards zero). It's assumed that the value b is the
     * significand of a number with 18 decimals precision.
     */
    function preciseMul(int256 a, int256 b) internal pure returns (int256) {
        return a.mul(b).div(PRECISE_UNIT_INT);
    }

    /**
     * @dev Multiplies value a by value b (result is rounded up). It's assumed that the value b is the significand
     * of a number with 18 decimals precision.
     */
    function preciseMulCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }
        return a.mul(b).sub(1).div(PRECISE_UNIT).add(1);
    }

    /**
     * @dev Divides value a by value b (result is rounded down).
     */
    function preciseDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.mul(PRECISE_UNIT).div(b);
    }


    /**
     * @dev Divides value a by value b (result is rounded towards 0).
     */
    function preciseDiv(int256 a, int256 b) internal pure returns (int256) {
        return a.mul(PRECISE_UNIT_INT).div(b);
    }

    /**
     * @dev Divides value a by value b (result is rounded up or away from 0).
     */
    function preciseDivCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "Cant divide by 0");

        return a > 0 ? a.mul(PRECISE_UNIT).sub(1).div(b).add(1) : 0;
    }

    /**
     * @dev Divides value a by value b (result is rounded down - positive numbers toward 0 and negative away from 0).
     */
    function divDown(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "Cant divide by 0");
        require(a != MIN_INT_256 || b != -1, "Invalid input");

        int256 result = a.div(b);
        if (a ^ b < 0 && a % b != 0) {
            result -= 1;
        }

        return result;
    }

    /**
     * @dev Multiplies value a by value b where rounding is towards the lesser number. 
     * (positive values are rounded towards zero and negative values are rounded away from 0). 
     */
    function conservativePreciseMul(int256 a, int256 b) internal pure returns (int256) {
        return divDown(a.mul(b), PRECISE_UNIT_INT);
    }

    /**
     * @dev Divides value a by value b where rounding is towards the lesser number. 
     * (positive values are rounded towards zero and negative values are rounded away from 0). 
     */
    function conservativePreciseDiv(int256 a, int256 b) internal pure returns (int256) {
        return divDown(a.mul(PRECISE_UNIT_INT), b);
    }

    /**
    * @dev Performs the power on a specified value, reverts on overflow.
    */
    function safePower(
        uint256 a,
        uint256 pow
    )
        internal
        pure
        returns (uint256)
    {
        require(a > 0, "Value must be positive");

        uint256 result = 1;
        for (uint256 i = 0; i < pow; i++){
            uint256 previousResult = result;

            // Using safemath multiplication prevents overflows
            result = previousResult.mul(a);
        }

        return result;
    }
}

/*
    Copyright 2021 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;

/**
 * @title StringArrayUtils
 * @author Set Protocol
 *
 * Utility functions to handle String Arrays
 */
library StringArrayUtils {

    /**
     * Finds the index of the first occurrence of the given element.
     * @param A The input string to search
     * @param a The value to find
     * @return Returns (index and isIn) for the first occurrence starting from index 0
     */
    function indexOf(string[] memory A, string memory a) internal pure returns (uint256, bool) {
        uint256 length = A.length;
        for (uint256 i = 0; i < length; i++) {
            if (keccak256(bytes(A[i])) == keccak256(bytes(a))) {
                return (i, true);
            }
        }
        return (uint256(-1), false);
    }

    /**
     * @param A The input array to search
     * @param a The string to remove
     */
    function removeStorage(string[] storage A, string memory a)
        internal
    {
        (uint256 index, bool isIn) = indexOf(A, a);
        if (!isIn) {
            revert("String not in array.");
        } else {
            uint256 lastIndex = A.length - 1; // If the array would be empty, the previous line would throw, so no underflow here
            if (index != lastIndex) { A[index] = A[lastIndex]; }
            A.pop();
        }
    }
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;

/**
 * @title AddressArrayUtils
 * @author Set Protocol
 *
 * Utility functions to handle Address Arrays
 *
 * CHANGELOG:
 * - 4/27/21: Added validatePairsWithArray methods
 */
library AddressArrayUtils {

    /**
     * Finds the index of the first occurrence of the given element.
     * @param A The input array to search
     * @param a The value to find
     * @return Returns (index and isIn) for the first occurrence starting from index 0
     */
    function indexOf(address[] memory A, address a) internal pure returns (uint256, bool) {
        uint256 length = A.length;
        for (uint256 i = 0; i < length; i++) {
            if (A[i] == a) {
                return (i, true);
            }
        }
        return (uint256(-1), false);
    }

    /**
    * Returns true if the value is present in the list. Uses indexOf internally.
    * @param A The input array to search
    * @param a The value to find
    * @return Returns isIn for the first occurrence starting from index 0
    */
    function contains(address[] memory A, address a) internal pure returns (bool) {
        (, bool isIn) = indexOf(A, a);
        return isIn;
    }

    /**
    * Returns true if there are 2 elements that are the same in an array
    * @param A The input array to search
    * @return Returns boolean for the first occurrence of a duplicate
    */
    function hasDuplicate(address[] memory A) internal pure returns(bool) {
        require(A.length > 0, "A is empty");

        for (uint256 i = 0; i < A.length - 1; i++) {
            address current = A[i];
            for (uint256 j = i + 1; j < A.length; j++) {
                if (current == A[j]) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * @param A The input array to search
     * @param a The address to remove
     * @return Returns the array with the object removed.
     */
    function remove(address[] memory A, address a)
        internal
        pure
        returns (address[] memory)
    {
        (uint256 index, bool isIn) = indexOf(A, a);
        if (!isIn) {
            revert("Address not in array.");
        } else {
            (address[] memory _A,) = pop(A, index);
            return _A;
        }
    }

    /**
     * @param A The input array to search
     * @param a The address to remove
     */
    function removeStorage(address[] storage A, address a)
        internal
    {
        (uint256 index, bool isIn) = indexOf(A, a);
        if (!isIn) {
            revert("Address not in array.");
        } else {
            uint256 lastIndex = A.length - 1; // If the array would be empty, the previous line would throw, so no underflow here
            if (index != lastIndex) { A[index] = A[lastIndex]; }
            A.pop();
        }
    }

    /**
    * Removes specified index from array
    * @param A The input array to search
    * @param index The index to remove
    * @return Returns the new array and the removed entry
    */
    function pop(address[] memory A, uint256 index)
        internal
        pure
        returns (address[] memory, address)
    {
        uint256 length = A.length;
        require(index < A.length, "Index must be < A length");
        address[] memory newAddresses = new address[](length - 1);
        for (uint256 i = 0; i < index; i++) {
            newAddresses[i] = A[i];
        }
        for (uint256 j = index + 1; j < length; j++) {
            newAddresses[j - 1] = A[j];
        }
        return (newAddresses, A[index]);
    }

    /**
     * Returns the combination of the two arrays
     * @param A The first array
     * @param B The second array
     * @return Returns A extended by B
     */
    function extend(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
        uint256 aLength = A.length;
        uint256 bLength = B.length;
        address[] memory newAddresses = new address[](aLength + bLength);
        for (uint256 i = 0; i < aLength; i++) {
            newAddresses[i] = A[i];
        }
        for (uint256 j = 0; j < bLength; j++) {
            newAddresses[aLength + j] = B[j];
        }
        return newAddresses;
    }

    /**
     * Validate that address and uint array lengths match. Validate address array is not empty
     * and contains no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of uint
     */
    function validatePairsWithArray(address[] memory A, uint[] memory B) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate that address and bool array lengths match. Validate address array is not empty
     * and contains no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of bool
     */
    function validatePairsWithArray(address[] memory A, bool[] memory B) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate that address and string array lengths match. Validate address array is not empty
     * and contains no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of strings
     */
    function validatePairsWithArray(address[] memory A, string[] memory B) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate that address array lengths match, and calling address array are not empty
     * and contain no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of addresses
     */
    function validatePairsWithArray(address[] memory A, address[] memory B) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate that address and bytes array lengths match. Validate address array is not empty
     * and contains no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of bytes
     */
    function validatePairsWithArray(address[] memory A, bytes[] memory B) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate address array is not empty and contains no duplicate elements.
     *
     * @param A          Array of addresses
     */
    function _validateLengthAndUniqueness(address[] memory A) internal pure {
        require(A.length > 0, "Array length must be > 0");
        require(!hasDuplicate(A), "Cannot duplicate addresses");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

/*
    Copyright 2021 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/
pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { FlexibleLeverageStrategyExtension } from "../adapters/FlexibleLeverageStrategyExtension.sol";
import { IFLIStrategyExtension } from "../interfaces/IFLIStrategyExtension.sol";
import { IQuoter } from "../interfaces/IQuoter.sol";
import { IUniswapV2Router } from "../interfaces/IUniswapV2Router.sol";
import { PreciseUnitMath } from "../lib/PreciseUnitMath.sol";
import { StringArrayUtils } from "../lib/StringArrayUtils.sol";


/**
 * @title FLIRebalanceViewer
 * @author Set Protocol
 *
 * Viewer contract for FlexibleLeverageStrategyExtension. Used by keeper bots to determine which exchanges to use when rebalancing.
 * This contract can only determine whether to use Uniswap V3 or Uniswap V2 (or forks) for rebalancing. Since AMMTradeSplitter adheres to
 * the Uniswap V2 router interface, this contract is compatible with that as well.
 */
contract FLIRebalanceViewer {

    using PreciseUnitMath  for uint256;
    using SafeMath for uint256;
    using StringArrayUtils for string[];

    /* ============ Structs ============ */

    struct ActionInfo {
        string[] exchangeNames;                                                     // List of enabled exchange names
        FlexibleLeverageStrategyExtension.ShouldRebalance[] rebalanceActions;       // List of rebalance actions with respect to exchangeNames
        uint256 uniV3Index;                                                         // Index of Uni V3 in both lists
        uint256 uniV2Index;                                                         // Index of Uni V2 in both lists
        uint256 minLeverage;                                                        // Minimum leverage ratio of strategy
        uint256 maxLeverage;                                                        // Maximum leverage ratio of strategy
        uint256[] chunkSendQuantity;                                                // Size of rebalances (quoted in sell asset units)
        address sellAsset;                                                          // Address of asset to sell during rebalance
        address buyAsset;                                                           // Address of asset to buy during rebalance
        bool isLever;                                                               // Whether the rebalance is a lever or delever
    }

    /* ============ State Variables ============ */

    IFLIStrategyExtension public fliStrategyExtension;

    IQuoter public uniswapV3Quoter;
    IUniswapV2Router public uniswapV2Router;

    string public uniswapV3ExchangeName;
    string public uniswapV2ExchangeName;

    /* ============ Constructor ============ */

    /**
     * Sets state variables
     *
     * @param _fliStrategyExtension     FlexibleLeverageStrategyAdapter contract address
     * @param _uniswapV3Quoter          Uniswap V3 Quoter contract address
     * @param _uniswapV2Router          Uniswap v2 Router contract address
     * @param _uniswapV3ExchangeName    Name of Uniswap V3 exchange in Set's IntegrationRegistry (ex: UniswapV3ExchangeAdapter)
     * @param _uniswapV2ExchangeName    Name of Uniswap V2 exchange in Set's IntegrationRegistry (ex: AMMSplitterExchangeAdapter)
     */
    constructor(
        IFLIStrategyExtension _fliStrategyExtension,
        IQuoter _uniswapV3Quoter,
        IUniswapV2Router _uniswapV2Router,
        string memory _uniswapV3ExchangeName,
        string memory _uniswapV2ExchangeName
    )
        public
    {
        fliStrategyExtension = _fliStrategyExtension;
        uniswapV3Quoter = _uniswapV3Quoter;
        uniswapV2Router = _uniswapV2Router;
        uniswapV3ExchangeName = _uniswapV3ExchangeName;
        uniswapV2ExchangeName = _uniswapV2ExchangeName;
    }

    /* =========== External Functions ============ */

    /**
     * Gets the priority order for which exchange should be used while rebalancing. Mimics the interface for
     * shouldRebalanceWithBound of FlexibleLeverageStrategyExtension. Note: this function is not marked as view
     * due to a quirk in the Uniswap V3 Quoter contract, but should be static called to save gas
     *
     * @param _minLeverageRatio       Min leverage ratio
     * @param _maxLeverageRatio       Max leverage ratio
     *
     * @return string[] memory              Ordered array of exchange names to use. Earlier elements in the array produce the best trades
     * @return ShouldRebalance[] memory     Array of ShouldRebalance Enums. Ordered relative to returned exchange names array
     */
    function shouldRebalanceWithBounds(
        uint256 _minLeverageRatio,
        uint256 _maxLeverageRatio
    )
        external
        returns(string[2] memory, FlexibleLeverageStrategyExtension.ShouldRebalance[2] memory)
    {

        ActionInfo memory actionInfo = _getActionInfo(_minLeverageRatio, _maxLeverageRatio);

        (uint256 uniswapV3Price, uint256 uniswapV2Price) = _getPrices(actionInfo);
        
        return _getExchangePriority(
            uniswapV3Price,
            uniswapV2Price,
            actionInfo
        );
    }

    /* ================= Internal Functions ================= */

    /**
     * Fetches prices for rebalancing trades on Uniswap V3 and Uniswap V2. Trade sizes are determined by FlexibleLeverageStrategyExtension's
     * getChunkRebalanceNotional.
     *
     * @param _actionInfo    ActionInfo struct
     *
     * @return uniswapV3Price   price of rebalancing trade on Uniswap V3 (scaled by trade size)
     * @return uniswapV2Price   price of rebalancing trade on Uniswap V2 (scaled by trade size)
     */
    function _getPrices(ActionInfo memory _actionInfo) internal returns (uint256 uniswapV3Price, uint256 uniswapV2Price) {
        uniswapV3Price = _getV3Price(_actionInfo.chunkSendQuantity[_actionInfo.uniV3Index], _actionInfo.isLever);
        uniswapV2Price = _getV2Price(
            _actionInfo.chunkSendQuantity[_actionInfo.uniV2Index],
            _actionInfo.isLever, _actionInfo.sellAsset, _actionInfo.buyAsset
        );
    }

    /**
     * Fetches price of a Uniswap V3 trade. Uniswap V3 fetches quotes using a write function that always reverts. This means that
     * this function cannot be view only. Additionally, the Uniswap V3 quoting function cannot be static called in solidity due to the
     * internal revert. To save on gas, static call the top level shouldRebalanceWithBounds function when interacting with this contact
     *
     * @param _sellSize     quantity of asset to sell
     * @param _isLever      whether FLI needs to lever or delever
     *
     * @return uint256      price of trade on Uniswap V3
     */
    function _getV3Price(uint256 _sellSize, bool _isLever) internal returns (uint256) {
        
        bytes memory uniswapV3TradePath = _isLever ? 
            fliStrategyExtension.getExchangeSettings(uniswapV3ExchangeName).leverExchangeData : 
            fliStrategyExtension.getExchangeSettings(uniswapV3ExchangeName).deleverExchangeData;

        uint256 outputAmount = uniswapV3Quoter.quoteExactInput(uniswapV3TradePath, _sellSize);

        // Divide to get ratio of quote / base asset. Don't care about decimals here. Standardizes to 10e18 with preciseDiv
        return outputAmount.preciseDiv(_sellSize);
    }

    /**
     * Fetches price of a Uniswap V2 trade
     *
     * @param _sellSize     quantity of asset to sell
     * @param _isLever      whether FLI needs to lever or delever
     *
     * @return uint256      price of trade on Uniswap V2
     */
    function _getV2Price(uint256 _sellSize, bool _isLever, address _sellAsset, address _buyAsset) internal view returns (uint256) {
        
        bytes memory uniswapV2TradePathRaw = _isLever ? 
            fliStrategyExtension.getExchangeSettings(uniswapV2ExchangeName).leverExchangeData : 
            fliStrategyExtension.getExchangeSettings(uniswapV2ExchangeName).deleverExchangeData;

        address[] memory uniswapV2TradePath;
        if (uniswapV2TradePathRaw.length == 0) {
            uniswapV2TradePath = new address[](2);
            uniswapV2TradePath[0] = _sellAsset;
            uniswapV2TradePath[1] = _buyAsset;
        } else {
            uniswapV2TradePath = abi.decode(uniswapV2TradePathRaw, (address[]));
        }
        
        uint256 outputAmount = uniswapV2Router.getAmountsOut(_sellSize, uniswapV2TradePath)[uniswapV2TradePath.length.sub(1)];
        
        // Divide to get ratio of quote / base asset. Don't care about decimals here. Standardizes to 10e18 with preciseDiv
        return outputAmount.preciseDiv(_sellSize);
    }

    /**
     * Gets the ordered priority of which exchanges to use for a rebalance
     *
     * @param _uniswapV3Price               price of rebalance trade on Uniswap V3
     * @param _uniswapV2Price               price of rebalance trade on Uniswap V2
     * @param _actionInfo                   ActionInfo struct
     *
     * @return string[] memory              Ordered array of exchange names to use. Earlier elements in the array produce the best trades
     * @return ShouldRebalance[] memory     Array of ShouldRebalance Enums. Ordered relative to returned exchange names array
     */
    function _getExchangePriority(
        uint256 _uniswapV3Price,
        uint256 _uniswapV2Price,
        ActionInfo memory _actionInfo
    )
        internal
        view
        returns (string[2] memory, FlexibleLeverageStrategyExtension.ShouldRebalance[2] memory)
    {

        // If no rebalance is required, set price to 0 so it is ordered last
        if (_actionInfo.rebalanceActions[_actionInfo.uniV3Index] == FlexibleLeverageStrategyExtension.ShouldRebalance.NONE) _uniswapV3Price = 0;
        if (_actionInfo.rebalanceActions[_actionInfo.uniV2Index] == FlexibleLeverageStrategyExtension.ShouldRebalance.NONE) _uniswapV2Price = 0;

        if (_uniswapV3Price > _uniswapV2Price) {
            return ([ uniswapV3ExchangeName, uniswapV2ExchangeName ],
                    [ _actionInfo.rebalanceActions[_actionInfo.uniV3Index], _actionInfo.rebalanceActions[_actionInfo.uniV2Index] ]);
        } else {
            return ([ uniswapV2ExchangeName, uniswapV3ExchangeName ],
                    [ _actionInfo.rebalanceActions[_actionInfo.uniV2Index], _actionInfo.rebalanceActions[_actionInfo.uniV3Index] ]);
        }
    }

    /**
     * Creates the an ActionInfo struct containing information about the rebalancing action
     *
     * @param _minLeverage          Min leverage ratio
     * @param _maxLeverage          Max leverage ratio
     *
     * @return actionInfo           Populated ActionInfo struct
     */
    function _getActionInfo(uint256 _minLeverage, uint256 _maxLeverage) internal view returns (ActionInfo memory actionInfo) {

        (actionInfo.exchangeNames, actionInfo.rebalanceActions) = fliStrategyExtension.shouldRebalanceWithBounds(
            _minLeverage,
            _maxLeverage
        );

        (actionInfo.uniV3Index, ) = actionInfo.exchangeNames.indexOf(uniswapV3ExchangeName);
        (actionInfo.uniV2Index, ) = actionInfo.exchangeNames.indexOf(uniswapV2ExchangeName);

        actionInfo.minLeverage = _minLeverage;
        actionInfo.maxLeverage = _maxLeverage;

        (actionInfo.chunkSendQuantity, actionInfo.sellAsset, actionInfo.buyAsset) = fliStrategyExtension.getChunkRebalanceNotional(
            actionInfo.exchangeNames
        );

        actionInfo.isLever = actionInfo.sellAsset == fliStrategyExtension.getStrategy().borrowAsset;
    }
}

/*
    Copyright 2021 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Math } from "@openzeppelin/contracts/math/Math.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/SafeCast.sol";

import { BaseExtension } from "../lib/BaseExtension.sol";
import { ICErc20 } from "../interfaces/ICErc20.sol";
import { IBaseManager } from "../interfaces/IBaseManager.sol";
import { IChainlinkAggregatorV3 } from "../interfaces/IChainlinkAggregatorV3.sol";
import { IComptroller } from "../interfaces/IComptroller.sol";
import { ILeverageModule } from "../interfaces/ILeverageModule.sol";
import { ISetToken } from "../interfaces/ISetToken.sol";
import { PreciseUnitMath } from "../lib/PreciseUnitMath.sol";
import { StringArrayUtils } from "../lib/StringArrayUtils.sol";


/**
 * @title FlexibleLeverageStrategyExtension
 * @author Set Protocol
 *
 * Smart contract that enables trustless leverage tokens using the flexible leverage methodology. This extension is paired with the CompoundLeverageModule from Set
 * protocol where module interactions are invoked via the IBaseManager contract. Any leveraged token can be constructed as long as the collateral and borrow
 * asset is available on Compound. This extension contract also allows the operator to set an ETH reward to incentivize keepers calling the rebalance function at
 * different leverage thresholds.
 *
 * CHANGELOG 4/14/2021:
 * - Update ExecutionSettings struct to split exchangeData into leverExchangeData and deleverExchangeData
 * - Update _lever and _delever internal functions with struct changes
 * - Update setExecutionSettings to account for leverExchangeData and deleverExchangeData
 *
 * CHANGELOG 5/24/2021:
 * - Update _calculateActionInfo to add chainlink prices
 * - Update _calculateBorrowUnits and _calculateMinRepayUnits to use chainlink as an oracle in
 *
 * CHANGELOG 6/29/2021: c55bd3cdb0fd43c03da9904493dcc23771ef0f71
 * - Add ExchangeSettings struct that contains exchange specific information
 * - Update ExecutionSettings struct to not include exchange information
 * - Add mapping of exchange names to ExchangeSettings structs and a list of enabled exchange names
 * - Update constructor to take an array of exchange names and an array of ExchangeSettings
 * - Add _exchangeName parameter to rebalancing functions to select which exchange to use
 * - Add permissioned addEnabledExchange, updateEnabledExchange, and removeEnabledExchange functions
 * - Add getChunkRebalanceNotional function
 * - Update shouldRebalance and shouldRebalanceWithBounds to return an array of ShouldRebalance enums and an array of exchange names
 * - Update _shouldRebalance to use exchange specific last trade timestamps
 * - Update _validateRipcord and _validateNormalRebalance to take in a timestamp parameter (so we can pass either global or exchange specific timestamp)
 * - Add _updateLastTradeTimestamp function to update global and exchange specific timestamp
 * - Change contract name to FlexibleLeverageStrategyExtension
 */
contract FlexibleLeverageStrategyExtension is BaseExtension {
    using Address for address;
    using PreciseUnitMath for uint256;
    using SafeMath for uint256;
    using SafeCast for int256;
    using StringArrayUtils for string[];

    /* ============ Enums ============ */

    enum ShouldRebalance {
        NONE,                   // Indicates no rebalance action can be taken
        REBALANCE,              // Indicates rebalance() function can be successfully called
        ITERATE_REBALANCE,      // Indicates iterateRebalance() function can be successfully called
        RIPCORD                 // Indicates ripcord() function can be successfully called
    }

    /* ============ Structs ============ */

    struct ActionInfo {
        uint256 collateralBalance;                      // Balance of underlying held in Compound in base units (e.g. USDC 10e6)
        uint256 borrowBalance;                          // Balance of underlying borrowed from Compound in base units
        uint256 collateralValue;                        // Valuation in USD adjusted for decimals in precise units (10e18)
        uint256 borrowValue;                            // Valuation in USD adjusted for decimals in precise units (10e18)
        uint256 collateralPrice;                        // Price of collateral in precise units (10e18) from Chainlink
        uint256 borrowPrice;                            // Price of borrow asset in precise units (10e18) from Chainlink
        uint256 setTotalSupply;                         // Total supply of SetToken
    }

     struct LeverageInfo {
        ActionInfo action;
        uint256 currentLeverageRatio;                   // Current leverage ratio of Set
        uint256 slippageTolerance;                      // Allowable percent trade slippage in preciseUnits (1% = 10^16)
        uint256 twapMaxTradeSize;                       // Max trade size in collateral units allowed for rebalance action
        string exchangeName;                            // Exchange to use for trade
    }

    struct ContractSettings {
        ISetToken setToken;                             // Instance of leverage token
        ILeverageModule leverageModule;                 // Instance of Compound leverage module
        IComptroller comptroller;                       // Instance of Compound Comptroller
        IChainlinkAggregatorV3 collateralPriceOracle;   // Chainlink oracle feed that returns prices in 8 decimals for collateral asset
        IChainlinkAggregatorV3 borrowPriceOracle;       // Chainlink oracle feed that returns prices in 8 decimals for borrow asset
        ICErc20 targetCollateralCToken;                 // Instance of target collateral cToken asset
        ICErc20 targetBorrowCToken;                     // Instance of target borrow cToken asset
        address collateralAsset;                        // Address of underlying collateral
        address borrowAsset;                            // Address of underlying borrow asset
        uint256 collateralDecimalAdjustment;            // Decimal adjustment for chainlink oracle of the collateral asset. Equal to 28-collateralDecimals (10^18 * 10^18 / 10^decimals / 10^8)
        uint256 borrowDecimalAdjustment;                // Decimal adjustment for chainlink oracle of the borrowing asset. Equal to 28-borrowDecimals (10^18 * 10^18 / 10^decimals / 10^8)
    }

    struct MethodologySettings {
        uint256 targetLeverageRatio;                     // Long term target ratio in precise units (10e18)
        uint256 minLeverageRatio;                        // In precise units (10e18). If current leverage is below, rebalance target is this ratio
        uint256 maxLeverageRatio;                        // In precise units (10e18). If current leverage is above, rebalance target is this ratio
        uint256 recenteringSpeed;                        // % at which to rebalance back to target leverage in precise units (10e18)
        uint256 rebalanceInterval;                       // Period of time required since last rebalance timestamp in seconds
    }

    struct ExecutionSettings {
        uint256 unutilizedLeveragePercentage;            // Percent of max borrow left unutilized in precise units (1% = 10e16)
        uint256 slippageTolerance;                       // % in precise units to price min token receive amount from trade quantities
        uint256 twapCooldownPeriod;                      // Cooldown period required since last trade timestamp in seconds
    }

    struct ExchangeSettings {
        uint256 twapMaxTradeSize;                        // Max trade size in collateral base units
        uint256 exchangeLastTradeTimestamp;              // Timestamp of last trade made with this exchange
        uint256 incentivizedTwapMaxTradeSize;            // Max trade size for incentivized rebalances in collateral base units
        bytes leverExchangeData;                         // Arbitrary exchange data passed into rebalance function for levering up
        bytes deleverExchangeData;                       // Arbitrary exchange data passed into rebalance function for delevering
    }

    struct IncentiveSettings {
        uint256 etherReward;                             // ETH reward for incentivized rebalances
        uint256 incentivizedLeverageRatio;               // Leverage ratio for incentivized rebalances
        uint256 incentivizedSlippageTolerance;           // Slippage tolerance percentage for incentivized rebalances
        uint256 incentivizedTwapCooldownPeriod;          // TWAP cooldown in seconds for incentivized rebalances
    }

    /* ============ Events ============ */

    event Engaged(uint256 _currentLeverageRatio, uint256 _newLeverageRatio, uint256 _chunkRebalanceNotional, uint256 _totalRebalanceNotional);
    event Rebalanced(
        uint256 _currentLeverageRatio,
        uint256 _newLeverageRatio,
        uint256 _chunkRebalanceNotional,
        uint256 _totalRebalanceNotional
    );
    event RebalanceIterated(
        uint256 _currentLeverageRatio,
        uint256 _newLeverageRatio,
        uint256 _chunkRebalanceNotional,
        uint256 _totalRebalanceNotional
    );
    event RipcordCalled(
        uint256 _currentLeverageRatio,
        uint256 _newLeverageRatio,
        uint256 _rebalanceNotional,
        uint256 _etherIncentive
    );
    event Disengaged(uint256 _currentLeverageRatio, uint256 _newLeverageRatio, uint256 _chunkRebalanceNotional, uint256 _totalRebalanceNotional);
    event MethodologySettingsUpdated(
        uint256 _targetLeverageRatio,
        uint256 _minLeverageRatio,
        uint256 _maxLeverageRatio,
        uint256 _recenteringSpeed,
        uint256 _rebalanceInterval
    );
    event ExecutionSettingsUpdated(
        uint256 _unutilizedLeveragePercentage,
        uint256 _twapCooldownPeriod,
        uint256 _slippageTolerance
    );
    event IncentiveSettingsUpdated(
        uint256 _etherReward,
        uint256 _incentivizedLeverageRatio,
        uint256 _incentivizedSlippageTolerance,
        uint256 _incentivizedTwapCooldownPeriod
    );
    event ExchangeUpdated(
        string _exchangeName,
        uint256 twapMaxTradeSize,
        uint256 exchangeLastTradeTimestamp,
        uint256 incentivizedTwapMaxTradeSize,
        bytes leverExchangeData,
        bytes deleverExchangeData
    );
    event ExchangeAdded(
        string _exchangeName,
        uint256 twapMaxTradeSize,
        uint256 exchangeLastTradeTimestamp,
        uint256 incentivizedTwapMaxTradeSize,
        bytes leverExchangeData,
        bytes deleverExchangeData
    );
    event ExchangeRemoved(
        string _exchangeName
    );

    /* ============ Modifiers ============ */

    /**
     * Throws if rebalance is currently in TWAP`
     */
    modifier noRebalanceInProgress() {
        require(twapLeverageRatio == 0, "Rebalance is currently in progress");
        _;
    }

    /* ============ State Variables ============ */

    ContractSettings internal strategy;                             // Struct of contracts used in the strategy (SetToken, price oracles, leverage module etc)
    MethodologySettings internal methodology;                       // Struct containing methodology parameters
    ExecutionSettings internal execution;                           // Struct containing execution parameters
    mapping(string => ExchangeSettings) internal exchangeSettings;  // Mapping from exchange name to exchange settings
    IncentiveSettings internal incentive;                           // Struct containing incentive parameters for ripcord
    string[] public enabledExchanges;                               // Array containing enabled exchanges
    uint256 public twapLeverageRatio;                               // Stored leverage ratio to keep track of target between TWAP rebalances
    uint256 public globalLastTradeTimestamp;                        // Last rebalance timestamp. Current timestamp must be greater than this variable + rebalance interval to rebalance

    /* ============ Constructor ============ */

    /**
     * Instantiate addresses, methodology parameters, execution parameters, and incentive parameters.
     *
     * @param _manager                  Address of IBaseManager contract
     * @param _strategy                 Struct of contract addresses
     * @param _methodology              Struct containing methodology parameters
     * @param _execution                Struct containing execution parameters
     * @param _incentive                Struct containing incentive parameters for ripcord
     * @param _exchangeNames            List of initial exchange names
     * @param _exchangeSettings         List of structs containing exchange parameters for the initial exchanges
     */
    constructor(
        IBaseManager _manager,
        ContractSettings memory _strategy,
        MethodologySettings memory _methodology,
        ExecutionSettings memory _execution,
        IncentiveSettings memory _incentive,
        string[] memory _exchangeNames,
        ExchangeSettings[] memory _exchangeSettings
    )
        public
        BaseExtension(_manager)
    {
        strategy = _strategy;
        methodology = _methodology;
        execution = _execution;
        incentive = _incentive;

        for (uint256 i = 0; i < _exchangeNames.length; i++) {
            _validateExchangeSettings(_exchangeSettings[i]);
            exchangeSettings[_exchangeNames[i]] = _exchangeSettings[i];
            enabledExchanges.push(_exchangeNames[i]);
        }

        _validateNonExchangeSettings(methodology, execution, incentive);
    }

    /* ============ External Functions ============ */

    /**
     * OPERATOR ONLY: Engage to target leverage ratio for the first time. SetToken will borrow debt position from Compound and trade for collateral asset. If target
     * leverage ratio is above max borrow or max trade size, then TWAP is kicked off. To complete engage if TWAP, any valid caller must call iterateRebalance until target
     * is met.
     *
     * @param _exchangeName     the exchange used for trading
     */
    function engage(string memory _exchangeName) external onlyOperator {
        ActionInfo memory engageInfo = _createActionInfo();

        require(engageInfo.setTotalSupply > 0, "SetToken must have > 0 supply");
        require(engageInfo.collateralBalance > 0, "Collateral balance must be > 0");
        require(engageInfo.borrowBalance == 0, "Debt must be 0");

        LeverageInfo memory leverageInfo = LeverageInfo({
            action: engageInfo,
            currentLeverageRatio: PreciseUnitMath.preciseUnit(), // 1x leverage in precise units
            slippageTolerance: execution.slippageTolerance,
            twapMaxTradeSize: exchangeSettings[_exchangeName].twapMaxTradeSize,
            exchangeName: _exchangeName
        });

        // Calculate total rebalance units and kick off TWAP if above max borrow or max trade size
        (
            uint256 chunkRebalanceNotional,
            uint256 totalRebalanceNotional
        ) = _calculateChunkRebalanceNotional(leverageInfo, methodology.targetLeverageRatio, true);

        _lever(leverageInfo, chunkRebalanceNotional);

        _updateRebalanceState(
            chunkRebalanceNotional,
            totalRebalanceNotional,
            methodology.targetLeverageRatio,
            _exchangeName
        );

        emit Engaged(
            leverageInfo.currentLeverageRatio,
            methodology.targetLeverageRatio,
            chunkRebalanceNotional,
            totalRebalanceNotional
        );
    }

    /**
     * ONLY EOA AND ALLOWED CALLER: Rebalance according to flexible leverage methodology. If current leverage ratio is between the max and min bounds, then rebalance
     * can only be called once the rebalance interval has elapsed since last timestamp. If outside the max and min, rebalance can be called anytime to bring leverage
     * ratio back to the max or min bounds. The methodology will determine whether to delever or lever.
     *
     * Note: If the calculated current leverage ratio is above the incentivized leverage ratio or in TWAP then rebalance cannot be called. Instead, you must call
     * ripcord() which is incentivized with a reward in Ether or iterateRebalance().
     *
     * @param _exchangeName     the exchange used for trading
     */
     function rebalance(string memory _exchangeName) external onlyEOA onlyAllowedCaller(msg.sender) {
        LeverageInfo memory leverageInfo = _getAndValidateLeveragedInfo(
            execution.slippageTolerance,
            exchangeSettings[_exchangeName].twapMaxTradeSize,
            _exchangeName
        );

        // use globalLastTradeTimestamps to prevent multiple rebalances being called with different exchanges during the epoch rebalance
        _validateNormalRebalance(leverageInfo, methodology.rebalanceInterval, globalLastTradeTimestamp);
        _validateNonTWAP();

        uint256 newLeverageRatio = _calculateNewLeverageRatio(leverageInfo.currentLeverageRatio);

        (
            uint256 chunkRebalanceNotional,
            uint256 totalRebalanceNotional
        ) = _handleRebalance(leverageInfo, newLeverageRatio);

        _updateRebalanceState(chunkRebalanceNotional, totalRebalanceNotional, newLeverageRatio, _exchangeName);

        emit Rebalanced(
            leverageInfo.currentLeverageRatio,
            newLeverageRatio,
            chunkRebalanceNotional,
            totalRebalanceNotional
        );
    }

    /**
     * ONLY EOA AND ALLOWED CALLER: Iterate a rebalance when in TWAP. TWAP cooldown period must have elapsed. If price moves advantageously, then exit without rebalancing
     * and clear TWAP state. This function can only be called when below incentivized leverage ratio and in TWAP state.
     *
     * @param _exchangeName     the exchange used for trading
     */
    function iterateRebalance(string memory _exchangeName) external onlyEOA onlyAllowedCaller(msg.sender) {
        LeverageInfo memory leverageInfo = _getAndValidateLeveragedInfo(
            execution.slippageTolerance,
            exchangeSettings[_exchangeName].twapMaxTradeSize,
            _exchangeName
        );

        // Use the exchangeLastTradeTimestamp since cooldown periods are measured on a per-exchange basis, allowing it to rebalance multiple time in quick
        // succession with different exchanges
        _validateNormalRebalance(leverageInfo, execution.twapCooldownPeriod, exchangeSettings[_exchangeName].exchangeLastTradeTimestamp);
        _validateTWAP();

        uint256 chunkRebalanceNotional;
        uint256 totalRebalanceNotional;
        if (!_isAdvantageousTWAP(leverageInfo.currentLeverageRatio)) {
            (chunkRebalanceNotional, totalRebalanceNotional) = _handleRebalance(leverageInfo, twapLeverageRatio);
        }

        // If not advantageous, then rebalance is skipped and chunk and total rebalance notional are both 0, which means TWAP state is
        // cleared
        _updateIterateState(chunkRebalanceNotional, totalRebalanceNotional, _exchangeName);

        emit RebalanceIterated(
            leverageInfo.currentLeverageRatio,
            twapLeverageRatio,
            chunkRebalanceNotional,
            totalRebalanceNotional
        );
    }

    /**
     * ONLY EOA: In case the current leverage ratio exceeds the incentivized leverage threshold, the ripcord function can be called by anyone to return leverage ratio
     * back to the max leverage ratio. This function typically would only be called during times of high downside volatility and / or normal keeper malfunctions. The caller
     * of ripcord() will receive a reward in Ether. The ripcord function uses it's own TWAP cooldown period, slippage tolerance and TWAP max trade size which are typically
     * looser than in regular rebalances.
     *
     * @param _exchangeName     the exchange used for trading
     */
    function ripcord(string memory _exchangeName) external onlyEOA {
        LeverageInfo memory leverageInfo = _getAndValidateLeveragedInfo(
            incentive.incentivizedSlippageTolerance,
            exchangeSettings[_exchangeName].incentivizedTwapMaxTradeSize,
            _exchangeName
        );

        // Use the exchangeLastTradeTimestamp so it can ripcord quickly with multiple exchanges
        _validateRipcord(leverageInfo, exchangeSettings[_exchangeName].exchangeLastTradeTimestamp);

        ( uint256 chunkRebalanceNotional, ) = _calculateChunkRebalanceNotional(leverageInfo, methodology.maxLeverageRatio, false);

        _delever(leverageInfo, chunkRebalanceNotional);

        _updateRipcordState(_exchangeName);

        uint256 etherTransferred = _transferEtherRewardToCaller(incentive.etherReward);

        emit RipcordCalled(
            leverageInfo.currentLeverageRatio,
            methodology.maxLeverageRatio,
            chunkRebalanceNotional,
            etherTransferred
        );
    }

    /**
     * OPERATOR ONLY: Return leverage ratio to 1x and delever to repay loan. This can be used for upgrading or shutting down the strategy. SetToken will redeem
     * collateral position and trade for debt position to repay Compound. If the chunk rebalance size is less than the total notional size, then this function will
     * delever and repay entire borrow balance on Compound. If chunk rebalance size is above max borrow or max trade size, then operator must
     * continue to call this function to complete repayment of loan. The function iterateRebalance will not work.
     *
     * Note: Delever to 0 will likely result in additional units of the borrow asset added as equity on the SetToken due to oracle price / market price mismatch
     *
     * @param _exchangeName     the exchange used for trading
     */
    function disengage(string memory _exchangeName) external onlyOperator {
        LeverageInfo memory leverageInfo = _getAndValidateLeveragedInfo(
            execution.slippageTolerance,
            exchangeSettings[_exchangeName].twapMaxTradeSize,
            _exchangeName
        );

        uint256 newLeverageRatio = PreciseUnitMath.preciseUnit();

        (
            uint256 chunkRebalanceNotional,
            uint256 totalRebalanceNotional
        ) = _calculateChunkRebalanceNotional(leverageInfo, newLeverageRatio, false);

        if (totalRebalanceNotional > chunkRebalanceNotional) {
            _delever(leverageInfo, chunkRebalanceNotional);
        } else {
            _deleverToZeroBorrowBalance(leverageInfo, totalRebalanceNotional);
        }

        emit Disengaged(
            leverageInfo.currentLeverageRatio,
            newLeverageRatio,
            chunkRebalanceNotional,
            totalRebalanceNotional
        );
    }

    /**
     * OPERATOR ONLY: Set methodology settings and check new settings are valid. Note: Need to pass in existing parameters if only changing a few settings. Must not be
     * in a rebalance.
     *
     * @param _newMethodologySettings          Struct containing methodology parameters
     */
    function setMethodologySettings(MethodologySettings memory _newMethodologySettings) external onlyOperator noRebalanceInProgress {
        methodology = _newMethodologySettings;

        _validateNonExchangeSettings(methodology, execution, incentive);

        emit MethodologySettingsUpdated(
            methodology.targetLeverageRatio,
            methodology.minLeverageRatio,
            methodology.maxLeverageRatio,
            methodology.recenteringSpeed,
            methodology.rebalanceInterval
        );
    }

    /**
     * OPERATOR ONLY: Set execution settings and check new settings are valid. Note: Need to pass in existing parameters if only changing a few settings. Must not be
     * in a rebalance.
     *
     * @param _newExecutionSettings          Struct containing execution parameters
     */
    function setExecutionSettings(ExecutionSettings memory _newExecutionSettings) external onlyOperator noRebalanceInProgress {
        execution = _newExecutionSettings;

        _validateNonExchangeSettings(methodology, execution, incentive);

        emit ExecutionSettingsUpdated(
            execution.unutilizedLeveragePercentage,
            execution.twapCooldownPeriod,
            execution.slippageTolerance
        );
    }

    /**
     * OPERATOR ONLY: Set incentive settings and check new settings are valid. Note: Need to pass in existing parameters if only changing a few settings. Must not be
     * in a rebalance.
     *
     * @param _newIncentiveSettings          Struct containing incentive parameters
     */
    function setIncentiveSettings(IncentiveSettings memory _newIncentiveSettings) external onlyOperator noRebalanceInProgress {
        incentive = _newIncentiveSettings;

        _validateNonExchangeSettings(methodology, execution, incentive);

        emit IncentiveSettingsUpdated(
            incentive.etherReward,
            incentive.incentivizedLeverageRatio,
            incentive.incentivizedSlippageTolerance,
            incentive.incentivizedTwapCooldownPeriod
        );
    }

    /**
     * OPERATOR ONLY: Add a new enabled exchange for trading during rebalances. New exchanges will have their exchangeLastTradeTimestamp set to 0. Adding
     * exchanges during rebalances is allowed, as it is not possible to enter an unexpected state while doing so.
     *
     * @param _exchangeName         Name of the exchange
     * @param _exchangeSettings     Struct containing exchange parameters
     */
    function addEnabledExchange(
        string memory _exchangeName,
        ExchangeSettings memory _exchangeSettings
    )
        external
        onlyOperator
    {
        require(exchangeSettings[_exchangeName].twapMaxTradeSize == 0, "Exchange already enabled");
        _validateExchangeSettings(_exchangeSettings);

        exchangeSettings[_exchangeName].twapMaxTradeSize = _exchangeSettings.twapMaxTradeSize;
        exchangeSettings[_exchangeName].incentivizedTwapMaxTradeSize = _exchangeSettings.incentivizedTwapMaxTradeSize;
        exchangeSettings[_exchangeName].leverExchangeData = _exchangeSettings.leverExchangeData;
        exchangeSettings[_exchangeName].deleverExchangeData = _exchangeSettings.deleverExchangeData;
        exchangeSettings[_exchangeName].exchangeLastTradeTimestamp = 0;

        enabledExchanges.push(_exchangeName);

        emit ExchangeAdded(
            _exchangeName,
            _exchangeSettings.twapMaxTradeSize,
            _exchangeSettings.exchangeLastTradeTimestamp,
            _exchangeSettings.incentivizedTwapMaxTradeSize,
            _exchangeSettings.leverExchangeData,
            _exchangeSettings.deleverExchangeData
        );
    }

    /**
     * OPERATOR ONLY: Removes an exchange. Reverts if the exchange is not already enabled. Removing exchanges during rebalances is allowed,
     * as it is not possible to enter an unexpected state while doing so.
     *
     * @param _exchangeName     Name of exchange to remove
     */
    function removeEnabledExchange(string memory _exchangeName) external onlyOperator {
        require(exchangeSettings[_exchangeName].twapMaxTradeSize != 0, "Exchange not enabled");

        delete exchangeSettings[_exchangeName];
        enabledExchanges.removeStorage(_exchangeName);

        emit ExchangeRemoved(_exchangeName);
    }

    /**
     * OPERATOR ONLY: Updates the settings of an exchange. Reverts if exchange is not already added. When updating an exchange, exchangeLastTradeTimestamp
     * is preserved. Updating exchanges during rebalances is allowed, as it is not possible to enter an unexpected state while doing so. Note: Need to
     * pass in all existing parameters even if only changing a few settings.
     *
     * @param _exchangeName         Name of the exchange
     * @param _exchangeSettings     Struct containing exchange parameters
     */
    function updateEnabledExchange(
        string memory _exchangeName,
        ExchangeSettings memory _exchangeSettings
    )
        external
        onlyOperator
    {
        require(exchangeSettings[_exchangeName].twapMaxTradeSize != 0, "Exchange not enabled");
        _validateExchangeSettings(_exchangeSettings);

        exchangeSettings[_exchangeName].twapMaxTradeSize = _exchangeSettings.twapMaxTradeSize;
        exchangeSettings[_exchangeName].incentivizedTwapMaxTradeSize = _exchangeSettings.incentivizedTwapMaxTradeSize;
        exchangeSettings[_exchangeName].leverExchangeData = _exchangeSettings.leverExchangeData;
        exchangeSettings[_exchangeName].deleverExchangeData = _exchangeSettings.deleverExchangeData;

        emit ExchangeUpdated(
            _exchangeName,
            _exchangeSettings.twapMaxTradeSize,
            _exchangeSettings.exchangeLastTradeTimestamp,
            _exchangeSettings.incentivizedTwapMaxTradeSize,
            _exchangeSettings.leverExchangeData,
            _exchangeSettings.deleverExchangeData
        );
    }

    /**
     * OPERATOR ONLY: Withdraw entire balance of ETH in this contract to operator. Rebalance must not be in progress
     */
    function withdrawEtherBalance() external onlyOperator noRebalanceInProgress {
        msg.sender.transfer(address(this).balance);
    }

    receive() external payable {}

    /* ============ External Getter Functions ============ */

    /**
     * Get current leverage ratio. Current leverage ratio is defined as the USD value of the collateral divided by the USD value of the SetToken. Prices for collateral
     * and borrow asset are retrieved from the Compound Price Oracle.
     *
     * return currentLeverageRatio         Current leverage ratio in precise units (10e18)
     */
    function getCurrentLeverageRatio() public view returns(uint256) {
        ActionInfo memory currentLeverageInfo = _createActionInfo();

        return _calculateCurrentLeverageRatio(currentLeverageInfo.collateralValue, currentLeverageInfo.borrowValue);
    }

    /**
     * Calculates the chunk rebalance size. This can be used by external contracts and keeper bots to calculate the optimal exchange to rebalance with.
     * Note: this function does not take into account timestamps, so it may return a nonzero value even when shouldRebalance would return ShouldRebalance.NONE for
     * all exchanges (since minimum delays have not elapsed)
     *
     * @param _exchangeNames    Array of exchange names to get rebalance sizes for
     *
     * @return sizes            Array of total notional chunk size. Measured in the asset that would be sold
     * @return sellAsset        Asset that would be sold during a rebalance
     * @return buyAsset         Asset that would be purchased during a rebalance
     */
    function getChunkRebalanceNotional(
        string[] calldata _exchangeNames
    )
        external
        view
        returns(uint256[] memory sizes, address sellAsset, address buyAsset)
    {

        uint256 newLeverageRatio;
        uint256 currentLeverageRatio = getCurrentLeverageRatio();
        bool isRipcord = false;

        // if over incentivized leverage ratio, always ripcord
        if (currentLeverageRatio > incentive.incentivizedLeverageRatio) {
            newLeverageRatio = methodology.maxLeverageRatio;
            isRipcord = true;
        // if we are in an ongoing twap, use the cached twapLeverageRatio as our target leverage
        } else if (twapLeverageRatio > 0) {
            newLeverageRatio = twapLeverageRatio;
        // if all else is false, then we would just use the normal rebalance new leverage ratio calculation
        } else {
            newLeverageRatio = _calculateNewLeverageRatio(currentLeverageRatio);
        }

        ActionInfo memory actionInfo = _createActionInfo();
        bool isLever = newLeverageRatio > currentLeverageRatio;

        sizes = new uint256[](_exchangeNames.length);

        for (uint256 i = 0; i < _exchangeNames.length; i++) {

            LeverageInfo memory leverageInfo = LeverageInfo({
                action: actionInfo,
                currentLeverageRatio: currentLeverageRatio,
                slippageTolerance: isRipcord ? incentive.incentivizedSlippageTolerance : execution.slippageTolerance,
                twapMaxTradeSize: isRipcord ?
                    exchangeSettings[_exchangeNames[i]].incentivizedTwapMaxTradeSize :
                    exchangeSettings[_exchangeNames[i]].twapMaxTradeSize,
                exchangeName: _exchangeNames[i]
            });

            (uint256 collateralNotional, ) = _calculateChunkRebalanceNotional(leverageInfo, newLeverageRatio, isLever);

            // _calculateBorrowUnits can convert both unit and notional values
            sizes[i] = isLever ? _calculateBorrowUnits(collateralNotional, leverageInfo.action) : collateralNotional;
        }

        sellAsset = isLever ? strategy.borrowAsset : strategy.collateralAsset;
        buyAsset = isLever ? strategy.collateralAsset : strategy.borrowAsset;
    }

    /**
     * Get current Ether incentive for when current leverage ratio exceeds incentivized leverage ratio and ripcord can be called. If ETH balance on the contract is
     * below the etherReward, then return the balance of ETH instead.
     *
     * return etherReward               Quantity of ETH reward in base units (10e18)
     */
    function getCurrentEtherIncentive() external view returns(uint256) {
        uint256 currentLeverageRatio = getCurrentLeverageRatio();

        if (currentLeverageRatio >= incentive.incentivizedLeverageRatio) {
            // If ETH reward is below the balance on this contract, then return ETH balance on contract instead
            return incentive.etherReward < address(this).balance ? incentive.etherReward : address(this).balance;
        } else {
            return 0;
        }
    }

    /**
     * Helper that checks if conditions are met for rebalance or ripcord. Returns an enum with 0 = no rebalance, 1 = call rebalance(), 2 = call iterateRebalance()
     * 3 = call ripcord()
     *
     * @return (string[] memory, ShouldRebalance[] memory)      List of exchange names and a list of enums representing whether that exchange should rebalance
     */
    function shouldRebalance() external view returns(string[] memory, ShouldRebalance[] memory) {
        uint256 currentLeverageRatio = getCurrentLeverageRatio();

        return _shouldRebalance(currentLeverageRatio, methodology.minLeverageRatio, methodology.maxLeverageRatio);
    }

    /**
     * Helper that checks if conditions are met for rebalance or ripcord with custom max and min bounds specified by caller. This function simplifies the
     * logic for off-chain keeper bots to determine what threshold to call rebalance when leverage exceeds max or drops below min. Returns an enum with
     * 0 = no rebalance, 1 = call rebalance(), 2 = call iterateRebalance()3 = call ripcord()
     *
     * @param _customMinLeverageRatio          Min leverage ratio passed in by caller
     * @param _customMaxLeverageRatio          Max leverage ratio passed in by caller
     *
     * @return (string[] memory, ShouldRebalance[] memory)      List of exchange names and a list of enums representing whether that exchange should rebalance
     */
    function shouldRebalanceWithBounds(
        uint256 _customMinLeverageRatio,
        uint256 _customMaxLeverageRatio
    )
        external
        view
        returns(string[] memory, ShouldRebalance[] memory)
    {
        require (
            _customMinLeverageRatio <= methodology.minLeverageRatio && _customMaxLeverageRatio >= methodology.maxLeverageRatio,
            "Custom bounds must be valid"
        );

        uint256 currentLeverageRatio = getCurrentLeverageRatio();

        return _shouldRebalance(currentLeverageRatio, _customMinLeverageRatio, _customMaxLeverageRatio);
    }

    /**
     * Gets the list of enabled exchanges
     */
    function getEnabledExchanges() external view returns (string[] memory) {
        return enabledExchanges;
    }

    /**
     * Explicit getter functions for parameter structs are defined as workaround to issues fetching structs that have dynamic types.
     */
    function getStrategy() external view returns (ContractSettings memory) { return strategy; }
    function getMethodology() external view returns (MethodologySettings memory) { return methodology; }
    function getExecution() external view returns (ExecutionSettings memory) { return execution; }
    function getIncentive() external view returns (IncentiveSettings memory) { return incentive; }
    function getExchangeSettings(string memory _exchangeName) external view returns (ExchangeSettings memory) {
        return exchangeSettings[_exchangeName];
    }

    /* ============ Internal Functions ============ */

    /**
     * Calculate notional rebalance quantity, whether to chunk rebalance based on max trade size and max borrow and invoke lever on CompoundLeverageModule
     *
     */
     function _lever(
        LeverageInfo memory _leverageInfo,
        uint256 _chunkRebalanceNotional
    )
        internal
    {
        uint256 collateralRebalanceUnits = _chunkRebalanceNotional.preciseDiv(_leverageInfo.action.setTotalSupply);

        uint256 borrowUnits = _calculateBorrowUnits(collateralRebalanceUnits, _leverageInfo.action);

        uint256 minReceiveCollateralUnits = _calculateMinCollateralReceiveUnits(collateralRebalanceUnits, _leverageInfo.slippageTolerance);

        bytes memory leverCallData = abi.encodeWithSignature(
            "lever(address,address,address,uint256,uint256,string,bytes)",
            address(strategy.setToken),
            strategy.borrowAsset,
            strategy.collateralAsset,
            borrowUnits,
            minReceiveCollateralUnits,
            _leverageInfo.exchangeName,
            exchangeSettings[_leverageInfo.exchangeName].leverExchangeData
        );

        invokeManager(address(strategy.leverageModule), leverCallData);
    }

    /**
     * Calculate delever units Invoke delever on CompoundLeverageModule.
     */
    function _delever(
        LeverageInfo memory _leverageInfo,
        uint256 _chunkRebalanceNotional
    )
        internal
    {
        uint256 collateralRebalanceUnits = _chunkRebalanceNotional.preciseDiv(_leverageInfo.action.setTotalSupply);

        uint256 minRepayUnits = _calculateMinRepayUnits(collateralRebalanceUnits, _leverageInfo.slippageTolerance, _leverageInfo.action);

        bytes memory deleverCallData = abi.encodeWithSignature(
            "delever(address,address,address,uint256,uint256,string,bytes)",
            address(strategy.setToken),
            strategy.collateralAsset,
            strategy.borrowAsset,
            collateralRebalanceUnits,
            minRepayUnits,
            _leverageInfo.exchangeName,
            exchangeSettings[_leverageInfo.exchangeName].deleverExchangeData
        );

        invokeManager(address(strategy.leverageModule), deleverCallData);
    }

    /**
     * Invoke deleverToZeroBorrowBalance on CompoundLeverageModule.
     */
    function _deleverToZeroBorrowBalance(
        LeverageInfo memory _leverageInfo,
        uint256 _chunkRebalanceNotional
    )
        internal
    {
        // Account for slippage tolerance in redeem quantity for the deleverToZeroBorrowBalance function
        uint256 maxCollateralRebalanceUnits = _chunkRebalanceNotional
            .preciseMul(PreciseUnitMath.preciseUnit().add(execution.slippageTolerance))
            .preciseDiv(_leverageInfo.action.setTotalSupply);

        bytes memory deleverToZeroBorrowBalanceCallData = abi.encodeWithSignature(
            "deleverToZeroBorrowBalance(address,address,address,uint256,string,bytes)",
            address(strategy.setToken),
            strategy.collateralAsset,
            strategy.borrowAsset,
            maxCollateralRebalanceUnits,
            _leverageInfo.exchangeName,
            exchangeSettings[_leverageInfo.exchangeName].deleverExchangeData
        );

        invokeManager(address(strategy.leverageModule), deleverToZeroBorrowBalanceCallData);
    }

    /**
     * Check whether to delever or lever based on the current vs new leverage ratios. Used in the rebalance() and iterateRebalance() functions
     *
     * return uint256           Calculated notional to trade
     * return uint256           Total notional to rebalance over TWAP
     */
    function _handleRebalance(LeverageInfo memory _leverageInfo, uint256 _newLeverageRatio) internal returns(uint256, uint256) {
        uint256 chunkRebalanceNotional;
        uint256 totalRebalanceNotional;
        if (_newLeverageRatio < _leverageInfo.currentLeverageRatio) {
            (
                chunkRebalanceNotional,
                totalRebalanceNotional
            ) = _calculateChunkRebalanceNotional(_leverageInfo, _newLeverageRatio, false);

            _delever(_leverageInfo, chunkRebalanceNotional);
        } else {
            (
                chunkRebalanceNotional,
                totalRebalanceNotional
            ) = _calculateChunkRebalanceNotional(_leverageInfo, _newLeverageRatio, true);

            _lever(_leverageInfo, chunkRebalanceNotional);
        }

        return (chunkRebalanceNotional, totalRebalanceNotional);
    }

    /**
     * Create the leverage info struct to be used in internal functions
     *
     * return LeverageInfo                Struct containing ActionInfo and other data
     */
    function _getAndValidateLeveragedInfo(uint256 _slippageTolerance, uint256 _maxTradeSize, string memory _exchangeName) internal view returns(LeverageInfo memory) {
        // Assume if maxTradeSize is 0, then the exchange is not enabled. This is enforced by addEnabledExchange and updateEnabledExchange
        require(_maxTradeSize > 0, "Must be valid exchange");

        ActionInfo memory actionInfo = _createActionInfo();

        require(actionInfo.setTotalSupply > 0, "SetToken must have > 0 supply");
        require(actionInfo.collateralBalance > 0, "Collateral balance must be > 0");
        require(actionInfo.borrowBalance > 0, "Borrow balance must exist");

        // Get current leverage ratio
        uint256 currentLeverageRatio = _calculateCurrentLeverageRatio(
            actionInfo.collateralValue,
            actionInfo.borrowValue
        );

        return LeverageInfo({
            action: actionInfo,
            currentLeverageRatio: currentLeverageRatio,
            slippageTolerance: _slippageTolerance,
            twapMaxTradeSize: _maxTradeSize,
            exchangeName: _exchangeName
        });
    }

    /**
     * Create the action info struct to be used in internal functions
     *
     * return ActionInfo                Struct containing data used by internal lever and delever functions
     */
    function _createActionInfo() internal view returns(ActionInfo memory) {
        ActionInfo memory rebalanceInfo;

        // Calculate prices from chainlink. Adjusts decimals to be in line with Compound's oracles. Chainlink returns prices with 8 decimal places, but
        // compound expects 36 - underlyingDecimals decimal places from their oracles. This is so that when the underlying amount is multiplied by the
        // received price, the collateral valuation is normalized to 36 decimals. To perform this adjustment, we multiply by 10^(36 - 8 - underlyingDeciamls)
        int256 rawCollateralPrice = strategy.collateralPriceOracle.latestAnswer();
        rebalanceInfo.collateralPrice = rawCollateralPrice.toUint256().mul(10 ** strategy.collateralDecimalAdjustment);
        int256 rawBorrowPrice = strategy.borrowPriceOracle.latestAnswer();
        rebalanceInfo.borrowPrice = rawBorrowPrice.toUint256().mul(10 ** strategy.borrowDecimalAdjustment);

        // Calculate stored exchange rate which does not trigger a state update
        uint256 cTokenBalance = strategy.targetCollateralCToken.balanceOf(address(strategy.setToken));
        rebalanceInfo.collateralBalance = cTokenBalance.preciseMul(strategy.targetCollateralCToken.exchangeRateStored());
        rebalanceInfo.borrowBalance = strategy.targetBorrowCToken.borrowBalanceStored(address(strategy.setToken));
        rebalanceInfo.collateralValue = rebalanceInfo.collateralPrice.preciseMul(rebalanceInfo.collateralBalance);
        rebalanceInfo.borrowValue = rebalanceInfo.borrowPrice.preciseMul(rebalanceInfo.borrowBalance);
        rebalanceInfo.setTotalSupply = strategy.setToken.totalSupply();

        return rebalanceInfo;
    }

    /**
     * Validate non-exchange settings in constructor and setters when updating.
     */
    function _validateNonExchangeSettings(
        MethodologySettings memory _methodology,
        ExecutionSettings memory _execution,
        IncentiveSettings memory _incentive
    )
        internal
        pure
    {
        require (
            _methodology.minLeverageRatio <= _methodology.targetLeverageRatio && _methodology.minLeverageRatio > 0,
            "Must be valid min leverage"
        );
        require (
            _methodology.maxLeverageRatio >= _methodology.targetLeverageRatio,
            "Must be valid max leverage"
        );
        require (
            _methodology.recenteringSpeed <= PreciseUnitMath.preciseUnit() && _methodology.recenteringSpeed > 0,
            "Must be valid recentering speed"
        );
        require (
            _execution.unutilizedLeveragePercentage <= PreciseUnitMath.preciseUnit(),
            "Unutilized leverage must be <100%"
        );
        require (
            _execution.slippageTolerance <= PreciseUnitMath.preciseUnit(),
            "Slippage tolerance must be <100%"
        );
        require (
            _incentive.incentivizedSlippageTolerance <= PreciseUnitMath.preciseUnit(),
            "Incentivized slippage tolerance must be <100%"
        );
        require (
            _incentive.incentivizedLeverageRatio >= _methodology.maxLeverageRatio,
            "Incentivized leverage ratio must be > max leverage ratio"
        );
        require (
            _methodology.rebalanceInterval >= _execution.twapCooldownPeriod,
            "Rebalance interval must be greater than TWAP cooldown period"
        );
        require (
            _execution.twapCooldownPeriod >= _incentive.incentivizedTwapCooldownPeriod,
            "TWAP cooldown must be greater than incentivized TWAP cooldown"
        );
    }

    /**
     * Validate an ExchangeSettings struct when adding or updating an exchange. Does not validate that twapMaxTradeSize < incentivizedMaxTradeSize since
     * it may be useful to disable exchanges for ripcord by setting incentivizedMaxTradeSize to 0.
     */
     function _validateExchangeSettings(ExchangeSettings memory _settings) internal pure {
         require(_settings.twapMaxTradeSize != 0, "Max TWAP trade size must not be 0");
     }

    /**
     * Validate that current leverage is below incentivized leverage ratio and cooldown / rebalance period has elapsed or outsize max/min bounds. Used
     * in rebalance() and iterateRebalance() functions
     */
    function _validateNormalRebalance(LeverageInfo memory _leverageInfo, uint256 _coolDown, uint256 _lastTradeTimestamp) internal view {
        require(_leverageInfo.currentLeverageRatio < incentive.incentivizedLeverageRatio, "Must be below incentivized leverage ratio");
        require(
            block.timestamp.sub(_lastTradeTimestamp) > _coolDown
            || _leverageInfo.currentLeverageRatio > methodology.maxLeverageRatio
            || _leverageInfo.currentLeverageRatio < methodology.minLeverageRatio,
            "Cooldown not elapsed or not valid leverage ratio"
        );
    }

    /**
     * Validate that current leverage is above incentivized leverage ratio and incentivized cooldown period has elapsed in ripcord()
     */
    function _validateRipcord(LeverageInfo memory _leverageInfo, uint256 _lastTradeTimestamp) internal view {
        require(_leverageInfo.currentLeverageRatio >= incentive.incentivizedLeverageRatio, "Must be above incentivized leverage ratio");
        // If currently in the midst of a TWAP rebalance, ensure that the cooldown period has elapsed
        require(_lastTradeTimestamp.add(incentive.incentivizedTwapCooldownPeriod) < block.timestamp, "TWAP cooldown must have elapsed");
    }

    /**
     * Validate TWAP in the iterateRebalance() function
     */
    function _validateTWAP() internal view {
        require(twapLeverageRatio > 0, "Not in TWAP state");
    }

    /**
     * Validate not TWAP in the rebalance() function
     */
    function _validateNonTWAP() internal view {
        require(twapLeverageRatio == 0, "Must call iterate");
    }

    /**
     * Check if price has moved advantageously while in the midst of the TWAP rebalance. This means the current leverage ratio has moved over/under
     * the stored TWAP leverage ratio on lever/delever so there is no need to execute a rebalance. Used in iterateRebalance()
     */
    function _isAdvantageousTWAP(uint256 _currentLeverageRatio) internal view returns (bool) {
        return (
            (twapLeverageRatio < methodology.targetLeverageRatio && _currentLeverageRatio >= twapLeverageRatio)
            || (twapLeverageRatio > methodology.targetLeverageRatio && _currentLeverageRatio <= twapLeverageRatio)
        );
    }

    /**
     * Calculate the current leverage ratio given a valuation of the collateral and borrow asset, which is calculated as collateral USD valuation / SetToken USD valuation
     *
     * return uint256            Current leverage ratio
     */
    function _calculateCurrentLeverageRatio(
        uint256 _collateralValue,
        uint256 _borrowValue
    )
        internal
        pure
        returns(uint256)
    {
        return _collateralValue.preciseDiv(_collateralValue.sub(_borrowValue));
    }

    /**
     * Calculate the new leverage ratio using the flexible leverage methodology. The methodology reduces the size of each rebalance by weighting
     * the current leverage ratio against the target leverage ratio by the recentering speed percentage. The lower the recentering speed, the slower
     * the leverage token will move towards the target leverage each rebalance.
     *
     * return uint256          New leverage ratio based on the flexible leverage methodology
     */
    function _calculateNewLeverageRatio(uint256 _currentLeverageRatio) internal view returns(uint256) {
        // CLRt+1 = max(MINLR, min(MAXLR, CLRt * (1 - RS) + TLR * RS))
        // a: TLR * RS
        // b: (1- RS) * CLRt
        // c: (1- RS) * CLRt + TLR * RS
        // d: min(MAXLR, CLRt * (1 - RS) + TLR * RS)
        uint256 a = methodology.targetLeverageRatio.preciseMul(methodology.recenteringSpeed);
        uint256 b = PreciseUnitMath.preciseUnit().sub(methodology.recenteringSpeed).preciseMul(_currentLeverageRatio);
        uint256 c = a.add(b);
        uint256 d = Math.min(c, methodology.maxLeverageRatio);
        return Math.max(methodology.minLeverageRatio, d);
    }

    /**
     * Calculate total notional rebalance quantity and chunked rebalance quantity in collateral units.
     *
     * return uint256          Chunked rebalance notional in collateral units
     * return uint256          Total rebalance notional in collateral units
     */
    function _calculateChunkRebalanceNotional(
        LeverageInfo memory _leverageInfo,
        uint256 _newLeverageRatio,
        bool _isLever
    )
        internal
        view
        returns (uint256, uint256)
    {
        // Calculate absolute value of difference between new and current leverage ratio
        uint256 leverageRatioDifference = _isLever ? _newLeverageRatio.sub(_leverageInfo.currentLeverageRatio) : _leverageInfo.currentLeverageRatio.sub(_newLeverageRatio);

        uint256 totalRebalanceNotional = leverageRatioDifference.preciseDiv(_leverageInfo.currentLeverageRatio).preciseMul(_leverageInfo.action.collateralBalance);

        uint256 maxBorrow = _calculateMaxBorrowCollateral(_leverageInfo.action, _isLever);

        uint256 chunkRebalanceNotional = Math.min(Math.min(maxBorrow, totalRebalanceNotional), _leverageInfo.twapMaxTradeSize);

        return (chunkRebalanceNotional, totalRebalanceNotional);
    }

    /**
     * Calculate the max borrow / repay amount allowed in collateral units for lever / delever. This is due to overcollateralization requirements on
     * assets deposited in lending protocols for borrowing.
     *
     * For lever, max borrow is calculated as:
     * (Net borrow limit in USD - existing borrow value in USD) / collateral asset price adjusted for decimals
     *
     * For delever, max borrow is calculated as:
     * Collateral balance in base units * (net borrow limit in USD - existing borrow value in USD) / net borrow limit in USD
     *
     * Net borrow limit is calculated as:
     * The collateral value in USD * Compound collateral factor * (1 - unutilized leverage %)
     *
     * return uint256          Max borrow notional denominated in collateral asset
     */
    function _calculateMaxBorrowCollateral(ActionInfo memory _actionInfo, bool _isLever) internal view returns(uint256) {
        // Retrieve collateral factor which is the % increase in borrow limit in precise units (75% = 75 * 1e16)
        ( , uint256 collateralFactorMantissa, ) = strategy.comptroller.markets(address(strategy.targetCollateralCToken));

        uint256 netBorrowLimit = _actionInfo.collateralValue
            .preciseMul(collateralFactorMantissa)
            .preciseMul(PreciseUnitMath.preciseUnit().sub(execution.unutilizedLeveragePercentage));

        if (_isLever) {
            return netBorrowLimit
                .sub(_actionInfo.borrowValue)
                .preciseDiv(_actionInfo.collateralPrice);
        } else {
            return _actionInfo.collateralBalance
                .preciseMul(netBorrowLimit.sub(_actionInfo.borrowValue))
                .preciseDiv(netBorrowLimit);
        }
    }

    /**
     * Derive the borrow units for lever. The units are calculated by the collateral units multiplied by collateral / borrow asset price. Oracle prices
     * have already been adjusted for the decimals in the token.
     *
     * return uint256           Position units to borrow
     */
    function _calculateBorrowUnits(uint256 _collateralRebalanceUnits, ActionInfo memory _actionInfo) internal pure returns (uint256) {
        return _collateralRebalanceUnits.preciseMul(_actionInfo.collateralPrice).preciseDiv(_actionInfo.borrowPrice);
    }

    /**
     * Calculate the min receive units in collateral units for lever. Units are calculated as target collateral rebalance units multiplied by slippage tolerance
     *
     * return uint256           Min position units to receive after lever trade
     */
    function _calculateMinCollateralReceiveUnits(uint256 _collateralRebalanceUnits, uint256 _slippageTolerance) internal pure returns (uint256) {
        return _collateralRebalanceUnits.preciseMul(PreciseUnitMath.preciseUnit().sub(_slippageTolerance));
    }

    /**
     * Derive the min repay units from collateral units for delever. Units are calculated as target collateral rebalance units multiplied by slippage tolerance
     * and pair price (collateral oracle price / borrow oracle price). Oracle prices have already been adjusted for the decimals in the token.
     *
     * return uint256           Min position units to repay in borrow asset
     */
    function _calculateMinRepayUnits(uint256 _collateralRebalanceUnits, uint256 _slippageTolerance, ActionInfo memory _actionInfo) internal pure returns (uint256) {
        return _collateralRebalanceUnits
            .preciseMul(_actionInfo.collateralPrice)
            .preciseDiv(_actionInfo.borrowPrice)
            .preciseMul(PreciseUnitMath.preciseUnit().sub(_slippageTolerance));
    }

    /**
     * Update last trade timestamp and if chunk rebalance size is less than total rebalance notional, store new leverage ratio to kick off TWAP. Used in
     * the engage() and rebalance() functions
     */
    function _updateRebalanceState(
        uint256 _chunkRebalanceNotional,
        uint256 _totalRebalanceNotional,
        uint256 _newLeverageRatio,
        string memory _exchangeName
    )
        internal
    {

        _updateLastTradeTimestamp(_exchangeName);

        if (_chunkRebalanceNotional < _totalRebalanceNotional) {
            twapLeverageRatio = _newLeverageRatio;
        }
    }

    /**
     * Update last trade timestamp and if chunk rebalance size is equal to the total rebalance notional, end TWAP by clearing state. This function is used
     * in iterateRebalance()
     */
    function _updateIterateState(uint256 _chunkRebalanceNotional, uint256 _totalRebalanceNotional, string memory _exchangeName) internal {

        _updateLastTradeTimestamp(_exchangeName);

        // If the chunk size is equal to the total notional meaning that rebalances are not chunked, then clear TWAP state.
        if (_chunkRebalanceNotional == _totalRebalanceNotional) {
            delete twapLeverageRatio;
        }
    }

    /**
     * Update last trade timestamp and if currently in a TWAP, delete the TWAP state. Used in the ripcord() function.
     */
    function _updateRipcordState(string memory _exchangeName) internal {

        _updateLastTradeTimestamp(_exchangeName);

        // If TWAP leverage ratio is stored, then clear state. This may happen if we are currently in a TWAP rebalance, and the leverage ratio moves above the
        // incentivized threshold for ripcord.
        if (twapLeverageRatio > 0) {
            delete twapLeverageRatio;
        }
    }

    /**
     * Update globalLastTradeTimestamp and exchangeLastTradeTimestamp values. This function updates both the exchange-specific and global timestamp so that the
     * epoch rebalance can use the global timestamp (since the global timestamp is always  equal to the most recently used exchange timestamp). This allows for
     * multiple rebalances to occur simultaneously since only the exchange-specific timestamp is checked for non-epoch rebalances.
     */
     function _updateLastTradeTimestamp(string memory _exchangeName) internal {
        globalLastTradeTimestamp = block.timestamp;
        exchangeSettings[_exchangeName].exchangeLastTradeTimestamp = block.timestamp;
     }

    /**
     * Transfer ETH reward to caller of the ripcord function. If the ETH balance on this contract is less than required
     * incentive quantity, then transfer contract balance instead to prevent reverts.
     *
     * return uint256           Amount of ETH transferred to caller
     */
    function _transferEtherRewardToCaller(uint256 _etherReward) internal returns(uint256) {
        uint256 etherToTransfer = _etherReward < address(this).balance ? _etherReward : address(this).balance;

        msg.sender.transfer(etherToTransfer);

        return etherToTransfer;
    }

    /**
     * Internal function returning the ShouldRebalance enum used in shouldRebalance and shouldRebalanceWithBounds external getter functions
     *
     * return ShouldRebalance         Enum detailing whether to rebalance, iterateRebalance, ripcord or no action
     */
    function _shouldRebalance(
        uint256 _currentLeverageRatio,
        uint256 _minLeverageRatio,
        uint256 _maxLeverageRatio
    )
        internal
        view
        returns(string[] memory, ShouldRebalance[] memory)
    {

        ShouldRebalance[] memory shouldRebalanceEnums = new ShouldRebalance[](enabledExchanges.length);

        for (uint256 i = 0; i < enabledExchanges.length; i++) {
            // If none of the below conditions are satisfied, then should not rebalance
            shouldRebalanceEnums[i] = ShouldRebalance.NONE;

            // If above ripcord threshold, then check if incentivized cooldown period has elapsed
            if (_currentLeverageRatio >= incentive.incentivizedLeverageRatio) {
                if (exchangeSettings[enabledExchanges[i]].exchangeLastTradeTimestamp.add(incentive.incentivizedTwapCooldownPeriod) < block.timestamp) {
                    shouldRebalanceEnums[i] = ShouldRebalance.RIPCORD;
                }
            } else {
                // If TWAP, then check if the cooldown period has elapsed
                if (twapLeverageRatio > 0) {
                    if (exchangeSettings[enabledExchanges[i]].exchangeLastTradeTimestamp.add(execution.twapCooldownPeriod) < block.timestamp) {
                        shouldRebalanceEnums[i] = ShouldRebalance.ITERATE_REBALANCE;
                    }
                } else {
                    // If not TWAP, then check if the rebalance interval has elapsed OR current leverage is above max leverage OR current leverage is below
                    // min leverage
                    if (
                        block.timestamp.sub(globalLastTradeTimestamp) > methodology.rebalanceInterval
                        || _currentLeverageRatio > _maxLeverageRatio
                        || _currentLeverageRatio < _minLeverageRatio
                    ) {
                        shouldRebalanceEnums[i] = ShouldRebalance.REBALANCE;
                    }
                }
            }
        }


        return (enabledExchanges, shouldRebalanceEnums);
    }
}

/*
    Copyright 2021 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import { FlexibleLeverageStrategyExtension } from "../adapters/FlexibleLeverageStrategyExtension.sol";

interface IFLIStrategyExtension {
    function getStrategy() external view returns (FlexibleLeverageStrategyExtension.ContractSettings memory);
    function getMethodology() external view returns (FlexibleLeverageStrategyExtension.MethodologySettings memory);
    function getIncentive() external view returns (FlexibleLeverageStrategyExtension.IncentiveSettings memory);
    function getExecution() external view returns (FlexibleLeverageStrategyExtension.ExecutionSettings memory);
    function getExchangeSettings(string memory _exchangeName) external view returns (FlexibleLeverageStrategyExtension.ExchangeSettings memory);
    function getEnabledExchanges() external view returns (string[] memory);

    function getCurrentLeverageRatio() external view returns (uint256);

    function getChunkRebalanceNotional(
        string[] calldata _exchangeNames
    ) 
        external
        view
        returns(uint256[] memory sizes, address sellAsset, address buyAsset);

    function shouldRebalance() external view returns(string[] memory, FlexibleLeverageStrategyExtension.ShouldRebalance[] memory);
    function shouldRebalanceWithBounds(
        uint256 _customMinLeverageRatio,
        uint256 _customMaxLeverageRatio
    )
        external
        view
        returns(string[] memory, FlexibleLeverageStrategyExtension.ShouldRebalance[] memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

/// @title Quoter Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IQuoter {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    function quoteExactInput(bytes memory path, uint256 amountIn) external returns (uint256 amountOut);

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountIn The desired input amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee. Path must be provided in reverse order
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    function quoteExactOutput(bytes memory path, uint256 amountOut) external returns (uint256 amountIn);

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountOut The desired output amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;

interface IUniswapV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

pragma solidity 0.6.10;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/**
 * @title ICErc20
 *
 * Interface for interacting with Compound cErc20 tokens (e.g. Dai, USDC)
 */
interface ICErc20 is IERC20 {

    function borrowBalanceCurrent(address _account) external returns (uint256);

    function borrowBalanceStored(address _account) external view returns (uint256);

    function balanceOfUnderlying(address _account) external returns (uint256);

    /**
     * Calculates the exchange rate from the underlying to the CToken
     *
     * @notice Accrue interest then return the up-to-date exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function underlying() external view returns (address);

    /**
     * Sender supplies assets into the market and receives cTokens in exchange
     *
     * @notice Accrues interest whether or not the operation succeeds, unless reverted
     * @param _mintAmount The amount of the underlying asset to supply
     * @return uint256 0=success, otherwise a failure
     */
    function mint(uint256 _mintAmount) external returns (uint256);

    /**
     * @notice Sender redeems cTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param _redeemTokens The number of cTokens to redeem into underlying
     * @return uint256 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeem(uint256 _redeemTokens) external returns (uint256);

    /**
     * @notice Sender redeems cTokens in exchange for a specified amount of underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param _redeemAmount The amount of underlying to redeem
     * @return uint256 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeemUnderlying(uint256 _redeemAmount) external returns (uint256);

    /**
      * @notice Sender borrows assets from the protocol to their own address
      * @param _borrowAmount The amount of the underlying asset to borrow
      * @return uint256 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function borrow(uint256 _borrowAmount) external returns (uint256);

    /**
     * @notice Sender repays their own borrow
     * @param _repayAmount The amount to repay
     * @return uint256 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function repayBorrow(uint256 _repayAmount) external returns (uint256);
}

pragma solidity 0.6.10;


/**
 * @title IComptroller
 *
 * Interface for interacting with Compound Comptroller
 */
interface IComptroller {

    /**
     * @notice Add assets to be included in account liquidity calculation
     * @param cTokens The list of addresses of the cToken markets to be enabled
     * @return Success indicator for whether each corresponding market was entered
     */
    function enterMarkets(address[] memory cTokens) external returns (uint256[] memory);

    /**
     * @notice Removes asset from sender's account liquidity calculation
     * @dev Sender must not have an outstanding borrow balance in the asset,
     *  or be providing neccessary collateral for an outstanding borrow.
     * @param cTokenAddress The address of the asset to be removed
     * @return Whether or not the account successfully exited the market
     */
    function exitMarket(address cTokenAddress) external returns (uint256);

    function claimComp(address holder) external;

    function markets(address cTokenAddress) external view returns (bool, uint256, bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity ^0.6.10;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { ISetToken } from "../interfaces/ISetToken.sol";
import { IIndexModule } from "../interfaces/IIndexModule.sol";
import { IStreamingFeeModule } from "../interfaces/IStreamingFeeModule.sol";
import { MutualUpgrade } from "../lib/MutualUpgrade.sol";
import { PreciseUnitMath } from "../lib/PreciseUnitMath.sol";
import { TimeLockUpgrade } from "../lib/TimeLockUpgrade.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract ICManager is TimeLockUpgrade, MutualUpgrade {
    using Address for address;
    using SafeMath for uint256;
    using PreciseUnitMath for uint256;

    /* ============ Events ============ */

    event FeesAccrued(
        uint256 _totalFees,
        uint256 _operatorTake,
        uint256 _methodologistTake
    );

    /* ============ Modifiers ============ */

    /**
     * Throws if the sender is not the SetToken operator
     */
    modifier onlyOperator() {
        require(msg.sender == operator, "Must be operator");
        _;
    }

    /**
     * Throws if the sender is not the SetToken methodologist
     */
    modifier onlyMethodologist() {
        require(msg.sender == methodologist, "Must be methodologist");
        _;
    }

    /* ============ State Variables ============ */

    // Instance of SetToken
    ISetToken public setToken;

    // Address of IndexModule for managing rebalances
    IIndexModule public indexModule;

    // Address of StreamingFeeModule
    IStreamingFeeModule public feeModule;

    // Address of operator
    address public operator;

    // Address of methodologist
    address public methodologist;

    // Percent in 1e18 of streamingFees sent to operator
    uint256 public operatorFeeSplit;

    /* ============ Constructor ============ */

    constructor(
        ISetToken _setToken,
        IIndexModule _indexModule,
        IStreamingFeeModule _feeModule,
        address _operator,
        address _methodologist,
        uint256 _operatorFeeSplit
    )
        public
    {
        require(
            _operatorFeeSplit <= PreciseUnitMath.preciseUnit(),
            "Operator Fee Split must be less than 1e18"
        );
        
        setToken = _setToken;
        indexModule = _indexModule;
        feeModule = _feeModule;
        operator = _operator;
        methodologist = _methodologist;
        operatorFeeSplit = _operatorFeeSplit;
    }

    /* ============ External Functions ============ */

    /**
     * OPERATOR ONLY: Start rebalance in IndexModule. Set new target units, zeroing out any units for components being removed from index.
     * Log position multiplier to adjust target units in case fees are accrued.
     *
     * @param _newComponents                    Array of new components to add to allocation
     * @param _newComponentsTargetUnits         Array of target units at end of rebalance for new components, maps to same index of component
     * @param _oldComponentsTargetUnits         Array of target units at end of rebalance for old component, maps to same index of component,
     *                                              if component being removed set to 0.
     * @param _positionMultiplier               Position multiplier when target units were calculated, needed in order to adjust target units
     *                                              if fees accrued
     */
    function startRebalance(
        address[] calldata _newComponents,
        uint256[] calldata _newComponentsTargetUnits,
        uint256[] calldata _oldComponentsTargetUnits,
        uint256 _positionMultiplier
    )
        external
        onlyOperator
    {
        indexModule.startRebalance(_newComponents, _newComponentsTargetUnits, _oldComponentsTargetUnits, _positionMultiplier);
    }

    /**
     * OPERATOR ONLY: Set trade maximums for passed components
     *
     * @param _components            Array of components
     * @param _tradeMaximums         Array of trade maximums mapping to correct component
     */
    function setTradeMaximums(
        address[] calldata _components,
        uint256[] calldata _tradeMaximums
    )
        external
        onlyOperator
    {
        indexModule.setTradeMaximums(_components, _tradeMaximums);
    }

    /**
     * OPERATOR ONLY: Set exchange for passed components
     *
     * @param _components        Array of components
     * @param _exchanges         Array of exchanges mapping to correct component, uint256 used to signify exchange
     */
    function setAssetExchanges(
        address[] calldata _components,
        uint256[] calldata _exchanges
    )
        external
        onlyOperator
    {
        indexModule.setExchanges(_components, _exchanges);
    }

    /**
     * OPERATOR ONLY: Set exchange for passed components
     *
     * @param _components           Array of components
     * @param _coolOffPeriods       Array of cool off periods to correct component
     */
    function setCoolOffPeriods(
        address[] calldata _components,
        uint256[] calldata _coolOffPeriods
    )
        external
        onlyOperator
    {
        indexModule.setCoolOffPeriods(_components, _coolOffPeriods);
    }

    /**
     * OPERATOR ONLY: Toggle ability for passed addresses to trade from current state 
     *
     * @param _traders           Array trader addresses to toggle status
     * @param _statuses          Booleans indicating if matching trader can trade
     */
    function updateTraderStatus(
        address[] calldata _traders,
        bool[] calldata _statuses
    )
        external
        onlyOperator
    {
        indexModule.updateTraderStatus(_traders, _statuses);
    }

    /**
     * OPERATOR ONLY: Toggle whether anyone can trade, bypassing the traderAllowList
     *
     * @param _status           Boolean indicating if anyone can trade
     */
    function updateAnyoneTrade(bool _status) external onlyOperator {
        indexModule.updateAnyoneTrade(_status);
    }

    /**
     * Accrue fees from streaming fee module and transfer tokens to operator / methodologist addresses based on fee split
     */
    function accrueFeeAndDistribute() public {
        feeModule.accrueFee(setToken);

        uint256 setTokenBalance = setToken.balanceOf(address(this));

        uint256 operatorTake = setTokenBalance.preciseMul(operatorFeeSplit);
        uint256 methodologistTake = setTokenBalance.sub(operatorTake);

        setToken.transfer(operator, operatorTake);

        setToken.transfer(methodologist, methodologistTake);

        emit FeesAccrued(setTokenBalance, operatorTake, methodologistTake);
    }

    /**
     * OPERATOR OR METHODOLOGIST ONLY: Update the SetToken manager address. Operator and Methodologist must each call
     * this function to execute the update.
     *
     * @param _newManager           New manager address
     */
    function updateManager(address _newManager) external mutualUpgrade(operator, methodologist) {
        setToken.setManager(_newManager);
    }

    /**
     * OPERATOR ONLY: Add a new module to the SetToken.
     *
     * @param _module           New module to add
     */
    function addModule(address _module) external onlyOperator {
        setToken.addModule(_module);
    }

    /**
     * OPERATOR ONLY: Interact with a module registered on the SetToken. Cannot be used to call functions in the
     * fee module, due to ability to bypass methodologist permissions to update streaming fee.
     *
     * @param _module           Module to interact with
     * @param _data             Byte data of function to call in module
     */
    function interactModule(address _module, bytes calldata _data) external onlyOperator {
        require(_module != address(feeModule), "Must not be fee module");

        // Invoke call to module, assume value will always be 0
        _module.functionCallWithValue(_data, 0);
    }

    /**
     * OPERATOR ONLY: Remove a new module from the SetToken.
     *
     * @param _module           Module to remove
     */
    function removeModule(address _module) external onlyOperator {
        setToken.removeModule(_module);
    }

    /**
     * METHODOLOGIST ONLY: Update the streaming fee for the SetToken. Subject to timelock period agreed upon by the
     * operator and methodologist
     *
     * @param _newFee           New streaming fee percentage
     */
    function updateStreamingFee(uint256 _newFee) external timeLockUpgrade onlyMethodologist {
        feeModule.updateStreamingFee(setToken, _newFee);
    }

    /**
     * OPERATOR OR METHODOLOGIST ONLY: Update the fee recipient address. Operator and Methodologist must each call
     * this function to execute the update.
     *
     * @param _newFeeRecipient           New fee recipient address
     */
    function updateFeeRecipient(address _newFeeRecipient) external mutualUpgrade(operator, methodologist) {
        feeModule.updateFeeRecipient(setToken, _newFeeRecipient);
    }

    /**
     * OPERATOR OR METHODOLOGIST ONLY: Update the fee split percentage. Operator and Methodologist must each call
     * this function to execute the update.
     *
     * @param _newFeeSplit           New fee split percentage
     */
    function updateFeeSplit(uint256 _newFeeSplit) external mutualUpgrade(operator, methodologist) {    
        require(
            _newFeeSplit <= PreciseUnitMath.preciseUnit(),
            "Operator Fee Split must be less than 1e18"
        );

        // Accrue fee to operator and methodologist prior to new fee split
        accrueFeeAndDistribute();
        operatorFeeSplit = _newFeeSplit;
    }

    /**
     * OPERATOR ONLY: Update the index module
     *
     * @param _newIndexModule           New index module
     */
    function updateIndexModule(IIndexModule _newIndexModule) external onlyOperator {
        indexModule = _newIndexModule;
    }

    /**
     * METHODOLOGIST ONLY: Update the methodologist address
     *
     * @param _newMethodologist           New methodologist address
     */
    function updateMethodologist(address _newMethodologist) external onlyMethodologist {
        methodologist = _newMethodologist;
    }

    /**
     * OPERATOR ONLY: Update the operator address
     *
     * @param _newOperator           New operator address
     */
    function updateOperator(address _newOperator) external onlyOperator {
        operator = _newOperator;
    }

    /**
     * OPERATOR OR METHODOLOGIST ONLY: Update the timelock period for updating the streaming fee percentage.
     * Operator and Methodologist must each call this function to execute the update.
     *
     * @param _newTimeLockPeriod           New timelock period in seconds
     */
    function setTimeLockPeriod(uint256 _newTimeLockPeriod) external override mutualUpgrade(operator, methodologist) {
        timeLockPeriod = _newTimeLockPeriod;
    }
}

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import { ISetToken } from "./ISetToken.sol";

interface IIndexModule {
    function startRebalance(
        address[] calldata _newComponents,
        uint256[] calldata _newComponentsTargetUnits,
        uint256[] calldata _oldComponentsTargetUnits,
        uint256 _positionMultiplier
    ) external;

    function setTradeMaximums(
        address[] calldata _components,
        uint256[] calldata _tradeMaximums
    ) external;

    function setExchanges(
        address[] calldata _components,
        uint256[] calldata _exchanges
    ) external;

    function setCoolOffPeriods(
        address[] calldata _components,
        uint256[] calldata _coolOffPeriods
    ) external;

    function updateTraderStatus(address[] calldata _traders, bool[] calldata _statuses) external;

    function updateAnyoneTrade(bool _status) external;
}

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import { ISetToken } from "./ISetToken.sol";

interface IStreamingFeeModule {
    struct FeeState {
        address feeRecipient;
        uint256 maxStreamingFeePercentage;
        uint256 streamingFeePercentage;
        uint256 lastStreamingFeeTimestamp;
    }

    function getFee(ISetToken _setToken) external view returns (uint256);
    function accrueFee(ISetToken _setToken) external;
    function updateStreamingFee(ISetToken _setToken, uint256 _newFee) external;
    function updateFeeRecipient(ISetToken _setToken, address _newFeeRecipient) external;
    function initialize(ISetToken _setToken, FeeState memory _settings) external;
}

/*
    Copyright 2018 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.6.10;

/**
 * @title MutualUpgrade
 * @author Set Protocol
 *
 * The MutualUpgrade contract contains a modifier for handling mutual upgrades between two parties
 */
contract MutualUpgrade {
    /* ============ State Variables ============ */

    // Mapping of upgradable units and if upgrade has been initialized by other party
    mapping(bytes32 => bool) public mutualUpgrades;

    /* ============ Events ============ */

    event MutualUpgradeRegistered(
        bytes32 _upgradeHash
    );

    /* ============ Modifiers ============ */

    modifier mutualUpgrade(address _signerOne, address _signerTwo) {
        require(
            msg.sender == _signerOne || msg.sender == _signerTwo,
            "Must be authorized address"
        );

        address nonCaller = _getNonCaller(_signerOne, _signerTwo);

        // The upgrade hash is defined by the hash of the transaction call data and sender of msg,
        // which uniquely identifies the function, arguments, and sender.
        bytes32 expectedHash = keccak256(abi.encodePacked(msg.data, nonCaller));

        if (!mutualUpgrades[expectedHash]) {
            bytes32 newHash = keccak256(abi.encodePacked(msg.data, msg.sender));

            mutualUpgrades[newHash] = true;

            emit MutualUpgradeRegistered(newHash);

            return;
        }

        delete mutualUpgrades[expectedHash];

        // Run the rest of the upgrades
        _;
    }

    /* ============ Internal Functions ============ */

    function _getNonCaller(address _signerOne, address _signerTwo) internal view returns(address) {
        return msg.sender == _signerOne ? _signerTwo : _signerOne;
    }
}

/*
    Copyright 2018 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.6.10;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title TimeLockUpgrade
 * @author Set Protocol
 *
 * The TimeLockUpgrade contract contains a modifier for handling minimum time period updates
 */
contract TimeLockUpgrade is
    Ownable
{
    using SafeMath for uint256;

    /* ============ State Variables ============ */

    // Timelock Upgrade Period in seconds
    uint256 public timeLockPeriod;

    // Mapping of upgradable units and initialized timelock
    mapping(bytes32 => uint256) public timeLockedUpgrades;

    /* ============ Events ============ */

    event UpgradeRegistered(
        bytes32 _upgradeHash,
        uint256 _timestamp
    );

    /* ============ Modifiers ============ */

    modifier timeLockUpgrade() {
        // If the time lock period is 0, then allow non-timebound upgrades.
        // This is useful for initialization of the protocol and for testing.
        if (timeLockPeriod == 0) {
            _;

            return;
        }

        // The upgrade hash is defined by the hash of the transaction call data,
        // which uniquely identifies the function as well as the passed in arguments.
        bytes32 upgradeHash = keccak256(
            abi.encodePacked(
                msg.data
            )
        );

        uint256 registrationTime = timeLockedUpgrades[upgradeHash];

        // If the upgrade hasn't been registered, register with the current time.
        if (registrationTime == 0) {
            timeLockedUpgrades[upgradeHash] = block.timestamp;

            emit UpgradeRegistered(
                upgradeHash,
                block.timestamp
            );

            return;
        }

        require(
            block.timestamp >= registrationTime.add(timeLockPeriod),
            "TimeLockUpgrade: Time lock period must have elapsed."
        );

        // Reset the timestamp to 0
        timeLockedUpgrades[upgradeHash] = 0;

        // Run the rest of the upgrades
        _;
    }

    /* ============ Function ============ */

    /**
     * Change timeLockPeriod period. Generally called after initially settings have been set up.
     *
     * @param  _timeLockPeriod   Time in seconds that upgrades need to be evaluated before execution
     */
    function setTimeLockPeriod(
        uint256 _timeLockPeriod
    )
        virtual
        external
        onlyOwner
    {
        // Only allow setting of the timeLockPeriod if the period is greater than the existing
        require(
            _timeLockPeriod > timeLockPeriod,
            "TimeLockUpgrade: New period must be greater than existing"
        );

        timeLockPeriod = _timeLockPeriod;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
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
    constructor () internal {
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.10;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { Vesting } from "./Vesting.sol";

/**
 * @title OtcEscrow
 * @author Badger DAO (Modified by Set Protocol)
 * 
 * A simple OTC swap contract allowing two users to set the parameters of an OTC
 * deal in the constructor arguments, and deposits the sold tokens into a vesting
 * contract when a swap is completed.
 */
contract OtcEscrow {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== Events =========== */

    event VestingDeployed(address vesting);
    
    /* ====== Modifiers ======== */

    /**
     * Throws if the sender is not Index Gov
     */
    modifier onlyIndexGov() {
        require(msg.sender == indexGov, "unauthorized");
        _;
    }

    /**
     * Throws if run more than once
     */
    modifier onlyOnce() {
        require(!hasRun, "swap already executed");
        hasRun = true;
        _;
    }

    /* ======== State Variables ======= */

    address public usdc;
    address public index;

    address public indexGov;
    address public beneficiary;

    uint256 public vestingStart;
    uint256 public vestingEnd;
    uint256 public vestingCliff;

    uint256 public usdcAmount;
    uint256 public indexAmount;

    bool hasRun;



    /* ====== Constructor ======== */

    /**
     * Sets the state variables that encode the terms of the OTC sale
     *
     * @param _beneficiary  Address that will purchase INDEX
     * @param _indexGov     Address that will receive USDC
     * @param _vestingStart Timestamp of vesting start
     * @param _vestingCliff Timestamp of vesting cliff
     * @param _vestingEnd   Timestamp of vesting end
     * @param _usdcAmount   Amount of USDC swapped for the sale
     * @param _indexAmount  Amount of INDEX swapped for the sale
     * @param _usdcAddress  Address of the USDC token
     * @param _indexAddress Address of the Index token
     */
    constructor(
        address _beneficiary,
        address _indexGov,
        uint256 _vestingStart,
        uint256 _vestingCliff,
        uint256 _vestingEnd,
        uint256 _usdcAmount,
        uint256 _indexAmount,
        address _usdcAddress,
        address _indexAddress
    ) public {
        beneficiary = _beneficiary;
        indexGov =  _indexGov;

        vestingStart = _vestingStart;
        vestingCliff = _vestingCliff;
        vestingEnd = _vestingEnd;

        usdcAmount = _usdcAmount;
        indexAmount = _indexAmount;

        usdc = _usdcAddress;
        index = _indexAddress;
        hasRun = false;
    }
    
    /* ======= External Functions ======= */

    /**
     * Executes the OTC deal. Sends the USDC from the beneficiary to Index Governance, and
     * locks the INDEX in the vesting contract. Can only be called once.
     */
    function swap() external onlyOnce {

        require(IERC20(index).balanceOf(address(this)) >= indexAmount, "insufficient INDEX");

        // Transfer expected USDC from beneficiary
        IERC20(usdc).safeTransferFrom(beneficiary, address(this), usdcAmount);

        // Create Vesting contract
        Vesting vesting = new Vesting(index, beneficiary, indexAmount, vestingStart, vestingCliff, vestingEnd);

        // Transfer index to vesting contract
        IERC20(index).safeTransfer(address(vesting), indexAmount);

        // Transfer USDC to index governance
        IERC20(usdc).safeTransfer(indexGov, usdcAmount);

        emit VestingDeployed(address(vesting));
    }

    /**
     * Return INDEX to Index Governance to revoke the deal
     */
    function revoke() external onlyIndexGov {
        uint256 indexBalance = IERC20(index).balanceOf(address(this));
        IERC20(index).safeTransfer(indexGov, indexBalance);
    }

    /**
     * Recovers USDC accidentally sent to the contract
     */
    function recoverUsdc() external {
        uint256 usdcBalance = IERC20(usdc).balanceOf(address(this));
        IERC20(usdc).safeTransfer(beneficiary, usdcBalance);
    }
}

pragma solidity ^0.6.10;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";


contract Vesting {
    using SafeMath for uint256;

    address public index;
    address public recipient;

    uint256 public vestingAmount;
    uint256 public vestingBegin;
    uint256 public vestingCliff;
    uint256 public vestingEnd;

    uint256 public lastUpdate;

    constructor(
        address index_,
        address recipient_,
        uint256 vestingAmount_,
        uint256 vestingBegin_,
        uint256 vestingCliff_,
        uint256 vestingEnd_
    ) public {
        require(vestingBegin_ >= block.timestamp, "TreasuryVester.constructor: vesting begin too early");
        require(vestingCliff_ >= vestingBegin_, "TreasuryVester.constructor: cliff is too early");
        require(vestingEnd_ > vestingCliff_, "TreasuryVester.constructor: end is too early");

        index = index_;
        recipient = recipient_;

        vestingAmount = vestingAmount_;
        vestingBegin = vestingBegin_;
        vestingCliff = vestingCliff_;
        vestingEnd = vestingEnd_;

        lastUpdate = vestingBegin;
    }

    function setRecipient(address recipient_) public {
        require(msg.sender == recipient, "TreasuryVester.setRecipient: unauthorized");
        recipient = recipient_;
    }

    function claim() public {
        require(block.timestamp >= vestingCliff, "TreasuryVester.claim: not time yet");
        uint256 amount;
        if (block.timestamp >= vestingEnd) {
            amount = IERC20(index).balanceOf(address(this));
        } else {
            amount = vestingAmount.mul(block.timestamp.sub(lastUpdate)).div(vestingEnd.sub(vestingBegin));
            lastUpdate = block.timestamp;
        }
        IERC20(index).transfer(recipient, amount);
    }
}

/*
    Copyright 2021 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.6.10;


import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { StakingRewardsV2 } from "../staking/StakingRewardsV2.sol";
import { IMasterChef } from "../interfaces/IMasterChef.sol";
import { IPair } from "../interfaces/IPair.sol";
import { Vesting } from "./Vesting.sol";


/**
 * @title IndexPowah
 * @author Set Protocol
 * 
 * An ERC20 token used for tracking the voting power for the Index Coop. The mutative functions of
 * the ERC20 interface have been disabled since the token is only designed to count votes for the
 * sake of utilizing Snapshot's erc20-balance-of strategy. This contract is inspired by Sushiswap's
 * SUSHIPOWAH contract which serves the same purpose.
 */
contract IndexPowah is IERC20, Ownable {

    using SafeMath for uint256;
    
    IERC20 public indexToken;
    
    IMasterChef public masterChef;
    uint256 public masterChefId;
    IPair public uniPair;
    IPair public sushiPair;

    StakingRewardsV2[] public farms;
    Vesting[] public vesting;

    /**
     * Sets the appropriate state variables for the contract.
     * 
     * @param _owner        owner of this contract
     * @param _indexToken   Index Coop's governance token contract
     * @param _uniPair      INDEX-WETH Uniswap pair
     * @param _sushiPair    INDEX-WETH Sushiswap pair
     * @param _masterChef   Sushiswap MasterChef (Onsen) contract
     * @param _farms        array of Index Coop staking farms
     * @param _vesting      array of vesting contracts from the index sale and full time contributors
     */
    constructor(
        address _owner,
        IERC20 _indexToken,
        IPair _uniPair,
        IPair _sushiPair,
        IMasterChef _masterChef,
        uint256 _masterChefId,
        StakingRewardsV2[] memory _farms,
        Vesting[] memory _vesting
    )
        public
    {
        indexToken = _indexToken;
        uniPair = _uniPair;
        sushiPair = _sushiPair;
        masterChef = _masterChef;
        masterChefId = _masterChefId;
        farms = _farms;
        vesting = _vesting;

        transferOwnership(_owner);
    }

    /**
     * Computes an address's balance of IndexPowah. Balances can not be transfered in the traditional way,
     * but are instead computed by the amount of index that an account directly hold, or indirectly holds
     * through the staking contracts, vesting contracts, uniswap, and sushiswap.
     *
     * @param _account  the address of the voter
     */
    function balanceOf(address _account) public view override returns (uint256) {
        uint256 indexAmount = indexToken.balanceOf(_account);
        uint256 unclaimedInFarms = _getFarmVotes(_account);
        uint256 vestingVotes = _getVestingVotes(_account);
        uint256 dexVotes = _getDexVotes(_account, uniPair) + _getDexVotes(_account, sushiPair) + _getMasterChefVotes(_account);

        return indexAmount + unclaimedInFarms + vestingVotes + dexVotes;
    }

    /**
     * ONLY OWNER: Adds new Index farms to be tracked
     *
     * @param _newFarms list of new farms to be tracked
     */
    function addFarms(StakingRewardsV2[] calldata _newFarms) external onlyOwner {
        for (uint256 i = 0; i < _newFarms.length; i++) {
            farms.push(_newFarms[0]);
        }
    }

    /**
     * ONLY OWNER: Adds new Index vesting contracts to be tracked
     *
     * @param _newVesting   list of new vesting contracts to be tracked
     */
    function addVesting(Vesting[] calldata _newVesting) external onlyOwner {
        for (uint256 i = 0; i < _newVesting.length; i++) {
            vesting.push(_newVesting[i]);
        }
    }

    /**
     * ONLY OWNER: Updates the MasterChef contract and pool ID
     * 
     * @param _newMasterChef    address of the new MasterChef contract
     * @param _newMasterChefId  new pool id for the index-eth MasterChef rewards
     */
    function updateMasterChef(IMasterChef _newMasterChef, uint256 _newMasterChefId) external onlyOwner {
        masterChef = _newMasterChef;
        masterChefId = _newMasterChefId;
    }

    function _getFarmVotes(address _account) internal view returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < farms.length; i++) {
            sum += farms[i].earned(_account);
        }
        return sum;
    }

    function _getVestingVotes(address _account) internal view returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < vesting.length; i++) {
            if(vesting[i].recipient() == _account) {
                sum += indexToken.balanceOf(address(vesting[i]));
            }
        }
        return sum;
    }

    function _getDexVotes(address _account, IPair pair) internal view returns (uint256) {
        uint256 lpBalance = pair.balanceOf(_account);
        return _getDexVotesFromBalance(lpBalance, pair);
    }

    function _getMasterChefVotes(address _account) internal view returns (uint256) {
        (uint256 lpBalance,) = masterChef.userInfo(masterChefId, _account);
        return _getDexVotesFromBalance(lpBalance, sushiPair);
    }

    function _getDexVotesFromBalance(uint256 lpBalance, IPair pair) internal view returns (uint256) {
        uint256 lpIndex = indexToken.balanceOf(address(pair));
        uint256 lpTotal = pair.totalSupply();
        if (lpTotal == 0) return 0;
        return lpIndex.mul(lpBalance).div(lpTotal);
    }


    /**
     * These functions are not used, but have been left in to keep the token ERC20 compliant
     */
    function name() public pure returns (string memory) { return "INDEXPOWAH"; }
    function symbol() public pure returns (string memory) { return "INDEXPOWAH"; }
    function decimals() public pure returns(uint8) { return 18; }
    function totalSupply() public view override returns (uint256) { return indexToken.totalSupply(); }
    function allowance(address, address) public view override returns (uint256) { return 0; }
    function transfer(address, uint256) public override returns (bool) { return false; }
    function approve(address, uint256) public override returns (bool) { return false; }
    function transferFrom(address, address, uint256) public override returns (bool) { return false; }
}

pragma solidity ^0.6.10;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Math } from  "@openzeppelin/contracts/math/Math.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Inheritance
import { RewardsDistributionRecipient } from  "./RewardsDistributionRecipient.sol";

// NOTE: V2 allows setting of rewardsDuration in constructor
contract StakingRewardsV2 is RewardsDistributionRecipient, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    IERC20 public rewardsToken;
    IERC20 public stakingToken;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public rewardsDuration;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken,
        uint256 _rewardsDuration
    ) public {
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
        rewardsDistribution = _rewardsDistribution;
        rewardsDuration = _rewardsDuration;
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
            );
    }

    function earned(address account) public view returns (uint256) {
        return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 amount) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() external {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint256 reward) external override onlyRewardsDistribution updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balance = rewardsToken.balanceOf(address(this));
        require(rewardRate <= balance.div(rewardsDuration), "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
}

pragma solidity 0.6.10;

interface IMasterChef {
    function userInfo(uint256 nr, address who) external view returns (uint256, uint256);
}

pragma solidity 0.6.10;

interface IPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

pragma solidity ^0.6.10;

abstract contract RewardsDistributionRecipient {
    address public rewardsDistribution;

    function notifyRewardAmount(uint256 reward) external virtual;

    modifier onlyRewardsDistribution() {
        require(msg.sender == rewardsDistribution, "Caller is not RewardsDistribution contract");
        _;
    }
}

pragma solidity ^0.6.10;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Math } from  "@openzeppelin/contracts/math/Math.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Inheritance
import { RewardsDistributionRecipient } from  "./RewardsDistributionRecipient.sol";

contract StakingRewards is RewardsDistributionRecipient, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    IERC20 public rewardsToken;
    IERC20 public stakingToken;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public rewardsDuration = 60 days;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken
    ) public {
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
        rewardsDistribution = _rewardsDistribution;
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
            );
    }

    function earned(address account) public view returns (uint256) {
        return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 amount) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() external {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint256 reward) external override onlyRewardsDistribution updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balance = rewardsToken.balanceOf(address(this));
        require(rewardRate <= balance.div(rewardsDuration), "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
}

/*
    Copyright 2021 Index Cooperative
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IUniswapV2Factory } from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import { Math } from "@openzeppelin/contracts/math/Math.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { IBasicIssuanceModule } from "../interfaces/IBasicIssuanceModule.sol";
import { IController } from "../interfaces/IController.sol";
import { ISetToken } from "../interfaces/ISetToken.sol";
import { IWETH } from "../interfaces/IWETH.sol";
import { PreciseUnitMath } from "../lib/PreciseUnitMath.sol";
import { UniSushiV2Library } from "../../external/contracts/UniSushiV2Library.sol";

/**
 * @title ExchangeIssuance
 * @author Index Coop
 *
 * Contract for issuing and redeeming any SetToken using ETH or an ERC20 as the paying/receiving currency.
 * All swaps are done using the best price found on Uniswap or Sushiswap.
 *
 */
contract ExchangeIssuanceV2 is ReentrancyGuard {

    using Address for address payable;
    using SafeMath for uint256;
    using PreciseUnitMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for ISetToken;

    /* ============ Enums ============ */

    enum Exchange { Uniswap, Sushiswap, None }

    /* ============ Constants ============= */

    uint256 constant private MAX_UINT96 = 2**96 - 1;
    address constant public ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /* ============ State Variables ============ */

    address public WETH;
    IUniswapV2Router02 public uniRouter;
    IUniswapV2Router02 public sushiRouter;

    address public immutable uniFactory;
    address public immutable sushiFactory;

    IController public immutable setController;
    IBasicIssuanceModule public immutable basicIssuanceModule;

    /* ============ Events ============ */

    event ExchangeIssue(
        address indexed _recipient,     // The recipient address of the issued SetTokens
        ISetToken indexed _setToken,    // The issued SetToken
        IERC20 indexed _inputToken,     // The address of the input asset(ERC20/ETH) used to issue the SetTokens
        uint256 _amountInputToken,      // The amount of input tokens used for issuance
        uint256 _amountSetIssued        // The amount of SetTokens received by the recipient
    );

    event ExchangeRedeem(
        address indexed _recipient,     // The recipient address which redeemed the SetTokens
        ISetToken indexed _setToken,    // The redeemed SetToken
        IERC20 indexed _outputToken,    // The address of output asset(ERC20/ETH) received by the recipient
        uint256 _amountSetRedeemed,     // The amount of SetTokens redeemed for output tokens
        uint256 _amountOutputToken      // The amount of output tokens received by the recipient
    );

    event Refund(
        address indexed _recipient,     // The recipient address which redeemed the SetTokens
        uint256 _refundAmount           // The amount of ETH redunded to the recipient
    );

    /* ============ Modifiers ============ */

    modifier isSetToken(ISetToken _setToken) {
         require(setController.isSet(address(_setToken)), "ExchangeIssuance: INVALID SET");
         _;
    }

    /* ============ Constructor ============ */

    constructor(
        address _weth,
        address _uniFactory,
        IUniswapV2Router02 _uniRouter,
        address _sushiFactory,
        IUniswapV2Router02 _sushiRouter,
        IController _setController,
        IBasicIssuanceModule _basicIssuanceModule
    )
        public
    {
        uniFactory = _uniFactory;
        uniRouter = _uniRouter;

        sushiFactory = _sushiFactory;
        sushiRouter = _sushiRouter;

        setController = _setController;
        basicIssuanceModule = _basicIssuanceModule;

        WETH = _weth;
        IERC20(WETH).safeApprove(address(uniRouter), PreciseUnitMath.maxUint256());
        IERC20(WETH).safeApprove(address(sushiRouter), PreciseUnitMath.maxUint256());
    }

    /* ============ Public Functions ============ */

    /**
     * Runs all the necessary approval functions required for a given ERC20 token.
     * This function can be called when a new token is added to a SetToken during a
     * rebalance.
     *
     * @param _token    Address of the token which needs approval
     */
    function approveToken(IERC20 _token) public {
        _safeApprove(_token, address(uniRouter), MAX_UINT96);
        _safeApprove(_token, address(sushiRouter), MAX_UINT96);
        _safeApprove(_token, address(basicIssuanceModule), MAX_UINT96);
    }

    /* ============ External Functions ============ */

    /**
     * Runs all the necessary approval functions required for a list of ERC20 tokens.
     *
     * @param _tokens    Addresses of the tokens which need approval
     */
    function approveTokens(IERC20[] calldata _tokens) external {
        for (uint256 i = 0; i < _tokens.length; i++) {
            approveToken(_tokens[i]);
        }
    }

    /**
     * Runs all the necessary approval functions required before issuing
     * or redeeming a SetToken. This function need to be called only once before the first time
     * this smart contract is used on any particular SetToken.
     *
     * @param _setToken    Address of the SetToken being initialized
     */
    function approveSetToken(ISetToken _setToken) isSetToken(_setToken) external {
        address[] memory components = _setToken.getComponents();
        for (uint256 i = 0; i < components.length; i++) {
            // Check that the component does not have external positions
            require(
                _setToken.getExternalPositionModules(components[i]).length == 0,
                "ExchangeIssuance: EXTERNAL_POSITIONS_NOT_ALLOWED"
            );
            approveToken(IERC20(components[i]));
        }
    }

    /**
     * Issues SetTokens for an exact amount of input ERC20 tokens.
     * The ERC20 token must be approved by the sender to this contract.
     *
     * @param _setToken         Address of the SetToken being issued
     * @param _inputToken       Address of input token
     * @param _amountInput      Amount of the input token / ether to spend
     * @param _minSetReceive    Minimum amount of SetTokens to receive. Prevents unnecessary slippage.
     *
     * @return setTokenAmount   Amount of SetTokens issued to the caller
     */
    function issueSetForExactToken(
        ISetToken _setToken,
        IERC20 _inputToken,
        uint256 _amountInput,
        uint256 _minSetReceive
    )
        isSetToken(_setToken)
        external
        nonReentrant
        returns (uint256)
    {
        require(_amountInput > 0, "ExchangeIssuance: INVALID INPUTS");

        _inputToken.safeTransferFrom(msg.sender, address(this), _amountInput);

        uint256 amountEth = address(_inputToken) == WETH
            ? _amountInput
            : _swapTokenForWETH(_inputToken, _amountInput);

        uint256 setTokenAmount = _issueSetForExactWETH(_setToken, _minSetReceive, amountEth);

        emit ExchangeIssue(msg.sender, _setToken, _inputToken, _amountInput, setTokenAmount);
        return setTokenAmount;
    }

    /**
    * Issues an exact amount of SetTokens for given amount of input ERC20 tokens.
    * The excess amount of tokens is returned in an equivalent amount of ether.
    *
    * @param _setToken              Address of the SetToken to be issued
    * @param _inputToken            Address of the input token
    * @param _amountSetToken        Amount of SetTokens to issue
    * @param _maxAmountInputToken   Maximum amount of input tokens to be used to issue SetTokens. The unused
    *                               input tokens are returned as ether.
    *
    * @return amountEthReturn       Amount of ether returned to the caller
    */
    function issueExactSetFromToken(
        ISetToken _setToken,
        IERC20 _inputToken,
        uint256 _amountSetToken,
        uint256 _maxAmountInputToken
    )
        isSetToken(_setToken)
        external
        nonReentrant
        returns (uint256)
    {
        require(_amountSetToken > 0 && _maxAmountInputToken > 0, "ExchangeIssuance: INVALID INPUTS");

        _inputToken.safeTransferFrom(msg.sender, address(this), _maxAmountInputToken);

        uint256 initETHAmount = address(_inputToken) == WETH
            ? _maxAmountInputToken
            : _swapTokenForWETH(_inputToken, _maxAmountInputToken);

        uint256 amountEthSpent = _issueExactSetFromWETH(_setToken, _amountSetToken, initETHAmount);

        uint256 amountEthReturn = initETHAmount.sub(amountEthSpent);
        if (amountEthReturn > 0) {
            IERC20(WETH).safeTransfer(msg.sender,  amountEthReturn);
        }

        emit Refund(msg.sender, amountEthReturn);
        emit ExchangeIssue(msg.sender, _setToken, _inputToken, _maxAmountInputToken, _amountSetToken);
        return amountEthReturn;
    }

    /**
     * Redeems an exact amount of SetTokens for an ERC20 token.
     * The SetToken must be approved by the sender to this contract.
     *
     * @param _setToken             Address of the SetToken being redeemed
     * @param _outputToken          Address of output token
     * @param _amountSetToken       Amount SetTokens to redeem
     * @param _minOutputReceive     Minimum amount of output token to receive
     *
     * @return outputAmount         Amount of output tokens sent to the caller
     */
    function redeemExactSetForToken(
        ISetToken _setToken,
        IERC20 _outputToken,
        uint256 _amountSetToken,
        uint256 _minOutputReceive
    )
        isSetToken(_setToken)
        external
        nonReentrant
        returns (uint256)
    {
        require(_amountSetToken > 0, "ExchangeIssuance: INVALID INPUTS");

        address[] memory components = _setToken.getComponents();
        (
            uint256 totalEth,
            uint256[] memory amountComponents,
            Exchange[] memory exchanges
        ) =  _getAmountETHForRedemption(_setToken, components, _amountSetToken);

        uint256 outputAmount;
        if (address(_outputToken) == WETH) {
            require(totalEth > _minOutputReceive, "ExchangeIssuance: INSUFFICIENT_OUTPUT_AMOUNT");
            _redeemExactSet(_setToken, _amountSetToken);
            outputAmount = _liquidateComponentsForWETH(components, amountComponents, exchanges);
        } else {
            (uint256 totalOutput, Exchange outTokenExchange, ) = _getMaxTokenForExactToken(totalEth, address(WETH), address(_outputToken));
            require(totalOutput > _minOutputReceive, "ExchangeIssuance: INSUFFICIENT_OUTPUT_AMOUNT");
            _redeemExactSet(_setToken, _amountSetToken);
            uint256 outputEth = _liquidateComponentsForWETH(components, amountComponents, exchanges);
            outputAmount = _swapExactTokensForTokens(outTokenExchange, WETH, address(_outputToken), outputEth);
        }

        _outputToken.safeTransfer(msg.sender, outputAmount);
        emit ExchangeRedeem(msg.sender, _setToken, _outputToken, _amountSetToken, outputAmount);
        return outputAmount;
    }


    /**
     * Returns an estimated amount of SetToken that can be issued given an amount of input ERC20 token.
     *
     * @param _setToken         Address of the SetToken being issued
     * @param _amountInput      Amount of the input token to spend
     * @param _inputToken       Address of input token.
     *
     * @return                  Estimated amount of SetTokens that will be received
     */
    function getEstimatedIssueSetAmount(
        ISetToken _setToken,
        IERC20 _inputToken,
        uint256 _amountInput
    )
        isSetToken(_setToken)
        external
        view
        returns (uint256)
    {
        require(_amountInput > 0, "ExchangeIssuance: INVALID INPUTS");

        uint256 amountEth;
        if (address(_inputToken) != WETH) {
            // get max amount of WETH for the `_amountInput` amount of input tokens
            (amountEth, , ) = _getMaxTokenForExactToken(_amountInput, address(_inputToken), WETH);
        } else {
            amountEth = _amountInput;
        }

        address[] memory components = _setToken.getComponents();
        (uint256 setIssueAmount, , ) = _getSetIssueAmountForETH(_setToken, components, amountEth);
        return setIssueAmount;
    }

    /**
    * Returns the amount of input ERC20 tokens required to issue an exact amount of SetTokens.
    *
    * @param _setToken          Address of the SetToken being issued
    * @param _amountSetToken    Amount of SetTokens to issue
    *
    * @return                   Amount of tokens needed to issue specified amount of SetTokens
    */
    function getAmountInToIssueExactSet(
        ISetToken _setToken,
        IERC20 _inputToken,
        uint256 _amountSetToken
    )
        isSetToken(_setToken)
        external
        view
        returns(uint256)
    {
        require(_amountSetToken > 0, "ExchangeIssuance: INVALID INPUTS");

        address[] memory components = _setToken.getComponents();
        (uint256 totalEth, , , , ) = _getAmountETHForIssuance(_setToken, components, _amountSetToken);

        if (address(_inputToken) == WETH) {
            return totalEth;
        }

        (uint256 tokenAmount, , ) = _getMinTokenForExactToken(totalEth, address(_inputToken), address(WETH));
        return tokenAmount;
    }

    /**
     * Returns amount of output ERC20 tokens received upon redeeming a given amount of SetToken.
     *
     * @param _setToken             Address of SetToken to be redeemed
     * @param _amountSetToken       Amount of SetToken to be redeemed
     * @param _outputToken          Address of output token
     *
     * @return                      Estimated amount of ether/erc20 that will be received
     */
    function getAmountOutOnRedeemSet(
        ISetToken _setToken,
        address _outputToken,
        uint256 _amountSetToken
    )
        isSetToken(_setToken)
        external
        view
        returns (uint256)
    {
        require(_amountSetToken > 0, "ExchangeIssuance: INVALID INPUTS");

        address[] memory components = _setToken.getComponents();
        (uint256 totalEth, , ) = _getAmountETHForRedemption(_setToken, components, _amountSetToken);

        if (_outputToken == WETH) {
            return totalEth;
        }

        // get maximum amount of tokens for totalEth amount of ETH
        (uint256 tokenAmount, , ) = _getMaxTokenForExactToken(totalEth, WETH, _outputToken);
        return tokenAmount;
    }


    /* ============ Internal Functions ============ */

    /**
     * Sets a max approval limit for an ERC20 token, provided the current allowance
     * is less than the required allownce.
     *
     * @param _token    Token to approve
     * @param _spender  Spender address to approve
     */
    function _safeApprove(IERC20 _token, address _spender, uint256 _requiredAllowance) internal {
        uint256 allowance = _token.allowance(address(this), _spender);
        if (allowance < _requiredAllowance) {
            _token.safeIncreaseAllowance(_spender, MAX_UINT96 - allowance);
        }
    }

    /**
     * Issues SetTokens for an exact amount of input WETH.
     *
     * @param _setToken         Address of the SetToken being issued
     * @param _minSetReceive    Minimum amount of index to receive
     * @param _totalEthAmount   Total amount of WETH to be used to purchase the SetToken components
     *
     * @return setTokenAmount   Amount of SetTokens issued
     */
    function _issueSetForExactWETH(ISetToken _setToken, uint256 _minSetReceive, uint256 _totalEthAmount) internal returns (uint256) {

        address[] memory components = _setToken.getComponents();
        (
            uint256 setIssueAmount,
            uint256[] memory amountEthIn,
            Exchange[] memory exchanges
        ) = _getSetIssueAmountForETH(_setToken, components, _totalEthAmount);

        require(setIssueAmount > _minSetReceive, "ExchangeIssuance: INSUFFICIENT_OUTPUT_AMOUNT");

        for (uint256 i = 0; i < components.length; i++) {
            _swapExactTokensForTokens(exchanges[i], WETH, components[i], amountEthIn[i]);
        }

        basicIssuanceModule.issue(_setToken, setIssueAmount, msg.sender);
        return setIssueAmount;
    }

    /**
     * Issues an exact amount of SetTokens using WETH.
     * Acquires SetToken components at the best price accross uniswap and sushiswap.
     * Uses the acquired components to issue the SetTokens.
     *
     * @param _setToken          Address of the SetToken being issued
     * @param _amountSetToken    Amount of SetTokens to be issued
     * @param _maxEther          Max amount of ether that can be used to acquire the SetToken components
     *
     * @return totalEth          Total amount of ether used to acquire the SetToken components
     */
    function _issueExactSetFromWETH(ISetToken _setToken, uint256 _amountSetToken, uint256 _maxEther) internal returns (uint256) {

        address[] memory components = _setToken.getComponents();
        (
            uint256 sumEth,
            ,
            Exchange[] memory exchanges,
            uint256[] memory amountComponents,
        ) = _getAmountETHForIssuance(_setToken, components, _amountSetToken);

        require(sumEth <= _maxEther, "ExchangeIssuance: INSUFFICIENT_INPUT_AMOUNT");

        uint256 totalEth = 0;
        for (uint256 i = 0; i < components.length; i++) {
            uint256 amountEth = _swapTokensForExactTokens(exchanges[i], WETH, components[i], amountComponents[i]);
            totalEth = totalEth.add(amountEth);
        }
        basicIssuanceModule.issue(_setToken, _amountSetToken, msg.sender);
        return totalEth;
    }

    /**
     * Redeems a given amount of SetToken.
     *
     * @param _setToken     Address of the SetToken to be redeemed
     * @param _amount       Amount of SetToken to be redeemed
     */
    function _redeemExactSet(ISetToken _setToken, uint256 _amount) internal returns (uint256) {
        _setToken.safeTransferFrom(msg.sender, address(this), _amount);
        basicIssuanceModule.redeem(_setToken, _amount, address(this));
    }

    /**
     * Liquidates a given list of SetToken components for WETH.
     *
     * @param _components           An array containing the address of SetToken components
     * @param _amountComponents     An array containing the amount of each SetToken component
     * @param _exchanges            An array containing the exchange on which to liquidate the SetToken component
     *
     * @return                      Total amount of WETH received after liquidating all SetToken components
     */
    function _liquidateComponentsForWETH(address[] memory _components, uint256[] memory _amountComponents, Exchange[] memory _exchanges)
        internal
        returns (uint256)
    {
        uint256 sumEth = 0;
        for (uint256 i = 0; i < _components.length; i++) {
            sumEth = _exchanges[i] == Exchange.None
                ? sumEth.add(_amountComponents[i])
                : sumEth.add(_swapExactTokensForTokens(_exchanges[i], _components[i], WETH, _amountComponents[i]));
        }
        return sumEth;
    }

    /**
     * Gets the total amount of ether required for purchasing each component in a SetToken,
     * to enable the issuance of a given amount of SetTokens.
     *
     * @param _setToken             Address of the SetToken to be issued
     * @param _components           An array containing the addresses of the SetToken components
     * @param _amountSetToken       Amount of SetToken to be issued
     *
     * @return sumEth               The total amount of Ether reuired to issue the set
     * @return amountEthIn          An array containing the amount of ether to purchase each component of the SetToken
     * @return exchanges            An array containing the exchange on which to perform the purchase
     * @return amountComponents     An array containing the amount of each SetToken component required for issuing the given
     *                              amount of SetToken
     * @return pairAddresses        An array containing the pair addresses of ETH/component exchange pool
     */
    function _getAmountETHForIssuance(ISetToken _setToken, address[] memory _components, uint256 _amountSetToken)
        internal
        view
        returns (
            uint256 sumEth,
            uint256[] memory amountEthIn,
            Exchange[] memory exchanges,
            uint256[] memory amountComponents,
            address[] memory pairAddresses
        )
    {
        sumEth = 0;
        amountEthIn = new uint256[](_components.length);
        amountComponents = new uint256[](_components.length);
        exchanges = new Exchange[](_components.length);
        pairAddresses = new address[](_components.length);

        for (uint256 i = 0; i < _components.length; i++) {

            // Check that the component does not have external positions
            require(
                _setToken.getExternalPositionModules(_components[i]).length == 0,
                "ExchangeIssuance: EXTERNAL_POSITIONS_NOT_ALLOWED"
            );

            // Get minimum amount of ETH to be spent to acquire the required amount of SetToken component
            uint256 unit = uint256(_setToken.getDefaultPositionRealUnit(_components[i]));
            amountComponents[i] = uint256(unit).preciseMulCeil(_amountSetToken);

            (amountEthIn[i], exchanges[i], pairAddresses[i]) = _getMinTokenForExactToken(amountComponents[i], WETH, _components[i]);
            sumEth = sumEth.add(amountEthIn[i]);
        }
        return (sumEth, amountEthIn, exchanges, amountComponents, pairAddresses);
    }

    /**
     * Gets the total amount of ether returned from liquidating each component in a SetToken.
     *
     * @param _setToken             Address of the SetToken to be redeemed
     * @param _components           An array containing the addresses of the SetToken components
     * @param _amountSetToken       Amount of SetToken to be redeemed
     *
     * @return sumEth               The total amount of Ether that would be obtained from liquidating the SetTokens
     * @return amountComponents     An array containing the amount of SetToken component to be liquidated
     * @return exchanges            An array containing the exchange on which to liquidate the SetToken components
     */
    function _getAmountETHForRedemption(ISetToken _setToken, address[] memory _components, uint256 _amountSetToken)
        internal
        view
        returns (uint256, uint256[] memory, Exchange[] memory)
    {
        uint256 sumEth = 0;
        uint256 amountEth = 0;

        uint256[] memory amountComponents = new uint256[](_components.length);
        Exchange[] memory exchanges = new Exchange[](_components.length);

        for (uint256 i = 0; i < _components.length; i++) {

            // Check that the component does not have external positions
            require(
                _setToken.getExternalPositionModules(_components[i]).length == 0,
                "ExchangeIssuance: EXTERNAL_POSITIONS_NOT_ALLOWED"
            );

            uint256 unit = uint256(_setToken.getDefaultPositionRealUnit(_components[i]));
            amountComponents[i] = unit.preciseMul(_amountSetToken);

            // get maximum amount of ETH received for a given amount of SetToken component
            (amountEth, exchanges[i], ) = _getMaxTokenForExactToken(amountComponents[i], _components[i], WETH);
            sumEth = sumEth.add(amountEth);
        }
        return (sumEth, amountComponents, exchanges);
    }

    /**
     * Returns an estimated amount of SetToken that can be issued given an amount of input ERC20 token.
     *
     * @param _setToken             Address of the SetToken to be issued
     * @param _components           An array containing the addresses of the SetToken components
     * @param _amountEth            Total amount of ether available for the purchase of SetToken components
     *
     * @return setIssueAmount       The max amount of SetTokens that can be issued
     * @return amountEthIn          An array containing the amount ether required to purchase each SetToken component
     * @return exchanges            An array containing the exchange on which to purchase the SetToken components
     */
    function _getSetIssueAmountForETH(ISetToken _setToken, address[] memory _components, uint256 _amountEth)
        internal
        view
        returns (uint256 setIssueAmount, uint256[] memory amountEthIn, Exchange[] memory exchanges)
    {
        uint256 sumEth;
        uint256[] memory unitAmountEthIn;
        uint256[] memory unitAmountComponents;
        address[] memory pairAddresses;
        (
            sumEth,
            unitAmountEthIn,
            exchanges,
            unitAmountComponents,
            pairAddresses
        ) = _getAmountETHForIssuance(_setToken, _components, PreciseUnitMath.preciseUnit());

        setIssueAmount = PreciseUnitMath.maxUint256();
        amountEthIn = new uint256[](_components.length);

        for (uint256 i = 0; i < _components.length; i++) {

            amountEthIn[i] = unitAmountEthIn[i].mul(_amountEth).div(sumEth);

            uint256 amountComponent;
            if (exchanges[i] == Exchange.None) {
                amountComponent = amountEthIn[i];
            } else {
                (uint256 reserveIn, uint256 reserveOut) = UniSushiV2Library.getReserves(pairAddresses[i], WETH, _components[i]);
                amountComponent = UniSushiV2Library.getAmountOut(amountEthIn[i], reserveIn, reserveOut);
            }
            setIssueAmount = Math.min(amountComponent.preciseDiv(unitAmountComponents[i]), setIssueAmount);
        }
        return (setIssueAmount, amountEthIn, exchanges);
    }

    /**
     * Swaps a given amount of an ERC20 token for WETH for the best price on Uniswap/Sushiswap.
     *
     * @param _token    Address of the ERC20 token to be swapped for WETH
     * @param _amount   Amount of ERC20 token to be swapped
     *
     * @return          Amount of WETH received after the swap
     */
    function _swapTokenForWETH(IERC20 _token, uint256 _amount) internal returns (uint256) {
        (, Exchange exchange, ) = _getMaxTokenForExactToken(_amount, address(_token), WETH);
        IUniswapV2Router02 router = _getRouter(exchange);
        _safeApprove(_token, address(router), _amount);
        return _swapExactTokensForTokens(exchange, address(_token), WETH, _amount);
    }

    /**
     * Swap exact tokens for another token on a given DEX.
     *
     * @param _exchange     The exchange on which to peform the swap
     * @param _tokenIn      The address of the input token
     * @param _tokenOut     The address of the output token
     * @param _amountIn     The amount of input token to be spent
     *
     * @return              The amount of output tokens
     */
    function _swapExactTokensForTokens(Exchange _exchange, address _tokenIn, address _tokenOut, uint256 _amountIn) internal returns (uint256) {
        if (_tokenIn == _tokenOut) {
            return _amountIn;
        }
        address[] memory path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;
        return _getRouter(_exchange).swapExactTokensForTokens(_amountIn, 0, path, address(this), block.timestamp)[1];
    }

    /**
     * Swap tokens for exact amount of output tokens on a given DEX.
     *
     * @param _exchange     The exchange on which to peform the swap
     * @param _tokenIn      The address of the input token
     * @param _tokenOut     The address of the output token
     * @param _amountOut    The amount of output token required
     *
     * @return              The amount of input tokens spent
     */
    function _swapTokensForExactTokens(Exchange _exchange, address _tokenIn, address _tokenOut, uint256 _amountOut) internal returns (uint256) {
        if (_tokenIn == _tokenOut) {
            return _amountOut;
        }
        address[] memory path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;
        return _getRouter(_exchange).swapTokensForExactTokens(_amountOut, PreciseUnitMath.maxUint256(), path, address(this), block.timestamp)[0];
    }

    /**
     * Compares the amount of token required for an exact amount of another token across both exchanges,
     * and returns the min amount.
     *
     * @param _amountOut    The amount of output token
     * @param _tokenA       The address of tokenA
     * @param _tokenB       The address of tokenB
     *
     * @return              The min amount of tokenA required across both exchanges
     * @return              The Exchange on which minimum amount of tokenA is required
     * @return              The pair address of the uniswap/sushiswap pool containing _tokenA and _tokenB
     */
    function _getMinTokenForExactToken(uint256 _amountOut, address _tokenA, address _tokenB) internal view returns (uint256, Exchange, address) {
        if (_tokenA == _tokenB) {
            return (_amountOut, Exchange.None, ETH_ADDRESS);
        }

        uint256 maxIn = PreciseUnitMath.maxUint256() ;
        uint256 uniTokenIn = maxIn;
        uint256 sushiTokenIn = maxIn;

        address uniswapPair = _getPair(uniFactory, _tokenA, _tokenB);
        if (uniswapPair != address(0)) {
            (uint256 reserveIn, uint256 reserveOut) = UniSushiV2Library.getReserves(uniswapPair, _tokenA, _tokenB);
            // Prevent subtraction overflow by making sure pool reserves are greater than swap amount
            if (reserveOut > _amountOut) {
                uniTokenIn = UniSushiV2Library.getAmountIn(_amountOut, reserveIn, reserveOut);
            }
        }

        address sushiswapPair = _getPair(sushiFactory, _tokenA, _tokenB);
        if (sushiswapPair != address(0)) {
            (uint256 reserveIn, uint256 reserveOut) = UniSushiV2Library.getReserves(sushiswapPair, _tokenA, _tokenB);
            // Prevent subtraction overflow by making sure pool reserves are greater than swap amount
            if (reserveOut > _amountOut) {
                sushiTokenIn = UniSushiV2Library.getAmountIn(_amountOut, reserveIn, reserveOut);
            }
        }

        // Fails if both the values are maxIn
        require(!(uniTokenIn == maxIn && sushiTokenIn == maxIn), "ExchangeIssuance: ILLIQUID_SET_COMPONENT");
        return (uniTokenIn <= sushiTokenIn) ? (uniTokenIn, Exchange.Uniswap, uniswapPair) : (sushiTokenIn, Exchange.Sushiswap, sushiswapPair);
    }

    /**
     * Compares the amount of token received for an exact amount of another token across both exchanges,
     * and returns the max amount.
     *
     * @param _amountIn     The amount of input token
     * @param _tokenA       The address of tokenA
     * @param _tokenB       The address of tokenB
     *
     * @return              The max amount of tokens that can be received across both exchanges
     * @return              The Exchange on which maximum amount of token can be received
     * @return              The pair address of the uniswap/sushiswap pool containing _tokenA and _tokenB
     */
    function _getMaxTokenForExactToken(uint256 _amountIn, address _tokenA, address _tokenB) internal view returns (uint256, Exchange, address) {
        if (_tokenA == _tokenB) {
            return (_amountIn, Exchange.None, ETH_ADDRESS);
        }

        uint256 uniTokenOut = 0;
        uint256 sushiTokenOut = 0;

        address uniswapPair = _getPair(uniFactory, _tokenA, _tokenB);
        if(uniswapPair != address(0)) {
            (uint256 reserveIn, uint256 reserveOut) = UniSushiV2Library.getReserves(uniswapPair, _tokenA, _tokenB);
            uniTokenOut = UniSushiV2Library.getAmountOut(_amountIn, reserveIn, reserveOut);
        }

        address sushiswapPair = _getPair(sushiFactory, _tokenA, _tokenB);
        if(sushiswapPair != address(0)) {
            (uint256 reserveIn, uint256 reserveOut) = UniSushiV2Library.getReserves(sushiswapPair, _tokenA, _tokenB);
            sushiTokenOut = UniSushiV2Library.getAmountOut(_amountIn, reserveIn, reserveOut);
        }

        // Fails if both the values are 0
        require(!(uniTokenOut == 0 && sushiTokenOut == 0), "ExchangeIssuance: ILLIQUID_SET_COMPONENT");
        return (uniTokenOut >= sushiTokenOut) ? (uniTokenOut, Exchange.Uniswap, uniswapPair) : (sushiTokenOut, Exchange.Sushiswap, sushiswapPair);
    }

    /**
     * Returns the pair address for on a given DEX.
     *
     * @param _factory   The factory to address
     * @param _tokenA    The address of tokenA
     * @param _tokenB    The address of tokenB
     *
     * @return           The pair address (Note: address(0) is returned by default if the pair is not available on that DEX)
     */
    function _getPair(address _factory, address _tokenA, address _tokenB) internal view returns (address) {
        return IUniswapV2Factory(_factory).getPair(_tokenA, _tokenB);
    }

    /**
     * Returns the router address of a given exchange.
     *
     * @param _exchange     The Exchange whose router address is needed
     *
     * @return              IUniswapV2Router02 router of the given exchange
     */
     function _getRouter(Exchange _exchange) internal view returns(IUniswapV2Router02) {
         return (_exchange == Exchange.Uniswap) ? uniRouter : sushiRouter;
     }

}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

/*
    Copyright 2020 Set Labs Inc.
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity >=0.6.10;

import { ISetToken } from "./ISetToken.sol";

interface IBasicIssuanceModule {
    function getRequiredComponentUnitsForIssue(
        ISetToken _setToken,
        uint256 _quantity
    ) external returns(address[] memory, uint256[] memory);
    function issue(ISetToken _setToken, uint256 _quantity, address _to) external;
    function redeem(ISetToken _token, uint256 _quantity, address _to) external;
}

/*
    Copyright 2020 Set Labs Inc.
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;

interface IController {
    function addSet(address _setToken) external;
    function feeRecipient() external view returns(address);
    function getModuleFee(address _module, uint256 _feeType) external view returns(uint256);
    function isModule(address _module) external view returns(bool);
    function isSet(address _setToken) external view returns(bool);
    function isSystemContract(address _contractAddress) external view returns (bool);
    function resourceId(uint256 _id) external view returns(address);
}

pragma solidity >=0.6.10;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

library UniSushiV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address pair, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pair).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

/*
    Copyright 2021 Index Cooperative
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IUniswapV2Factory } from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import { Math } from "@openzeppelin/contracts/math/Math.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { IBasicIssuanceModule } from "../interfaces/IBasicIssuanceModule.sol";
import { IController } from "../interfaces/IController.sol";
import { ISetToken } from "../interfaces/ISetToken.sol";
import { IWETH } from "../interfaces/IWETH.sol";
import { PreciseUnitMath } from "../lib/PreciseUnitMath.sol";
import { UniSushiV2Library } from "../../external/contracts/UniSushiV2Library.sol";


/**
 * @title ExchangeIssuance
 * @author Index Coop
 *
 * Contract for issuing and redeeming any SetToken using ETH or an ERC20 as the paying/receiving currency.
 * All swaps are done using the best price found on Uniswap or Sushiswap.
 *
 */
contract ExchangeIssuance is ReentrancyGuard {

    using Address for address payable;
    using SafeMath for uint256;
    using PreciseUnitMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for ISetToken;

    /* ============ Enums ============ */

    enum Exchange { Uniswap, Sushiswap, None }

    /* ============ Constants ============= */

    uint256 constant private MAX_UINT96 = 2**96 - 1;
    address constant public ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /* ============ State Variables ============ */

    address public WETH;
    IUniswapV2Router02 public uniRouter;
    IUniswapV2Router02 public sushiRouter;

    address public immutable uniFactory;
    address public immutable sushiFactory;

    IController public immutable setController;
    IBasicIssuanceModule public immutable basicIssuanceModule;

    /* ============ Events ============ */

    event ExchangeIssue(
        address indexed _recipient,     // The recipient address of the issued SetTokens
        ISetToken indexed _setToken,    // The issued SetToken
        IERC20 indexed _inputToken,     // The address of the input asset(ERC20/ETH) used to issue the SetTokens
        uint256 _amountInputToken,      // The amount of input tokens used for issuance
        uint256 _amountSetIssued        // The amount of SetTokens received by the recipient
    );

    event ExchangeRedeem(
        address indexed _recipient,     // The recipient address which redeemed the SetTokens
        ISetToken indexed _setToken,    // The redeemed SetToken
        IERC20 indexed _outputToken,    // The address of output asset(ERC20/ETH) received by the recipient
        uint256 _amountSetRedeemed,     // The amount of SetTokens redeemed for output tokens
        uint256 _amountOutputToken      // The amount of output tokens received by the recipient
    );

    event Refund(
        address indexed _recipient,     // The recipient address which redeemed the SetTokens
        uint256 _refundAmount           // The amount of ETH redunded to the recipient
    );

    /* ============ Modifiers ============ */

    modifier isSetToken(ISetToken _setToken) {
         require(setController.isSet(address(_setToken)), "ExchangeIssuance: INVALID SET");
         _;
    }

    /* ============ Constructor ============ */

    constructor(
        address _weth,
        address _uniFactory,
        IUniswapV2Router02 _uniRouter,
        address _sushiFactory,
        IUniswapV2Router02 _sushiRouter,
        IController _setController,
        IBasicIssuanceModule _basicIssuanceModule
    )
        public
    {
        uniFactory = _uniFactory;
        uniRouter = _uniRouter;

        sushiFactory = _sushiFactory;
        sushiRouter = _sushiRouter;

        setController = _setController;
        basicIssuanceModule = _basicIssuanceModule;

        WETH = _weth;
        IERC20(WETH).safeApprove(address(uniRouter), PreciseUnitMath.maxUint256());
        IERC20(WETH).safeApprove(address(sushiRouter), PreciseUnitMath.maxUint256());
    }

    /* ============ Public Functions ============ */

    /**
     * Runs all the necessary approval functions required for a given ERC20 token.
     * This function can be called when a new token is added to a SetToken during a
     * rebalance.
     *
     * @param _token    Address of the token which needs approval
     */
    function approveToken(IERC20 _token) public {
        _safeApprove(_token, address(uniRouter), MAX_UINT96);
        _safeApprove(_token, address(sushiRouter), MAX_UINT96);
        _safeApprove(_token, address(basicIssuanceModule), MAX_UINT96);
    }

    /* ============ External Functions ============ */

    receive() external payable {
        // required for weth.withdraw() to work properly
        require(msg.sender == WETH, "ExchangeIssuance: Direct deposits not allowed");
    }

    /**
     * Runs all the necessary approval functions required for a list of ERC20 tokens.
     *
     * @param _tokens    Addresses of the tokens which need approval
     */
    function approveTokens(IERC20[] calldata _tokens) external {
        for (uint256 i = 0; i < _tokens.length; i++) {
            approveToken(_tokens[i]);
        }
    }

    /**
     * Runs all the necessary approval functions required before issuing
     * or redeeming a SetToken. This function need to be called only once before the first time
     * this smart contract is used on any particular SetToken.
     *
     * @param _setToken    Address of the SetToken being initialized
     */
    function approveSetToken(ISetToken _setToken) isSetToken(_setToken) external {
        address[] memory components = _setToken.getComponents();
        for (uint256 i = 0; i < components.length; i++) {
            // Check that the component does not have external positions
            require(
                _setToken.getExternalPositionModules(components[i]).length == 0,
                "ExchangeIssuance: EXTERNAL_POSITIONS_NOT_ALLOWED"
            );
            approveToken(IERC20(components[i]));
        }
    }

    /**
     * Issues SetTokens for an exact amount of input ERC20 tokens.
     * The ERC20 token must be approved by the sender to this contract.
     *
     * @param _setToken         Address of the SetToken being issued
     * @param _inputToken       Address of input token
     * @param _amountInput      Amount of the input token / ether to spend
     * @param _minSetReceive    Minimum amount of SetTokens to receive. Prevents unnecessary slippage.
     *
     * @return setTokenAmount   Amount of SetTokens issued to the caller
     */
    function issueSetForExactToken(
        ISetToken _setToken,
        IERC20 _inputToken,
        uint256 _amountInput,
        uint256 _minSetReceive
    )
        isSetToken(_setToken)
        external
        nonReentrant
        returns (uint256)
    {
        require(_amountInput > 0, "ExchangeIssuance: INVALID INPUTS");

        _inputToken.safeTransferFrom(msg.sender, address(this), _amountInput);

        uint256 amountEth = address(_inputToken) == WETH
            ? _amountInput
            : _swapTokenForWETH(_inputToken, _amountInput);

        uint256 setTokenAmount = _issueSetForExactWETH(_setToken, _minSetReceive, amountEth);

        emit ExchangeIssue(msg.sender, _setToken, _inputToken, _amountInput, setTokenAmount);
        return setTokenAmount;
    }

    /**
     * Issues SetTokens for an exact amount of input ether.
     *
     * @param _setToken         Address of the SetToken to be issued
     * @param _minSetReceive    Minimum amount of SetTokens to receive. Prevents unnecessary slippage.
     *
     * @return setTokenAmount   Amount of SetTokens issued to the caller
     */
    function issueSetForExactETH(
        ISetToken _setToken,
        uint256 _minSetReceive
    )
        isSetToken(_setToken)
        external
        payable
        nonReentrant
        returns(uint256)
    {
        require(msg.value > 0, "ExchangeIssuance: INVALID INPUTS");

        IWETH(WETH).deposit{value: msg.value}();

        uint256 setTokenAmount = _issueSetForExactWETH(_setToken, _minSetReceive, msg.value);

        emit ExchangeIssue(msg.sender, _setToken, IERC20(ETH_ADDRESS), msg.value, setTokenAmount);
        return setTokenAmount;
    }

    /**
    * Issues an exact amount of SetTokens for given amount of input ERC20 tokens.
    * The excess amount of tokens is returned in an equivalent amount of ether.
    *
    * @param _setToken              Address of the SetToken to be issued
    * @param _inputToken            Address of the input token
    * @param _amountSetToken        Amount of SetTokens to issue
    * @param _maxAmountInputToken   Maximum amount of input tokens to be used to issue SetTokens. The unused
    *                               input tokens are returned as ether.
    *
    * @return amountEthReturn       Amount of ether returned to the caller
    */
    function issueExactSetFromToken(
        ISetToken _setToken,
        IERC20 _inputToken,
        uint256 _amountSetToken,
        uint256 _maxAmountInputToken
    )
        isSetToken(_setToken)
        external
        nonReentrant
        returns (uint256)
    {
        require(_amountSetToken > 0 && _maxAmountInputToken > 0, "ExchangeIssuance: INVALID INPUTS");

        _inputToken.safeTransferFrom(msg.sender, address(this), _maxAmountInputToken);

        uint256 initETHAmount = address(_inputToken) == WETH
            ? _maxAmountInputToken
            : _swapTokenForWETH(_inputToken, _maxAmountInputToken);

        uint256 amountEthSpent = _issueExactSetFromWETH(_setToken, _amountSetToken, initETHAmount);

        uint256 amountEthReturn = initETHAmount.sub(amountEthSpent);
        if (amountEthReturn > 0) {
            IWETH(WETH).withdraw(amountEthReturn);
            (payable(msg.sender)).sendValue(amountEthReturn);
        }

        emit Refund(msg.sender, amountEthReturn);
        emit ExchangeIssue(msg.sender, _setToken, _inputToken, _maxAmountInputToken, _amountSetToken);
        return amountEthReturn;
    }

    /**
    * Issues an exact amount of SetTokens using a given amount of ether.
    * The excess ether is returned back.
    *
    * @param _setToken          Address of the SetToken being issued
    * @param _amountSetToken    Amount of SetTokens to issue
    *
    * @return amountEthReturn   Amount of ether returned to the caller
    */
    function issueExactSetFromETH(
        ISetToken _setToken,
        uint256 _amountSetToken
    )
        isSetToken(_setToken)
        external
        payable
        nonReentrant
        returns (uint256)
    {
        require(msg.value > 0 && _amountSetToken > 0, "ExchangeIssuance: INVALID INPUTS");

        IWETH(WETH).deposit{value: msg.value}();

        uint256 amountEth = _issueExactSetFromWETH(_setToken, _amountSetToken, msg.value);

        uint256 amountEthReturn = msg.value.sub(amountEth);

        if (amountEthReturn > 0) {
            IWETH(WETH).withdraw(amountEthReturn);
            (payable(msg.sender)).sendValue(amountEthReturn);
        }

        emit Refund(msg.sender, amountEthReturn);
        emit ExchangeIssue(msg.sender, _setToken, IERC20(ETH_ADDRESS), amountEth, _amountSetToken);
        return amountEthReturn;
    }

    /**
     * Redeems an exact amount of SetTokens for an ERC20 token.
     * The SetToken must be approved by the sender to this contract.
     *
     * @param _setToken             Address of the SetToken being redeemed
     * @param _outputToken          Address of output token
     * @param _amountSetToken       Amount SetTokens to redeem
     * @param _minOutputReceive     Minimum amount of output token to receive
     *
     * @return outputAmount         Amount of output tokens sent to the caller
     */
    function redeemExactSetForToken(
        ISetToken _setToken,
        IERC20 _outputToken,
        uint256 _amountSetToken,
        uint256 _minOutputReceive
    )
        isSetToken(_setToken)
        external
        nonReentrant
        returns (uint256)
    {
        require(_amountSetToken > 0, "ExchangeIssuance: INVALID INPUTS");

        address[] memory components = _setToken.getComponents();
        (
            uint256 totalEth,
            uint256[] memory amountComponents,
            Exchange[] memory exchanges
        ) =  _getAmountETHForRedemption(_setToken, components, _amountSetToken);

        uint256 outputAmount;
        if (address(_outputToken) == WETH) {
            require(totalEth > _minOutputReceive, "ExchangeIssuance: INSUFFICIENT_OUTPUT_AMOUNT");
            _redeemExactSet(_setToken, _amountSetToken);
            outputAmount = _liquidateComponentsForWETH(components, amountComponents, exchanges);
        } else {
            (uint256 totalOutput, Exchange outTokenExchange, ) = _getMaxTokenForExactToken(totalEth, address(WETH), address(_outputToken));
            require(totalOutput > _minOutputReceive, "ExchangeIssuance: INSUFFICIENT_OUTPUT_AMOUNT");
            _redeemExactSet(_setToken, _amountSetToken);
            uint256 outputEth = _liquidateComponentsForWETH(components, amountComponents, exchanges);
            outputAmount = _swapExactTokensForTokens(outTokenExchange, WETH, address(_outputToken), outputEth);
        }

        _outputToken.safeTransfer(msg.sender, outputAmount);
        emit ExchangeRedeem(msg.sender, _setToken, _outputToken, _amountSetToken, outputAmount);
        return outputAmount;
    }

    /**
     * Redeems an exact amount of SetTokens for ETH.
     * The SetToken must be approved by the sender to this contract.
     *
     * @param _setToken             Address of the SetToken to be redeemed
     * @param _amountSetToken       Amount of SetTokens to redeem
     * @param _minEthOut            Minimum amount of ETH to receive
     *
     * @return amountEthOut         Amount of ether sent to the caller
     */
    function redeemExactSetForETH(
        ISetToken _setToken,
        uint256 _amountSetToken,
        uint256 _minEthOut
    )
        isSetToken(_setToken)
        external
        nonReentrant
        returns (uint256)
    {
        require(_amountSetToken > 0, "ExchangeIssuance: INVALID INPUTS");

        address[] memory components = _setToken.getComponents();
        (
            uint256 totalEth,
            uint256[] memory amountComponents,
            Exchange[] memory exchanges
        ) =  _getAmountETHForRedemption(_setToken, components, _amountSetToken);

        require(totalEth > _minEthOut, "ExchangeIssuance: INSUFFICIENT_OUTPUT_AMOUNT");

        _redeemExactSet(_setToken, _amountSetToken);

        uint256 amountEthOut = _liquidateComponentsForWETH(components, amountComponents, exchanges);

        IWETH(WETH).withdraw(amountEthOut);
        (payable(msg.sender)).sendValue(amountEthOut);

        emit ExchangeRedeem(msg.sender, _setToken, IERC20(ETH_ADDRESS), _amountSetToken, amountEthOut);
        return amountEthOut;
    }

    /**
     * Returns an estimated amount of SetToken that can be issued given an amount of input ERC20 token.
     *
     * @param _setToken         Address of the SetToken being issued
     * @param _amountInput      Amount of the input token to spend
     * @param _inputToken       Address of input token.
     *
     * @return                  Estimated amount of SetTokens that will be received
     */
    function getEstimatedIssueSetAmount(
        ISetToken _setToken,
        IERC20 _inputToken,
        uint256 _amountInput
    )
        isSetToken(_setToken)
        external
        view
        returns (uint256)
    {
        require(_amountInput > 0, "ExchangeIssuance: INVALID INPUTS");

        uint256 amountEth;
        if (address(_inputToken) != WETH) {
            // get max amount of WETH for the `_amountInput` amount of input tokens
            (amountEth, , ) = _getMaxTokenForExactToken(_amountInput, address(_inputToken), WETH);
        } else {
            amountEth = _amountInput;
        }

        address[] memory components = _setToken.getComponents();
        (uint256 setIssueAmount, , ) = _getSetIssueAmountForETH(_setToken, components, amountEth);
        return setIssueAmount;
    }

    /**
    * Returns the amount of input ERC20 tokens required to issue an exact amount of SetTokens.
    *
    * @param _setToken          Address of the SetToken being issued
    * @param _amountSetToken    Amount of SetTokens to issue
    *
    * @return                   Amount of tokens needed to issue specified amount of SetTokens
    */
    function getAmountInToIssueExactSet(
        ISetToken _setToken,
        IERC20 _inputToken,
        uint256 _amountSetToken
    )
        isSetToken(_setToken)
        external
        view
        returns(uint256)
    {
        require(_amountSetToken > 0, "ExchangeIssuance: INVALID INPUTS");

        address[] memory components = _setToken.getComponents();
        (uint256 totalEth, , , , ) = _getAmountETHForIssuance(_setToken, components, _amountSetToken);

        if (address(_inputToken) == WETH) {
            return totalEth;
        }

        (uint256 tokenAmount, , ) = _getMinTokenForExactToken(totalEth, address(_inputToken), address(WETH));
        return tokenAmount;
    }

    /**
     * Returns amount of output ERC20 tokens received upon redeeming a given amount of SetToken.
     *
     * @param _setToken             Address of SetToken to be redeemed
     * @param _amountSetToken       Amount of SetToken to be redeemed
     * @param _outputToken          Address of output token
     *
     * @return                      Estimated amount of ether/erc20 that will be received
     */
    function getAmountOutOnRedeemSet(
        ISetToken _setToken,
        address _outputToken,
        uint256 _amountSetToken
    )
        isSetToken(_setToken)
        external
        view
        returns (uint256)
    {
        require(_amountSetToken > 0, "ExchangeIssuance: INVALID INPUTS");

        address[] memory components = _setToken.getComponents();
        (uint256 totalEth, , ) = _getAmountETHForRedemption(_setToken, components, _amountSetToken);

        if (_outputToken == WETH) {
            return totalEth;
        }

        // get maximum amount of tokens for totalEth amount of ETH
        (uint256 tokenAmount, , ) = _getMaxTokenForExactToken(totalEth, WETH, _outputToken);
        return tokenAmount;
    }


    /* ============ Internal Functions ============ */

    /**
     * Sets a max approval limit for an ERC20 token, provided the current allowance
     * is less than the required allownce.
     *
     * @param _token    Token to approve
     * @param _spender  Spender address to approve
     */
    function _safeApprove(IERC20 _token, address _spender, uint256 _requiredAllowance) internal {
        uint256 allowance = _token.allowance(address(this), _spender);
        if (allowance < _requiredAllowance) {
            _token.safeIncreaseAllowance(_spender, MAX_UINT96 - allowance);
        }
    }

    /**
     * Issues SetTokens for an exact amount of input WETH.
     *
     * @param _setToken         Address of the SetToken being issued
     * @param _minSetReceive    Minimum amount of index to receive
     * @param _totalEthAmount   Total amount of WETH to be used to purchase the SetToken components
     *
     * @return setTokenAmount   Amount of SetTokens issued
     */
    function _issueSetForExactWETH(ISetToken _setToken, uint256 _minSetReceive, uint256 _totalEthAmount) internal returns (uint256) {

        address[] memory components = _setToken.getComponents();
        (
            uint256 setIssueAmount,
            uint256[] memory amountEthIn,
            Exchange[] memory exchanges
        ) = _getSetIssueAmountForETH(_setToken, components, _totalEthAmount);

        require(setIssueAmount > _minSetReceive, "ExchangeIssuance: INSUFFICIENT_OUTPUT_AMOUNT");

        for (uint256 i = 0; i < components.length; i++) {
            _swapExactTokensForTokens(exchanges[i], WETH, components[i], amountEthIn[i]);
        }

        basicIssuanceModule.issue(_setToken, setIssueAmount, msg.sender);
        return setIssueAmount;
    }

    /**
     * Issues an exact amount of SetTokens using WETH.
     * Acquires SetToken components at the best price accross uniswap and sushiswap.
     * Uses the acquired components to issue the SetTokens.
     *
     * @param _setToken          Address of the SetToken being issued
     * @param _amountSetToken    Amount of SetTokens to be issued
     * @param _maxEther          Max amount of ether that can be used to acquire the SetToken components
     *
     * @return totalEth          Total amount of ether used to acquire the SetToken components
     */
    function _issueExactSetFromWETH(ISetToken _setToken, uint256 _amountSetToken, uint256 _maxEther) internal returns (uint256) {

        address[] memory components = _setToken.getComponents();
        (
            uint256 sumEth,
            ,
            Exchange[] memory exchanges,
            uint256[] memory amountComponents,
        ) = _getAmountETHForIssuance(_setToken, components, _amountSetToken);

        require(sumEth <= _maxEther, "ExchangeIssuance: INSUFFICIENT_INPUT_AMOUNT");

        uint256 totalEth = 0;
        for (uint256 i = 0; i < components.length; i++) {
            uint256 amountEth = _swapTokensForExactTokens(exchanges[i], WETH, components[i], amountComponents[i]);
            totalEth = totalEth.add(amountEth);
        }
        basicIssuanceModule.issue(_setToken, _amountSetToken, msg.sender);
        return totalEth;
    }

    /**
     * Redeems a given amount of SetToken.
     *
     * @param _setToken     Address of the SetToken to be redeemed
     * @param _amount       Amount of SetToken to be redeemed
     */
    function _redeemExactSet(ISetToken _setToken, uint256 _amount) internal returns (uint256) {
        _setToken.safeTransferFrom(msg.sender, address(this), _amount);
        basicIssuanceModule.redeem(_setToken, _amount, address(this));
    }

    /**
     * Liquidates a given list of SetToken components for WETH.
     *
     * @param _components           An array containing the address of SetToken components
     * @param _amountComponents     An array containing the amount of each SetToken component
     * @param _exchanges            An array containing the exchange on which to liquidate the SetToken component
     *
     * @return                      Total amount of WETH received after liquidating all SetToken components
     */
    function _liquidateComponentsForWETH(address[] memory _components, uint256[] memory _amountComponents, Exchange[] memory _exchanges)
        internal
        returns (uint256)
    {
        uint256 sumEth = 0;
        for (uint256 i = 0; i < _components.length; i++) {
            sumEth = _exchanges[i] == Exchange.None
                ? sumEth.add(_amountComponents[i])
                : sumEth.add(_swapExactTokensForTokens(_exchanges[i], _components[i], WETH, _amountComponents[i]));
        }
        return sumEth;
    }

    /**
     * Gets the total amount of ether required for purchasing each component in a SetToken,
     * to enable the issuance of a given amount of SetTokens.
     *
     * @param _setToken             Address of the SetToken to be issued
     * @param _components           An array containing the addresses of the SetToken components
     * @param _amountSetToken       Amount of SetToken to be issued
     *
     * @return sumEth               The total amount of Ether reuired to issue the set
     * @return amountEthIn          An array containing the amount of ether to purchase each component of the SetToken
     * @return exchanges            An array containing the exchange on which to perform the purchase
     * @return amountComponents     An array containing the amount of each SetToken component required for issuing the given
     *                              amount of SetToken
     * @return pairAddresses        An array containing the pair addresses of ETH/component exchange pool
     */
    function _getAmountETHForIssuance(ISetToken _setToken, address[] memory _components, uint256 _amountSetToken)
        internal
        view
        returns (
            uint256 sumEth,
            uint256[] memory amountEthIn,
            Exchange[] memory exchanges,
            uint256[] memory amountComponents,
            address[] memory pairAddresses
        )
    {
        sumEth = 0;
        amountEthIn = new uint256[](_components.length);
        amountComponents = new uint256[](_components.length);
        exchanges = new Exchange[](_components.length);
        pairAddresses = new address[](_components.length);

        for (uint256 i = 0; i < _components.length; i++) {

            // Check that the component does not have external positions
            require(
                _setToken.getExternalPositionModules(_components[i]).length == 0,
                "ExchangeIssuance: EXTERNAL_POSITIONS_NOT_ALLOWED"
            );

            // Get minimum amount of ETH to be spent to acquire the required amount of SetToken component
            uint256 unit = uint256(_setToken.getDefaultPositionRealUnit(_components[i]));
            amountComponents[i] = uint256(unit).preciseMulCeil(_amountSetToken);

            (amountEthIn[i], exchanges[i], pairAddresses[i]) = _getMinTokenForExactToken(amountComponents[i], WETH, _components[i]);
            sumEth = sumEth.add(amountEthIn[i]);
        }
        return (sumEth, amountEthIn, exchanges, amountComponents, pairAddresses);
    }

    /**
     * Gets the total amount of ether returned from liquidating each component in a SetToken.
     *
     * @param _setToken             Address of the SetToken to be redeemed
     * @param _components           An array containing the addresses of the SetToken components
     * @param _amountSetToken       Amount of SetToken to be redeemed
     *
     * @return sumEth               The total amount of Ether that would be obtained from liquidating the SetTokens
     * @return amountComponents     An array containing the amount of SetToken component to be liquidated
     * @return exchanges            An array containing the exchange on which to liquidate the SetToken components
     */
    function _getAmountETHForRedemption(ISetToken _setToken, address[] memory _components, uint256 _amountSetToken)
        internal
        view
        returns (uint256, uint256[] memory, Exchange[] memory)
    {
        uint256 sumEth = 0;
        uint256 amountEth = 0;

        uint256[] memory amountComponents = new uint256[](_components.length);
        Exchange[] memory exchanges = new Exchange[](_components.length);

        for (uint256 i = 0; i < _components.length; i++) {

            // Check that the component does not have external positions
            require(
                _setToken.getExternalPositionModules(_components[i]).length == 0,
                "ExchangeIssuance: EXTERNAL_POSITIONS_NOT_ALLOWED"
            );

            uint256 unit = uint256(_setToken.getDefaultPositionRealUnit(_components[i]));
            amountComponents[i] = unit.preciseMul(_amountSetToken);

            // get maximum amount of ETH received for a given amount of SetToken component
            (amountEth, exchanges[i], ) = _getMaxTokenForExactToken(amountComponents[i], _components[i], WETH);
            sumEth = sumEth.add(amountEth);
        }
        return (sumEth, amountComponents, exchanges);
    }

    /**
     * Returns an estimated amount of SetToken that can be issued given an amount of input ERC20 token.
     *
     * @param _setToken             Address of the SetToken to be issued
     * @param _components           An array containing the addresses of the SetToken components
     * @param _amountEth            Total amount of ether available for the purchase of SetToken components
     *
     * @return setIssueAmount       The max amount of SetTokens that can be issued
     * @return amountEthIn          An array containing the amount ether required to purchase each SetToken component
     * @return exchanges            An array containing the exchange on which to purchase the SetToken components
     */
    function _getSetIssueAmountForETH(ISetToken _setToken, address[] memory _components, uint256 _amountEth)
        internal
        view
        returns (uint256 setIssueAmount, uint256[] memory amountEthIn, Exchange[] memory exchanges)
    {
        uint256 sumEth;
        uint256[] memory unitAmountEthIn;
        uint256[] memory unitAmountComponents;
        address[] memory pairAddresses;
        (
            sumEth,
            unitAmountEthIn,
            exchanges,
            unitAmountComponents,
            pairAddresses
        ) = _getAmountETHForIssuance(_setToken, _components, PreciseUnitMath.preciseUnit());

        setIssueAmount = PreciseUnitMath.maxUint256();
        amountEthIn = new uint256[](_components.length);

        for (uint256 i = 0; i < _components.length; i++) {

            amountEthIn[i] = unitAmountEthIn[i].mul(_amountEth).div(sumEth);

            uint256 amountComponent;
            if (exchanges[i] == Exchange.None) {
                amountComponent = amountEthIn[i];
            } else {
                (uint256 reserveIn, uint256 reserveOut) = UniSushiV2Library.getReserves(pairAddresses[i], WETH, _components[i]);
                amountComponent = UniSushiV2Library.getAmountOut(amountEthIn[i], reserveIn, reserveOut);
            }
            setIssueAmount = Math.min(amountComponent.preciseDiv(unitAmountComponents[i]), setIssueAmount);
        }
        return (setIssueAmount, amountEthIn, exchanges);
    }

    /**
     * Swaps a given amount of an ERC20 token for WETH for the best price on Uniswap/Sushiswap.
     *
     * @param _token    Address of the ERC20 token to be swapped for WETH
     * @param _amount   Amount of ERC20 token to be swapped
     *
     * @return          Amount of WETH received after the swap
     */
    function _swapTokenForWETH(IERC20 _token, uint256 _amount) internal returns (uint256) {
        (, Exchange exchange, ) = _getMaxTokenForExactToken(_amount, address(_token), WETH);
        IUniswapV2Router02 router = _getRouter(exchange);
        _safeApprove(_token, address(router), _amount);
        return _swapExactTokensForTokens(exchange, address(_token), WETH, _amount);
    }

    /**
     * Swap exact tokens for another token on a given DEX.
     *
     * @param _exchange     The exchange on which to peform the swap
     * @param _tokenIn      The address of the input token
     * @param _tokenOut     The address of the output token
     * @param _amountIn     The amount of input token to be spent
     *
     * @return              The amount of output tokens
     */
    function _swapExactTokensForTokens(Exchange _exchange, address _tokenIn, address _tokenOut, uint256 _amountIn) internal returns (uint256) {
        if (_tokenIn == _tokenOut) {
            return _amountIn;
        }
        address[] memory path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;
        return _getRouter(_exchange).swapExactTokensForTokens(_amountIn, 0, path, address(this), block.timestamp)[1];
    }

    /**
     * Swap tokens for exact amount of output tokens on a given DEX.
     *
     * @param _exchange     The exchange on which to peform the swap
     * @param _tokenIn      The address of the input token
     * @param _tokenOut     The address of the output token
     * @param _amountOut    The amount of output token required
     *
     * @return              The amount of input tokens spent
     */
    function _swapTokensForExactTokens(Exchange _exchange, address _tokenIn, address _tokenOut, uint256 _amountOut) internal returns (uint256) {
        if (_tokenIn == _tokenOut) {
            return _amountOut;
        }
        address[] memory path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;
        return _getRouter(_exchange).swapTokensForExactTokens(_amountOut, PreciseUnitMath.maxUint256(), path, address(this), block.timestamp)[0];
    }

    /**
     * Compares the amount of token required for an exact amount of another token across both exchanges,
     * and returns the min amount.
     *
     * @param _amountOut    The amount of output token
     * @param _tokenA       The address of tokenA
     * @param _tokenB       The address of tokenB
     *
     * @return              The min amount of tokenA required across both exchanges
     * @return              The Exchange on which minimum amount of tokenA is required
     * @return              The pair address of the uniswap/sushiswap pool containing _tokenA and _tokenB
     */
    function _getMinTokenForExactToken(uint256 _amountOut, address _tokenA, address _tokenB) internal view returns (uint256, Exchange, address) {
        if (_tokenA == _tokenB) {
            return (_amountOut, Exchange.None, ETH_ADDRESS);
        }

        uint256 maxIn = PreciseUnitMath.maxUint256() ;
        uint256 uniTokenIn = maxIn;
        uint256 sushiTokenIn = maxIn;

        address uniswapPair = _getPair(uniFactory, _tokenA, _tokenB);
        if (uniswapPair != address(0)) {
            (uint256 reserveIn, uint256 reserveOut) = UniSushiV2Library.getReserves(uniswapPair, _tokenA, _tokenB);
            // Prevent subtraction overflow by making sure pool reserves are greater than swap amount
            if (reserveOut > _amountOut) {
                uniTokenIn = UniSushiV2Library.getAmountIn(_amountOut, reserveIn, reserveOut);
            }
        }

        address sushiswapPair = _getPair(sushiFactory, _tokenA, _tokenB);
        if (sushiswapPair != address(0)) {
            (uint256 reserveIn, uint256 reserveOut) = UniSushiV2Library.getReserves(sushiswapPair, _tokenA, _tokenB);
            // Prevent subtraction overflow by making sure pool reserves are greater than swap amount
            if (reserveOut > _amountOut) {
                sushiTokenIn = UniSushiV2Library.getAmountIn(_amountOut, reserveIn, reserveOut);
            }
        }

        // Fails if both the values are maxIn
        require(!(uniTokenIn == maxIn && sushiTokenIn == maxIn), "ExchangeIssuance: ILLIQUID_SET_COMPONENT");
        return (uniTokenIn <= sushiTokenIn) ? (uniTokenIn, Exchange.Uniswap, uniswapPair) : (sushiTokenIn, Exchange.Sushiswap, sushiswapPair);
    }

    /**
     * Compares the amount of token received for an exact amount of another token across both exchanges,
     * and returns the max amount.
     *
     * @param _amountIn     The amount of input token
     * @param _tokenA       The address of tokenA
     * @param _tokenB       The address of tokenB
     *
     * @return              The max amount of tokens that can be received across both exchanges
     * @return              The Exchange on which maximum amount of token can be received
     * @return              The pair address of the uniswap/sushiswap pool containing _tokenA and _tokenB
     */
    function _getMaxTokenForExactToken(uint256 _amountIn, address _tokenA, address _tokenB) internal view returns (uint256, Exchange, address) {
        if (_tokenA == _tokenB) {
            return (_amountIn, Exchange.None, ETH_ADDRESS);
        }

        uint256 uniTokenOut = 0;
        uint256 sushiTokenOut = 0;

        address uniswapPair = _getPair(uniFactory, _tokenA, _tokenB);
        if(uniswapPair != address(0)) {
            (uint256 reserveIn, uint256 reserveOut) = UniSushiV2Library.getReserves(uniswapPair, _tokenA, _tokenB);
            uniTokenOut = UniSushiV2Library.getAmountOut(_amountIn, reserveIn, reserveOut);
        }

        address sushiswapPair = _getPair(sushiFactory, _tokenA, _tokenB);
        if(sushiswapPair != address(0)) {
            (uint256 reserveIn, uint256 reserveOut) = UniSushiV2Library.getReserves(sushiswapPair, _tokenA, _tokenB);
            sushiTokenOut = UniSushiV2Library.getAmountOut(_amountIn, reserveIn, reserveOut);
        }

        // Fails if both the values are 0
        require(!(uniTokenOut == 0 && sushiTokenOut == 0), "ExchangeIssuance: ILLIQUID_SET_COMPONENT");
        return (uniTokenOut >= sushiTokenOut) ? (uniTokenOut, Exchange.Uniswap, uniswapPair) : (sushiTokenOut, Exchange.Sushiswap, sushiswapPair);
    }

    /**
     * Returns the pair address for on a given DEX.
     *
     * @param _factory   The factory to address
     * @param _tokenA    The address of tokenA
     * @param _tokenB    The address of tokenB
     *
     * @return           The pair address (Note: address(0) is returned by default if the pair is not available on that DEX)
     */
    function _getPair(address _factory, address _tokenA, address _tokenB) internal view returns (address) {
        return IUniswapV2Factory(_factory).getPair(_tokenA, _tokenB);
    }

    /**
     * Returns the router address of a given exchange.
     *
     * @param _exchange     The Exchange whose router address is needed
     *
     * @return              IUniswapV2Router02 router of the given exchange
     */
     function _getRouter(Exchange _exchange) internal view returns(IUniswapV2Router02) {
         return (_exchange == Exchange.Uniswap) ? uniRouter : sushiRouter;
     }

}

/*
    Copyright 2021 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import { AddressArrayUtils } from "../lib/AddressArrayUtils.sol";
import { IExtension } from "../interfaces/IExtension.sol";
import { ISetToken } from "../interfaces/ISetToken.sol";
import { MutualUpgrade } from "../lib/MutualUpgrade.sol";


/**
 * @title BaseManagerV2
 * @author Set Protocol
 *
 * Smart contract manager that contains permissions and admin functionality. Implements IIP-64, supporting
 * a registry of protected modules that can only be upgraded with methodologist consent.
 */
contract BaseManagerV2 is MutualUpgrade {
    using Address for address;
    using AddressArrayUtils for address[];
    using SafeERC20 for IERC20;

    /* ============ Struct ========== */

    struct ProtectedModule {
        bool isProtected;                               // Flag set to true if module is protected
        address[] authorizedExtensionsList;             // List of Extensions authorized to call module
        mapping(address => bool) authorizedExtensions;  // Map of extensions authorized to call module
    }

    /* ============ Events ============ */

    event ExtensionAdded(
        address _extension
    );

    event ExtensionRemoved(
        address _extension
    );

    event MethodologistChanged(
        address _oldMethodologist,
        address _newMethodologist
    );

    event OperatorChanged(
        address _oldOperator,
        address _newOperator
    );

    event ExtensionAuthorized(
        address _module,
        address _extension
    );

    event ExtensionAuthorizationRevoked(
        address _module,
        address _extension
    );

    event ModuleProtected(
        address _module,
        address[] _extensions
    );

    event ModuleUnprotected(
        address _module
    );

    event ReplacedProtectedModule(
        address _oldModule,
        address _newModule,
        address[] _newExtensions
    );

    event EmergencyReplacedProtectedModule(
        address _module,
        address[] _extensions
    );

    event EmergencyRemovedProtectedModule(
        address _module
    );

    event EmergencyResolved();

    /* ============ Modifiers ============ */

    /**
     * Throws if the sender is not the SetToken operator
     */
    modifier onlyOperator() {
        require(msg.sender == operator, "Must be operator");
        _;
    }

    /**
     * Throws if the sender is not the SetToken methodologist
     */
    modifier onlyMethodologist() {
        require(msg.sender == methodologist, "Must be methodologist");
        _;
    }

    /**
     * Throws if the sender is not a listed extension
     */
    modifier onlyExtension() {
        require(isExtension[msg.sender], "Must be extension");
        _;
    }

    /**
     * Throws if contract is in an emergency state following a unilateral operator removal of a
     * protected module.
     */
    modifier upgradesPermitted() {
        require(emergencies == 0, "Upgrades paused by emergency");
        _;
    }

    /**
     * Throws if contract is *not* in an emergency state. Emergency replacement and resolution
     * can only happen in an emergency
     */
    modifier onlyEmergency() {
        require(emergencies > 0, "Not in emergency");
        _;
    }

    /* ============ State Variables ============ */

    // Instance of SetToken
    ISetToken public setToken;

    // Array of listed extensions
    address[] internal extensions;

    // Mapping to check if extension is added
    mapping(address => bool) public isExtension;

    // Address of operator which typically executes manager only functions on Set Protocol modules
    address public operator;

    // Address of methodologist which serves as providing methodology for the index
    address public methodologist;

    // Counter incremented when the operator "emergency removes" a protected module. Decremented
    // when methodologist executes an "emergency replacement". Operator can only add modules and
    // extensions when `emergencies` is zero. Emergencies can only be declared "over" by mutual agreement
    // between operator and methodologist or by the methodologist alone via `resolveEmergency`
    uint256 public emergencies;

    // Mapping of protected modules. These cannot be called or removed except by mutual upgrade.
    mapping(address => ProtectedModule) public protectedModules;

    // List of protected modules, for iteration. Used when checking that an extension removal
    // can happen without methodologist approval
    address[] public protectedModulesList;

    // Boolean set when methodologist authorizes initialization after contract deployment.
    // Must be true to call via `interactManager`.
    bool public initialized;

    /* ============ Constructor ============ */

    constructor(
        ISetToken _setToken,
        address _operator,
        address _methodologist
    )
        public
    {
        setToken = _setToken;
        operator = _operator;
        methodologist = _methodologist;
    }

    /* ============ External Functions ============ */

    /**
     * ONLY METHODOLOGIST : Called by the methodologist to enable contract. All `interactManager`
     * calls revert until this is invoked. Lets methodologist review and authorize initial protected
     * module settings.
     */
    function authorizeInitialization() external onlyMethodologist {
        require(!initialized, "Initialization authorized");
        initialized = true;
    }

    /**
     * MUTUAL UPGRADE: Update the SetToken manager address. Operator and Methodologist must each call
     * this function to execute the update.
     *
     * @param _newManager           New manager address
     */
    function setManager(address _newManager) external mutualUpgrade(operator, methodologist) {
        require(_newManager != address(0), "Zero address not valid");
        setToken.setManager(_newManager);
    }

    /**
     * OPERATOR ONLY: Add a new extension that the BaseManager can call.
     *
     * @param _extension           New extension to add
     */
    function addExtension(address _extension) external upgradesPermitted onlyOperator {
        require(!isExtension[_extension], "Extension already exists");
        require(address(IExtension(_extension).manager()) == address(this), "Extension manager invalid");

        _addExtension(_extension);
    }

    /**
     * OPERATOR ONLY: Remove an existing extension tracked by the BaseManager.
     *
     * @param _extension           Old extension to remove
     */
    function removeExtension(address _extension) external onlyOperator {
        require(isExtension[_extension], "Extension does not exist");
        require(!_isAuthorizedExtension(_extension), "Extension used by protected module");

        extensions.removeStorage(_extension);

        isExtension[_extension] = false;

        emit ExtensionRemoved(_extension);
    }

    /**
     * MUTUAL UPGRADE: Authorizes an extension for a protected module. Operator and Methodologist must
     * each call this function to execute the update. Adds extension to manager if not already present.
     *
     * @param _module           Module to authorize extension for
     * @param _extension          Extension to authorize for module
     */
    function authorizeExtension(address _module, address _extension)
        external
        mutualUpgrade(operator, methodologist)
    {
        require(protectedModules[_module].isProtected, "Module not protected");
        require(!protectedModules[_module].authorizedExtensions[_extension], "Extension already authorized");

        _authorizeExtension(_module, _extension);

        emit ExtensionAuthorized(_module, _extension);
    }

    /**
     * MUTUAL UPGRADE: Revokes extension authorization for a protected module. Operator and Methodologist
     * must each call this function to execute the update. In order to remove the extension completely
     * from the contract removeExtension must be called by the operator.
     *
     * @param _module           Module to revoke extension authorization for
     * @param _extension          Extension to revoke authorization of
     */
    function revokeExtensionAuthorization(address _module, address _extension)
        external
        mutualUpgrade(operator, methodologist)
    {
        require(protectedModules[_module].isProtected, "Module not protected");
        require(isExtension[_extension], "Extension does not exist");
        require(protectedModules[_module].authorizedExtensions[_extension], "Extension not authorized");

        protectedModules[_module].authorizedExtensions[_extension] = false;
        protectedModules[_module].authorizedExtensionsList.removeStorage(_extension);

        emit ExtensionAuthorizationRevoked(_module, _extension);
    }

    /**
     * ADAPTER ONLY: Interact with a module registered on the SetToken. Manager initialization must
     * have been authorized by methodologist. Extension making this call must be authorized
     * to call module if module is protected.
     *
     * @param _module           Module to interact with
     * @param _data             Byte data of function to call in module
     */
    function interactManager(address _module, bytes memory _data) external onlyExtension {
        require(initialized, "Manager not initialized");
        require(_module != address(setToken), "Extensions cannot call SetToken");
        require(_senderAuthorizedForModule(_module, msg.sender), "Extension not authorized for module");

        // Invoke call to module, assume value will always be 0
        _module.functionCallWithValue(_data, 0);
    }

    /**
     * OPERATOR ONLY: Transfers _tokens held by the manager to _destination. Can be used to
     * recover anything sent here accidentally. In BaseManagerV2, extensions should
     * be the only contracts designated as `feeRecipient` in fee modules.
     *
     * @param _token           ERC20 token to send
     * @param _destination     Address receiving the tokens
     * @param _amount          Quantity of tokens to send
     */
    function transferTokens(address _token, address _destination, uint256 _amount) external onlyExtension {
        IERC20(_token).safeTransfer(_destination, _amount);
    }

    /**
     * OPERATOR ONLY: Add a new module to the SetToken.
     *
     * @param _module           New module to add
     */
    function addModule(address _module) external upgradesPermitted onlyOperator {
        setToken.addModule(_module);
    }

    /**
     * OPERATOR ONLY: Remove a new module from the SetToken. Any extensions associated with this
     * module need to be removed in separate transactions via removeExtension.
     *
     * @param _module           Module to remove
     */
    function removeModule(address _module) external onlyOperator {
        require(!protectedModules[_module].isProtected, "Module protected");
        setToken.removeModule(_module);
    }

    /**
     * OPERATOR ONLY: Marks a currently protected module as unprotected and deletes its authorized
     * extension registries. Removes module from the SetToken. Increments the `emergencies` counter,
     * prohibiting any operator-only module or extension additions until `emergencyReplaceProtectedModule`
     * is executed or `resolveEmergency` is called by the methodologist.
     *
     * Called by operator when a module must be removed immediately for security reasons and it's unsafe
     * to wait for a `mutualUpgrade` process to play out.
     *
     * NOTE: If removing a fee module, you can ensure all fees are distributed by calling distribute
     * on the module's de-authorized fee extension after this call.
     *
     * @param _module           Module to remove
     */
    function emergencyRemoveProtectedModule(address _module) external onlyOperator {
        _unProtectModule(_module);
        setToken.removeModule(_module);
        emergencies += 1;

        emit EmergencyRemovedProtectedModule(_module);
    }

    /**
     * OPERATOR ONLY: Marks an existing module as protected and authorizes extensions for
     * it, adding them if necessary. Adds module to the protected modules list
     *
     * The operator uses this when they're adding new features and want to assure the methodologist
     * they won't be unilaterally changed in the future. Cannot be called during an emergency because
     * methodologist needs to explicitly approve protection arrangements under those conditions.
     *
     * NOTE: If adding a fee extension while protecting a fee module, it's important to set the
     * module `feeRecipient` to the new extension's address (ideally before this call).
     *
     * @param  _module          Module to protect
     * @param  _extensions        Array of extensions to authorize for protected module
     */
    function protectModule(address _module, address[] memory _extensions)
        external
        upgradesPermitted
        onlyOperator
    {
        require(setToken.getModules().contains(_module), "Module not added yet");
        _protectModule(_module, _extensions);

        emit ModuleProtected(_module, _extensions);
    }

    /**
     * METHODOLOGIST ONLY: Marks a currently protected module as unprotected and deletes its authorized
     * extension registries. Removes old module from the protected modules list.
     *
     * Called by the methodologist when they want to cede control over a protected module without triggering
     * an emergency (for example, to remove it because its dead).
     *
     * @param  _module          Module to revoke protections for
     */
    function unProtectModule(address _module) external onlyMethodologist {
        _unProtectModule(_module);

        emit ModuleUnprotected(_module);
    }

    /**
     * MUTUAL UPGRADE: Replaces a protected module. Operator and Methodologist must each call this
     * function to execute the update.
     *
     * > Marks a currently protected module as unprotected
     * > Deletes its authorized extension registries.
     * > Removes old module from SetToken.
     * > Adds new module to SetToken.
     * > Marks `_newModule` as protected and authorizes new extensions for it.
     *
     * Used when methodologists wants to guarantee that an existing protection arrangement is replaced
     * with a suitable substitute (ex: upgrading a StreamingFeeSplitExtension).
     *
     * NOTE: If replacing a fee module, it's necessary to set the module `feeRecipient` to be
     * the new fee extension address after this call. Any fees remaining in the old module's
     * de-authorized extensions can be distributed by calling `distribute()` on the old extension.
     *
     * @param _oldModule        Module to remove
     * @param _newModule        Module to add in place of removed module
     * @param _newExtensions      Extensions to authorize for new module
     */
    function replaceProtectedModule(address _oldModule, address _newModule, address[] memory _newExtensions)
        external
        mutualUpgrade(operator, methodologist)
    {
        _unProtectModule(_oldModule);

        setToken.removeModule(_oldModule);
        setToken.addModule(_newModule);

        _protectModule(_newModule, _newExtensions);

        emit ReplacedProtectedModule(_oldModule, _newModule, _newExtensions);
    }

    /**
     * MUTUAL UPGRADE & EMERGENCY ONLY: Replaces a module the operator has removed with
     * `emergencyRemoveProtectedModule`. Operator and Methodologist must each call this function to
     *  execute the update.
     *
     * > Adds new module to SetToken.
     * > Marks `_newModule` as protected and authorizes new extensions for it.
     * > Adds `_newModule` to protectedModules list.
     * > Decrements the emergencies counter,
     *
     * Used when methodologist wants to guarantee that a protection arrangement which was
     * removed in an emergency is replaced with a suitable substitute. Operator's ability to add modules
     * or extensions is restored after invoking this method (if this is the only emergency.)
     *
     * NOTE: If replacing a fee module, it's necessary to set the module `feeRecipient` to be
     * the new fee extension address after this call. Any fees remaining in the old module's
     * de-authorized extensions can be distributed by calling `accrueFeesAndDistribute` on the old extension.
     *
     * @param _module          Module to add in place of removed module
     * @param _extensions      Array of extensions to authorize for replacement module
     */
    function emergencyReplaceProtectedModule(
        address _module,
        address[] memory _extensions
    )
        external
        mutualUpgrade(operator, methodologist)
        onlyEmergency
    {
        setToken.addModule(_module);
        _protectModule(_module, _extensions);

        emergencies -= 1;

        emit EmergencyReplacedProtectedModule(_module, _extensions);
    }

    /**
     * METHODOLOGIST ONLY & EMERGENCY ONLY: Decrements the emergencies counter.
     *
     * Allows a methodologist to exit a state of emergency without replacing a protected module that
     * was removed. This could happen if the module has no viable substitute or operator and methodologist
     * agree that restoring normal operations is the best way forward.
     */
    function resolveEmergency() external onlyMethodologist onlyEmergency {
        emergencies -= 1;

        emit EmergencyResolved();
    }

    /**
     * METHODOLOGIST ONLY: Update the methodologist address
     *
     * @param _newMethodologist           New methodologist address
     */
    function setMethodologist(address _newMethodologist) external onlyMethodologist {
        emit MethodologistChanged(methodologist, _newMethodologist);

        methodologist = _newMethodologist;
    }

    /**
     * OPERATOR ONLY: Update the operator address
     *
     * @param _newOperator           New operator address
     */
    function setOperator(address _newOperator) external onlyOperator {
        emit OperatorChanged(operator, _newOperator);

        operator = _newOperator;
    }

    /* ============ External Getters ============ */

    function getExtensions() external view returns(address[] memory) {
        return extensions;
    }

    function getAuthorizedExtensions(address _module) external view returns (address[] memory) {
        return protectedModules[_module].authorizedExtensionsList;
    }

    function isAuthorizedExtension(address _module, address _extension) external view returns (bool) {
        return protectedModules[_module].authorizedExtensions[_extension];
    }

    function getProtectedModules() external view returns (address[] memory) {
        return protectedModulesList;
    }

    /* ============ Internal ============ */


    /**
     * Add a new extension that the BaseManager can call.
     */
    function _addExtension(address _extension) internal {
        extensions.push(_extension);

        isExtension[_extension] = true;

        emit ExtensionAdded(_extension);
    }

    /**
     * Marks a currently protected module as unprotected and deletes it from authorized extension
     * registries. Removes module from the SetToken.
     */
    function _unProtectModule(address _module) internal {
        require(protectedModules[_module].isProtected, "Module not protected");

        // Clear mapping and array entries in struct before deleting mapping entry
        for (uint256 i = 0; i < protectedModules[_module].authorizedExtensionsList.length; i++) {
            address extension = protectedModules[_module].authorizedExtensionsList[i];
            protectedModules[_module].authorizedExtensions[extension] = false;
        }

        delete protectedModules[_module];

        protectedModulesList.removeStorage(_module);
    }

    /**
     * Adds new module to SetToken. Marks `_newModule` as protected and authorizes
     * new extensions for it. Adds `_newModule` module to protectedModules list.
     */
    function _protectModule(address _module, address[] memory _extensions) internal {
        require(!protectedModules[_module].isProtected, "Module already protected");

        protectedModules[_module].isProtected = true;
        protectedModulesList.push(_module);

        for (uint i = 0; i < _extensions.length; i++) {
            _authorizeExtension(_module, _extensions[i]);
        }
    }

    /**
     * Adds extension if not already added and marks extension as authorized for module
     */
    function _authorizeExtension(address _module, address _extension) internal {
        if (!isExtension[_extension]) {
            _addExtension(_extension);
        }

        protectedModules[_module].authorizedExtensions[_extension] = true;
        protectedModules[_module].authorizedExtensionsList.push(_extension);
    }

    /**
     * Searches the extension mappings of each protected modules to determine if an extension
     * is authorized by any of them. Authorized extensions cannot be unilaterally removed by
     * the operator.
     */
    function _isAuthorizedExtension(address _extension) internal view returns (bool) {
        for (uint256 i = 0; i < protectedModulesList.length; i++) {
            if (protectedModules[protectedModulesList[i]].authorizedExtensions[_extension]) {
                return true;
            }
        }

        return false;
    }

    /**
     * Checks if `_sender` (an extension) is allowed to call a module (which may be protected)
     */
    function _senderAuthorizedForModule(address _module, address _sender) internal view returns (bool) {
        if (protectedModules[_module].isProtected) {
            return protectedModules[_module].authorizedExtensions[_sender];
        }

        return true;
    }
}

/*
    Copyright 2021 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import { IBaseManager } from "./IBaseManager.sol";

interface IExtension {
    function manager() external view returns (IBaseManager);
}

pragma solidity 0.6.10;

import { MutualUpgrade } from "../lib/MutualUpgrade.sol";


// Mock contract implementation of MutualUpgrade functions
contract MutualUpgradeMock is
    MutualUpgrade
{
    uint256 public testUint;
    address public owner;
    address public methodologist;

    constructor(address _owner, address _methodologist) public {
        owner = _owner;
        methodologist = _methodologist;
    }

    function testMutualUpgrade(
        uint256 _testUint
    )
        external
        mutualUpgrade(owner, methodologist)
    {
        testUint = _testUint;
    }
}

/*
    Copyright 2021 IndexCooperative

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { BaseExtension } from "../lib/BaseExtension.sol";
import { IBaseManager } from "../interfaces/IBaseManager.sol";
import { ISetToken } from "../interfaces/ISetToken.sol";
import { IStreamingFeeModule } from "../interfaces/IStreamingFeeModule.sol";
import { PreciseUnitMath } from "../lib/PreciseUnitMath.sol";
import { TimeLockUpgrade } from "../lib/TimeLockUpgrade.sol";
import { MutualUpgrade } from "../lib/MutualUpgrade.sol";


/**
 * @title StreamingFeeSplitExtension
 * @author Set Protocol
 *
 * Smart contract manager extension that allows for splitting and setting streaming fees. Fee splits are updated by operator.
 * Any fee updates are timelocked.
 */
contract StreamingFeeSplitExtension is BaseExtension, TimeLockUpgrade, MutualUpgrade {
    using Address for address;
    using PreciseUnitMath for uint256;
    using SafeMath for uint256;

    /* ============ Events ============ */

    event FeesDistributed(
        address indexed _operatorFeeRecipient,
        address indexed _methodologist,
        uint256 _operatorTake,
        uint256 _methodologistTake
    );

    /* ============ State Variables ============ */

    ISetToken public setToken;
    IStreamingFeeModule public streamingFeeModule;

    // Percent of fees in precise units (10^16 = 1%) sent to operator, rest to methodologist
    uint256 public operatorFeeSplit;

    // Address which receives operator's share of fees when they're distributed. (See IIP-72)
    address public operatorFeeRecipient;

    /* ============ Constructor ============ */

    constructor(
        IBaseManager _manager,
        IStreamingFeeModule _streamingFeeModule,
        uint256 _operatorFeeSplit,
        address _operatorFeeRecipient
    )
        public
        BaseExtension(_manager)
    {
        streamingFeeModule = _streamingFeeModule;
        operatorFeeSplit = _operatorFeeSplit;
        operatorFeeRecipient = _operatorFeeRecipient;
        setToken = manager.setToken();
    }

    /* ============ External Functions ============ */

    /**
     * ANYONE CALLABLE: Accrues fees from streaming fee module. Gets resulting balance after fee accrual,
     * calculates fees for operator and methodologist, and sends to operatorFeeRecipient and methodologist
     * respectively.
     */
    function accrueFeesAndDistribute() public {
        // Emits a FeeActualized event
        streamingFeeModule.accrueFee(setToken);

        uint256 totalFees = setToken.balanceOf(address(this));

        address methodologist = manager.methodologist();

        uint256 operatorTake = totalFees.preciseMul(operatorFeeSplit);
        uint256 methodologistTake = totalFees.sub(operatorTake);

        if (operatorTake > 0) {
            setToken.transfer(operatorFeeRecipient, operatorTake);
        }

        if (methodologistTake > 0) {
            setToken.transfer(methodologist, methodologistTake);
        }

        emit FeesDistributed(operatorFeeRecipient, methodologist, operatorTake, methodologistTake);
    }

    /**
     * MUTUAL UPGRADE: Initializes the streaming fee module. Operator and Methodologist must each call
     * this function to execute the update.
     *
     * This method is called after invoking `replaceProtectedModule` or `emergencyReplaceProtectedModule`
     * to configure the replacement streaming fee module's fee settings.
     *
     * @dev FeeState settings encode the following struct
     * ```
     * struct FeeState {
     *   address feeRecipient;                // Address to accrue fees to
     *   uint256 maxStreamingFeePercentage;   // Max streaming fee maanager commits to using (1% = 1e16, 100% = 1e18)
     *   uint256 streamingFeePercentage;      // Percent of Set accruing to manager annually (1% = 1e16, 100% = 1e18)
     *   uint256 lastStreamingFeeTimestamp;   // Timestamp last streaming fee was accrued
     *}
     *```
     * @param _settings     FeeModule.FeeState settings
     */
    function initializeModule(IStreamingFeeModule.FeeState memory _settings)
        external
        mutualUpgrade(manager.operator(), manager.methodologist())
    {
        bytes memory callData = abi.encodeWithSelector(
            IStreamingFeeModule.initialize.selector,
            manager.setToken(),
            _settings
        );

        invokeManager(address(streamingFeeModule), callData);
    }

    /**
     * MUTUAL UPGRADE: Updates streaming fee on StreamingFeeModule. Operator and Methodologist must
     * each call this function to execute the update. Because the method is timelocked, each party
     * must call it twice: once to set the lock and once to execute.
     *
     * Method is timelocked to protect token owners from sudden changes in fee structure which
     * they would rather not bear. The delay gives them a chance to exit their positions without penalty.
     *
     * NOTE: This will accrue streaming fees though not send to operator fee recipient and methodologist.
     *
     * @param _newFee       Percent of Set accruing to fee extension annually (1% = 1e16, 100% = 1e18)
     */
    function updateStreamingFee(uint256 _newFee)
        external
        mutualUpgrade(manager.operator(), manager.methodologist())
        timeLockUpgrade
    {
        bytes memory callData = abi.encodeWithSelector(
            IStreamingFeeModule.updateStreamingFee.selector,
            manager.setToken(),
            _newFee
        );

        invokeManager(address(streamingFeeModule), callData);
    }

    /**
     * MUTUAL UPGRADE: Updates fee recipient on streaming fee module.
     *
     * @param _newFeeRecipient  Address of new fee recipient. This should be the address of the fee extension itself.
     */
    function updateFeeRecipient(address _newFeeRecipient)
        external
        mutualUpgrade(manager.operator(), manager.methodologist())
    {
        bytes memory callData = abi.encodeWithSelector(
            IStreamingFeeModule.updateFeeRecipient.selector,
            manager.setToken(),
            _newFeeRecipient
        );

        invokeManager(address(streamingFeeModule), callData);
    }

    /**
     * MUTUAL UPGRADE: Updates fee split between operator and methodologist. Split defined in precise units (1% = 10^16).
     * Fees will be accrued and distributed before the new split goes into effect.
     *
     * @param _newFeeSplit      Percent of fees in precise units (10^16 = 1%) sent to operator, (rest go to the methodologist).
     */
    function updateFeeSplit(uint256 _newFeeSplit)
        external
        mutualUpgrade(manager.operator(), manager.methodologist())
    {
        require(_newFeeSplit <= PreciseUnitMath.preciseUnit(), "Fee must be less than 100%");
        accrueFeesAndDistribute();
        operatorFeeSplit = _newFeeSplit;
    }

    /**
     * OPERATOR ONLY: Updates the address that receives the operator's share of the fees (see IIP-72)
     *
     * @param _newOperatorFeeRecipient  Address to send operator's fees to.
     */
    function updateOperatorFeeRecipient(address _newOperatorFeeRecipient)
        external
        onlyOperator
    {
        require(_newOperatorFeeRecipient != address(0), "Zero address not valid");
        operatorFeeRecipient = _newOperatorFeeRecipient;
    }
}

/*
    Copyright 2021 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { IManagerIssuanceHook } from "../interfaces/IManagerIssuanceHook.sol";
import { ISetToken } from "../interfaces/ISetToken.sol";


/**
 * @title SupplyCapIssuanceHook
 * @author Set Protocol
 *
 * Issuance hook that checks new issuances won't push SetToken totalSupply over supply cap.
 */
contract SupplyCapIssuanceHook is Ownable, IManagerIssuanceHook {
    using SafeMath for uint256;

    /* ============ Events ============ */

    event SupplyCapUpdated(uint256 _newCap);
    
    /* ============ State Variables ============ */

    // Cap on totalSupply of Sets
    uint256 public supplyCap;

    /* ============ Constructor ============ */

    /**
     * Constructor, overwrites owner and original supply cap.
     *
     * @param _initialOwner     Owner address, overwrites Ownable logic which sets to deployer as default
     * @param _supplyCap        Supply cap for Set (in wei of Set)
     */
    constructor(
        address _initialOwner,
        uint256 _supplyCap
    )
        public
    {
        supplyCap = _supplyCap;

        // Overwrite _owner param of Ownable contract
        transferOwnership(_initialOwner);
    }

    /**
     * Adheres to IManagerIssuanceHook interface, and checks to make sure the current issue call won't push total supply over cap.
     */
    function invokePreIssueHook(
        ISetToken _setToken,
        uint256 _issueQuantity,
        address /*_sender*/,
        address /*_to*/
    )
        external
        override
    {
        uint256 totalSupply = _setToken.totalSupply();

        require(totalSupply.add(_issueQuantity) <= supplyCap, "Supply cap exceeded");
    }

    /**
     * Adheres to IManagerIssuanceHook interface
     */
    function invokePreRedeemHook(
        ISetToken _setToken,
        uint256 _redeemQuantity,
        address _sender,
        address _to
    )
        external
        override
    {}

    /**
     * ONLY OWNER: Updates supply cap
     */
    function updateSupplyCap(uint256 _newCap) external onlyOwner {
        supplyCap = _newCap;
        SupplyCapUpdated(_newCap);
    }
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;

import { ISetToken } from "./ISetToken.sol";

interface IManagerIssuanceHook {
    function invokePreIssueHook(ISetToken _setToken, uint256 _issueQuantity, address _sender, address _to) external;
    function invokePreRedeemHook(ISetToken _setToken, uint256 _redeemQuantity, address _sender, address _to) external;
}

/*
    Copyright 2021 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { AddressArrayUtils } from "../lib/AddressArrayUtils.sol";

import { IManagerIssuanceHook } from "../interfaces/IManagerIssuanceHook.sol";
import { ISetToken } from "../interfaces/ISetToken.sol";


/**
 * @title SupplyCapAllowedCallerIssuanceHook
 * @author Set Protocol
 *
 * Issuance hook that checks
 * 1) New issuances won't push SetToken totalSupply over supply cap
 * 2) A contract address is allowed to call the module. This does not apply if caller is an EOA
 */
contract SupplyCapAllowedCallerIssuanceHook is Ownable, IManagerIssuanceHook {
    using SafeMath for uint256;
    using AddressArrayUtils for address[];

    /* ============ Events ============ */

    event SupplyCapUpdated(uint256 _newCap);
    event CallerStatusUpdated(address indexed _caller, bool _status);
    event AnyoneCallableUpdated(bool indexed _status);
    
    /* ============ State Variables ============ */

    // Cap on totalSupply of Sets
    uint256 public supplyCap;

    // Boolean indicating if anyone can call function
    bool public anyoneCallable;

    // Mapping of contract addresses allowed to call function
    mapping(address => bool) public callAllowList;

    /* ============ Constructor ============ */

    /**
     * Constructor, overwrites owner and original supply cap.
     *
     * @param _initialOwner      Owner address, overwrites Ownable logic which sets to deployer as default
     * @param _supplyCap         Supply cap for Set (in wei of Set)
     */
    constructor(
        address _initialOwner,
        uint256 _supplyCap
    )
        public
    {
        supplyCap = _supplyCap;

        // Overwrite _owner param of Ownable contract
        transferOwnership(_initialOwner);
    }

    /* ============ External Functions ============ */

    /**
     * Adheres to IManagerIssuanceHook interface, and checks to make sure the current issue call won't push total supply over cap.
     */
    function invokePreIssueHook(
        ISetToken _setToken,
        uint256 _issueQuantity,
        address _sender,
        address /*_to*/
    )
        external
        override
    {
        _validateAllowedContractCaller(_sender);
        
        uint256 totalSupply = _setToken.totalSupply();
        require(totalSupply.add(_issueQuantity) <= supplyCap, "Supply cap exceeded");
    }

    /**
     * Adheres to IManagerIssuanceHook interface
     */
    function invokePreRedeemHook(
        ISetToken _setToken,
        uint256 _redeemQuantity,
        address _sender,
        address _to
    )
        external
        override
    {}

    /**
     * ONLY OWNER: Updates supply cap
     */
    function updateSupplyCap(uint256 _newCap) external onlyOwner {
        supplyCap = _newCap;
        SupplyCapUpdated(_newCap);
    }

    /**
     * ONLY OWNER: Toggle ability for passed addresses to call only allowed caller functions
     *
     * @param _callers           Array of caller addresses to toggle status
     * @param _statuses          Array of statuses for each caller
     */
    function updateCallerStatus(address[] calldata _callers, bool[] calldata _statuses) external onlyOwner {
        _callers.validatePairsWithArray(_statuses);

        for (uint256 i = 0; i < _callers.length; i++) {
            address caller = _callers[i];
            bool status = _statuses[i];
            callAllowList[caller] = status;
            emit CallerStatusUpdated(caller, status);
        }
    }

    /**
     * ONLY OWNER: Toggle whether anyone can call function, bypassing the callAllowlist 
     *
     * @param _status           Boolean indicating whether to allow anyone call
     */
    function updateAnyoneCallable(bool _status) external onlyOwner {
        anyoneCallable = _status;
        emit AnyoneCallableUpdated(_status);
    }

    /* ============ Internal Functions ============ */

    /**
     * Validate if passed address is allowed to call function. If anyoneCallable is set to true, anyone can call otherwise needs to be an EOA or 
     * approved contract address.
     */
    function _validateAllowedContractCaller(address _caller) internal view {
        require(
            _caller == tx.origin || anyoneCallable || callAllowList[_caller],
            "Contract not permitted to call"
        );
    }
}

/*
    Copyright 2021 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.6.10;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { AddressArrayUtils } from "../lib/AddressArrayUtils.sol";
import { IAdapter } from "../interfaces/IAdapter.sol";
import { ISetToken } from "../interfaces/ISetToken.sol";


/**
 * @title BaseManager
 * @author Set Protocol
 *
 * Smart contract manager that contains permissions and admin functionality
 */
contract BaseManager {
    using Address for address;
    using AddressArrayUtils for address[];

    /* ============ Events ============ */

    event AdapterAdded(
        address _adapter
    );

    event AdapterRemoved(
        address _adapter
    );

    event MethodologistChanged(
        address _oldMethodologist,
        address _newMethodologist
    );

    event OperatorChanged(
        address _oldOperator,
        address _newOperator
    );

    /* ============ Modifiers ============ */

    /**
     * Throws if the sender is not the SetToken operator
     */
    modifier onlyOperator() {
        require(msg.sender == operator, "Must be operator");
        _;
    }

    /**
     * Throws if the sender is not the SetToken methodologist
     */
    modifier onlyMethodologist() {
        require(msg.sender == methodologist, "Must be methodologist");
        _;
    }

    /**
     * Throws if the sender is not a listed adapter
     */
    modifier onlyAdapter() {
        require(isAdapter[msg.sender], "Must be adapter");
        _;
    }

    /* ============ State Variables ============ */

    // Instance of SetToken
    ISetToken public setToken;

    // Array of listed adapters
    address[] internal adapters;

    // Mapping to check if adapter is added
    mapping(address => bool) public isAdapter;

    // Address of operator which typically executes manager only functions on Set Protocol modules
    address public operator;

    // Address of methodologist which serves as providing methodology for the index
    address public methodologist;

    /* ============ Constructor ============ */

    constructor(
        ISetToken _setToken,
        address _operator,
        address _methodologist
    )
        public
    {
        setToken = _setToken;
        operator = _operator;
        methodologist = _methodologist;
    }

    /* ============ External Functions ============ */

    /**
     * MUTUAL UPGRADE: Update the SetToken manager address. Operator and Methodologist must each call
     * this function to execute the update.
     *
     * @param _newManager           New manager address
     */
    function setManager(address _newManager) external onlyOperator {
        require(_newManager != address(0), "Zero address not valid");
        setToken.setManager(_newManager);
    }

    /**
     * MUTUAL UPGRADE: Add a new adapter that the BaseManager can call.
     *
     * @param _adapter           New adapter to add
     */
    function addAdapter(address _adapter) external onlyOperator {
        require(!isAdapter[_adapter], "Adapter already exists");
        require(address(IAdapter(_adapter).manager()) == address(this), "Adapter manager invalid");

        adapters.push(_adapter);

        isAdapter[_adapter] = true;

        emit AdapterAdded(_adapter);
    }

    /**
     * MUTUAL UPGRADE: Remove an existing adapter tracked by the BaseManager.
     *
     * @param _adapter           Old adapter to remove
     */
    function removeAdapter(address _adapter) external onlyOperator {
        require(isAdapter[_adapter], "Adapter does not exist");

        adapters.removeStorage(_adapter);

        isAdapter[_adapter] = false;

        emit AdapterRemoved(_adapter);
    }

    /**
     * ADAPTER ONLY: Interact with a module registered on the SetToken.
     *
     * @param _module           Module to interact with
     * @param _data             Byte data of function to call in module
     */
    function interactManager(address _module, bytes calldata _data) external onlyAdapter {
        // Invoke call to module, assume value will always be 0
        _module.functionCallWithValue(_data, 0);
    }

    /**
     * OPERATOR ONLY: Add a new module to the SetToken.
     *
     * @param _module           New module to add
     */
    function addModule(address _module) external onlyOperator {
        setToken.addModule(_module);
    }

    /**
     * OPERATOR ONLY: Remove a new module from the SetToken.
     *
     * @param _module           Module to remove
     */
    function removeModule(address _module) external onlyOperator {
        setToken.removeModule(_module);
    }

    /**
     * METHODOLOGIST ONLY: Update the methodologist address
     *
     * @param _newMethodologist           New methodologist address
     */
    function setMethodologist(address _newMethodologist) external onlyMethodologist {
        emit MethodologistChanged(methodologist, _newMethodologist);

        methodologist = _newMethodologist;
    }

    /**
     * OPERATOR ONLY: Update the operator address
     *
     * @param _newOperator           New operator address
     */
    function setOperator(address _newOperator) external onlyOperator {
        emit OperatorChanged(operator, _newOperator);

        operator = _newOperator;
    }

    /* ============ External Getters ============ */

    function getAdapters() external view returns(address[] memory) {
        return adapters;
    }
}

/*
    Copyright 2021 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import { IBaseManager } from "./IBaseManager.sol";

interface IAdapter {
    function manager() external view returns (IBaseManager);
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;

import { BaseExtension } from "../lib/BaseExtension.sol";
import { IBaseManager } from "../interfaces/IBaseManager.sol";

contract BaseExtensionMock is BaseExtension {

    constructor(IBaseManager _manager) public BaseExtension(_manager) {}

    /* ============ External Functions ============ */

    function testInvokeManagerTransfer(address _token, address _destination, uint256 _amount) external {
        invokeManagerTransfer(_token, _destination, _amount);
    }

    function testInvokeManager(address _module, bytes calldata _encoded) external {
        invokeManager(_module, _encoded);
    }

    function testOnlyOperator()
        external
        onlyOperator
    {}

    function testOnlyMethodologist()
        external
        onlyMethodologist
    {}

    function testOnlyEOA()
        external
        onlyEOA
    {}

    function testOnlyAllowedCaller(address _caller)
        external
        onlyAllowedCaller(_caller)
    {}

    function interactManager(address _target, bytes calldata _data) external {
        invokeManager(_target, _data);
    }
}

/*
    Copyright 2021 IndexCooperative

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.6.10;

import { BaseExtension } from "../lib/BaseExtension.sol";
import { IBaseManager } from "../interfaces/IBaseManager.sol";
import { IGovernanceModule } from "../interfaces/IGovernanceModule.sol";
import { ISetToken } from "../interfaces/ISetToken.sol";

/**
 * @title GovernanceExtension
 * @author Set Protocol
 *
 * Smart contract extension that acts as a manager interface for interacting with the Set Protocol
 * GovernanceModule to perform meta-governance actions. All governance functions are callable only
 * by a subset of allowed callers. The operator has the power to add/remove callers from the allowed
 * callers mapping.
 */
contract GovernanceExtension is BaseExtension {

    /* ============ State Variables ============ */

    ISetToken public setToken;
    IGovernanceModule public governanceModule;

    /* ============ Constructor ============ */

    constructor(IBaseManager _manager, IGovernanceModule _governanceModule) public BaseExtension(_manager) {
        governanceModule = _governanceModule;
        setToken = manager.setToken();
    }

    /* ============ External Functions ============ */

    /**
     * ONLY APPROVED CALLER: Submits a delegate call to the GovernanceModule. Approved caller mapping
     * is part of BaseExtension.
     *
     * @param _governanceName       Name of governance extension being used
     */
    function delegate(
        string memory _governanceName,
        address _delegatee
    )
        external
        onlyAllowedCaller(msg.sender)
    {
        bytes memory callData = abi.encodeWithSelector(
            IGovernanceModule.delegate.selector,
            setToken,
            _governanceName,
            _delegatee
        );

        invokeManager(address(governanceModule), callData);
    }

    /**
     * ONLY APPROVED CALLER: Submits a proposal call to the GovernanceModule. Approved caller mapping
     * is part of BaseExtension.
     *
     * @param _governanceName       Name of governance extension being used
     * @param _proposalData         Byte data of proposal
     */
    function propose(
        string memory _governanceName,
        bytes memory _proposalData
    )
        external
        onlyAllowedCaller(msg.sender)
    {
        bytes memory callData = abi.encodeWithSelector(
            IGovernanceModule.propose.selector,
            setToken,
            _governanceName,
            _proposalData
        );

        invokeManager(address(governanceModule), callData);
    }

    /**
     * ONLY APPROVED CALLER: Submits a register call to the GovernanceModule. Approved caller mapping
     * is part of BaseExtension.
     *
     * @param _governanceName       Name of governance extension being used
     */
    function register(string memory _governanceName) external onlyAllowedCaller(msg.sender) {
        bytes memory callData = abi.encodeWithSelector(
            IGovernanceModule.register.selector,
            setToken,
            _governanceName
        );

        invokeManager(address(governanceModule), callData);
    }

    /**
     * ONLY APPROVED CALLER: Submits a revoke call to the GovernanceModule. Approved caller mapping
     * is part of BaseExtension.
     *
     * @param _governanceName       Name of governance extension being used
     */
    function revoke(string memory _governanceName) external onlyAllowedCaller(msg.sender) {
        bytes memory callData = abi.encodeWithSelector(
            IGovernanceModule.revoke.selector,
            setToken,
            _governanceName
        );

        invokeManager(address(governanceModule), callData);
    }

    /**
     * ONLY APPROVED CALLER: Submits a vote call to the GovernanceModule. Approved caller mapping
     * is part of BaseExtension.
     *
     * @param _governanceName       Name of governance extension being used
     * @param _proposalId           Id of proposal being voted on
     * @param _support              Boolean indicating if supporting proposal
     * @param _data                 Arbitrary bytes to be used to construct vote call data
     */
    function vote(
        string memory _governanceName,
        uint256 _proposalId,
        bool _support,
        bytes memory _data
    )
        external
        onlyAllowedCaller(msg.sender)
    {
        bytes memory callData = abi.encodeWithSelector(
            IGovernanceModule.vote.selector,
            setToken,
            _governanceName,
            _proposalId,
            _support,
            _data
        );

        invokeManager(address(governanceModule), callData);
    }

    /**
     * ONLY OPERATOR: Initialize GovernanceModule for Set
     */
    function initialize() external onlyOperator {
        bytes memory callData = abi.encodeWithSelector(
            IGovernanceModule.initialize.selector,
            setToken
        );

        invokeManager(address(governanceModule), callData);
    }
}

/*
    Copyright 2020 Set Labs Inc.
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;

import { ISetToken } from "./ISetToken.sol";

interface IGovernanceModule {
    function delegate(ISetToken _setToken, string memory _governanceName, address _delegatee) external;
    function propose(ISetToken _setToken, string memory _governanceName, bytes memory _proposalData) external;
    function register(ISetToken _setToken, string memory _governanceName) external;
    function revoke(ISetToken _setToken, string memory _governanceName) external;
    function vote(
        ISetToken _setToken,
        string memory _governanceName,
        uint256 _proposalId,
        bool _support,
        bytes memory _data
    )
        external;
    function initialize(ISetToken _setToken) external;
}

/*
    Copyright 2021 IndexCooperative

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { AddressArrayUtils } from "../lib/AddressArrayUtils.sol";
import { BaseExtension } from "../lib/BaseExtension.sol";
import { IBaseManager } from "../interfaces/IBaseManager.sol";
import { IGeneralIndexModule } from "../interfaces/IGeneralIndexModule.sol";
import { ISetToken } from "../interfaces/ISetToken.sol";

/**
 * @title GIMExtension
 * @author Set Protocol
 *
 * Smart contract manager extension that acts as a pass-through contract for interacting with GeneralIndexModule.
 * All functions are only callable by operator. startRebalance() on GIM maps to startRebalanceWithUnits on
 * GIMExtension.
 */
contract GIMExtension is BaseExtension {

    using AddressArrayUtils for address[];
    using SafeMath for uint256;

    /* ============ State Variables ============ */

    ISetToken public setToken;
    IGeneralIndexModule public generalIndexModule;  // GIM

    /* ============ Constructor ============ */

    constructor(IBaseManager _manager, IGeneralIndexModule _generalIndexModule) public BaseExtension(_manager) {
        generalIndexModule = _generalIndexModule;
        setToken = manager.setToken();
    }

    /* ============ External Functions ============ */

    /**
     * ONLY OPERATOR: Submits a startRebalance call to GeneralIndexModule. Uses internal function so that this contract can be inherited and
     * custom startRebalance logic can be added on top. Components array is sorted in new and old components arrays in order to conform to
     * startRebalance interface. See GIM for function specific restrictions.
     * @param _components               Array of components involved in rebalance inclusive of components being removed from set (targetUnit = 0)
     * @param _targetUnits              Array of target units at end of rebalance, maps to same index of _components array
     * @param _positionMultiplier       Position multiplier when target units were calculated, needed in order to adjust target units if fees accrued
     */
    function startRebalanceWithUnits(
        address[] calldata _components,
        uint256[] calldata _targetUnits,
        uint256 _positionMultiplier
    )
        external
        onlyOperator
    {
        (
            address[] memory newComponents,
            uint256[] memory newComponentsTargetUnits,
            uint256[] memory oldComponentsTargetUnits
        ) = _sortNewAndOldComponents(_components, _targetUnits);
        _startRebalance(newComponents, newComponentsTargetUnits, oldComponentsTargetUnits, _positionMultiplier);
    }

    /**
     * ONLY OPERATOR: Submits a setTradeMaximums call to GeneralIndexModule. See GIM for function specific restrictions.
     *
     * @param _components           Array of components
     * @param _tradeMaximums        Array of trade maximums mapping to correct component
     */
    function setTradeMaximums(
        address[] memory _components,
        uint256[] memory _tradeMaximums
    )
        external
        onlyOperator
    {
        bytes memory callData = abi.encodeWithSelector(
            IGeneralIndexModule.setTradeMaximums.selector,
            setToken,
            _components,
            _tradeMaximums
        );

        invokeManager(address(generalIndexModule), callData);
    }

    /**
     * ONLY OPERATOR: Submits a setExchanges call to GeneralIndexModule. See GIM for function specific restrictions.
     *
     * @param _components           Array of components
     * @param _exchangeNames        Array of exchange names mapping to correct component
     */
    function setExchanges(
        address[] memory _components,
        string[] memory _exchangeNames
    )
        external
        onlyOperator
    {
        bytes memory callData = abi.encodeWithSelector(
            IGeneralIndexModule.setExchanges.selector,
            setToken,
            _components,
            _exchangeNames
        );

        invokeManager(address(generalIndexModule), callData);
    }

    /**
     * ONLY OPERATOR: Submits a setCoolOffPeriods call to GeneralIndexModule. See GIM for function specific restrictions.
     *
     * @param _components           Array of components
     * @param _coolOffPeriods       Array of cool off periods to correct component
     */
    function setCoolOffPeriods(
        address[] memory _components,
        uint256[] memory _coolOffPeriods
    )
        external
        onlyOperator
    {
        bytes memory callData = abi.encodeWithSelector(
            IGeneralIndexModule.setCoolOffPeriods.selector,
            setToken,
            _components,
            _coolOffPeriods
        );

        invokeManager(address(generalIndexModule), callData);
    }

    /**
     * ONLY OPERATOR: Submits a setExchangeData call to GeneralIndexModule. See GIM for function specific restrictions.
     *
     * @param _components           Array of components
     * @param _exchangeData         Array of exchange specific arbitrary bytes data
     */
    function setExchangeData(
        address[] memory _components,
        bytes[] memory _exchangeData
    )
        external
        onlyOperator
    {
        bytes memory callData = abi.encodeWithSelector(
            IGeneralIndexModule.setExchangeData.selector,
            setToken,
            _components,
            _exchangeData
        );

        invokeManager(address(generalIndexModule), callData);
    }

    /**
     * ONLY OPERATOR: Submits a setRaiseTargetPercentage call to GeneralIndexModule. See GIM for function specific restrictions.
     *
     * @param _raiseTargetPercentage        Amount to raise all component's unit targets by (in precise units)
     */
    function setRaiseTargetPercentage(uint256 _raiseTargetPercentage) external onlyOperator {
        bytes memory callData = abi.encodeWithSelector(
            IGeneralIndexModule.setRaiseTargetPercentage.selector,
            setToken,
            _raiseTargetPercentage
        );

        invokeManager(address(generalIndexModule), callData);
    }

    /**
     * ONLY OPERATOR: Submits a setTraderStatus call to GeneralIndexModule. See GIM for function specific restrictions.
     *
     * @param _traders           Array trader addresses to toggle status
     * @param _statuses          Booleans indicating if matching trader can trade
     */
    function setTraderStatus(
        address[] memory _traders,
        bool[] memory _statuses
    )
        external
        onlyOperator
    {
        bytes memory callData = abi.encodeWithSelector(
            IGeneralIndexModule.setTraderStatus.selector,
            setToken,
            _traders,
            _statuses
        );

        invokeManager(address(generalIndexModule), callData);
    }

    /**
     * ONLY OPERATOR: Submits a setAnyoneTrade call to GeneralIndexModule. See GIM for function specific restrictions.
     *
     * @param _status          Boolean indicating if anyone can call trade
     */
    function setAnyoneTrade(bool _status) external onlyOperator {
        bytes memory callData = abi.encodeWithSelector(
            IGeneralIndexModule.setAnyoneTrade.selector,
            setToken,
            _status
        );

        invokeManager(address(generalIndexModule), callData);
    }

    /**
     * ONLY OPERATOR: Submits a initialize call to GeneralIndexModule. See GIM for function specific restrictions.
     */
    function initialize() external onlyOperator {
        bytes memory callData = abi.encodeWithSelector(
            IGeneralIndexModule.initialize.selector,
            setToken
        );

        invokeManager(address(generalIndexModule), callData);
    }

    /* ============ Internal Functions ============ */

    /**
     * Internal function that creates calldata and submits startRebalance call to GeneralIndexModule.
     *
     * @param _newComponents                    Array of new components to add to allocation
     * @param _newComponentsTargetUnits         Array of target units at end of rebalance for new components, maps to same index of _newComponents array
     * @param _oldComponentsTargetUnits         Array of target units at end of rebalance for old component, maps to same index of
     *                                               _setToken.getComponents() array, if component being removed set to 0.
     * @param _positionMultiplier               Position multiplier when target units were calculated, needed in order to adjust target units
     *                                               if fees accrued
     */
    function _startRebalance(
        address[] memory _newComponents,
        uint256[] memory _newComponentsTargetUnits,
        uint256[] memory _oldComponentsTargetUnits,
        uint256 _positionMultiplier
    )
        internal
    {
        bytes memory callData = abi.encodeWithSelector(
            IGeneralIndexModule.startRebalance.selector,
            setToken,
            _newComponents,
            _newComponentsTargetUnits,
            _oldComponentsTargetUnits,
            _positionMultiplier
        );

        invokeManager(address(generalIndexModule), callData);
    }

    /**
     * Internal function that sorts components into old and new components and builds the requisite target unit arrays. Old components target units
     * MUST maintain the order of the components array on the SetToken. The _components array MUST contain an entry for all current components even if
     * component is being removed (targetUnit = 0). This is validated implicitly by calculating the amount of new components that would be added as
     * implied by the array lengths, if more than the expected amount of new components are added then it implies an old component is missing.
     *
     * @param _components          Array of components involved in rebalance inclusive of components being removed from set (targetUnit = 0)
     * @param _targetUnits         Array of target units at end of rebalance, maps to same index of _components array
     */
    function _sortNewAndOldComponents(
        address[] memory _components,
        uint256[] memory _targetUnits
    )
        internal
        view
        returns (address[] memory, uint256[] memory, uint256[] memory)
    {
        address[] memory currentComponents = setToken.getComponents();

        uint256 currentSetComponentsLength = currentComponents.length;
        uint256 rebalanceComponentsLength = _components.length;

        require(rebalanceComponentsLength >= currentSetComponentsLength, "Components array must be equal or longer than current components");

        // We assume that there is an entry for each old component regardless of if it's 0, so any additional components in the array
        // must be added as a new component. Hence we can declare the length of the new components array as the difference between
        // rebalanceComponentsLength and currentSetComponentsLength
        uint256[] memory oldComponentsTargetUnits = new uint256[](currentSetComponentsLength);
        address[] memory newComponents = new address[](rebalanceComponentsLength.sub(currentSetComponentsLength));
        uint256[] memory newTargetUnits = new uint256[](rebalanceComponentsLength.sub(currentSetComponentsLength));

        uint256 newCounter;     // Count amount of components added to newComponents array to add new components to next index
        for (uint256 i = 0; i < rebalanceComponentsLength; i++) {
            address component = _components[i];
            (uint256 index, bool isIn) = currentComponents.indexOf(component);

            if (isIn) {
                oldComponentsTargetUnits[index] = _targetUnits[i];  // Use index in order to map to correct component in currentComponents array
            } else {
                require(newCounter < newComponents.length, "Unexpected new component added");
                newComponents[newCounter] = component;
                newTargetUnits[newCounter] = _targetUnits[i];
                newCounter = newCounter.add(1);
            }
        }

        return (newComponents, newTargetUnits, oldComponentsTargetUnits);
    }
}

/*
    Copyright 2020 Set Labs Inc.
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISetToken } from "./ISetToken.sol";

interface IGeneralIndexModule {
    function startRebalance(
        ISetToken _setToken,
        address[] calldata _newComponents,
        uint256[] calldata _newComponentsTargetUnits,
        uint256[] calldata _oldComponentsTargetUnits,
        uint256 _positionMultiplier
    )
        external;
    
    function trade(
        ISetToken _setToken,
        IERC20 _component,
        uint256 _ethQuantityLimit
    )
        external;

    function tradeRemainingWETH(
        ISetToken _setToken,
        IERC20 _component,
        uint256 _minComponentReceived
    )
        external;
    
    function raiseAssetTargets(ISetToken _setToken) external;

    function setTradeMaximums(
        ISetToken _setToken,
        address[] memory _components,
        uint256[] memory _tradeMaximums
    )
        external;
    
    function setExchanges(
        ISetToken _setToken,
        address[] memory _components,
        string[] memory _exchangeNames
    )
        external;

    function setCoolOffPeriods(
        ISetToken _setToken,
        address[] memory _components,
        uint256[] memory _coolOffPeriods
    )
        external;

    function setExchangeData(
        ISetToken _setToken,
        address[] memory _components,
        bytes[] memory _exchangeData
    )
        external;

    function setRaiseTargetPercentage(ISetToken _setToken, uint256 _raiseTargetPercentage) external;

    function setTraderStatus(
        ISetToken _setToken,
        address[] memory _traders,
        bool[] memory _statuses
    )
        external;

    function setAnyoneTrade(ISetToken _setToken, bool _status) external;
    function initialize(ISetToken _setToken) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.10;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { MerkleProof } from "@openzeppelin/contracts/cryptography/MerkleProof.sol";
import { IMerkleDistributor } from "../interfaces/IMerkleDistributor.sol";

contract MerkleDistributor is IMerkleDistributor {
    address public immutable override token;
    bytes32 public immutable override merkleRoot;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    constructor(address token_, bytes32 merkleRoot_) public {
        token = token_;
        merkleRoot = merkleRoot_;
    }

    function isClaimed(uint256 index) public view override returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external override {
        require(!isClaimed(index), "MerkleDistributor: Drop already claimed.");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), "MerkleDistributor: Invalid proof.");

        // Mark it claimed and send the token.
        _setClaimed(index);
        require(IERC20(token).transfer(account, amount), "MerkleDistributor: Transfer failed.");

        emit Claimed(index, account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.10;

// Allows anyone to claim a token if they exist in a merkle root.
interface IMerkleDistributor {
    // Returns the address of the token distributed by this contract.
    function token() external view returns (address);
    // Returns the merkle root of the merkle tree containing account balances available to claim.
    function merkleRoot() external view returns (bytes32);
    // Returns true if the index has been marked claimed.
    function isClaimed(uint256 index) external view returns (bool);
    // Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external;

    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(uint256 index, address account, uint256 amount);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.10;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

/// @title A vesting contract for full time contributors
/// @author 0xModene
/// @notice You can use this contract to set up vesting for full time DAO contributors
/// @dev All function calls are currently implemented without side effects
contract FTCVesting {
    using SafeMath for uint256;

    address public index;
    address public recipient;
    address public treasury;

    uint256 public vestingAmount;
    uint256 public vestingBegin;
    uint256 public vestingCliff;
    uint256 public vestingEnd;

    uint256 public lastUpdate;

    constructor(
        address index_,
        address recipient_,
        address treasury_,
        uint256 vestingAmount_,
        uint256 vestingBegin_,
        uint256 vestingCliff_,
        uint256 vestingEnd_
    ) public {
        require(vestingCliff_ >= vestingBegin_, "FTCVester.constructor: cliff is too early");
        require(vestingEnd_ > vestingCliff_, "FTCVester.constructor: end is too early");

        index = index_;
        recipient = recipient_;
        treasury = treasury_;

        vestingAmount = vestingAmount_;
        vestingBegin = vestingBegin_;
        vestingCliff = vestingCliff_;
        vestingEnd = vestingEnd_;

        lastUpdate = vestingBegin;
    }

    modifier onlyTreasury {
        require(msg.sender == treasury, "FTCVester.onlyTreasury: unauthorized");
        _;
    }

    modifier onlyRecipient {
        require(msg.sender == recipient, "FTCVester.onlyRecipient: unauthorized");
        _;
    }

    modifier overCliff {
        require(block.timestamp >= vestingCliff, "FTCVester.overCliff: cliff not reached");
        _;
    }

    /// @notice Sets new recipient address
    /// @param recipient_ new recipient address
    function setRecipient(address recipient_) external onlyRecipient {
        recipient = recipient_;
    }

    /// @notice Sets new treasury address
    /// @param treasury_ new treasury address
    function setTreasury(address treasury_) external onlyTreasury {
        treasury = treasury_;
    }

    /// @notice Allows recipient to claim all currently vested tokens
    function claim() external onlyRecipient overCliff {
        uint256 amount;
        if (block.timestamp >= vestingEnd) {
            amount = IERC20(index).balanceOf(address(this));
        } else {
            amount = vestingAmount.mul(block.timestamp.sub(lastUpdate)).div(vestingEnd.sub(vestingBegin));
            lastUpdate = block.timestamp;
        }
        IERC20(index).transfer(recipient, amount);
    }

    /// @notice Allows treasury to claw back funds in event of separation from recipient
    function clawback() external onlyTreasury {
        IERC20(index).transfer(treasury, IERC20(index).balanceOf(address(this)));
    }
}

pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

import { FlexibleLeverageStrategyExtension } from "../adapters/FlexibleLeverageStrategyExtension.sol";

// Mock contract for FlexibleLeverageStrategyExtension used to test FLIRebalanceViewer
contract FLIStrategyExtensionMock {

    string[] internal shouldRebalanceNames;
    FlexibleLeverageStrategyExtension.ShouldRebalance[] internal shouldRebalancesEnums;

    uint256[] internal chunkRebalanceSizes;
    address internal chunkRebalanceSellAsset;
    address internal chunkRebalanceBuyAsset;

    FlexibleLeverageStrategyExtension.ContractSettings internal strategy;

    mapping(string => FlexibleLeverageStrategyExtension.ExchangeSettings) internal exchangeSettings;
    

    function shouldRebalanceWithBounds(
        uint256 /* _customMinLeverageRatio */,
        uint256 /* _customMaxLeverageRatio */
    )
        external
        view
        returns(string[] memory, FlexibleLeverageStrategyExtension.ShouldRebalance[] memory)
    {
        return (shouldRebalanceNames, shouldRebalancesEnums);
    }

    function getChunkRebalanceNotional(
        string[] calldata /* _exchangeNames */
    ) 
        external
        view
        returns(uint256[] memory sizes, address sellAsset, address buyAsset)
    {
        sizes = chunkRebalanceSizes;
        sellAsset = chunkRebalanceSellAsset;
        buyAsset = chunkRebalanceBuyAsset;
    }

    function getStrategy() external view returns (FlexibleLeverageStrategyExtension.ContractSettings memory) {
        return strategy;
    }

    function getExchangeSettings(string memory _exchangeName) external view returns (FlexibleLeverageStrategyExtension.ExchangeSettings memory) {
        return exchangeSettings[_exchangeName];
    }

    function getEnabledExchanges() external view returns (string[] memory) {
        return shouldRebalanceNames;
    }

    /* =========== Functions for setting mock state =========== */

    function setShouldRebalanceWithBounds(
        string[] memory _shouldRebalanceNames,
        FlexibleLeverageStrategyExtension.ShouldRebalance[] memory _shouldRebalancesEnums
    )
        external
    {
        shouldRebalanceNames = _shouldRebalanceNames;
        shouldRebalancesEnums = _shouldRebalancesEnums;
    }

    function setGetChunkRebalanceWithBounds(
        uint256[] memory _chunkRebalanceSizes,
        address _chunkRebalanceSellAsset,
        address _chunkRebalanceBuyAsset
    )
        external
    {
        chunkRebalanceSizes = _chunkRebalanceSizes;
        chunkRebalanceSellAsset = _chunkRebalanceSellAsset;
        chunkRebalanceBuyAsset = _chunkRebalanceBuyAsset;
    }

    function setStrategy(FlexibleLeverageStrategyExtension.ContractSettings memory _strategy) external {
        strategy = _strategy;
    }

    function setExchangeSettings(string memory _exchangeName, FlexibleLeverageStrategyExtension.ExchangeSettings memory _settings) external {
        exchangeSettings[_exchangeName] = _settings;
    }
}

pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * Trade Adapter that doubles as a mock exchange
 */
contract TradeAdapterMock {

    /* ============ Helper Functions ============ */

    function withdraw(address _token)
        external
    {
        uint256 balance = ERC20(_token).balanceOf(address(this));
        require(ERC20(_token).transfer(msg.sender, balance), "ERC20 transfer failed");
    }

    /* ============ Trade Functions ============ */

    function trade(
        address _sourceToken,
        address _destinationToken,
        address _destinationAddress,
        uint256 _sourceQuantity,
        uint256 _minDestinationQuantity
    )
        external
    {
        uint256 destinationBalance = ERC20(_destinationToken).balanceOf(address(this));
        require(ERC20(_sourceToken).transferFrom(_destinationAddress, address(this), _sourceQuantity), "ERC20 TransferFrom failed");
        require(ERC20(_destinationToken).transfer(_destinationAddress, destinationBalance), "ERC20 transfer failed");
    }

    /* ============ Adapter Functions ============ */

    function getSpender()
        external
        view
        returns (address)
    {
        return address(this);
    }

    function getTradeCalldata(
        address _sourceToken,
        address _destinationToken,
        address _destinationAddress,
        uint256 _sourceQuantity,
        uint256 _minDestinationQuantity,
        bytes memory /* _data */
    )
        external
        view
        returns (address, uint256, bytes memory)
    {
        // Encode method data for SetToken to invoke
        bytes memory methodData = abi.encodeWithSignature(
            "trade(address,address,address,uint256,uint256)",
            _sourceToken,
            _destinationToken,
            _destinationAddress,
            _sourceQuantity,
            _minDestinationQuantity
        );

        return (address(this), 0, methodData);
    }
}

/*
    Copyright 2021 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// mock class using BasicToken
contract StandardTokenMock is ERC20 {
    constructor(
        address _initialAccount,
        uint256 _initialBalance,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    )
        public
        ERC20(_name, _symbol)
    {
        _mint(_initialAccount, _initialBalance);
        _setupDecimals(_decimals);
    }
}

/*
    Copyright 2021 IndexCooperative

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { BaseExtension } from "../lib/BaseExtension.sol";
import { IIssuanceModule } from "../interfaces/IIssuanceModule.sol";
import { IBaseManager } from "../interfaces/IBaseManager.sol";
import { ISetToken } from "../interfaces/ISetToken.sol";
import { IStreamingFeeModule } from "../interfaces/IStreamingFeeModule.sol";
import { PreciseUnitMath } from "../lib/PreciseUnitMath.sol";
import { TimeLockUpgrade } from "../lib/TimeLockUpgrade.sol";
import { MutualUpgrade } from "../lib/MutualUpgrade.sol";


/**
 * @title FeeSplitExtension
 * @author Set Protocol
 *
 * Smart contract extension that allows for splitting and setting streaming and mint/redeem fees.
 */
contract FeeSplitExtension is BaseExtension, TimeLockUpgrade, MutualUpgrade {
    using Address for address;
    using PreciseUnitMath for uint256;
    using SafeMath for uint256;

    /* ============ Events ============ */

    event FeesDistributed(
        address indexed _operatorFeeRecipient,
        address indexed _methodologist,
        uint256 _operatorTake,
        uint256 _methodologistTake
    );

    /* ============ State Variables ============ */

    ISetToken public setToken;
    IStreamingFeeModule public streamingFeeModule;
    IIssuanceModule public issuanceModule;

    // Percent of fees in precise units (10^16 = 1%) sent to operator, rest to methodologist
    uint256 public operatorFeeSplit;

    // Address which receives operator's share of fees when they're distributed. (See IIP-72)
    address public operatorFeeRecipient;

    /* ============ Constructor ============ */

    constructor(
        IBaseManager _manager,
        IStreamingFeeModule _streamingFeeModule,
        IIssuanceModule _issuanceModule,
        uint256 _operatorFeeSplit,
        address _operatorFeeRecipient
    )
        public
        BaseExtension(_manager)
    {
        streamingFeeModule = _streamingFeeModule;
        issuanceModule = _issuanceModule;
        operatorFeeSplit = _operatorFeeSplit;
        operatorFeeRecipient = _operatorFeeRecipient;
        setToken = manager.setToken();
    }

    /* ============ External Functions ============ */

    /**
     * ANYONE CALLABLE: Accrues fees from streaming fee module. Gets resulting balance after fee accrual, calculates fees for
     * operator and methodologist, and sends to operator fee recipient and methodologist respectively. NOTE: mint/redeem fees
     * will automatically be sent to this address so reading the balance of the SetToken in the contract after accrual is
     * sufficient for accounting for all collected fees.
     */
    function accrueFeesAndDistribute() public {
        // Emits a FeeActualized event
        streamingFeeModule.accrueFee(setToken);

        uint256 totalFees = setToken.balanceOf(address(this));

        address methodologist = manager.methodologist();

        uint256 operatorTake = totalFees.preciseMul(operatorFeeSplit);
        uint256 methodologistTake = totalFees.sub(operatorTake);

        if (operatorTake > 0) {
            setToken.transfer(operatorFeeRecipient, operatorTake);
        }

        if (methodologistTake > 0) {
            setToken.transfer(methodologist, methodologistTake);
        }

        emit FeesDistributed(operatorFeeRecipient, methodologist, operatorTake, methodologistTake);
    }

    /**
     * MUTUAL UPGRADE: Initializes the issuance module. Operator and Methodologist must each call
     * this function to execute the update.
     *
     * This method is called after invoking `replaceProtectedModule` or `emergencyReplaceProtectedModule`
     * to configure the replacement streaming fee module's fee settings.
     *
     * @param _maxManagerFee            Max size of issuance and redeem fees in precise units (10^16 = 1%).
     * @param _managerIssueFee          Manager issuance fees in precise units (10^16 = 1%)
     * @param _managerRedeemFee         Manager redeem fees in precise units (10^16 = 1%)
     * @param _feeRecipient             Address that receives all manager issue and redeem fees
     * @param _managerIssuanceHook      Address of manager defined hook contract
     */
    function initializeIssuanceModule(
        uint256 _maxManagerFee,
        uint256 _managerIssueFee,
        uint256 _managerRedeemFee,
        address _feeRecipient,
        address _managerIssuanceHook
    )
        external
        mutualUpgrade(manager.operator(), manager.methodologist())
    {
        bytes memory callData = abi.encodeWithSelector(
            IIssuanceModule.initialize.selector,
            manager.setToken(),
            _maxManagerFee,
            _managerIssueFee,
            _managerRedeemFee,
            _feeRecipient,
            _managerIssuanceHook
        );

        invokeManager(address(issuanceModule), callData);
    }

    /**
     * MUTUAL UPGRADE: Initializes the issuance module. Operator and Methodologist must each call
     * this function to execute the update.
     *
     * This method is called after invoking `replaceProtectedModule` or `emergencyReplaceProtectedModule`
     * to configure the replacement streaming fee module's fee settings.
     *
     * @dev FeeState settings encode the following struct
     * ```
     * struct FeeState {
     *   address feeRecipient;                // Address to accrue fees to
     *   uint256 maxStreamingFeePercentage;   // Max streaming fee maanager commits to using (1% = 1e16, 100% = 1e18)
     *   uint256 streamingFeePercentage;      // Percent of Set accruing to manager annually (1% = 1e16, 100% = 1e18)
     *   uint256 lastStreamingFeeTimestamp;   // Timestamp last streaming fee was accrued
     *}
     *```
     * @param _settings     FeeModule.FeeState settings
     */
    function initializeStreamingFeeModule(IStreamingFeeModule.FeeState memory _settings)
        external
        mutualUpgrade(manager.operator(), manager.methodologist())
    {
        bytes memory callData = abi.encodeWithSelector(
            IStreamingFeeModule.initialize.selector,
            manager.setToken(),
            _settings
        );

        invokeManager(address(streamingFeeModule), callData);
    }

    /**
     * MUTUAL UPGRADE: Updates streaming fee on StreamingFeeModule. Operator and Methodologist must each call
     * this function to execute the update. Because the method is timelocked, each party must call it twice:
     * once to set the lock and once to execute.
     *
     * Method is timelocked to protect token owners from sudden changes in fee structure which
     * they would rather not bear. The delay gives them a chance to exit their positions without penalty.
     *
     * NOTE: This will accrue streaming fees though not send to operator fee recipient and methodologist.
     *
     * @param _newFee       Percent of Set accruing to fee extension annually (1% = 1e16, 100% = 1e18)
     */
    function updateStreamingFee(uint256 _newFee)
        external
        mutualUpgrade(manager.operator(), manager.methodologist())
        timeLockUpgrade
    {
        bytes memory callData = abi.encodeWithSignature("updateStreamingFee(address,uint256)", manager.setToken(), _newFee);
        invokeManager(address(streamingFeeModule), callData);
    }

    /**
     * MUTUAL UPGRADE: Updates issue fee on IssuanceModule. Only is executed once time lock has passed.
     * Operator and Methodologist must each call this function to execute the update. Because the method
     * is timelocked, each party must call it twice: once to set the lock and once to execute.
     *
     * Method is timelocked to protect token owners from sudden changes in fee structure which
     * they would rather not bear. The delay gives them a chance to exit their positions without penalty.
     *
     * @param _newFee           New issue fee percentage in precise units (1% = 1e16, 100% = 1e18)
     */
    function updateIssueFee(uint256 _newFee)
        external
        mutualUpgrade(manager.operator(), manager.methodologist())
        timeLockUpgrade
    {
        bytes memory callData = abi.encodeWithSignature("updateIssueFee(address,uint256)", manager.setToken(), _newFee);
        invokeManager(address(issuanceModule), callData);
    }

    /**
     * MUTUAL UPGRADE: Updates redeem fee on IssuanceModule. Only is executed once time lock has passed.
     * Operator and Methodologist must each call this function to execute the update. Because the method is
     * timelocked, each party must call it twice: once to set the lock and once to execute.
     *
     * Method is timelocked to protect token owners from sudden changes in fee structure which
     * they would rather not bear. The delay gives them a chance to exit their positions without penalty.
     *
     * @param _newFee           New redeem fee percentage in precise units (1% = 1e16, 100% = 1e18)
     */
    function updateRedeemFee(uint256 _newFee)
        external
        mutualUpgrade(manager.operator(), manager.methodologist())
        timeLockUpgrade
    {
        bytes memory callData = abi.encodeWithSignature("updateRedeemFee(address,uint256)", manager.setToken(), _newFee);
        invokeManager(address(issuanceModule), callData);
    }

    /**
     * MUTUAL UPGRADE: Updates fee recipient on both streaming fee and issuance modules.
     *
     * @param _newFeeRecipient  Address of new fee recipient. This should be the address of the fee extension itself.
     */
    function updateFeeRecipient(address _newFeeRecipient)
        external
        mutualUpgrade(manager.operator(), manager.methodologist())
    {
        bytes memory callData = abi.encodeWithSignature("updateFeeRecipient(address,address)", manager.setToken(), _newFeeRecipient);
        invokeManager(address(streamingFeeModule), callData);
        invokeManager(address(issuanceModule), callData);
    }

    /**
     * MUTUAL UPGRADE: Updates fee split between operator and methodologist. Split defined in precise units (1% = 10^16).
     *
     * @param _newFeeSplit      Percent of fees in precise units (10^16 = 1%) sent to operator, (rest go to the methodologist).
     */
    function updateFeeSplit(uint256 _newFeeSplit)
        external
        mutualUpgrade(manager.operator(), manager.methodologist())
    {
        require(_newFeeSplit <= PreciseUnitMath.preciseUnit(), "Fee must be less than 100%");
        accrueFeesAndDistribute();
        operatorFeeSplit = _newFeeSplit;
    }

    /**
     * OPERATOR ONLY: Updates the address that receives the operator's share of the fees (see IIP-72)
     *
     * @param _newOperatorFeeRecipient  Address to send operator's fees to.
     */
    function updateOperatorFeeRecipient(address _newOperatorFeeRecipient)
        external
        onlyOperator
    {
        require(_newOperatorFeeRecipient != address(0), "Zero address not valid");
        operatorFeeRecipient = _newOperatorFeeRecipient;
    }
}

/*
    Copyright 2021 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;

import { ISetToken } from "./ISetToken.sol";

/**
 * @title IDebtIssuanceModule
 * @author Set Protocol
 *
 * Interface for interacting with Debt Issuance module interface.
 */
interface IIssuanceModule {
    function updateIssueFee(ISetToken _setToken, uint256 _newIssueFee) external;
    function updateRedeemFee(ISetToken _setToken, uint256 _newRedeemFee) external;
    function updateFeeRecipient(ISetToken _setToken, address _newRedeemFee) external;

    function initialize(
        ISetToken _setToken,
        uint256 _maxManagerFee,
        uint256 _managerIssueFee,
        uint256 _managerRedeemFee,
        address _feeRecipient,
        address _managerIssuanceHook
    ) external;
}

/*
    Copyright 2021 Index Cooperative.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.6.10;

import { IAirdropModule } from "../interfaces/IAirdropModule.sol";
import { IManagerIssuanceHook } from "../interfaces/IManagerIssuanceHook.sol";
import { ISetToken } from "../interfaces/ISetToken.sol";

/**
 * @title AirdropIssuanceHook
 * @author Index Coop
 *
 * Issuance hooks that absorbs all airdropped tokens. Useful for ensuring that rebasing tokens are fully accounted for before issuance. Only works
 * with tokens that strictly positively rebase such as aTokens.
 */
contract AirdropIssuanceHook is IManagerIssuanceHook {

    /* ============ State Variables ============ */

    // Address of Set Protocol AirdropModule
    IAirdropModule public airdropModule;

    /* ============== Constructor ================ */

    /**
     * Sets state variables.
     *
     * @param   _airdropModule      address of AirdropModule
     */
    constructor(IAirdropModule _airdropModule) public {
        airdropModule = _airdropModule;
    }

    /* =========== External Functions =========== */

    /**
     * Absorbs all airdropped tokens. Called by some issuance modules before issuance.
     *
     * @param   _setToken           address of SetToken to absorb airdrops for
     */
    function invokePreIssueHook(ISetToken _setToken, uint256 /* _issueQuantity */, address /* _sender */, address /* _to */) external override {
        _sync(_setToken);
    }

    /**
     * Absorbs all airdropped tokens. Called by some issuance modules before redemption.
     *
     * @param   _setToken           address of SetToken to absorb airdrops for
     */
    function invokePreRedeemHook(ISetToken _setToken, uint256 /* _issueQuantity */, address /* _sender */, address /* _to */) external override {
        _sync(_setToken);
    }

    /* =========== Internal Functions ========== */

    /**
     * Absorbs all airdropped tokens. AirdropModule must be added to an initialized for the SetToken. Must have anyoneAbsorb set to true on
     * the AirdropModule.
     *
     * @param   _setToken           address of SetToken to absorb airdrops for
     */
    function _sync(ISetToken _setToken) internal {
        address[] memory airdrops = airdropModule.getAirdrops(_setToken);
        airdropModule.batchAbsorb(_setToken, airdrops);
    }
}

/*
    Copyright 2021 Index Cooperative.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.6.10;

import { ISetToken } from "../interfaces/ISetToken.sol";

interface IAirdropModule {
    function batchAbsorb(ISetToken _setToken, address[] memory _tokens) external;
    function getAirdrops(ISetToken _setToken) external view returns (address[] memory);
}

/*
    Copyright 2021 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import { StringArrayUtils } from "../lib/StringArrayUtils.sol";


contract StringArrayUtilsMock {
    using StringArrayUtils for string[];

    string[] public storageArray;

    function testIndexOf(string[] memory A, string memory a) external pure returns (uint256, bool) {
        return A.indexOf(a);
    }

    function testRemoveStorage(string memory a) external {
        storageArray.removeStorage(a);
    }

    function setStorageArray(string[] memory A) external {
        storageArray = A;
    }

    function getStorageArray() external view returns(string[] memory) {
        return storageArray;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}