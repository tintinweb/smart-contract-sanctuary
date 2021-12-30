// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './ISymbol.sol';
import './SymbolStorage.sol';
import '../oracle/IOracleManager.sol';
import '../library/SafeMath.sol';
import '../library/DpmmLinearPricing.sol';
import '../utils/NameVersion.sol';

contract SymbolImplementationFutures is SymbolStorage, NameVersion {

    using SafeMath for uint256;
    using SafeMath for int256;

    int256 constant ONE = 1e18;

    address public immutable manager;

    address public immutable oracleManager;

    bytes32 public immutable symbolId;

    int256 public immutable feeRatio;

    int256 public immutable alpha;

    int256 public immutable fundingPeriod; // in seconds

    int256 public immutable minTradeVolume;

    int256 public immutable initialMarginRatio;

    int256 public immutable maintenanceMarginRatio;

    int256 public immutable pricePercentThreshold; // max price percent change to force settlement

    uint256 public immutable timeThreshold; // max time delay in seconds to force settlement

    bool   public immutable isCloseOnly;

    modifier _onlyManager_() {
        require(msg.sender == manager, 'SymbolImplementationFutures: only manager');
        _;
    }

    constructor (
        address manager_,
        address oracleManager_,
        string memory symbol_,
        int256[8] memory parameters_,
        bool isCloseOnly_
    ) NameVersion('SymbolImplementationFutures', '3.0.1')
    {
        manager = manager_;
        oracleManager = oracleManager_;
        symbol = symbol_;
        symbolId = keccak256(abi.encodePacked(symbol_));

        feeRatio = parameters_[0];
        alpha = parameters_[1];
        fundingPeriod = parameters_[2];
        minTradeVolume = parameters_[3];
        initialMarginRatio = parameters_[4];
        maintenanceMarginRatio = parameters_[5];
        pricePercentThreshold = parameters_[6];
        timeThreshold = parameters_[7].itou();
        isCloseOnly = isCloseOnly_;

        require(
            IOracleManager(oracleManager_).value(symbolId) != 0,
            'SymbolImplementationFutures.constructor: no price oralce'
        );
    }

    function hasPosition(uint256 pTokenId) external view returns (bool) {
        return positions[pTokenId].volume != 0;
    }

    //================================================================================

    function settleOnAddLiquidity(int256 liquidity)
    external _onlyManager_ returns (ISymbol.SettlementOnAddLiquidity memory s)
    {
        Data memory data;

        if (_getNetVolumeAndCostWithSkip(data)) return s;
        if (_getTimestampAndPriceWithSkip(data)) return s;
        _getFunding(data, liquidity);
        _getTradersPnl(data);
        _getInitialMarginRequired(data);

        s.settled = true;
        s.funding = data.funding;
        s.deltaTradersPnl = data.tradersPnl - tradersPnl;
        s.deltaInitialMarginRequired = data.initialMarginRequired - initialMarginRequired;

        indexPrice = data.curIndexPrice;
        fundingTimestamp = data.curTimestamp;
        cumulativeFundingPerVolume = data.cumulativeFundingPerVolume;
        tradersPnl = data.tradersPnl;
        initialMarginRequired = data.initialMarginRequired;
    }

    function settleOnRemoveLiquidity(int256 liquidity, int256 removedLiquidity)
    external _onlyManager_ returns (ISymbol.SettlementOnRemoveLiquidity memory s)
    {
        Data memory data;

        if (_getNetVolumeAndCostWithSkip(data)) return s;
        _getTimestampAndPrice(data);
        _getFunding(data, liquidity);
        _getTradersPnl(data);
        _getInitialMarginRequired(data);

        s.settled = true;
        s.funding = data.funding;
        s.deltaTradersPnl = data.tradersPnl - tradersPnl;
        s.deltaInitialMarginRequired = data.initialMarginRequired - initialMarginRequired;
        s.removeLiquidityPenalty = _getRemoveLiquidityPenalty(data, liquidity - removedLiquidity);

        indexPrice = data.curIndexPrice;
        fundingTimestamp = data.curTimestamp;
        cumulativeFundingPerVolume = data.cumulativeFundingPerVolume;
        tradersPnl = data.tradersPnl;
        initialMarginRequired = data.initialMarginRequired;
    }

    function settleOnTraderWithPosition(uint256 pTokenId, int256 liquidity)
    external _onlyManager_ returns (ISymbol.SettlementOnTraderWithPosition memory s)
    {
        Data memory data;

        _getNetVolumeAndCost(data);
        _getTimestampAndPrice(data);
        _getFunding(data, liquidity);
        _getTradersPnl(data);
        _getInitialMarginRequired(data);

        Position memory p = positions[pTokenId];

        s.funding = data.funding;
        s.deltaTradersPnl = data.tradersPnl - tradersPnl;
        s.deltaInitialMarginRequired = data.initialMarginRequired - initialMarginRequired;

        int256 diff;
        unchecked { diff = data.cumulativeFundingPerVolume - p.cumulativeFundingPerVolume; }
        s.traderFunding = p.volume * diff / ONE;

        int256 notional = p.volume * data.curIndexPrice / ONE;
        s.traderPnl = notional - p.cost;
        s.traderInitialMarginRequired = notional.abs() * initialMarginRatio / ONE;

        indexPrice = data.curIndexPrice;
        fundingTimestamp = data.curTimestamp;
        cumulativeFundingPerVolume = data.cumulativeFundingPerVolume;
        tradersPnl = data.tradersPnl;
        initialMarginRequired = data.initialMarginRequired;

        positions[pTokenId].cumulativeFundingPerVolume = data.cumulativeFundingPerVolume;
    }

    function settleOnTrade(uint256 pTokenId, int256 tradeVolume, int256 liquidity)
    external _onlyManager_ returns (ISymbol.SettlementOnTrade memory s)
    {
        require(
            tradeVolume != 0 && tradeVolume % minTradeVolume == 0,
            'SymbolImplementationFutures.trade: invalid tradeVolume'
        );

        Data memory data;
        _getNetVolumeAndCost(data);
        _getTimestampAndPrice(data);
        _getFunding(data, liquidity);

        Position memory p = positions[pTokenId];

        if (isCloseOnly) {
            require(
                (p.volume > 0 && tradeVolume < 0 && p.volume + tradeVolume >= 0) ||
                (p.volume < 0 && tradeVolume > 0 && p.volume + tradeVolume <= 0),
                'SymbolImplementationFutures.trade: close only'
            );
        }

        int256 diff;
        unchecked { diff = data.cumulativeFundingPerVolume - p.cumulativeFundingPerVolume; }
        s.traderFunding = p.volume * diff / ONE;

        s.tradeCost = DpmmLinearPricing.calculateCost(
            data.curIndexPrice,
            data.K,
            data.netVolume,
            tradeVolume
        );
        s.tradeFee = s.tradeCost.abs() * feeRatio / ONE;

        if (!(p.volume >= 0 && tradeVolume >= 0) && !(p.volume <= 0 && tradeVolume <= 0)) {
            int256 absVolume = p.volume.abs();
            int256 absTradeVolume = tradeVolume.abs();
            if (absVolume <= absTradeVolume) {
                s.tradeRealizedCost = s.tradeCost * absVolume / absTradeVolume + p.cost;
            } else {
                s.tradeRealizedCost = p.cost * absTradeVolume / absVolume + s.tradeCost;
            }
        }

        data.netVolume += tradeVolume;
        data.netCost += s.tradeCost - s.tradeRealizedCost;
        _getTradersPnl(data);
        _getInitialMarginRequired(data);

        p.volume += tradeVolume;
        p.cost += s.tradeCost - s.tradeRealizedCost;
        p.cumulativeFundingPerVolume = data.cumulativeFundingPerVolume;

        s.funding = data.funding;
        s.deltaTradersPnl = data.tradersPnl - tradersPnl;
        s.deltaInitialMarginRequired = data.initialMarginRequired - initialMarginRequired;
        s.indexPrice = data.curIndexPrice;

        int256 notional = p.volume * data.curIndexPrice / ONE;
        s.traderPnl = notional - p.cost;
        s.traderInitialMarginRequired = notional.abs() * initialMarginRatio / ONE;

        if (p.volume == 0) {
            s.positionChangeStatus = -1;
            nPositionHolders--;
        } else if (p.volume - tradeVolume == 0) {
            s.positionChangeStatus = 1;
            nPositionHolders++;
        }

        netVolume = data.netVolume;
        netCost = data.netCost;
        indexPrice = data.curIndexPrice;
        fundingTimestamp = data.curTimestamp;
        cumulativeFundingPerVolume = data.cumulativeFundingPerVolume;
        tradersPnl = data.tradersPnl;
        initialMarginRequired = data.initialMarginRequired;

        positions[pTokenId] = p;
    }

    function settleOnLiquidate(uint256 pTokenId, int256 liquidity)
    external _onlyManager_ returns (ISymbol.SettlementOnLiquidate memory s)
    {
        Data memory data;

        _getNetVolumeAndCost(data);
        _getTimestampAndPrice(data);
        _getFunding(data, liquidity);

        Position memory p = positions[pTokenId];

        int256 diff;
        unchecked { diff = data.cumulativeFundingPerVolume - p.cumulativeFundingPerVolume; }
        s.traderFunding = p.volume * diff / ONE;

        s.tradeVolume = -p.volume;
        s.tradeCost = DpmmLinearPricing.calculateCost(
            data.curIndexPrice,
            data.K,
            data.netVolume,
            -p.volume
        );
        s.tradeRealizedCost = s.tradeCost + p.cost;

        data.netVolume -= p.volume;
        data.netCost -= p.cost;
        _getTradersPnl(data);
        _getInitialMarginRequired(data);

        s.funding = data.funding;
        s.deltaTradersPnl = data.tradersPnl - tradersPnl;
        s.deltaInitialMarginRequired = data.initialMarginRequired - initialMarginRequired;
        s.indexPrice = data.curIndexPrice;

        int256 notional = p.volume * data.curIndexPrice / ONE;
        s.traderPnl = notional - p.cost;
        s.traderMaintenanceMarginRequired = notional.abs() * maintenanceMarginRatio / ONE;

        netVolume = data.netVolume;
        netCost = data.netCost;
        indexPrice = data.curIndexPrice;
        fundingTimestamp = data.curTimestamp;
        cumulativeFundingPerVolume = data.cumulativeFundingPerVolume;
        tradersPnl = data.tradersPnl;
        initialMarginRequired = data.initialMarginRequired;
        if (p.volume != 0) {
            nPositionHolders--;
        }

        delete positions[pTokenId];
    }

    //================================================================================

    struct Data {
        uint256 preTimestamp;
        uint256 curTimestamp;
        int256 preIndexPrice;
        int256 curIndexPrice;
        int256 netVolume;
        int256 netCost;
        int256 cumulativeFundingPerVolume;
        int256 K;
        int256 tradersPnl;
        int256 initialMarginRequired;
        int256 funding;
    }

    function _getNetVolumeAndCost(Data memory data) internal view {
        data.netVolume = netVolume;
        data.netCost = netCost;
    }

    function _getNetVolumeAndCostWithSkip(Data memory data) internal view returns (bool) {
        data.netVolume = netVolume;
        if (data.netVolume == 0) {
            return true;
        }
        data.netCost = netCost;
        return false;
    }

    function _getTimestampAndPrice(Data memory data) internal view {
        data.preTimestamp = fundingTimestamp;
        data.curTimestamp = block.timestamp;
        data.curIndexPrice = IOracleManager(oracleManager).getValue(symbolId).utoi();
    }

    function _getTimestampAndPriceWithSkip(Data memory data) internal view returns (bool) {
        _getTimestampAndPrice(data);
        data.preIndexPrice = indexPrice;
        return (
            data.curTimestamp < data.preTimestamp + timeThreshold &&
            (data.curIndexPrice - data.preIndexPrice).abs() * ONE < data.preIndexPrice * pricePercentThreshold
        );
    }

    function _calculateK(int256 indexPrice, int256 liquidity) internal view returns (int256) {
        return indexPrice * alpha / liquidity;
    }

    function _getFunding(Data memory data, int256 liquidity) internal view {
        data.cumulativeFundingPerVolume = cumulativeFundingPerVolume;
        data.K = _calculateK(data.curIndexPrice, liquidity);

        int256 markPrice = DpmmLinearPricing.calculateMarkPrice(data.curIndexPrice, data.K, data.netVolume);
        int256 diff = (markPrice - data.curIndexPrice) * (data.curTimestamp - data.preTimestamp).utoi() / fundingPeriod;
        data.funding = data.netVolume * diff / ONE;
        unchecked { data.cumulativeFundingPerVolume += diff; }
    }

    function _getTradersPnl(Data memory data) internal pure {
        data.tradersPnl = -DpmmLinearPricing.calculateCost(data.curIndexPrice, data.K, data.netVolume, -data.netVolume) - data.netCost;
    }

    function _getInitialMarginRequired(Data memory data) internal view {
        data.initialMarginRequired = data.netVolume.abs() * data.curIndexPrice / ONE * initialMarginRatio / ONE;
    }

    function _getRemoveLiquidityPenalty(Data memory data, int256 newLiquidity)
    internal view returns (int256)
    {
        int256 newK = _calculateK(data.curIndexPrice, newLiquidity);
        int256 newPnl = -DpmmLinearPricing.calculateCost(data.curIndexPrice, newK, data.netVolume, -data.netVolume) - data.netCost;
        return newPnl - data.tradersPnl;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface ISymbol {

    struct SettlementOnAddLiquidity {
        bool settled;
        int256 funding;
        int256 deltaTradersPnl;
        int256 deltaInitialMarginRequired;
    }

    struct SettlementOnRemoveLiquidity {
        bool settled;
        int256 funding;
        int256 deltaTradersPnl;
        int256 deltaInitialMarginRequired;
        int256 removeLiquidityPenalty;
    }

    struct SettlementOnTraderWithPosition {
        int256 funding;
        int256 deltaTradersPnl;
        int256 deltaInitialMarginRequired;
        int256 traderFunding;
        int256 traderPnl;
        int256 traderInitialMarginRequired;
    }

    struct SettlementOnTrade {
        int256 funding;
        int256 deltaTradersPnl;
        int256 deltaInitialMarginRequired;
        int256 indexPrice;
        int256 traderFunding;
        int256 traderPnl;
        int256 traderInitialMarginRequired;
        int256 tradeCost;
        int256 tradeFee;
        int256 tradeRealizedCost;
        int256 positionChangeStatus; // 1: new open (enter), -1: total close (exit), 0: others (not change)
    }

    struct SettlementOnLiquidate {
        int256 funding;
        int256 deltaTradersPnl;
        int256 deltaInitialMarginRequired;
        int256 indexPrice;
        int256 traderFunding;
        int256 traderPnl;
        int256 traderMaintenanceMarginRequired;
        int256 tradeVolume;
        int256 tradeCost;
        int256 tradeRealizedCost;
    }

    struct Position {
        int256 volume;
        int256 cost;
        int256 cumulativeFundingPerVolume;
    }

    function implementation() external view returns (address);

    function symbol() external view returns (string memory);

    function netVolume() external view returns (int256);

    function netCost() external view returns (int256);

    function indexPrice() external view returns (int256);

    function fundingTimestamp() external view returns (uint256);

    function cumulativeFundingPerVolume() external view returns (int256);

    function tradersPnl() external view returns (int256);

    function initialMarginRequired() external view returns (int256);

    function nPositionHolders() external view returns (uint256);

    function positions(uint256 pTokenId) external view returns (Position memory);

    function setImplementation(address newImplementation) external;

    function manager() external view returns (address);

    function oracleManager() external view returns (address);

    function symbolId() external view returns (bytes32);

    function feeRatio() external view returns (int256);             // futures only

    function alpha() external view returns (int256);

    function fundingPeriod() external view returns (int256);

    function minTradeVolume() external view returns (int256);

    function initialMarginRatio() external view returns (int256);

    function maintenanceMarginRatio() external view returns (int256);

    function pricePercentThreshold() external view returns (int256);

    function timeThreshold() external view returns (uint256);

    function isCloseOnly() external view returns (bool);

    function priceId() external view returns (bytes32);              // option only

    function volatilityId() external view returns (bytes32);         // option only

    function feeRatioITM() external view returns (int256);           // option only

    function feeRatioOTM() external view returns (int256);           // option only

    function strikePrice() external view returns (int256);           // option only

    function minInitialMarginRatio() external view returns (int256); // option only

    function isCall() external view returns (bool);                  // option only

    function hasPosition(uint256 pTokenId) external view returns (bool);

    function settleOnAddLiquidity(int256 liquidity)
    external returns (ISymbol.SettlementOnAddLiquidity memory s);

    function settleOnRemoveLiquidity(int256 liquidity, int256 removedLiquidity)
    external returns (ISymbol.SettlementOnRemoveLiquidity memory s);

    function settleOnTraderWithPosition(uint256 pTokenId, int256 liquidity)
    external returns (ISymbol.SettlementOnTraderWithPosition memory s);

    function settleOnTrade(uint256 pTokenId, int256 tradeVolume, int256 liquidity)
    external returns (ISymbol.SettlementOnTrade memory s);

    function settleOnLiquidate(uint256 pTokenId, int256 liquidity)
    external returns (ISymbol.SettlementOnLiquidate memory s);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/Admin.sol';

abstract contract SymbolStorage is Admin {

    // admin will be truned in to Timelock after deployment

    event NewImplementation(address newImplementation);

    address public implementation;

    string public symbol;

    int256 public netVolume;

    int256 public netCost;

    int256 public indexPrice;

    uint256 public fundingTimestamp;

    int256 public cumulativeFundingPerVolume;

    int256 public tradersPnl;

    int256 public initialMarginRequired;

    uint256 public nPositionHolders;

    struct Position {
        int256 volume;
        int256 cost;
        int256 cumulativeFundingPerVolume;
    }

    // pTokenId => Position
    mapping (uint256 => Position) public positions;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/INameVersion.sol';
import '../utils/IAdmin.sol';

interface IOracleManager is INameVersion, IAdmin {

    event NewOracle(bytes32 indexed symbolId, address indexed oracle);

    function getOracle(bytes32 symbolId) external view returns (address);

    function getOracle(string memory symbol) external view returns (address);

    function setOracle(address oracleAddress) external;

    function delOracle(bytes32 symbolId) external;

    function delOracle(string memory symbol) external;

    function value(bytes32 symbolId) external view returns (uint256);

    function getValue(bytes32 symbolId) external view returns (uint256);

    function updateValue(
        bytes32 symbolId,
        uint256 timestamp_,
        uint256 value_,
        uint8   v_,
        bytes32 r_,
        bytes32 s_
    ) external returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

library SafeMath {

    uint256 constant UMAX = 2 ** 255 - 1;
    int256  constant IMIN = -2 ** 255;

    function utoi(uint256 a) internal pure returns (int256) {
        require(a <= UMAX, 'SafeMath.utoi: overflow');
        return int256(a);
    }

    function itou(int256 a) internal pure returns (uint256) {
        require(a >= 0, 'SafeMath.itou: underflow');
        return uint256(a);
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != IMIN, 'SafeMath.abs: overflow');
        return a >= 0 ? a : -a;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a <= b ? a : b;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a <= b ? a : b;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

library DpmmLinearPricing {

    int256 constant ONE = 1e18;

    function calculateMarkPrice(
        int256 indexPrice,
        int256 K,
        int256 tradersNetVolume
    ) internal pure returns (int256)
    {
        return indexPrice * (ONE + K * tradersNetVolume / ONE) / ONE;
    }

    function calculateCost(
        int256 indexPrice,
        int256 K,
        int256 tradersNetVolume,
        int256 tradeVolume
    ) internal pure returns (int256)
    {
        int256 r = ((tradersNetVolume + tradeVolume) ** 2 - tradersNetVolume ** 2) / ONE * K / ONE / 2 + tradeVolume;
        return indexPrice * r / ONE;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './INameVersion.sol';

/**
 * @dev Convenience contract for name and version information
 */
abstract contract NameVersion is INameVersion {

    bytes32 public immutable nameId;
    bytes32 public immutable versionId;

    constructor (string memory name, string memory version) {
        nameId = keccak256(abi.encodePacked(name));
        versionId = keccak256(abi.encodePacked(version));
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IAdmin.sol';

abstract contract Admin is IAdmin {

    address public admin;

    modifier _onlyAdmin_() {
        require(msg.sender == admin, 'Admin: only admin');
        _;
    }

    constructor () {
        admin = msg.sender;
        emit NewAdmin(admin);
    }

    function setAdmin(address newAdmin) external _onlyAdmin_ {
        admin = newAdmin;
        emit NewAdmin(newAdmin);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IAdmin {

    event NewAdmin(address indexed newAdmin);

    function admin() external view returns (address);

    function setAdmin(address newAdmin) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface INameVersion {

    function nameId() external view returns (bytes32);

    function versionId() external view returns (bytes32);

}