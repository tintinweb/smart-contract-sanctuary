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

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Math } from "@openzeppelin/contracts/math/Math.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/SafeCast.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { AddressArrayUtils } from "../../lib/AddressArrayUtils.sol";
import { IController } from "../../interfaces/IController.sol";
import { IIndexExchangeAdapter } from "../../interfaces/IIndexExchangeAdapter.sol";
import { Invoke } from "../lib/Invoke.sol";
import { ISetToken } from "../../interfaces/ISetToken.sol";
import { IWETH } from "../../interfaces/external/IWETH.sol";
import { ModuleBase } from "../lib/ModuleBase.sol";
import { Position } from "../lib/Position.sol";
import { PreciseUnitMath } from "../../lib/PreciseUnitMath.sol";
import { Uint256ArrayUtils } from "../../lib/Uint256ArrayUtils.sol";


/**
 * @title GeneralIndexModule
 * @author Set Protocol
 *
 * Smart contract that facilitates rebalances for indices. Manager can update allocation by calling startRebalance().
 * There is no "end" to a rebalance, however once there are no more tokens to sell the rebalance is effectively over
 * until the manager calls startRebalance() again with a new allocation. Once a new allocation is passed in, allowed
 * traders can submit rebalance transactions by calling trade() and specifying the component they wish to rebalance.
 * All parameterizations for a trade are set by the manager ahead of time, including max trade size, coolOffPeriod bet-
 * ween trades, and exchange to trade on. WETH is used as the quote asset for all trades, near the end of rebalance
 * tradeRemaingingWETH() or raiseAssetTargets() can be called to clean up any excess WETH positions. Once a component's
 * target allocation is met any further attempted trades of that component will revert.
 *
 * SECURITY ASSUMPTION:
 *  - Works with following modules: StreamingFeeModule, BasicIssuanceModule (any other module additions to Sets using
 *    this module need to be examined separately)
 */
