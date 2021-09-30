// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;

import './FuzzyswapPool.sol';

contract FuzzyswapPoolDeployer{
    struct Parameters {
        address dataStorage;
        address factory;
        address token0;
        address token1;
    }

    Parameters public parameters;

    address private factory;
    address private owner;

    modifier onlyFactory(){
        require(msg.sender == factory);
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    constructor(){
        owner = msg.sender;
    }

    function setFactory(address _factory) external onlyOwner{
        require(factory == address(0));
        factory = _factory;
    }

    /// @dev Deploys a pool with the given parameters by transiently setting the parameters storage slot and then
    /// clearing it after deploying the pool.
    /// @param dataStorage The address of contract's dataStorage
    /// @param _factory The contract address of the Uniswap V3 factory
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    function deploy(
        address dataStorage,
        address _factory,
        address token0,
        address token1
    ) external onlyFactory returns (address pool) {
        parameters = Parameters({dataStorage: dataStorage, factory: _factory, token0: token0, token1: token1});
        pool = address(new FuzzyswapPool{salt: keccak256(abi.encode(token0, token1))}());
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;

import './interfaces/IFuzzyswapPool.sol';
import './interfaces/IDataStorageOperator.sol';
import './interfaces/IFuzzyswapVirtualPool.sol';

// LICENSED

//import './libraries/Oracle.sol';
import './libraries/Position.sol';
import './libraries/SqrtPriceMath.sol';
import './libraries/SwapMath.sol';
import './libraries/Tick.sol';
import './libraries/TickTable.sol';

// UNLICENSED

import './libraries/LowGasSafeMath.sol';
import './libraries/SafeCast.sol';

import './libraries/FullMath.sol';
import './libraries/Constants.sol';
import './libraries/TransferHelper.sol';
import './libraries/TickMath.sol';
import './libraries/LiquidityMath.sol';

import './interfaces/IFuzzyswapPoolDeployer.sol';
import './interfaces/IFuzzyswapFactory.sol';
import './interfaces/IERC20Minimal.sol';
import './interfaces/callback/IFuzzyswapMintCallback.sol';
import './interfaces/callback/IFuzzyswapSwapCallback.sol';
import './interfaces/callback/IFuzzyswapFlashCallback.sol';

contract FuzzyswapPool is IFuzzyswapPool {
    using LowGasSafeMath for uint256;
    using LowGasSafeMath for int256;
    using SafeCast for uint256;
    using SafeCast for int256;
    using TickTable for mapping(int16 => uint256);
    using Tick for mapping(int24 => Tick.Data);
    using Position for Position.Data;
    using Position for mapping(bytes32 => Position.Data);

    IDataStorageOperator public immutable override dataStorageOperator;
    /// @inheritdoc IFuzzyswapPoolImmutables
    address public immutable override factory;
    /// @inheritdoc IFuzzyswapPoolImmutables
    address public immutable override token0;
    /// @inheritdoc IFuzzyswapPoolImmutables
    address public immutable override token1;
    uint24 public override fee;
    uint24 private constant fee_ = 500;

    /// @inheritdoc IFuzzyswapPoolImmutables
    uint8 public constant override tickSpacing = 60;
    
    /// @inheritdoc IFuzzyswapPoolImmutables
    uint128 public constant override maxLiquidityPerTick = 11505743598341114571880798222544994;

    struct GlobalState {
        // the current price
        uint160 sqrtPriceX96;
        // the current tick
        int24 tick;
        // the most-recently updated index of the observations array
        uint16 observationIndex;
        // the most-recently updated index of the observations written on swap
        uint16 observationIndexSwap;
        // the current protocol fee as a percentage of the swap fee taken on withdrawal
        // represented as an integer denominator (1/x)%
        uint8 feeProtocol;
        // whether the pool is locked
        bool unlocked;
    }

    /// @inheritdoc IFuzzyswapPoolState
    uint256 public override totalFeeGrowth0Token;
    /// @inheritdoc IFuzzyswapPoolState
    uint256 public override totalFeeGrowth1Token;
    /// @inheritdoc IFuzzyswapPoolState
    GlobalState public override globalState;

    // accumulated protocol fees in token0/token1 units
    struct ProtocolFees {
        uint128 token0;
        uint128 token1;
    }
    /// @inheritdoc IFuzzyswapPoolState
    ProtocolFees public override protocolFees;

    /// @inheritdoc IFuzzyswapPoolState
    uint128 public override liquidity;

    /// @inheritdoc IFuzzyswapPoolState
    mapping(int24 => Tick.Data) public override ticks;
    /// @inheritdoc IFuzzyswapPoolState
    mapping(int16 => uint256) public override tickTable;
    /// @inheritdoc IFuzzyswapPoolState
    mapping(bytes32 => Position.Data) public override positions;

    struct Incentive {
        address virtualPool;
        uint32 endTimestamp;
        uint32 startTimestamp;
    }

    Incentive public activeIncentive;

    /// @dev Mutually exclusive reentrancy protection into the pool to/from a method. This method also prevents entrance
    /// to a function before the pool is initialized. The reentrancy guard is required throughout the contract because
    /// we use balance checks to determine the payment status of interactions such as mint, swap and flash.
    modifier lock() {
        require(globalState.unlocked, 'LOK');
        globalState.unlocked = false;
        _;
        globalState.unlocked = true;
    }

    /// @dev Prevents calling a function from anyone except the address returned by IFuzzyswapFactory#owner()
    modifier onlyFactoryOwner() {
        require(msg.sender == IFuzzyswapFactory(factory).owner());
        _;
    }

    constructor() {
        address _dataStorageOperator;
        (_dataStorageOperator, factory, token0, token1) = IFuzzyswapPoolDeployer(msg.sender).parameters();
        dataStorageOperator = IDataStorageOperator(_dataStorageOperator);
        fee = fee_;
    }

    /// @dev Get the pool's balance of token0
    /// @dev This function is gas optimized to avoid a redundant extcodesize check in addition to the returndatasize
    /// check
    function balanceToken0() private view returns (uint256) {
        (bool success, bytes memory data) =
            token0.staticcall(abi.encodeWithSelector(IERC20Minimal.balanceOf.selector, address(this)));
        require(success && data.length >= 32);
        return abi.decode(data, (uint256));
    }

    /// @dev Get the pool's balance of token1
    /// @dev This function is gas optimized to avoid a redundant extcodesize check in addition to the returndatasize
    /// check
    function balanceToken1() private view returns (uint256) {
        (bool success, bytes memory data) =
            token1.staticcall(abi.encodeWithSelector(IERC20Minimal.balanceOf.selector, address(this)));
        require(success && data.length >= 32);
        return abi.decode(data, (uint256));
    }

    function observations(uint256 index)
        external
        override
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulative,
            uint112 volatilityCumulative,
            bool initialized,
            uint256 volumePerAvgLiquidity
        ){
        return dataStorageOperator.observations(index);
    }

    /// @dev Common checks for valid tick inputs.
    function tickValidation(int24 bottomTick, int24 topTick) private pure {
        require(bottomTick < topTick, 'TLU');
        require(bottomTick >= TickMath.MIN_TICK, 'TLM');
        require(topTick <= TickMath.MAX_TICK, 'TUM');
    }

    /// @dev Returns the block timestamp truncated to 32 bits, i.e. mod 2**32. This method is overridden in tests.
    function _blockTimestamp() internal view virtual returns (uint32) {
        return uint32(block.timestamp); // truncation is desired
    }

    struct cumulatives{
        int56 tickCumulative;
        uint160 outerSecondPerLiquidity;
        uint32 outerSecondsSpent;
    }

    /// @inheritdoc IFuzzyswapPoolDerivedState
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
            Tick.Data storage _lower = ticks[bottomTick];
            Tick.Data storage _upper = ticks[topTick];
            (
                lower.tickCumulative,
                lower.outerSecondPerLiquidity,
                lower.outerSecondsSpent
            ) = (
                _lower.outerTickCumulative,
                _lower.outerSecondsPerLiquidity,
                _lower.outerSecondsSpent
            );

            (
                upper.tickCumulative,
                upper.outerSecondPerLiquidity,
                upper.outerSecondsSpent
            ) = (
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
            (int56 globalTickCumulative, uint160 globalSecondsPerLiquidityCumulative,,) =
                dataStorageOperator.observeSingle(
                    globalTime,
                    0,
                    _globalState.tick,
                    _globalState.observationIndex,
                    liquidity
                );
            return (
                globalTickCumulative -
                    lower.tickCumulative -
                    upper.tickCumulative,
                globalSecondsPerLiquidityCumulative -
                    lower.outerSecondPerLiquidity -
                    upper.outerSecondPerLiquidity,
                globalTime -
                lower.outerSecondsSpent -
                upper.outerSecondsSpent
            );
        } else {
            return (
                upper.tickCumulative - lower.tickCumulative,
                upper.outerSecondPerLiquidity - lower.outerSecondPerLiquidity,
                upper.outerSecondsSpent - lower.outerSecondsSpent
            );
        }
    }

    /// @inheritdoc IFuzzyswapPoolDerivedState
    function observe(uint32[] calldata secondsAgos)
        external
        view
        override
        returns (int56[] memory tickCumulatives,
                uint160[] memory secondsPerLiquidityCumulatives,
                uint112[] memory volatilityCumulatives,
                uint256[] memory volumePerAvgLiquiditys)
    {
        return
            dataStorageOperator.observe(
                _blockTimestamp(),
                secondsAgos,
                globalState.tick,
                globalState.observationIndex,
                liquidity
            );
    }

    /// @inheritdoc IFuzzyswapPoolActions
    /// @dev not locked because it initializes unlocked
    function initialize(uint160 sqrtPriceX96) external override {
        require(globalState.sqrtPriceX96 == 0);

        int24 tick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);

        dataStorageOperator.initialize(_blockTimestamp());

        globalState = GlobalState({
            sqrtPriceX96: sqrtPriceX96,
            tick: tick,
            observationIndex: 0,
            observationIndexSwap: 0,
            feeProtocol: 0,
            unlocked: true
        });

        emit Initialize(sqrtPriceX96, tick);
    }

    struct ModifyPositionParams {
        // the address that owns the position
        address owner;
        // the lower and upper tick of the position
        int24 bottomTick;
        int24 topTick;
        // any change in liquidity
        int128 liquidityDelta;
    }

    /// @dev Effect some changes to a position
    /// @param params the position details and the change to the position's liquidity to effect
    /// @return position a storage pointer referencing the position with the given owner and tick range
    /// @return amount0 the amount of token0 owed to the pool, negative if the pool should pay the recipient
    /// @return amount1 the amount of token1 owed to the pool, negative if the pool should pay the recipient
    function _modifyPosition(ModifyPositionParams memory params)
        private
        returns (
            Position.Data storage position,
            int256 amount0,
            int256 amount1
        )
    {

        GlobalState memory _globalState = globalState; // SLOAD for gas optimization

        position = _applyLiquidityDeltaToPosition(
            params.owner,
            params.bottomTick,
            params.topTick,
            params.liquidityDelta,
            _globalState.tick
        );

        if (params.liquidityDelta != 0) {
             int128 globalLiquidityDelta;
            (amount0, amount1, globalLiquidityDelta) = _getAmountsForLiquidity(
                params.bottomTick, 
                params.topTick,
                params.liquidityDelta,
                _globalState);
            if (globalLiquidityDelta != 0) {
                uint128 liquidityBefore = liquidity; // SLOAD for gas optimization
                    globalState.observationIndex = dataStorageOperator.write(
                    _globalState.observationIndex,
                    _blockTimestamp(),
                    _globalState.tick,
                    liquidityBefore,
                    0,
                    0
                );

                _changeFee(_blockTimestamp(), _globalState.tick, globalState.observationIndex, liquidityBefore);
                liquidity = LiquidityMath.addDelta(liquidityBefore, params.liquidityDelta);
            }
        }
    }

    function _getAmountsForLiquidity (
        int24 bottomTick,
        int24 topTick,
        int128 liquidityDelta,
        GlobalState memory _globalState) 
    private pure
    returns(int256 amount0, int256 amount1, int128 globalLiquidityDelta) {
            if (_globalState.tick < bottomTick) {
                // current tick is below the passed range; liquidity can only become in range by crossing from left to
                // right, when we'll need _more_ token0 (it's becoming more valuable) so user must provide it
                amount0 = SqrtPriceMath.getAmount0Delta(
                    TickMath.getSqrtRatioAtTick(bottomTick),
                    TickMath.getSqrtRatioAtTick(topTick),
                    liquidityDelta
                );
            } else if (_globalState.tick < topTick) {
                // current tick is inside the passed range

                amount0 = SqrtPriceMath.getAmount0Delta(
                    _globalState.sqrtPriceX96,
                    TickMath.getSqrtRatioAtTick(topTick),
                    liquidityDelta
                );
                amount1 = SqrtPriceMath.getAmount1Delta(
                    TickMath.getSqrtRatioAtTick(bottomTick),
                    _globalState.sqrtPriceX96,
                    liquidityDelta
                );

                globalLiquidityDelta = liquidityDelta;
            } else {
                // current tick is above the passed range; liquidity can only become in range by crossing from right to
                // left, when we'll need _more_ token1 (it's becoming more valuable) so user must provide it
                amount1 = SqrtPriceMath.getAmount1Delta(
                    TickMath.getSqrtRatioAtTick(bottomTick),
                    TickMath.getSqrtRatioAtTick(topTick),
                    liquidityDelta
                );
            }
    }

    /// @notice Returns the Info struct of a position, given an owner and position boundaries
    /// @param owner The address of the position owner
    /// @param bottomTick The lower tick boundary of the position
    /// @param topTick The upper tick boundary of the position
    /// @return position The position info struct of the given owners' position
    function getOrCreatePosition(
        address owner,
        int24 bottomTick,
        int24 topTick
    ) private view returns (Position.Data storage) {
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

    /// @dev Gets and updates a position with the given liquidity delta
    /// @param owner the owner of the position
    /// @param bottomTick the lower tick of the position's tick range
    /// @param topTick the upper tick of the position's tick range
    /// @param tick the current tick, passed to avoid sloads
    function _applyLiquidityDeltaToPosition(
        address owner,
        int24 bottomTick,
        int24 topTick,
        int128 liquidityDelta,
        int24 tick
    ) private returns (Position.Data storage position) {
        position = getOrCreatePosition(owner, bottomTick, topTick);

        // SLOAD for gas optimization
        (uint256 _totalFeeGrowth0Token, uint256 _totalFeeGrowth1Token) = (totalFeeGrowth0Token, totalFeeGrowth1Token);

        // if we need to update the ticks, do it
        bool flippedBottom;
        bool flippedTop;
        if (liquidityDelta != 0) {
            uint32 time = _blockTimestamp();
            (int56 tickCumulative, uint160 secondsPerLiquidityCumulative,,) =
                dataStorageOperator.observeSingle(
                    time,
                    0,
                    globalState.tick,
                    globalState.observationIndex,
                    liquidity
                );

            if (ticks.update(
                bottomTick,
                tick,
                liquidityDelta,
                _totalFeeGrowth0Token,
                _totalFeeGrowth1Token,
                secondsPerLiquidityCumulative,
                tickCumulative,
                time,
                false
            )) {
                flippedBottom = true;
                tickTable.flipTick(bottomTick);
            }

            if (ticks.update(
                topTick,
                tick,
                liquidityDelta,
                _totalFeeGrowth0Token,
                _totalFeeGrowth1Token,
                secondsPerLiquidityCumulative,
                tickCumulative,
                time,
                true
            )) {
                flippedTop = true;
                tickTable.flipTick(topTick);
            }
        }

        (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) =
            ticks.getInnerFeeGrowth(bottomTick, topTick, tick, _totalFeeGrowth0Token, _totalFeeGrowth1Token);

        position.recalculate(liquidityDelta, feeGrowthInside0X128, feeGrowthInside1X128);

        // clear any tick data that is no longer needed
        if (liquidityDelta < 0) {
            if (flippedBottom) {
                ticks.clear(bottomTick);
            }
            if (flippedTop) {
                ticks.clear(topTick);
            }
        }
    }

    /// @inheritdoc IFuzzyswapPoolActions
    function mint(
        address sender,
        address recipient,
        int24 bottomTick,
        int24 topTick,
        uint128 _liquidity,
        bytes calldata data
    ) external override lock returns (uint256 amount0, uint256 amount1, uint256 liquidityAmount) {
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

        uint256 realAmount0;
        uint256 realAmount1;
        {
            if (amount0 > 0) realAmount0 = balanceToken0();
            if (amount1 > 0) realAmount1 = balanceToken1();
            IFuzzyswapMintCallback(msg.sender).fuzzyswapMintCallback(amount0, amount1, data);
            if (amount0 > 0) require((realAmount0 = balanceToken0() - realAmount0) > 0, 'IIAM');
            if (amount1 > 0) require((realAmount1 = balanceToken1() - realAmount1) > 0, 'IIAM');
        }

        if (realAmount0 < amount0) {
            _liquidity = uint128(FullMath.mulDiv(uint256(_liquidity), realAmount0, amount0));
            
        } 
        if (realAmount1 < amount1) {
            uint128 liquidityForRA1 = uint128(FullMath.mulDiv(uint256(_liquidity), realAmount1, amount1));
            if (liquidityForRA1 < _liquidity) {
                _liquidity = liquidityForRA1;
            }
        }

        require(_liquidity > 0, 'IIL2');

        {
            (, int256 amount0Int, int256 amount1Int) =
            _modifyPosition(
                ModifyPositionParams({
                    owner: recipient,
                    bottomTick: bottomTick,
                    topTick: topTick,
                    liquidityDelta: int256(_liquidity).toInt128()
                })
            );

            require((amount0 = uint256(amount0Int)) <= realAmount0, 'IIAM2');
            require((amount1 = uint256(amount1Int)) <= realAmount1, 'IIAM2');
        }

        if (realAmount0 > amount0) {
            TransferHelper.safeTransfer(token0, sender, realAmount0 - amount0);
        }
        if (realAmount1 > amount1) {
            TransferHelper.safeTransfer(token1, sender, realAmount1 - amount1);
        }
        liquidityAmount = _liquidity;
        emit Mint(msg.sender, recipient, bottomTick, topTick, _liquidity, amount0, amount1);
    }

    /// @inheritdoc IFuzzyswapPoolActions
    function collect(
        address recipient,
        int24 bottomTick,
        int24 topTick,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external override lock returns (uint128 amount0, uint128 amount1) {
        // we don't need to checkTicks here, because invalid positions will never have non-zero fees{0,1}
        Position.Data storage position = getOrCreatePosition(msg.sender, bottomTick, topTick);

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

    /// @inheritdoc IFuzzyswapPoolActions
    function burn(
        int24 bottomTick,
        int24 topTick,
        uint128 amount
    ) external override lock returns (uint256 amount0, uint256 amount1) {
        tickValidation(bottomTick, topTick);
        (Position.Data storage position, int256 amount0Int, int256 amount1Int) =
            _modifyPosition(
                ModifyPositionParams({
                    owner: msg.sender,
                    bottomTick: bottomTick,
                    topTick: topTick,
                    liquidityDelta: -int256(amount).toInt128()
                })
            );

        amount0 = uint256(-amount0Int);
        amount1 = uint256(-amount1Int);

        if (amount0 > 0 || amount1 > 0) {
            (position.fees0, position.fees1) = (
                position.fees0 + uint128(amount0),
                position.fees1 + uint128(amount1)
            );
        }

        emit Burn(msg.sender, bottomTick, topTick, amount, amount0, amount1);
    }

    /// @dev Changes fee according to k*TWAV+b
    function _changeFee(
        uint32 _time,
        int24 _tick,
        uint16 _index,
        uint128 _liquidity
    ) private {
        fee = dataStorageOperator.getFee(
            _time,
            _tick,
            _index,
            _liquidity
        );
        //fee = uint24(49 * TWVolatilityAverage + fee_) <= 15000 ? uint24(49 * TWVolatilityAverage + fee_) : 15000;
    }

    struct SwapCache {
        // the protocol fee for the input token
        uint8 feeProtocol;
        // liquidity at the beginning of the swap
        uint128 liquidityStart;
        // the timestamp of the current block
        uint32 blockTimestamp;
        // the current value of the tick accumulator, computed only if we cross an initialized tick
        int56 tickCumulative;
        // the current value of seconds per liquidity accumulator, computed only if we cross an initialized tick
        uint160 secondsPerLiquidityCumulative;
        // whether we've computed and cached the above two accumulators
        bool computedLatestObservation;
    }

    // the top level state of the swap, the results of which are recorded in storage at the end
    struct SwapState {
        // the amount remaining to be swapped in/out of the input/output asset
        int256 amountSpecifiedRemaining;
        // the amount already swapped out/in of the output/input asset
        int256 amountCalculated;
        // current sqrt(price)
        uint160 sqrtPriceX96;
        // the tick associated with the current price
        int24 tick;
        // the global fee growth of the input token
        uint256 feeGrowthGlobalX128;
        // amount of input token paid as protocol fee
        uint128 protocolFee;
        // the current liquidity in range
        uint128 liquidity;
    }

    struct StepComputations {
        // the price at the beginning of the step
        uint160 sqrtPriceStartX96;
        // the next tick to swap to from the current tick in the swap direction
        int24 tickNext;
        // whether tickNext is initialized or not
        bool initialized;
        // sqrt(price) for the next tick (1/0)
        uint160 sqrtPriceNextX96;
        // how much is being swapped in in this step
        uint256 amountIn;
        // how much is being swapped out
        uint256 amountOut;
        // how much fee is being paid in
        uint256 feeAmount;
    }

    /// @inheritdoc IFuzzyswapPoolActions
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external override returns (int256 amount0, int256 amount1) {
        SwapCache memory cache;
        SwapState memory state;

        (amount0, amount1, cache, state) = _calculateSwap(
            zeroForOne,
            amountSpecified,
            sqrtPriceLimitX96
        );
        // do the transfers and collect payment
        if (zeroForOne) {
            if (amount1 < 0) TransferHelper.safeTransfer(token1, recipient, uint256(-amount1));

            uint256 balance0Before = balanceToken0();
            IFuzzyswapSwapCallback(msg.sender).fuzzyswapSwapCallback(amount0, amount1, data);
            require(balance0Before.add(uint256(amount0)) <= balanceToken0(), 'IIA');
        } else {
            if (amount0 < 0) TransferHelper.safeTransfer(token0, recipient, uint256(-amount0));

            uint256 balance1Before = balanceToken1();
            IFuzzyswapSwapCallback(msg.sender).fuzzyswapSwapCallback(amount0, amount1, data);
            require(balance1Before.add(uint256(amount1)) <= balanceToken1(), 'IIA');
        }


        _changeFee(cache.blockTimestamp, state.tick, globalState.observationIndex, liquidity);

        emit Swap(msg.sender, recipient, amount0, amount1, state.sqrtPriceX96, state.liquidity, state.tick);
        globalState.unlocked = true;
    }

    function swapSupportingFeeOnInputTokens(
        address sender,
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external override returns (int256 amount0, int256 amount1) {
        SwapCache memory cache;
        SwapState memory state;

        if (zeroForOne) {
            uint256 balance0Before = balanceToken0();
            IFuzzyswapSwapCallback(msg.sender).fuzzyswapSwapCallback(amountSpecified, 0, data);
            require((amountSpecified = int(balanceToken0().sub(balance0Before))) > 0, 'IIA');
        } else {
            if (amount0 < 0) TransferHelper.safeTransfer(token0, recipient, uint256(-amount0));

            uint256 balance1Before = balanceToken1();
            IFuzzyswapSwapCallback(msg.sender).fuzzyswapSwapCallback(0, amountSpecified, data);
            require((amountSpecified = int(balanceToken1().sub(balance1Before))) > 0, 'IIA');
        }

        (amount0, amount1, cache, state) = _calculateSwap(
            zeroForOne,
            amountSpecified,
            sqrtPriceLimitX96
        );
        // do the transfers and collect payment

        
        if (zeroForOne) {
            if (amount1 < 0) TransferHelper.safeTransfer(token1, recipient, uint256(-amount1));

            if (amount0 < amountSpecified) {
                TransferHelper.safeTransfer(token0, sender, uint256(amountSpecified.sub(amount0)));
            }
        } else {
            if (amount0 < 0) TransferHelper.safeTransfer(token0, recipient, uint256(-amount0));

            if (amount1 < amountSpecified) {
                TransferHelper.safeTransfer(token1, sender, uint256(amountSpecified.sub(amount1)));
            }
        }


        _changeFee(cache.blockTimestamp, state.tick, globalState.observationIndex, liquidity);

        emit Swap(msg.sender, recipient, amount0, amount1, state.sqrtPriceX96, state.liquidity, state.tick);
        globalState.unlocked = true;
    }

    function _calculateSwap(        
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96
        ) private returns(int256 amount0, int256 amount1, SwapCache memory cache, SwapState memory state) {
        require(amountSpecified != 0, 'AS');

        GlobalState memory globalStateStart = globalState;

        require(globalStateStart.unlocked, 'LOK');
        require(
            zeroForOne
                ? sqrtPriceLimitX96 < globalStateStart.sqrtPriceX96 && sqrtPriceLimitX96 > TickMath.MIN_SQRT_RATIO
                : sqrtPriceLimitX96 > globalStateStart.sqrtPriceX96 && sqrtPriceLimitX96 < TickMath.MAX_SQRT_RATIO,
            'SPL'
        );

        globalState.unlocked = false;

        cache =
            SwapCache({
                liquidityStart: liquidity,
                blockTimestamp: _blockTimestamp(),
                feeProtocol: zeroForOne ? (globalStateStart.feeProtocol % 16) : (globalStateStart.feeProtocol >> 4),
                secondsPerLiquidityCumulative: 0,
                tickCumulative: 0,
                computedLatestObservation: false
            });

        bool exactInput = amountSpecified > 0;

        state =
            SwapState({
                amountSpecifiedRemaining: amountSpecified,
                amountCalculated: 0,
                sqrtPriceX96: globalStateStart.sqrtPriceX96,
                tick: globalStateStart.tick,
                feeGrowthGlobalX128: zeroForOne ? totalFeeGrowth0Token : totalFeeGrowth1Token,
                protocolFee: 0,
                liquidity: cache.liquidityStart
            });

        uint32 _time;
        if(activeIncentive.virtualPool != address(0)){
            (_time,,,,,) = dataStorageOperator.observations(globalStateStart.observationIndexSwap);
            if (_time != cache.blockTimestamp){
                if(activeIncentive.endTimestamp > cache.blockTimestamp){
                    IFuzzyswapVirtualPool(activeIncentive.virtualPool).increaseCumulative(
                        _time,
                        cache.blockTimestamp
                    );
                }
            }
        }

        // continue swapping as long as we haven't used the entire input/output and haven't reached the price limit
        while (state.amountSpecifiedRemaining != 0 && state.sqrtPriceX96 != sqrtPriceLimitX96) {
            StepComputations memory step;

            step.sqrtPriceStartX96 = state.sqrtPriceX96;

            (step.tickNext, step.initialized) = tickTable.nextTickInTheSameRow(
                state.tick,
                zeroForOne
            );

            // ensure that we do not overshoot the min/max tick, as the tick bitmap is not aware of these bounds
            if (step.tickNext < TickMath.MIN_TICK) {
                step.tickNext = TickMath.MIN_TICK;
            } else if (step.tickNext > TickMath.MAX_TICK) {
                step.tickNext = TickMath.MAX_TICK;
            }

            // get the price for the next tick
            step.sqrtPriceNextX96 = TickMath.getSqrtRatioAtTick(step.tickNext);

            // compute values to swap to the target tick, price limit, or point where input/output amount is exhausted
            (state.sqrtPriceX96, step.amountIn, step.amountOut, step.feeAmount) = SwapMath.computeSwapStep(
                zeroForOne,
                state.sqrtPriceX96,
                (!zeroForOne != (step.sqrtPriceNextX96 < sqrtPriceLimitX96))
                        ? sqrtPriceLimitX96
                        : step.sqrtPriceNextX96,
                state.liquidity,
                state.amountSpecifiedRemaining,
                fee
            );

            if (exactInput) {
                state.amountSpecifiedRemaining -= (step.amountIn + step.feeAmount).toInt256();
                state.amountCalculated = state.amountCalculated.sub(step.amountOut.toInt256());
            } else {
                state.amountSpecifiedRemaining += step.amountOut.toInt256();
                state.amountCalculated = state.amountCalculated.add((step.amountIn + step.feeAmount).toInt256());
            }

            // if the protocol fee is on, calculate how much is owed, decrement feeAmount, and increment protocolFee
            if (cache.feeProtocol > 0) {
                uint256 delta = step.feeAmount / cache.feeProtocol;
                step.feeAmount -= delta;
                state.protocolFee += uint128(delta);
            }

            // update global fee tracker
            if (state.liquidity > 0)
                state.feeGrowthGlobalX128 += FullMath.mulDiv(step.feeAmount, Constants.Q128, state.liquidity);

            // shift tick if we reached the next price
            if (state.sqrtPriceX96 == step.sqrtPriceNextX96) {
                // if the tick is initialized, run the tick transition
                if (step.initialized) {
                    // check for the placeholder value, which we replace with the actual value the first time the swap
                    // crosses an initialized tick
                    if (!cache.computedLatestObservation) {
                        (cache.tickCumulative, cache.secondsPerLiquidityCumulative,,) = dataStorageOperator.observeSingle(
                            cache.blockTimestamp,
                            0,
                            globalStateStart.tick,
                            globalStateStart.observationIndex,
                            cache.liquidityStart
                        );
                        cache.computedLatestObservation = true;
                    }
                    if(activeIncentive.virtualPool != address(0)){
                        if(activeIncentive.endTimestamp > cache.blockTimestamp){
                            IFuzzyswapVirtualPool(activeIncentive.virtualPool).cross(
                                step.tickNext,
                                zeroForOne
                            );
                        }
                    }
                    int128 liquidityDelta =
                        ticks.cross(
                            step.tickNext,
                            (zeroForOne ? state.feeGrowthGlobalX128 : totalFeeGrowth0Token),
                            (zeroForOne ? totalFeeGrowth1Token : state.feeGrowthGlobalX128),
                            cache.secondsPerLiquidityCumulative,
                            cache.tickCumulative,
                            cache.blockTimestamp
                        );
                    // if we're moving leftward, we interpret liquidityDelta as the opposite sign
                    // safe because liquidityDelta cannot be type(int128).min
                    if (zeroForOne) liquidityDelta = -liquidityDelta;

                    state.liquidity = LiquidityMath.addDelta(state.liquidity, liquidityDelta);
                }

                state.tick = zeroForOne ? step.tickNext - 1 : step.tickNext;
            } else if (state.sqrtPriceX96 != step.sqrtPriceStartX96) {
                // recompute unless we're on a lower tick boundary (i.e. already transitioned ticks), and haven't moved

                state.tick = TickMath.getTickAtSqrtRatio(state.sqrtPriceX96);
                if(activeIncentive.endTimestamp > cache.blockTimestamp){
                        IFuzzyswapVirtualPool(activeIncentive.virtualPool).cross(
                            state.tick,
                            zeroForOne
                        );
                }
            }
        }

        (amount0, amount1) = zeroForOne == exactInput
            ? (amountSpecified - state.amountSpecifiedRemaining, state.amountCalculated)
            : (state.amountCalculated, amountSpecified - state.amountSpecifiedRemaining);

        // update tick and write an oracle entry if the tick change
        if (state.tick != globalStateStart.tick) {
            uint16 observationIndex =
                dataStorageOperator.write(
                    globalStateStart.observationIndex,
                    cache.blockTimestamp,
                    globalStateStart.tick,
                    cache.liquidityStart,
                    amount0,
                    amount1
                );
            (globalState.sqrtPriceX96, globalState.tick, globalState.observationIndex, globalState.observationIndexSwap) = (
                state.sqrtPriceX96,
                state.tick,
                observationIndex,
                observationIndex
            );
            if(activeIncentive.virtualPool != address(0)){
                 if (activeIncentive.startTimestamp <= cache.blockTimestamp){
                    if(activeIncentive.endTimestamp < cache.blockTimestamp){
                        activeIncentive.endTimestamp = 0;
                        activeIncentive.virtualPool = address(0);
                    }
                    else{
                        IFuzzyswapVirtualPool(activeIncentive.virtualPool).processSwap(
                        );
                    }
                }
            }
        } else {
            // otherwise just update the price
            globalState.sqrtPriceX96 = state.sqrtPriceX96;
        }

        // update liquidity if it changed
        if (cache.liquidityStart != state.liquidity) liquidity = state.liquidity;

        // update fee growth global and, if necessary, protocol fees
        // overflow is acceptable, protocol has to withdraw before it hits type(uint128).max fees
        if (zeroForOne) {
            totalFeeGrowth0Token = state.feeGrowthGlobalX128;
            if (state.protocolFee > 0) protocolFees.token0 += state.protocolFee;
        } else {
            totalFeeGrowth1Token = state.feeGrowthGlobalX128;
            if (state.protocolFee > 0) protocolFees.token1 += state.protocolFee;
        }


    }

    /// @inheritdoc IFuzzyswapPoolActions
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external override lock {
        uint128 _liquidity = liquidity;
        require(_liquidity > 0, 'L');

        uint256 fee0 = FullMath.mulDivRoundingUp(amount0, fee, 1e6);
        uint256 fee1 = FullMath.mulDivRoundingUp(amount1, fee, 1e6);
        uint256 balance0Before = balanceToken0();
        uint256 balance1Before = balanceToken1();

        if (amount0 > 0) TransferHelper.safeTransfer(token0, recipient, amount0);
        if (amount1 > 0) TransferHelper.safeTransfer(token1, recipient, amount1);

        IFuzzyswapFlashCallback(msg.sender).fuzzyswapFlashCallback(fee0, fee1, data);

        uint256 paid0 = balanceToken0();
        uint256 paid1 = balanceToken1();

        require(balance0Before.add(fee0) <= paid0, 'F0');
        require(balance1Before.add(fee1) <= paid1, 'F1');

        // sub is safe because we know balanceAfter is gt balanceBefore by at least fee
        paid0 -= balance0Before;
        paid1 -= balance1Before;

        if (paid0 > 0) {
            uint8 feeProtocol0 = globalState.feeProtocol % 16;
            uint256 fees0 = feeProtocol0 == 0 ? 0 : paid0 / feeProtocol0;
            if (uint128(fees0) > 0) protocolFees.token0 += uint128(fees0);
            totalFeeGrowth0Token += FullMath.mulDiv(paid0 - fees0, Constants.Q128, _liquidity);
        }
        if (paid1 > 0) {
            uint8 feeProtocol1 = globalState.feeProtocol >> 4;
            uint256 fees1 = feeProtocol1 == 0 ? 0 : paid1 / feeProtocol1;
            if (uint128(fees1) > 0) protocolFees.token1 += uint128(fees1);
            totalFeeGrowth1Token += FullMath.mulDiv(paid1 - fees1, Constants.Q128, _liquidity);
        }

        emit Flash(msg.sender, recipient, amount0, amount1, paid0, paid1);
    }

    /// @inheritdoc IFuzzyswapPoolOwnerActions
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external override lock onlyFactoryOwner {
        require(
            (feeProtocol0 == 0 || (feeProtocol0 >= 4 && feeProtocol0 <= 10)) &&
                (feeProtocol1 == 0 || (feeProtocol1 >= 4 && feeProtocol1 <= 10))
        );
        uint8 feeProtocolOld = globalState.feeProtocol;
        globalState.feeProtocol = feeProtocol0 + (feeProtocol1 << 4);
        emit SetFeeProtocol(feeProtocolOld % 16, feeProtocolOld >> 4, feeProtocol0, feeProtocol1);
    }

    /// @inheritdoc IFuzzyswapPoolOwnerActions
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external override lock onlyFactoryOwner returns (uint128 amount0, uint128 amount1) {
        amount0 = amount0Requested > protocolFees.token0 ? protocolFees.token0 : amount0Requested;
        amount1 = amount1Requested > protocolFees.token1 ? protocolFees.token1 : amount1Requested;

        if (amount0 > 0) {
            if (amount0 == protocolFees.token0) amount0--; // ensure that the slot is not cleared, for gas savings
            protocolFees.token0 -= amount0;
            TransferHelper.safeTransfer(token0, recipient, amount0);
        }
        if (amount1 > 0) {
            if (amount1 == protocolFees.token1) amount1--; // ensure that the slot is not cleared, for gas savings
            protocolFees.token1 -= amount1;
            TransferHelper.safeTransfer(token1, recipient, amount1);
        }

        emit CollectProtocol(msg.sender, recipient, amount0, amount1);
    }

    /**
     *  @dev Sets new active incentive
     */
    function setIncentive(address virtualPoolAddress, uint32 endTimestamp, uint32 startTimestamp) external override {
        require(msg.sender == IFuzzyswapFactory(factory).stackerAddress());
        require(activeIncentive.endTimestamp < _blockTimestamp());
        activeIncentive = Incentive(virtualPoolAddress, endTimestamp, startTimestamp);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IFuzzyswapPoolImmutables.sol';
import './pool/IFuzzyswapPoolState.sol';
import './pool/IFuzzyswapPoolDerivedState.sol';
import './pool/IFuzzyswapPoolActions.sol';
import './pool/IFuzzyswapPoolOwnerActions.sol';
import './pool/IFuzzyswapPoolEvents.sol';

/// @title The interface for a Fuzzyswap Pool
/// @notice A Fuzzyswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IFuzzyswapPool is
    IFuzzyswapPoolImmutables,
    IFuzzyswapPoolState,
    IFuzzyswapPoolDerivedState,
    IFuzzyswapPoolActions,
    IFuzzyswapPoolOwnerActions,
    IFuzzyswapPoolEvents
{

}

pragma solidity >=0.7.0;

interface IDataStorageOperator{
    function observations(uint256 index)
    external
    view
    returns (
        uint32 blockTimestamp,
        int56 tickCumulative,
        uint160 secondsPerLiquidityCumulative,
        uint112 volatilityCumulative,
        bool initialized,
        uint256 volumePerAvgLiquidity
    );

    function setPool(address _pool) external;

    function setFactory(address _factory) external;

    function initialize(uint32 time)
        external;

    function observeSingle(
        uint32 time,
        uint32 secondsAgo,
        int24 tick,
        uint16 index,
        uint128 liquidity
    ) external view returns (int56 tickCumulative,
                            uint160 secondsPerLiquidityCumulative,
                            uint112 volatilityCumulative,
                            uint256 volumePerAvgLiquidity
    );

    function observe(
        uint32 time,
        uint32[] memory secondsAgos,
        int24 tick,
        uint16 index,
        uint128 liquidity
    ) external view returns (int56[] memory tickCumulatives,
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
        int256 volume0,
        int256 volume1
    ) external returns (uint16 indexUpdated);

    function timeAgo() external view returns(uint32);

    function getFee(
        uint32 _time,
        int24 _tick,
        uint16 _index,
        uint128 _liquidity
    ) external view returns(uint24 fee);
}

pragma solidity =0.7.6;

interface IFuzzyswapVirtualPool{
    function cross(
        int24 nextTick,
        bool zeroForOne
    )external;

    function finish(uint32 _endTimestamp, uint32 startTimestamp) external;

    function processSwap(
    ) external;

    function increaseCumulative(
        uint32 previousTimestamp,
        uint32 currentTimestamp
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.5.0;

import './FullMath.sol';
import './Constants.sol';
import './LiquidityMath.sol';

/// @title Position
/// @notice Positions represent an owner address' liquidity between a lower and upper tick boundary
/// @dev Positions store additional state for tracking fees owed to the position
library Position {
    // info stored for each user's position
    struct Data {
        // the amount of liquidity owned by this position
        uint128 liquidity;
        // fee growth per unit of liquidity as of the last update to liquidity or fees owed
        uint256 innerFeeGrowth0Token;
        uint256 innerFeeGrowth1Token;
        // the fees owed to the position owner in token0/token1
        uint128 fees0;
        uint128 fees1;
    }

    /// @notice Credits accumulated fees to a user's position
    /// @param self The individual position to update
    /// @param liquidityDelta The change in pool liquidity as a result of the position update
    /// @param innerFeeGrowth0Token The all-time fee growth in token0, per unit of liquidity, inside the position's tick boundaries
    /// @param innerFeeGrowth1Token The all-time fee growth in token1, per unit of liquidity, inside the position's tick boundaries
    function recalculate(
        Data storage self,
        int128 liquidityDelta,
        uint256 innerFeeGrowth0Token,
        uint256 innerFeeGrowth1Token
    ) internal {
        uint128 currentLiquidity = self.liquidity;
        uint256 _innerFeeGrowth0Token = self.innerFeeGrowth0Token;
        uint256 _innerFeeGrowth1Token = self.innerFeeGrowth1Token;

        uint128 liquidityNext;
        if (liquidityDelta == 0) {
            require(currentLiquidity > 0, 'NP'); // disallow pokes for 0 liquidity positions
        } else {
            liquidityNext = LiquidityMath.addDelta(currentLiquidity, liquidityDelta);
        }

        // calculate accumulated fees
        uint128 fees0 =
            uint128(
                FullMath.mulDiv(
                    innerFeeGrowth0Token - _innerFeeGrowth0Token,
                    currentLiquidity,
                    Constants.Q128
                )
            );
        uint128 fees1 =
            uint128(
                FullMath.mulDiv(
                    innerFeeGrowth1Token - _innerFeeGrowth1Token,
                    currentLiquidity,
                    Constants.Q128
                )
            );

        // update the position
        if (liquidityDelta != 0) self.liquidity = liquidityNext;
        self.innerFeeGrowth0Token = innerFeeGrowth0Token;
        self.innerFeeGrowth1Token = innerFeeGrowth1Token;

        // overflow is acceptable, have to withdraw before you hit type(uint128).max fees
        if (fees0 != 0 || fees1 != 0) {
            self.fees0 += fees0;
            self.fees1 += fees1;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.5.0;

import './LowGasSafeMath.sol';
import './SafeCast.sol';

import './FullMath.sol';
import './Constants.sol';

/// @title Functions based on Q64.96 sqrt price and liquidity
/// @notice Contains the math that uses square root of price as a Q64.96 and liquidity to compute deltas
library SqrtPriceMath {
    using LowGasSafeMath for uint256;
    using SafeCast for uint256;

    /// @notice Gets the next sqrt price given an input amount of token0 or token1
    /// @dev Throws if price or liquidity are 0, or if the next price is out of bounds
    /// @param sqrtPX96 The starting price, i.e., before accounting for the input amount
    /// @param liquidity The amount of usable liquidity
    /// @param amountIn How much of token0, or token1, is being swapped in
    /// @param zeroForOne Whether the amount in is token0 or token1
    /// @return sqrtQX96 The price after adding the input amount to token0 or token1
    function getNextSqrtPriceFromInput(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amountIn,
        bool zeroForOne
    ) internal pure returns (uint160 sqrtQX96) {
        return getNextSqrtPrice(sqrtPX96, liquidity, amountIn, zeroForOne, true);
    }

    /// @notice Gets the next sqrt price given an output amount of token0 or token1
    /// @dev Throws if price or liquidity are 0 or the next price is out of bounds
    /// @param sqrtPX96 The starting price before accounting for the output amount
    /// @param liquidity The amount of usable liquidity
    /// @param amountOut How much of token0, or token1, is being swapped out
    /// @param zeroForOne Whether the amount out is token0 or token1
    /// @return sqrtQX96 The price after removing the output amount of token0 or token1
    function getNextSqrtPriceFromOutput(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amountOut,
        bool zeroForOne
    ) internal pure returns (uint160 sqrtQX96) {
        return getNextSqrtPrice(sqrtPX96, liquidity, amountOut, zeroForOne, false);
    }

    function getNextSqrtPrice(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amount,
        bool zeroForOne,
        bool fromInput
    ) internal pure returns (uint160 sqrtQX96) {
        require(sqrtPX96 > 0);
        require(liquidity > 0);

        if (zeroForOne == fromInput) { // rounding up or down
            // we short circuit amount == 0 because the result is otherwise not guaranteed to equal the input price
            if (amount == 0) return sqrtPX96;
            uint256 numerator1 = uint256(liquidity) << Constants.RESOLUTION;

            if (fromInput) {
                uint256 product;
                if ((product = amount * sqrtPX96) / amount == sqrtPX96) {
                    uint256 denominator = numerator1 + product;
                    if (denominator >= numerator1)
                        // always fits in 160 bits
                        return uint160(FullMath.mulDivRoundingUp(numerator1, sqrtPX96, denominator));
                }

                return uint160(FullMath.divRoundingUp(numerator1, (numerator1 / sqrtPX96).add(amount)));
            } else {
                uint256 product;
                // if the product overflows, we know the denominator underflows
                // in addition, we must check that the denominator does not underflow
                require((product = amount * sqrtPX96) / amount == sqrtPX96 && numerator1 > product);
                uint256 denominator = numerator1 - product;
                return FullMath.mulDivRoundingUp(numerator1, sqrtPX96, denominator).toUint160();
            }
        } else {
            // if we're adding (subtracting), rounding down requires rounding the quotient down (up)
            // in both cases, avoid a mulDiv for most inputs
            if (fromInput) {
                uint256 quotient =
                    (
                        amount <= type(uint160).max
                            ? (amount << Constants.RESOLUTION) / liquidity
                            : FullMath.mulDiv(amount, Constants.Q96, liquidity)
                    );

                return uint256(sqrtPX96).add(quotient).toUint160();
            } else {
                uint256 quotient =
                    (
                        amount <= type(uint160).max
                            ? FullMath.divRoundingUp(amount << Constants.RESOLUTION, liquidity)
                            : FullMath.mulDivRoundingUp(amount, Constants.Q96, liquidity)
                    );

                require(sqrtPX96 > quotient);
                // always fits 160 bits
                return uint160(sqrtPX96 - quotient);
            }
        }
    }


    /// @notice Gets the amount0 delta between two prices
    /// @dev Calculates liquidity / sqrt(lower) - liquidity / sqrt(upper),
    /// i.e. liquidity * (sqrt(upper) - sqrt(lower)) / (sqrt(upper) * sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The amount of usable liquidity
    /// @param roundUp Whether to round the amount up or down
    /// @return amount0 Amount of token0 required to cover a position of size liquidity between the two passed prices
    function getAmount0Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity,
        bool roundUp
    ) internal pure returns (uint256 amount0) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        uint256 numerator1 = uint256(liquidity) << Constants.RESOLUTION;
        uint256 numerator2 = sqrtRatioBX96 - sqrtRatioAX96;

        require(sqrtRatioAX96 > 0);

        return
            roundUp
                ? FullMath.divRoundingUp(
                    FullMath.mulDivRoundingUp(numerator1, numerator2, sqrtRatioBX96),
                    sqrtRatioAX96
                )
                : FullMath.mulDiv(numerator1, numerator2, sqrtRatioBX96) / sqrtRatioAX96;
    }

    /// @notice Gets the amount1 delta between two prices
    /// @dev Calculates liquidity * (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The amount of usable liquidity
    /// @param roundUp Whether to round the amount up, or down
    /// @return amount1 Amount of token1 required to cover a position of size liquidity between the two passed prices
    function getAmount1Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity,
        bool roundUp
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return
            roundUp
                ? FullMath.mulDivRoundingUp(liquidity, sqrtRatioBX96 - sqrtRatioAX96, Constants.Q96)
                : FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, Constants.Q96);
    }

    /// @notice Helper that gets signed token0 delta
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The change in liquidity for which to compute the amount0 delta
    /// @return amount0 Amount of token0 corresponding to the passed liquidityDelta between the two prices
    function getAmount0Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        int128 liquidity
    ) internal pure returns (int256 amount0) {
        return
            liquidity < 0
                ? -getAmount0Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(-liquidity), false).toInt256()
                : getAmount0Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(liquidity), true).toInt256();
    }

    /// @notice Helper that gets signed token1 delta
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The change in liquidity for which to compute the amount1 delta
    /// @return amount1 Amount of token1 corresponding to the passed liquidityDelta between the two prices
    function getAmount1Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        int128 liquidity
    ) internal pure returns (int256 amount1) {
        return
            liquidity < 0
                ? -getAmount1Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(-liquidity), false).toInt256()
                : getAmount1Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(liquidity), true).toInt256();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.5.0;

import './FullMath.sol';
import './SqrtPriceMath.sol';

/// @title Computes the result of a swap within ticks
/// @notice Contains methods for computing the result of a swap within a single tick price range, i.e., a single tick.
library SwapMath {
    function getAmountADelta01(uint160 to, uint160 from, uint128 liquidity) internal pure returns(uint256) {
        return SqrtPriceMath.getAmount0Delta(to, from, liquidity, true);
    }
    function getAmountADelta10(uint160 to, uint160 from, uint128 liquidity) internal pure returns(uint256) {
        return SqrtPriceMath.getAmount1Delta(from, to, liquidity, true);
    }
    function getAmountBDelta01(uint160 to, uint160 from, uint128 liquidity) internal pure returns(uint256) {
        return SqrtPriceMath.getAmount1Delta(to, from, liquidity, false);
    }
    function getAmountBDelta10(uint160 to, uint160 from, uint128 liquidity) internal pure returns(uint256) {
        return SqrtPriceMath.getAmount0Delta(from, to, liquidity, false);
    }
    /// @notice Computes the result of swapping some amount in, or amount out, given the parameters of the swap
    /// @dev The fee, plus the amount in, will never exceed the amount remaining if the swap's `amountSpecified` is positive
    /// @param sqrtRatioCurrentX96 The current sqrt price of the pool
    /// @param sqrtRatioTargetX96 The price that cannot be exceeded, from which the direction of the swap is inferred
    /// @param liquidity The usable liquidity
    /// @param amountRemaining How much input or output amount is remaining to be swapped in/out
    /// @param feePips The fee taken from the input amount, expressed in hundredths of a bip
    /// @return sqrtRatioNextX96 The price after swapping the amount in/out, not to exceed the price target
    /// @return amountIn The amount to be swapped in, of either token0 or token1, based on the direction of the swap
    /// @return amountOut The amount to be received, of either token0 or token1, based on the direction of the swap
    /// @return feeAmount The amount of input that will be taken as a fee
    function computeSwapStep(
        bool zeroForOne,
        uint160 sqrtRatioCurrentX96,
        uint160 sqrtRatioTargetX96,
        uint128 liquidity,
        int256 amountRemaining,
        uint24 feePips
    )
        internal
        pure
        returns (
            uint160 sqrtRatioNextX96,
            uint256 amountIn,
            uint256 amountOut,
            uint256 feeAmount
        )
    {
        function(uint160, uint160, uint128) pure returns(uint256) getAmountA = zeroForOne ?
                getAmountADelta01 : getAmountADelta10;

        if (amountRemaining >= 0) { // exactIn or not
            

            uint256 amountRemainingLessFee = FullMath.mulDiv(uint256(amountRemaining), 1e6 - feePips, 1e6);
            amountIn = getAmountA(sqrtRatioTargetX96, sqrtRatioCurrentX96, liquidity);
            if (amountRemainingLessFee >= amountIn) {
                sqrtRatioNextX96 = sqrtRatioTargetX96;
                feeAmount = FullMath.mulDivRoundingUp(amountIn, feePips, 1e6 - feePips);
            }
            else {
                sqrtRatioNextX96 = SqrtPriceMath.getNextSqrtPriceFromInput(
                    sqrtRatioCurrentX96,
                    liquidity,
                    amountRemainingLessFee,
                    zeroForOne
                );
                if (sqrtRatioTargetX96 != sqrtRatioNextX96) { // != MAX
                    amountIn = getAmountA(sqrtRatioNextX96, sqrtRatioCurrentX96, liquidity);

                    // we didn't reach the target, so take the remainder of the maximum input as fee
                    feeAmount = uint256(amountRemaining) - amountIn;
                } else {
                    feeAmount = FullMath.mulDivRoundingUp(amountIn, feePips, 1e6 - feePips);
                }
            }

            
            amountOut = (zeroForOne ?  getAmountBDelta01 : getAmountBDelta10)(sqrtRatioNextX96, sqrtRatioCurrentX96, liquidity);
        } else {
            function(uint160, uint160, uint128) pure returns(uint256) getAmountB = zeroForOne ?
                getAmountBDelta01 : getAmountBDelta10;
                
            amountOut = getAmountB(sqrtRatioTargetX96, sqrtRatioCurrentX96, liquidity);
            if (uint256(-amountRemaining) >= amountOut) sqrtRatioNextX96 = sqrtRatioTargetX96;
            else {
                sqrtRatioNextX96 = SqrtPriceMath.getNextSqrtPriceFromOutput(
                    sqrtRatioCurrentX96,
                    liquidity,
                    uint256(-amountRemaining),
                    zeroForOne
                );

                if (sqrtRatioTargetX96 != sqrtRatioNextX96) { // != MAX
                    amountOut = getAmountB(sqrtRatioNextX96, sqrtRatioCurrentX96, liquidity);
                }

                // cap the output amount to not exceed the remaining output amount
                if (amountOut > uint256(-amountRemaining)) {
                    amountOut = uint256(-amountRemaining);
                }
            }

            amountIn = getAmountA(sqrtRatioNextX96, sqrtRatioCurrentX96, liquidity);
            feeAmount = FullMath.mulDivRoundingUp(amountIn, feePips, 1e6 - feePips);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.5.0;

import './LowGasSafeMath.sol';
import './SafeCast.sol';

import './TickMath.sol';
import './LiquidityMath.sol';

/// @title Tick
/// @notice Contains functions for managing tick processes and relevant calculations
library Tick {
    using LowGasSafeMath for int256;
    using SafeCast for int256;

    // info stored for each initialized individual tick
    struct Data {
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
        mapping(int24 => Tick.Data) storage self,
        int24 bottomTick,
        int24 topTick,
        int24 currentTick,
        uint256 totalFeeGrowth0Token,
        uint256 totalFeeGrowth1Token
    ) internal view returns (uint256 innerFeeGrowth0Token, uint256 innerFeeGrowth1Token) {
        Data storage lower = self[bottomTick];
        Data storage upper = self[topTick];

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
        mapping(int24 => Tick.Data) storage self,
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
        Tick.Data storage data = self[tick];

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

    /// @notice Clears tick data
    /// @param self The mapping containing all initialized tick information for initialized ticks
    /// @param tick The tick that will be cleared
    function clear(mapping(int24 => Tick.Data) storage self, int24 tick) internal {
        delete self[tick];
    }

    /// @notice Transitions to next tick as needed by price movement
    /// @param self The mapping containing all tick information for initialized ticks
    /// @param tick The destination tick of the transition
    /// @param totalFeeGrowth0Token The all-time global fee growth, per unit of liquidity, in token0
    /// @param totalFeeGrowth1Token The all-time global fee growth, per unit of liquidity, in token1
    /// @param secondsPerLiquidityCumulative The current seconds per liquidity
    /// @param time The current block.timestamp
    /// @return liquidityDelta The amount of liquidity added (subtracted) when tick is crossed from left to right (right to left)
    function cross (
        mapping(int24 => Tick.Data) storage self,
        int24 tick,
        uint256 totalFeeGrowth0Token,
        uint256 totalFeeGrowth1Token,
        uint160 secondsPerLiquidityCumulative,
        int56 tickCumulative,
        uint32 time
    ) internal returns (int128 liquidityDelta) {
        Tick.Data storage data = self[tick];
        data.outerFeeGrowth0Token = totalFeeGrowth0Token - data.outerFeeGrowth0Token;
        data.outerFeeGrowth1Token = totalFeeGrowth1Token - data.outerFeeGrowth1Token;
        data.outerSecondsPerLiquidity = secondsPerLiquidityCumulative - data.outerSecondsPerLiquidity;
        data.outerTickCumulative = tickCumulative - data.outerTickCumulative;
        data.outerSecondsSpent = time - data.outerSecondsSpent;
        liquidityDelta = data.liquidityDelta;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.5.0;


/// @title Packed tick initialized state library
/// @notice Stores a packed mapping of tick index to its initialized state
/// @dev The mapping uses int16 for keys since ticks are represented as int24 and there are 256 (2^8) values per word.
library TickTable {
    /// @notice Computes the position in the mapping where the initialized bit for a tick lives
    /// @param tick The tick for which to compute the position
    /// @return rowNumber The key in the mapping containing the word in which the bit is stored
    /// @return bitNumber The bit position in the word where the flag is stored
    function position(int24 tick) private pure returns (int16 rowNumber, uint8 bitNumber) {
        assembly {
            bitNumber := smod(tick, 256)
            rowNumber := shr(8, tick)
        }
    }

    /// @notice Flips the initialized state for a given tick from false to true, or vice versa
    /// @param self The mapping in which to flip the tick
    /// @param tick The tick to flip
    function flipTick(
        mapping(int16 => uint256) storage self,
        int24 tick
    ) internal {
        require(tick % 60 == 0, 'tick is not spaced'); // ensure that the tick is spaced
        (int16 rowNumber, uint8 bitNumber) = position(tick / 60);
        self[rowNumber] ^= 1 << bitNumber;
    }

    function getLeastSignificantBit(uint256 word) internal pure returns(uint8 leastBitPos) {
        require(word > 0);
        assembly {
            word := and(sub(0, word), word)
            leastBitPos := gt(and(word, 0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA), 0)
            leastBitPos := or(leastBitPos, shl(7, gt( and(word, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000000000000000000000000000), 0)))
            leastBitPos := or(leastBitPos, shl(6, gt( and(word, 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000), 0)))
            leastBitPos := or(leastBitPos, shl(5, gt( and(word, 0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000), 0)))
            leastBitPos := or(leastBitPos, shl(4, gt( and(word, 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000), 0)))
            leastBitPos := or(leastBitPos, shl(3, gt( and(word, 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00), 0)))
            leastBitPos := or(leastBitPos, shl(2, gt( and(word, 0xF0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0), 0)))
            leastBitPos := or(leastBitPos, shl(1, gt( and(word, 0xCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC), 0)))
        }
    }

    function getMostSignificantBit(uint256 word) internal pure returns(uint8 mostBitPos) {
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
        return(getLeastSignificantBit(word));
    }

    /// @notice Returns the next initialized tick contained in the same word (or adjacent word) as the tick that is either
    /// to the left (less than or equal to) or right (greater than) of the given tick
    /// @param self The mapping in which to compute the next initialized tick
    /// @param tick The starting tick
    /// @param lte Whether to search for the next initialized tick to the left (less than or equal to the starting tick)
    /// @return next The next initialized or uninitialized tick up to 256 ticks away from the current tick
    /// @return initialized Whether the next tick is initialized, as the function only searches within up to 256 ticks
    function nextTickInTheSameRow(
        mapping(int16 => uint256) storage self,
        int24 tick,
        bool lte
    ) internal view returns (int24, bool) {
        int24 compressed = tick / 60;
        if (tick < 0 && tick % 60 != 0) compressed--; // round towards negative infinity

        if (lte) {
            (int16 rowNumber, uint8 bitNumber) = position(compressed);
            // all the 1s at or to the right of the current bitNumber
            uint256 _row = self[rowNumber] << (255 - bitNumber);

            if (_row != 0){
                return(
                    (compressed - int24(255 - getMostSignificantBit(_row))) * 60,
                    true
                );
            }
            else {
                return(
                    (compressed - int24(bitNumber)) * 60,
                    false
                );
            }
        } else {
            compressed += 1;
            // start from the word of the next tick, since the current tick state doesn't matter
            (int16 rowNumber, uint8 bitNumber) = position(compressed);
            // all the 1s at or to the left of the bitNumber
            //uint256 mask = ~((1 << bitNumber) - 1);
            //uint256 _row = self[rowNumber] & mask;

            uint256 _row = self[rowNumber] >> (bitNumber);
            
            if (_row != 0){
                return(
                    (compressed + int24(getLeastSignificantBit(_row))) * 60,
                    true
                );
            }
            else {
                return(
                    (compressed + int24(type(uint8).max - bitNumber)) * 60,
                    false
                );
            }
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
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20Minimal.transfer.selector, to, value));
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
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        // get abs value
        int24 mask = tick >> 24 - 1;
        uint256 absTick = uint256((tick ^ mask) - mask);
        //uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
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
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, 'R');
        uint256 ratio = uint256(sqrtPriceX96) << 32;

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

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
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

/// @title An interface for a contract that is capable of deploying Uniswap V3 Pools
/// @notice A contract that constructs a pool must implement this to pass arguments to the pool
/// @dev This is used to avoid having constructor arguments in the pool contract, which results in the init code hash
/// of the pool being constant allowing the CREATE2 address of the pool to be cheaply computed on-chain
interface IFuzzyswapPoolDeployer {
    /// @notice Get the parameters to be used in constructing the pool, set transiently during pool creation.
    /// @dev Called by the pool constructor to fetch the parameters of the pool
    /// Returns factory The factory address
    /// Returns token0 The first token of the pool by address sort order
    /// Returns token1 The second token of the pool by address sort order
    /// Returns fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    function parameters()
        external
        view
        returns (
            address dataStorage,
            address factory,
            address token0,
            address token1
        );

    function deploy(
        address dataStorage,
        address factory,
        address token0,
        address token1
    ) external returns (address pool);

    function setFactory(
        address factory
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Fuzzyswap Factory
/// @notice The Fuzzyswap Factory facilitates creation of Fuzzyswap pools and control over the protocol fees
interface IFuzzyswapFactory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        address pool
    );

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);


    /// @notice Returns the current poolDeployerAddress
    /// @return The address of the poolDeployer
    function poolDeployer() external view returns (address);

    /** @dev Is retrieved from the pools to restrict calling
     *  certain functions not by a stacker contract
     *  @return The stacker contract address
     */
    function stackerAddress() external view returns (address);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB
    ) external view returns (address pool);


    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /**
     * @dev updates stacker address on the factory
     * @param _stackerAddress The new stacker contract address
     */
    function setStackerAddress(address _stackerAddress) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Minimal ERC20 interface for Fuzzyswap
/// @notice Contains a subset of the full ERC20 interface that is used in Fuzzyswap
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

/// @title Callback for IFuzzyswapPoolActions#mint
/// @notice Any contract that calls IFuzzyswapPoolActions#mint must implement this interface
interface IFuzzyswapMintCallback {
    /// @notice Called to `msg.sender` after minting liquidity to a position from IFuzzyswapPool#mint.
    /// @dev In the implementation you must pay the pool tokens owed for the minted liquidity.
    /// The caller of this method must be checked to be a FuzzyswapPool deployed by the canonical FuzzyswapFactory.
    /// @param amount0Owed The amount of token0 due to the pool for the minted liquidity
    /// @param amount1Owed The amount of token1 due to the pool for the minted liquidity
    /// @param data Any data passed through by the caller via the IFuzzyswapPoolActions#mint call
    function fuzzyswapMintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IFuzzyswapPoolActions#swap
/// @notice Any contract that calls IFuzzyswapPoolActions#swap must implement this interface
interface IFuzzyswapSwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IFuzzyswapPool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a FuzzyswapPool deployed by the canonical FuzzyswapFactory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IFuzzyswapPoolActions#swap call
    function fuzzyswapSwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IFuzzyswapPoolActions#flash
/// @notice Any contract that calls IFuzzyswapPoolActions#flash must implement this interface
interface IFuzzyswapFlashCallback {
    /// @notice Called to `msg.sender` after transferring to the recipient from IFuzzyswapPool#flash.
    /// @dev In the implementation you must repay the pool the tokens sent by flash plus the computed fee amounts.
    /// The caller of this method must be checked to be a FuzzyswapPool deployed by the canonical FuzzyswapFactory.
    /// @param fee0 The fee amount in token0 due to the pool by the end of the flash
    /// @param fee1 The fee amount in token1 due to the pool by the end of the flash
    /// @param data Any data passed through by the caller via the IFuzzyswapPoolActions#flash call
    function fuzzyswapFlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import '../IDataStorageOperator.sol';

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IFuzzyswapPoolImmutables {
    function dataStorageOperator() external view returns (IDataStorageOperator);

    /// @notice The contract that deployed the pool, which must adhere to the IFuzzyswapFactory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (uint8);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IFuzzyswapPoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last dataStorage observation that was written,
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function globalState()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationIndexSwap,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function totalFeeGrowth0Token() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function totalFeeGrowth1Token() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    
    
    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityTotal the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityDelta how much liquidity changes when the pool price crosses the tick,
    /// outerFeeGrowth0Token the fee growth on the other side of the tick from the current tick in token0,
    /// outerFeeGrowth1Token the fee growth on the other side of the tick from the current tick in token1,
    /// outerTickCumulative the cumulative tick value on the other side of the tick from the current tick
    /// outerSecondsPerLiquidity the seconds spent per liquidity on the other side of the tick from the current tick,
    /// outerSecondsSpent the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityTotal is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityTotal is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
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

    /// @notice Returns 256 packed tick initialized boolean values. See TickTable for more information
    function tickTable(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, bottomTick and topTick
    /// @return  _liquidity The amount of liquidity in the position,
    /// Returns innerFeeGrowth0Token fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns innerFeeGrowth1Token fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns fees0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns fees1 the computed amount of token1 owed to the position as of the last mint/burn/poke
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

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulative the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulative,
            uint112 volatilityCumulative,
            bool initialized,
            uint256 volumePerAvgLiquidity
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IFuzzyswapPoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulatives Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives,
                uint160[] memory secondsPerLiquidityCumulatives,
                uint112[] memory volatilityCumulatives,
                uint256[] memory volumePerAvgLiquiditys
        );

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param bottomTick The lower tick of the range
    /// @param topTick The upper tick of the range
    /// @return innerTickCumulative The snapshot of the tick accumulator for the range
    /// @return innerSecondsSpentPerLiquidity The snapshot of seconds per liquidity for the range
    /// @return innerSecondsSpent The snapshot of seconds per liquidity for the range
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

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IFuzzyswapPoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/bottomTick/topTick position
    /// @dev The caller of this method receives a callback in the form of IFuzzyswapMintCallback#fuzzyswapMintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on bottomTick, topTick, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param bottomTick The lower tick of the position in which to add liquidity
    /// @param topTick The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address sender,
        address recipient,
        int24 bottomTick,
        int24 topTick,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1, uint256 liquidityAmount);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param bottomTick The lower tick of the position for which to collect fees
    /// @param topTick The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 bottomTick,
        int24 topTick,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param bottomTick The lower tick of the position for which to burn liquidity
    /// @param topTick The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 bottomTick,
        int24 topTick,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IFuzzyswapSwapCallback#fuzzyswapSwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    // TODO
    function swapSupportingFeeOnInputTokens(
        address sender,
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IFuzzyswapFlashCallback#fuzzyswapFlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IFuzzyswapPoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    function setIncentive(address virtualPoolAddress, uint32 endTimestamp, uint32 startTimestamp) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IFuzzyswapPoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param bottomTick The lower tick of the position
    /// @param topTick The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed bottomTick,
        int24 indexed topTick,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param bottomTick The lower tick of the position
    /// @param topTick The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed bottomTick,
        int24 indexed topTick,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param bottomTick The lower tick of the position
    /// @param topTick The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed bottomTick,
        int24 indexed topTick,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 0
  },
  "metadata": {
    "bytecodeHash": "none"
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
  "libraries": {}
}