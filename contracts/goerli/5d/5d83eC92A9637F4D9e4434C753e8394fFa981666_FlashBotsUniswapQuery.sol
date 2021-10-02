/**
 *Submitted for verification at Etherscan.io on 2021-10-01
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;

interface IUniswapV2Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

interface Quoter {
     function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);
    
     function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
}

interface IUniswapV3Pool {
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

    function token0() external view returns (address);

    function token1() external view returns (address);

    function fee() external view returns (uint24);

    function tickSpacing() external view returns (int24);
}

abstract contract UniswapV2Factory {
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    function allPairsLength() external view virtual returns (uint256);
}

abstract contract UniswapV3Factory {
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view virtual returns (address);
}

// In order to quickly load up data from Uniswap-like market, this contract allows easy iteration with a single eth_call
contract FlashBotsUniswapQuery {
    function getReservesByPairs(IUniswapV2Pair[] calldata _pairs)
        external
        view
        returns (uint256[3][] memory)
    {
        uint256[3][] memory result = new uint256[3][](_pairs.length);
        for (uint256 i = 0; i < _pairs.length; i++) {
            (result[i][0], result[i][1], result[i][2]) = _pairs[i]
                .getReserves();
        }
        return result;
    }

    function getPriceLiquidityFeeByPools(IUniswapV3Pool[] calldata _pools)
        external
        view
        returns (uint256[3][] memory)
    {
        uint256[3][] memory result = new uint256[3][](_pools.length);
        for (uint256 i = 0; i < _pools.length; i++) {
            (result[i][0], , , , , , ) = _pools[i].slot0();
            result[i][1] = _pools[i].liquidity();
            result[i][2] = _pools[i].fee();
        }
        return result;
    }

    function getPairsByIndexRange(
        UniswapV2Factory _uniswapFactory,
        uint256 _start,
        uint256 _stop
    ) external view returns (address[3][] memory) {
        uint256 _allPairsLength = _uniswapFactory.allPairsLength();
        if (_stop > _allPairsLength) {
            _stop = _allPairsLength;
        }
        require(_stop >= _start, "start cannot be higher than stop");
        uint256 _qty = _stop - _start;
        address[3][] memory result = new address[3][](_qty);
        for (uint256 i = 0; i < _qty; i++) {
            IUniswapV2Pair _uniswapPair = IUniswapV2Pair(
                _uniswapFactory.allPairs(_start + i)
            );
            result[i][0] = _uniswapPair.token0();
            result[i][1] = _uniswapPair.token1();
            result[i][2] = address(_uniswapPair);
        }
        return result;
    }

    function getPoolsByTokens(
        UniswapV3Factory _uniswapFactory,
        address[] memory _token0,
        address[] memory _token1,
        uint24[] memory _feeList
    ) external view returns (address[3][] memory) {
        require(
            _token0.length == _token1.length,
            "token 0 and 1 length not equal"
        );
        uint256 count = 0;
        address[3][] memory result = new address[3][](_token0.length * 3);
        for (uint256 i = 0; i < _token0.length; i++) {
            for (uint256 j = 0; j < _feeList.length; j++) {
                address poolAddress = _uniswapFactory.getPool(
                    _token0[i],
                    _token1[i],
                    _feeList[j]
                );
                if (poolAddress != address(0)) {
                    result[count][0] = _token0[i];
                    result[count][1] = _token1[i];
                    result[count][2] = poolAddress;
                    count++;
                }
            }
        }
        address[3][] memory finalResult = new address[3][](count);
        for (uint256 k = 0; k < count; k++) {
            finalResult[k][0] = result[k][0];
            finalResult[k][1] = result[k][1];
            finalResult[k][2] = result[k][2];
        }
        return result;
    }
    
    function V3getTokensOut(
        Quoter _quoter,
        address _tokenIn,
        address _tokenOut,
        uint24 _fee,
        uint256 _inAmount,
        uint160 _sqrtPriceLimitX96
    ) external payable returns (uint256) {
        return
            _quoter.quoteExactInputSingle(
                _tokenIn,
                _tokenOut,
                _fee,
                _inAmount,
                _sqrtPriceLimitX96
            );
    }
    
    function V3getTokensIn(
        Quoter _quoter,
        address _tokenIn,
        address _tokenOut,
        uint24 _fee,
        uint256 _outAmount,
        uint160 _sqrtPriceLimitX96
    ) external payable returns (uint256) {
        return
            _quoter.quoteExactOutputSingle(
                _tokenIn,
                _tokenOut,
                _fee,
                _outAmount,
                _sqrtPriceLimitX96
            );
    }
}