contract GeneralIndexModule is ModuleBase, ReentrancyGuard {
    using SafeCast for int256;
    using SafeCast for uint256;
    using SafeMath for uint256;
    using Position for uint256;
    using Math for uint256;
    using Position for ISetToken;
    using Invoke for ISetToken;
    using AddressArrayUtils for address[];
    using AddressArrayUtils for IERC20[];
    using Uint256ArrayUtils for uint256[];

    /* ============ Struct ============ */

    struct TradeExecutionParams {
        uint256 targetUnit;              // Target unit of component for Set
        uint256 maxSize;                 // Max trade size in precise units
        uint256 coolOffPeriod;           // Required time between trades for the asset
        uint256 lastTradeTimestamp;      // Timestamp of last trade
        string exchangeName;             // Name of exchange adapter
        bytes exchangeData;              // Arbitrary data that can be used to encode exchange specific settings (fee tier) or features (multi-hop)
    }

    struct TradePermissionInfo {
        bool anyoneTrade;                               // Boolean indicating if anyone can execute a trade
        address[] tradersHistory;                       // Tracks permissioned traders to be deleted on module removal
        mapping(address => bool) tradeAllowList;        // Mapping indicating which addresses are allowed to execute trade
    }

    struct RebalanceInfo {
        uint256 positionMultiplier;         // Position multiplier at the beginning of rebalance
        uint256 raiseTargetPercentage;      // Amount to raise all unit targets by if allowed (in precise units)
        address[] rebalanceComponents;      // Array of components involved in rebalance
    }

    struct TradeInfo {
        ISetToken setToken;                         // Instance of SetToken
        IIndexExchangeAdapter exchangeAdapter;      // Instance of Exchange Adapter
        address sendToken;                          // Address of token being sold
        address receiveToken;                       // Address of token being bought
        bool isSendTokenFixed;                      // Boolean indicating fixed asset is send token
        uint256 setTotalSupply;                     // Total supply of Set (in precise units)
        uint256 totalFixedQuantity;                 // Total quantity of fixed asset being traded
        uint256 sendQuantity;                       // Units of component sent to the exchange
        uint256 floatingQuantityLimit;              // Max/min amount of floating token spent/received during trade
        uint256 preTradeSendTokenBalance;           // Total initial balance of token being sold
        uint256 preTradeReceiveTokenBalance;        // Total initial balance of token being bought
        bytes exchangeData;                         // Arbitrary data for executing trade on given exchange
    }

    /* ============ Events ============ */

    event TargetUnitsUpdated(ISetToken indexed _setToken, address indexed _component, uint256 _newUnit, uint256 _positionMultiplier);
    event TradeMaximumUpdated(ISetToken indexed _setToken, address indexed _component, uint256 _newMaximum);
    event AssetExchangeUpdated(ISetToken indexed _setToken, address indexed _component, string _newExchangeName);
    event CoolOffPeriodUpdated(ISetToken indexed _setToken, address indexed _component, uint256 _newCoolOffPeriod);
    event ExchangeDataUpdated(ISetToken indexed _setToken, address indexed _component, bytes _newExchangeData);
    event RaiseTargetPercentageUpdated(ISetToken indexed _setToken, uint256 indexed _raiseTargetPercentage);
    event AssetTargetsRaised(ISetToken indexed _setToken, uint256 indexed positionMultiplier);

    event AnyoneTradeUpdated(ISetToken indexed _setToken, bool indexed _status);
    event TraderStatusUpdated(ISetToken indexed _setToken, address indexed _trader, bool _status);

    event TradeExecuted(
        ISetToken indexed _setToken,
        address indexed _sellComponent,
        address indexed _buyComponent,
        IIndexExchangeAdapter _exchangeAdapter,
        address _executor,
        uint256 _netAmountSold,
        uint256 _netAmountReceived,
        uint256 _protocolFee
    );

    event RebalanceStarted(ISetToken indexed _setToken);

    /* ============ Constants ============ */

    uint256 private constant GENERAL_INDEX_MODULE_PROTOCOL_FEE_INDEX = 0;                   // Id of protocol fee % assigned to this module in the Controller

    /* ============ State Variables ============ */

    mapping(ISetToken => mapping(IERC20 => TradeExecutionParams)) public executionInfo;     // Mapping of SetToken to execution parameters of each asset on SetToken
    mapping(ISetToken => TradePermissionInfo) public permissionInfo;                        // Mapping of SetToken to trading permissions
    mapping(ISetToken => RebalanceInfo) public rebalanceInfo;                               // Mapping of SetToken to relevant data for current rebalance
    IWETH public immutable weth;                                                            // Weth contract address

    /* ============ Modifiers ============ */

    modifier onlyAllowedTrader(ISetToken _setToken) {
        _validateOnlyAllowedTrader(_setToken);
        _;
    }

    modifier onlyEOAIfUnrestricted(ISetToken _setToken) {
        _validateOnlyEOAIfUnrestricted(_setToken);
        _;
    }

    /* ============ Constructor ============ */

    constructor(IController _controller, IWETH _weth) public ModuleBase(_controller) {
        weth = _weth;
    }

    /* ============ External Functions ============ */

    /**
     * MANAGER ONLY: Changes the target allocation of the Set, opening it up for trading by the Sets designated traders. The manager
     * must pass in any new components and their target units (units defined by the amount of that component the manager wants in 10**18
     * units of a SetToken). Old component target units must be passed in, in the current order of the components array on the
     * SetToken. If a component is being removed it's index in the _oldComponentsTargetUnits should be set to 0. Additionally, the
     * positionMultiplier is passed in, in order to adjust the target units in the event fees are accrued or some other activity occurs
     * that changes the positionMultiplier of the Set. This guarantees the same relative allocation between all the components.
     *
     * @param _setToken                         Address of the SetToken to be rebalanced
     * @param _newComponents                    Array of new components to add to allocation
     * @param _newComponentsTargetUnits         Array of target units at end of rebalance for new components, maps to same index of _newComponents array
     * @param _oldComponentsTargetUnits         Array of target units at end of rebalance for old component, maps to same index of
     *                                               _setToken.getComponents() array, if component being removed set to 0.
     * @param _positionMultiplier               Position multiplier when target units were calculated, needed in order to adjust target units
     *                                               if fees accrued
     */
    function startRebalance(
        ISetToken _setToken,
        address[] calldata _newComponents,
        uint256[] calldata _newComponentsTargetUnits,
        uint256[] calldata _oldComponentsTargetUnits,
        uint256 _positionMultiplier
    )
        external
        onlyManagerAndValidSet(_setToken)
    {
        ( address[] memory aggregateComponents, uint256[] memory aggregateTargetUnits ) = _getAggregateComponentsAndUnits(
            _setToken.getComponents(),
            _newComponents,
            _newComponentsTargetUnits,
            _oldComponentsTargetUnits
        );

        for (uint256 i = 0; i < aggregateComponents.length; i++) {
            require(
                _setToken.getExternalPositionModules(aggregateComponents[i]).length == 0,
                "External positions not allowed"
            );

            executionInfo[_setToken][IERC20(aggregateComponents[i])].targetUnit = aggregateTargetUnits[i];
            emit TargetUnitsUpdated(_setToken, aggregateComponents[i], aggregateTargetUnits[i], _positionMultiplier);
        }

        rebalanceInfo[_setToken].rebalanceComponents = aggregateComponents;
        rebalanceInfo[_setToken].positionMultiplier = _positionMultiplier;

        emit RebalanceStarted(_setToken);
    }

    /**
     * ACCESS LIMITED: Calling trade() pushes the current component units closer to the target units defined by the manager in startRebalance().
     * Only approved addresses can call, if anyoneTrade is false then contracts are allowed to call otherwise calling address must be EOA.
     *
     * Trade can be called at anytime but will revert if the passed component's target unit is met or cool off period hasn't passed. Trader can pass
     * in a max/min amount of ETH spent/received in the trade based on if the component is being bought/sold in order to prevent sandwich attacks.
     * The parameters defined by the manager are used to determine which exchange will be used and the size of the trade. Trade size will default
     * to max trade size unless the max trade size would exceed the target, then an amount that would match the target unit is traded. Protocol fees,
     * if enabled, are collected in the token received in a trade.
     *
     * @param _setToken             Address of the SetToken
     * @param _component            Address of SetToken component to trade
     * @param _ethQuantityLimit     Max/min amount of ETH spent/received during trade
     */
    function trade(
        ISetToken _setToken,
        IERC20 _component,
        uint256 _ethQuantityLimit
    )
        external
        nonReentrant
        onlyAllowedTrader(_setToken)
        onlyEOAIfUnrestricted(_setToken)
        virtual
    {
        _validateTradeParameters(_setToken, _component);

        TradeInfo memory tradeInfo = _createTradeInfo(_setToken, _component, _ethQuantityLimit);

        _executeTrade(tradeInfo);

        uint256 protocolFee = _accrueProtocolFee(tradeInfo);
        (uint256 netSendAmount, uint256 netReceiveAmount) = _updatePositionStateAndTimestamp(tradeInfo, _component);

        emit TradeExecuted(
            tradeInfo.setToken,
            tradeInfo.sendToken,
            tradeInfo.receiveToken,
            tradeInfo.exchangeAdapter,
            msg.sender,
            netSendAmount,
            netReceiveAmount,
            protocolFee
        );
    }

    /**
     * ACCESS LIMITED: Only callable when 1) there are no more components to be sold and, 2) entire remaining WETH amount (above WETH target) can be
     * traded such that resulting inflows won't exceed component's maxTradeSize nor overshoot the target unit. To be used near the end of rebalances
     * when a component's calculated trade size is greater in value than remaining WETH.
     *
     * Only approved addresses can call, if anyoneTrade is false then contracts are allowed to call otherwise calling address must be EOA. Trade
     * can be called at anytime but will revert if the passed component's target unit is met or cool off period hasn't passed. Like with trade()
     * a minimum component receive amount can be set.
     *
     * @param _setToken                     Address of the SetToken
     * @param _component                    Address of the SetToken component to trade
     * @param _minComponentReceived        Min amount of component received during trade
     */
    function tradeRemainingWETH(
        ISetToken _setToken,
        IERC20 _component,
        uint256 _minComponentReceived
    )
        external
        nonReentrant
        onlyAllowedTrader(_setToken)
        onlyEOAIfUnrestricted(_setToken)
        virtual
    {
        require(_noTokensToSell(_setToken), "Sell other set components first");
        require(
            executionInfo[_setToken][weth].targetUnit < _getDefaultPositionRealUnit(_setToken, weth),
            "WETH is below target unit"
        );

        _validateTradeParameters(_setToken, _component);

        TradeInfo memory tradeInfo = _createTradeRemainingInfo(_setToken, _component, _minComponentReceived);

        _executeTrade(tradeInfo);

        uint256 protocolFee = _accrueProtocolFee(tradeInfo);
        (uint256 netSendAmount, uint256 netReceiveAmount) = _updatePositionStateAndTimestamp(tradeInfo, _component);

        require(
            netReceiveAmount.add(protocolFee) < executionInfo[_setToken][_component].maxSize,
            "Trade amount > max trade size"
        );

        _validateComponentPositionUnit(_setToken, _component);

        emit TradeExecuted(
            tradeInfo.setToken,
            tradeInfo.sendToken,
            tradeInfo.receiveToken,
            tradeInfo.exchangeAdapter,
            msg.sender,
            netSendAmount,
            netReceiveAmount,
            protocolFee
        );
    }

    /**
     * ACCESS LIMITED: For situation where all target units met and remaining WETH, uniformly raise targets by same percentage by applying
     * to logged positionMultiplier in RebalanceInfo struct, in order to allow further trading. Can be called multiple times if necessary,
     * targets are increased by amount specified by raiseAssetTargetsPercentage as set by manager. In order to reduce tracking error
     * raising the target by a smaller amount allows greater granularity in finding an equilibrium between the excess ETH and components
     * that need to be bought. Raising the targets too much could result in vastly under allocating to WETH as more WETH than necessary is
     * spent buying the components to meet their new target.
     *
     * @param _setToken             Address of the SetToken
     */
    function raiseAssetTargets(ISetToken _setToken) external onlyAllowedTrader(_setToken) virtual {
        require(
            _allTargetsMet(_setToken)
            && _getDefaultPositionRealUnit(_setToken, weth) > _getNormalizedTargetUnit(_setToken, weth),
            "Targets not met or ETH =~ 0"
        );

        // positionMultiplier / (10^18 + raiseTargetPercentage)
        // ex: (10 ** 18) / ((10 ** 18) + ether(.0025)) => 997506234413965087
        rebalanceInfo[_setToken].positionMultiplier = rebalanceInfo[_setToken].positionMultiplier.preciseDiv(
            PreciseUnitMath.preciseUnit().add(rebalanceInfo[_setToken].raiseTargetPercentage)
        );
        emit AssetTargetsRaised(_setToken, rebalanceInfo[_setToken].positionMultiplier);
    }

    /**
     * MANAGER ONLY: Set trade maximums for passed components of the SetToken. Can be called at anytime.
     * Note: Trade maximums must be set before rebalance can begin properly - they are zero by
     * default and trades will not execute if a component's trade size is greater than the maximum.
     *
     * @param _setToken             Address of the SetToken
     * @param _components           Array of components
     * @param _tradeMaximums        Array of trade maximums mapping to correct component
     */
    function setTradeMaximums(
        ISetToken _setToken,
        address[] memory _components,
        uint256[] memory _tradeMaximums
    )
        external
        onlyManagerAndValidSet(_setToken)
    {
        _components.validatePairsWithArray(_tradeMaximums);

        for (uint256 i = 0; i < _components.length; i++) {
            executionInfo[_setToken][IERC20(_components[i])].maxSize = _tradeMaximums[i];
            emit TradeMaximumUpdated(_setToken, _components[i], _tradeMaximums[i]);
        }
    }

    /**
     * MANAGER ONLY: Set exchange for passed components of the SetToken. Can be called at anytime.
     *
     * @param _setToken             Address of the SetToken
     * @param _components           Array of components
     * @param _exchangeNames        Array of exchange names mapping to correct component
     */
    function setExchanges(
        ISetToken _setToken,
        address[] memory _components,
        string[] memory _exchangeNames
    )
        external
        onlyManagerAndValidSet(_setToken)
    {
        _components.validatePairsWithArray(_exchangeNames);

        for (uint256 i = 0; i < _components.length; i++) {
            if (_components[i] != address(weth)) {

                require(
                    controller.getIntegrationRegistry().isValidIntegration(address(this), _exchangeNames[i]),
                    "Unrecognized exchange name"
                );

                executionInfo[_setToken][IERC20(_components[i])].exchangeName = _exchangeNames[i];
                emit AssetExchangeUpdated(_setToken, _components[i], _exchangeNames[i]);
            }
        }
    }

    /**
     * MANAGER ONLY: Set cool off periods for passed components of the SetToken. Can be called at any time.
     *
     * @param _setToken             Address of the SetToken
     * @param _components           Array of components
     * @param _coolOffPeriods       Array of cool off periods to correct component
     */
    function setCoolOffPeriods(
        ISetToken _setToken,
        address[] memory _components,
        uint256[] memory _coolOffPeriods
    )
        external
        onlyManagerAndValidSet(_setToken)
    {
        _components.validatePairsWithArray(_coolOffPeriods);

        for (uint256 i = 0; i < _components.length; i++) {
            executionInfo[_setToken][IERC20(_components[i])].coolOffPeriod = _coolOffPeriods[i];
            emit CoolOffPeriodUpdated(_setToken, _components[i], _coolOffPeriods[i]);
        }
    }

    /**
     * MANAGER ONLY: Set arbitrary byte data on a per asset basis that can be used to pass exchange specific settings (i.e. specifying
     * fee tiers) or exchange specific features (enabling multi-hop trades). Can be called at any time.
     *
     * @param _setToken             Address of the SetToken
     * @param _components           Array of components
     * @param _exchangeData         Array of exchange specific arbitrary bytes data
     */
    function setExchangeData(
        ISetToken _setToken,
        address[] memory _components,
        bytes[] memory _exchangeData
    )
        external
        onlyManagerAndValidSet(_setToken)
    {
        _components.validatePairsWithArray(_exchangeData);

        for (uint256 i = 0; i < _components.length; i++) {
            executionInfo[_setToken][IERC20(_components[i])].exchangeData = _exchangeData[i];
            emit ExchangeDataUpdated(_setToken, _components[i], _exchangeData[i]);
        }
    }

    /**
     * MANAGER ONLY: Set amount by which all component's targets units would be raised. Can be called at any time.
     *
     * @param _setToken                     Address of the SetToken
     * @param _raiseTargetPercentage        Amount to raise all component's unit targets by (in precise units)
     */
    function setRaiseTargetPercentage(
        ISetToken _setToken,
        uint256 _raiseTargetPercentage
    )
        external
        onlyManagerAndValidSet(_setToken)
    {
        require(_raiseTargetPercentage > 0, "Target percentage must be > 0");
        rebalanceInfo[_setToken].raiseTargetPercentage = _raiseTargetPercentage;
        emit RaiseTargetPercentageUpdated(_setToken, _raiseTargetPercentage);
    }

    /**
     * MANAGER ONLY: Toggles ability for passed addresses to call trade() or tradeRemainingWETH(). Can be called at any time.
     *
     * @param _setToken          Address of the SetToken
     * @param _traders           Array trader addresses to toggle status
     * @param _statuses          Booleans indicating if matching trader can trade
     */
    function setTraderStatus(
        ISetToken _setToken,
        address[] memory _traders,
        bool[] memory _statuses
    )
        external
        onlyManagerAndValidSet(_setToken)
    {
        _traders.validatePairsWithArray(_statuses);

        for (uint256 i = 0; i < _traders.length; i++) {
            _updateTradersHistory(_setToken, _traders[i], _statuses[i]);
            permissionInfo[_setToken].tradeAllowList[_traders[i]] = _statuses[i];
            emit TraderStatusUpdated(_setToken, _traders[i], _statuses[i]);
        }
    }

    /**
     * MANAGER ONLY: Toggle whether anyone can trade, if true bypasses the traderAllowList. Can be called at anytime.
     *
     * @param _setToken         Address of the SetToken
     * @param _status           Boolean indicating if anyone can trade
     */
    function setAnyoneTrade(ISetToken _setToken, bool _status) external onlyManagerAndValidSet(_setToken) {
        permissionInfo[_setToken].anyoneTrade = _status;
        emit AnyoneTradeUpdated(_setToken, _status);
    }

    /**
     * MANAGER ONLY: Called to initialize module to SetToken in order to allow GeneralIndexModule access for rebalances.
     * Grabs the current units for each asset in the Set and set's the targetUnit to that unit in order to prevent any
     * trading until startRebalance() is explicitly called. Position multiplier is also logged in order to make sure any
     * position multiplier changes don't unintentionally open the Set for rebalancing.
     *
     * @param _setToken         Address of the Set Token
     */
    function initialize(ISetToken _setToken)
        external
        onlySetManager(_setToken, msg.sender)
        onlyValidAndPendingSet(_setToken)
    {
        ISetToken.Position[] memory positions = _setToken.getPositions();

        for (uint256 i = 0; i < positions.length; i++) {
            ISetToken.Position memory position = positions[i];
            require(position.positionState == 0, "External positions not allowed");
            executionInfo[_setToken][IERC20(position.component)].targetUnit = position.unit.toUint256();
            executionInfo[_setToken][IERC20(position.component)].lastTradeTimestamp = 0;
        }

        rebalanceInfo[_setToken].positionMultiplier = _setToken.positionMultiplier().toUint256();
        _setToken.initializeModule();
    }

    /**
     * Called by a SetToken to notify that this module was removed from the SetToken.
     * Clears the rebalanceInfo and permissionsInfo of the calling SetToken.
     * IMPORTANT: SetToken's execution settings, including trade maximums and exchange names,
     * are NOT DELETED. Restoring a previously removed module requires that care is taken to
     * initialize execution settings appropriately.
     */
    function removeModule() external override {
        TradePermissionInfo storage tokenPermissionInfo = permissionInfo[ISetToken(msg.sender)];

        for (uint i = 0; i < tokenPermissionInfo.tradersHistory.length; i++) {
            tokenPermissionInfo.tradeAllowList[tokenPermissionInfo.tradersHistory[i]] = false;
        }

        delete rebalanceInfo[ISetToken(msg.sender)];
        delete permissionInfo[ISetToken(msg.sender)];
    }

    /* ============ External View Functions ============ */

    /**
     * Get the array of SetToken components involved in rebalance.
     *
     * @param _setToken         Address of the SetToken
     *
     * @return address[]        Array of _setToken components involved in rebalance
     */
    function getRebalanceComponents(ISetToken _setToken)
        external
        view
        onlyValidAndInitializedSet(_setToken)
        returns (address[] memory)
    {
        return rebalanceInfo[_setToken].rebalanceComponents;
    }

    /**
     * Calculates the amount of a component that is going to be traded and whether the component is being bought
     * or sold. If currentUnit and targetUnit are the same, function will revert.
     *
     * @param _setToken                 Instance of the SetToken to rebalance
     * @param _component                IERC20 component to trade
     *
     * @return isSendTokenFixed         Boolean indicating fixed asset is send token
     * @return componentQuantity        Amount of component being traded
     */
    function getComponentTradeQuantityAndDirection(
        ISetToken _setToken,
        IERC20 _component
    )
        external
        view
        onlyValidAndInitializedSet(_setToken)
        returns (bool, uint256)
    {
        require(_setToken.isComponent(address(_component)), "Component not recognized");
        uint256 totalSupply = _setToken.totalSupply();
        return _calculateTradeSizeAndDirection(_setToken, _component, totalSupply);
    }


    /**
     * Get if a given address is an allowed trader.
     *
     * @param _setToken         Address of the SetToken
     * @param _trader           Address of the trader
     *
     * @return bool             True if _trader is allowed to trade, else false
     */
    function getIsAllowedTrader(ISetToken _setToken, address _trader)
        external
        view
        onlyValidAndInitializedSet(_setToken)
        returns (bool)
    {
        return _isAllowedTrader(_setToken, _trader);
    }

    /**
     * Get the list of traders who are allowed to call trade(), tradeRemainingWeth(), and raiseAssetTarget()
     *
     * @param _setToken         Address of the SetToken
     *
     * @return address[]
     */
    function getAllowedTraders(ISetToken _setToken)
        external
        view
        onlyValidAndInitializedSet(_setToken)
        returns (address[] memory)
    {
        return permissionInfo[_setToken].tradersHistory;
    }

    /* ============ Internal Functions ============ */

    /**
     * Validate that component is a valid component and enough time has elapsed since component's last trade. Traders
     * cannot explicitly trade WETH, it may only implicitly be traded by being the quote asset for other component trades.
     *
     * @param _setToken         Instance of the SetToken
     * @param _component        IERC20 component to be validated
     */
    function _validateTradeParameters(ISetToken _setToken, IERC20 _component) internal view virtual {
        require(address(_component) != address(weth), "Can not explicitly trade WETH");
        require(
            rebalanceInfo[_setToken].rebalanceComponents.contains(address(_component)),
            "Component not part of rebalance"
        );

        TradeExecutionParams memory componentInfo = executionInfo[_setToken][_component];
        require(
            componentInfo.lastTradeTimestamp.add(componentInfo.coolOffPeriod) <= block.timestamp,
            "Component cool off in progress"
        );
    }

    /**
     * Create and return TradeInfo struct. This function reverts if the target has already been met.
     * If this is a trade from component into WETH, sell the total fixed component quantity
     * and expect to receive an ETH amount the user has specified (or more). If it's a trade from
     * WETH into a component, sell the lesser of: the user's WETH limit OR the SetToken's
     * remaining WETH balance and expect to receive a fixed component quantity.
     *
     * @param _setToken             Instance of the SetToken to rebalance
     * @param _component            IERC20 component to trade
     * @param _ethQuantityLimit     Max/min amount of weth spent/received during trade
     *
     * @return tradeInfo            Struct containing data for trade
     */
    function _createTradeInfo(
        ISetToken _setToken,
        IERC20 _component,
        uint256 _ethQuantityLimit
    )
        internal
        view
        virtual
        returns (TradeInfo memory tradeInfo)
    {
        tradeInfo = _getDefaultTradeInfo(_setToken, _component, true);

        if (tradeInfo.isSendTokenFixed){
            tradeInfo.sendQuantity = tradeInfo.totalFixedQuantity;
            tradeInfo.floatingQuantityLimit = _ethQuantityLimit;
        } else {
            tradeInfo.sendQuantity = _ethQuantityLimit.min(tradeInfo.preTradeSendTokenBalance);
            tradeInfo.floatingQuantityLimit = tradeInfo.totalFixedQuantity;
        }
    }

    /**
     * Create and return TradeInfo struct. This function does NOT check if the WETH target has been met.
     *
     * @param _setToken                     Instance of the SetToken to rebalance
     * @param _component                    IERC20 component to trade
     * @param _minComponentReceived         Min amount of component received during trade
     *
     * @return tradeInfo                    Struct containing data for tradeRemaining info
     */
    function _createTradeRemainingInfo(
        ISetToken _setToken,
        IERC20 _component,
        uint256 _minComponentReceived
    )
        internal
        view
        returns (TradeInfo memory tradeInfo)
    {
        tradeInfo = _getDefaultTradeInfo(_setToken, _component, false);

        (,,
            uint256 currentNotional,
            uint256 targetNotional
        ) = _getUnitsAndNotionalAmounts(_setToken, weth, tradeInfo.setTotalSupply);

        tradeInfo.sendQuantity =  currentNotional.sub(targetNotional);
        tradeInfo.floatingQuantityLimit = _minComponentReceived;
        tradeInfo.isSendTokenFixed = true;
    }

    /**
     * Create and returns a partial TradeInfo struct with all fields that overlap between `trade`
     * and `tradeRemaining` info constructors filled in. Values for `sendQuantity` and `floatingQuantityLimit`
     * are derived separately, outside this method. `trade` requires that trade size and direction are
     * calculated, whereas `tradeRemaining` automatically sets WETH as the sendToken and _component
     * as receiveToken.
     *
     * @param _setToken                     Instance of the SetToken to rebalance
     * @param _component                    IERC20 component to trade
     * @param  calculateTradeDirection      Indicates whether method should calculate trade size and direction
     *
     * @return tradeInfo                    Struct containing partial data for trade
     */
    function _getDefaultTradeInfo(ISetToken _setToken, IERC20 _component, bool calculateTradeDirection)
        internal
        view
        returns (TradeInfo memory tradeInfo)
    {
        tradeInfo.setToken = _setToken;
        tradeInfo.setTotalSupply = _setToken.totalSupply();
        tradeInfo.exchangeAdapter = _getExchangeAdapter(_setToken, _component);
        tradeInfo.exchangeData = executionInfo[_setToken][_component].exchangeData;

        if(calculateTradeDirection){
            (
                tradeInfo.isSendTokenFixed,
                tradeInfo.totalFixedQuantity
            ) = _calculateTradeSizeAndDirection(_setToken, _component, tradeInfo.setTotalSupply);
        }

        if (tradeInfo.isSendTokenFixed){
            tradeInfo.sendToken = address(_component);
            tradeInfo.receiveToken = address(weth);
        } else {
            tradeInfo.sendToken = address(weth);
            tradeInfo.receiveToken = address(_component);
        }

        tradeInfo.preTradeSendTokenBalance = IERC20(tradeInfo.sendToken).balanceOf(address(_setToken));
        tradeInfo.preTradeReceiveTokenBalance = IERC20(tradeInfo.receiveToken).balanceOf(address(_setToken));
    }

    /**
     * Function handles all interactions with exchange. All GeneralIndexModule adapters must allow for selling or buying a fixed
     * quantity of a token in return for a non-fixed (floating) quantity of a token. If `isSendTokenFixed` is true then the adapter
     * will choose the exchange interface associated with inputting a fixed amount, otherwise it will select the interface used for
     * receiving a fixed amount. Any other exchange specific data can also be created by calling generateDataParam function.
     *
     * @param _tradeInfo            Struct containing trade information used in internal functions
     */
    function _executeTrade(TradeInfo memory _tradeInfo) internal virtual {
        _tradeInfo.setToken.invokeApprove(
            _tradeInfo.sendToken,
            _tradeInfo.exchangeAdapter.getSpender(),
            _tradeInfo.sendQuantity
        );

        (
            address targetExchange,
            uint256 callValue,
            bytes memory methodData
        ) = _tradeInfo.exchangeAdapter.getTradeCalldata(
            _tradeInfo.sendToken,
            _tradeInfo.receiveToken,
            address(_tradeInfo.setToken),
            _tradeInfo.isSendTokenFixed,
            _tradeInfo.sendQuantity,
            _tradeInfo.floatingQuantityLimit,
            _tradeInfo.exchangeData
        );

        _tradeInfo.setToken.invoke(targetExchange, callValue, methodData);
    }

    /**
     * Retrieve fee from controller and calculate total protocol fee and send from SetToken to protocol recipient.
     * The protocol fee is collected from the amount of received token in the trade.
     *
     * @param _tradeInfo                Struct containing trade information used in internal functions
     *
     * @return protocolFee              Amount of receive token taken as protocol fee
     */
    function _accrueProtocolFee(TradeInfo memory _tradeInfo) internal returns (uint256 protocolFee) {
        uint256 exchangedQuantity =  IERC20(_tradeInfo.receiveToken)
            .balanceOf(address(_tradeInfo.setToken))
            .sub(_tradeInfo.preTradeReceiveTokenBalance);

        protocolFee = getModuleFee(GENERAL_INDEX_MODULE_PROTOCOL_FEE_INDEX, exchangedQuantity);
        payProtocolFeeFromSetToken(_tradeInfo.setToken, _tradeInfo.receiveToken, protocolFee);
    }

    /**
     * Update SetToken positions and executionInfo's last trade timestamp. This function is intended
     * to be called after the fees have been accrued, hence it returns the amount of tokens bought net of fees.
     *
     * @param _tradeInfo                Struct containing trade information used in internal functions
     * @param _component                IERC20 component which was traded
     *
     * @return netSendAmount            Amount of sendTokens used in the trade
     * @return netReceiveAmount         Amount of receiveTokens received in the trade (net of fees)
     */
    function _updatePositionStateAndTimestamp(TradeInfo memory _tradeInfo, IERC20 _component)
        internal
        returns (uint256 netSendAmount, uint256 netReceiveAmount)
    {
        (uint256 postTradeSendTokenBalance,,) = _tradeInfo.setToken.calculateAndEditDefaultPosition(
            _tradeInfo.sendToken,
            _tradeInfo.setTotalSupply,
            _tradeInfo.preTradeSendTokenBalance
        );
        (uint256 postTradeReceiveTokenBalance,,) = _tradeInfo.setToken.calculateAndEditDefaultPosition(
            _tradeInfo.receiveToken,
            _tradeInfo.setTotalSupply,
            _tradeInfo.preTradeReceiveTokenBalance
        );

        netSendAmount = _tradeInfo.preTradeSendTokenBalance.sub(postTradeSendTokenBalance);
        netReceiveAmount = postTradeReceiveTokenBalance.sub(_tradeInfo.preTradeReceiveTokenBalance);

        executionInfo[_tradeInfo.setToken][_component].lastTradeTimestamp = block.timestamp;
    }

    /**
     * Calculates the amount of a component is going to be traded and whether the component is being bought or sold.
     * If currentUnit and targetUnit are the same, function will revert.
     *
     * @param _setToken                 Instance of the SetToken to rebalance
     * @param _component                IERC20 component to trade
     * @param _totalSupply              Total supply of _setToken
     *
     * @return isSendTokenFixed         Boolean indicating fixed asset is send token
     * @return totalFixedQuantity       Amount of fixed token to send or receive
     */
    function _calculateTradeSizeAndDirection(
        ISetToken _setToken,
        IERC20 _component,
        uint256 _totalSupply
    )
        internal
        view
        returns (bool isSendTokenFixed, uint256 totalFixedQuantity)
    {
        uint256 protocolFee = controller.getModuleFee(address(this), GENERAL_INDEX_MODULE_PROTOCOL_FEE_INDEX);
        uint256 componentMaxSize = executionInfo[_setToken][_component].maxSize;

        (
            uint256 currentUnit,
            uint256 targetUnit,
            uint256 currentNotional,
            uint256 targetNotional
        ) = _getUnitsAndNotionalAmounts(_setToken, _component, _totalSupply);

        require(currentUnit != targetUnit, "Target already met");

        isSendTokenFixed = targetNotional < currentNotional;

        // In order to account for fees taken by protocol when buying the notional difference between currentUnit
        // and targetUnit is divided by (1 - protocolFee) to make sure that targetUnit can be met. Failure to
        // do so would lead to never being able to meet target of components that need to be bought.
        //
        // ? - lesserOf: (componentMaxSize, (currentNotional - targetNotional))
        // : - lesserOf: (componentMaxSize, (targetNotional - currentNotional) / 10 ** 18 - protocolFee)
        totalFixedQuantity = isSendTokenFixed
            ? componentMaxSize.min(currentNotional.sub(targetNotional))
            : componentMaxSize.min(targetNotional.sub(currentNotional).preciseDiv(PreciseUnitMath.preciseUnit().sub(protocolFee)));
    }

    /**
     * Gets unit and notional amount values for current position and target. These are necessary
     * to calculate the trade size and direction for regular trades and the `sendQuantity` for
     * remainingWEth trades.
     *
     * @param _setToken                 Instance of the SetToken to rebalance
     * @param _component                IERC20 component to calculate notional amounts for
     * @param _totalSupply              SetToken total supply
     *
     * @return uint256              Current default position real unit of component
     * @return uint256              Normalized unit of the trade target
     * @return uint256              Current notional amount: total notional amount of SetToken default position
     * @return uint256              Target notional amount: Total SetToken supply * targetUnit
     */
    function _getUnitsAndNotionalAmounts(ISetToken _setToken, IERC20 _component, uint256 _totalSupply)
        internal
        view
        returns (uint256, uint256, uint256, uint256)
    {
        uint256 currentUnit = _getDefaultPositionRealUnit(_setToken, _component);
        uint256 targetUnit = _getNormalizedTargetUnit(_setToken, _component);

        return (
            currentUnit,
            targetUnit,
            _totalSupply.getDefaultTotalNotional(currentUnit),
            _totalSupply.preciseMulCeil(targetUnit)
        );
    }

    /**
     * Check if there are any more tokens to sell. Since we allow WETH to float around it's target during rebalances it is not checked.
     *
     * @param _setToken             Instance of the SetToken to be rebalanced
     *
     * @return bool                 True if there is not any component that can be sold, otherwise false
     */
    function _noTokensToSell(ISetToken _setToken) internal view returns (bool) {
        address[] memory rebalanceComponents = rebalanceInfo[_setToken].rebalanceComponents;

        for (uint256 i = 0; i < rebalanceComponents.length; i++) {
            if (_canSell(_setToken, rebalanceComponents[i]) ) { return false; }
        }
        return true;
    }

    /**
     * Check if all targets are met.
     *
     * @param _setToken             Instance of the SetToken to be rebalanced
     *
     * @return bool                 True if all component's target units have been met, otherwise false
     */
    function _allTargetsMet(ISetToken _setToken) internal view returns (bool) {
        address[] memory rebalanceComponents = rebalanceInfo[_setToken].rebalanceComponents;

        for (uint256 i = 0; i < rebalanceComponents.length; i++) {
            if (_targetUnmet(_setToken, rebalanceComponents[i])) { return false; }
        }
        return true;
    }

    /**
     * Calculates and returns the normalized target unit value.
     *
     * @param _setToken             Instance of the SetToken to be rebalanced
     * @param _component            IERC20 component whose normalized target unit is required
     *
     * @return uint256                          Normalized target unit of the component
     */
    function _getNormalizedTargetUnit(ISetToken _setToken, IERC20 _component) internal view returns(uint256) {
        // (targetUnit * current position multiplier) / position multiplier when rebalance started
        return executionInfo[_setToken][_component]
            .targetUnit
            .mul(_setToken.positionMultiplier().toUint256())
            .div(rebalanceInfo[_setToken].positionMultiplier);
    }

    /**
     * Gets exchange adapter address for a component after checking that it exists in the
     * IntegrationRegistry. This method is called during a trade and must validate the adapter
     * because its state may have changed since it was set in a separate transaction.
     *
     * @param _setToken                         Instance of the SetToken to be rebalanced
     * @param _component                        IERC20 component whose exchange adapter is fetched
     *
     * @return IExchangeAdapter                 Adapter address
     */
    function _getExchangeAdapter(ISetToken _setToken, IERC20 _component) internal view returns(IIndexExchangeAdapter) {
        return IIndexExchangeAdapter(getAndValidateAdapter(executionInfo[_setToken][_component].exchangeName));
    }

    /**
     * Extends and/or updates the current component set and its target units with new components and targets,
     * Validates inputs, requiring that that new components and new target units arrays are the same size, and
     * that the number of old components target units matches the number of current components. Throws if
     * a duplicate component has been added.
     *
     * @param  _currentComponents               Complete set of current SetToken components
     * @param _newComponents                    Array of new components to add to allocation
     * @param _newComponentsTargetUnits         Array of target units at end of rebalance for new components, maps to same index of _newComponents array
     * @param _oldComponentsTargetUnits         Array of target units at end of rebalance for old component, maps to same index of
     *                                               _setToken.getComponents() array, if component being removed set to 0.
     *
     * @return aggregateComponents              Array of current components extended by new components, without duplicates
     * @return aggregateTargetUnits             Array of old component target units extended by new target units, without duplicates
     */
    function _getAggregateComponentsAndUnits(
        address[] memory _currentComponents,
        address[] calldata _newComponents,
        uint256[] calldata _newComponentsTargetUnits,
        uint256[] calldata _oldComponentsTargetUnits
    )
        internal
        pure
        returns (address[] memory aggregateComponents, uint256[] memory aggregateTargetUnits)
    {
        // Don't use validate arrays because empty arrays are valid
        require(_newComponents.length == _newComponentsTargetUnits.length, "Array length mismatch");
        require(_currentComponents.length == _oldComponentsTargetUnits.length, "Old Components targets missing");

        aggregateComponents = _currentComponents.extend(_newComponents);
        aggregateTargetUnits = _oldComponentsTargetUnits.extend(_newComponentsTargetUnits);

        require(!aggregateComponents.hasDuplicate(), "Cannot duplicate components");
    }

    /**
     * Validate component position unit has not exceeded it's target unit. This is used during tradeRemainingWETH() to make sure
     * the amount of component bought does not exceed the targetUnit.
     *
     * @param _setToken         Instance of the SetToken
     * @param _component        IERC20 component whose position units are to be validated
     */
    function _validateComponentPositionUnit(ISetToken _setToken, IERC20 _component) internal view {
        uint256 currentUnit = _getDefaultPositionRealUnit(_setToken, _component);
        uint256 targetUnit = _getNormalizedTargetUnit(_setToken, _component);
        require(currentUnit <= targetUnit, "Can not exceed target unit");
    }

    /**
     * Get the SetToken's default position as uint256
     *
     * @param _setToken         Instance of the SetToken
     * @param _component        IERC20 component to fetch the default position for
     *
     * return uint256           Real unit position
     */
    function _getDefaultPositionRealUnit(ISetToken _setToken, IERC20 _component) internal view returns (uint256) {
        return _setToken.getDefaultPositionRealUnit(address(_component)).toUint256();
    }

    /**
     * Determine if passed address is allowed to call trade for the SetToken. If anyoneTrade set to true anyone can call otherwise
     * needs to be approved.
     *
     * @param _setToken             Instance of SetToken to be rebalanced
     * @param  _trader              Address of the trader who called contract function
     *
     * @return bool                 True if trader is an approved trader for the SetToken
     */
    function _isAllowedTrader(ISetToken _setToken, address _trader) internal view returns (bool) {
        TradePermissionInfo storage permissions = permissionInfo[_setToken];
        return permissions.anyoneTrade || permissions.tradeAllowList[_trader];
    }

    /**
     * Checks if sell conditions are met. The component cannot be WETH and its normalized target
     * unit must be less than its default position real unit
     *
     * @param _setToken                         Instance of the SetToken to be rebalanced
     * @param _component                        Component evaluated for sale
     *
     * @return bool                             True if sell allowed, false otherwise
     */
    function _canSell(ISetToken _setToken, address _component) internal view returns(bool) {
        return (
            _component != address(weth) &&
            (
                _getNormalizedTargetUnit(_setToken, IERC20(_component)) <
                _getDefaultPositionRealUnit(_setToken,IERC20(_component))
            )
        );
    }

    /**
     * Determines if a target is met. Due to small rounding errors converting between virtual and
     * real unit on SetToken we allow for a 1 wei buffer when checking if target is met. In order to
     * avoid subtraction overflow errors targetUnits of zero check for an exact amount. WETH is not
     * checked as it is allowed to float around its target.
     *
     * @param _setToken                         Instance of the SetToken to be rebalanced
     * @param _component                        Component whose target is evaluated
     *
     * @return bool                             True if component's target units are met, false otherwise
     */
    function _targetUnmet(ISetToken _setToken, address _component) internal view returns(bool) {
        if (_component == address(weth)) return false;

        uint256 normalizedTargetUnit = _getNormalizedTargetUnit(_setToken, IERC20(_component));
        uint256 currentUnit = _getDefaultPositionRealUnit(_setToken, IERC20(_component));

        return (normalizedTargetUnit > 0)
            ? !(normalizedTargetUnit.approximatelyEquals(currentUnit, 1))
            : normalizedTargetUnit != currentUnit;
    }

    /**
     * Adds or removes newly permissioned trader to/from permissionsInfo traderHistory. It's
     * necessary to verify that traderHistory contains the address because AddressArrayUtils will
     * throw when attempting to remove a non-element and it's possible someone can set a new
     * trader's status to false.
     *
     * @param _setToken                         Instance of the SetToken
     * @param _trader                           Trader whose permission is being set
     * @param _status                           Boolean permission being set

     */
    function _updateTradersHistory(ISetToken _setToken, address _trader, bool _status) internal {
        if (_status && !permissionInfo[_setToken].tradersHistory.contains(_trader)) {
            permissionInfo[_setToken].tradersHistory.push(_trader);
        } else if(!_status && permissionInfo[_setToken].tradersHistory.contains(_trader)) {
            permissionInfo[_setToken].tradersHistory.removeStorage(_trader);
        }
    }

    /* ============== Modifier Helpers ===============
     * Internal functions used to reduce bytecode size
     */

    /*
     * Trader must be permissioned for SetToken
     */
    function _validateOnlyAllowedTrader(ISetToken _setToken) internal view {
        require(_isAllowedTrader(_setToken, msg.sender), "Address not permitted to trade");
    }

    /*
     * Trade must be an EOA if `anyoneTrade` has been enabled for SetToken on the module.
     */
    function _validateOnlyEOAIfUnrestricted(ISetToken _setToken) internal view {
        if(permissionInfo[_setToken].anyoneTrade) {
            require(msg.sender == tx.origin, "Caller must be EOA Address");
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
 * - 4/21/21: Added validatePairsWithArray methods
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

interface IIndexExchangeAdapter {
    function getSpender() external view returns(address);

    /**
     * Returns calldata for executing trade on given adapter's exchange when using the GeneralIndexModule.
     *
     * @param  _sourceToken              Address of source token to be sold
     * @param  _destinationToken         Address of destination token to buy
     * @param  _destinationAddress       Address that assets should be transferred to
     * @param  _isSendTokenFixed         Boolean indicating if the send quantity is fixed, used to determine correct trade interface
     * @param  _sourceQuantity           Fixed/Max amount of source token to sell
     * @param  _destinationQuantity      Min/Fixed amount of destination tokens to receive
     * @param  _data                     Arbitrary bytes that can be used to store exchange specific parameters or logic
     *
     * @return address                   Target contract address
     * @return uint256                   Call value
     * @return bytes                     Trade calldata
     */
    function getTradeCalldata(
        address _sourceToken,
        address _destinationToken,
        address _destinationAddress,
        bool _isSendTokenFixed,
        uint256 _sourceQuantity,
        uint256 _destinationQuantity,
        bytes memory _data
    )
        external
        view
        returns (address, uint256, bytes memory);
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

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { ISetToken } from "../../interfaces/ISetToken.sol";


/**
 * @title Invoke
 * @author Set Protocol
 *
 * A collection of common utility functions for interacting with the SetToken's invoke function
 */
library Invoke {
    using SafeMath for uint256;

    /* ============ Internal ============ */

    /**
     * Instructs the SetToken to set approvals of the ERC20 token to a spender.
     *
     * @param _setToken        SetToken instance to invoke
     * @param _token           ERC20 token to approve
     * @param _spender         The account allowed to spend the SetToken's balance
     * @param _quantity        The quantity of allowance to allow
     */
    function invokeApprove(
        ISetToken _setToken,
        address _token,
        address _spender,
        uint256 _quantity
    )
        internal
    {
        bytes memory callData = abi.encodeWithSignature("approve(address,uint256)", _spender, _quantity);
        _setToken.invoke(_token, 0, callData);
    }

    /**
     * Instructs the SetToken to transfer the ERC20 token to a recipient.
     *
     * @param _setToken        SetToken instance to invoke
     * @param _token           ERC20 token to transfer
     * @param _to              The recipient account
     * @param _quantity        The quantity to transfer
     */
    function invokeTransfer(
        ISetToken _setToken,
        address _token,
        address _to,
        uint256 _quantity
    )
        internal
    {
        if (_quantity > 0) {
            bytes memory callData = abi.encodeWithSignature("transfer(address,uint256)", _to, _quantity);
            _setToken.invoke(_token, 0, callData);
        }
    }

    /**
     * Instructs the SetToken to transfer the ERC20 token to a recipient.
     * The new SetToken balance must equal the existing balance less the quantity transferred
     *
     * @param _setToken        SetToken instance to invoke
     * @param _token           ERC20 token to transfer
     * @param _to              The recipient account
     * @param _quantity        The quantity to transfer
     */
    function strictInvokeTransfer(
        ISetToken _setToken,
        address _token,
        address _to,
        uint256 _quantity
    )
        internal
    {
        if (_quantity > 0) {
            // Retrieve current balance of token for the SetToken
            uint256 existingBalance = IERC20(_token).balanceOf(address(_setToken));

            Invoke.invokeTransfer(_setToken, _token, _to, _quantity);

            // Get new balance of transferred token for SetToken
            uint256 newBalance = IERC20(_token).balanceOf(address(_setToken));

            // Verify only the transfer quantity is subtracted
            require(
                newBalance == existingBalance.sub(_quantity),
                "Invalid post transfer balance"
            );
        }
    }

    /**
     * Instructs the SetToken to unwrap the passed quantity of WETH
     *
     * @param _setToken        SetToken instance to invoke
     * @param _weth            WETH address
     * @param _quantity        The quantity to unwrap
     */
    function invokeUnwrapWETH(ISetToken _setToken, address _weth, uint256 _quantity) internal {
        bytes memory callData = abi.encodeWithSignature("withdraw(uint256)", _quantity);
        _setToken.invoke(_weth, 0, callData);
    }

    /**
     * Instructs the SetToken to wrap the passed quantity of ETH
     *
     * @param _setToken        SetToken instance to invoke
     * @param _weth            WETH address
     * @param _quantity        The quantity to unwrap
     */
    function invokeWrapWETH(ISetToken _setToken, address _weth, uint256 _quantity) internal {
        bytes memory callData = abi.encodeWithSignature("deposit()");
        _setToken.invoke(_weth, _quantity, callData);
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

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IWETH
 * @author Set Protocol
 *
 * Interface for Wrapped Ether. This interface allows for interaction for wrapped ether's deposit and withdrawal
 * functionality.
 */
interface IWETH is IERC20{
    function deposit()
        external
        payable;

    function withdraw(
        uint256 wad
    )
        external;
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

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { AddressArrayUtils } from "../../lib/AddressArrayUtils.sol";
import { ExplicitERC20 } from "../../lib/ExplicitERC20.sol";
import { IController } from "../../interfaces/IController.sol";
import { IModule } from "../../interfaces/IModule.sol";
import { ISetToken } from "../../interfaces/ISetToken.sol";
import { Invoke } from "./Invoke.sol";
import { Position } from "./Position.sol";
import { PreciseUnitMath } from "../../lib/PreciseUnitMath.sol";
import { ResourceIdentifier } from "./ResourceIdentifier.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/SafeCast.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/math/SignedSafeMath.sol";

/**
 * @title ModuleBase
 * @author Set Protocol
 *
 * Abstract class that houses common Module-related state and functions.
 *
 * CHANGELOG:
 * - 4/21/21: Delegated modifier logic to internal helpers to reduce contract size
 *
 */
abstract contract ModuleBase is IModule {
    using AddressArrayUtils for address[];
    using Invoke for ISetToken;
    using Position for ISetToken;
    using PreciseUnitMath for uint256;
    using ResourceIdentifier for IController;
    using SafeCast for int256;
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    /* ============ State Variables ============ */

    // Address of the controller
    IController public controller;

    /* ============ Modifiers ============ */

    modifier onlyManagerAndValidSet(ISetToken _setToken) {
        _validateOnlyManagerAndValidSet(_setToken);
        _;
    }

    modifier onlySetManager(ISetToken _setToken, address _caller) {
        _validateOnlySetManager(_setToken, _caller);
        _;
    }

    modifier onlyValidAndInitializedSet(ISetToken _setToken) {
        _validateOnlyValidAndInitializedSet(_setToken);
        _;
    }

    /**
     * Throws if the sender is not a SetToken's module or module not enabled
     */
    modifier onlyModule(ISetToken _setToken) {
        _validateOnlyModule(_setToken);
        _;
    }

    /**
     * Utilized during module initializations to check that the module is in pending state
     * and that the SetToken is valid
     */
    modifier onlyValidAndPendingSet(ISetToken _setToken) {
        _validateOnlyValidAndPendingSet(_setToken);
        _;
    }

    /* ============ Constructor ============ */

    /**
     * Set state variables and map asset pairs to their oracles
     *
     * @param _controller             Address of controller contract
     */
    constructor(IController _controller) public {
        controller = _controller;
    }

    /* ============ Internal Functions ============ */

    /**
     * Transfers tokens from an address (that has set allowance on the module).
     *
     * @param  _token          The address of the ERC20 token
     * @param  _from           The address to transfer from
     * @param  _to             The address to transfer to
     * @param  _quantity       The number of tokens to transfer
     */
    function transferFrom(IERC20 _token, address _from, address _to, uint256 _quantity) internal {
        ExplicitERC20.transferFrom(_token, _from, _to, _quantity);
    }

    /**
     * Gets the integration for the module with the passed in name. Validates that the address is not empty
     */
    function getAndValidateAdapter(string memory _integrationName) internal view returns(address) { 
        bytes32 integrationHash = getNameHash(_integrationName);
        return getAndValidateAdapterWithHash(integrationHash);
    }

    /**
     * Gets the integration for the module with the passed in hash. Validates that the address is not empty
     */
    function getAndValidateAdapterWithHash(bytes32 _integrationHash) internal view returns(address) { 
        address adapter = controller.getIntegrationRegistry().getIntegrationAdapterWithHash(
            address(this),
            _integrationHash
        );

        require(adapter != address(0), "Must be valid adapter"); 
        return adapter;
    }

    /**
     * Gets the total fee for this module of the passed in index (fee % * quantity)
     */
    function getModuleFee(uint256 _feeIndex, uint256 _quantity) internal view returns(uint256) {
        uint256 feePercentage = controller.getModuleFee(address(this), _feeIndex);
        return _quantity.preciseMul(feePercentage);
    }

    /**
     * Pays the _feeQuantity from the _setToken denominated in _token to the protocol fee recipient
     */
    function payProtocolFeeFromSetToken(ISetToken _setToken, address _token, uint256 _feeQuantity) internal {
        if (_feeQuantity > 0) {
            _setToken.strictInvokeTransfer(_token, controller.feeRecipient(), _feeQuantity); 
        }
    }

    /**
     * Returns true if the module is in process of initialization on the SetToken
     */
    function isSetPendingInitialization(ISetToken _setToken) internal view returns(bool) {
        return _setToken.isPendingModule(address(this));
    }

    /**
     * Returns true if the address is the SetToken's manager
     */
    function isSetManager(ISetToken _setToken, address _toCheck) internal view returns(bool) {
        return _setToken.manager() == _toCheck;
    }

    /**
     * Returns true if SetToken must be enabled on the controller 
     * and module is registered on the SetToken
     */
    function isSetValidAndInitialized(ISetToken _setToken) internal view returns(bool) {
        return controller.isSet(address(_setToken)) &&
            _setToken.isInitializedModule(address(this));
    }

    /**
     * Hashes the string and returns a bytes32 value
     */
    function getNameHash(string memory _name) internal pure returns(bytes32) {
        return keccak256(bytes(_name));
    }

    /* ============== Modifier Helpers ===============
     * Internal functions used to reduce bytecode size
     */

    /**
     * Caller must SetToken manager and SetToken must be valid and initialized
     */
    function _validateOnlyManagerAndValidSet(ISetToken _setToken) internal view {
       require(isSetManager(_setToken, msg.sender), "Must be the SetToken manager");
       require(isSetValidAndInitialized(_setToken), "Must be a valid and initialized SetToken");
    }

    /**
     * Caller must SetToken manager
     */
    function _validateOnlySetManager(ISetToken _setToken, address _caller) internal view {
        require(isSetManager(_setToken, _caller), "Must be the SetToken manager");
    }

    /**
     * SetToken must be valid and initialized
     */
    function _validateOnlyValidAndInitializedSet(ISetToken _setToken) internal view {
        require(isSetValidAndInitialized(_setToken), "Must be a valid and initialized SetToken");
    }

    /**
     * Caller must be initialized module and module must be enabled on the controller
     */
    function _validateOnlyModule(ISetToken _setToken) internal view {
        require(
            _setToken.moduleStates(msg.sender) == ISetToken.ModuleState.INITIALIZED,
            "Only the module can call"
        );

        require(
            controller.isModule(msg.sender),
            "Module must be enabled on controller"
        );
    }

    /**
     * SetToken must be in a pending state and module must be in pending state
     */
    function _validateOnlyValidAndPendingSet(ISetToken _setToken) internal view {
        require(controller.isSet(address(_setToken)), "Must be controller-enabled SetToken");
        require(isSetPendingInitialization(_setToken), "Must be pending initialization");
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
import { SafeCast } from "@openzeppelin/contracts/utils/SafeCast.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/math/SignedSafeMath.sol";

import { ISetToken } from "../../interfaces/ISetToken.sol";
import { PreciseUnitMath } from "../../lib/PreciseUnitMath.sol";


/**
 * @title Position
 * @author Set Protocol
 *
 * Collection of helper functions for handling and updating SetToken Positions
 *
 * CHANGELOG:
 *  - Updated editExternalPosition to work when no external position is associated with module
 */
library Position {
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SafeCast for int256;
    using SignedSafeMath for int256;
    using PreciseUnitMath for uint256;

    /* ============ Helper ============ */

    /**
     * Returns whether the SetToken has a default position for a given component (if the real unit is > 0)
     */
    function hasDefaultPosition(ISetToken _setToken, address _component) internal view returns(bool) {
        return _setToken.getDefaultPositionRealUnit(_component) > 0;
    }

    /**
     * Returns whether the SetToken has an external position for a given component (if # of position modules is > 0)
     */
    function hasExternalPosition(ISetToken _setToken, address _component) internal view returns(bool) {
        return _setToken.getExternalPositionModules(_component).length > 0;
    }
    
    /**
     * Returns whether the SetToken component default position real unit is greater than or equal to units passed in.
     */
    function hasSufficientDefaultUnits(ISetToken _setToken, address _component, uint256 _unit) internal view returns(bool) {
        return _setToken.getDefaultPositionRealUnit(_component) >= _unit.toInt256();
    }

    /**
     * Returns whether the SetToken component external position is greater than or equal to the real units passed in.
     */
    function hasSufficientExternalUnits(
        ISetToken _setToken,
        address _component,
        address _positionModule,
        uint256 _unit
    )
        internal
        view
        returns(bool)
    {
       return _setToken.getExternalPositionRealUnit(_component, _positionModule) >= _unit.toInt256();    
    }

    /**
     * If the position does not exist, create a new Position and add to the SetToken. If it already exists,
     * then set the position units. If the new units is 0, remove the position. Handles adding/removing of 
     * components where needed (in light of potential external positions).
     *
     * @param _setToken           Address of SetToken being modified
     * @param _component          Address of the component
     * @param _newUnit            Quantity of Position units - must be >= 0
     */
    function editDefaultPosition(ISetToken _setToken, address _component, uint256 _newUnit) internal {
        bool isPositionFound = hasDefaultPosition(_setToken, _component);
        if (!isPositionFound && _newUnit > 0) {
            // If there is no Default Position and no External Modules, then component does not exist
            if (!hasExternalPosition(_setToken, _component)) {
                _setToken.addComponent(_component);
            }
        } else if (isPositionFound && _newUnit == 0) {
            // If there is a Default Position and no external positions, remove the component
            if (!hasExternalPosition(_setToken, _component)) {
                _setToken.removeComponent(_component);
            }
        }

        _setToken.editDefaultPositionUnit(_component, _newUnit.toInt256());
    }

    /**
     * Update an external position and remove and external positions or components if necessary. The logic flows as follows:
     * 1) If component is not already added then add component and external position. 
     * 2) If component is added but no existing external position using the passed module exists then add the external position.
     * 3) If the existing position is being added to then just update the unit and data
     * 4) If the position is being closed and no other external positions or default positions are associated with the component
     *    then untrack the component and remove external position.
     * 5) If the position is being closed and other existing positions still exist for the component then just remove the
     *    external position.
     *
     * @param _setToken         SetToken being updated
     * @param _component        Component position being updated
     * @param _module           Module external position is associated with
     * @param _newUnit          Position units of new external position
     * @param _data             Arbitrary data associated with the position
     */
    function editExternalPosition(
        ISetToken _setToken,
        address _component,
        address _module,
        int256 _newUnit,
        bytes memory _data
    )
        internal
    {
        if (_newUnit != 0) {
            if (!_setToken.isComponent(_component)) {
                _setToken.addComponent(_component);
                _setToken.addExternalPositionModule(_component, _module);
            } else if (!_setToken.isExternalPositionModule(_component, _module)) {
                _setToken.addExternalPositionModule(_component, _module);
            }
            _setToken.editExternalPositionUnit(_component, _module, _newUnit);
            _setToken.editExternalPositionData(_component, _module, _data);
        } else {
            require(_data.length == 0, "Passed data must be null");
            // If no default or external position remaining then remove component from components array
            if (_setToken.getExternalPositionRealUnit(_component, _module) != 0) {
                address[] memory positionModules = _setToken.getExternalPositionModules(_component);
                if (_setToken.getDefaultPositionRealUnit(_component) == 0 && positionModules.length == 1) {
                    require(positionModules[0] == _module, "External positions must be 0 to remove component");
                    _setToken.removeComponent(_component);
                }
                _setToken.removeExternalPositionModule(_component, _module);
            }
        }
    }

    /**
     * Get total notional amount of Default position
     *
     * @param _setTokenSupply     Supply of SetToken in precise units (10^18)
     * @param _positionUnit       Quantity of Position units
     *
     * @return                    Total notional amount of units
     */
    function getDefaultTotalNotional(uint256 _setTokenSupply, uint256 _positionUnit) internal pure returns (uint256) {
        return _setTokenSupply.preciseMul(_positionUnit);
    }

    /**
     * Get position unit from total notional amount
     *
     * @param _setTokenSupply     Supply of SetToken in precise units (10^18)
     * @param _totalNotional      Total notional amount of component prior to
     * @return                    Default position unit
     */
    function getDefaultPositionUnit(uint256 _setTokenSupply, uint256 _totalNotional) internal pure returns (uint256) {
        return _totalNotional.preciseDiv(_setTokenSupply);
    }

    /**
     * Get the total tracked balance - total supply * position unit
     *
     * @param _setToken           Address of the SetToken
     * @param _component          Address of the component
     * @return                    Notional tracked balance
     */
    function getDefaultTrackedBalance(ISetToken _setToken, address _component) internal view returns(uint256) {
        int256 positionUnit = _setToken.getDefaultPositionRealUnit(_component); 
        return _setToken.totalSupply().preciseMul(positionUnit.toUint256());
    }

    /**
     * Calculates the new default position unit and performs the edit with the new unit
     *
     * @param _setToken                 Address of the SetToken
     * @param _component                Address of the component
     * @param _setTotalSupply           Current SetToken supply
     * @param _componentPreviousBalance Pre-action component balance
     * @return                          Current component balance
     * @return                          Previous position unit
     * @return                          New position unit
     */
    function calculateAndEditDefaultPosition(
        ISetToken _setToken,
        address _component,
        uint256 _setTotalSupply,
        uint256 _componentPreviousBalance
    )
        internal
        returns(uint256, uint256, uint256)
    {
        uint256 currentBalance = IERC20(_component).balanceOf(address(_setToken));
        uint256 positionUnit = _setToken.getDefaultPositionRealUnit(_component).toUint256();

        uint256 newTokenUnit;
        if (currentBalance > 0) {
            newTokenUnit = calculateDefaultEditPositionUnit(
                _setTotalSupply,
                _componentPreviousBalance,
                currentBalance,
                positionUnit
            );
        } else {
            newTokenUnit = 0;
        }

        editDefaultPosition(_setToken, _component, newTokenUnit);

        return (currentBalance, positionUnit, newTokenUnit);
    }

    /**
     * Calculate the new position unit given total notional values pre and post executing an action that changes SetToken state
     * The intention is to make updates to the units without accidentally picking up airdropped assets as well.
     *
     * @param _setTokenSupply     Supply of SetToken in precise units (10^18)
     * @param _preTotalNotional   Total notional amount of component prior to executing action
     * @param _postTotalNotional  Total notional amount of component after the executing action
     * @param _prePositionUnit    Position unit of SetToken prior to executing action
     * @return                    New position unit
     */
    function calculateDefaultEditPositionUnit(
        uint256 _setTokenSupply,
        uint256 _preTotalNotional,
        uint256 _postTotalNotional,
        uint256 _prePositionUnit
    )
        internal
        pure
        returns (uint256)
    {
        // If pre action total notional amount is greater then subtract post action total notional and calculate new position units
        uint256 airdroppedAmount = _preTotalNotional.sub(_prePositionUnit.preciseMul(_setTokenSupply));
        return _postTotalNotional.sub(airdroppedAmount).preciseDiv(_setTokenSupply);
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
 * - 4/21/21: Added approximatelyEquals function
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

    /**
     * @dev Returns true if a =~ b within range, false otherwise.
     */
    function approximatelyEquals(uint256 a, uint256 b, uint256 range) internal pure returns (bool) {
        return a <= b.add(range) && a >= b.sub(range);
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
 * @title Uint256ArrayUtils
 * @author Set Protocol
 *
 * Utility functions to handle Uint256 Arrays
 */
library Uint256ArrayUtils {

    /**
     * Returns the combination of the two arrays
     * @param A The first array
     * @param B The second array
     * @return Returns A extended by B
     */
    function extend(uint256[] memory A, uint256[] memory B) internal pure returns (uint256[] memory) {
        uint256 aLength = A.length;
        uint256 bLength = B.length;
        uint256[] memory newUints = new uint256[](aLength + bLength);
        for (uint256 i = 0; i < aLength; i++) {
            newUints[i] = A[i];
        }
        for (uint256 j = 0; j < bLength; j++) {
            newUints[aLength + j] = B[j];
        }
        return newUints;
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

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title ExplicitERC20
 * @author Set Protocol
 *
 * Utility functions for ERC20 transfers that require the explicit amount to be transferred.
 */
library ExplicitERC20 {
    using SafeMath for uint256;

    /**
     * When given allowance, transfers a token from the "_from" to the "_to" of quantity "_quantity".
     * Ensures that the recipient has received the correct quantity (ie no fees taken on transfer)
     *
     * @param _token           ERC20 token to approve
     * @param _from            The account to transfer tokens from
     * @param _to              The account to transfer tokens to
     * @param _quantity        The quantity to transfer
     */
    function transferFrom(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _quantity
    )
        internal
    {
        // Call specified ERC20 contract to transfer tokens (via proxy).
        if (_quantity > 0) {
            uint256 existingBalance = _token.balanceOf(_to);

            SafeERC20.safeTransferFrom(
                _token,
                _from,
                _to,
                _quantity
            );

            uint256 newBalance = _token.balanceOf(_to);

            // Verify transfer quantity is reflected in balance
            require(
                newBalance == existingBalance.add(_quantity),
                "Invalid post transfer balance"
            );
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
 * @title IModule
 * @author Set Protocol
 *
 * Interface for interacting with Modules.
 */
interface IModule {
    /**
     * Called by a SetToken to notify that this module was removed from the Set token. Any logic can be included
     * in case checks need to be made or state needs to be cleared.
     */
    function removeModule() external;
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

import { IController } from "../../interfaces/IController.sol";
import { IIntegrationRegistry } from "../../interfaces/IIntegrationRegistry.sol";
import { IPriceOracle } from "../../interfaces/IPriceOracle.sol";
import { ISetValuer } from "../../interfaces/ISetValuer.sol";

/**
 * @title ResourceIdentifier
 * @author Set Protocol
 *
 * A collection of utility functions to fetch information related to Resource contracts in the system
 */
library ResourceIdentifier {

    // IntegrationRegistry will always be resource ID 0 in the system
    uint256 constant internal INTEGRATION_REGISTRY_RESOURCE_ID = 0;
    // PriceOracle will always be resource ID 1 in the system
    uint256 constant internal PRICE_ORACLE_RESOURCE_ID = 1;
    // SetValuer resource will always be resource ID 2 in the system
    uint256 constant internal SET_VALUER_RESOURCE_ID = 2;

    /* ============ Internal ============ */

    /**
     * Gets the instance of integration registry stored on Controller. Note: IntegrationRegistry is stored as index 0 on
     * the Controller
     */
    function getIntegrationRegistry(IController _controller) internal view returns (IIntegrationRegistry) {
        return IIntegrationRegistry(_controller.resourceId(INTEGRATION_REGISTRY_RESOURCE_ID));
    }

    /**
     * Gets instance of price oracle on Controller. Note: PriceOracle is stored as index 1 on the Controller
     */
    function getPriceOracle(IController _controller) internal view returns (IPriceOracle) {
        return IPriceOracle(_controller.resourceId(PRICE_ORACLE_RESOURCE_ID));
    }

    /**
     * Gets the instance of Set valuer on Controller. Note: SetValuer is stored as index 2 on the Controller
     */
    function getSetValuer(IController _controller) internal view returns (ISetValuer) {
        return ISetValuer(_controller.resourceId(SET_VALUER_RESOURCE_ID));
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

interface IIntegrationRegistry {
    function addIntegration(address _module, string memory _id, address _wrapper) external;
    function getIntegrationAdapter(address _module, string memory _id) external view returns(address);
    function getIntegrationAdapterWithHash(address _module, bytes32 _id) external view returns(address);
    function isValidIntegration(address _module, string memory _id) external view returns(bool);
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
 * @title IPriceOracle
 * @author Set Protocol
 *
 * Interface for interacting with PriceOracle
 */
interface IPriceOracle {

    /* ============ Functions ============ */

    function getPrice(address _assetOne, address _assetTwo) external view returns (uint256);
    function masterQuoteAsset() external view returns (address);
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

import { ISetToken } from "../interfaces/ISetToken.sol";

interface ISetValuer {
    function calculateSetTokenValuation(ISetToken _setToken, address _quoteAsset) external view returns (uint256);
}

