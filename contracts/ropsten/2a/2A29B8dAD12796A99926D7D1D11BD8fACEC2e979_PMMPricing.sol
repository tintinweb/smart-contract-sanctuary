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

    function getTvMidPrice(int256 timePrice, int256 deltaB, int256 equity, uint256 K) external pure returns (int256) {
        if (equity <=0) {
            return timePrice;
        }
        IEverlastingOption.Side side = deltaB == 0 ? IEverlastingOption.Side.FLAT : (deltaB > 0 ? IEverlastingOption.Side.SHORT : IEverlastingOption.Side.LONG);
        IEverlastingOption.VirtualBalance memory updateBalance = getExpectedTargetExt(
            side, equity.itou(), timePrice.itou(), deltaB.abs().itou(), K
        );
        uint256 midPrice = getMidPrice(updateBalance, timePrice.itou(), K);
        return midPrice.utoi();
    }

    function queryTradePMM(int256 timePrice, int256 deltaB, int256 volume, int256 equity, uint256 K) external pure returns (int256) {
        IEverlastingOption.Side side = deltaB == 0 ? IEverlastingOption.Side.FLAT : (deltaB > 0 ? IEverlastingOption.Side.SHORT : IEverlastingOption.Side.LONG);
        IEverlastingOption.VirtualBalance memory updateBalance = getExpectedTargetExt(
            side, equity.itou(), timePrice.itou(), deltaB.abs().itou(), K
        );
        uint256 deltaQuote;
        int256 tvCost;
        if (volume >= 0) {
            deltaQuote = _queryBuyBaseToken(
                updateBalance, timePrice.itou(), K, volume.itou()
            );
            tvCost = deltaQuote.utoi();
        } else {
            deltaQuote = _querySellBaseToken(
                updateBalance, timePrice.itou(), K, (-volume).itou()
            );
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
    ) internal pure returns (
        IEverlastingOption.VirtualBalance memory updateBalance
    ) {
        if (side == IEverlastingOption.Side.SHORT) {
            (updateBalance.baseTarget, updateBalance.quoteTarget) = PMMCurve._RegressionTargetWhenShort(quoteBalance, price, deltaB, _K_);
            updateBalance.baseBalance = updateBalance.baseTarget - deltaB;
            updateBalance.quoteBalance = quoteBalance;
            updateBalance.newSide = IEverlastingOption.Side.SHORT;
        }
        else if (side == IEverlastingOption.Side.LONG) {
            (updateBalance.baseTarget, updateBalance.quoteTarget) = PMMCurve._RegressionTargetWhenLong(quoteBalance, price, deltaB, _K_);
            updateBalance.baseBalance = updateBalance.baseTarget + deltaB;
            updateBalance.quoteBalance = quoteBalance;
            updateBalance.newSide = IEverlastingOption.Side.LONG;
        }
    }

    function _expectedTargetHelperWhenBalanced(uint256 quoteBalance, uint256 price) internal pure returns (
        IEverlastingOption.VirtualBalance memory updateBalance
    ) {
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
    )
    public
    pure
    returns (IEverlastingOption.VirtualBalance memory) {
        if (side == IEverlastingOption.Side.FLAT) {
            return _expectedTargetHelperWhenBalanced(quoteBalance, price);
        }
        else {
            return _expectedTargetHelperWhenBiased(
                side,
                quoteBalance,
                price,
                deltaB,
                _K_);
        }
    }


    function getMidPrice(IEverlastingOption.VirtualBalance memory updateBalance, uint256 oraclePrice, uint256 K) public pure returns (uint256) {
        if (updateBalance.newSide == IEverlastingOption.Side.LONG) {
            uint256 R =
            DecimalMath.divFloor(
                updateBalance.quoteTarget * updateBalance.quoteTarget / updateBalance.quoteBalance,
                updateBalance.quoteBalance
            );
            R = DecimalMath.ONE - K + (DecimalMath.mul(K, R));
            return DecimalMath.divFloor(oraclePrice, R);
        } else {
            uint256 R =
            DecimalMath.divFloor(
                updateBalance.baseTarget * updateBalance.baseTarget / updateBalance.baseBalance,
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
    ) internal pure returns (
        uint256 receiveQuote,
        IEverlastingOption.Side newSide,
        uint256 newDeltaB)
    {
        uint256 backToOnePayBase = baseTarget - baseBalance;

        // case 2: R>1
        // complex case, R status depends on trading amount
        if (sellBaseAmount < backToOnePayBase) {
            // case 2.1: R status do not change
            receiveQuote = PMMCurve._RAboveSellBaseToken(
                price,
                K,
                sellBaseAmount,
                baseBalance,
                baseTarget
            );
            newSide = IEverlastingOption.Side.SHORT;
            newDeltaB = backToOnePayBase - sellBaseAmount;
            uint256 backToOneReceiveQuote = PMMCurve._RAboveSellBaseToken(price, K, backToOnePayBase, baseBalance, baseTarget);
            if (receiveQuote > backToOneReceiveQuote) {
                // [Important corner case!] may enter this branch when some precision problem happens. And consequently contribute to negative spare quote amount
                // to make sure spare quote>=0, mannually set receiveQuote=backToOneReceiveQuote
                receiveQuote = backToOneReceiveQuote;
            }
        }
        else if (sellBaseAmount == backToOnePayBase) {
            // case 2.2: R status changes to ONE
            receiveQuote = PMMCurve._RAboveSellBaseToken(price, K, backToOnePayBase, baseBalance, baseTarget);
            newSide = IEverlastingOption.Side.FLAT;
            newDeltaB = 0;
        }
        else {
            // case 2.3: R status changes to BELOW_ONE
            {
                receiveQuote = PMMCurve._RAboveSellBaseToken(price, K, backToOnePayBase, baseBalance, baseTarget) + (
                    PMMCurve._ROneSellBaseToken(
                        price,
                        K,
                        sellBaseAmount - backToOnePayBase,
                        quoteTarget
                    )
                );
            }
            newSide = IEverlastingOption.Side.LONG;
            newDeltaB = sellBaseAmount - backToOnePayBase;
            // newDeltaB = sellBaseAmount.sub(_POOL_MARGIN_ACCOUNT.SIZE)?
        }
    }

    function _querySellBaseToken(IEverlastingOption.VirtualBalance memory updateBalance, uint256 price, uint256 K, uint256 sellBaseAmount)
    public pure
    returns (uint256 receiveQuote)
    {
        uint256 newDeltaB;
        IEverlastingOption.Side newSide;
        if (updateBalance.newSide == IEverlastingOption.Side.FLAT) {
            // case 1: R=1
            // R falls below one
            receiveQuote = PMMCurve._ROneSellBaseToken(price, K, sellBaseAmount, updateBalance.quoteTarget);
            newSide = IEverlastingOption.Side.LONG;
            newDeltaB = sellBaseAmount;
        }
        else if (updateBalance.newSide == IEverlastingOption.Side.SHORT) {
            (receiveQuote, newSide, newDeltaB) = _sellHelperRAboveOne(sellBaseAmount, K, price, updateBalance.baseTarget, updateBalance.baseBalance, updateBalance.quoteTarget);
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
    ) internal pure returns (
        uint256 payQuote,
        IEverlastingOption.Side newSide,
        uint256 newDeltaB
    ) {
        // case 3: R<1
        // complex case, R status may change
        if (buyBaseAmount < backToOneReceiveBase) {
            // case 3.1: R status do not change
            // no need to check payQuote because spare base token must be greater than zero
            payQuote = PMMCurve._RBelowBuyBaseToken(
                price,
                K,
                buyBaseAmount,
                quoteBalance,
                quoteTarget
            );

            newSide = IEverlastingOption.Side.LONG;
            newDeltaB = backToOneReceiveBase - buyBaseAmount;

        } else if (buyBaseAmount == backToOneReceiveBase) {
            // case 3.2: R status changes to ONE
            payQuote = PMMCurve._RBelowBuyBaseToken(price, K, backToOneReceiveBase, quoteBalance, quoteTarget);
            newSide = IEverlastingOption.Side.FLAT;
            newDeltaB = 0;
        } else {
            // case 3.3: R status changes to ABOVE_ONE
            uint256 addQuote = PMMCurve._ROneBuyBaseToken(
                price,
                K,
                buyBaseAmount - backToOneReceiveBase,
                baseTarget);
            payQuote = PMMCurve._RBelowBuyBaseToken(price, K, backToOneReceiveBase, quoteBalance, quoteTarget) + addQuote;
            newSide = IEverlastingOption.Side.SHORT;
            newDeltaB = buyBaseAmount - backToOneReceiveBase;
        }
    }


    function _queryBuyBaseToken(IEverlastingOption.VirtualBalance memory updateBalance, uint256 price, uint256 K, uint256 buyBaseAmount)
    public pure
    returns (uint256 payQuote)
    {
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
                (payQuote, newSide, newDeltaB) = _buyHelperRBelowOne(buyBaseAmount, K, price, updateBalance.baseBalance - updateBalance.baseTarget, updateBalance.baseTarget, updateBalance.quoteTarget, updateBalance.quoteBalance);
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
        return target * d / ONE;
    }

    function mulCeil(uint256 target, uint256 d)
        internal
        pure
        returns (uint256)
    {
        return (target * d).divCeil(ONE);
    }

    function divFloor(uint256 target, uint256 d)
        internal
        pure
        returns (uint256)
    {
        return target * ONE / d;
    }

    function divCeil(uint256 target, uint256 d)
        internal
        pure
        returns (uint256)
    {
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
    function _ROneSellBaseToken(uint256 price, uint256 k, uint256 amount, uint256 targetQuoteTokenAmount)
        internal
        pure
        returns (uint256 receiveQuoteToken)
    {
        uint256 Q2 =
            ParaMath._SolveQuadraticFunctionForTrade(
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

    function _ROneBuyBaseToken(uint256 price, uint256 k, uint256 amount, uint256 targetBaseTokenAmount)
        internal
        pure
        returns (uint256 payQuoteToken)
    {
        require(amount < targetBaseTokenAmount, "PARA_BASE_BALANCE_NOT_ENOUGH");
        uint256 B2 = targetBaseTokenAmount - amount;
        payQuoteToken = _RAboveIntegrate(
            price,
            k,
            targetBaseTokenAmount,
            targetBaseTokenAmount,
            B2
        );
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
        uint256 Q2 =
            ParaMath._SolveQuadraticFunctionForTrade(
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
        uint256 Q2 =
            ParaMath._SolveQuadraticFunctionForTrade(
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
        return _RAboveIntegrate(
            price, k, targetBaseAmount, baseBalance, B2
        );
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
    )
        internal pure returns (uint256 B0,  uint256 Q0)
    {
        uint256 ideltaB = DecimalMath.mul(deltaB, price);
        require( Q1*Q1 + 4*ideltaB*ideltaB > 4*ideltaB*Q1 + DecimalMath.mul(4*k, ideltaB*ideltaB), "Unable to long under current pool status!");
        uint256 ac = ideltaB * 4 * (Q1 - ideltaB + DecimalMath.mul(ideltaB,k));
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
    )
       internal pure returns (uint256 B0, uint256 Q0)
    {
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

library SafeMath {

    uint256 constant UMAX = 2**255 - 1;
    int256  constant IMIN = -2**255;

    /// convert uint256 to int256
    function utoi(uint256 a) internal pure returns (int256) {
        require(a <= UMAX, 'UIO');
        return int256(a);
    }

    /// convert int256 to uint256
    function itou(int256 a) internal pure returns (uint256) {
        require(a >= 0, 'IUO');
        return uint256(a);
    }

    /// take abs of int256
    function abs(int256 a) internal pure returns (int256) {
        require(a != IMIN, 'AO');
        return a >= 0 ? a : -a;
    }


    /// rescale a uint256 from base 10**decimals1 to 10**decimals2
    function rescale(uint256 a, uint256 decimals1, uint256 decimals2) internal pure returns (uint256) {
        return decimals1 == decimals2 ? a : a * (10 ** decimals2) / (10 ** decimals1);
    }

    /// rescale a int256 from base 10**decimals1 to 10**decimals2
    function rescale(int256 a, uint256 decimals1, uint256 decimals2) internal pure returns (int256) {
        return decimals1 == decimals2 ? a : a * utoi(10 ** decimals2) / utoi(10 ** decimals1);
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

import '../interface/IMigratable.sol';

interface IEverlastingOption is IMigratable {

    struct SymbolInfo {
        uint256 symbolId;
        string  symbol;
        address oracleAddress; // spot price oracle
        address volatilityAddress; // iv oracle
        int256  multiplier;
        int256  feeRatio;
        int256  strikePrice;
        bool    isCall;
        int256  deltaFundingCoefficient; // intrisic value
        int256  cumulativeDeltaFundingRate;
        int256  intrinsicValue;
        int256  cumulativePremiumFundingRate;
        int256  timeValue;
        int256  tradersNetVolume;
        int256  tradersNetCost;
        int256  quote_balance_offset;
        uint256 K;
    }

    struct SignedPrice {
        uint256 symbolId;
        uint256 timestamp;
        uint256 price;
        uint8   v;
        bytes32 r;
        bytes32 s;
    }

    enum Side {FLAT, SHORT, LONG} // POOL STATUS 例如LONG代表池子LONG, 此时池子的baseBalance > baseTarget

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

    event Trade(address indexed account, uint256 indexed symbolId, int256 tradeVolume, uint256 intrinsicValue, uint256 timeValue);

    event Liquidate(address indexed account, address indexed liquidator, uint256 reward);

    event ProtocolFeeCollection(address indexed collector, uint256 amount);

    function getParameters() external view returns (
        int256 minInitialMarginRatio,
        int256 minMaintenanceMarginRatio,
        int256 minLiquidationReward,
        int256 maxLiquidationReward,
        int256 liquidationCutRatio,
        int256 protocolFeeCollectRatio
    );

    function getAddresses() external view returns (
        address bTokenAddress,
        address lTokenAddress,
        address pTokenAddress,
        address liquidatorQualifierAddress,
        address protocolFeeCollector
    );

    function getSymbol(uint256 symbolId) external view returns (SymbolInfo memory);

    function getLiquidity() external view returns (int256);

    function getLastTimestamp() external view returns (uint256);

    function getProtocolFeeAccrued() external view returns (int256);

    function collectProtocolFee() external;

    function addSymbol(
        uint256 symbolId,
        string  memory symbol,
        uint256 strikePrice,
        bool    isCall,
        address oracleAddress,
        address volatilityAddress,
        uint256 multiplier,
        uint256 feeRatio,
        uint256 deltaFundingCoefficient,
        uint256 k
    ) external;

    function removeSymbol(uint256 symbolId) external;

    function toggleCloseOnly(uint256 symbolId) external;

    function setSymbolParameters(
        uint256 symbolId,
        address oracleAddress,
        address volatilityAddress,
        uint256 feeRatio,
        uint256 deltaFundingCoefficient,
        uint256 k
    ) external;

    function addLiquidity(uint256 bAmount, SignedPrice[] memory volatility) external;

    function removeLiquidity(uint256 lShares, SignedPrice[] memory volatility) external;

    function addMargin(uint256 bAmount) external;

    function removeMargin(uint256 bAmount, SignedPrice[] memory volatility) external;

    function trade(uint256 symbolId, int256 tradeVolume, SignedPrice[] memory volatility) external;

    function liquidate(address account, SignedPrice[] memory volatility) external;




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
        uint256 V0V0V1V2 = DecimalMath.divCeil(V0 * V0 / V1, V2);
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
        uint256 kQ02Q1 = DecimalMath.mul(k, Q0) * Q0 / Q1; // kQ0^2/Q1
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
        uint256 squareRoot =
            DecimalMath.mul(
                (DecimalMath.ONE - k) * 4,
                DecimalMath.mul(k, Q0) * Q0
            ); // 4(1-k)kQ0^2
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
        uint256 sqrt =
            DecimalMath.divCeil(DecimalMath.mul(k, fairAmount) *4, V1);
        sqrt = ((sqrt + DecimalMath.ONE) * DecimalMath.ONE).sqrt();
        uint256 premium =
            DecimalMath.divCeil(sqrt - DecimalMath.ONE, k * 2);
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IOwnable.sol';

interface IMigratable is IOwnable {

    event PrepareMigration(uint256 migrationTimestamp, address source, address target);

    event ExecuteMigration(uint256 migrationTimestamp, address source, address target);

    function migrationTimestamp() external view returns (uint256);

    function migrationDestination() external view returns (address);

    function prepareMigration(address target, uint256 graceDays) external;

    function approveMigration() external;

    function executeMigration(address source) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IOwnable {

    event ChangeController(address oldController, address newController);

    function controller() external view returns (address);

    function setNewController(address newController) external;

    function claimNewController() external;

}

