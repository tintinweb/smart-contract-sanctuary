// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import "./LowGasSafeMath.sol";
import "./SafeCast.sol";
import "./TickMath.sol";
import "./SwapMath.sol";
import "./BitMath.sol";
import "./IUniswapV3Pool.sol";


contract PriceMath {
    using LowGasSafeMath for uint256;
    using LowGasSafeMath for int256;
    using SafeCast for uint256;
    using SafeCast for int256;
    
    struct SwapState {
        uint160 sqrtPriceX96;
        uint160 sqrtPriceNextX96;
        int24 tick;
        int24 tickNext;
        uint24 fee;
        uint128 liquidity;
        int24 tickSpacing;
        int256 amountInMax;
    }

    function calculate(
        address poolAddress,
        bool zeroForOne
    ) external view returns (int256 amount0, int256 amount1) {
        IUniswapV3Pool pool = IUniswapV3Pool(poolAddress);

        SwapState memory state = SwapState({
            sqrtPriceX96: 0,
            sqrtPriceNextX96: 0,
            tick: 0,
            tickNext: 0,
            fee: pool.fee(),
            liquidity: pool.liquidity(),
            tickSpacing: pool.tickSpacing(),
            amountInMax: 1000000000000000000000 // 1000 ETH
        });

        (state.sqrtPriceX96, state.tick,,,,,) = pool.slot0();

        (state.tickNext,) = nextInitializedTickWithinOneWord(
            pool,
            state.tick,
            state.tickSpacing,
            zeroForOne
        );
        if (state.tickNext < TickMath.MIN_TICK) {
            state.tickNext = TickMath.MIN_TICK;
        } else if (state.tickNext > TickMath.MAX_TICK) {
            state.tickNext = TickMath.MAX_TICK;
        }

        state.sqrtPriceNextX96 = TickMath.getSqrtRatioAtTick(state.tickNext);

        (, uint256 amountIn, uint256 amountOut, uint256 feeAmount) = SwapMath.computeSwapStep(
            state.sqrtPriceX96,
            state.sqrtPriceNextX96,
            state.liquidity,
            state.amountInMax,
            state.fee
        );

        int256 amountInCalculated = (amountIn + feeAmount).toInt256();
        int256 amountOutCalculated = amountOut.toInt256();

        (amount0, amount1) = zeroForOne
            ? (amountInCalculated, amountOutCalculated)
            : (amountOutCalculated, amountInCalculated);
    }

    function nextInitializedTickWithinOneWord(
        IUniswapV3Pool pool,
        int24 tick,
        int24 tickSpacing,
        bool lte
    ) internal view returns (int24 next, bool initialized) {
        int24 compressed = tick / tickSpacing;
        if (tick < 0 && tick % tickSpacing != 0) compressed--; // round towards negative infinity

        if (lte) {
            (int16 wordPos, uint8 bitPos) = position(compressed);
            // all the 1s at or to the right of the current bitPos
            uint256 mask = (1 << bitPos) - 1 + (1 << bitPos);
            uint256 masked = pool.tickBitmap(wordPos) & mask;

            // if there are no initialized ticks to the right of or at the current tick, return rightmost in the word
            initialized = masked != 0;
            // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
            next = initialized
                ? (compressed - int24(bitPos - BitMath.mostSignificantBit(masked))) * tickSpacing
                : (compressed - int24(bitPos)) * tickSpacing;
        } else {
            // start from the word of the next tick, since the current tick state doesn't matter
            (int16 wordPos, uint8 bitPos) = position(compressed + 1);
            // all the 1s at or to the left of the bitPos
            uint256 mask = ~((1 << bitPos) - 1);
            uint256 masked = pool.tickBitmap(wordPos) & mask;

            // if there are no initialized ticks to the left of the current tick, return leftmost in the word
            initialized = masked != 0;
            // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
            next = initialized
                ? (compressed + 1 + int24(BitMath.leastSignificantBit(masked) - bitPos)) * tickSpacing
                : (compressed + 1 + int24(type(uint8).max - bitPos)) * tickSpacing;
        }
    }

    function position(int24 tick) private pure returns (int16 wordPos, uint8 bitPos) {
        wordPos = int16(tick >> 8);
        bitPos = uint8(tick % 256);
    }
}