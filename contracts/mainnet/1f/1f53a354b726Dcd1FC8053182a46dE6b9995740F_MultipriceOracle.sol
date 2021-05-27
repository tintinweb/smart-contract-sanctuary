// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import '@uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolState.sol';
import '@uniswap/v3-core/contracts/libraries/FullMath.sol';
import '@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol';

import './interfaces/IERC20.sol';
import './interfaces/IChainlink.sol';
import './interfaces/IUniswapV2.sol';
import './interfaces/IUniswapV3.sol';

import './libraries/Math.sol';
import './libraries/SafeCast.sol';
import './libraries/SafeMath.sol';
import './libraries/UniswapV2Library.sol';

/// @title Multiprice oracle sourcing asset prices from multiple on-chain sources
contract MultipriceOracle {
    using SafeCast for uint256;
    using SafeMath for uint256;

    IChainLinkFeedsRegistry public immutable chainLinkRegistry;
    address public immutable uniswapV3Factory;
    uint24 public immutable uniswapV3PoolFee;
    IUniswapV3CrossPoolOracle public immutable uniswapV3Oracle;
    IUniswapV2Factory public immutable uniswapV2Factory;
    IUniswapV2Factory public immutable sushiswapFactory;
    address public immutable weth;

    mapping(address => bool) public isUsdEquivalent;

    uint256 private constant WEI_UNIT = 10**18;

    constructor(
        IChainLinkFeedsRegistry _chainLinkRegistry,
        address _uniswapV3Factory,
        uint24 _uniswapV3PoolFee,
        IUniswapV3CrossPoolOracle _uniswapV3Oracle,
        IUniswapV2Factory _uniswapV2Factory,
        IUniswapV2Factory _sushiswapFactory,
        address _weth,
        address[] memory _usdEquivalents
    ) {
        chainLinkRegistry = _chainLinkRegistry;
        uniswapV3Factory = _uniswapV3Factory;
        uniswapV3PoolFee = _uniswapV3PoolFee;
        uniswapV3Oracle = _uniswapV3Oracle;
        uniswapV2Factory = _uniswapV2Factory;
        sushiswapFactory = _sushiswapFactory;
        weth = _weth;

        for (uint256 ii = 0; ii < _usdEquivalents.length; ++ii) {
            isUsdEquivalent[_usdEquivalents[ii]] = true;
        }
    }

    function assetToAsset(
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut,
        uint256 _clPriceBuffer,
        uint32 _uniswapV3TwapPeriod,
        uint8 _inclusionBitmap
    )
        external
        view
        returns (
            uint256 value,
            uint256 cl,
            uint256 clBuf,
            uint256 uniV3Twap,
            uint256 uniV3Spot,
            uint256 uniV2Spot,
            uint256 sushiSpot
        )
    {
        // Inclusion bitmap only considers five lowest bits
        require(uint256(_inclusionBitmap) < 1 << 5, 'Inclusion bitmap invalid');

        cl = chainLinkAssetToAsset(_tokenIn, _amountIn, _tokenOut);
        clBuf = cl.mul(WEI_UNIT.sub(_clPriceBuffer)).div(WEI_UNIT);
        uniV3Twap = uniV3TwapAssetToAsset(_tokenIn, _amountIn, _tokenOut, _uniswapV3TwapPeriod);
        uniV3Spot = uniV3SpotAssetToAsset(_tokenIn, _amountIn, _tokenOut);
        uniV2Spot = uniV2SpotAssetToAsset(uniswapV2Factory, _tokenIn, _amountIn, _tokenOut);
        sushiSpot = uniV2SpotAssetToAsset(sushiswapFactory, _tokenIn, _amountIn, _tokenOut);

        uint256[5] memory inclusions = [clBuf, uniV3Twap, uniV3Spot, uniV2Spot, sushiSpot];
        for (uint256 ii = 0; _inclusionBitmap > 0; ) {
            if (_inclusionBitmap % 2 > 0) {
                value = value > 0 ? Math.min(value, inclusions[ii]) : inclusions[ii];
            }

            // Loop bookkeeping
            ++ii;
            _inclusionBitmap >>= 1;
        }
    }

    /********************
     * Chainlink quotes *
     ********************/
    function chainLinkAssetToAsset(
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut
    ) public view returns (uint256 amountOut) {
        int256 inDecimals = uint256(IERC20(_tokenIn).decimals()).toInt256();
        int256 outDecimals = uint256(IERC20(_tokenOut).decimals()).toInt256();

        if (isUsdEquivalent[_tokenOut]) {
            uint256 rate = chainLinkRegistry.getPriceUSD(_tokenIn);

            // Rate is 0 if the token's feed is not registered
            if (rate > 0) {
                // Adjust decimals for output amount in tokenOut's decimals
                // Rates for usd queries are in 8 decimals
                int256 eFactor = outDecimals - inDecimals - 8;
                return _adjustDecimals(_amountIn.mul(rate), eFactor);
            }
        }

        if (_tokenOut == weth) {
            uint256 rate = chainLinkRegistry.getPriceETH(_tokenIn);

            // Rate is 0 if the token's feed is not registered
            if (rate > 0) {
                // Adjust decimals for output amount in wei
                // Rates for eth queries are in 18 decimals but are cancelled out by wei's 18
                // decimals, leaving just the in decimals to be adjusted for
                int256 eFactor = -inDecimals;
                return _adjustDecimals(_amountIn.mul(rate), eFactor);
            }
        }

        // Try our best to go between two chainlink feeds
        // Messy but tippy-toeing around stack too deeps
        // All four cases covered (token1 price <> token2 price):
        //   1. usd<>usd
        //   2. usd<>eth
        //   3. eth<>eth
        //   4. eth<>usd

        uint256 inUsdRate = chainLinkRegistry.getPriceUSD(_tokenIn);
        uint256 outUsdRate = chainLinkRegistry.getPriceUSD(_tokenOut);
        if (inUsdRate > 0 && outUsdRate > 0) {
            // usd<>usd; both tokens priced in usd terms
            int256 eFactor = outDecimals - inDecimals;
            return _adjustDecimals(_amountIn.mul(inUsdRate).div(outUsdRate), eFactor);
        }

        uint256 inEthRate = chainLinkRegistry.getPriceETH(_tokenIn);
        uint256 outEthRate = chainLinkRegistry.getPriceETH(_tokenOut);
        if (inEthRate > 0 && outEthRate > 0) {
            // eth<>eth; both tokens priced in eth terms
            int256 eFactor = outDecimals - inDecimals;
            return _adjustDecimals(_amountIn.mul(inEthRate).div(outEthRate), eFactor);
        }

        uint256 ethUsdRate = chainLinkRegistry.getPriceUSD(weth);
        if (inUsdRate > 0 && outEthRate > 0) {
            // usd<>eth; convert via amount in -> usd -> eth -> amount out:
            //   amountIn (usd) = amountIn * tokenIn usd rate
            //   amountOut (eth) = amountIn (usd) / eth usd rate
            //   amountOut = amountOut (eth) / tokenOut eth rate
            // Adjust for e-factor first to avoid losing precision from large divisions
            // Usd rates cancel each other, leaving just the 18 decimals from the eth rate and token decimals
            int256 eFactor = outDecimals - inDecimals + 18;
            uint256 adjustedInUsdValue = _adjustDecimals(_amountIn.mul(inUsdRate), eFactor);
            return adjustedInUsdValue.div(ethUsdRate).div(outEthRate);
        }

        if (inEthRate > 0 && outUsdRate > 0) {
            // eth<>usd; convert via amount in -> eth -> usd -> amount out:
            //   amountIn (eth) = amountIn * tokenIn eth rate
            //   amountOut (usd) = amountIn (eth) * eth usd rate
            //   amountOut = amountOut (usd) / tokenOut usd rate
            uint256 unadjustedInUsdValue = _amountIn.mul(inEthRate).mul(ethUsdRate);
            uint256 unadjustedOutAmount = unadjustedInUsdValue.div(outUsdRate); // split div to avoid stack too deep
            // Usd rates cancel each other, leaving just the 18 decimals from the eth rate and token decimals
            int256 eFactor = outDecimals - inDecimals - 18;
            return _adjustDecimals(unadjustedOutAmount, eFactor);
        }

        revert('ChainLink rate not available');
    }

    function _adjustDecimals(uint256 _amount, int256 _eFactor) internal pure returns (uint256) {
        if (_eFactor < 0) {
            uint256 tenToE = 10**uint256(-_eFactor);
            return _amount.div(tenToE);
        } else {
            uint256 tenToE = 10**uint256(_eFactor);
            return _amount.mul(tenToE);
        }
    }

    /*************************
     * UniswapV3 TWAP quotes *
     *************************/
    function uniV3TwapAssetToAsset(
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut,
        uint32 _twapPeriod
    ) public view returns (uint256 amountOut) {
        return uniswapV3Oracle.assetToAsset(_tokenIn, _amountIn, _tokenOut, _twapPeriod);
    }

    /*************************
     * UniswapV3 spot quotes *
     *************************/
    function uniV3SpotAssetToAsset(
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut
    ) public view returns (uint256 amountOut) {
        if (_tokenIn == weth) {
            return _uniV3SpotPrice(weth, _amountIn, _tokenOut);
        } else if (_tokenOut == weth) {
            return _uniV3SpotPrice(_tokenIn, _amountIn, weth);
        } else {
            uint256 ethAmount = _uniV3SpotPrice(_tokenIn, _amountIn, weth);
            return _uniV3SpotPrice(weth, ethAmount, _tokenOut);
        }
    }

    function _uniV3SpotPrice(
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut
    ) internal view returns (uint256 amountOut) {
        address pool =
            PoolAddress.computeAddress(uniswapV3Factory, PoolAddress.getPoolKey(_tokenIn, _tokenOut, uniswapV3PoolFee));
        (uint160 sqrtPriceX96, , , , , , ) = IUniswapV3PoolState(pool).slot0();

        // 160 + 160 - 64 = 256; 96 + 96 - 64 = 128
        uint256 priceX128 = FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, 1 << 64);

        // Pool prices base/quote with lowerToken/higherToken, so adjust for inputs
        return
            _tokenIn < _tokenOut
                ? FullMath.mulDiv(priceX128, _amountIn, 1 << 128)
                : FullMath.mulDiv(1 << 128, _amountIn, priceX128);
    }

    /***********************************
     * UniswapV2/Sushiswap spot quotes *
     ***********************************/
    function uniV2SpotAssetToAsset(
        IUniswapV2Factory _factory,
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut
    ) public view returns (uint256 amountOut) {
        if (_tokenIn == weth) {
            return _uniV2SpotEthToAsset(_factory, _amountIn, _tokenOut);
        } else if (_tokenOut == weth) {
            return _uniV2SpotAssetToEth(_factory, _tokenIn, _amountIn);
        } else {
            uint256 ethAmount = _uniV2SpotAssetToEth(_factory, _tokenIn, _amountIn);
            return _uniV2SpotEthToAsset(_factory, ethAmount, _tokenOut);
        }
    }

    function _uniV2SpotAssetToEth(
        IUniswapV2Factory _factory,
        address _tokenIn,
        uint256 _amountIn
    ) internal view returns (uint256 ethAmountOut) {
        address pair = _factory.getPair(_tokenIn, weth);
        (uint256 tokenInReserve, uint256 ethReserve) = UniswapV2Library.getReserves(pair, _tokenIn, weth);
        // No slippage--just spot pricing based on current reserves
        return UniswapV2Library.quote(_amountIn, tokenInReserve, ethReserve);
    }

    function _uniV2SpotEthToAsset(
        IUniswapV2Factory _factory,
        uint256 _ethAmountIn,
        address _tokenOut
    ) internal view returns (uint256 amountOut) {
        address pair = _factory.getPair(weth, _tokenOut);
        (uint256 ethReserve, uint256 tokenOutReserve) = UniswapV2Library.getReserves(pair, weth, _tokenOut);
        // No slippage--just spot pricing based on current reserves
        return UniswapV2Library.quote(_ethAmountIn, ethReserve, tokenOutReserve);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
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

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
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

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
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

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
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
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        factory,
                        keccak256(abi.encode(key.token0, key.token1, key.fee)),
                        POOL_INIT_CODE_HASH
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

interface IERC20 {
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

// See https://etherscan.io/address/0x271bf4568fb737cc2e6277e9B1EE0034098cDA2a#code
interface IChainLinkFeedsRegistry {
    function getPriceETH(address tokenIn) external view returns (uint256);

    function getPriceUSD(address tokenIn) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.7.6;

// See https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/interfaces/IUniswapV2Factory.sol
interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

// See https://github.com/sohkai/uniswap-v3-cross-pool-oracle
interface IUniswapV3CrossPoolOracle {
    function assetToAsset(
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint32 twapPeriod
    ) external view returns (uint256 amountOut);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

// See https://github.com/Uniswap/uniswap-v3-core/blob/main/contracts/libraries/SafeCast.sol
library SafeCast {
    function toInt256(uint256 y) internal pure returns (int256 z) {
        require(y < 2**255);
        z = int256(y);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.7.6;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

import "./SafeMath.sol";

// Forked from https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol
// Modified getReserves() to accept a pair rather than factory and updates to the internal SafeMath that's not pegged to solc 0.6.6
// Sushiswap's factory uses a different init code than UniswapV2's, and so it's more reliable to
// grab the pair's address from the factory than to calculate it
library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address pair, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pair).getReserves();
        (address token0,) = sortTokens(tokenA, tokenB);
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
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