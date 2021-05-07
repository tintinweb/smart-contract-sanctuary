/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

pragma solidity ^0.7.6;

pragma abicoder v2;

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


contract UniV3Helper {
    
    int24 private constant MIN_TICK = -887272;
    int24 private constant MAX_TICK = -MIN_TICK;
    
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
        if (fromTick < MIN_TICK) {
            fromTick = MIN_TICK;
        }
        if (toTick > MAX_TICK) {
            toTick = MAX_TICK;
        }
        
        int24[] memory initTicks = new int24[](uint((toTick - fromTick + 1) / tickSpacing));

        uint counter = 0;
        for (int24 tickNum = (fromTick / tickSpacing * tickSpacing); tickNum <=  (toTick / tickSpacing * tickSpacing); tickNum += (256 * tickSpacing)) {
            int16 pos = int16((tickNum / tickSpacing) >> 8);
            uint256 bm = pool.tickBitmap(pos);   
        
             while (bm != 0) {
                 uint8 bit = mostSignificantBit(bm);
                 initTicks[counter] = (int24(pos) * 256 + int24(bit)) * tickSpacing;
                 
                 counter += 1;
                 bm ^= 1 << bit;
             }
             
        }
        
        ticks = new bytes[](counter);
        for (uint i = 0; i < counter; i++) {
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
    
    function mostSignificantBit(uint256 x) private pure returns (uint8 r) {
        require(x > 0);

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