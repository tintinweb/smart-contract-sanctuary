// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import './interfaces/IAlgebraPool.sol';
import './interfaces/IDataStorageOperator.sol';
import './interfaces/IAlgebraVirtualPool.sol';

import './base/PoolState.sol';
import './base/PoolImmutables.sol';

import './libraries/TokenDeltaMath.sol';
import './libraries/PriceMovementMath.sol';
import './libraries/TickManager.sol';
import './libraries/TickTable.sol';

import './libraries/LowGasSafeMath.sol';
import './libraries/SafeCast.sol';

import './libraries/FullMath.sol';
import './libraries/Constants.sol';
import './libraries/TransferHelper.sol';
import './libraries/TickMath.sol';
import './libraries/LiquidityMath.sol';

import './interfaces/IAlgebraPoolDeployer.sol';
import './interfaces/IAlgebraFactory.sol';
import './interfaces/IERC20Minimal.sol';
import './interfaces/callback/IAlgebraMintCallback.sol';
import './interfaces/callback/IAlgebraSwapCallback.sol';
import './interfaces/callback/IAlgebraFlashCallback.sol';

contract AlgebraPool is PoolState, PoolImmutables, IAlgebraPool {
    using LowGasSafeMath for uint256;
    using LowGasSafeMath for int256;
    using SafeCast for uint256;
    using SafeCast for int256;
    using TickTable for mapping(int16 => uint256);
    using TickManager for mapping(int24 => TickManager.Tick);

    struct Position {
        // The amount of liquidity concentrated in the range
        uint128 liquidity;
        // The last updated fee growth per unit of liquidity
        uint256 innerFeeGrowth0Token;
        uint256 innerFeeGrowth1Token;
        // The amount of token0 owed to a LP
        uint128 fees0;
        // The amount of token1 owed to a LP
        uint128 fees1;
    }

    // @inheritdoc IAlgebraPoolState
    mapping(bytes32 => Position) public override positions;

    struct Incentive {
        // The address of a virtual pool associated with the current active incentive
        address virtualPool;
        // The timestamp when the active incentive is finished
        uint32 endTimestamp;
        // The first swap after this timestamp is going to initialize the virtual pool
        uint32 startTimestamp;
    }

    // @inheritdoc IAlgebraPoolState
    Incentive public override activeIncentive;

    // @dev Restricts everyone calling a function except factory owner
    modifier onlyFactoryOwner() {
        require(msg.sender == IAlgebraFactory(factory).owner());
        _;
    }

    constructor() PoolImmutables(msg.sender) {
        globalState.fee = Constants.BASE_FEE;
    }

    function balanceToken0() private view returns (uint256) {
        (bool success, bytes memory data) = token0.staticcall(
            abi.encodeWithSelector(IERC20Minimal.balanceOf.selector, address(this))
        );
        require(success && data.length >= 32);
        return abi.decode(data, (uint256));
    }

    function balanceToken1() private view returns (uint256) {
        (bool success, bytes memory data) = token1.staticcall(
            abi.encodeWithSelector(IERC20Minimal.balanceOf.selector, address(this))
        );
        require(success && data.length >= 32);
        return abi.decode(data, (uint256));
    }

    // @inheritdoc IDataStorageOperator
    function timepoints(uint256 index)
        external
        view
        override
        returns (
            bool initialized,
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulative,
            uint112 volatilityCumulative,
            uint256 volumePerAvgLiquidity
        )
    {
        return IDataStorageOperator(dataStorageOperator).timepoints(index);
    }

    function tickValidation(int24 bottomTick, int24 topTick) private pure {
        require(bottomTick < topTick, 'TLU');
        require(bottomTick >= TickMath.MIN_TICK, 'TLM');
        require(topTick <= TickMath.MAX_TICK, 'TUM');
    }

    struct cumulatives {
        int56 tickCumulative;
        uint160 outerSecondPerLiquidity;
        uint32 outerSecondsSpent;
    }

    // @inheritdoc IAlgebraPoolDerivedState
    function getInnerCumulatives(int24 bottomTick, int24 topTick)
        external
        view
        override
        returns (
            int56 innerTickCumulative,
            uint160 innerSecondsSpentPerLiquidity,
            uint32 innerSecondsSpent
        )
    {
        tickValidation(bottomTick, topTick);

        cumulatives memory upper;
        cumulatives memory lower;

        {
            TickManager.Tick storage _lower = ticks[bottomTick];
            TickManager.Tick storage _upper = ticks[topTick];
            (lower.tickCumulative, lower.outerSecondPerLiquidity, lower.outerSecondsSpent) = (
                _lower.outerTickCumulative,
                _lower.outerSecondsPerLiquidity,
                _lower.outerSecondsSpent
            );

            (upper.tickCumulative, upper.outerSecondPerLiquidity, upper.outerSecondsSpent) = (
                _upper.outerTickCumulative,
                _upper.outerSecondsPerLiquidity,
                _upper.outerSecondsSpent
            );
            require(_lower.initialized);
            require(_upper.initialized);
        }

        GlobalState memory _globalState = globalState;

        if (_globalState.tick < bottomTick) {
            return (
                lower.tickCumulative - upper.tickCumulative,
                lower.outerSecondPerLiquidity - upper.outerSecondPerLiquidity,
                lower.outerSecondsSpent - upper.outerSecondsSpent
            );
        } else if (_globalState.tick < topTick) {
            uint32 globalTime = _blockTimestamp();
            (int56 globalTickCumulative, uint160 globalSecondsPerLiquidityCumulative, , ) = IDataStorageOperator(
                dataStorageOperator
            ).getSingleTimepoint(globalTime, 0, _globalState.tick, _globalState.timepointIndex, liquidity);
            return (
                globalTickCumulative - lower.tickCumulative - upper.tickCumulative,
                globalSecondsPerLiquidityCumulative - lower.outerSecondPerLiquidity - upper.outerSecondPerLiquidity,
                globalTime - lower.outerSecondsSpent - upper.outerSecondsSpent
            );
        } else {
            return (
                upper.tickCumulative - lower.tickCumulative,
                upper.outerSecondPerLiquidity - lower.outerSecondPerLiquidity,
                upper.outerSecondsSpent - lower.outerSecondsSpent
            );
        }
    }

    // @inheritdoc IAlgebraPoolDerivedState
    function getTimepoints(uint32[] calldata secondsAgos)
        external
        view
        override
        returns (
            int56[] memory tickCumulatives,
            uint160[] memory secondsPerLiquidityCumulatives,
            uint112[] memory volatilityCumulatives,
            uint256[] memory volumePerAvgLiquiditys
        )
    {
        return
            IDataStorageOperator(dataStorageOperator).getTimepoints(
                _blockTimestamp(),
                secondsAgos,
                globalState.tick,
                globalState.timepointIndex,
                liquidity
            );
    }

    // @inheritdoc IAlgebraPoolActions
    function initialize(uint160 initialPrice) external override {
        require(globalState.price == 0, 'AI');

        int24 tick = TickMath.getTickAtSqrtRatio(initialPrice);

        // initialize DataStorageOperator
        IDataStorageOperator(dataStorageOperator).initialize(_blockTimestamp());

        // initialize the pool
        globalState.price = initialPrice;
        globalState.unlocked = true;
        globalState.tick = tick;

        emit Initialize(initialPrice, tick);
    }

    /**
     * @notice Increases amounts of tokens owed to owner of the position
     * @param _position The position object to operate with
     * @param liquidityDelta The amount on which to increase\decrease the liquidity
     * @param innerFeeGrowth0Token Total fee token0 fee growth per 1/liquidity between position's lower and upper ticks
     * @param innerFeeGrowth1Token Total fee token1 fee growth per 1/liquidity between position's lower and upper ticks
     */
    function _recalculatePosition(
        Position storage _position,
        int128 liquidityDelta,
        uint256 innerFeeGrowth0Token,
        uint256 innerFeeGrowth1Token
    ) internal {
        uint128 currentLiquidity = _position.liquidity;
        uint256 _innerFeeGrowth0Token = _position.innerFeeGrowth0Token;
        uint256 _innerFeeGrowth1Token = _position.innerFeeGrowth1Token;

        uint128 liquidityNext;
        if (liquidityDelta == 0) {
            require(currentLiquidity > 0, 'NP'); // Do not recalculate the empty ranges
        } else {
            liquidityNext = LiquidityMath.addDelta(currentLiquidity, liquidityDelta);
        }

        (uint128 fees0, uint128 fees1) = (
            uint128(FullMath.mulDiv(innerFeeGrowth0Token - _innerFeeGrowth0Token, currentLiquidity, Constants.Q128)),
            uint128(FullMath.mulDiv(innerFeeGrowth1Token - _innerFeeGrowth1Token, currentLiquidity, Constants.Q128))
        );

        // update the position
        if (liquidityDelta != 0) _position.liquidity = liquidityNext;
        _position.innerFeeGrowth0Token = innerFeeGrowth0Token;
        _position.innerFeeGrowth1Token = innerFeeGrowth1Token;

        // To avoid overflow owner has to collect fee before it
        if (fees0 != 0 || fees1 != 0) {
            _position.fees0 += fees0;
            _position.fees1 += fees1;
        }
    }

    /**
     * @dev Updates position's ticks and its fees
     * @return position The Position object to operate with
     * @return amount0 The amount of token0 the caller needs to send, negative if the pool needs to send it
     * @return amount1 The amount of token1 the caller needs to send, negative if the pool needs to send it
     */
    function _modifyPosition(
        address owner,
        int24 bottomTick,
        int24 topTick,
        int128 liquidityDelta
    )
        private
        returns (
            Position storage position,
            int256 amount0,
            int256 amount1
        )
    {
        GlobalState memory _globalState = globalState;

        position = getOrCreatePosition(owner, bottomTick, topTick);

        (uint256 _totalFeeGrowth0Token, uint256 _totalFeeGrowth1Token) = (totalFeeGrowth0Token, totalFeeGrowth1Token);

        bool toggledBottom;
        bool toggledTop;
        if (liquidityDelta != 0) {
            uint32 time = _blockTimestamp();
            (int56 tickCumulative, uint160 secondsPerLiquidityCumulative, , ) = IDataStorageOperator(
                dataStorageOperator
            ).getSingleTimepoint(time, 0, globalState.tick, globalState.timepointIndex, liquidity);

            if (
                ticks.update(
                    bottomTick,
                    _globalState.tick,
                    liquidityDelta,
                    _totalFeeGrowth0Token,
                    _totalFeeGrowth1Token,
                    secondsPerLiquidityCumulative,
                    tickCumulative,
                    time,
                    false
                )
            ) {
                toggledBottom = true;
                tickTable.toggleTick(bottomTick);
            }

            if (
                ticks.update(
                    topTick,
                    _globalState.tick,
                    liquidityDelta,
                    _totalFeeGrowth0Token,
                    _totalFeeGrowth1Token,
                    secondsPerLiquidityCumulative,
                    tickCumulative,
                    time,
                    true
                )
            ) {
                toggledTop = true;
                tickTable.toggleTick(topTick);
            }
        }

        (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) = ticks.getInnerFeeGrowth(
            bottomTick,
            topTick,
            _globalState.tick,
            _totalFeeGrowth0Token,
            _totalFeeGrowth1Token
        );

        _recalculatePosition(position, liquidityDelta, feeGrowthInside0X128, feeGrowthInside1X128);

        // if liquidityDelta is negative, i.e. the liquidity was removed, and also the tick was toggled, it
        // means that it should not be initialized anymore, so we delete it
        if (liquidityDelta < 0) {
            if (toggledBottom) {
                delete ticks[bottomTick];
            }
            if (toggledTop) {
                delete ticks[topTick];
            }
        }

        if (liquidityDelta != 0) {
            int128 globalLiquidityDelta;
            (amount0, amount1, globalLiquidityDelta) = _getAmountsForLiquidity(
                bottomTick,
                topTick,
                liquidityDelta,
                _globalState
            );
            if (globalLiquidityDelta != 0) {
                uint128 liquidityBefore = liquidity;
                uint16 newTimepointIndex = IDataStorageOperator(dataStorageOperator).write(
                    _globalState.timepointIndex,
                    _blockTimestamp(),
                    _globalState.tick,
                    liquidityBefore,
                    0
                );
                globalState.timepointIndex = newTimepointIndex;
                _changeFee(_blockTimestamp(), _globalState.tick, newTimepointIndex, liquidityBefore);
                liquidity = LiquidityMath.addDelta(liquidityBefore, liquidityDelta);
            }
        }
    }

    function _getAmountsForLiquidity(
        int24 bottomTick,
        int24 topTick,
        int128 liquidityDelta,
        GlobalState memory _globalState
    )
        private
        pure
        returns (
            int256 amount0,
            int256 amount1,
            int128 globalLiquidityDelta
        )
    {
        // If current tick is less than the provided bottom one then only the token0 has to be provided
        if (_globalState.tick < bottomTick) {
            amount0 = TokenDeltaMath.getToken0Delta(
                TickMath.getSqrtRatioAtTick(bottomTick),
                TickMath.getSqrtRatioAtTick(topTick),
                liquidityDelta
            );
        } else if (_globalState.tick < topTick) {
            amount0 = TokenDeltaMath.getToken0Delta(
                _globalState.price,
                TickMath.getSqrtRatioAtTick(topTick),
                liquidityDelta
            );
            amount1 = TokenDeltaMath.getToken1Delta(
                TickMath.getSqrtRatioAtTick(bottomTick),
                _globalState.price,
                liquidityDelta
            );

            globalLiquidityDelta = liquidityDelta;
        }
        // If current tick is greater than the provided top one then only the token1 has to be provided
        else {
            amount1 = TokenDeltaMath.getToken1Delta(
                TickMath.getSqrtRatioAtTick(bottomTick),
                TickMath.getSqrtRatioAtTick(topTick),
                liquidityDelta
            );
        }
    }

    /**
     * @notice This function fetches certain position object
     * @param owner The address owing the position
     * @param bottomTick The position's bottom tick
     * @param topTick The position's top tick
     * @return position The Position object
     */
    function getOrCreatePosition(
        address owner,
        int24 bottomTick,
        int24 topTick
    ) private view returns (Position storage) {
        bytes32 key;
        assembly {
            let p := mload(0x40)
            mstore(0x40, add(p, 96))
            mstore(p, topTick)
            mstore(add(p, 32), bottomTick)
            mstore(add(p, 64), owner)
            key := keccak256(p, 96)
        }
        return positions[key];
    }

    // @inheritdoc IAlgebraPoolActions
    function mint(
        address sender,
        address recipient,
        int24 bottomTick,
        int24 topTick,
        uint128 _liquidity,
        bytes calldata data
    )
        external
        override
        lock
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 liquidityAmount
        )
    {
        require(_liquidity > 0, 'IL');
        tickValidation(bottomTick, topTick);
        {
            (int256 amount0Int, int256 amount1Int, ) = _getAmountsForLiquidity(
                bottomTick,
                topTick,
                int256(_liquidity).toInt128(),
                globalState
            );

            amount0 = uint256(amount0Int);
            amount1 = uint256(amount1Int);
        }

        uint256 receivedAmount0;
        uint256 receivedAmount1;
        {
            if (amount0 > 0) receivedAmount0 = balanceToken0();
            if (amount1 > 0) receivedAmount1 = balanceToken1();
            IAlgebraMintCallback(msg.sender).AlgebraMintCallback(amount0, amount1, data);
            if (amount0 > 0) require((receivedAmount0 = balanceToken0() - receivedAmount0) > 0, 'IIAM');
            if (amount1 > 0) require((receivedAmount1 = balanceToken1() - receivedAmount1) > 0, 'IIAM');
        }

        if (receivedAmount0 < amount0) {
            _liquidity = uint128(FullMath.mulDiv(uint256(_liquidity), receivedAmount0, amount0));
        }
        if (receivedAmount1 < amount1) {
            uint128 liquidityForRA1 = uint128(FullMath.mulDiv(uint256(_liquidity), receivedAmount1, amount1));
            if (liquidityForRA1 < _liquidity) {
                _liquidity = liquidityForRA1;
            }
        }

        require(_liquidity > 0, 'IIL2');

        {
            (, int256 amount0Int, int256 amount1Int) = _modifyPosition(
                recipient,
                bottomTick,
                topTick,
                int256(_liquidity).toInt128()
            );

            require((amount0 = uint256(amount0Int)) <= receivedAmount0, 'IIAM2');
            require((amount1 = uint256(amount1Int)) <= receivedAmount1, 'IIAM2');
        }

        if (receivedAmount0 > amount0) {
            TransferHelper.safeTransfer(token0, sender, receivedAmount0 - amount0);
        }
        if (receivedAmount1 > amount1) {
            TransferHelper.safeTransfer(token1, sender, receivedAmount1 - amount1);
        }
        liquidityAmount = _liquidity;
        emit Mint(msg.sender, recipient, bottomTick, topTick, _liquidity, amount0, amount1);
    }

    // @inheritdoc IAlgebraPoolActions
    function collect(
        address recipient,
        int24 bottomTick,
        int24 topTick,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external override lock returns (uint128 amount0, uint128 amount1) {
        Position storage position = getOrCreatePosition(msg.sender, bottomTick, topTick);

        amount0 = amount0Requested > position.fees0 ? position.fees0 : amount0Requested;
        amount1 = amount1Requested > position.fees1 ? position.fees1 : amount1Requested;

        if (amount0 > 0) {
            position.fees0 -= amount0;
            TransferHelper.safeTransfer(token0, recipient, amount0);
        }
        if (amount1 > 0) {
            position.fees1 -= amount1;
            TransferHelper.safeTransfer(token1, recipient, amount1);
        }

        emit Collect(msg.sender, recipient, bottomTick, topTick, amount0, amount1);
    }

    // @inheritdoc IAlgebraPoolActions
    function burn(
        int24 bottomTick,
        int24 topTick,
        uint128 amount
    ) external override lock returns (uint256 amount0, uint256 amount1) {
        tickValidation(bottomTick, topTick);
        (Position storage position, int256 amount0Int, int256 amount1Int) = _modifyPosition(
            msg.sender,
            bottomTick,
            topTick,
            -int256(amount).toInt128()
        );

        amount0 = uint256(-amount0Int);
        amount1 = uint256(-amount1Int);

        if (amount0 > 0 || amount1 > 0) {
            (position.fees0, position.fees1) = (position.fees0 + uint128(amount0), position.fees1 + uint128(amount1));
        }

        emit Burn(msg.sender, bottomTick, topTick, amount, amount0, amount1);
    }

    // @dev Changes fee according combination of sigmoids
    function _changeFee(
        uint32 _time,
        int24 _tick,
        uint16 _index,
        uint128 _liquidity
    ) private {
        globalState.fee = IDataStorageOperator(dataStorageOperator).getFee(_time, _tick, _index, _liquidity);
        emit ChangeFee(globalState.fee);
    }

    // @inheritdoc IAlgebraPoolActions
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 limitSqrtPrice,
        bytes calldata data
    ) external override returns (int256 amount0, int256 amount1) {
        uint32 blockTimestamp;
        uint160 currentPrice;
        int24 currentTick;
        uint128 currentLiquidity;

        (amount0, amount1, blockTimestamp, currentPrice, currentTick, currentLiquidity) = _calculateSwap(
            zeroForOne,
            amountSpecified,
            limitSqrtPrice
        );

        if (zeroForOne) {
            // transfer to recipient
            if (amount1 < 0) TransferHelper.safeTransfer(token1, recipient, uint256(-amount1));

            uint256 balance0Before = balanceToken0();
            // callback to get tokens from the caller
            IAlgebraSwapCallback(msg.sender).AlgebraSwapCallback(amount0, amount1, data);
            require(balance0Before.add(uint256(amount0)) <= balanceToken0(), 'IIA');
        } else {
            // transfer to recipient
            if (amount0 < 0) TransferHelper.safeTransfer(token0, recipient, uint256(-amount0));

            uint256 balance1Before = balanceToken1();
            // callback to get tokens from the caller
            IAlgebraSwapCallback(msg.sender).AlgebraSwapCallback(amount0, amount1, data);
            require(balance1Before.add(uint256(amount1)) <= balanceToken1(), 'IIA');
        }

        _changeFee(blockTimestamp, currentTick, globalState.timepointIndex, currentLiquidity);

        emit Swap(msg.sender, recipient, amount0, amount1, currentPrice, currentLiquidity, currentTick);
        globalState.unlocked = true;
    }

    // @inheritdoc IAlgebraPoolActions
    function swapSupportingFeeOnInputTokens(
        address sender,
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 limitSqrtPrice,
        bytes calldata data
    ) external override returns (int256 amount0, int256 amount1) {
        uint32 blockTimestamp;
        uint160 currentPrice;
        int24 currentTick;
        uint128 currentLiquidity;

        // Since the pool can get less tokens then sent, firstly we are getting tokens from the
        // original caller of the transaction. And change the _amountSpecified_
        if (zeroForOne) {
            uint256 balance0Before = balanceToken0();
            IAlgebraSwapCallback(msg.sender).AlgebraSwapCallback(amountSpecified, 0, data);
            require((amountSpecified = int256(balanceToken0().sub(balance0Before))) > 0, 'IIA');
        } else {
            uint256 balance1Before = balanceToken1();
            IAlgebraSwapCallback(msg.sender).AlgebraSwapCallback(0, amountSpecified, data);
            require((amountSpecified = int256(balanceToken1().sub(balance1Before))) > 0, 'IIA');
        }

        (amount0, amount1, blockTimestamp, currentPrice, currentTick, currentLiquidity) = _calculateSwap(
            zeroForOne,
            amountSpecified,
            limitSqrtPrice
        );

        // only transfer to the recipient
        if (zeroForOne) {
            if (amount1 < 0) TransferHelper.safeTransfer(token1, recipient, uint256(-amount1));

            // return the leftovers
            if (amount0 < amountSpecified) {
                TransferHelper.safeTransfer(token0, sender, uint256(amountSpecified.sub(amount0)));
            }
        } else {
            if (amount0 < 0) TransferHelper.safeTransfer(token0, recipient, uint256(-amount0));

            // return the leftovers
            if (amount1 < amountSpecified) {
                TransferHelper.safeTransfer(token1, sender, uint256(amountSpecified.sub(amount1)));
            }
        }

        _changeFee(blockTimestamp, currentTick, globalState.timepointIndex, currentLiquidity);

        emit Swap(msg.sender, recipient, amount0, amount1, currentPrice, currentLiquidity, currentTick);
        globalState.unlocked = true;
    }

    struct SwapCache {
        // The community fee of the selling token
        uint8 communityFee;
        // The liquidity at the start of a swap
        uint128 liquidityStart;
        // The global tickCumulative at the moment
        int56 tickCumulative;
        // The global secondPerLiquidity at the moment
        uint160 secondsPerLiquidityCumulative;
        // True if we have already fetched _tickCumulative_ and _secondPerLiquidity_ from the DataOperator
        bool computedLatestTimepoint;
        // The remainder of the exact input\output amount
        int256 amountSpecifiedRemaining;
        // The additive amount of total output\input calculated trough the swap
        int256 amountCalculated;
        // The initial totalFeeGrowth + the fee growth during a swap
        uint256 totalFeeGrowth;
        // The accumulator of the community fee earned during a swap
        uint128 communityFeeAccumulated;
        // True if there is an active incentive at the moment
        bool hasActiveIncentive;
        // Whether the exact input or output is specified
        bool exactInput;
        // The current dynamic fee
        uint16 fee;
        // The index of the last written timepoint
        uint16 timepointIndex;
        // The tick at the start of a swap
        int24 startTick;
    }

    struct StepComputations {
        // The sqrt of the price at the star
        uint160 stepSqrtPrice;
        // The tick till the current step goes
        int24 nextTick;
        // True if the _nextTick is initialized
        bool initialized;
        // The sqrt of the price calculated from the _nextTick
        uint160 nextTickPrice;
        // The additive amount of tokens that have been provided
        uint256 input;
        // The additive amount of token that have been withdrawn
        uint256 output;
        // The total amount of fee earned within a current step
        uint256 feeAmount;
    }

    function _calculateSwap(
        bool zeroForOne,
        int256 amountSpecified,
        uint160 limitSqrtPrice
    )
        private
        returns (
            int256 amount0,
            int256 amount1,
            uint32 blockTimestamp,
            uint160 currentPrice,
            int24 currentTick,
            uint128 currentLiquidity
        )
    {
        SwapCache memory cache;
        {
            GlobalState memory _globalState = globalState;
            globalState.unlocked = false;
            require(_globalState.unlocked, 'LOK');
            require(amountSpecified != 0, 'AS');

            require(
                zeroForOne
                    ? limitSqrtPrice < _globalState.price && limitSqrtPrice > TickMath.MIN_SQRT_RATIO
                    : limitSqrtPrice > _globalState.price && limitSqrtPrice < TickMath.MAX_SQRT_RATIO,
                'SPL'
            );

            currentPrice = _globalState.price;
            currentTick = _globalState.tick;
            currentLiquidity = liquidity;

            cache.liquidityStart = currentLiquidity;
            cache.amountSpecifiedRemaining = amountSpecified;
            cache.exactInput = amountSpecified > 0;

            cache.totalFeeGrowth = zeroForOne ? totalFeeGrowth0Token : totalFeeGrowth1Token;
            cache.communityFee = zeroForOne ? (_globalState.communityFeeToken0) : (_globalState.communityFeeToken1);
            cache.fee = _globalState.fee;
            cache.timepointIndex = _globalState.timepointIndex;
            cache.startTick = _globalState.tick;

            blockTimestamp = _blockTimestamp();
            if (activeIncentive.virtualPool != address(0)) {
                cache.hasActiveIncentive = true;
                (, uint32 _time, , , , ) = IDataStorageOperator(dataStorageOperator).timepoints(
                    _globalState.timepointIndexSwap
                );
                if (_time != blockTimestamp) {
                    if (
                        activeIncentive.endTimestamp > blockTimestamp && activeIncentive.startTimestamp < blockTimestamp
                    ) {
                        IAlgebraVirtualPool(activeIncentive.virtualPool).increaseCumulative(_time, blockTimestamp);
                    }
                }
            }
        }

        StepComputations memory step;
        // swap until there is remaining input or output tokens or we reach the price limit
        while (cache.amountSpecifiedRemaining != 0 && currentPrice != limitSqrtPrice) {
            step.stepSqrtPrice = currentPrice;

            (step.nextTick, step.initialized) = tickTable.nextTickInTheSameRow(currentTick, zeroForOne);

            step.nextTickPrice = TickMath.getSqrtRatioAtTick(step.nextTick);

            // calculate the amounts needed to move the price to the next target if it is possible or as much
            // as possible
            (currentPrice, step.input, step.output, step.feeAmount) = PriceMovementMath.movePriceTowardsTarget(
                zeroForOne,
                currentPrice,
                (!zeroForOne != (step.nextTickPrice < limitSqrtPrice)) // move the price to the target or to the limit
                    ? limitSqrtPrice
                    : step.nextTickPrice,
                currentLiquidity,
                cache.amountSpecifiedRemaining,
                cache.fee
            );

            if (cache.exactInput) {
                // decrease remaining input amount
                cache.amountSpecifiedRemaining -= (step.input + step.feeAmount).toInt256();
                // decrease calculated output amount
                cache.amountCalculated = cache.amountCalculated.sub(step.output.toInt256());
            } else {
                // increase remaining output amount (since its negative)
                cache.amountSpecifiedRemaining += step.output.toInt256();
                // increase calculated input amount
                cache.amountCalculated = cache.amountCalculated.add((step.input + step.feeAmount).toInt256());
            }

            if (cache.communityFee > 0) {
                uint256 delta = step.feeAmount / cache.communityFee;
                step.feeAmount -= delta;
                cache.communityFeeAccumulated += uint128(delta);
            }

            if (currentLiquidity > 0)
                cache.totalFeeGrowth += FullMath.mulDiv(step.feeAmount, Constants.Q128, currentLiquidity);

            if (currentPrice == step.nextTickPrice) {
                // if the reached tick is initialized then we need to cross it
                if (step.initialized) {
                    // once at a swap we have to get the last timepoint of the observation
                    if (!cache.computedLatestTimepoint) {
                        (cache.tickCumulative, cache.secondsPerLiquidityCumulative, , ) = IDataStorageOperator(
                            dataStorageOperator
                        ).getSingleTimepoint(
                                blockTimestamp,
                                0,
                                cache.startTick,
                                cache.timepointIndex,
                                cache.liquidityStart
                            );
                        cache.computedLatestTimepoint = true;
                    }
                    // every tick cross is needed to be duplicated in a virtual pool
                    if (cache.hasActiveIncentive) {
                        if (activeIncentive.endTimestamp > blockTimestamp) {
                            IAlgebraVirtualPool(activeIncentive.virtualPool).cross(step.nextTick, zeroForOne);
                        }
                    }
                    int128 liquidityDelta = ticks.cross(
                        step.nextTick,
                        (zeroForOne ? cache.totalFeeGrowth : totalFeeGrowth0Token),
                        (zeroForOne ? totalFeeGrowth1Token : cache.totalFeeGrowth),
                        cache.secondsPerLiquidityCumulative,
                        cache.tickCumulative,
                        blockTimestamp
                    );
                    // ----------------------->
                    //    delta=x  delta=-x
                    //         ________
                    // _______|        |________
                    //
                    //
                    // <-----------------------
                    //    delta=-x  delta=x
                    //         ________
                    // _______|        |________
                    if (zeroForOne) liquidityDelta = -liquidityDelta;

                    currentLiquidity = LiquidityMath.addDelta(currentLiquidity, liquidityDelta);
                }
                //  nextTick=x
                //  ---------------> currentTick=x
                //          tick=x  |    tick=x+1
                // ___________|_____|_______|___________
                //
                //                          nextTick=x+1
                //      currentTick=x<------------------
                //          tick=x  |    tick=x+1
                // ___________|_____|_______|___________
                currentTick = zeroForOne ? step.nextTick - 1 : step.nextTick;
            } else if (currentPrice != step.stepSqrtPrice) {
                // if the price has changed but hasn't reached the target

                currentTick = TickMath.getTickAtSqrtRatio(currentPrice);
            }
        }

        (amount0, amount1) = zeroForOne == cache.exactInput // the amount to provide could be less then initially specified (e.g. reached limit)
            ? (amountSpecified - cache.amountSpecifiedRemaining, cache.amountCalculated) // the amount to get could be less then initially specified (e.g. reached limit)
            : (cache.amountCalculated, amountSpecified - cache.amountSpecifiedRemaining);

        // if the tick has changed we write a timepoint into the data storage
        if (currentTick != cache.startTick) {
            uint16 timepointIndex = IDataStorageOperator(dataStorageOperator).write(
                cache.timepointIndex,
                blockTimestamp,
                cache.startTick,
                cache.liquidityStart,
                volumePerLiquidityInBlock
            );
            if (timepointIndex != cache.timepointIndex) {
                volumePerLiquidityInBlock = 0;
            }
            (globalState.price, globalState.tick, globalState.timepointIndex, globalState.timepointIndexSwap) = (
                currentPrice,
                currentTick,
                timepointIndex,
                timepointIndex
            );
            // the swap results should be provided to a virtual pool
            if (cache.hasActiveIncentive) {
                if (activeIncentive.startTimestamp <= blockTimestamp) {
                    if (activeIncentive.endTimestamp < blockTimestamp) {
                        activeIncentive.endTimestamp = 0;
                        activeIncentive.virtualPool = address(0);
                    } else {
                        IAlgebraVirtualPool(activeIncentive.virtualPool).processSwap();
                    }
                }
            }
        } else {
            // if we haven't reached the next tick, we moved the price anyway
            globalState.price = currentPrice;
        }

        if (cache.liquidityStart != currentLiquidity) liquidity = currentLiquidity;
        volumePerLiquidityInBlock += IDataStorageOperator(dataStorageOperator).calculateVolumePerLiquidity(
            currentLiquidity,
            amount0,
            amount1
        );

        // to avoid overflow of the community fee it should be claimed before it
        if (zeroForOne) {
            totalFeeGrowth0Token = cache.totalFeeGrowth;
            if (cache.communityFeeAccumulated > 0) communityFees.token0 += cache.communityFeeAccumulated;
        } else {
            totalFeeGrowth1Token = cache.totalFeeGrowth;
            if (cache.communityFeeAccumulated > 0) communityFees.token1 += cache.communityFeeAccumulated;
        }
    }

    // @inheritdoc IAlgebraPoolActions
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external override lock {
        uint128 _liquidity = liquidity;
        require(_liquidity > 0, 'L');

        uint256 fee0 = FullMath.mulDivRoundingUp(amount0, globalState.fee, 1e6);
        uint256 fee1 = FullMath.mulDivRoundingUp(amount1, globalState.fee, 1e6);
        uint256 balance0Before = balanceToken0();
        uint256 balance1Before = balanceToken1();

        if (amount0 > 0) TransferHelper.safeTransfer(token0, recipient, amount0);
        if (amount1 > 0) TransferHelper.safeTransfer(token1, recipient, amount1);

        IAlgebraFlashCallback(msg.sender).AlgebraFlashCallback(fee0, fee1, data);

        uint256 paid0 = balanceToken0();
        uint256 paid1 = balanceToken1();

        require(balance0Before.add(fee0) <= paid0, 'F0');
        require(balance1Before.add(fee1) <= paid1, 'F1');

        paid0 -= balance0Before;
        paid1 -= balance1Before;

        if (paid0 > 0) {
            uint256 fees0 = globalState.communityFeeToken0 == 0 ? 0 : paid0 / globalState.communityFeeToken0;
            if (uint128(fees0) > 0) communityFees.token0 += uint128(fees0);
            totalFeeGrowth0Token += FullMath.mulDiv(paid0 - fees0, Constants.Q128, _liquidity);
        }
        if (paid1 > 0) {
            uint256 fees1 = globalState.communityFeeToken1 == 0 ? 0 : paid1 / globalState.communityFeeToken1;
            if (uint128(fees1) > 0) communityFees.token1 += uint128(fees1);
            totalFeeGrowth1Token += FullMath.mulDiv(paid1 - fees1, Constants.Q128, _liquidity);
        }

        emit Flash(msg.sender, recipient, amount0, amount1, paid0, paid1);
    }

    // @inheritdoc IAlgebraPoolPermissionedActions
    function setCommunityFee(uint8 communityFee0, uint8 communityFee1) external override lock onlyFactoryOwner {
        require(
            (communityFee0 == 0 || (communityFee0 >= 4 && communityFee0 <= 10)) &&
                (communityFee1 == 0 || (communityFee1 >= 4 && communityFee1 <= 10))
        );
        uint8 communityFeeOld0 = globalState.communityFeeToken0;
        uint8 communityFeeOld1 = globalState.communityFeeToken1;
        globalState.communityFeeToken0 = communityFee0;
        globalState.communityFeeToken1 = communityFee1;
        emit SetCommunityFee(communityFeeOld0, communityFeeOld1, communityFee0, communityFee1);
    }

    // @inheritdoc IAlgebraPoolPermissionedActions
    function collectCommunityFee(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external override lock onlyFactoryOwner returns (uint128 amount0, uint128 amount1) {
        amount0 = amount0Requested > communityFees.token0 ? communityFees.token0 : amount0Requested;
        amount1 = amount1Requested > communityFees.token1 ? communityFees.token1 : amount1Requested;

        if (amount0 > 0) {
            if (amount0 == communityFees.token0) amount0--; // communityFees should be at least 1 but not 0 (gas saving)
            communityFees.token0 -= amount0;
            TransferHelper.safeTransfer(token0, recipient, amount0);
        }
        if (amount1 > 0) {
            if (amount1 == communityFees.token1) amount1--; // communityFees should be at least 1 but not 0 (gas saving)
            communityFees.token1 -= amount1;
            TransferHelper.safeTransfer(token1, recipient, amount1);
        }

        emit CollectCommunityFee(msg.sender, recipient, amount0, amount1);
    }

    // @inheritdoc IAlgebraPoolPermissionedActions
    function setIncentive(
        address virtualPoolAddress,
        uint32 endTimestamp,
        uint32 startTimestamp
    ) external override {
        require(msg.sender == IAlgebraFactory(factory).stakerAddress());
        require(activeIncentive.endTimestamp < _blockTimestamp());
        activeIncentive = Incentive(virtualPoolAddress, endTimestamp, startTimestamp);

        emit IncentiveSet(virtualPoolAddress, endTimestamp, startTimestamp);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IAlgebraPoolImmutables.sol';
import './pool/IAlgebraPoolState.sol';
import './pool/IAlgebraPoolDerivedState.sol';
import './pool/IAlgebraPoolActions.sol';
import './pool/IAlgebraPoolPermissionedActions.sol';
import './pool/IAlgebraPoolEvents.sol';

/**
 * @title The interface for a Algebra Pool
 * @dev The pool interface is broken up into many smaller pieces
 */
interface IAlgebraPool is
    IAlgebraPoolImmutables,
    IAlgebraPoolState,
    IAlgebraPoolDerivedState,
    IAlgebraPoolActions,
    IAlgebraPoolPermissionedActions,
    IAlgebraPoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.7.0;

interface IDataStorageOperator {
    /**
     * @notice Returns data belonging to a certain timepoint
     * @param index The index of timepoint in the array
     * @dev There is more convenient function to fetch a timepoint: observe(). Which requires not an index but seconds
     * @return initialized whether the timepoint has been initialized and the values are safe to use
     * blockTimestamp The timestamp of the observation,
     * tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the timepoint timestamp,
     * secondsPerLiquidityCumulative the seconds per in range liquidity for the life of the pool as of the timepoint timestamp,
     * volatilityCumulative Cumulative standard deviation for the life of the pool as of the timepoint timestamp
     * volumePerAvgLiquidity Cumulative swap volume per liquidity for the life of the pool as of the timepoint timestamp
     */
    function timepoints(uint256 index)
        external
        view
        returns (
            bool initialized,
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulative,
            uint112 volatilityCumulative,
            uint144 volumePerLiquidityCumulative
        );

    function initialize(uint32 time) external;

    function getSingleTimepoint(
        uint32 time,
        uint32 secondsAgo,
        int24 tick,
        uint16 index,
        uint128 liquidity
    )
        external
        view
        returns (
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulative,
            uint112 volatilityCumulative,
            uint256 volumePerAvgLiquidity
        );

    function getTimepoints(
        uint32 time,
        uint32[] memory secondsAgos,
        int24 tick,
        uint16 index,
        uint128 liquidity
    )
        external
        view
        returns (
            int56[] memory tickCumulatives,
            uint160[] memory secondsPerLiquidityCumulatives,
            uint112[] memory volatilityCumulatives,
            uint256[] memory volumePerAvgLiquiditys
        );

    function getAverages(
        uint32 time,
        int24 tick,
        uint16 index,
        uint128 liquidity
    ) external view returns (uint112 TWVolatilityAverage, uint256 TWVolumePerLiqAverage);

    function write(
        uint16 index,
        uint32 blockTimestamp,
        int24 tick,
        uint128 liquidity,
        uint128 volumePerLiquidity
    ) external returns (uint16 indexUpdated);

    function calculateVolumePerLiquidity(
        uint128 liquidity,
        int256 amount0,
        int256 amount1
    ) external pure returns (uint128 volumePerLiquidity);

    function timeAgo() external view returns (uint32);

    function getFee(
        uint32 _time,
        int24 _tick,
        uint16 _index,
        uint128 _liquidity
    ) external view returns (uint16 fee);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.7.6;

interface IAlgebraVirtualPool {
    function cross(int24 nextTick, bool zeroForOne) external;

    function finish(uint32 _endTimestamp, uint32 startTimestamp) external;

    function processSwap() external;

    function increaseCumulative(uint32 previousTimestamp, uint32 currentTimestamp) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.7.6;

import '../interfaces/pool/IAlgebraPoolState.sol';
import '../libraries/TickManager.sol';

abstract contract PoolState is IAlgebraPoolState {
    struct GlobalState {
        // The square root of the current price
        uint160 price;
        // The current tick
        int24 tick;
        uint16 fee;
        // The index of the last written timepoint
        uint16 timepointIndex;
        // The index of the last written (on swap) timepoint
        uint16 timepointIndexSwap;
        // The community fee represented as a denominator of the fraction of all collected fee
        uint8 communityFeeToken0;
        uint8 communityFeeToken1;
        // True if the contract is unlocked, otherwise - false
        bool unlocked;
    }

    // @inheritdoc IAlgebraPoolState
    uint256 public override totalFeeGrowth0Token;
    // @inheritdoc IAlgebraPoolState
    uint256 public override totalFeeGrowth1Token;
    // @inheritdoc IAlgebraPoolState
    GlobalState public override globalState;

    // Protocol fees of token0 and token1 apart
    struct CommunityFees {
        uint128 token0;
        uint128 token1;
    }
    // @inheritdoc IAlgebraPoolState
    CommunityFees public override communityFees;

    // @inheritdoc IAlgebraPoolState
    uint128 public override liquidity;
    uint128 internal volumePerLiquidityInBlock;

    // @inheritdoc IAlgebraPoolState
    mapping(int24 => TickManager.Tick) public override ticks;
    // @inheritdoc IAlgebraPoolState
    mapping(int16 => uint256) public override tickTable;

    // @dev Reentrancy protection. Implemented in every function of the contract since there are checks of balances.
    modifier lock() {
        require(globalState.unlocked, 'LOK');
        globalState.unlocked = false;
        _;
        globalState.unlocked = true;
    }

    /**
     * @dev This function is created for testing by overriding it.
     * @return A timestamp converted to uint32
     */
    function _blockTimestamp() internal view virtual returns (uint32) {
        return uint32(block.timestamp); // truncation is desired
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.7.6;

import '../interfaces/pool/IAlgebraPoolImmutables.sol';
import '../interfaces/IAlgebraPoolDeployer.sol';

abstract contract PoolImmutables is IAlgebraPoolImmutables {
    // @inheritdoc IAlgebraPoolImmutables
    address public immutable override dataStorageOperator;

    // @inheritdoc IAlgebraPoolImmutables
    address public immutable override factory;
    // @inheritdoc IAlgebraPoolImmutables
    address public immutable override token0;
    // @inheritdoc IAlgebraPoolImmutables
    address public immutable override token1;

    // @inheritdoc IAlgebraPoolImmutables
    uint8 public constant override tickSpacing = 60;

    // @inheritdoc IAlgebraPoolImmutables
    uint128 public constant override maxLiquidityPerTick = 11505743598341114571880798222544994;

    constructor(address deployer) {
        (dataStorageOperator, factory, token0, token1) = IAlgebraPoolDeployer(deployer).parameters();
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './LowGasSafeMath.sol';
import './SafeCast.sol';

import './FullMath.sol';
import './Constants.sol';

/// @title Functions based on Q64.96 sqrt price and liquidity
/// @notice Contains the math that uses square root of price as a Q64.96 and liquidity to compute deltas
library TokenDeltaMath {
    using LowGasSafeMath for uint256;
    using SafeCast for uint256;

    /// @notice Gets the token0 delta between two prices
    /// @dev Calculates liquidity / sqrt(lower) - liquidity / sqrt(upper),
    /// i.e. liquidity * (sqrt(upper) - sqrt(lower)) / (sqrt(upper) * sqrt(lower))
    /// @param priceLower A sqrt price
    /// @param priceUpper Another sqrt price
    /// @param liquidity The amount of usable liquidity
    /// @param roundUp Whether to round the amount up or down
    /// @return token0Delta Amount of token0 required to cover a position of size liquidity between the two passed prices
    function getToken0Delta(
        uint160 priceLower,
        uint160 priceUpper,
        uint128 liquidity,
        bool roundUp
    ) internal pure returns (uint256 token0Delta) {
        require(priceLower > 0);
        uint256 priceDelta = priceUpper - priceLower;
        uint256 liquidityShifted = uint256(liquidity) << Constants.RESOLUTION;

        token0Delta = roundUp
            ? FullMath.divRoundingUp(FullMath.mulDivRoundingUp(priceDelta, liquidityShifted, priceUpper), priceLower)
            : FullMath.mulDiv(priceDelta, liquidityShifted, priceUpper) / priceLower;
    }

    /// @notice Gets the token1 delta between two prices
    /// @dev Calculates liquidity * (sqrt(upper) - sqrt(lower))
    /// @param priceLower A sqrt price
    /// @param priceUpper Another sqrt price
    /// @param liquidity The amount of usable liquidity
    /// @param roundUp Whether to round the amount up, or down
    /// @return token1Delta Amount of token1 required to cover a position of size liquidity between the two passed prices
    function getToken1Delta(
        uint160 priceLower,
        uint160 priceUpper,
        uint128 liquidity,
        bool roundUp
    ) internal pure returns (uint256 token1Delta) {
        uint256 priceDelta = priceUpper - priceLower;
        token1Delta = roundUp
            ? FullMath.mulDivRoundingUp(priceDelta, liquidity, Constants.Q96)
            : FullMath.mulDiv(priceDelta, liquidity, Constants.Q96);
    }

    /// @notice Helper that gets signed token0 delta
    /// @param priceLower A sqrt price
    /// @param priceUpper Another sqrt price
    /// @param liquidity The change in liquidity for which to compute the token0 delta
    /// @return token0Delta Amount of token0 corresponding to the passed liquidityDelta between the two prices
    function getToken0Delta(
        uint160 priceLower,
        uint160 priceUpper,
        int128 liquidity
    ) internal pure returns (int256 token0Delta) {
        token0Delta = liquidity >= 0
            ? getToken0Delta(priceLower, priceUpper, uint128(liquidity), true).toInt256()
            : -getToken0Delta(priceLower, priceUpper, uint128(-liquidity), false).toInt256();
    }

    /// @notice Helper that gets signed token1 delta
    /// @param priceLower A sqrt price
    /// @param priceUpper Another sqrt price
    /// @param liquidity The change in liquidity for which to compute the token1 delta
    /// @return token1Delta Amount of token1 corresponding to the passed liquidityDelta between the two prices
    function getToken1Delta(
        uint160 priceLower,
        uint160 priceUpper,
        int128 liquidity
    ) internal pure returns (int256 token1Delta) {
        token1Delta = liquidity >= 0
            ? getToken1Delta(priceLower, priceUpper, uint128(liquidity), true).toInt256()
            : -getToken1Delta(priceLower, priceUpper, uint128(-liquidity), false).toInt256();
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './FullMath.sol';
import './TokenDeltaMath.sol';

/// @title Computes the result of price movement
/// @notice Contains methods for computing the result of price movement within a single tick price range.
library PriceMovementMath {
    using LowGasSafeMath for uint256;
    using SafeCast for uint256;

    /// @notice Gets the next sqrt price given an input amount of token0 or token1
    /// @dev Throws if price or liquidity are 0, or if the next price is out of bounds
    /// @param price The starting price, i.e., before accounting for the input amount
    /// @param liquidity The amount of usable liquidity
    /// @param input How much of token0, or token1, is being swapped in
    /// @param zeroForOne Whether the amount in is token0 or token1
    /// @return resultPrice The price after adding the input amount to token0 or token1
    function getNewPriceAfterInput(
        uint160 price,
        uint128 liquidity,
        uint256 input,
        bool zeroForOne
    ) internal pure returns (uint160 resultPrice) {
        return getNewPrice(price, liquidity, input, zeroForOne, true);
    }

    /// @notice Gets the next sqrt price given an output amount of token0 or token1
    /// @dev Throws if price or liquidity are 0 or the next price is out of bounds
    /// @param price The starting price before accounting for the output amount
    /// @param liquidity The amount of usable liquidity
    /// @param output How much of token0, or token1, is being swapped out
    /// @param zeroForOne Whether the amount out is token0 or token1
    /// @return resultPrice The price after removing the output amount of token0 or token1
    function getNewPriceAfterOutput(
        uint160 price,
        uint128 liquidity,
        uint256 output,
        bool zeroForOne
    ) internal pure returns (uint160 resultPrice) {
        return getNewPrice(price, liquidity, output, zeroForOne, false);
    }

    function getNewPrice(
        uint160 price,
        uint128 liquidity,
        uint256 amount,
        bool zeroForOne,
        bool fromInput
    ) internal pure returns (uint160 resultPrice) {
        require(price > 0);
        require(liquidity > 0);

        if (zeroForOne == fromInput) {
            // rounding up or down
            if (amount == 0) return price;
            uint256 liquidityShifted = uint256(liquidity) << Constants.RESOLUTION;

            if (fromInput) {
                uint256 product;
                if ((product = amount * price) / amount == price) {
                    uint256 denominator = liquidityShifted + product;
                    if (denominator >= liquidityShifted)
                        // always fits in 160 bits
                        return uint160(FullMath.mulDivRoundingUp(liquidityShifted, price, denominator));
                }

                return uint160(FullMath.divRoundingUp(liquidityShifted, (liquidityShifted / price).add(amount)));
            } else {
                uint256 product;
                // if the product overflows, we know the denominator underflows
                // in addition, we must check that the denominator does not underflow
                require((product = amount * price) / amount == price);
                require(liquidityShifted > product);
                return FullMath.mulDivRoundingUp(liquidityShifted, price, liquidityShifted - product).toUint160();
            }
        } else {
            // if we're adding (subtracting), rounding down requires rounding the quotient down (up)
            // in both cases, avoid a mulDiv for most inputs
            if (fromInput) {
                return
                    uint256(price)
                        .add(
                            amount <= type(uint160).max
                                ? (amount << Constants.RESOLUTION) / liquidity
                                : FullMath.mulDiv(amount, Constants.Q96, liquidity)
                        )
                        .toUint160();
            } else {
                uint256 quotient = amount <= type(uint160).max
                    ? FullMath.divRoundingUp(amount << Constants.RESOLUTION, liquidity)
                    : FullMath.mulDivRoundingUp(amount, Constants.Q96, liquidity);

                require(price > quotient);
                // always fits 160 bits
                return uint160(price - quotient);
            }
        }
    }

    function getTokenADelta01(
        uint160 to,
        uint160 from,
        uint128 liquidity
    ) internal pure returns (uint256) {
        return TokenDeltaMath.getToken0Delta(to, from, liquidity, true);
    }

    function getTokenADelta10(
        uint160 to,
        uint160 from,
        uint128 liquidity
    ) internal pure returns (uint256) {
        return TokenDeltaMath.getToken1Delta(from, to, liquidity, true);
    }

    function getTokenBDelta01(
        uint160 to,
        uint160 from,
        uint128 liquidity
    ) internal pure returns (uint256) {
        return TokenDeltaMath.getToken1Delta(to, from, liquidity, false);
    }

    function getTokenBDelta10(
        uint160 to,
        uint160 from,
        uint128 liquidity
    ) internal pure returns (uint256) {
        return TokenDeltaMath.getToken0Delta(from, to, liquidity, false);
    }

    /// @notice Computes the result of swapping some amount in, or amount out, given the parameters of the swap
    /// @dev The fee, plus the amount in, will never exceed the amount remaining if the swap's `amountSpecified` is positive
    /// @param currentPrice The current sqrt price of the pool
    /// @param targetPrice The price that cannot be exceeded, from which the direction of the swap is inferred
    /// @param liquidity The usable liquidity
    /// @param amountAvailable How much input or output amount is remaining to be swapped in/out
    /// @param fee The fee taken from the input amount, expressed in hundredths of a bip
    /// @return resultPrice The price after swapping the amount in/out, not to exceed the price target
    /// @return input The amount to be swapped in, of either token0 or token1, based on the direction of the swap
    /// @return output The amount to be received, of either token0 or token1, based on the direction of the swap
    /// @return feeAmount The amount of input that will be taken as a fee
    function movePriceTowardsTarget(
        bool zeroForOne,
        uint160 currentPrice,
        uint160 targetPrice,
        uint128 liquidity,
        int256 amountAvailable,
        uint24 fee
    )
        internal
        pure
        returns (
            uint160 resultPrice,
            uint256 input,
            uint256 output,
            uint256 feeAmount
        )
    {
        function(uint160, uint160, uint128) pure returns (uint256) getAmountA = zeroForOne
            ? getTokenADelta01
            : getTokenADelta10;

        if (amountAvailable >= 0) {
            // exactIn or not
            uint256 amountAvailableAfterFee = FullMath.mulDiv(uint256(amountAvailable), 1e6 - fee, 1e6);
            input = getAmountA(targetPrice, currentPrice, liquidity);
            if (amountAvailableAfterFee >= input) {
                resultPrice = targetPrice;
                feeAmount = FullMath.mulDivRoundingUp(input, fee, 1e6 - fee);
            } else {
                resultPrice = getNewPriceAfterInput(currentPrice, liquidity, amountAvailableAfterFee, zeroForOne);
                if (targetPrice != resultPrice) {
                    // != MAX
                    input = getAmountA(resultPrice, currentPrice, liquidity);

                    // we didn't reach the target, so take the remainder of the maximum input as fee
                    feeAmount = uint256(amountAvailable) - input;
                } else {
                    feeAmount = FullMath.mulDivRoundingUp(input, fee, 1e6 - fee);
                }
            }

            output = (zeroForOne ? getTokenBDelta01 : getTokenBDelta10)(resultPrice, currentPrice, liquidity);
        } else {
            function(uint160, uint160, uint128) pure returns (uint256) getAmountB = zeroForOne
                ? getTokenBDelta01
                : getTokenBDelta10;

            output = getAmountB(targetPrice, currentPrice, liquidity);
            if (uint256(-amountAvailable) >= output) resultPrice = targetPrice;
            else {
                resultPrice = getNewPriceAfterOutput(currentPrice, liquidity, uint256(-amountAvailable), zeroForOne);

                if (targetPrice != resultPrice) {
                    // != MAX
                    output = getAmountB(resultPrice, currentPrice, liquidity);
                }

                // cap the output amount to not exceed the remaining output amount
                if (output > uint256(-amountAvailable)) {
                    output = uint256(-amountAvailable);
                }
            }

            input = getAmountA(resultPrice, currentPrice, liquidity);
            feeAmount = FullMath.mulDivRoundingUp(input, fee, 1e6 - fee);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './LowGasSafeMath.sol';
import './SafeCast.sol';

import './TickMath.sol';
import './LiquidityMath.sol';

/// @title TickManager
/// @notice Contains functions for managing tick processes and relevant calculations
library TickManager {
    using LowGasSafeMath for int256;
    using SafeCast for int256;

    // info stored for each initialized individual tick
    struct Tick {
        // the total position liquidity that references this tick
        uint128 liquidityTotal;
        // amount of net liquidity added (subtracted) when tick is crossed from left to right (right to left),
        int128 liquidityDelta;
        // fee growth per unit of liquidity on the _other_ side of this tick (relative to the current tick)
        // only has relative meaning, not absolute — the value depends on when the tick is initialized
        uint256 outerFeeGrowth0Token;
        uint256 outerFeeGrowth1Token;
        // the cumulative tick value on the other side of the tick
        int56 outerTickCumulative;
        // the seconds per unit of liquidity on the _other_ side of this tick (relative to the current tick)
        // only has relative meaning, not absolute — the value depends on when the tick is initialized
        uint160 outerSecondsPerLiquidity;
        // the seconds spent on the other side of the tick (relative to the current tick)
        // only has relative meaning, not absolute — the value depends on when the tick is initialized
        uint32 outerSecondsSpent;
        // true iff the tick is initialized, i.e. the value is exactly equivalent to the expression liquidityTotal != 0
        // these 8 bits are set to prevent fresh sstores when crossing newly initialized ticks
        bool initialized;
    }

    /// @notice Retrieves fee growth data
    /// @param self The mapping containing all tick information for initialized ticks
    /// @param bottomTick The lower tick boundary of the position
    /// @param topTick The upper tick boundary of the position
    /// @param currentTick The current tick
    /// @param totalFeeGrowth0Token The all-time global fee growth, per unit of liquidity, in token0
    /// @param totalFeeGrowth1Token The all-time global fee growth, per unit of liquidity, in token1
    /// @return innerFeeGrowth0Token The all-time fee growth in token0, per unit of liquidity, inside the position's tick boundaries
    /// @return innerFeeGrowth1Token The all-time fee growth in token1, per unit of liquidity, inside the position's tick boundaries
    function getInnerFeeGrowth(
        mapping(int24 => Tick) storage self,
        int24 bottomTick,
        int24 topTick,
        int24 currentTick,
        uint256 totalFeeGrowth0Token,
        uint256 totalFeeGrowth1Token
    ) internal view returns (uint256 innerFeeGrowth0Token, uint256 innerFeeGrowth1Token) {
        Tick storage lower = self[bottomTick];
        Tick storage upper = self[topTick];

        if (currentTick < topTick) {
            if (currentTick >= bottomTick) {
                innerFeeGrowth0Token = totalFeeGrowth0Token - lower.outerFeeGrowth0Token;
                innerFeeGrowth1Token = totalFeeGrowth1Token - lower.outerFeeGrowth1Token;
            } else {
                innerFeeGrowth0Token = lower.outerFeeGrowth0Token;
                innerFeeGrowth1Token = lower.outerFeeGrowth1Token;
            }
            innerFeeGrowth0Token -= upper.outerFeeGrowth0Token;
            innerFeeGrowth1Token -= upper.outerFeeGrowth1Token;
        } else {
            innerFeeGrowth0Token = upper.outerFeeGrowth0Token - lower.outerFeeGrowth0Token;
            innerFeeGrowth1Token = upper.outerFeeGrowth1Token - lower.outerFeeGrowth1Token;
        }
    }

    /// @notice Updates a tick and returns true if the tick was flipped from initialized to uninitialized, or vice versa
    /// @param self The mapping containing all tick information for initialized ticks
    /// @param tick The tick that will be updated
    /// @param currentTick The current tick
    /// @param liquidityDelta A new amount of liquidity to be added (subtracted) when tick is crossed from left to right (right to left)
    /// @param totalFeeGrowth0Token The all-time global fee growth, per unit of liquidity, in token0
    /// @param totalFeeGrowth1Token The all-time global fee growth, per unit of liquidity, in token1
    /// @param secondsPerLiquidityCumulative The all-time seconds per max(1, liquidity) of the pool
    /// @param time The current block timestamp cast to a uint32
    /// @param upper true for updating a position's upper tick, or false for updating a position's lower tick
    /// @return flipped Whether the tick was flipped from initialized to uninitialized, or vice versa
    function update(
        mapping(int24 => Tick) storage self,
        int24 tick,
        int24 currentTick,
        int128 liquidityDelta,
        uint256 totalFeeGrowth0Token,
        uint256 totalFeeGrowth1Token,
        uint160 secondsPerLiquidityCumulative,
        int56 tickCumulative,
        uint32 time,
        bool upper
    ) internal returns (bool flipped) {
        Tick storage data = self[tick];

        uint128 liquidityTotalBefore = data.liquidityTotal;
        uint128 liquidityTotalAfter = LiquidityMath.addDelta(liquidityTotalBefore, liquidityDelta);
        require(liquidityTotalAfter <= 11505743598341114571880798222544994, 'LO');

        flipped = (liquidityTotalAfter == 0) != (liquidityTotalBefore == 0);

        if (liquidityTotalBefore == 0) {
            // by convention, we assume that all growth before a tick was initialized happened _below_ the tick
            if (tick <= currentTick) {
                data.outerFeeGrowth0Token = totalFeeGrowth0Token;
                data.outerFeeGrowth1Token = totalFeeGrowth1Token;
                data.outerSecondsPerLiquidity = secondsPerLiquidityCumulative;
                data.outerTickCumulative = tickCumulative;
                data.outerSecondsSpent = time;
            }
            data.initialized = true;
        }

        data.liquidityTotal = liquidityTotalAfter;

        // when the lower (upper) tick is crossed left to right (right to left), liquidity must be added (removed)
        data.liquidityDelta = upper
            ? int256(data.liquidityDelta).sub(liquidityDelta).toInt128()
            : int256(data.liquidityDelta).add(liquidityDelta).toInt128();
    }

    /// @notice Transitions to next tick as needed by price movement
    /// @param self The mapping containing all tick information for initialized ticks
    /// @param tick The destination tick of the transition
    /// @param totalFeeGrowth0Token The all-time global fee growth, per unit of liquidity, in token0
    /// @param totalFeeGrowth1Token The all-time global fee growth, per unit of liquidity, in token1
    /// @param secondsPerLiquidityCumulative The current seconds per liquidity
    /// @param time The current block.timestamp
    /// @return liquidityDelta The amount of liquidity added (subtracted) when tick is crossed from left to right (right to left)
    function cross(
        mapping(int24 => Tick) storage self,
        int24 tick,
        uint256 totalFeeGrowth0Token,
        uint256 totalFeeGrowth1Token,
        uint160 secondsPerLiquidityCumulative,
        int56 tickCumulative,
        uint32 time
    ) internal returns (int128 liquidityDelta) {
        Tick storage data = self[tick];
        data.outerFeeGrowth0Token = totalFeeGrowth0Token - data.outerFeeGrowth0Token;
        data.outerFeeGrowth1Token = totalFeeGrowth1Token - data.outerFeeGrowth1Token;
        data.outerSecondsPerLiquidity = secondsPerLiquidityCumulative - data.outerSecondsPerLiquidity;
        data.outerTickCumulative = tickCumulative - data.outerTickCumulative;
        data.outerSecondsSpent = time - data.outerSecondsSpent;
        liquidityDelta = data.liquidityDelta;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Packed tick initialized state library
/// @notice Stores a packed mapping of tick index to its initialized state
/// @dev The mapping uses int16 for keys since ticks are represented as int24 and there are 256 (2^8) values per word.
library TickTable {
    /// @notice Toggles the initialized state for a given tick from false to true, or vice versa
    /// @param self The mapping in which to toggle the tick
    /// @param tick The tick to toggle
    function toggleTick(mapping(int16 => uint256) storage self, int24 tick) internal {
        require(tick % 60 == 0, 'tick is not spaced'); // ensure that the tick is spaced
        tick /= 60; // compress tick
        int16 rowNumber;
        uint8 bitNumber;

        assembly {
            bitNumber := and(tick, 0xFF)
            rowNumber := shr(8, tick)
        }
        self[rowNumber] ^= 1 << bitNumber;
    }

    function getLeastSignificantBit(uint256 word) internal pure returns (uint8 leastBitPos) {
        require(word > 0);
        assembly {
            word := and(sub(0, word), word)
            leastBitPos := gt(and(word, 0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA), 0)
            leastBitPos := or(
                leastBitPos,
                shl(7, gt(and(word, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000000000000000000000000000), 0))
            )
            leastBitPos := or(
                leastBitPos,
                shl(6, gt(and(word, 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000), 0))
            )
            leastBitPos := or(
                leastBitPos,
                shl(5, gt(and(word, 0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000), 0))
            )
            leastBitPos := or(
                leastBitPos,
                shl(4, gt(and(word, 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000), 0))
            )
            leastBitPos := or(
                leastBitPos,
                shl(3, gt(and(word, 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00), 0))
            )
            leastBitPos := or(
                leastBitPos,
                shl(2, gt(and(word, 0xF0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0), 0))
            )
            leastBitPos := or(
                leastBitPos,
                shl(1, gt(and(word, 0xCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC), 0))
            )
        }
    }

    function getMostSignificantBit(uint256 word) internal pure returns (uint8 mostBitPos) {
        require(word > 0);
        assembly {
            word := or(word, shr(1, word))
            word := or(word, shr(2, word))
            word := or(word, shr(4, word))
            word := or(word, shr(8, word))
            word := or(word, shr(16, word))
            word := or(word, shr(32, word))
            word := or(word, shr(64, word))
            word := or(word, shr(128, word))
            word := sub(word, shr(1, word))
        }
        return (getLeastSignificantBit(word));
    }

    /// @notice Returns the next initialized tick contained in the same word (or adjacent word) as the tick that is either
    /// to the left (less than or equal to) or right (greater than) of the given tick
    /// @param self The mapping in which to compute the next initialized tick
    /// @param tick The starting tick
    /// @param lte Whether to search for the next initialized tick to the left (less than or equal to the starting tick)
    /// @return nextTick The next initialized or uninitialized tick up to 256 ticks away from the current tick
    /// @return initialized Whether the next tick is initialized, as the function only searches within up to 256 ticks
    function nextTickInTheSameRow(
        mapping(int16 => uint256) storage self,
        int24 tick,
        bool lte
    ) internal view returns (int24, bool) {
        // compress and round towards negative infinity if negative
        assembly {
            tick := sub(sdiv(tick, 60), and(slt(tick, 0), not(iszero(smod(tick, 60)))))
        }

        if (lte) {
            // unpacking not made into a separate function for gas and contract size savings
            int16 rowNumber;
            uint8 bitNumber;
            assembly {
                bitNumber := and(tick, 0xFF)
                rowNumber := shr(8, tick)
            }
            // all the 1s at or to the right of the current bitNumber
            uint256 _row = self[rowNumber] << (255 - bitNumber);

            if (_row != 0) {
                tick -= int24(255 - getMostSignificantBit(_row));
                return (uncompressAndBoundTick(tick), true);
            } else {
                tick -= int24(bitNumber);
                return (uncompressAndBoundTick(tick), false);
            }
        } else {
            // start from the word of the next tick, since the current tick state doesn't matter
            tick += 1;
            int16 rowNumber;
            uint8 bitNumber;
            assembly {
                bitNumber := and(tick, 0xFF)
                rowNumber := shr(8, tick)
            }

            // all the 1s at or to the left of the bitNumber
            uint256 _row = self[rowNumber] >> (bitNumber);

            if (_row != 0) {
                tick += int24(getLeastSignificantBit(_row));
                return (uncompressAndBoundTick(tick), true);
            } else {
                tick += int24(type(uint8).max - bitNumber);
                return (uncompressAndBoundTick(tick), false);
            }
        }
    }

    function uncompressAndBoundTick(int24 tick) private pure returns (int24 boundedTick) {
        boundedTick = tick * 60;
        if (boundedTick < -887272) {
            boundedTick = -887272;
        } else if (boundedTick > 887272) {
            boundedTick = 887272;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0;

/// @title Optimized overflow and underflow safe math operations
/// @notice Contains methods for doing math operations that revert on overflow or underflow for minimal gas cost
library LowGasSafeMath {
    /// @notice Returns x + y, reverts if sum overflows uint256
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    /// @notice Returns x * y, reverts if overflows
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @return z The product of x and y
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(x == 0 || (z = x * y) / x == y);
    }

    /// @notice Returns x + y, reverts if overflows or underflows
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x + y) >= x == (y >= 0));
    }

    /// @notice Returns x - y, reverts if overflows or underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x - y) <= x == (y >= 0));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
    /// @notice Cast a uint256 to a uint160, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint160
    function toUint160(uint256 y) internal pure returns (uint160 z) {
        require((z = uint160(y)) == y);
    }

    /// @notice Cast a int256 to a int128, revert on overflow or underflow
    /// @param y The int256 to be downcasted
    /// @return z The downcasted integer, now type int128
    function toInt128(int256 y) internal pure returns (int128 z) {
        require((z = int128(y)) == y);
    }

    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z The casted integer, now type int256
    function toInt256(uint256 y) internal pure returns (int256 z) {
        require(y < 2**255);
        z = int256(y);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = -denominator & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }

    /// @notice Returns ceil(x / y)
    /// @dev division by 0 has unspecified behavior, and must be checked externally
    /// @param x The dividend
    /// @param y The divisor
    /// @return z The quotient, ceil(x / y)
    function divRoundingUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := add(div(x, y), gt(mod(x, y), 0))
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

library Constants {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;
    uint16 internal constant BASE_FEE = 500;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '../interfaces/IERC20Minimal.sol';

/// @title TransferHelper
/// @notice Contains helper methods for interacting with ERC20 tokens that do not consistently return true/false
library TransferHelper {
    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Calls transfer on token contract, errors with TF if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20Minimal.transfer.selector, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TF');
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return price A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 price) {
        // get abs value
        int24 mask = tick >> (24 - 1);
        uint256 absTick = uint256((tick ^ mask) - mask);
        require(absTick <= uint256(MAX_TICK), 'T');

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        price = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case price < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param price The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 price) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(price >= MIN_SQRT_RATIO && price < MAX_SQRT_RATIO, 'R');
        uint256 ratio = uint256(price) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= price ? tickHi : tickLow;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math library for liquidity
library LiquidityMath {
    /// @notice Add a signed liquidity delta to liquidity and revert if it overflows or underflows
    /// @param x The liquidity before change
    /// @param y The delta by which liquidity should be changed
    /// @return z The liquidity delta
    function addDelta(uint128 x, int128 y) internal pure returns (uint128 z) {
        if (y < 0) {
            require((z = x - uint128(-y)) < x, 'LS');
        } else {
            require((z = x + uint128(y)) >= x, 'LA');
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/**
 * @title An interface for a contract that is capable of deploying Algebra Pools
 * @notice A contract that constructs a pool must implement this to pass arguments to the pool
 * @dev This is used to avoid having constructor arguments in the pool contract, which results in the init code hash
 * of the pool being constant allowing the CREATE2 address of the pool to be cheaply computed on-chain
 */
interface IAlgebraPoolDeployer {
    /**
     * @notice Get the parameters to be used in constructing the pool, set transiently during pool creation.
     * @dev Called by the pool constructor to fetch the parameters of the pool
     * Returns dataStorage The pools associated dataStorage
     * Returns factory The factory address
     * Returns token0 The first token of the pool by address sort order
     * Returns token1 The second token of the pool by address sort order
     */
    function parameters()
        external
        view
        returns (
            address dataStorage,
            address factory,
            address token0,
            address token1
        );

    /**
     * @dev Deploys a pool with the given parameters by transiently setting the parameters storage slot and then
     * clearing it after deploying the pool.
     * @param dataStorage The pools associated dataStorage
     * @param factory The contract address of the Algebra factory
     * @param token0 The first token of the pool by address sort order
     * @param token1 The second token of the pool by address sort order
     * @return pool The deployed pool's address
     */
    function deploy(
        address dataStorage,
        address factory,
        address token0,
        address token1
    ) external returns (address pool);

    /**
     * @dev Sets the factory address to the poolDeployer for permissioned actions
     * @param factory The address of the Algebra factory
     */
    function setFactory(address factory) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/**
 * @title The interface for the Algebra Factory
 */
interface IAlgebraFactory {
    /**
     *  @notice Emitted when the owner of the factory is changed
     *  @param oldOwner The owner before the owner was changed
     *  @param newOwner The owner after the owner was changed
     */
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /**
     *  @notice Emitted when a pool is created
     *  @param token0 The first token of the pool by address sort order
     *  @param token1 The second token of the pool by address sort order
     *  @param pool The address of the created pool
     */
    event PoolCreated(address indexed token0, address indexed token1, address pool);

    /**
     *  @notice Returns the current owner of the factory
     *  @dev Can be changed by the current owner via setOwner
     *  @return The address of the factory owner
     */
    function owner() external view returns (address);

    /**
     *  @notice Returns the current poolDeployerAddress
     *  @return The address of the poolDeployer
     */
    function poolDeployer() external view returns (address);

    /**
     * @dev Is retrieved from the pools to restrict calling
     * certain functions not by a staker contract
     * @return The staker contract address
     */
    function stakerAddress() external view returns (address);

    /**
     *  @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
     *  @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
     *  @param tokenA The contract address of either token0 or token1
     *  @param tokenB The contract address of the other token
     *  @return pool The pool address
     */
    function poolByPair(address tokenA, address tokenB) external view returns (address pool);

    /**
     *  @notice Creates a pool for the given two tokens and fee
     *  @param tokenA One of the two tokens in the desired pool
     *  @param tokenB The other of the two tokens in the desired pool
     *  @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
     *  from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
     *  are invalid.
     *  @return pool The address of the newly created pool
     */
    function createPool(address tokenA, address tokenB) external returns (address pool);

    /**
     *  @notice Updates the owner of the factory
     *  @dev Must be called by the current owner
     *  @param _owner The new owner of the factory
     */
    function setOwner(address _owner) external;

    /**
     * @dev updates staker address on the factory
     * @param _stakerAddress The new staker contract address
     */
    function setStakerAddress(address _stakerAddress) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Minimal ERC20 interface for Algebra
/// @notice Contains a subset of the full ERC20 interface that is used in Algebra
interface IERC20Minimal {
    /// @notice Returns the balance of a token
    /// @param account The account for which to look up the number of tokens it has, i.e. its balance
    /// @return The number of tokens held by the account
    function balanceOf(address account) external view returns (uint256);

    /// @notice Transfers the amount of token from the `msg.sender` to the recipient
    /// @param recipient The account that will receive the amount transferred
    /// @param amount The number of tokens to send from the sender to the recipient
    /// @return Returns true for a successful transfer, false for an unsuccessful transfer
    function transfer(address recipient, uint256 amount) external returns (bool);

    /// @notice Returns the current allowance given to a spender by an owner
    /// @param owner The account of the token owner
    /// @param spender The account of the token spender
    /// @return The current allowance granted by `owner` to `spender`
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Sets the allowance of a spender from the `msg.sender` to the value `amount`
    /// @param spender The account which will be allowed to spend a given amount of the owners tokens
    /// @param amount The amount of tokens allowed to be used by `spender`
    /// @return Returns true for a successful approval, false for unsuccessful
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Transfers `amount` tokens from `sender` to `recipient` up to the allowance given to the `msg.sender`
    /// @param sender The account from which the transfer will be initiated
    /// @param recipient The recipient of the transfer
    /// @param amount The amount of the transfer
    /// @return Returns true for a successful transfer, false for unsuccessful
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /// @notice Event emitted when tokens are transferred from one address to another, either via `#transfer` or `#transferFrom`.
    /// @param from The account from which the tokens were sent, i.e. the balance decreased
    /// @param to The account to which the tokens were sent, i.e. the balance increased
    /// @param value The amount of tokens that were transferred
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice Event emitted when the approval amount for the spender of a given owner's tokens changes.
    /// @param owner The account that approved spending of its tokens
    /// @param spender The account for which the spending allowance was modified
    /// @param value The new allowance from the owner to the spender
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IAlgebraPoolActions#mint
/// @notice Any contract that calls IAlgebraPoolActions#mint must implement this interface
interface IAlgebraMintCallback {
    /// @notice Called to `msg.sender` after minting liquidity to a position from IAlgebraPool#mint.
    /// @dev In the implementation you must pay the pool tokens owed for the minted liquidity.
    /// The caller of this method must be checked to be a AlgebraPool deployed by the canonical AlgebraFactory.
    /// @param amount0Owed The amount of token0 due to the pool for the minted liquidity
    /// @param amount1Owed The amount of token1 due to the pool for the minted liquidity
    /// @param data Any data passed through by the caller via the IAlgebraPoolActions#mint call
    function AlgebraMintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IAlgebraPoolActions#swap
/// @notice Any contract that calls IAlgebraPoolActions#swap must implement this interface
interface IAlgebraSwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IAlgebraPool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a AlgebraPool deployed by the canonical AlgebraFactory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IAlgebraPoolActions#swap call
    function AlgebraSwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/**
 *  @title Callback for IAlgebraPoolActions#flash
 *  @notice Any contract that calls IAlgebraPoolActions#flash must implement this interface
 */
interface IAlgebraFlashCallback {
    /**
     *  @notice Called to `msg.sender` after transferring to the recipient from IAlgebraPool#flash.
     *  @dev In the implementation you must repay the pool the tokens sent by flash plus the computed fee amounts.
     *  The caller of this method must be checked to be a AlgebraPool deployed by the canonical AlgebraFactory.
     *  @param fee0 The fee amount in token0 due to the pool by the end of the flash
     *  @param fee1 The fee amount in token1 due to the pool by the end of the flash
     *  @param data Any data passed through by the caller via the IAlgebraPoolActions#flash call
     */
    function AlgebraFlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import '../IDataStorageOperator.sol';

// @title Pool state that never changes
interface IAlgebraPoolImmutables {
    /**
     * @notice The contract that stores all the timepoints and can perform actions with them
     * @return The operator address
     */
    function dataStorageOperator() external view returns (address);

    /**
     * @notice The contract that deployed the pool, which must adhere to the IAlgebraFactory interface
     * @return The contract address
     */
    function factory() external view returns (address);

    /**
     * @notice The first of the two tokens of the pool, sorted by address
     * @return The token contract address
     */
    function token0() external view returns (address);

    /**
     * @notice The second of the two tokens of the pool, sorted by address
     * @return The token contract address
     */
    function token1() external view returns (address);

    /**
     * @notice The pool tick spacing
     * @dev Ticks can only be used at multiples of this value
     * e.g.: a tickSpacing of 60 means ticks can be initialized every 60th tick, i.e., ..., -120, -60, 0, 60, 120, ...
     * This value is an int24 to avoid casting even though it is always positive.
     * @return The tick spacing
     */
    function tickSpacing() external view returns (uint8);

    /**
     * @notice The maximum amount of position liquidity that can use any tick in the range
     * @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
     * also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
     * @return The max amount of liquidity per tick
     */
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

// @title Pool state that can change
interface IAlgebraPoolState {
    /**
     * @notice The globalState structure in the pool stores many values but requires only one slot
     * and is exposed as a single method to save gas when accessed externally.
     * @return price The current price of the pool as a sqrt(token1/token0) Q64.96 value
     * @return tick The current tick of the pool, i.e. according to the last tick transition that was run.
     * This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(price) if the price is on a tick
     * boundary.
     * timepointIndex The index of the last written timepoint
     * timepointIndexSwap The index of the last written (on swap) timepoint
     * communityFee The community fee for both tokens of the pool.
     * Encoded as two 4 bit values, where the community fee of token1 is shifted 4 bits and the community fee of token0
     * is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
     * unlocked Whether the pool is currently locked to reentrancy
     */
    function globalState()
        external
        view
        returns (
            uint160 price,
            int24 tick,
            uint16 fee,
            uint16 timepointIndex,
            uint16 timepointIndexSwap,
            uint8 communityFeeToken0,
            uint8 communityFeeToken1,
            bool unlocked
        );

    /**
     * @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
     * @dev This value can overflow the uint256
     */
    function totalFeeGrowth0Token() external view returns (uint256);

    /**
     * @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
     * @dev This value can overflow the uint256
     */
    function totalFeeGrowth1Token() external view returns (uint256);

    /**
     * @notice The amounts of token0 and token1 that are owed to the protocol
     * @dev Protocol fees will never exceed uint128 max in either token
     */
    function communityFees() external view returns (uint128 token0, uint128 token1);

    /**
     * @notice The currently in range liquidity available to the pool
     * @dev This value has no relationship to the total liquidity across all ticks
     */
    function liquidity() external view returns (uint128);

    /**
     * @notice The pool's fee in hundredths of a bip, i.e. 1e-6
     * @return The fee
     */
    //function fee() external view returns (uint24);

    /**
     * @notice Look up information about a specific tick in the pool
     * @param tick The tick to look up
     * @return liquidityTotal the total amount of position liquidity that uses the pool either as tick lower or
     * tick upper,
     * @return liquidityDelta how much liquidity changes when the pool price crosses the tick,
     * outerFeeGrowth0Token the fee growth on the other side of the tick from the current tick in token0,
     * outerFeeGrowth1Token the fee growth on the other side of the tick from the current tick in token1,
     * outerTickCumulative the cumulative tick value on the other side of the tick from the current tick
     * outerSecondsPerLiquidity the seconds spent per liquidity on the other side of the tick from the current tick,
     * outerSecondsSpent the seconds spent on the other side of the tick from the current tick,
     * initialized Set to true if the tick is initialized, i.e. liquidityTotal is greater than 0,
     * otherwise equal to false. Outside values can only be used if the tick is initialized.
     * In addition, these values are only relative and must be used only in comparison to previous snapshots for
     * a specific position.
     */
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityTotal,
            int128 liquidityDelta,
            uint256 outerFeeGrowth0Token,
            uint256 outerFeeGrowth1Token,
            int56 outerTickCumulative,
            uint160 outerSecondsPerLiquidity,
            uint32 outerSecondsSpent,
            bool initialized
        );

    /** @notice Returns 256 packed tick initialized boolean values. See TickTable for more information */
    function tickTable(int16 wordPosition) external view returns (uint256);

    /**
     * @notice Returns the information about a position by the position's key
     * @param key The position's key is a hash of a preimage composed by the owner, bottomTick and topTick
     * @return  _liquidity The amount of liquidity in the position,
     * innerFeeGrowth0Token fee growth of token0 inside the tick range as of the last mint/burn/poke,
     * innerFeeGrowth1Token fee growth of token1 inside the tick range as of the last mint/burn/poke,
     * fees0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
     * fees1 the computed amount of token1 owed to the position as of the last mint/burn/poke
     */
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 innerFeeGrowth0Token,
            uint256 innerFeeGrowth1Token,
            uint128 fees0,
            uint128 fees1
        );

    /**
     * @notice Returns data about a specific timepoint index
     * @param index The element of the timepoints array to fetch
     * @dev You most likely want to use #getTimepoints() instead of this method to get an timepoint as of some amount of time
     * ago, rather than at a specific index in the array.
     * @return initialized whether the timepoint has been initialized and the values are safe to use
     * blockTimestamp The timestamp of the timepoint,
     * tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the timepoint timestamp,
     * secondsPerLiquidityCumulative the seconds per in range liquidity for the life of the pool as of the timepoint timestamp,
     * volatilityCumulative Cumulative standard deviation for the life of the pool as of the timepoint timestamp
     * volumePerAvgLiquidity Cumulative swap volume per liquidity for the life of the pool as of the timepoint timestamp
     */
    function timepoints(uint256 index)
        external
        view
        returns (
            bool initialized,
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulative,
            uint112 volatilityCumulative,
            uint256 volumePerAvgLiquidity
        );

    /**
     * @notice Returns the information about active incentive
     * @dev if there is no active incentive at the moment, virtualPool,endTimestamp,startTimestamp would be equal to 0
     * @return virtualPool The address of a virtual pool associated with the current active incentive
     * endTimestamp The timestamp when the active incentive is finished
     * startTimestamp The first swap after this timestamp is going to initialize the virtual pool
     */
    function activeIncentive()
        external
        view
        returns (
            address virtualPool,
            uint32 endTimestamp,
            uint32 startTimestamp
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/**
 * @title Pool state that is not stored
 * @notice Contains view functions to provide information about the pool that is computed rather than stored on the
 * blockchain. The functions here may have variable gas costs.
 */
interface IAlgebraPoolDerivedState {
    /**
     * @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
     * @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
     * the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
     * you must call it with secondsAgos = [3600, 0].
     * @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
     * log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
     * @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
     * @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
     * @return secondsPerLiquidityCumulatives Cumulative seconds per liquidity-in-range value as of each `secondsAgos`
     * from the current block timestamp
     * @return volatilityCumulatives Cumulative standard deviation as of each `secondsAgos`
     * @return volumePerAvgLiquiditys Cumulative swap volume per liquidity as of each `secondsAgos`
     */
    function getTimepoints(uint32[] calldata secondsAgos)
        external
        view
        returns (
            int56[] memory tickCumulatives,
            uint160[] memory secondsPerLiquidityCumulatives,
            uint112[] memory volatilityCumulatives,
            uint256[] memory volumePerAvgLiquiditys
        );

    /**
     * @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
     * @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
     * I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
     * snapshot is taken and the second snapshot is taken.
     * @param bottomTick The lower tick of the range
     * @param topTick The upper tick of the range
     * @return innerTickCumulative The snapshot of the tick accumulator for the range
     * @return innerSecondsSpentPerLiquidity The snapshot of seconds per liquidity for the range
     * @return innerSecondsSpent The snapshot of seconds per liquidity for the range
     */
    function getInnerCumulatives(int24 bottomTick, int24 topTick)
        external
        view
        returns (
            int56 innerTickCumulative,
            uint160 innerSecondsSpentPerLiquidity,
            uint32 innerSecondsSpent
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

// @title Permissionless pool actions
interface IAlgebraPoolActions {
    /**
     * @notice Sets the initial price for the pool
     * @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
     * @param price the initial sqrt price of the pool as a Q64.96
     */
    function initialize(uint160 price) external;

    /**
     * @notice Adds liquidity for the given recipient/bottomTick/topTick position
     * @dev The caller of this method receives a callback in the form of IAlgebraMintCallback# AlgebraMintCallback
     * in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
     * on bottomTick, topTick, the amount of liquidity, and the current price.
     * @param recipient The address for which the liquidity will be created
     * @param bottomTick The lower tick of the position in which to add liquidity
     * @param topTick The upper tick of the position in which to add liquidity
     * @param amount The amount of liquidity to mint
     * @param data Any data that should be passed through to the callback
     * @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
     * amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
     */
    function mint(
        address sender,
        address recipient,
        int24 bottomTick,
        int24 topTick,
        uint128 amount,
        bytes calldata data
    )
        external
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 liquidityAmount
        );

    /**
     *  @notice Collects tokens owed to a position
     *  @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
     *  Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
     *  amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
     *  actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
     *  @param recipient The address which should receive the fees collected
     *  @param bottomTick The lower tick of the position for which to collect fees
     *  @param topTick The upper tick of the position for which to collect fees
     *  @param amount0Requested How much token0 should be withdrawn from the fees owed
     *  @param amount1Requested How much token1 should be withdrawn from the fees owed
     *  @return amount0 The amount of fees collected in token0
     *  amount1 The amount of fees collected in token1
     */
    function collect(
        address recipient,
        int24 bottomTick,
        int24 topTick,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /**
     *  @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
     *  @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
     *  @dev Fees must be collected separately via a call to #collect
     *  @param bottomTick The lower tick of the position for which to burn liquidity
     *  @param topTick The upper tick of the position for which to burn liquidity
     *  @param amount How much liquidity to burn
     *  @return amount0 The amount of token0 sent to the recipient
     *  amount1 The amount of token1 sent to the recipient
     */
    function burn(
        int24 bottomTick,
        int24 topTick,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /**
     *  @notice Swap token0 for token1, or token1 for token0
     *  @dev The caller of this method receives a callback in the form of IAlgebraSwapCallback# AlgebraSwapCallback
     *  @param recipient The address to receive the output of the swap
     *  @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
     *  @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
     *  @param limitSqrtPrice The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
     *  value after the swap. If one for zero, the price cannot be greater than this value after the swap
     *  @param data Any data to be passed through to the callback. If using the Router it should contain
     *  SwapRouter#SwapCallbackData
     *  @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
     *  amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
     */
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 limitSqrtPrice,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /**
     *  @notice Swap token0 for token1, or token1 for token0 (tokens that have fee on transfer)
     *  @dev The caller of this method receives a callback in the form of I AlgebraSwapCallback# AlgebraSwapCallback
     *  @param sender The address called this function (Comes from the Router)
     *  @param recipient The address to receive the output of the swap
     *  @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
     *  @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
     *  @param limitSqrtPrice The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
     *  value after the swap. If one for zero, the price cannot be greater than this value after the swap
     *  @param data Any data to be passed through to the callback. If using the Router it should contain
     *  SwapRouter#SwapCallbackData
     *  @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
     *  amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
     */
    function swapSupportingFeeOnInputTokens(
        address sender,
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 limitSqrtPrice,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /**
     *  @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
     *  @dev The caller of this method receives a callback in the form of IAlgebraFlashCallback# AlgebraFlashCallback
     *  @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
     *  with 0 amount{0,1} and sending the donation amount(s) from the callback
     *  @param recipient The address which will receive the token0 and token1 amounts
     *  @param amount0 The amount of token0 to send
     *  @param amount1 The amount of token1 to send
     *  @param data Any data to be passed through to the callback
     */
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/**
 * @title Permissioned pool actions
 * @notice Contains pool methods that may only be called by the factory owner or staker
 */
interface IAlgebraPoolPermissionedActions {
    /**
     * @notice Set the denominator of the protocol's % share of the fees
     * @param communityFee0 new community fee for token0 of the pool
     * @param communityFee1 new community fee for token1 of the pool
     */
    function setCommunityFee(uint8 communityFee0, uint8 communityFee1) external;

    /**
     * @notice Sets an active incentive
     * @param virtualPoolAddress The address of a virtual pool associated with the incentive
     * @param endTimestamp The timestamp when the active incentive is finished
     * @param startTimestamp The first swap after this timestamp is going to initialize the virtual pool
     */
    function setIncentive(
        address virtualPoolAddress,
        uint32 endTimestamp,
        uint32 startTimestamp
    ) external;

    /**
     * @notice Collect the community fee accrued to the pool
     * @param recipient The address to which collected community fees should be sent
     * @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
     * @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
     * @return amount0 The community fee collected in token0
     * amount1 The community fee collected in token1
     */
    function collectCommunityFee(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

// @title Events emitted by a pool
interface IAlgebraPoolEvents {
    /**
     * @notice Emitted exactly once by a pool when #initialize is first called on the pool
     * @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
     * @param price The initial sqrt price of the pool, as a Q64.96
     * @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
     */
    event Initialize(uint160 price, int24 tick);

    /**
     * @notice Emitted when liquidity is minted for a given position
     * @param sender The address that minted the liquidity
     * @param owner The owner of the position and recipient of any minted liquidity
     * @param bottomTick The lower tick of the position
     * @param topTick The upper tick of the position
     * @param amount The amount of liquidity minted to the position range
     * @param amount0 How much token0 was required for the minted liquidity
     * @param amount1 How much token1 was required for the minted liquidity
     */
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed bottomTick,
        int24 indexed topTick,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /**
     * @notice Emitted when fees are collected by the owner of a position
     * @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
     * @param owner The owner of the position for which fees are collected
     * @param bottomTick The lower tick of the position
     * @param topTick The upper tick of the position
     * @param amount0 The amount of token0 fees collected
     * @param amount1 The amount of token1 fees collected
     */
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed bottomTick,
        int24 indexed topTick,
        uint128 amount0,
        uint128 amount1
    );

    /**
     * @notice Emitted when a position's liquidity is removed
     * @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
     * @param owner The owner of the position for which liquidity is removed
     * @param bottomTick The lower tick of the position
     * @param topTick The upper tick of the position
     * @param amount The amount of liquidity to remove
     * @param amount0 The amount of token0 withdrawn
     * @param amount1 The amount of token1 withdrawn
     */
    event Burn(
        address indexed owner,
        int24 indexed bottomTick,
        int24 indexed topTick,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /**
     * @notice Emitted by the pool for any swaps between token0 and token1
     * @param sender The address that initiated the swap call, and that received the callback
     * @param recipient The address that received the output of the swap
     * @param amount0 The delta of the token0 balance of the pool
     * @param amount1 The delta of the token1 balance of the pool
     * @param price The sqrt(price) of the pool after the swap, as a Q64.96
     * @param liquidity The liquidity of the pool after the swap
     * @param tick The log base 1.0001 of price of the pool after the swap
     */
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 price,
        uint128 liquidity,
        int24 tick
    );

    /**
     * @notice Emitted by the pool for any flashes of token0/token1
     * @param sender The address that initiated the swap call, and that received the callback
     * @param recipient The address that received the tokens from flash
     * @param amount0 The amount of token0 that was flashed
     * @param amount1 The amount of token1 that was flashed
     * @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
     * @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
     */
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /**
     * @notice Emitted when the community fee is changed by the pool
     * @param communityFee0Old The previous value of the token0 community fee
     * @param communityFee1Old The previous value of the token1 community fee
     * @param communityFee0New The updated value of the token0 community fee
     * @param communityFee1New The updated value of the token1 community fee
     */
    event SetCommunityFee(
        uint8 communityFee0Old,
        uint8 communityFee1Old,
        uint8 communityFee0New,
        uint8 communityFee1New
    );

    /**
     * @notice Emitted when the collected community fees are withdrawn by the factory owner
     * @param sender The address that collects the community fees
     * @param recipient The address that receives the collected community fees
     * @param amount0 The amount of token0 community fees that is withdrawn
     * @param amount0 The amount of token1 community fees that is withdrawn
     */
    event CollectCommunityFee(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);

    /**
     * @notice Emitted when new activeIncentive is set
     * @param virtualPoolAddress The address of a virtual pool associated with the current active incentive
     * @param endTimestamp The timestamp when the active incentive is finished
     * @param startTimestamp The first swap after this timestamp is going to initialize the virtual pool
     */
    event IncentiveSet(address virtualPoolAddress, uint32 endTimestamp, uint32 startTimestamp);
    /**
     * @notice Emitted when the fee changes
     * @param Fee The value of the token fee
     */
    event ChangeFee(uint16 Fee);
}