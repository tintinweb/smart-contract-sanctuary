// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./AMM.sol";
import "../lib/CappedPool.sol";
import "../lib/CombinedActionsGuard.sol";
import "../interfaces/IPriceProvider.sol";
import "../interfaces/IIVProvider.sol";
import "../interfaces/IBlackScholes.sol";
import "../interfaces/IIVGuesser.sol";
import "../interfaces/IPodOption.sol";
import "../interfaces/IOptionAMMPool.sol";
import "../interfaces/IFeePool.sol";
import "../interfaces/IConfigurationManager.sol";
import "../interfaces/IEmergencyStop.sol";
import "../interfaces/IFeePoolBuilder.sol";
import "../options/rewards/AaveIncentives.sol";

/**
 * Represents an Option specific single-sided AMM.
 *
 * The tokenA MUST be an PodOption contract implementation.
 * The tokenB is preferable to be an stable asset such as DAI or USDC.
 *
 * There are 4 external contracts used by this contract:
 *
 * - priceProvider: responsible for the the spot price of the option's underlying asset.
 * - priceMethod: responsible for the current price of the option itself.
 * - impliedVolatility: responsible for one of the priceMethod inputs:
 *     implied Volatility
 * - feePoolA and feePoolB: responsible for handling Liquidity providers fees.
 */

