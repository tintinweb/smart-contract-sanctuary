// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./Ether.sol";
import "./MultiCall.sol";
import "./UniV3Helper.sol";

//solhint-disable-next-line no-empty-blocks
contract EvmHelpers is Ether, MultiCall, UniV3Helper {}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;


contract Ether {
    function balanceOf(address wallet) external view returns (uint256) {
        return wallet.balance;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;


contract MultiCall {
    struct Call {
        address to;
        bytes data;
    }

   function multicall(Call[] memory calls) public returns (bytes[] memory results) {
        results = new bytes[](calls.length);
        for (uint i = 0; i < calls.length; i++) {
            (, results[i]) = calls[i].to.call(calls[i].data);  // solhint-disable-line avoid-low-level-calls
        }
    }


    // be careful with calls.length == 0
    function multicallWithGasLimitation(Call[] memory calls, uint256 gasBuffer) public returns (bytes[] memory results, uint256 lastSuccessIndex) {
        results = new bytes[](calls.length);
        for (uint i = 0; i < calls.length; i++) {
            (, results[i]) = calls[i].to.call(calls[i].data);  // solhint-disable-line avoid-low-level-calls
            if (gasleft() < gasBuffer) {
                return (results, i);
            }
        }
        return (results, calls.length - 1);
    }

   function multicallWithGas(Call[] memory calls) public returns (bytes[] memory results, uint256[] memory gasUsed) {
        results = new bytes[](calls.length);
        gasUsed = new uint256[](calls.length);
        for (uint i = 0; i < calls.length; i++) {
            uint256 initialGas = gasleft();
            (, results[i]) = calls[i].to.call(calls[i].data);  // solhint-disable-line avoid-low-level-calls
            gasUsed[i] = initialGas - gasleft();
        }
    }

    function gaslimit() external view returns (uint256) {
        return block.gaslimit;
    }

    function gasLeft() external view returns (uint256) {
        return gasleft();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./interfaces/IUniswapV3.sol";


contract UniV3Helper {
    int24 private constant _MIN_TICK = -887272;
    int24 private constant _MAX_TICK = -_MIN_TICK;

    struct Tick {
        uint128 liquidityGross;
        int128 liquidityNet;
        uint256 feeGrowthOutside0X128;
        uint256 feeGrowthOutside1X128;
        int56 tickCumulativeOutside;
        uint160 secondsPerLiquidityOutsideX128;
        uint32 secondsOutside;
        int24 index; // tick index
    }

    function getTicks(IUniswapV3 pool, int24 tickRange) external view returns (bytes[] memory ticks) {
        int24 tickSpacing = pool.tickSpacing();
        (,int24 tick,,,,,) = pool.slot0();

        int24 fromTick = tick - (tickSpacing * tickRange);
        int24 toTick = tick + (tickSpacing * tickRange);
        if (fromTick < _MIN_TICK) {
            fromTick = _MIN_TICK;
        }
        if (toTick > _MAX_TICK) {
            toTick = _MAX_TICK;
        }

        int24[] memory initTicks = new int24[](uint256(int256((toTick - fromTick + 1) / tickSpacing)));

        uint256 counter = 0;
        for (int24 tickNum = (fromTick / tickSpacing * tickSpacing); tickNum <=  (toTick / tickSpacing * tickSpacing); tickNum += (256 * tickSpacing)) {
            int16 pos = int16((tickNum / tickSpacing) >> 8);
            uint256 bm = pool.tickBitmap(pos);

             while (bm != 0) {
                 uint8 bit = _mostSignificantBit(bm);
                 initTicks[counter] = (int24(pos) * 256 + int24(uint24(bit))) * tickSpacing;

                 counter += 1;
                 bm ^= 1 << bit;
             }

        }

        ticks = new bytes[](counter);
        for (uint256 i = 0; i < counter; i++) {
            (
                uint128 liquidityGross,
                int128 liquidityNet,
                uint256 feeGrowthOutside0X128,
                uint256 feeGrowthOutside1X128
                , // int56 tickCumulativeOutside,
                , // secondsPerLiquidityOutsideX128
                , // uint32 secondsOutside
                , // init
            ) = pool.ticks(initTicks[i]);

             ticks[i] = abi.encodePacked(
                 liquidityGross,
                 liquidityNet,
                 feeGrowthOutside0X128,
                 feeGrowthOutside1X128,
                 // tickCumulativeOutside,
                 // secondsPerLiquidityOutsideX128,
                 // secondsOutside,
                 initTicks[i]
             );
        }
    }

    function _mostSignificantBit(uint256 x) private pure returns (uint8 r) {
        require(x > 0, "x is 0");

        if (x >= 0x100000000000000000000000000000000) {
            x >>= 128;
            r += 128;
        }
        if (x >= 0x10000000000000000) {
            x >>= 64;
            r += 64;
        }
        if (x >= 0x100000000) {
            x >>= 32;
            r += 32;
        }
        if (x >= 0x10000) {
            x >>= 16;
            r += 16;
        }
        if (x >= 0x100) {
            x >>= 8;
            r += 8;
        }
        if (x >= 0x10) {
            x >>= 4;
            r += 4;
        }
        if (x >= 0x4) {
            x >>= 2;
            r += 2;
        }
        if (x >= 0x2) r += 1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;


interface IUniswapV3 {
    function tickSpacing() external view returns (int24);

    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    function feeGrowthGlobal0X128() external view returns (uint256);

    function feeGrowthGlobal1X128() external view returns (uint256);

    function protocolFees() external view returns (uint128 token0, uint128 token1);

    function liquidity() external view returns (uint128);

    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    function tickBitmap(int16 wordPosition) external view returns (uint256);

    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}