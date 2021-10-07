// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../oracles/IVolatilityChainlinkOracle.sol";
import "../interface/IEverlastingOption.sol";
import "../interface/ILTokenOption.sol";
import "../interface/IPTokenOption.sol";
import "../interface/IERC20.sol";
import "../interface/IOracleViewer.sol";
import "../interface/IOracleWithUpdate.sol";
import "../interface/IVolatilityOracle.sol";
import "../interface/ILiquidatorQualifier.sol";
import "../library/SafeMath.sol";
import "../library/SafeERC20.sol";
import "../governance/IGovernanceData.sol";

import {PMMPricing} from "../library/PMMPricing.sol";
import {IEverlastingOptionPricing} from "../interface/IEverlastingOptionPricing.sol";

contract EverlastingOption is IEverlastingOption, Ownable {
    using SafeMath for uint256;
    using SafeMath for int256;
    using SafeERC20 for IERC20;

    PMMPricing public PmmPricer;
    IEverlastingOptionPricing public OptionPricer;
    int256 private constant ONE = 10**18;
    int256 private constant MinInitialMarginRatio = 10**16;
    int256 public _T = 10**18 / int256(365); // premium funding period = 1 day
    int256 public _premiumFundingCoefficient = 10**18 / int256(3600 * 24); // premium funding rate per second

    uint256 private immutable _decimals;

    address private immutable _bTokenAddress;
    address private immutable _lTokenAddress;
    address private immutable _pTokenAddress;
    address private immutable _liquidatorQualifierAddress;
    address private immutable _protocolFeeCollector;
    address private immutable _governanceDataAddress;
    IGovernanceData private _governanceData;

    int256 private _liquidity;
    uint256 private _lastTimestamp;
    int256 private _protocolFeeAccrued;

    // symbolId => SymbolInfo
    SymbolInfo private _symbol;

    bool private _mutex;
    modifier _lock_() {
        require(!_mutex, "reentry");
        _mutex = true;
        _;
        _mutex = false;
    }

    constructor(
        address pricingAddress,
        address everlastingPricingOptionAddress,
        address[6] memory addresses
    ) {
        PmmPricer = PMMPricing(pricingAddress);
        OptionPricer = IEverlastingOptionPricing(everlastingPricingOptionAddress);

        _bTokenAddress = addresses[0];
        _lTokenAddress = addresses[1];
        _pTokenAddress = addresses[2];
        _liquidatorQualifierAddress = addresses[3];
        _protocolFeeCollector = addresses[4];
        _governanceDataAddress = addresses[5];
        _governanceData = IGovernanceData(addresses[5]);

        _decimals = IERC20(addresses[0]).decimals();
    }

    function getAddresses()
        external
        view
        override
        returns (
            address bTokenAddress,
            address lTokenAddress,
            address pTokenAddress,
            address liquidatorQualifierAddress,
            address protocolFeeCollector,
            address governanceData
        )
    {
        return (
            _bTokenAddress,
            _lTokenAddress,
            _pTokenAddress,
            _liquidatorQualifierAddress,
            _protocolFeeCollector,
            _governanceDataAddress
        );
    }

    function getSymbol() external view override returns (SymbolInfo memory) {
        return _symbol;
    }

    function getLiquidity() external view override returns (int256) {
        return _liquidity;
    }

    function getLastTimestamp() external view override returns (uint256) {
        return _lastTimestamp;
    }

    function getProtocolFeeAccrued() external view override returns (int256) {
        return _protocolFeeAccrued;
    }

    function collectProtocolFee() external override {
        uint256 balance = IERC20(_bTokenAddress).balanceOf(address(this)).rescale(_decimals, 18);
        uint256 amount = _protocolFeeAccrued.itou();
        if (amount > balance) amount = balance;
        _protocolFeeAccrued -= amount.utoi();
        _transferOut(_protocolFeeCollector, amount);
        emit ProtocolFeeCollection(_protocolFeeCollector, amount);
    }

    function setPoolParameters(
        uint256 premiumFundingCoefficient,
        int256 T,
        address everlastingPricingOptionAddress
    ) external onlyOwner {
        _premiumFundingCoefficient = int256(premiumFundingCoefficient);
        _T = T;
        OptionPricer = IEverlastingOptionPricing(everlastingPricingOptionAddress);
    }

    //================================================================================
    // Interactions with offchain volatility
    //================================================================================

    function addLiquidity(uint256 bAmount, SignedData memory data) external override {
        require(bAmount > 0, "0 bAmount");
        _updateVolatilityAndPrice(data);
        _addLiquidity(msg.sender, bAmount);
    }

    function removeLiquidity(uint256 lShares, SignedData memory data) external override {
        require(lShares > 0, "0 lShares");
        _updateVolatilityAndPrice(data);
        _removeLiquidity(msg.sender, lShares);
    }

    function addMargin(uint256 bAmount) external override {
        require(bAmount > 0, "0 bAmount");
        _addMargin(msg.sender, bAmount);
    }

    function removeMargin(uint256 bAmount, SignedData memory data) external override {
        require(bAmount > 0, "0 bAmount");
        _updateVolatilityAndPrice(data);
        _removeMargin(msg.sender, bAmount);
    }

    function trade(int256 tradeVolume, SignedData memory data) external override {
        require(tradeVolume != 0 && (tradeVolume / ONE) * ONE == tradeVolume, "inv Vol");
        _updateVolatilityAndPrice(data);
        _trade(msg.sender, tradeVolume);
    }

    function tradeWithChainlinkOracle(int256 tradeVolume) external {
        require(tradeVolume != 0 && (tradeVolume / ONE) * ONE == tradeVolume, "inv Vol");
        _updateDataFromChainlink();
        _trade(msg.sender, tradeVolume);
    }

    function liquidate(address account, SignedData memory data) external override {
        address liquidator = msg.sender;
        require(
            _liquidatorQualifierAddress == address(0) ||
                ILiquidatorQualifier(_liquidatorQualifierAddress).isQualifiedLiquidator(liquidator),
            "unqualified"
        );
        _updateVolatilityAndPrice(data);
        _liquidate(liquidator, account);
    }

    //================================================================================
    // Core logics
    //================================================================================
    function _addLiquidity(address account, uint256 bAmount) internal _lock_ {
        (int256 totalDynamicEquity, , ) = _updateSymbolPricesAndFundingRates();

        bAmount = _transferIn(account, bAmount);
        ILTokenOption lToken = ILTokenOption(_lTokenAddress);

        uint256 totalSupply = lToken.totalSupply();
        uint256 lShares;
        if (totalSupply == 0) {
            lShares = bAmount;
        } else {
            lShares = (bAmount * totalSupply) / totalDynamicEquity.itou();
        }

        lToken.mint(account, lShares);
        _liquidity += bAmount.utoi();

        emit AddLiquidity(account, lShares, bAmount);
    }

    function _removeLiquidity(address account, uint256 lShares) internal _lock_ {
        (int256 totalDynamicEquity, int256 minPoolRequiredMargin, ) = _updateSymbolPricesAndFundingRates();
        ILTokenOption lToken = ILTokenOption(_lTokenAddress);

        uint256 totalSupply = lToken.totalSupply();
        uint256 bAmount = (lShares * totalDynamicEquity.itou()) / totalSupply;

        _liquidity -= bAmount.utoi();
        require((totalDynamicEquity - bAmount.utoi()) >= minPoolRequiredMargin, "pool insuf margin");
        lToken.burn(account, lShares);
        _transferOut(account, bAmount);

        emit RemoveLiquidity(account, lShares, bAmount);
    }

    function _addMargin(address account, uint256 bAmount) internal _lock_ {
        bAmount = _transferIn(account, bAmount);

        IPTokenOption pToken = IPTokenOption(_pTokenAddress);
        if (!pToken.exists(account)) pToken.mint(account);

        pToken.addMargin(account, bAmount.utoi());
        emit AddMargin(account, bAmount);
    }

    function _removeMargin(address account, uint256 bAmount) internal _lock_ {
        _updateSymbolPricesAndFundingRates();
        (
            IPTokenOption.Position memory position,
            bool positionUpdate,
            int256 margin
        ) = _settleTraderFundingFee(account);

        int256 amount = bAmount.utoi();
        if (amount >= margin) {
            amount = margin;
            bAmount = amount.itou();
            margin = 0;
        } else {
            margin -= amount;
        }

        (bool initialMarginSafe, ) = _getTraderMarginStatus(position, margin);
        require(initialMarginSafe, "insuf margin");
        _updateTraderPortfolio(account, position, positionUpdate, margin);

        _transferOut(account, bAmount);

        emit RemoveMargin(account, bAmount);
    }

    // struct for temp use in trade function, to prevent stack too deep error
    struct TradeParams {
        int256 tradersNetVolume;
        int256 intrinsicValue;
        int256 timeValue;
        int256 multiplier;
        int256 curCost;
        int256 fee;
        int256 realizedCost;
        int256 protocolFee;
        int256 tvCost;
        int256 oraclePrice;
        int256 strikePrice;
        bool isCall;
        int256 changeOfNotionalValue;
    }

    function _trade(address account, int256 tradeVolume) internal _lock_ {
        (
            int256 totalDynamicEquity,
            int256 minPoolRequiredMargin,
            int256 timePrice
        ) = _updateSymbolPricesAndFundingRates();

        (
            IPTokenOption.Position memory position,
            bool positionUpdate,
            int256 margin
        ) = _settleTraderFundingFee(account);

        TradeParams memory params;

        params.tvCost = _queryTradePMM((tradeVolume * _governanceData.symbolMultiplier()) / ONE, timePrice);
        _symbol.quote_balance_offset += params.tvCost;

        params.tradersNetVolume = _symbol.tradersNetVolume;
        params.intrinsicValue = _symbol.intrinsicValue;
        params.timeValue = _symbol.timeValue;
        params.multiplier = _governanceData.symbolMultiplier();
        params.curCost =
            (((tradeVolume * params.intrinsicValue) / ONE) * params.multiplier) /
            ONE +
            params.tvCost;
        params.fee = (params.curCost.abs() * _governanceData.symbolFeeRatio()) / ONE;
        params.oraclePrice = getOraclePrice();
        params.strikePrice = _symbol.strikePrice;
        params.isCall = _symbol.isCall;
        params.changeOfNotionalValue =
            (((((params.tradersNetVolume + tradeVolume).abs() - params.tradersNetVolume.abs()) *
                params.oraclePrice) / ONE) * params.multiplier) /
            ONE;

        if (!(position.volume >= 0 && tradeVolume >= 0) && !(position.volume <= 0 && tradeVolume <= 0)) {
            int256 absVolume = position.volume.abs();
            int256 absTradeVolume = tradeVolume.abs();
            if (absVolume <= absTradeVolume) {
                // previous position is totally closed
                params.realizedCost = (params.curCost * absVolume) / absTradeVolume + position.cost;
            } else {
                // previous position is partially closed
                params.realizedCost = (position.cost * absTradeVolume) / absVolume + params.curCost;
            }
        }

        minPoolRequiredMargin +=
            (params.changeOfNotionalValue *
                _dynamicInitialMarginRatio(params.oraclePrice, params.strikePrice, params.isCall) *
                10) /
            ONE;

        position.volume += tradeVolume;
        position.cost += params.curCost - params.realizedCost;
        position.lastCumulativeDeltaFundingRate = _symbol.cumulativeDeltaFundingRate;
        position.lastCumulativePremiumFundingRate = _symbol.cumulativePremiumFundingRate;
        margin -= params.fee + params.realizedCost;
        positionUpdate = true;

        _symbol.tradersNetVolume += tradeVolume;
        _symbol.tradersNetCost += params.curCost - params.realizedCost;

        params.protocolFee = (params.fee * _governanceData.protocolFeeCollectRatio()) / ONE;
        _protocolFeeAccrued += params.protocolFee;
        _liquidity += params.fee - params.protocolFee + params.realizedCost;

        require(totalDynamicEquity >= minPoolRequiredMargin, "insuf liquidity");

        (bool initialMarginSafe, ) = _getTraderMarginStatus(position, margin);
        require(initialMarginSafe, "insuf margin");
        _updateTraderPortfolio(account, position, positionUpdate, margin);

        emit Trade(account, tradeVolume, params.intrinsicValue.itou(), params.timeValue.itou());
    }

    function _liquidate(address liquidator, address account) internal _lock_ {
        (, , int256 timePrice) = _updateSymbolPricesAndFundingRates();

        (IPTokenOption.Position memory position, , int256 margin) = _settleTraderFundingFee(account);

        (, bool maintenanceMarginSafe) = _getTraderMarginStatus(position, margin);
        require(!maintenanceMarginSafe, "cant liq");

        int256 netEquity = margin;
        if (position.volume != 0) {
            int256 tvCost = _queryTradePMM(
                (-position.volume * _governanceData.symbolMultiplier()) / ONE,
                timePrice
            );
            _symbol.quote_balance_offset += tvCost;
            _symbol.tradersNetVolume -= position.volume;
            _symbol.tradersNetCost -= position.cost;
            int256 curCost = (((-position.volume * _symbol.intrinsicValue) / ONE) *
                _governanceData.symbolMultiplier()) /
                ONE +
                tvCost;
            netEquity -= curCost + position.cost;
        }

        int256 reward;
        int256 minLiquidationReward = _governanceData.minLiquidationReward();
        int256 maxLiquidationReward = _governanceData.maxLiquidationReward();

        if (netEquity <= minLiquidationReward) {
            reward = minLiquidationReward;
        } else if (netEquity >= maxLiquidationReward) {
            reward = maxLiquidationReward;
        } else {
            reward =
                ((netEquity - minLiquidationReward) * _governanceData.liquidationCutRatio()) /
                ONE +
                minLiquidationReward;
        }

        _liquidity += margin - reward;

        IPTokenOption(_pTokenAddress).burn(account);
        _transferOut(liquidator, reward.itou());

        emit Liquidate(account, liquidator, reward.itou());
    }

    //================================================================================
    // Helpers
    //================================================================================

    function _updateVolatilityAndPrice(SignedData memory data) internal {
        IVolatilityOracle(_governanceData.symbolVolatilityAddress()).updateVolatilityAndPrice(
            data.timestamp,
            data.price,
            data.volatility,
            data.v,
            data.r,
            data.s
        );
    }

    function _updateDataFromChainlink() internal {
        IVolatilityChainlinkOracle chainlinkOracle = IVolatilityChainlinkOracle(
            _governanceData.symbolOracleAddress()
        );
        IVolatilityOracle(_governanceData.symbolVolatilityAddress()).updateFromChainlink(
            block.timestamp, // solhint-disable-line
            chainlinkOracle.latestVolatility(),
            chainlinkOracle.latestPrice()
        );
    }

    function getOraclePrice() internal view returns (int256) {
        return IVolatilityOracle(_governanceData.symbolVolatilityAddress()).price().utoi();
    }

    function getTvMidPrice()
        public
        view
        returns (
            int256,
            int256,
            int256
        )
    {
        int256 oraclePrice = getOraclePrice();
        int256 volatility = IVolatilityOracle(_governanceData.symbolVolatilityAddress()).volatility().utoi();
        (int256 timePrice, int256 delta) = OptionPricer.getEverlastingTimeValueAndDelta(
            oraclePrice,
            _symbol.strikePrice,
            volatility,
            _T
        );
        int256 midPrice = PmmPricer.getTvMidPrice(
            timePrice,
            ((_symbol.tradersNetVolume * _governanceData.symbolMultiplier()) / ONE),
            _liquidity + _symbol.quote_balance_offset,
            _symbol.K
        );
        return (timePrice, midPrice, delta);
    }

    function _queryTradePMM(int256 volume, int256 timePrice) internal view returns (int256 tvCost) {
        require(volume != 0, "inv Vol");
        tvCost = PmmPricer.queryTradePMM(
            timePrice,
            ((_symbol.tradersNetVolume * _governanceData.symbolMultiplier()) / ONE),
            volume,
            _liquidity + _symbol.quote_balance_offset,
            _symbol.K
        );
    }

    struct FundingParams {
        int256 oraclePrice;
        int256 ratePerSec1;
        int256 offset1;
        int256 ratePerSec2;
        int256 offset2;
    }

    function _updateSymbolPricesAndFundingRates()
        internal
        returns (
            int256 totalDynamicEquity,
            int256 minPoolRequiredMargin,
            int256 timePrice
        )
    {
        uint256 preTimestamp = _lastTimestamp;
        uint256 curTimestamp = block.timestamp;

        totalDynamicEquity = _liquidity;

        int256 oraclePrice = getOraclePrice();
        int256 intrinsicPrice = _symbol.isCall
            ? (oraclePrice - _symbol.strikePrice).max(0)
            : (_symbol.strikePrice - oraclePrice).max(0);
        (int256 timePrice, int256 midPrice, int256 delta) = getTvMidPrice();
        _symbol.intrinsicValue = intrinsicPrice;
        _symbol.timeValue = midPrice;
        if (_symbol.isCall && intrinsicPrice > 0) {
            delta = delta + ONE;
        } else if (!_symbol.isCall && intrinsicPrice > 0) {
            delta = delta - ONE;
        }

        if (_symbol.tradersNetVolume != 0) {
            int256 cost = (((_symbol.tradersNetVolume * (intrinsicPrice + midPrice)) / ONE) *
                _governanceData.symbolMultiplier()) / ONE;
            totalDynamicEquity -= cost - _symbol.tradersNetCost;
            int256 notionalValue = ((((_symbol.tradersNetVolume * oraclePrice) / ONE) *
                _governanceData.symbolMultiplier()) / ONE);
            minPoolRequiredMargin +=
                (notionalValue.abs() *
                    _dynamicInitialMarginRatio(oraclePrice, _symbol.strikePrice, _symbol.isCall) *
                    10) /
                ONE;
        }

        if (curTimestamp > preTimestamp && _liquidity > 0) {
            if (_symbol.tradersNetVolume != 0) {
                FundingParams memory params;
                params.oraclePrice = getOraclePrice();
                params.ratePerSec1 =
                    (((((((((((delta * _symbol.tradersNetVolume) / ONE) * params.oraclePrice) / ONE) *
                        params.oraclePrice) / ONE) * _governanceData.symbolMultiplier()) / ONE) *
                        _governanceData.symbolMultiplier()) / ONE) *
                        _governanceData.symbolDeltaFundingCoefficient()) /
                    totalDynamicEquity;
                params.offset1 = params.ratePerSec1 * int256(curTimestamp - preTimestamp);
                unchecked {
                    _symbol.cumulativeDeltaFundingRate += params.offset1;
                }

                params.ratePerSec2 =
                    (((_symbol.timeValue * _governanceData.symbolMultiplier()) / ONE) *
                        _premiumFundingCoefficient) /
                    ONE;
                params.offset2 = params.ratePerSec2 * int256(curTimestamp - preTimestamp);
                unchecked {
                    _symbol.cumulativePremiumFundingRate += params.offset2;
                }
            }
        }
        _lastTimestamp = curTimestamp;
    }

    function _getTraderPortfolio(address account)
        internal
        view
        returns (
            IPTokenOption.Position memory position,
            bool positionUpdate,
            int256 margin
        )
    {
        IPTokenOption pToken = IPTokenOption(_pTokenAddress);
        position = pToken.getPosition(account);
        margin = pToken.getMargin(account);
    }

    function _updateTraderPortfolio(
        address account,
        IPTokenOption.Position memory position,
        bool positionUpdate,
        int256 margin
    ) internal {
        IPTokenOption pToken = IPTokenOption(_pTokenAddress);
        if (positionUpdate) {
            pToken.updatePosition(account, position);
        }
        pToken.updateMargin(account, margin);
    }

    function _settleTraderFundingFee(address account)
        internal
        returns (
            IPTokenOption.Position memory position,
            bool positionUpdate,
            int256 margin
        )
    {
        (position, positionUpdate, margin) = _getTraderPortfolio(account);
        int256 funding;
        if (position.volume != 0) {
            int256 cumulativeDeltaFundingRate = _symbol.cumulativeDeltaFundingRate;
            int256 delta;
            unchecked {
                delta = cumulativeDeltaFundingRate - position.lastCumulativeDeltaFundingRate;
            }
            funding += (position.volume * delta) / ONE;

            position.lastCumulativeDeltaFundingRate = cumulativeDeltaFundingRate;

            int256 cumulativePremiumFundingRate = _symbol.cumulativePremiumFundingRate;
            unchecked {
                delta = cumulativePremiumFundingRate - position.lastCumulativePremiumFundingRate;
            }
            funding += (position.volume * delta) / ONE;
            position.lastCumulativePremiumFundingRate = cumulativePremiumFundingRate;

            positionUpdate = true;
        }
        if (funding != 0) {
            margin -= funding;
            _liquidity += funding;
        }
    }

    function _getTraderMarginStatus(IPTokenOption.Position memory position, int256 margin)
        internal
        view
        returns (bool, bool)
    {
        int256 totalDynamicMargin = margin;
        int256 totalMinInitialMargin;
        if (position.volume != 0) {
            int256 cost = (((position.volume * (_symbol.intrinsicValue + _symbol.timeValue)) / ONE) *
                _governanceData.symbolMultiplier()) / ONE;
            totalDynamicMargin += cost - position.cost;

            int256 oraclePrice = getOraclePrice();
            int256 notionalValue = ((((position.volume * oraclePrice) / ONE) *
                _governanceData.symbolMultiplier()) / ONE);
            totalMinInitialMargin +=
                (notionalValue.abs() *
                    _dynamicInitialMarginRatio(oraclePrice, _symbol.strikePrice, _symbol.isCall)) /
                ONE;
        }
        int256 totalMinMaintenanceMargin = (totalMinInitialMargin *
            _governanceData.maintenanceMarginRatio()) / _governanceData.initialMarginRatio();
        return (totalDynamicMargin >= totalMinInitialMargin, totalDynamicMargin >= totalMinMaintenanceMargin);
    }

    function _dynamicInitialMarginRatio(
        int256 spotPrice,
        int256 strikePrice,
        bool isCall
    ) internal view returns (int256) {
        if ((strikePrice >= spotPrice && !isCall) || (strikePrice <= spotPrice && isCall)) {
            return _governanceData.initialMarginRatio();
        } else {
            int256 OTMRatio = isCall
                ? (((strikePrice - spotPrice) * ONE) / strikePrice)
                : (((spotPrice - strikePrice) * ONE) / strikePrice);
            int256 dynInitialMarginRatio = (((ONE - OTMRatio * 3) * _governanceData.initialMarginRatio()) /
                ONE).max(MinInitialMarginRatio);
            return dynInitialMarginRatio;
        }
    }

    function _transferIn(address from, uint256 bAmount) internal returns (uint256) {
        IERC20 bToken = IERC20(_bTokenAddress);
        uint256 balance1 = bToken.balanceOf(address(this));
        bToken.safeTransferFrom(from, address(this), bAmount.rescale(18, _decimals));
        uint256 balance2 = bToken.balanceOf(address(this));
        return (balance2 - balance1).rescale(_decimals, 18);
    }

    function _transferOut(address to, uint256 bAmount) internal {
        uint256 amount = bAmount.rescale(18, _decimals);
        uint256 leftover = bAmount - amount.rescale(_decimals, 18);
        // leftover due to decimal precision is accrued to _protocolFeeAccrued
        _protocolFeeAccrued += leftover.utoi();
        IERC20(_bTokenAddress).safeTransfer(to, amount);
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IVolatilityChainlinkOracle {
    function latestVolatility() external view returns (uint256);

    function latestPrice() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IEverlastingOption {
    struct SymbolInfo {
        string symbol;
        int256 strikePrice;
        bool isCall;
        int256 cumulativeDeltaFundingRate;
        int256 intrinsicValue;
        int256 cumulativePremiumFundingRate;
        int256 timeValue;
        int256 tradersNetVolume;
        int256 tradersNetCost;
        int256 quote_balance_offset;
        uint256 K;
    }

    struct SignedData {
        uint256 timestamp;
        uint256 price;
        uint256 volatility;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    enum Side {
        FLAT,
        SHORT,
        LONG
    } // POOL STATUS 例如LONG代表池子LONG, 此时池子的baseBalance > baseTarget

    struct VirtualBalance {
        uint256 baseTarget;
        uint256 baseBalance;
        uint256 quoteTarget;
        uint256 quoteBalance;
        Side newSide;
    }

    event AddLiquidity(address indexed account, uint256 lShares, uint256 bAmount);

    event RemoveLiquidity(address indexed account, uint256 lShares, uint256 bAmount);

    event AddMargin(address indexed account, uint256 bAmount);

    event RemoveMargin(address indexed account, uint256 bAmount);

    event Trade(address indexed account, int256 tradeVolume, uint256 intrinsicValue, uint256 timeValue);

    event Liquidate(address indexed account, address indexed liquidator, uint256 reward);

    event ProtocolFeeCollection(address indexed collector, uint256 amount);

    function getAddresses()
        external
        view
        returns (
            address bTokenAddress,
            address lTokenAddress,
            address pTokenAddress,
            address liquidatorQualifierAddress,
            address protocolFeeCollector,
            address governanceData
        );

    function getSymbol() external view returns (SymbolInfo memory);

    function getLiquidity() external view returns (int256);

    function getLastTimestamp() external view returns (uint256);

    function getProtocolFeeAccrued() external view returns (int256);

    function collectProtocolFee() external;

    function addLiquidity(uint256 bAmount, SignedData memory price) external;

    function removeLiquidity(uint256 lShares, SignedData memory price) external;

    function addMargin(uint256 bAmount) external;

    function removeMargin(uint256 bAmount, SignedData memory price) external;

    function trade(int256 tradeVolume, SignedData memory price) external;

    function liquidate(address account, SignedData memory price) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./IERC20.sol";

interface ILTokenOption is IERC20 {
    function pool() external view returns (address);

    function setPool(address newPool) external;

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./IERC721.sol";

interface IPTokenOption is IERC721 {
    struct Position {
        // position volume, long is positive and short is negative
        int256 volume;
        // the cost the establish this position
        int256 cost;
        // the last cumulativeFundingRate since last funding settlement for this position
        // the overflow for this value in intended
        int256 lastCumulativeDeltaFundingRate;
        int256 lastCumulativePremiumFundingRate;
    }

    event UpdateMargin(address indexed owner, int256 amount);

    event UpdatePosition(
        address indexed owner,
        int256 volume,
        int256 cost,
        int256 lastCumulativeDiseqFundingRate,
        int256 lastCumulativeFundingRate2
    );

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function pool() external view returns (address);

    function totalMinted() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function setPool(address newPool) external;

    function getNumPositionHolders() external view returns (uint256);

    function exists(address owner) external view returns (bool);

    function getMargin(address owner) external view returns (int256);

    function updateMargin(address owner, int256 margin) external;

    function addMargin(address owner, int256 delta) external;

    function getPosition(address owner) external view returns (Position memory);

    function updatePosition(address owner, Position memory position) external;

    function mint(address owner) external;

    function burn(address owner) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    event Transfer(address indexed from, address indexed to, uint256 amount);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IOracleViewer {
    function getPrice() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IOracleWithUpdate {
    function getPrice() external returns (uint256);

    function updatePrice(
        uint256 timestamp,
        uint256 price,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IVolatilityOracle {
    function volatility() external view returns (uint256);

    function price() external view returns (uint256);

    function updateVolatilityAndPrice(
        uint256 timestamp_,
        uint256 price_,
        uint256 volatility_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external;

    function updateFromChainlink(
        uint256 timestamp_,
        uint256 price_,
        uint256 volatility_
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface ILiquidatorQualifier {
    function isQualifiedLiquidator(address liquidator) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

library SafeMath {
    uint256 constant UMAX = 2**255 - 1;
    int256 constant IMIN = -2**255;

    /// convert uint256 to int256
    function utoi(uint256 a) internal pure returns (int256) {
        require(a <= UMAX, "UIO");
        return int256(a);
    }

    /// convert int256 to uint256
    function itou(int256 a) internal pure returns (uint256) {
        require(a >= 0, "IUO");
        return uint256(a);
    }

    /// take abs of int256
    function abs(int256 a) internal pure returns (int256) {
        require(a != IMIN, "AO");
        return a >= 0 ? a : -a;
    }

    /// rescale a uint256 from base 10**decimals1 to 10**decimals2
    function rescale(
        uint256 a,
        uint256 decimals1,
        uint256 decimals2
    ) internal pure returns (uint256) {
        return decimals1 == decimals2 ? a : (a * (10**decimals2)) / (10**decimals1);
    }

    /// rescale a int256 from base 10**decimals1 to 10**decimals2
    function rescale(
        int256 a,
        uint256 decimals1,
        uint256 decimals2
    ) internal pure returns (int256) {
        return decimals1 == decimals2 ? a : (a * utoi(10**decimals2)) / utoi(10**decimals1);
    }

    /// reformat a uint256 to be a valid 10**decimals base value
    /// the reformatted value is still in 10**18 base
    function reformat(uint256 a, uint256 decimals) internal pure returns (uint256) {
        return decimals == 18 ? a : rescale(rescale(a, 18, decimals), decimals, 18);
    }

    /// reformat a int256 to be a valid 10**decimals base value
    /// the reformatted value is still in 10**18 base
    function reformat(int256 a, uint256 decimals) internal pure returns (int256) {
        return decimals == 18 ? a : rescale(rescale(a, 18, decimals), decimals, 18);
    }

    /// ceiling value away from zero, return a valid 10**decimals base value, but still in 10**18 based
    function ceil(int256 a, uint256 decimals) internal pure returns (int256) {
        if (reformat(a, decimals) == a) {
            return a;
        } else {
            int256 b = rescale(a, 18, decimals);
            b += a > 0 ? int256(1) : int256(-1);
            return rescale(b, decimals, 18);
        }
    }

    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient = a / b;
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = x / 2 + 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
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

import "../interface/IERC20.sol";
import "./Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) - value;
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
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IGovernanceData {
    function initialMarginRatio() external view returns (int256);

    function maintenanceMarginRatio() external view returns (int256);

    function minLiquidationReward() external view returns (int256);

    function maxLiquidationReward() external view returns (int256);

    function liquidationCutRatio() external view returns (int256);

    function protocolFeeCollectRatio() external view returns (int256);

    function symbolOracleAddress() external view returns (address);

    function symbolVolatilityAddress() external view returns (address);

    function symbolMultiplier() external view returns (int256);

    function symbolFeeRatio() external view returns (int256);

    function symbolFeeRatioOTM() external view returns (int256);

    function symbolDeltaFundingCoefficient() external view returns (int256);

    function getParameters()
        external
        view
        returns (
            int256,
            int256,
            int256,
            int256,
            int256,
            int256
        );
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import {DecimalMath} from "../library/DecimalMath.sol";
import {PMMCurve} from "../library/PMMCurve.sol";
import {SafeMath} from "../library/SafeMath.sol";
import "../interface/IEverlastingOption.sol";

/**
 * @title Pricing
 * @author Deri Protocol
 *
 * @notice Parapara Pricing model
 */
contract PMMPricing {
    using SafeMath for uint256;
    using SafeMath for int256;

    function getTvMidPrice(
        int256 timePrice,
        int256 deltaB,
        int256 equity,
        uint256 K
    ) external pure returns (int256) {
        if (equity <= 0) {
            return timePrice;
        }
        IEverlastingOption.Side side = deltaB == 0
            ? IEverlastingOption.Side.FLAT
            : (deltaB > 0 ? IEverlastingOption.Side.SHORT : IEverlastingOption.Side.LONG);
        IEverlastingOption.VirtualBalance memory updateBalance = getExpectedTargetExt(
            side,
            equity.itou(),
            timePrice.itou(),
            deltaB.abs().itou(),
            K
        );
        uint256 midPrice = getMidPrice(updateBalance, timePrice.itou(), K);
        return midPrice.utoi();
    }

    function queryTradePMM(
        int256 timePrice,
        int256 deltaB,
        int256 volume,
        int256 equity,
        uint256 K
    ) external pure returns (int256) {
        IEverlastingOption.Side side = deltaB == 0
            ? IEverlastingOption.Side.FLAT
            : (deltaB > 0 ? IEverlastingOption.Side.SHORT : IEverlastingOption.Side.LONG);
        IEverlastingOption.VirtualBalance memory updateBalance = getExpectedTargetExt(
            side,
            equity.itou(),
            timePrice.itou(),
            deltaB.abs().itou(),
            K
        );
        uint256 deltaQuote;
        int256 tvCost;
        if (volume >= 0) {
            deltaQuote = _queryBuyBaseToken(updateBalance, timePrice.itou(), K, volume.itou());
            tvCost = deltaQuote.utoi();
        } else {
            deltaQuote = _querySellBaseToken(updateBalance, timePrice.itou(), K, (-volume).itou());
            tvCost = -(deltaQuote.utoi());
        }
        return tvCost;
    }

    // ============ Helper functions ============
    function _expectedTargetHelperWhenBiased(
        IEverlastingOption.Side side,
        uint256 quoteBalance,
        uint256 price,
        uint256 deltaB,
        uint256 _K_
    ) internal pure returns (IEverlastingOption.VirtualBalance memory updateBalance) {
        if (side == IEverlastingOption.Side.SHORT) {
            (updateBalance.baseTarget, updateBalance.quoteTarget) = PMMCurve._RegressionTargetWhenShort(
                quoteBalance,
                price,
                deltaB,
                _K_
            );
            updateBalance.baseBalance = updateBalance.baseTarget - deltaB;
            updateBalance.quoteBalance = quoteBalance;
            updateBalance.newSide = IEverlastingOption.Side.SHORT;
        } else if (side == IEverlastingOption.Side.LONG) {
            (updateBalance.baseTarget, updateBalance.quoteTarget) = PMMCurve._RegressionTargetWhenLong(
                quoteBalance,
                price,
                deltaB,
                _K_
            );
            updateBalance.baseBalance = updateBalance.baseTarget + deltaB;
            updateBalance.quoteBalance = quoteBalance;
            updateBalance.newSide = IEverlastingOption.Side.LONG;
        }
    }

    function _expectedTargetHelperWhenBalanced(uint256 quoteBalance, uint256 price)
        internal
        pure
        returns (IEverlastingOption.VirtualBalance memory updateBalance)
    {
        uint256 baseTarget = DecimalMath.divFloor(quoteBalance, price);
        updateBalance.baseTarget = baseTarget;
        updateBalance.baseBalance = baseTarget;
        updateBalance.quoteTarget = quoteBalance;
        updateBalance.quoteBalance = quoteBalance;
        updateBalance.newSide = IEverlastingOption.Side.FLAT;
    }

    function getExpectedTargetExt(
        IEverlastingOption.Side side,
        uint256 quoteBalance,
        uint256 price,
        uint256 deltaB,
        uint256 _K_
    ) public pure returns (IEverlastingOption.VirtualBalance memory) {
        if (side == IEverlastingOption.Side.FLAT) {
            return _expectedTargetHelperWhenBalanced(quoteBalance, price);
        } else {
            return _expectedTargetHelperWhenBiased(side, quoteBalance, price, deltaB, _K_);
        }
    }

    function getMidPrice(
        IEverlastingOption.VirtualBalance memory updateBalance,
        uint256 oraclePrice,
        uint256 K
    ) public pure returns (uint256) {
        if (updateBalance.newSide == IEverlastingOption.Side.LONG) {
            uint256 R = DecimalMath.divFloor(
                (updateBalance.quoteTarget * updateBalance.quoteTarget) / updateBalance.quoteBalance,
                updateBalance.quoteBalance
            );
            R = DecimalMath.ONE - K + (DecimalMath.mul(K, R));
            return DecimalMath.divFloor(oraclePrice, R);
        } else {
            uint256 R = DecimalMath.divFloor(
                (updateBalance.baseTarget * updateBalance.baseTarget) / updateBalance.baseBalance,
                updateBalance.baseBalance
            );
            R = DecimalMath.ONE - K + (DecimalMath.mul(K, R));
            return DecimalMath.mul(oraclePrice, R);
        }
    }

    function _sellHelperRAboveOne(
        uint256 sellBaseAmount,
        uint256 K,
        uint256 price,
        uint256 baseTarget,
        uint256 baseBalance,
        uint256 quoteTarget
    )
        internal
        pure
        returns (
            uint256 receiveQuote,
            IEverlastingOption.Side newSide,
            uint256 newDeltaB
        )
    {
        uint256 backToOnePayBase = baseTarget - baseBalance;

        // case 2: R>1
        // complex case, R status depends on trading amount
        if (sellBaseAmount < backToOnePayBase) {
            // case 2.1: R status do not change
            receiveQuote = PMMCurve._RAboveSellBaseToken(price, K, sellBaseAmount, baseBalance, baseTarget);
            newSide = IEverlastingOption.Side.SHORT;
            newDeltaB = backToOnePayBase - sellBaseAmount;
            uint256 backToOneReceiveQuote = PMMCurve._RAboveSellBaseToken(
                price,
                K,
                backToOnePayBase,
                baseBalance,
                baseTarget
            );
            if (receiveQuote > backToOneReceiveQuote) {
                // [Important corner case!] may enter this branch when some precision problem happens. And consequently contribute to negative spare quote amount
                // to make sure spare quote>=0, mannually set receiveQuote=backToOneReceiveQuote
                receiveQuote = backToOneReceiveQuote;
            }
        } else if (sellBaseAmount == backToOnePayBase) {
            // case 2.2: R status changes to ONE
            receiveQuote = PMMCurve._RAboveSellBaseToken(price, K, backToOnePayBase, baseBalance, baseTarget);
            newSide = IEverlastingOption.Side.FLAT;
            newDeltaB = 0;
        } else {
            // case 2.3: R status changes to BELOW_ONE
            {
                receiveQuote =
                    PMMCurve._RAboveSellBaseToken(price, K, backToOnePayBase, baseBalance, baseTarget) +
                    (PMMCurve._ROneSellBaseToken(price, K, sellBaseAmount - backToOnePayBase, quoteTarget));
            }
            newSide = IEverlastingOption.Side.LONG;
            newDeltaB = sellBaseAmount - backToOnePayBase;
            // newDeltaB = sellBaseAmount.sub(_POOL_MARGIN_ACCOUNT.SIZE)?
        }
    }

    function _querySellBaseToken(
        IEverlastingOption.VirtualBalance memory updateBalance,
        uint256 price,
        uint256 K,
        uint256 sellBaseAmount
    ) public pure returns (uint256 receiveQuote) {
        uint256 newDeltaB;
        IEverlastingOption.Side newSide;
        if (updateBalance.newSide == IEverlastingOption.Side.FLAT) {
            // case 1: R=1
            // R falls below one
            receiveQuote = PMMCurve._ROneSellBaseToken(price, K, sellBaseAmount, updateBalance.quoteTarget);
            newSide = IEverlastingOption.Side.LONG;
            newDeltaB = sellBaseAmount;
        } else if (updateBalance.newSide == IEverlastingOption.Side.SHORT) {
            (receiveQuote, newSide, newDeltaB) = _sellHelperRAboveOne(
                sellBaseAmount,
                K,
                price,
                updateBalance.baseTarget,
                updateBalance.baseBalance,
                updateBalance.quoteTarget
            );
        } else {
            // ACCOUNT._R_STATUS_() == IEverlastingOption.Side.LONG
            // case 3: R<1
            receiveQuote = PMMCurve._RBelowSellBaseToken(
                price,
                K,
                sellBaseAmount,
                updateBalance.quoteBalance,
                updateBalance.quoteTarget
            );
            newSide = IEverlastingOption.Side.LONG;
            newDeltaB = updateBalance.baseBalance - updateBalance.baseTarget + sellBaseAmount;
        }

        //        // count fees
        //        if (newSide == IEverlastingOption.Side.FLAT) {
        //            newUpdateBalance = _expectedTargetHelperWhenBalanced(updateBalance.quoteBalance, price);
        //        } else {
        //            newUpdateBalance = _expectedTargetHelperWhenBiased(newSide, updateBalance.quoteBalance, price, newDeltaB, K);
        //        }

        return receiveQuote;
    }

    // to avoid stack too deep
    function _buyHelperRBelowOne(
        uint256 buyBaseAmount,
        uint256 K,
        uint256 price,
        uint256 backToOneReceiveBase,
        uint256 baseTarget,
        uint256 quoteTarget,
        uint256 quoteBalance
    )
        internal
        pure
        returns (
            uint256 payQuote,
            IEverlastingOption.Side newSide,
            uint256 newDeltaB
        )
    {
        // case 3: R<1
        // complex case, R status may change
        if (buyBaseAmount < backToOneReceiveBase) {
            // case 3.1: R status do not change
            // no need to check payQuote because spare base token must be greater than zero
            payQuote = PMMCurve._RBelowBuyBaseToken(price, K, buyBaseAmount, quoteBalance, quoteTarget);

            newSide = IEverlastingOption.Side.LONG;
            newDeltaB = backToOneReceiveBase - buyBaseAmount;
        } else if (buyBaseAmount == backToOneReceiveBase) {
            // case 3.2: R status changes to ONE
            payQuote = PMMCurve._RBelowBuyBaseToken(
                price,
                K,
                backToOneReceiveBase,
                quoteBalance,
                quoteTarget
            );
            newSide = IEverlastingOption.Side.FLAT;
            newDeltaB = 0;
        } else {
            // case 3.3: R status changes to ABOVE_ONE
            uint256 addQuote = PMMCurve._ROneBuyBaseToken(
                price,
                K,
                buyBaseAmount - backToOneReceiveBase,
                baseTarget
            );
            payQuote =
                PMMCurve._RBelowBuyBaseToken(price, K, backToOneReceiveBase, quoteBalance, quoteTarget) +
                addQuote;
            newSide = IEverlastingOption.Side.SHORT;
            newDeltaB = buyBaseAmount - backToOneReceiveBase;
        }
    }

    function _queryBuyBaseToken(
        IEverlastingOption.VirtualBalance memory updateBalance,
        uint256 price,
        uint256 K,
        uint256 buyBaseAmount
    ) public pure returns (uint256 payQuote) {
        uint256 newDeltaB;
        IEverlastingOption.Side newSide;
        {
            if (updateBalance.newSide == IEverlastingOption.Side.FLAT) {
                // case 1: R=1
                payQuote = PMMCurve._ROneBuyBaseToken(price, K, buyBaseAmount, updateBalance.baseTarget);
                newSide = IEverlastingOption.Side.SHORT;
                newDeltaB = buyBaseAmount;
            } else if (updateBalance.newSide == IEverlastingOption.Side.SHORT) {
                // case 2: R>1
                payQuote = PMMCurve._RAboveBuyBaseToken(
                    price,
                    K,
                    buyBaseAmount,
                    updateBalance.baseBalance,
                    updateBalance.baseTarget
                );
                newSide = IEverlastingOption.Side.SHORT;
                newDeltaB = updateBalance.baseTarget - updateBalance.baseBalance + buyBaseAmount;
            } else if (updateBalance.newSide == IEverlastingOption.Side.LONG) {
                (payQuote, newSide, newDeltaB) = _buyHelperRBelowOne(
                    buyBaseAmount,
                    K,
                    price,
                    updateBalance.baseBalance - updateBalance.baseTarget,
                    updateBalance.baseTarget,
                    updateBalance.quoteTarget,
                    updateBalance.quoteBalance
                );
            }
        }
        //        if (newSide == IEverlastingOption.Side.FLAT) {
        //            newUpdateBalance = _expectedTargetHelperWhenBalanced(updateBalance.quoteBalance, price);
        //        } else {
        //            newUpdateBalance = _expectedTargetHelperWhenBiased(newSide, updateBalance.quoteBalance, price, newDeltaB, K);
        //        }
        return payQuote;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IEverlastingOptionPricing {
    function getEverlastingTimeValue(
        int256 S,
        int256 K,
        int256 V,
        int256 T
    ) external pure returns (int256);

    function getEverlastingTimeValueAndDelta(
        int256 S,
        int256 K,
        int256 V,
        int256 T
    ) external pure returns (int256, int256);
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `operator` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed operator, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address);

    /**
     * @dev Returns the 'tokenId' owned by 'owner'
     *
     * Requirements:
     *
     *  - `owner` must exist
     */
    function getTokenId(address owner) external view returns (uint256);

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Gives permission to `operator` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address
     * clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address operator, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     *   by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first
     * that contract recipients are aware of the ERC721 protocol to prevent
     * tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token
     *   by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     *   {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     *   by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     *   {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

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
        assembly {
            size := extcodesize(account)
        }
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
        (bool success, ) = recipient.call{value: amount}("");
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

pragma solidity >=0.8.0 <0.9.0;

import {SafeMath} from "./SafeMath.sol";

/**
 * @title DecimalMath
 * @author Deri Protocol
 *
 * @notice Functions for fixed point number with 18 decimals
 */
library DecimalMath {
    using SafeMath for uint256;

    uint256 constant ONE = 10**18;

    function mul(uint256 target, uint256 d) internal pure returns (uint256) {
        return (target * d) / ONE;
    }

    function mulCeil(uint256 target, uint256 d) internal pure returns (uint256) {
        return (target * d).divCeil(ONE);
    }

    function divFloor(uint256 target, uint256 d) internal pure returns (uint256) {
        return (target * ONE) / d;
    }

    function divCeil(uint256 target, uint256 d) internal pure returns (uint256) {
        return (target * ONE).divCeil(d);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import {SafeMath} from "../library/SafeMath.sol";
import {DecimalMath} from "../library/DecimalMath.sol";
import {ParaMath} from "../library/ParaMath.sol";

/**
 * @title Pricing
 * @author Deri Protocol
 * @notice Parapara Pricing model
 */
library PMMCurve {
    using SafeMath for uint256;

    // ============ R = 1 cases ============
    // Solving the quadratic equation for trading
    function _ROneSellBaseToken(
        uint256 price,
        uint256 k,
        uint256 amount,
        uint256 targetQuoteTokenAmount
    ) internal pure returns (uint256 receiveQuoteToken) {
        uint256 Q2 = ParaMath._SolveQuadraticFunctionForTrade(
            targetQuoteTokenAmount,
            targetQuoteTokenAmount,
            DecimalMath.mul(price, amount),
            false,
            k
        );
        // in theory Q2 <= targetQuoteTokenAmount
        // however when amount is close to 0, precision problems may cause Q2 > targetQuoteTokenAmount
        return targetQuoteTokenAmount - Q2;
    }

    function _ROneBuyBaseToken(
        uint256 price,
        uint256 k,
        uint256 amount,
        uint256 targetBaseTokenAmount
    ) internal pure returns (uint256 payQuoteToken) {
        require(amount < targetBaseTokenAmount, "PARA_BASE_BALANCE_NOT_ENOUGH");
        uint256 B2 = targetBaseTokenAmount - amount;
        payQuoteToken = _RAboveIntegrate(price, k, targetBaseTokenAmount, targetBaseTokenAmount, B2);
        return payQuoteToken;
    }

    // ============ R < 1 cases ============

    function _RBelowSellBaseToken(
        uint256 price,
        uint256 k,
        uint256 amount,
        uint256 quoteBalance,
        uint256 targetQuoteAmount
    ) internal pure returns (uint256 receieQuoteToken) {
        uint256 Q2 = ParaMath._SolveQuadraticFunctionForTrade(
            targetQuoteAmount,
            quoteBalance,
            DecimalMath.mul(price, amount),
            false,
            k
        );
        return quoteBalance - Q2;
    }

    function _RBelowBuyBaseToken(
        uint256 price,
        uint256 k,
        uint256 amount,
        uint256 quoteBalance,
        uint256 targetQuoteAmount
    ) internal pure returns (uint256 payQuoteToken) {
        // Here we don't require amount less than some value
        // Because it is limited at upper function
        // See Trader.queryBuyBaseToken
        uint256 Q2 = ParaMath._SolveQuadraticFunctionForTrade(
            targetQuoteAmount,
            quoteBalance,
            DecimalMath.mulCeil(price, amount),
            true,
            k
        );
        return Q2 - quoteBalance;
    }

    // ============ R > 1 cases ============

    function _RAboveBuyBaseToken(
        uint256 price,
        uint256 k,
        uint256 amount,
        uint256 baseBalance,
        uint256 targetBaseAmount
    ) internal pure returns (uint256 payQuoteToken) {
        require(amount < baseBalance, "PARA_BASE_BALANCE_NOT_ENOUGH");
        uint256 B2 = baseBalance - amount;
        return _RAboveIntegrate(price, k, targetBaseAmount, baseBalance, B2);
    }

    function _RAboveSellBaseToken(
        uint256 price,
        uint256 k,
        uint256 amount,
        uint256 baseBalance,
        uint256 targetBaseAmount
    ) internal pure returns (uint256 receiveQuoteToken) {
        // here we don't require B1 <= targetBaseAmount
        // Because it is limited at upper function
        // See Trader.querySellBaseToken
        uint256 B1 = baseBalance + amount;
        return _RAboveIntegrate(price, k, targetBaseAmount, B1, baseBalance);
    }

    /*
        Update BaseTarget when AMM holds short position
        given oracle price
        B0 == Q0 / price
    */
    function _RegressionTargetWhenShort(
        uint256 Q1,
        uint256 price,
        uint256 deltaB,
        uint256 k
    ) internal pure returns (uint256 B0, uint256 Q0) {
        uint256 ideltaB = DecimalMath.mul(deltaB, price);
        require(
            Q1 * Q1 + 4 * ideltaB * ideltaB > 4 * ideltaB * Q1 + DecimalMath.mul(4 * k, ideltaB * ideltaB),
            "Unable to long under current pool status!"
        );
        uint256 ac = ideltaB * 4 * (Q1 - ideltaB + DecimalMath.mul(ideltaB, k));
        uint256 square = (Q1 * Q1) - ac;
        uint256 sqrt = square.sqrt();
        B0 = DecimalMath.divCeil(Q1 + sqrt, price * 2);
        Q0 = DecimalMath.mul(B0, price);
    }

    /*
        Update BaseTarget when AMM holds long position
        given oracle price
        B0 == Q0 / price
    */
    function _RegressionTargetWhenLong(
        uint256 Q1,
        uint256 price,
        uint256 deltaB,
        uint256 k
    ) internal pure returns (uint256 B0, uint256 Q0) {
        uint256 square = Q1 * Q1 + (DecimalMath.mul(deltaB, price) * (DecimalMath.mul(Q1, k) * 4));
        uint256 sqrt = square.sqrt();
        uint256 deltaQ = DecimalMath.divCeil(sqrt - Q1, k * 2);
        Q0 = Q1 + deltaQ;
        B0 = DecimalMath.divCeil(Q0, price);
    }

    function _RAboveIntegrate(
        uint256 price,
        uint256 k,
        uint256 B0,
        uint256 B1,
        uint256 B2
    ) internal pure returns (uint256) {
        return ParaMath._GeneralIntegrate(B0, B1, B2, price, k);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import {SafeMath} from "./SafeMath.sol";
import {DecimalMath} from "./DecimalMath.sol";

/**
 * @title ParaMath
 * @author Deri Protocol
 *
 * @notice Functions for complex calculating. Including ONE Integration and TWO Quadratic solutions
 */
library ParaMath {
    using SafeMath for uint256;

    /*
        Integrate dodo curve fron V1 to V2
        require V0>=V1>=V2>0
        res = (1-k)i(V1-V2)+ikV0*V0(1/V2-1/V1)
        let V1-V2=delta
        res = i*delta*(1-k+k(V0^2/V1/V2))
    */
    function _GeneralIntegrate(
        uint256 V0,
        uint256 V1,
        uint256 V2,
        uint256 i,
        uint256 k
    ) internal pure returns (uint256) {
        uint256 fairAmount = DecimalMath.mul(i, V1 - V2); // i*delta
        uint256 V0V0V1V2 = DecimalMath.divCeil((V0 * V0) / V1, V2);
        uint256 penalty = DecimalMath.mul(k, V0V0V1V2); // k(V0^2/V1/V2)
        return DecimalMath.mul(fairAmount, DecimalMath.ONE - k + penalty);
    }

    /*
        The same with integration expression above, we have:
        i*deltaB = (Q2-Q1)*(1-k+kQ0^2/Q1/Q2)
        Given Q1 and deltaB, solve Q2
        This is a quadratic function and the standard version is
        aQ2^2 + bQ2 + c = 0, where
        a=1-k
        -b=(1-k)Q1-kQ0^2/Q1+i*deltaB
        c=-kQ0^2
        and Q2=(-b+sqrt(b^2+4(1-k)kQ0^2))/2(1-k)
        note: another root is negative, abondan
        if deltaBSig=true, then Q2>Q1
        if deltaBSig=false, then Q2<Q1
    */
    function _SolveQuadraticFunctionForTrade(
        uint256 Q0,
        uint256 Q1,
        uint256 ideltaB,
        bool deltaBSig,
        uint256 k
    ) internal pure returns (uint256) {
        // calculate -b value and sig
        // -b = (1-k)Q1-kQ0^2/Q1+i*deltaB
        uint256 kQ02Q1 = (DecimalMath.mul(k, Q0) * Q0) / Q1; // kQ0^2/Q1
        uint256 b = DecimalMath.mul(DecimalMath.ONE - k, Q1); // (1-k)Q1
        bool minusbSig = true;
        if (deltaBSig) {
            b = b + ideltaB; // (1-k)Q1+i*deltaB
        } else {
            kQ02Q1 = kQ02Q1 + ideltaB; // i*deltaB+kQ0^2/Q1
        }
        if (b >= kQ02Q1) {
            b = b - kQ02Q1;
            minusbSig = true;
        } else {
            b = kQ02Q1 - b;
            minusbSig = false;
        }

        // calculate sqrt
        uint256 squareRoot = DecimalMath.mul((DecimalMath.ONE - k) * 4, DecimalMath.mul(k, Q0) * Q0); // 4(1-k)kQ0^2
        squareRoot = (b * b + squareRoot).sqrt(); // sqrt(b*b+4(1-k)kQ0*Q0)

        // final res
        uint256 denominator = (DecimalMath.ONE - k) * 2; // 2(1-k)
        uint256 numerator;
        if (minusbSig) {
            numerator = b + squareRoot;
        } else {
            numerator = squareRoot - b;
        }
        if (deltaBSig) {
            return DecimalMath.divFloor(numerator, denominator);
        } else {
            return DecimalMath.divCeil(numerator, denominator);
        }
    }

    /*
        Start from the integration function
        i*deltaB = (Q2-Q1)*(1-k+kQ0^2/Q1/Q2)
        Assume Q2=Q0, Given Q1 and deltaB, solve Q0
        let fairAmount = i*deltaB
    */
    function _SolveQuadraticFunctionForTarget(
        uint256 V1,
        uint256 k,
        uint256 fairAmount
    ) internal pure returns (uint256 V0) {
        // V0 = V1+V1*(sqrt-1)/2k
        uint256 sqrt = DecimalMath.divCeil(DecimalMath.mul(k, fairAmount) * 4, V1);
        sqrt = ((sqrt + DecimalMath.ONE) * DecimalMath.ONE).sqrt();
        uint256 premium = DecimalMath.divCeil(sqrt - DecimalMath.ONE, k * 2);
        // V0 is greater than or equal to V1 according to the solution
        return DecimalMath.mul(V1, DecimalMath.ONE + premium);
    }

    /*
        Update BaseTarget when AMM holds short position
        given oracle price
        B0 == Q0 / price
    */
    //    function _RegressionTargetWhenShort(
    //        uint256 Q1,
    //        uint256 price,
    //        uint256 deltaB,
    //        uint256 k
    //    )
    //        internal pure returns (uint256 B0,  uint256 Q0)
    //    {
    //        uint256 denominator = DecimalMath.mul(DecimalMath.ONE * 2, DecimalMath.ONE + k.sqrt());
    //        uint256 edgePrice = DecimalMath.divCeil(Q1, denominator);
    //        require(k < edgePrice, "Unable to long under current pool status!");
    //        uint256 ideltaB = DecimalMath.mul(deltaB, price);
    //        uint256 ac = ideltaB * 4 * (Q1 - ideltaB + (DecimalMath.mul(ideltaB,k)));
    //        uint256 square = (Q1 * Q1) - ac;
    //        uint256 sqrt = square.sqrt();
    //        B0 = DecimalMath.divCeil(Q1 + sqrt, price * 2);
    //        Q0 = DecimalMath.mul(B0, price);
    //    }

    /*
        Update BaseTarget when AMM holds long position
        given oracle price
        B0 == Q0 / price
    */
    //    function _RegressionTargetWhenLong(
    //        uint256 Q1,
    //        uint256 price,
    //        uint256 deltaB,
    //        uint256 k
    //    )
    //       internal pure returns (uint256 B0, uint256 Q0)
    //    {
    //        uint256 square = Q1 * Q1 + (DecimalMath.mul(deltaB, price) * (DecimalMath.mul(Q1, k) * 4));
    //        uint256 sqrt = square.sqrt();
    //        uint256 deltaQ = DecimalMath.divCeil(sqrt - Q1, k * 2);
    //        Q0 = Q1 + deltaQ;
    //        B0 = DecimalMath.divCeil(Q0, price);
    //    }
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