contract OptionAMMPool is AMM, IOptionAMMPool, CappedPool, CombinedActionsGuard, ReentrancyGuard, AaveIncentives {
    using SafeMath for uint256;
    uint256 public constant PRICING_DECIMALS = 18;
    uint256 private constant _SECONDS_IN_A_YEAR = 31536000;
    uint256 private constant _ORACLE_IV_WEIGHT = 3;
    uint256 private constant _POOL_IV_WEIGHT = 1;

    // External Contracts
    /**
     * @notice store globally accessed configurations
     */
    IConfigurationManager public immutable configurationManager;

    /**
     * @notice responsible for handling Liquidity providers fees of the token A
     */
    IFeePool public immutable feePoolA;

    /**
     * @notice responsible for handling Liquidity providers fees of the token B
     */
    IFeePool public immutable feePoolB;

    // Option Info
    struct PriceProperties {
        uint256 expiration;
        uint256 startOfExerciseWindow;
        uint256 strikePrice;
        address underlyingAsset;
        IPodOption.OptionType optionType;
        uint256 currentIV;
        int256 riskFree;
        uint256 initialIVGuess;
    }

    /**
     * @notice priceProperties are all information needed to handle the price discovery method
     * most of the properties will be used by getABPrice
     */
    PriceProperties public priceProperties;

    event TradeInfo(uint256 spotPrice, uint256 newIV);

    constructor(
        address _optionAddress,
        address _stableAsset,
        uint256 _initialIV,
        IConfigurationManager _configurationManager,
        IFeePoolBuilder _feePoolBuilder
    ) public AMM(_optionAddress, _stableAsset) CappedPool(_configurationManager) AaveIncentives(_configurationManager) {
        require(
            IPodOption(_optionAddress).exerciseType() == IPodOption.ExerciseType.EUROPEAN,
            "Pool: invalid exercise type"
        );

        feePoolA = _feePoolBuilder.buildFeePool(_stableAsset, 10, 3, address(this));
        feePoolB = _feePoolBuilder.buildFeePool(_stableAsset, 10, 3, address(this));

        priceProperties.currentIV = _initialIV;
        priceProperties.initialIVGuess = _initialIV;
        priceProperties.underlyingAsset = IPodOption(_optionAddress).underlyingAsset();
        priceProperties.expiration = IPodOption(_optionAddress).expiration();
        priceProperties.startOfExerciseWindow = IPodOption(_optionAddress).startOfExerciseWindow();
        priceProperties.optionType = IPodOption(_optionAddress).optionType();

        uint256 strikePrice = IPodOption(_optionAddress).strikePrice();
        uint256 strikePriceDecimals = IPodOption(_optionAddress).strikePriceDecimals();

        require(strikePriceDecimals <= PRICING_DECIMALS, "Pool: invalid strikePrice unit");
        require(tokenBDecimals() <= PRICING_DECIMALS, "Pool: invalid tokenB unit");
        uint256 strikePriceWithRightDecimals = strikePrice.mul(10**(PRICING_DECIMALS - strikePriceDecimals));

        priceProperties.strikePrice = strikePriceWithRightDecimals;
        configurationManager = IConfigurationManager(_configurationManager);
    }

    /**
     * @notice addLiquidity in any proportion of tokenA or tokenB
     *
     * @dev This function can only be called before option expiration
     *
     * @param amountOfA amount of TokenA to add
     * @param amountOfB amount of TokenB to add
     * @param owner address of the account that will have ownership of the liquidity
     */
    function addLiquidity(
        uint256 amountOfA,
        uint256 amountOfB,
        address owner
    ) external override capped(tokenB(), amountOfB) {
        require(msg.sender == configurationManager.getOptionHelper() || msg.sender == owner, "AMM: invalid sender");
        _nonCombinedActions();
        _beforeStartOfExerciseWindow();
        _emergencyStopCheck();
        _addLiquidity(amountOfA, amountOfB, owner);
        _emitTradeInfo();
    }

    /**
     * @notice removeLiquidity in any proportion of tokenA or tokenB
     *
     * @param amountOfA amount of TokenA to add
     * @param amountOfB amount of TokenB to add
     */
    function removeLiquidity(uint256 amountOfA, uint256 amountOfB) external override nonReentrant {
        _nonCombinedActions();
        _emergencyStopCheck();
        _removeLiquidity(amountOfA, amountOfB);
        _emitTradeInfo();
    }

    /**
     * @notice withdrawRewards claims reward from Aave and send to admin
     * @dev should only be called by the admin power
     *
     */
    function withdrawRewards() external override {
        require(msg.sender == configurationManager.owner(), "not owner");
        address[] memory assets = new address[](1);
        assets[0] = this.tokenB();

        _claimRewards(assets);

        address rewardAsset = _parseAddressFromUint(configurationManager.getParameter("REWARD_ASSET"));
        uint256 rewardsToSend = _rewardBalance();

        IERC20(rewardAsset).safeTransfer(msg.sender, rewardsToSend);
    }

    /**
     * @notice tradeExactAInput msg.sender is able to trade exact amount of token A in exchange for minimum
     * amount of token B and send the tokens B to the owner. After that, this function also updates the
     * priceProperties.* currentIV
     *
     * @dev initialIVGuess is a parameter for gas saving costs purpose. Instead of calculating the new implied volatility
     * out of thin ar, caller can help the Numeric Method achieve the result in less iterations with this parameter.
     * In order to know which guess the caller should use, call the getOptionTradeDetailsExactAInput first.
     *
     * @param exactAmountAIn exact amount of A token that will be transfer from msg.sender
     * @param minAmountBOut minimum acceptable amount of token B to transfer to owner
     * @param owner the destination address that will receive the token B
     * @param initialIVGuess The first guess that the Numeric Method (getPutIV / getCallIV) should use
     */
    function tradeExactAInput(
        uint256 exactAmountAIn,
        uint256 minAmountBOut,
        address owner,
        uint256 initialIVGuess
    ) external override nonReentrant returns (uint256) {
        _nonCombinedActions();
        _beforeStartOfExerciseWindow();
        _emergencyStopCheck();
        priceProperties.initialIVGuess = initialIVGuess;

        uint256 amountBOut = _tradeExactAInput(exactAmountAIn, minAmountBOut, owner);

        _emitTradeInfo();
        return amountBOut;
    }

    /**
     * @notice _tradeExactAOutput owner is able to receive exact amount of token A in exchange of a max
     * acceptable amount of token B transfer from the msg.sender. After that, this function also updates
     * the priceProperties.currentIV
     *
     * @dev initialIVGuess is a parameter for gas saving costs purpose. Instead of calculating the new implied volatility
     * out of thin ar, caller can help the Numeric Method achieve the result in less iterations with this parameter.
     * In order to know which guess the caller should use, call the getOptionTradeDetailsExactAOutput first.
     *
     * @param exactAmountAOut exact amount of token A that will be transfer to owner
     * @param maxAmountBIn maximum acceptable amount of token B to transfer from msg.sender
     * @param owner the destination address that will receive the token A
     * @param initialIVGuess The first guess that the Numeric Method (getPutIV / getCallIV) should use
     */
    function tradeExactAOutput(
        uint256 exactAmountAOut,
        uint256 maxAmountBIn,
        address owner,
        uint256 initialIVGuess
    ) external override nonReentrant returns (uint256) {
        _nonCombinedActions();
        _beforeStartOfExerciseWindow();
        _emergencyStopCheck();
        priceProperties.initialIVGuess = initialIVGuess;

        uint256 amountBIn = _tradeExactAOutput(exactAmountAOut, maxAmountBIn, owner);

        _emitTradeInfo();
        return amountBIn;
    }

    /**
     * @notice _tradeExactBInput msg.sender is able to trade exact amount of token B in exchange for minimum
     * amount of token A sent to the owner. After that, this function also updates the priceProperties.currentIV
     *
     * @dev initialIVGuess is a parameter for gas saving costs purpose. Instead of calculating the new implied volatility
     * out of thin ar, caller can help the Numeric Method achieve the result ini less iterations with this parameter.
     * In order to know which guess the caller should use, call the getOptionTradeDetailsExactBInput first.
     *
     * @param exactAmountBIn exact amount of token B that will be transfer from msg.sender
     * @param minAmountAOut minimum acceptable amount of token A to transfer to owner
     * @param owner the destination address that will receive the token A
     * @param initialIVGuess The first guess that the Numeric Method (getPutIV / getCallIV) should use
     */
    function tradeExactBInput(
        uint256 exactAmountBIn,
        uint256 minAmountAOut,
        address owner,
        uint256 initialIVGuess
    ) external override nonReentrant returns (uint256) {
        _nonCombinedActions();
        _beforeStartOfExerciseWindow();
        _emergencyStopCheck();
        priceProperties.initialIVGuess = initialIVGuess;

        uint256 amountAOut = _tradeExactBInput(exactAmountBIn, minAmountAOut, owner);

        _emitTradeInfo();
        return amountAOut;
    }

    /**
     * @notice _tradeExactBOutput owner is able to receive exact amount of token B in exchange of a max
     * acceptable amount of token A transfer from msg.sender. After that, this function also updates the
     * priceProperties.currentIV
     *
     * @dev initialIVGuess is a parameter for gas saving costs purpose. Instead of calculating the new implied volatility
     * out of thin ar, caller can help the Numeric Method achieve the result ini less iterations with this parameter.
     * In order to know which guess the caller should use, call the getOptionTradeDetailsExactBOutput first.
     *
     * @param exactAmountBOut exact amount of token B that will be transfer to owner
     * @param maxAmountAIn maximum acceptable amount of token A to transfer from msg.sender
     * @param owner the destination address that will receive the token B
     * @param initialIVGuess The first guess that the Numeric Method (getPutIV / getCallIV) should use
     */
    function tradeExactBOutput(
        uint256 exactAmountBOut,
        uint256 maxAmountAIn,
        address owner,
        uint256 initialIVGuess
    ) external override nonReentrant returns (uint256) {
        _nonCombinedActions();
        _beforeStartOfExerciseWindow();
        _emergencyStopCheck();
        priceProperties.initialIVGuess = initialIVGuess;

        uint256 amountAIn = _tradeExactBOutput(exactAmountBOut, maxAmountAIn, owner);

        _emitTradeInfo();
        return amountAIn;
    }

    /**
     * @notice getRemoveLiquidityAmounts external function that returns the available for rescue
     * amounts of token A, and token B based on the original position
     *
     * @param percentA percent of exposition of Token A to be removed
     * @param percentB percent of exposition of Token B to be removed
     * @param user Opening Value Factor by the moment of the deposit
     *
     * @return withdrawAmountA the total amount of token A that will be rescued
     * @return withdrawAmountB the total amount of token B that will be rescued plus fees
     */
    function getRemoveLiquidityAmounts(
        uint256 percentA,
        uint256 percentB,
        address user
    ) external override view returns (uint256 withdrawAmountA, uint256 withdrawAmountB) {
        (uint256 poolWithdrawAmountA, uint256 poolWithdrawAmountB) = _getRemoveLiquidityAmounts(
            percentA,
            percentB,
            user
        );
        (uint256 feeSharesA, uint256 feeSharesB) = _getAmountOfFeeShares(percentA, percentB, user);
        uint256 feesWithdrawAmountA = 0;
        uint256 feesWithdrawAmountB = 0;

        if (feeSharesA > 0) {
            (, feesWithdrawAmountA) = feePoolA.getWithdrawAmount(user, feeSharesA);
        }

        if (feeSharesB > 0) {
            (, feesWithdrawAmountB) = feePoolB.getWithdrawAmount(user, feeSharesB);
        }

        withdrawAmountA = poolWithdrawAmountA;
        withdrawAmountB = poolWithdrawAmountB.add(feesWithdrawAmountA).add(feesWithdrawAmountB);
        return (withdrawAmountA, withdrawAmountB);
    }

    /**
     * @notice getABPrice This function wll call internal function _getABPrice that will calculate the
     * calculate the ABPrice based on current market conditions. It calculates only the unit price AB, not taking in
     * consideration the slippage.
     *
     * @return ABPrice ABPrice is the unit price AB. Meaning how many units of B, buys 1 unit of A
     */
    function getABPrice() external override view returns (uint256 ABPrice) {
        return _getABPrice();
    }

    /**
     * @notice getAdjustedIV This function will return the adjustedIV, which is an average
     * between the pool IV and an external oracle IV
     *
     * @return adjustedIV The average between pool's IV and external oracle IV
     */
    function getAdjustedIV() external override view returns (uint256 adjustedIV) {
        return _getAdjustedIV(tokenA(), priceProperties.currentIV);
    }

    /**
     * @notice getOptionTradeDetailsExactAInput view function that simulates a trade, in order the preview
     * the amountBOut, the new implied volatility, that will be used as the initialIVGuess if caller wants to perform
     * a trade in sequence. Also returns the amount of Fees that will be payed to liquidity pools A and B.
     *
     * @param exactAmountAIn amount of token A that will by transfer from msg.sender to the pool
     *
     * @return amountBOut amount of B in exchange of the exactAmountAIn
     * @return newIV the new implied volatility that this trade will result
     * @return feesTokenA amount of fees of collected by token A
     * @return feesTokenB amount of fees of collected by token B
     */
    function getOptionTradeDetailsExactAInput(uint256 exactAmountAIn)
        external
        override
        view
        returns (
            uint256 amountBOut,
            uint256 newIV,
            uint256 feesTokenA,
            uint256 feesTokenB
        )
    {
        return _getOptionTradeDetailsExactAInput(exactAmountAIn);
    }

    /**
     * @notice getOptionTradeDetailsExactAOutput view function that simulates a trade, in order the preview
     * the amountBIn, the new implied volatility, that will be used as the initialIVGuess if caller wants to perform
     * a trade in sequence. Also returns the amount of Fees that will be payed to liquidity pools A and B.
     *
     * @param exactAmountAOut amount of token A that will by transfer from pool to the msg.sender/owner
     *
     * @return amountBIn amount of B that will be transfer from msg.sender to the pool
     * @return newIV the new implied volatility that this trade will result
     * @return feesTokenA amount of fees of collected by token A
     * @return feesTokenB amount of fees of collected by token B
     */
    function getOptionTradeDetailsExactAOutput(uint256 exactAmountAOut)
        external
        override
        view
        returns (
            uint256 amountBIn,
            uint256 newIV,
            uint256 feesTokenA,
            uint256 feesTokenB
        )
    {
        return _getOptionTradeDetailsExactAOutput(exactAmountAOut);
    }

    /**
     * @notice getOptionTradeDetailsExactBInput view function that simulates a trade, in order the preview
     * the amountAOut, the new implied volatility, that will be used as the initialIVGuess if caller wants to perform
     * a trade in sequence. Also returns the amount of Fees that will be payed to liquidity pools A and B.
     *
     * @param exactAmountBIn amount of token B that will by transfer from msg.sender to the pool
     *
     * @return amountAOut amount of A that will be transfer from contract to owner
     * @return newIV the new implied volatility that this trade will result
     * @return feesTokenA amount of fees of collected by token A
     * @return feesTokenB amount of fees of collected by token B
     */
    function getOptionTradeDetailsExactBInput(uint256 exactAmountBIn)
        external
        override
        view
        returns (
            uint256 amountAOut,
            uint256 newIV,
            uint256 feesTokenA,
            uint256 feesTokenB
        )
    {
        return _getOptionTradeDetailsExactBInput(exactAmountBIn);
    }

    /**
     * @notice getOptionTradeDetailsExactBOutput view function that simulates a trade, in order the preview
     * the amountAIn, the new implied volatility, that will be used as the initialIVGuess if caller wants to perform
     * a trade in sequence. Also returns the amount of Fees that will be payed to liquidity pools A and B.
     *
     * @param exactAmountBOut amount of token B that will by transfer from pool to the msg.sender/owner
     *
     * @return amountAIn amount of A that will be transfer from msg.sender to the pool
     * @return newIV the new implied volatility that this trade will result
     * @return feesTokenA amount of fees of collected by token A
     * @return feesTokenB amount of fees of collected by token B
     */
    function getOptionTradeDetailsExactBOutput(uint256 exactAmountBOut)
        external
        override
        view
        returns (
            uint256 amountAIn,
            uint256 newIV,
            uint256 feesTokenA,
            uint256 feesTokenB
        )
    {
        return _getOptionTradeDetailsExactBOutput(exactAmountBOut);
    }

    function _getOptionTradeDetailsExactAInput(uint256 exactAmountAIn)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 newABPrice, uint256 spotPrice, uint256 timeToMaturity) = _getPriceDetails();
        if (newABPrice == 0) {
            return (0, 0, 0, 0);
        }

        (uint256 poolAmountA, uint256 poolAmountB) = _getPoolAmounts(newABPrice);

        uint256 amountBOutPool = _getAmountBOutPool(exactAmountAIn, poolAmountA, poolAmountB);
        uint256 newTargetABPrice = _getNewTargetPrice(newABPrice, exactAmountAIn, amountBOutPool, TradeDirection.AB);

        // Prevents the pool to sell an option under the minimum target price,
        // because it causes an infinite loop when trying to calculate newIV
        if (!_isValidTargetPrice(newTargetABPrice, spotPrice)) {
            return (0, 0, 0, 0);
        }

        uint256 newIV = _getNewIV(newTargetABPrice, spotPrice, timeToMaturity);

        uint256 feesTokenA = feePoolA.getCollectable(amountBOutPool, poolAmountB);
        uint256 feesTokenB = feePoolB.getCollectable(amountBOutPool, poolAmountB);

        uint256 amountBOutUser = amountBOutPool.sub(feesTokenA).sub(feesTokenB);

        return (amountBOutUser, newIV, feesTokenA, feesTokenB);
    }

    function _getOptionTradeDetailsExactAOutput(uint256 exactAmountAOut)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 newABPrice, uint256 spotPrice, uint256 timeToMaturity) = _getPriceDetails();
        if (newABPrice == 0) {
            return (0, 0, 0, 0);
        }
        (uint256 poolAmountA, uint256 poolAmountB) = _getPoolAmounts(newABPrice);

        uint256 amountBInPool = _getAmountBInPool(exactAmountAOut, poolAmountA, poolAmountB);
        uint256 newTargetABPrice = _getNewTargetPrice(newABPrice, exactAmountAOut, amountBInPool, TradeDirection.BA);

        uint256 feesTokenA = feePoolA.getCollectable(amountBInPool, poolAmountB);
        uint256 feesTokenB = feePoolB.getCollectable(amountBInPool, poolAmountB);

        uint256 amountBInUser = amountBInPool.add(feesTokenA).add(feesTokenB);

        uint256 newIV = _getNewIV(newTargetABPrice, spotPrice, timeToMaturity);

        return (amountBInUser, newIV, feesTokenA, feesTokenB);
    }

    function _getOptionTradeDetailsExactBInput(uint256 exactAmountBIn)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 newABPrice, uint256 spotPrice, uint256 timeToMaturity) = _getPriceDetails();
        if (newABPrice == 0) {
            return (0, 0, 0, 0);
        }
        (uint256 poolAmountA, uint256 poolAmountB) = _getPoolAmounts(newABPrice);

        uint256 feesTokenA = feePoolA.getCollectable(exactAmountBIn, poolAmountB);
        uint256 feesTokenB = feePoolB.getCollectable(exactAmountBIn, poolAmountB);
        uint256 totalFees = feesTokenA.add(feesTokenB);

        uint256 poolBIn = exactAmountBIn.sub(totalFees);

        uint256 amountAOutPool = _getAmountAOutPool(poolBIn, poolAmountA, poolAmountB);
        uint256 newTargetABPrice = _getNewTargetPrice(newABPrice, amountAOutPool, poolBIn, TradeDirection.BA);

        uint256 newIV = _getNewIV(newTargetABPrice, spotPrice, timeToMaturity);

        return (amountAOutPool, newIV, feesTokenA, feesTokenB);
    }

    function _getOptionTradeDetailsExactBOutput(uint256 exactAmountBOut)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 newABPrice, uint256 spotPrice, uint256 timeToMaturity) = _getPriceDetails();
        if (newABPrice == 0) {
            return (0, 0, 0, 0);
        }
        (uint256 poolAmountA, uint256 poolAmountB) = _getPoolAmounts(newABPrice);

        uint256 feesTokenA = feePoolA.getCollectable(exactAmountBOut, poolAmountB);
        uint256 feesTokenB = feePoolB.getCollectable(exactAmountBOut, poolAmountB);
        uint256 totalFees = feesTokenA.add(feesTokenB);

        uint256 poolBOut = exactAmountBOut.add(totalFees);

        uint256 amountAInPool = _getAmountAInPool(poolBOut, poolAmountA, poolAmountB);
        uint256 newTargetABPrice = _getNewTargetPrice(newABPrice, amountAInPool, poolBOut, TradeDirection.AB);

        // Prevents the pool to sell an option under the minimum target price,
        // because it causes an infinite loop when trying to calculate newIV
        if (!_isValidTargetPrice(newTargetABPrice, spotPrice)) {
            return (0, 0, 0, 0);
        }

        uint256 newIV = _getNewIV(newTargetABPrice, spotPrice, timeToMaturity);

        return (amountAInPool, newIV, feesTokenA, feesTokenB);
    }

    function _getPriceDetails()
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 timeToMaturity = _getTimeToMaturityInYears();

        if (timeToMaturity == 0) {
            return (0, 0, 0);
        }

        uint256 spotPrice = _getSpotPrice(priceProperties.underlyingAsset, PRICING_DECIMALS);
        uint256 adjustedIV = _getAdjustedIV(tokenA(), priceProperties.currentIV);

        IBlackScholes pricingMethod = IBlackScholes(configurationManager.getPricingMethod());
        uint256 newABPrice;

        if (priceProperties.optionType == IPodOption.OptionType.PUT) {
            newABPrice = pricingMethod.getPutPrice(
                spotPrice,
                priceProperties.strikePrice,
                adjustedIV,
                timeToMaturity,
                priceProperties.riskFree
            );
        } else {
            newABPrice = pricingMethod.getCallPrice(
                spotPrice,
                priceProperties.strikePrice,
                adjustedIV,
                timeToMaturity,
                priceProperties.riskFree
            );
        }
        if (newABPrice == 0) {
            return (0, spotPrice, timeToMaturity);
        }
        uint256 newABPriceWithDecimals = newABPrice.div(10**(PRICING_DECIMALS.sub(tokenBDecimals())));
        return (newABPriceWithDecimals, spotPrice, timeToMaturity);
    }

    /**
     * @dev returns maturity in years with 18 decimals
     */
    function _getTimeToMaturityInYears() internal view returns (uint256) {
        if (block.timestamp >= priceProperties.expiration) {
            return 0;
        }
        return priceProperties.expiration.sub(block.timestamp).mul(10**PRICING_DECIMALS).div(_SECONDS_IN_A_YEAR);
    }

    function _getPoolAmounts(uint256 newABPrice) internal view returns (uint256 poolAmountA, uint256 poolAmountB) {
        (uint256 totalAmountA, uint256 totalAmountB) = _getPoolBalances();
        if (newABPrice != 0) {
            poolAmountA = _min(totalAmountA, totalAmountB.mul(10**uint256(tokenADecimals())).div(newABPrice));
            poolAmountB = _min(totalAmountB, totalAmountA.mul(newABPrice).div(10**uint256(tokenADecimals())));
        }
        return (poolAmountA, poolAmountB);
    }

    function _getABPrice() internal override view returns (uint256) {
        (uint256 newABPrice, , ) = _getPriceDetails();
        return newABPrice;
    }

    function _getSpotPrice(address asset, uint256 decimalsOutput) internal view returns (uint256) {
        IPriceProvider priceProvider = IPriceProvider(configurationManager.getPriceProvider());
        uint256 spotPrice = priceProvider.getAssetPrice(asset);
        uint256 spotPriceDecimals = priceProvider.getAssetDecimals(asset);
        uint256 diffDecimals;
        uint256 spotPriceWithRightPrecision;

        if (decimalsOutput <= spotPriceDecimals) {
            diffDecimals = spotPriceDecimals.sub(decimalsOutput);
            spotPriceWithRightPrecision = spotPrice.div(10**diffDecimals);
        } else {
            diffDecimals = decimalsOutput.sub(spotPriceDecimals);
            spotPriceWithRightPrecision = spotPrice.mul(10**diffDecimals);
        }
        return spotPriceWithRightPrecision;
    }

    function _getOracleIV(address optionAddress) internal view returns (uint256 normalizedOracleIV) {
        IIVProvider ivProvider = IIVProvider(configurationManager.getIVProvider());
        (, , uint256 oracleIV, uint256 ivDecimals) = ivProvider.getIV(optionAddress);
        uint256 diffDecimals;

        if (ivDecimals <= PRICING_DECIMALS) {
            diffDecimals = PRICING_DECIMALS.sub(ivDecimals);
        } else {
            diffDecimals = ivDecimals.sub(PRICING_DECIMALS);
        }
        return oracleIV.div(10**diffDecimals);
    }

    function _getAdjustedIV(address optionAddress, uint256 currentIV) internal view returns (uint256 adjustedIV) {
        uint256 oracleIV = _getOracleIV(optionAddress);

        adjustedIV = _ORACLE_IV_WEIGHT.mul(oracleIV).add(_POOL_IV_WEIGHT.mul(currentIV)).div(
            _POOL_IV_WEIGHT + _ORACLE_IV_WEIGHT
        );
    }

    function _getNewIV(
        uint256 newTargetABPrice,
        uint256 spotPrice,
        uint256 timeToMaturity
    ) internal view returns (uint256) {
        uint256 newTargetABPriceWithDecimals = newTargetABPrice.mul(10**(PRICING_DECIMALS.sub(tokenBDecimals())));
        uint256 newIV;
        IIVGuesser ivGuesser = IIVGuesser(configurationManager.getIVGuesser());
        if (priceProperties.optionType == IPodOption.OptionType.PUT) {
            (newIV, ) = ivGuesser.getPutIV(
                newTargetABPriceWithDecimals,
                priceProperties.initialIVGuess,
                spotPrice,
                priceProperties.strikePrice,
                timeToMaturity,
                priceProperties.riskFree
            );
        } else {
            (newIV, ) = ivGuesser.getCallIV(
                newTargetABPriceWithDecimals,
                priceProperties.initialIVGuess,
                spotPrice,
                priceProperties.strikePrice,
                timeToMaturity,
                priceProperties.riskFree
            );
        }
        return newIV;
    }

    /**
     * @dev After it gets the unit BlackScholes price, it applies slippage based on the minimum available in the pool
     * (returned by the _getPoolAmounts()) and the product constant curve.
     * @param amountBOutPool The exact amount of tokenB will leave the pool
     * @param poolAmountA The amount of A available for trade
     * @param poolAmountB The amount of B available for trade
     * @return amountAInPool The amount of tokenA(options) will enter the pool
     */
    function _getAmountAInPool(
        uint256 amountBOutPool,
        uint256 poolAmountA,
        uint256 poolAmountB
    ) internal pure returns (uint256 amountAInPool) {
        uint256 productConstant = poolAmountA.mul(poolAmountB);
        require(amountBOutPool < poolAmountB, "AMM: insufficient liquidity");
        amountAInPool = productConstant.div(poolAmountB.sub(amountBOutPool)).sub(poolAmountA);
    }

    /**
     * @dev After it gets the unit BlackScholes price, it applies slippage based on the minimum available in the pool
     * (returned by the _getPoolAmounts()) and the product constant curve.
     * @param amountBInPool The exact amount of tokenB will enter the pool
     * @param poolAmountA The amount of A available for trade
     * @param poolAmountB The amount of B available for trade
     * @return amountAOutPool The amount of tokenA(options) will leave the pool
     */
    function _getAmountAOutPool(
        uint256 amountBInPool,
        uint256 poolAmountA,
        uint256 poolAmountB
    ) internal pure returns (uint256 amountAOutPool) {
        uint256 productConstant = poolAmountA.mul(poolAmountB);
        amountAOutPool = poolAmountA.sub(productConstant.div(poolAmountB.add(amountBInPool)));
    }

    /**
     * @dev After it gets the unit BlackScholes price, it applies slippage based on the minimum available in the pool
     * (returned by the _getPoolAmounts()) and the product constant curve.
     * @param amountAOutPool The amount of tokenA(options) will leave the pool
     * @param poolAmountA The amount of A available for trade
     * @param poolAmountB The amount of B available for trade
     * @return amountBInPool The amount of tokenB will enter the pool
     */
    function _getAmountBInPool(
        uint256 amountAOutPool,
        uint256 poolAmountA,
        uint256 poolAmountB
    ) internal pure returns (uint256 amountBInPool) {
        uint256 productConstant = poolAmountA.mul(poolAmountB);
        require(amountAOutPool < poolAmountA, "AMM: insufficient liquidity");
        amountBInPool = productConstant.div(poolAmountA.sub(amountAOutPool)).sub(poolAmountB);
    }

    /**
     * @dev After it gets the unit BlackScholes price, it applies slippage based on the minimum available in the pool
     * (returned by the _getPoolAmounts()) and the product constant curve.
     * @param amountAInPool The exact amount of tokenA(options) will enter the pool
     * @param poolAmountA The amount of A available for trade
     * @param poolAmountB The amount of B available for trade
     * @return amountBOutPool The amount of tokenB will leave the pool
     */
    function _getAmountBOutPool(
        uint256 amountAInPool,
        uint256 poolAmountA,
        uint256 poolAmountB
    ) internal pure returns (uint256 amountBOutPool) {
        uint256 productConstant = poolAmountA.mul(poolAmountB);
        amountBOutPool = poolAmountB.sub(productConstant.div(poolAmountA.add(amountAInPool)));
    }

    /**
     * @dev Based on the tokensA and tokensB leaving or entering the pool, it is possible to calculate the new option
     * target price. That price will be used later to update the currentIV.
     * @param newABPrice calculated Black Scholes unit price (how many units of tokenB, to buy 1 tokenA(option))
     * @param amountA The amount of tokenA that will leave or enter the pool
     * @param amountB TThe amount of tokenB that will leave or enter the pool
     * @param tradeDirection The trade direction, if it is AB, means that tokenA will enter, and tokenB will leave.
     * @return newTargetPrice The new unit target price (how many units of tokenB, to buy 1 tokenA(option))
     */
    function _getNewTargetPrice(
        uint256 newABPrice,
        uint256 amountA,
        uint256 amountB,
        TradeDirection tradeDirection
    ) internal view returns (uint256 newTargetPrice) {
        (uint256 poolAmountA, uint256 poolAmountB) = _getPoolAmounts(newABPrice);
        if (tradeDirection == TradeDirection.AB) {
            newTargetPrice = poolAmountB.sub(amountB).mul(10**uint256(tokenADecimals())).div(poolAmountA.add(amountA));
        } else {
            newTargetPrice = poolAmountB.add(amountB).mul(10**uint256(tokenADecimals())).div(poolAmountA.sub(amountA));
        }
    }

    function _getTradeDetailsExactAInput(uint256 exactAmountAIn) internal override returns (TradeDetails memory) {
        (uint256 amountBOut, uint256 newIV, uint256 feesTokenA, uint256 feesTokenB) = _getOptionTradeDetailsExactAInput(
            exactAmountAIn
        );

        TradeDetails memory tradeDetails = TradeDetails(amountBOut, feesTokenA, feesTokenB, abi.encodePacked(newIV));
        return tradeDetails;
    }

    function _getTradeDetailsExactAOutput(uint256 exactAmountAOut) internal override returns (TradeDetails memory) {
        (uint256 amountBIn, uint256 newIV, uint256 feesTokenA, uint256 feesTokenB) = _getOptionTradeDetailsExactAOutput(
            exactAmountAOut
        );

        TradeDetails memory tradeDetails = TradeDetails(amountBIn, feesTokenA, feesTokenB, abi.encodePacked(newIV));
        return tradeDetails;
    }

    function _getTradeDetailsExactBInput(uint256 exactAmountBIn) internal override returns (TradeDetails memory) {
        (uint256 amountAOut, uint256 newIV, uint256 feesTokenA, uint256 feesTokenB) = _getOptionTradeDetailsExactBInput(
            exactAmountBIn
        );

        TradeDetails memory tradeDetails = TradeDetails(amountAOut, feesTokenA, feesTokenB, abi.encodePacked(newIV));
        return tradeDetails;
    }

    function _getTradeDetailsExactBOutput(uint256 exactAmountBOut) internal override returns (TradeDetails memory) {
        (uint256 amountAIn, uint256 newIV, uint256 feesTokenA, uint256 feesTokenB) = _getOptionTradeDetailsExactBOutput(
            exactAmountBOut
        );

        TradeDetails memory tradeDetails = TradeDetails(amountAIn, feesTokenA, feesTokenB, abi.encodePacked(newIV));
        return tradeDetails;
    }

    /**
     * @dev If a option is ITM, either PUTs or CALLs, the minimum price that it would cost is the difference between
     * the spot price and strike price. If the target price after applying slippage is above this minimum, the function
     * returns true.
     * @param newTargetPrice the new ABPrice after slippage (how many units of tokenB, to buy 1 option)
     * @param spotPrice current underlying asset spot price during this transaction
     * @return true if is a valid target price (above the minimum)
     */
    function _isValidTargetPrice(uint256 newTargetPrice, uint256 spotPrice) internal view returns (bool) {
        if (priceProperties.optionType == IPodOption.OptionType.PUT) {
            if (spotPrice < priceProperties.strikePrice) {
                return
                    newTargetPrice >
                    priceProperties.strikePrice.sub(spotPrice).div(10**PRICING_DECIMALS.sub(tokenBDecimals()));
            }
        } else {
            if (spotPrice > priceProperties.strikePrice) {
                return
                    newTargetPrice >
                    spotPrice.sub(priceProperties.strikePrice).div(10**PRICING_DECIMALS.sub(tokenBDecimals()));
            }
        }
        return true;
    }

    function _onAddLiquidity(UserDepositSnapshot memory _userDepositSnapshot, address owner) internal override {
        uint256 currentQuotesA = feePoolA.sharesOf(owner);
        uint256 currentQuotesB = feePoolB.sharesOf(owner);
        uint256 amountOfQuotesAToAdd = 0;
        uint256 amountOfQuotesBToAdd = 0;

        uint256 totalQuotesA = _userDepositSnapshot.tokenABalance.mul(10**FIMP_DECIMALS).div(_userDepositSnapshot.fImp);

        if (totalQuotesA > currentQuotesA) {
            amountOfQuotesAToAdd = totalQuotesA.sub(currentQuotesA);
        }

        uint256 totalQuotesB = _userDepositSnapshot.tokenBBalance.mul(10**FIMP_DECIMALS).div(_userDepositSnapshot.fImp);

        if (totalQuotesB > currentQuotesB) {
            amountOfQuotesBToAdd = totalQuotesB.sub(currentQuotesB);
        }

        feePoolA.mint(owner, amountOfQuotesAToAdd);
        feePoolB.mint(owner, amountOfQuotesBToAdd);
    }

    function _onRemoveLiquidity(
        uint256 percentA,
        uint256 percentB,
        address owner
    ) internal override {
        (uint256 amountOfSharesAToRemove, uint256 amountOfSharesBToRemove) = _getAmountOfFeeShares(
            percentA,
            percentB,
            owner
        );

        if (amountOfSharesAToRemove > 0) {
            feePoolA.withdraw(owner, amountOfSharesAToRemove);
        }
        if (amountOfSharesBToRemove > 0) {
            feePoolB.withdraw(owner, amountOfSharesBToRemove);
        }
    }

    function _getAmountOfFeeShares(
        uint256 percentA,
        uint256 percentB,
        address owner
    ) internal view returns (uint256, uint256) {
        uint256 currentSharesA = feePoolA.sharesOf(owner);
        uint256 currentSharesB = feePoolB.sharesOf(owner);

        uint256 amountOfSharesAToRemove = currentSharesA.mul(percentA).div(PERCENT_PRECISION);
        uint256 amountOfSharesBToRemove = currentSharesB.mul(percentB).div(PERCENT_PRECISION);

        return (amountOfSharesAToRemove, amountOfSharesBToRemove);
    }

    function _onTrade(TradeDetails memory tradeDetails) internal override {
        uint256 newIV = abi.decode(tradeDetails.params, (uint256));
        priceProperties.currentIV = newIV;

        IERC20(tokenB()).safeTransfer(address(feePoolA), tradeDetails.feesTokenA);
        IERC20(tokenB()).safeTransfer(address(feePoolB), tradeDetails.feesTokenB);
    }

    /**
     * @dev Check for functions which are only allowed to be executed
     * BEFORE start of exercise window.
     */
    function _beforeStartOfExerciseWindow() internal view {
        require(block.timestamp < priceProperties.startOfExerciseWindow, "Pool: exercise window has started");
    }

    function _emergencyStopCheck() private view {
        IEmergencyStop emergencyStop = IEmergencyStop(configurationManager.getEmergencyStop());
        require(
            !emergencyStop.isStopped(address(this)) &&
                !emergencyStop.isStopped(configurationManager.getPriceProvider()) &&
                !emergencyStop.isStopped(configurationManager.getPricingMethod()),
            "Pool: Pool is stopped"
        );
    }

    function _emitTradeInfo() private {
        uint256 spotPrice = _getSpotPrice(priceProperties.underlyingAsset, PRICING_DECIMALS);
        emit TradeInfo(spotPrice, priceProperties.currentIV);
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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../lib/RequiredDecimals.sol";
import "../interfaces/IAMM.sol";

/**
 * Represents a generalized contract for a single-sided AMM pair.
 *
 * That means is possible to add and remove liquidity in any proportion
 * at any time, even 0 in one of the sides.
 *
 * The AMM is constituted by 3 core functions: Add Liquidity, Remove liquidity and Trade.
 *
 * There are 4 possible trade types between the token pair (tokenA and tokenB):
 *
 * - ExactAInput:
 *     tokenA as an exact Input, meaning that the output tokenB is variable.
 *     it is important to have a slippage control of the minimum acceptable amount of tokenB in return
 * - ExactAOutput:
 *     tokenA as an exact Output, meaning that the input tokenB is variable.
 *     it is important to have a slippage control of the maximum acceptable amount of tokenB sent
 * - ExactBInput:
 *     tokenB as an exact Input, meaning that the output tokenA is variable.
 *     it is important to have a slippage control of the minimum acceptable amount of tokenA in return
 * - ExactBOutput:
 *     tokenB as an exact Output, meaning that the input tokenA is variable.
 *     it is important to have a slippage control of the maximum acceptable amount of tokenA sent
 *
 * Several functions are provided as virtual and must be overridden by the inheritor.
 *
 * - _getABPrice:
 *     function that will return the tokenA:tokenB price relation.
 *     How many units of tokenB in order to traded for 1 unit of tokenA.
 *     This price is represented in the same tokenB number of decimals.
 * - _onAddLiquidity:
 *     Executed after adding liquidity. Usually used for handling fees
 * - _onRemoveLiquidity:
 *     Executed after removing liquidity. Usually used for handling fees
 *
 *  Also, for which TradeType (E.g: ExactAInput) there are more two functions to override:

 * _getTradeDetails[$TradeType]:
 *   This function is responsible to return the TradeDetails struct, that contains basically the amount
 *   of the other token depending on the trade type. (E.g: ExactAInput => The TradeDetails will return the
 *   amount of B output).
 * _onTrade[$TradeType]:
 *    function that will be executed after UserDepositSnapshot updates and before
 *    token transfers. Usually used for handling fees and updating state at the inheritor.
 *
 */

abstract contract AMM is IAMM, RequiredDecimals {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /**
     * @dev The initial value for deposit factor (Fimp)
     */
    uint256 public constant INITIAL_FIMP = 10**27;

    /**
     * @notice The Fimp's precision (aka number of decimals)
     */
    uint256 public constant FIMP_DECIMALS = 27;

    /**
     * @notice The percent's precision
     */
    uint256 public constant PERCENT_PRECISION = 100;

    /**
     * @dev Address of the token A
     */
    address private _tokenA;

    /**
     * @dev Address of the token B
     */
    address private _tokenB;

    /**
     * @dev Token A number of decimals
     */
    uint8 private _tokenADecimals;

    /**
     * @dev Token B number of decimals
     */
    uint8 private _tokenBDecimals;

    /**
     * @notice The total balance of token A in the pool not counting the amortization
     */
    uint256 public deamortizedTokenABalance;

    /**
     * @notice The total balance of token B in the pool not counting the amortization
     */
    uint256 public deamortizedTokenBBalance;

    /**
     * @notice It contains the token A original balance, token B original balance,
     * and the Open Value Factor (Fimp) at the time of the deposit.
     */
    struct UserDepositSnapshot {
        uint256 tokenABalance;
        uint256 tokenBBalance;
        uint256 fImp;
    }

    struct Mult {
        uint256 AA; // How much A Im getting for rescuing one A that i've deposited
        uint256 AB; // How much B Im getting for rescuing one A that i've deposited
        uint256 BA; // How much A Im getting for rescuing one B that i've deposited
        uint256 BB; // How much B Im getting for rescuing one B that i've deposited
    }

    struct TradeDetails {
        uint256 amount;
        uint256 feesTokenA;
        uint256 feesTokenB;
        bytes params;
    }
    /**
     * @dev Tracks the UserDepositSnapshot struct of each user.
     * It contains the token A original balance, token B original balance,
     * and the Open Value Factor (Fimp) at the time of the deposit.
     */
    mapping(address => UserDepositSnapshot) private _userSnapshots;

    /** Events */
    event AddLiquidity(address indexed caller, address indexed owner, uint256 amountA, uint256 amountB);
    event RemoveLiquidity(address indexed caller, uint256 amountA, uint256 amountB);
    event TradeExactAInput(address indexed caller, address indexed owner, uint256 exactAmountAIn, uint256 amountBOut);
    event TradeExactBInput(address indexed caller, address indexed owner, uint256 exactAmountBIn, uint256 amountAOut);
    event TradeExactAOutput(address indexed caller, address indexed owner, uint256 amountBIn, uint256 exactAmountAOut);
    event TradeExactBOutput(address indexed caller, address indexed owner, uint256 amountAIn, uint256 exactAmountBOut);

    constructor(address tokenA, address tokenB) public {
        require(Address.isContract(tokenA), "AMM: token a is not a contract");
        require(Address.isContract(tokenB), "AMM: token b is not a contract");
        require(tokenA != tokenB, "AMM: tokens must differ");

        _tokenA = tokenA;
        _tokenB = tokenB;

        _tokenADecimals = tryDecimals(IERC20(tokenA));
        _tokenBDecimals = tryDecimals(IERC20(tokenB));
    }

    /**
     * @dev Returns the address for tokenA
     */
    function tokenA() public override view returns (address) {
        return _tokenA;
    }

    /**
     * @dev Returns the address for tokenB
     */
    function tokenB() public override view returns (address) {
        return _tokenB;
    }

    /**
     * @dev Returns the decimals for tokenA
     */
    function tokenADecimals() public override view returns (uint8) {
        return _tokenADecimals;
    }

    /**
     * @dev Returns the decimals for tokenB
     */
    function tokenBDecimals() public override view returns (uint8) {
        return _tokenBDecimals;
    }

    /**
     * @notice getPoolBalances external function that returns the current pool balance of token A and token B
     *
     * @return totalTokenA balanceOf this contract of token A
     * @return totalTokenB balanceOf this contract of token B
     */
    function getPoolBalances() external view returns (uint256 totalTokenA, uint256 totalTokenB) {
        return _getPoolBalances();
    }

    /**
     * @notice getUserDepositSnapshot external function that User original balance of token A,
     * token B and the Opening Value * * Factor (Fimp) at the moment of the liquidity added
     *
     * @param user address to check the balance info
     *
     * @return tokenAOriginalBalance balance of token A by the moment of deposit
     * @return tokenBOriginalBalance balance of token B by the moment of deposit
     * @return fImpUser value of the Opening Value Factor by the moment of the deposit
     */
    function getUserDepositSnapshot(address user)
        external
        view
        returns (
            uint256 tokenAOriginalBalance,
            uint256 tokenBOriginalBalance,
            uint256 fImpUser
        )
    {
        return _getUserDepositSnapshot(user);
    }

    /**
     * @notice _addLiquidity in any proportion of tokenA or tokenB
     *
     * @dev The inheritor contract should implement _getABPrice and _onAddLiquidity functions
     *
     * @param amountOfA amount of TokenA to add
     * @param amountOfB amount of TokenB to add
     * @param owner address of the account that will have ownership of the liquidity
     */
    function _addLiquidity(
        uint256 amountOfA,
        uint256 amountOfB,
        address owner
    ) internal {
        _isValidAddress(owner);
        // Get Pool Balances
        (uint256 totalTokenA, uint256 totalTokenB) = _getPoolBalances();

        bool hasNoLiquidity = deamortizedTokenABalance == 0 && deamortizedTokenBBalance == 0;
        uint256 fImpOpening;
        uint256 userAmountToStoreTokenA = amountOfA;
        uint256 userAmountToStoreTokenB = amountOfB;

        if (hasNoLiquidity) {
            // In the first liquidity, is necessary add both tokens
            bool bothTokensHigherThanZero = amountOfA > 0 && amountOfB > 0;
            require(bothTokensHigherThanZero, "AMM: invalid first liquidity");

            fImpOpening = INITIAL_FIMP;

            deamortizedTokenABalance = amountOfA;
            deamortizedTokenBBalance = amountOfB;
        } else {
            // Get ABPrice
            uint256 ABPrice = _getABPrice();
            require(ABPrice > 0, "AMM: option price zero");

            // Calculate the Pool's Value Factor (Fimp)
            fImpOpening = _getFImpOpening(
                totalTokenA,
                totalTokenB,
                ABPrice,
                deamortizedTokenABalance,
                deamortizedTokenBBalance
            );

            (userAmountToStoreTokenA, userAmountToStoreTokenB) = _getUserBalanceToStore(
                amountOfA,
                amountOfB,
                fImpOpening,
                _userSnapshots[owner]
            );

            // Update Deamortized Balance of the pool for each token;
            deamortizedTokenABalance = deamortizedTokenABalance.add(amountOfA.mul(10**FIMP_DECIMALS).div(fImpOpening));
            deamortizedTokenBBalance = deamortizedTokenBBalance.add(amountOfB.mul(10**FIMP_DECIMALS).div(fImpOpening));
        }

        // Update the User Balances for each token and with the Pool Factor previously calculated
        UserDepositSnapshot memory userDepositSnapshot = UserDepositSnapshot(
            userAmountToStoreTokenA,
            userAmountToStoreTokenB,
            fImpOpening
        );
        _userSnapshots[owner] = userDepositSnapshot;

        _onAddLiquidity(_userSnapshots[owner], owner);

        // Update Total Balance of the pool for each token
        if (amountOfA > 0) {
            IERC20(_tokenA).safeTransferFrom(msg.sender, address(this), amountOfA);
        }

        if (amountOfB > 0) {
            IERC20(_tokenB).safeTransferFrom(msg.sender, address(this), amountOfB);
        }

        emit AddLiquidity(msg.sender, owner, amountOfA, amountOfB);
    }

    /**
     * @notice _removeLiquidity in any proportion of tokenA or tokenB
     * @dev The inheritor contract should implement _getABPrice and _onRemoveLiquidity functions
     *
     * @param percentA proportion of the exposition of the original tokenA that want to be removed
     * @param percentB proportion of the exposition of the original tokenB that want to be removed
     */
    function _removeLiquidity(uint256 percentA, uint256 percentB) internal {
        (uint256 userTokenABalance, uint256 userTokenBBalance, uint256 userFImp) = _getUserDepositSnapshot(msg.sender);
        require(percentA <= 100 && percentB <= 100, "AMM: forbidden percent");

        uint256 originalBalanceAToReduce = percentA.mul(userTokenABalance).div(PERCENT_PRECISION);
        uint256 originalBalanceBToReduce = percentB.mul(userTokenBBalance).div(PERCENT_PRECISION);

        // Get Pool Balances
        (uint256 totalTokenA, uint256 totalTokenB) = _getPoolBalances();

        // Get ABPrice
        uint256 ABPrice = _getABPrice();

        // Calculate the Pool's Value Factor (Fimp)
        uint256 fImpOpening = _getFImpOpening(
            totalTokenA,
            totalTokenB,
            ABPrice,
            deamortizedTokenABalance,
            deamortizedTokenBBalance
        );

        // Calculate Multipliers
        Mult memory multipliers = _getMultipliers(totalTokenA, totalTokenB, fImpOpening);

        // Update User balance
        _userSnapshots[msg.sender].tokenABalance = userTokenABalance.sub(originalBalanceAToReduce);
        _userSnapshots[msg.sender].tokenBBalance = userTokenBBalance.sub(originalBalanceBToReduce);

        // Update deamortized balance
        deamortizedTokenABalance = deamortizedTokenABalance.sub(
            originalBalanceAToReduce.mul(10**FIMP_DECIMALS).div(userFImp)
        );
        deamortizedTokenBBalance = deamortizedTokenBBalance.sub(
            originalBalanceBToReduce.mul(10**FIMP_DECIMALS).div(userFImp)
        );

        // Calculate amount to send
        (uint256 withdrawAmountA, uint256 withdrawAmountB) = _getWithdrawAmounts(
            originalBalanceAToReduce,
            originalBalanceBToReduce,
            userFImp,
            multipliers
        );

        if (withdrawAmountA > totalTokenA) {
            withdrawAmountA = totalTokenA;
        }

        if (withdrawAmountB > totalTokenB) {
            withdrawAmountB = totalTokenB;
        }

        _onRemoveLiquidity(percentA, percentB, msg.sender);

        // Transfers / Update
        if (withdrawAmountA > 0) {
            IERC20(_tokenA).safeTransfer(msg.sender, withdrawAmountA);
        }

        if (withdrawAmountB > 0) {
            IERC20(_tokenB).safeTransfer(msg.sender, withdrawAmountB);
        }

        emit RemoveLiquidity(msg.sender, withdrawAmountA, withdrawAmountB);
    }

    /**
     * @notice _tradeExactAInput msg.sender is able to trade exact amount of token A in exchange for minimum
     * amount of token B sent by the contract to the owner
     * @dev The inheritor contract should implement _getTradeDetailsExactAInput and _onTradeExactAInput functions
     * _getTradeDetailsExactAInput should return tradeDetails struct format
     *
     * @param exactAmountAIn exact amount of A token that will be transfer from msg.sender
     * @param minAmountBOut minimum acceptable amount of token B to transfer to owner
     * @param owner the destination address that will receive the token B
     */
    function _tradeExactAInput(
        uint256 exactAmountAIn,
        uint256 minAmountBOut,
        address owner
    ) internal returns (uint256) {
        _isValidInput(exactAmountAIn);
        _isValidAddress(owner);
        TradeDetails memory tradeDetails = _getTradeDetailsExactAInput(exactAmountAIn);
        uint256 amountBOut = tradeDetails.amount;
        require(amountBOut > 0, "AMM: invalid amountBOut");
        require(amountBOut >= minAmountBOut, "AMM: slippage not acceptable");

        _onTrade(tradeDetails);

        IERC20(_tokenA).safeTransferFrom(msg.sender, address(this), exactAmountAIn);
        IERC20(_tokenB).safeTransfer(owner, amountBOut);

        emit TradeExactAInput(msg.sender, owner, exactAmountAIn, amountBOut);
        return amountBOut;
    }

    /**
     * @notice _tradeExactAOutput owner is able to receive exact amount of token A in exchange of a max
     * acceptable amount of token B sent by the msg.sender to the contract
     *
     * @dev The inheritor contract should implement _getTradeDetailsExactAOutput and _onTradeExactAOutput functions
     * _getTradeDetailsExactAOutput should return tradeDetails struct format
     *
     * @param exactAmountAOut exact amount of token A that will be transfer to owner
     * @param maxAmountBIn maximum acceptable amount of token B to transfer from msg.sender
     * @param owner the destination address that will receive the token A
     */
    function _tradeExactAOutput(
        uint256 exactAmountAOut,
        uint256 maxAmountBIn,
        address owner
    ) internal returns (uint256) {
        _isValidInput(maxAmountBIn);
        _isValidAddress(owner);
        TradeDetails memory tradeDetails = _getTradeDetailsExactAOutput(exactAmountAOut);
        uint256 amountBIn = tradeDetails.amount;
        require(amountBIn > 0, "AMM: invalid amountBIn");
        require(amountBIn <= maxAmountBIn, "AMM: slippage not acceptable");
        _onTrade(tradeDetails);

        IERC20(_tokenB).safeTransferFrom(msg.sender, address(this), amountBIn);
        IERC20(_tokenA).safeTransfer(owner, exactAmountAOut);

        emit TradeExactAOutput(msg.sender, owner, amountBIn, exactAmountAOut);
        return amountBIn;
    }

    /**
     * @notice _tradeExactBInput msg.sender is able to trade exact amount of token B in exchange for minimum
     * amount of token A sent by the contract to the owner
     *
     * @dev The inheritor contract should implement _getTradeDetailsExactBInput and _onTradeExactBInput functions
     * _getTradeDetailsExactBInput should return tradeDetails struct format
     *
     * @param exactAmountBIn exact amount of token B that will be transfer from msg.sender
     * @param minAmountAOut minimum acceptable amount of token A to transfer to owner
     * @param owner the destination address that will receive the token A
     */
    function _tradeExactBInput(
        uint256 exactAmountBIn,
        uint256 minAmountAOut,
        address owner
    ) internal returns (uint256) {
        _isValidInput(exactAmountBIn);
        _isValidAddress(owner);
        TradeDetails memory tradeDetails = _getTradeDetailsExactBInput(exactAmountBIn);
        uint256 amountAOut = tradeDetails.amount;
        require(amountAOut > 0, "AMM: invalid amountAOut");
        require(amountAOut >= minAmountAOut, "AMM: slippage not acceptable");

        _onTrade(tradeDetails);

        IERC20(_tokenB).safeTransferFrom(msg.sender, address(this), exactAmountBIn);
        IERC20(_tokenA).safeTransfer(owner, amountAOut);

        emit TradeExactBInput(msg.sender, owner, exactAmountBIn, amountAOut);
        return amountAOut;
    }

    /**
     * @notice _tradeExactBOutput owner is able to receive exact amount of token B from the contract in exchange of a
     * max acceptable amount of token A sent by the msg.sender to the contract.
     *
     * @dev The inheritor contract should implement _getTradeDetailsExactBOutput and _onTradeExactBOutput functions
     * _getTradeDetailsExactBOutput should return tradeDetails struct format
     *
     * @param exactAmountBOut exact amount of token B that will be transfer to owner
     * @param maxAmountAIn maximum acceptable amount of token A to transfer from msg.sender
     * @param owner the destination address that will receive the token B
     */
    function _tradeExactBOutput(
        uint256 exactAmountBOut,
        uint256 maxAmountAIn,
        address owner
    ) internal returns (uint256) {
        _isValidInput(maxAmountAIn);
        _isValidAddress(owner);
        TradeDetails memory tradeDetails = _getTradeDetailsExactBOutput(exactAmountBOut);
        uint256 amountAIn = tradeDetails.amount;
        require(amountAIn > 0, "AMM: invalid amountAIn");
        require(amountAIn <= maxAmountAIn, "AMM: slippage not acceptable");

        _onTrade(tradeDetails);

        IERC20(_tokenA).safeTransferFrom(msg.sender, address(this), amountAIn);
        IERC20(_tokenB).safeTransfer(owner, exactAmountBOut);

        emit TradeExactBOutput(msg.sender, owner, amountAIn, exactAmountBOut);
        return amountAIn;
    }

    /**
     * @notice _getFImpOpening Auxiliary function that calculate the Opening Value Factor Fimp
     *
     * @param _totalTokenA total contract balance of token A
     * @param _totalTokenB total contract balance of token B
     * @param _ABPrice Unit price AB, meaning, how many units of token B could buy 1 unit of token A
     * @param _deamortizedTokenABalance contract deamortized balance of token A
     * @param _deamortizedTokenBBalance contract deamortized balance of token B
     * @return fImpOpening Opening Value Factor Fimp
     */
    function _getFImpOpening(
        uint256 _totalTokenA,
        uint256 _totalTokenB,
        uint256 _ABPrice,
        uint256 _deamortizedTokenABalance,
        uint256 _deamortizedTokenBBalance
    ) internal view returns (uint256) {
        uint256 numerator;
        uint256 denominator;
        {
            numerator = _totalTokenA.mul(_ABPrice).div(10**uint256(_tokenADecimals)).add(_totalTokenB).mul(
                10**FIMP_DECIMALS
            );
        }
        {
            denominator = _deamortizedTokenABalance.mul(_ABPrice).div(10**uint256(_tokenADecimals)).add(
                _deamortizedTokenBBalance
            );
        }

        return numerator.div(denominator);
    }

    /**
     * @notice _getPoolBalances external function that returns the current pool balance of token A and token B
     *
     * @return totalTokenA balanceOf this contract of token A
     * @return totalTokenB balanceOf this contract of token B
     */
    function _getPoolBalances() internal view returns (uint256 totalTokenA, uint256 totalTokenB) {
        totalTokenA = IERC20(_tokenA).balanceOf(address(this));
        totalTokenB = IERC20(_tokenB).balanceOf(address(this));
    }

    /**
     * @notice _getUserDepositSnapshot internal function that User original balance of token A,
     * token B and the Opening Value * * Factor (Fimp) at the moment of the liquidity added
     *
     * @param user address of the user that want to check the balance
     *
     * @return tokenAOriginalBalance balance of token A by the moment of deposit
     * @return tokenBOriginalBalance balance of token B by the moment of deposit
     * @return fImpOriginal value of the Opening Value Factor by the moment of the deposit
     */
    function _getUserDepositSnapshot(address user)
        internal
        view
        returns (
            uint256 tokenAOriginalBalance,
            uint256 tokenBOriginalBalance,
            uint256 fImpOriginal
        )
    {
        tokenAOriginalBalance = _userSnapshots[user].tokenABalance;
        tokenBOriginalBalance = _userSnapshots[user].tokenBBalance;
        fImpOriginal = _userSnapshots[user].fImp;
    }

    /**
     * @notice _getMultipliers internal function that calculate new multipliers based on the current pool position
     *
     * mAA => How much A the users can rescue for each A they deposited
     * mBA => How much A the users can rescue for each B they deposited
     * mBB => How much B the users can rescue for each B they deposited
     * mAB => How much B the users can rescue for each A they deposited
     *
     * @param totalTokenA balanceOf this contract of token A
     * @param totalTokenB balanceOf this contract of token B
     * @param fImpOpening current Open Value Factor
     * @return multipliers multiplier struct containing the 4 multipliers: mAA, mBA, mBB, mAB
     */
    function _getMultipliers(
        uint256 totalTokenA,
        uint256 totalTokenB,
        uint256 fImpOpening
    ) internal view returns (Mult memory multipliers) {
        uint256 totalTokenAWithPrecision = totalTokenA.mul(10**FIMP_DECIMALS);
        uint256 totalTokenBWithPrecision = totalTokenB.mul(10**FIMP_DECIMALS);
        uint256 mAA = 0;
        uint256 mBB = 0;
        uint256 mAB = 0;
        uint256 mBA = 0;

        if (deamortizedTokenABalance > 0) {
            mAA = (_min(deamortizedTokenABalance.mul(fImpOpening), totalTokenAWithPrecision)).div(
                deamortizedTokenABalance
            );
        }

        if (deamortizedTokenBBalance > 0) {
            mBB = (_min(deamortizedTokenBBalance.mul(fImpOpening), totalTokenBWithPrecision)).div(
                deamortizedTokenBBalance
            );
        }
        if (mAA > 0) {
            mAB = totalTokenBWithPrecision.sub(mBB.mul(deamortizedTokenBBalance)).div(deamortizedTokenABalance);
        }

        if (mBB > 0) {
            mBA = totalTokenAWithPrecision.sub(mAA.mul(deamortizedTokenABalance)).div(deamortizedTokenBBalance);
        }

        multipliers = Mult(mAA, mAB, mBA, mBB);
    }

    /**
     * @notice _getRemoveLiquidityAmounts internal function of getRemoveLiquidityAmounts
     *
     * @param percentA percent of exposition A to be removed
     * @param percentB percent of exposition B to be removed
     * @param user address of the account that will be removed
     *
     * @return withdrawAmountA amount of token A that will be rescued
     * @return withdrawAmountB amount of token B that will be rescued
     */
    function _getRemoveLiquidityAmounts(
        uint256 percentA,
        uint256 percentB,
        address user
    ) internal view returns (uint256 withdrawAmountA, uint256 withdrawAmountB) {
        (uint256 totalTokenA, uint256 totalTokenB) = _getPoolBalances();
        (uint256 originalBalanceTokenA, uint256 originalBalanceTokenB, uint256 fImpOriginal) = _getUserDepositSnapshot(
            user
        );

        uint256 originalBalanceAToReduce = percentA.mul(originalBalanceTokenA).div(PERCENT_PRECISION);
        uint256 originalBalanceBToReduce = percentB.mul(originalBalanceTokenB).div(PERCENT_PRECISION);

        bool hasNoLiquidity = totalTokenA == 0 && totalTokenB == 0;
        if (hasNoLiquidity) {
            return (0, 0);
        }

        uint256 ABPrice = _getABPrice();
        uint256 fImpOpening = _getFImpOpening(
            totalTokenA,
            totalTokenB,
            ABPrice,
            deamortizedTokenABalance,
            deamortizedTokenBBalance
        );

        Mult memory multipliers = _getMultipliers(totalTokenA, totalTokenB, fImpOpening);

        (withdrawAmountA, withdrawAmountB) = _getWithdrawAmounts(
            originalBalanceAToReduce,
            originalBalanceBToReduce,
            fImpOriginal,
            multipliers
        );
    }

    /**
     * @notice _getWithdrawAmounts internal function of getRemoveLiquidityAmounts
     *
     * @param _originalBalanceAToReduce amount of original deposit of the token A
     * @param _originalBalanceBToReduce amount of original deposit of the token B
     * @param _userFImp Opening Value Factor by the moment of the deposit
     *
     * @return withdrawAmountA amount of token A that will be rescued
     * @return withdrawAmountB amount of token B that will be rescued
     */
    function _getWithdrawAmounts(
        uint256 _originalBalanceAToReduce,
        uint256 _originalBalanceBToReduce,
        uint256 _userFImp,
        Mult memory multipliers
    ) internal pure returns (uint256 withdrawAmountA, uint256 withdrawAmountB) {
        if (_userFImp > 0) {
            withdrawAmountA = _originalBalanceAToReduce
                .mul(multipliers.AA)
                .add(_originalBalanceBToReduce.mul(multipliers.BA))
                .div(_userFImp);
            withdrawAmountB = _originalBalanceBToReduce
                .mul(multipliers.BB)
                .add(_originalBalanceAToReduce.mul(multipliers.AB))
                .div(_userFImp);
        }
        return (withdrawAmountA, withdrawAmountB);
    }

    /**
     * @notice _getUserBalanceToStore internal auxiliary function to help calculation the
     * tokenA and tokenB value that should be stored in UserDepositSnapshot struct
     *
     * @param amountOfA current deposit of the token A
     * @param amountOfB current deposit of the token B
     * @param fImpOpening Opening Value Factor by the moment of the deposit
     *
     * @return userToStoreTokenA amount of token A that will be stored
     * @return userToStoreTokenB amount of token B that will be stored
     */
    function _getUserBalanceToStore(
        uint256 amountOfA,
        uint256 amountOfB,
        uint256 fImpOpening,
        UserDepositSnapshot memory userDepositSnapshot
    ) internal pure returns (uint256 userToStoreTokenA, uint256 userToStoreTokenB) {
        userToStoreTokenA = amountOfA;
        userToStoreTokenB = amountOfB;

        //Re-add Liquidity case
        if (userDepositSnapshot.fImp != 0) {
            userToStoreTokenA = userDepositSnapshot.tokenABalance.mul(fImpOpening).div(userDepositSnapshot.fImp).add(
                amountOfA
            );
            userToStoreTokenB = userDepositSnapshot.tokenBBalance.mul(fImpOpening).div(userDepositSnapshot.fImp).add(
                amountOfB
            );
        }
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function _getABPrice() internal virtual view returns (uint256 ABPrice);

    function _getTradeDetailsExactAInput(uint256 amountAIn) internal virtual returns (TradeDetails memory);

    function _getTradeDetailsExactAOutput(uint256 amountAOut) internal virtual returns (TradeDetails memory);

    function _getTradeDetailsExactBInput(uint256 amountBIn) internal virtual returns (TradeDetails memory);

    function _getTradeDetailsExactBOutput(uint256 amountBOut) internal virtual returns (TradeDetails memory);

    function _onTrade(TradeDetails memory tradeDetails) internal virtual;

    function _onRemoveLiquidity(
        uint256 percentA,
        uint256 percentB,
        address owner
    ) internal virtual;

    function _onAddLiquidity(UserDepositSnapshot memory userDepositSnapshot, address owner) internal virtual;

    function _isValidAddress(address recipient) private pure {
        require(recipient != address(0), "AMM: transfer to zero address");
    }

    function _isValidInput(uint256 input) private pure {
        require(input > 0, "AMM: input should be greater than zero");
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IConfigurationManager.sol";
import "../interfaces/ICapProvider.sol";

/**
 * @title CappedPool
 * @author Pods Finance
 *
 * @notice Controls a maximum cap for a guarded release
 */
abstract contract CappedPool {
    using SafeMath for uint256;

    IConfigurationManager private immutable _configurationManager;

    constructor(IConfigurationManager configurationManager) public {
        _configurationManager = configurationManager;
    }

    /**
     * @dev Modifier to stop transactions that exceed the cap
     */
    modifier capped(address token, uint256 amountOfLiquidity) {
        uint256 cap = capSize();

        if (cap > 0) {
            uint256 poolBalance = IERC20(token).balanceOf(address(this));
            require(poolBalance.add(amountOfLiquidity) <= cap, "CappedPool: amount exceed cap");
        }
        _;
    }

    /**
     * @dev Get the cap size
     */
    function capSize() public view returns (uint256) {
        ICapProvider capProvider = ICapProvider(_configurationManager.getCapProvider());
        return capProvider.getCap(address(this));
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

contract CombinedActionsGuard {
    mapping(address => uint256) sessions;

    /**
     * @dev Prevents an address from calling more than one function that contains this
     * function in the same block
     */
    function _nonCombinedActions() internal {
        require(sessions[tx.origin] != block.number, "CombinedActionsGuard: reentrant call");
        sessions[tx.origin] = block.number;
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

interface IPriceProvider {
    function setAssetFeeds(address[] memory _assets, address[] memory _feeds) external;

    function updateAssetFeeds(address[] memory _assets, address[] memory _feeds) external;

    function removeAssetFeeds(address[] memory _assets) external;

    function getAssetPrice(address _asset) external view returns (uint256);

    function getAssetDecimals(address _asset) external view returns (uint8);

    function latestRoundData(address _asset)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function getPriceFeed(address _asset) external view returns (address);

    function updateMinUpdateInterval() external;
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IIVProvider {
    struct IVData {
        uint256 roundId;
        uint256 updatedAt;
        uint256 answer;
        uint8 decimals;
    }

    event UpdatedIV(address indexed option, uint256 roundId, uint256 updatedAt, uint256 answer, uint8 decimals);
    event UpdaterSet(address indexed admin, address indexed updater);

    function getIV(address option)
        external
        view
        returns (
            uint256 roundId,
            uint256 updatedAt,
            uint256 answer,
            uint8 decimals
        );

    function updateIV(
        address option,
        uint256 answer,
        uint8 decimals
    ) external;

    function setUpdater(address updater) external;
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity >=0.6.12;

interface IBlackScholes {
    function getCallPrice(
        uint256 spotPrice,
        uint256 strikePrice,
        uint256 sigma,
        uint256 time,
        int256 riskFree
    ) external view returns (uint256);

    function getPutPrice(
        uint256 spotPrice,
        uint256 strikePrice,
        uint256 sigma,
        uint256 time,
        int256 riskFree
    ) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

interface IIVGuesser {
    function blackScholes() external view returns (address);

    function getPutIV(
        uint256 _targetPrice,
        uint256 _initialIVGuess,
        uint256 _spotPrice,
        uint256 _strikePrice,
        uint256 _timeToMaturity,
        int256 _riskFree
    ) external view returns (uint256, uint256);

    function getCallIV(
        uint256 _targetPrice,
        uint256 _initialIVGuess,
        uint256 _spotPrice,
        uint256 _strikePrice,
        uint256 _timeToMaturity,
        int256 _riskFree
    ) external view returns (uint256, uint256);

    function updateAcceptableRange() external;
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPodOption is IERC20 {
    /** Enums */
    // @dev 0 for Put, 1 for Call
    enum OptionType { PUT, CALL }
    // @dev 0 for European, 1 for American
    enum ExerciseType { EUROPEAN, AMERICAN }

    /** Events */
    event Mint(address indexed minter, uint256 amount);
    event Unmint(address indexed minter, uint256 optionAmount, uint256 strikeAmount, uint256 underlyingAmount);
    event Exercise(address indexed exerciser, uint256 amount);
    event Withdraw(address indexed minter, uint256 strikeAmount, uint256 underlyingAmount);

    /** Functions */

    /**
     * @notice Locks collateral and write option tokens.
     *
     * @dev The issued amount ratio is 1:1, i.e., 1 option token for 1 underlying token.
     *
     * The collateral could be the strike or the underlying asset depending on the option type: Put or Call,
     * respectively
     *
     * It presumes the caller has already called IERC20.approve() on the
     * strike/underlying token contract to move caller funds.
     *
     * Options can only be minted while the series is NOT expired.
     *
     * It is also important to notice that options will be sent back
     * to `msg.sender` and not the `owner`. This behavior is designed to allow
     * proxy contracts to mint on others behalf. The `owner` will be able to remove
     * the deposited collateral after series expiration or by calling unmint(), even
     * if a third-party minted options on its behalf.
     *
     * @param amountOfOptions The amount option tokens to be issued
     * @param owner Which address will be the owner of the options
     */
    function mint(uint256 amountOfOptions, address owner) external;

    /**
     * @notice Allow option token holders to use them to exercise the amount of units
     * of the locked tokens for the equivalent amount of the exercisable assets.
     *
     * @dev It presumes the caller has already called IERC20.approve() exercisable asset
     * to move caller funds.
     *
     * On American options, this function can only called anytime before expiration.
     * For European options, this function can only be called during the exerciseWindow.
     * Meaning, after expiration and before the end of exercise window.
     *
     * @param amountOfOptions The amount option tokens to be exercised
     */
    function exercise(uint256 amountOfOptions) external;

    /**
     * @notice After series expiration in case of American or after exercise window for European,
     * allow minters who have locked their collateral to withdraw them proportionally
     * to their minted options.
     *
     * @dev If assets had been exercised during the option series the minter may withdraw
     * the exercised assets or a combination of exercised and collateral.
     */
    function withdraw() external;

    /**
     * @notice Unlocks collateral by burning option tokens.
     *
     * Options can only be burned while the series is NOT expired.
     *
     * @param amountOfOptions The amount option tokens to be burned
     */
    function unmint(uint256 amountOfOptions) external;

    function optionType() external view returns (OptionType);

    function exerciseType() external view returns (ExerciseType);

    function underlyingAsset() external view returns (address);

    function underlyingAssetDecimals() external view returns (uint8);

    function strikeAsset() external view returns (address);

    function strikeAssetDecimals() external view returns (uint8);

    function strikePrice() external view returns (uint256);

    function strikePriceDecimals() external view returns (uint8);

    function expiration() external view returns (uint256);

    function startOfExerciseWindow() external view returns (uint256);

    function hasExpired() external view returns (bool);

    function isTradeWindow() external view returns (bool);

    function isExerciseWindow() external view returns (bool);

    function isWithdrawWindow() external view returns (bool);

    function strikeToTransfer(uint256 amountOfOptions) external view returns (uint256);

    function getSellerWithdrawAmounts(address owner)
        external
        view
        returns (uint256 strikeAmount, uint256 underlyingAmount);

    function underlyingReserves() external view returns (uint256);

    function strikeReserves() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "./IAMM.sol";

interface IOptionAMMPool is IAMM {
    // @dev 0 for when tokenA enter the pool and B leaving (A -> B)
    // and 1 for the opposite direction
    enum TradeDirection { AB, BA }

    function tradeExactAInput(
        uint256 exactAmountAIn,
        uint256 minAmountBOut,
        address owner,
        uint256 sigmaInitialGuess
    ) external returns (uint256);

    function tradeExactAOutput(
        uint256 exactAmountAOut,
        uint256 maxAmountBIn,
        address owner,
        uint256 sigmaInitialGuess
    ) external returns (uint256);

    function tradeExactBInput(
        uint256 exactAmountBIn,
        uint256 minAmountAOut,
        address owner,
        uint256 sigmaInitialGuess
    ) external returns (uint256);

    function tradeExactBOutput(
        uint256 exactAmountBOut,
        uint256 maxAmountAIn,
        address owner,
        uint256 sigmaInitialGuess
    ) external returns (uint256);

    function getOptionTradeDetailsExactAInput(uint256 exactAmountAIn)
        external
        view
        returns (
            uint256 amountBOutput,
            uint256 newSigma,
            uint256 feesTokenA,
            uint256 feesTokenB
        );

    function getOptionTradeDetailsExactAOutput(uint256 exactAmountAOut)
        external
        view
        returns (
            uint256 amountBInput,
            uint256 newSigma,
            uint256 feesTokenA,
            uint256 feesTokenB
        );

    function getOptionTradeDetailsExactBInput(uint256 exactAmountBIn)
        external
        view
        returns (
            uint256 amountAOutput,
            uint256 newSigma,
            uint256 feesTokenA,
            uint256 feesTokenB
        );

    function getOptionTradeDetailsExactBOutput(uint256 exactAmountBOut)
        external
        view
        returns (
            uint256 amountAInput,
            uint256 newSigma,
            uint256 feesTokenA,
            uint256 feesTokenB
        );

    function getRemoveLiquidityAmounts(
        uint256 percentA,
        uint256 percentB,
        address user
    ) external view returns (uint256 withdrawAmountA, uint256 withdrawAmountB);

    function getABPrice() external view returns (uint256);

    function getAdjustedIV() external view returns (uint256);

    function withdrawRewards() external;
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

interface IFeePool {
    struct Balance {
        uint256 shares;
        uint256 liability;
    }

    function setFee(uint256 feeBaseValue, uint8 decimals) external;

    function withdraw(address to, uint256 amount) external;

    function mint(address to, uint256 amount) external;

    function feeToken() external view returns (address);

    function feeValue() external view returns (uint256);

    function feeDecimals() external view returns (uint8);

    function getCollectable(uint256 amount, uint256 poolAmount) external view returns (uint256);

    function sharesOf(address owner) external view returns (uint256);

    function getWithdrawAmount(address owner, uint256 amountOfShares) external view returns (uint256, uint256);
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

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

interface IEmergencyStop {
    function stop(address target) external;

    function resume(address target) external;

    function isStopped(address target) external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "./IFeePool.sol";

interface IFeePoolBuilder {
    function buildFeePool(
        address asset,
        uint256 feeBaseValue,
        uint8 feeDecimals,
        address owner
    ) external returns (IFeePool);
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/IAaveIncentivesController.sol";
import "../../interfaces/IConfigurationManager.sol";
import "../../lib/Conversion.sol";

abstract contract AaveIncentives is Conversion {
    address public immutable rewardAsset;
    address public immutable rewardContract;

    event RewardsClaimed(address indexed claimer, uint256 rewardAmount);

    constructor(IConfigurationManager configurationManager) public {
        rewardAsset = _parseAddressFromUint(configurationManager.getParameter("REWARD_ASSET"));
        rewardContract = _parseAddressFromUint(configurationManager.getParameter("REWARD_CONTRACT"));
    }

    /**
     * @notice Gets the current reward claimed
     */
    function _rewardBalance() internal view returns (uint256) {
        return IERC20(rewardAsset).balanceOf(address(this));
    }

    /**
     * @notice Claim pending rewards
     */
    function _claimRewards(address[] memory assets) internal {
        IAaveIncentivesController distributor = IAaveIncentivesController(rewardContract);
        uint256 amountToClaim = distributor.getRewardsBalance(assets, address(this));
        distributor.claimRewards(assets, amountToClaim, address(this));
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

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RequiredDecimals {
    uint256 private constant _MAX_TOKEN_DECIMALS = 38;

    /**
     * Tries to fetch the decimals of a token, if not existent, fails with a require statement
     *
     * @param token An instance of IERC20
     * @return The decimals of a token
     */
    function tryDecimals(IERC20 token) internal view returns (uint8) {
        // solhint-disable-line private-vars-leading-underscore
        bytes memory payload = abi.encodeWithSignature("decimals()");
        // solhint-disable avoid-low-level-calls
        (bool success, bytes memory returnData) = address(token).staticcall(payload);

        require(success, "RequiredDecimals: required decimals");
        uint8 decimals = abi.decode(returnData, (uint8));
        require(decimals < _MAX_TOKEN_DECIMALS, "RequiredDecimals: token decimals should be lower than 38");

        return decimals;
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

interface IAMM {
    function addLiquidity(
        uint256 amountOfA,
        uint256 amountOfB,
        address owner
    ) external;

    function removeLiquidity(uint256 amountOfA, uint256 amountOfB) external;

    function tokenA() external view returns (address);

    function tokenB() external view returns (address);

    function tokenADecimals() external view returns (uint8);

    function tokenBDecimals() external view returns (uint8);
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

interface ICapProvider {
    function setCap(address target, uint256 value) external;

    function getCap(address target) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

interface IAaveIncentivesController {
    function getRewardsBalance(address[] calldata assets, address user) external view returns (uint256);

    function claimRewards(
        address[] calldata assets,
        uint256 amount,
        address to
    ) external returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

contract Conversion {
    /**
     * @notice Parses the address represented by an uint
     */
    function _parseAddressFromUint(uint256 x) internal pure returns (address) {
        bytes memory data = new bytes(32);
        assembly {
            mstore(add(data, 32), x)
        }
        return abi.decode(data, (address));
    }
}