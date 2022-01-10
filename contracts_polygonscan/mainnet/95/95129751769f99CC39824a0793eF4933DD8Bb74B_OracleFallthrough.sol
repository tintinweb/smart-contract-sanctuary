// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

/* ==========  Libraries  ========== */
import "../lib/PriceLibrary.sol";
import "../lib/FixedPoint.sol";


interface IIndexedUniswapV2Oracle {
/* ==========  Mutative Functions  ========== */

  function updatePrice(address token) external returns (bool);

  function updatePrices(address[] calldata tokens) external returns (bool[] memory);

/* ==========  Meta Price Queries  ========== */

  function hasPriceObservationInWindow(address token, uint256 priceKey) external view returns (bool);

  function getPriceObservationInWindow(
    address token, uint256 priceKey
  ) external view returns (PriceLibrary.PriceObservation memory);

  function getPriceObservationsInRange(
    address token, uint256 timeFrom, uint256 timeTo
  ) external view returns (PriceLibrary.PriceObservation[] memory prices);

/* ==========  Price Update Queries  ========== */

  function canUpdatePrice(address token) external view returns (bool);

  function canUpdatePrices(address[] calldata tokens) external view returns (bool[] memory);

/* ==========  Price Queries: Singular  ========== */

  function computeTwoWayAveragePrice(
    address token, uint256 minTimeElapsed, uint256 maxTimeElapsed
  ) external view returns (PriceLibrary.TwoWayAveragePrice memory);

  function computeAverageTokenPrice(
    address token, uint256 minTimeElapsed, uint256 maxTimeElapsed
  ) external view returns (FixedPoint.uq112x112 memory);

  function computeAverageEthPrice(
    address token, uint256 minTimeElapsed, uint256 maxTimeElapsed
  ) external view returns (FixedPoint.uq112x112 memory);

/* ==========  Price Queries: Multiple  ========== */

  function computeTwoWayAveragePrices(
    address[] calldata tokens,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) external view returns (PriceLibrary.TwoWayAveragePrice[] memory);

  function computeAverageTokenPrices(
    address[] calldata tokens,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) external view returns (FixedPoint.uq112x112[] memory);

  function computeAverageEthPrices(
    address[] calldata tokens,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) external view returns (FixedPoint.uq112x112[] memory);

/* ==========  Value Queries: Singular  ========== */

  function computeAverageEthForTokens(
    address token,
    uint256 tokenAmount,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) external view returns (uint144);

  function computeAverageTokensForEth(
    address token,
    uint256 wethAmount,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) external view returns (uint144);

/* ==========  Value Queries: Multiple  ========== */

  function computeAverageEthForTokens(
    address[] calldata tokens,
    uint256[] calldata tokenAmounts,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) external view returns (uint144[] memory);

  function computeAverageTokensForEth(
    address[] calldata tokens,
    uint256[] calldata wethAmounts,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) external view returns (uint144[] memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

/* ==========  Internal Libraries  ========== */
import "./FixedPoint.sol";
import "./UniswapV2OracleLibrary.sol";
import "./UniswapV2Library.sol";


library PriceLibrary {
  using FixedPoint for FixedPoint.uq112x112;
  using FixedPoint for FixedPoint.uq144x112;

/* ========= Structs ========= */

  struct PriceObservation {
    uint32 timestamp;
    uint224 priceCumulativeLast;
    uint224 ethPriceCumulativeLast;
  }

  /**
   * @dev Average prices for a token in terms of weth and weth in terms of the token.
   *
   * Note: The average weth price is not equivalent to the reciprocal of the average
   * token price. See the UniSwap whitepaper for more info.
   */
  struct TwoWayAveragePrice {
    uint224 priceAverage;
    uint224 ethPriceAverage;
  }

/* ========= View Functions ========= */

  function pairInitialized(
    address uniswapFactory,
    address token,
    address weth
  )
    internal
    view
    returns (bool)
  {
    address pair = UniswapV2Library.pairFor(uniswapFactory, token, weth);
    (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(pair).getReserves();
    return reserve0 != 0 && reserve1 != 0;
  }

  function observePrice(
    address uniswapFactory,
    address tokenIn,
    address quoteToken
  )
    internal
    view
    returns (uint32 /* timestamp */, uint224 /* priceCumulativeLast */)
  {
    (address token0, address token1) = UniswapV2Library.sortTokens(tokenIn, quoteToken);
    address pair = UniswapV2Library.calculatePair(uniswapFactory, token0, token1);
    if (token0 == tokenIn) {
      (uint256 price0Cumulative, uint32 blockTimestamp) = UniswapV2OracleLibrary.currentCumulativePrice0(pair);
      return (blockTimestamp, uint224(price0Cumulative));
    } else {
      (uint256 price1Cumulative, uint32 blockTimestamp) = UniswapV2OracleLibrary.currentCumulativePrice1(pair);
      return (blockTimestamp, uint224(price1Cumulative));
    }
  }

  /**
   * @dev Query the current cumulative price of a token in terms of weth
   * and the current cumulative price of weth in terms of the token.
   */
  function observeTwoWayPrice(
    address uniswapFactory,
    address token,
    address weth
  ) internal view returns (PriceObservation memory) {
    (address token0, address token1) = UniswapV2Library.sortTokens(token, weth);
    address pair = UniswapV2Library.calculatePair(uniswapFactory, token0, token1);
    // Get the sorted token prices
    (
      uint256 price0Cumulative,
      uint256 price1Cumulative,
      uint32 blockTimestamp
    ) = UniswapV2OracleLibrary.currentCumulativePrices(pair);
    // Check which token is weth and which is the token,
    // then build the price observation.
    if (token0 == token) {
      return PriceObservation({
        timestamp: blockTimestamp,
        priceCumulativeLast: uint224(price0Cumulative),
        ethPriceCumulativeLast: uint224(price1Cumulative)
      });
    } else {
      return PriceObservation({
        timestamp: blockTimestamp,
        priceCumulativeLast: uint224(price1Cumulative),
        ethPriceCumulativeLast: uint224(price0Cumulative)
      });
    }
  }

/* ========= Utility Functions ========= */

  /**
   * @dev Computes the average price of a token in terms of weth
   * and the average price of weth in terms of a token using two
   * price observations.
   */
  function computeTwoWayAveragePrice(
    PriceObservation memory observation1,
    PriceObservation memory observation2
  ) internal pure returns (TwoWayAveragePrice memory) {
    uint32 timeElapsed = uint32(observation2.timestamp - observation1.timestamp);
    FixedPoint.uq112x112 memory priceAverage = UniswapV2OracleLibrary.computeAveragePrice(
      observation1.priceCumulativeLast,
      observation2.priceCumulativeLast,
      timeElapsed
    );
    FixedPoint.uq112x112 memory ethPriceAverage = UniswapV2OracleLibrary.computeAveragePrice(
      observation1.ethPriceCumulativeLast,
      observation2.ethPriceCumulativeLast,
      timeElapsed
    );
    return TwoWayAveragePrice({
      priceAverage: priceAverage._x,
      ethPriceAverage: ethPriceAverage._x
    });
  }

  function computeAveragePrice(
    uint32 timestampStart,
    uint224 priceCumulativeStart,
    uint32 timestampEnd,
    uint224 priceCumulativeEnd
  ) internal pure returns (FixedPoint.uq112x112 memory) {
    return UniswapV2OracleLibrary.computeAveragePrice(
      priceCumulativeStart,
      priceCumulativeEnd,
      uint32(timestampEnd - timestampStart)
    );
  }

  /**
   * @dev Computes the average price of the token the price observations
   * are for in terms of weth.
   */
  function computeAverageTokenPrice(
    PriceObservation memory observation1,
    PriceObservation memory observation2
  ) internal pure returns (FixedPoint.uq112x112 memory) {
    return UniswapV2OracleLibrary.computeAveragePrice(
      observation1.priceCumulativeLast,
      observation2.priceCumulativeLast,
      uint32(observation2.timestamp - observation1.timestamp)
    );
  }

  /**
   * @dev Computes the average price of weth in terms of the token
   * the price observations are for.
   */
  function computeAverageEthPrice(
    PriceObservation memory observation1,
    PriceObservation memory observation2
  ) internal pure returns (FixedPoint.uq112x112 memory) {
    return UniswapV2OracleLibrary.computeAveragePrice(
      observation1.ethPriceCumulativeLast,
      observation2.ethPriceCumulativeLast,
      uint32(observation2.timestamp - observation1.timestamp)
    );
  }

  /**
   * @dev Compute the average value in weth of `tokenAmount` of the
   * token that the average price values are for.
   */
  function computeAverageEthForTokens(
    TwoWayAveragePrice memory prices,
    uint256 tokenAmount
  ) internal pure returns (uint144) {
    return FixedPoint.uq112x112(prices.priceAverage).mul(tokenAmount).decode144();
  }

  /**
   * @dev Compute the average value of `wethAmount` weth in terms of
   * the token that the average price values are for.
   */
  function computeAverageTokensForEth(
    TwoWayAveragePrice memory prices,
    uint256 wethAmount
  ) internal pure returns (uint144) {
    return FixedPoint.uq112x112(prices.ethPriceAverage).mul(wethAmount).decode144();
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;

import "./FullMath.sol";


/************************************************************************************************
From https://github.com/Uniswap/uniswap-lib/blob/master/contracts/libraries/FixedPoint.sol

Copied from the github repository at commit hash 9642a0705fdaf36b477354a4167a8cd765250860.

Modifications:
- Removed `sqrt` function

Subject to the GPL-3.0 license
*************************************************************************************************/


// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
  using FullMath for uint256;

  // range: [0, 2**112 - 1]
  // resolution: 1 / 2**112
  struct uq112x112 {
    uint224 _x;
  }

  // range: [0, 2**144 - 1]
  // resolution: 1 / 2**112
  struct uq144x112 {
    uint _x;
  }

  uint8 private constant RESOLUTION = 112;
  uint private constant Q112 = uint(1) << RESOLUTION;
  uint private constant Q224 = Q112 << RESOLUTION;

  // encode a uint112 as a UQ112x112
  function encode(uint112 x) internal pure returns (uq112x112 memory) {
    return uq112x112(uint224(x) << RESOLUTION);
  }

  // encodes a uint144 as a UQ144x112
  function encode144(uint144 x) internal pure returns (uq144x112 memory) {
    return uq144x112(uint256(x) << RESOLUTION);
  }

  // divide a UQ112x112 by a uint112, returning a UQ112x112
  function div(uq112x112 memory self, uint112 x) internal pure returns (uq112x112 memory) {
    require(x != 0, "FixedPoint: DIV_BY_ZERO");
    return uq112x112(self._x / uint224(x));
  }

  // multiply a UQ112x112 by a uint, returning a UQ144x112
  // reverts on overflow
  function mul(uq112x112 memory self, uint y) internal pure returns (uq144x112 memory) {
    uint z;
    require(
      y == 0 || (z = uint(self._x) * y) / y == uint(self._x),
      "FixedPoint: MULTIPLICATION_OVERFLOW"
    );
    return uq144x112(z);
  }

  // multiply a UQ112x112 by a UQ112x112, returning a UQ112x112
  // reverts on overflow
  function mul(uq112x112 memory self, uq112x112 memory y) internal pure returns (uq112x112 memory) {
    uint224 z = uint224(uint256(self._x).mulDiv(y._x, Q112));
    return uq112x112(z);
  }

  // returns a UQ112x112 which represents the ratio of the numerator to the denominator
  // equivalent to encode(numerator).div(denominator)
  function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
    require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
    return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
  }

  // decode a UQ112x112 into a uint112 by truncating after the radix point
  function decode(uq112x112 memory self) internal pure returns (uint112) {
    return uint112(self._x >> RESOLUTION);
  }

  // decode a UQ144x112 into a uint144 by truncating after the radix point
  function decode144(uq144x112 memory self) internal pure returns (uint144) {
    return uint144(self._x >> RESOLUTION);
  }

  // take the reciprocal of a UQ112x112
  function reciprocal(uq112x112 memory self) internal pure returns (uq112x112 memory) {
    require(self._x != 0, "FixedPoint: ZERO_RECIPROCAL");
    return uq112x112(uint224(Q224 / self._x));
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
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;

/* ==========  Internal Interfaces  ========== */
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

/* ==========  Internal Libraries  ========== */
import "./FixedPoint.sol";


/************************************************************************************************
Originally from https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/libraries/UniswapV2OracleLibrary.sol

This source code has been modified from the original, which was copied from the github repository
at commit hash 6d03bede0a97c72323fa1c379ed3fdf7231d0b26.

Subject to the GPL-3.0 license
*************************************************************************************************/


// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
  using FixedPoint for *;

  // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
  function currentBlockTimestamp() internal view returns (uint32) {
    return uint32(block.timestamp % 2**32);
  }

  // produces the cumulative prices using counterfactuals to save gas and avoid a call to sync.
  function currentCumulativePrices(address pair)
    internal
    view
    returns (
      uint256 price0Cumulative,
      uint256 price1Cumulative,
      uint32 blockTimestamp
    )
  {
    blockTimestamp = currentBlockTimestamp();
    price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
    price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

    // if time has elapsed since the last update on the pair, mock the accumulated price values
    (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    ) = IUniswapV2Pair(pair).getReserves();
    require(
      reserve0 != 0 && reserve1 != 0,
      "UniswapV2OracleLibrary::currentCumulativePrices: Pair has no reserves."
    );
    if (blockTimestampLast != blockTimestamp) {
      // subtraction overflow is desired
      uint32 timeElapsed = blockTimestamp - blockTimestampLast;
      // addition overflow is desired
      // counterfactual
      price0Cumulative += (
        uint256(FixedPoint.fraction(reserve1, reserve0)._x) *
        timeElapsed
      );
      // counterfactual
      price1Cumulative += (
        uint256(FixedPoint.fraction(reserve0, reserve1)._x) *
        timeElapsed
      );
    }
  }

  // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
  // only gets the first price
  function currentCumulativePrice0(address pair)
    internal
    view
    returns (uint256 price0Cumulative, uint32 blockTimestamp)
  {
    blockTimestamp = currentBlockTimestamp();
    price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();

    // if time has elapsed since the last update on the pair, mock the accumulated price values
    (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    ) = IUniswapV2Pair(pair).getReserves();
    require(
      reserve0 != 0 && reserve1 != 0,
      "UniswapV2OracleLibrary::currentCumulativePrice0: Pair has no reserves."
    );
    if (blockTimestampLast != blockTimestamp) {
      // subtraction overflow is desired
      uint32 timeElapsed = blockTimestamp - blockTimestampLast;
      // addition overflow is desired
      // counterfactual
      price0Cumulative += (
        uint256(FixedPoint.fraction(reserve1, reserve0)._x) *
        timeElapsed
      );
    }
  }

  // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
  // only gets the second price
  function currentCumulativePrice1(address pair)
    internal
    view
    returns (uint256 price1Cumulative, uint32 blockTimestamp)
  {
    blockTimestamp = currentBlockTimestamp();
    price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

    // if time has elapsed since the last update on the pair, mock the accumulated price values
    (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    ) = IUniswapV2Pair(pair).getReserves();
    require(
      reserve0 != 0 && reserve1 != 0,
      "UniswapV2OracleLibrary::currentCumulativePrice1: Pair has no reserves."
    );
    if (blockTimestampLast != blockTimestamp) {
      // subtraction overflow is desired
      uint32 timeElapsed = blockTimestamp - blockTimestampLast;
      // addition overflow is desired
      // counterfactual
      price1Cumulative += (
        uint256(FixedPoint.fraction(reserve0, reserve1)._x) *
        timeElapsed
      );
    }
  }

  function computeAveragePrice(
    uint224 priceCumulativeStart,
    uint224 priceCumulativeEnd,
    uint32 timeElapsed
  ) internal pure returns (FixedPoint.uq112x112 memory priceAverage) {
    // overflow is desired.
    priceAverage = FixedPoint.uq112x112(
      uint224((priceCumulativeEnd - priceCumulativeStart) / timeElapsed)
    );
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;

/************************************************************************************************
Originally from https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol

This source code has been modified from the original, which was copied from the github repository
at commit hash 87edfdcaf49ccc52591502993db4c8c08ea9eec0.

Subject to the GPL-3.0 license
*************************************************************************************************/


library UniswapV2Library {
  // returns sorted token addresses, used to handle return values from pairs sorted in this order
  function sortTokens(address tokenA, address tokenB)
    internal
    pure
    returns (address token0, address token1)
  {
    require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
  }

  function calculatePair(
    address factory,
    address token0,
    address token1
  ) internal pure returns (address pair) {
    pair = address(
      uint256(
        keccak256(
          abi.encodePacked(
            hex"ff",
            factory,
            keccak256(abi.encodePacked(token0, token1)),
            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
          )
        )
      )
    );
  }

  // calculates the CREATE2 address for a pair without making any external calls
  function pairFor(
    address factory,
    address tokenA,
    address tokenB
  ) internal pure returns (address pair) {
    (address token0, address token1) = sortTokens(tokenA, tokenB);
    pair = calculatePair(factory, token0, token1);
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";

/* ==========  Internal Libraries  ========== */
import "./lib/PriceLibrary.sol";
import "./lib/FixedPoint.sol";

/* ==========  Internal Inheritance  ========== */
import "./interfaces/IIndexedUniswapV2Oracle.sol";


contract OracleFallthrough is Ownable {
  using PriceLibrary for address;
  using PriceLibrary for PriceLibrary.TwoWayAveragePrice;
  using FixedPoint for FixedPoint.uq112x112;
  using FixedPoint for FixedPoint.uq144x112;

  IIndexedUniswapV2Oracle public immutable ethOracle;
  IIndexedUniswapV2Oracle public immutable maticOracle;
  address public immutable weth;
  address public immutable wmatic;

  mapping (address => bool) public useMatic;

  constructor(
    IIndexedUniswapV2Oracle _ethOracle,
    IIndexedUniswapV2Oracle _maticOracle,
    address _weth,
    address _wmatic
  ) public Ownable() {
    ethOracle = _ethOracle;
    maticOracle = _maticOracle;
    weth = _weth;
    wmatic = _wmatic;
  }

/* ==========  Mutative Functions  ========== */

  function setUseMatic(address token, bool _useMatic) external onlyOwner {
    require(token != wmatic && token != weth, "OracleFallthrough::setUseMatic: Can not set useMatic for weth or matic.");
    useMatic[token] = _useMatic;
  }

  function setUseMaticMultiple(address[] calldata tokens, bool[] calldata useMatics) external onlyOwner {
    uint256 len = tokens.length;
    require(useMatics.length == len, "OracleFallthrough::setUseMaticMultiple: Array lengths do not match.");
    for (uint256 i; i < len; i++) {
      address token = tokens[i];
      require(token != wmatic && token != weth, "OracleFallthrough::setUseMaticMultiple: Can not set useMatic for weth or matic.");
      useMatic[token] = useMatics[i];
    }
  }

  function updatePrice(address token) public returns (bool) {
    (bool didUpdate, bool usedMatic) = _updatePrice(token);
    if (usedMatic) _updateMaticPrice();
    return didUpdate;
  }

  function updatePrices(address[] calldata tokens) external returns (bool[] memory) {
    uint256 len = tokens.length;
    bool[] memory didUpdates = new bool[](len);
    bool anyMatic;
    for (uint256 i; i < len; i++) {
      bool usedMatic;
      (didUpdates[i], usedMatic) = _updatePrice(tokens[i]);
      anyMatic = anyMatic || usedMatic;
    }
    if (anyMatic) _updateMaticPrice();
    return didUpdates;
  }

/* ==========  Price Update Queries  ========== */

  function canUpdatePrice(address token) public view returns (bool) {
    return (useMatic[token] ? maticOracle : ethOracle).canUpdatePrice(token);
  }

  function canUpdatePrices(address[] calldata tokens) external view returns (bool[] memory) {
    uint256 len = tokens.length;
    bool[] memory canUpdates = new bool[](len);
    for (uint256 i; i < len; i++) canUpdates[i] = canUpdatePrice(tokens[i]);
  }

/* ==========  Price Queries: Singular  ========== */

  function computeTwoWayAveragePrice(
    address token,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  )
    external
    view
    returns (PriceLibrary.TwoWayAveragePrice memory)
  {
    return _getTwoWayPrice(token, minTimeElapsed, maxTimeElapsed);
  }

  function computeAverageTokenPrice(
    address token,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  )
    external
    view
    returns (FixedPoint.uq112x112 memory priceAverage)
  {
    return _getTokenPrice(token, minTimeElapsed, maxTimeElapsed);
  }

  function computeAverageEthPrice(
    address token,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  )
    external
    view
    returns (FixedPoint.uq112x112 memory priceAverage)
  {
    return _getEthPrice(token, minTimeElapsed, maxTimeElapsed);
  }

/* ==========  Price Queries: Multiple  ========== */

  function computeTwoWayAveragePrices(
    address[] calldata tokens,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  )
    external
    view
    returns (PriceLibrary.TwoWayAveragePrice[] memory prices)
  {
    uint256 len = tokens.length;
    prices = new PriceLibrary.TwoWayAveragePrice[](len);
    for (uint256 i = 0; i < len; i++) {
      prices[i] = _getTwoWayPrice(tokens[i], minTimeElapsed, maxTimeElapsed);
    }
  }

  function computeAverageTokenPrices(
    address[] calldata tokens,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  )
    external
    view
    returns (FixedPoint.uq112x112[] memory averagePrices)
  {
    uint256 len = tokens.length;
    averagePrices = new FixedPoint.uq112x112[](len);
    for (uint256 i = 0; i < len; i++) {
      averagePrices[i] = _getTokenPrice(tokens[i], minTimeElapsed, maxTimeElapsed);
    }
  }

  function computeAverageEthPrices(
    address[] calldata tokens,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  )
    external
    view
    returns (FixedPoint.uq112x112[] memory averagePrices)
  {
    uint256 len = tokens.length;
    averagePrices = new FixedPoint.uq112x112[](len);
    for (uint256 i = 0; i < len; i++) {
      averagePrices[i] = _getEthPrice(tokens[i], minTimeElapsed, maxTimeElapsed);
    }
  }

/* ==========  Value Queries: Singular  ========== */

  function computeAverageEthForTokens(
    address token,
    uint256 tokenAmount,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  )
    external
    view
    returns (uint144 /* averageValueInWETH */)
  {
    FixedPoint.uq112x112 memory tokenPrice = _getTokenPrice(token, minTimeElapsed, maxTimeElapsed);
    return tokenPrice.mul(tokenAmount).decode144();
  }

  function computeAverageTokensForEth(
    address token,
    uint256 wethAmount,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  )
    external
    view
    returns (uint144 /* averageValueInToken */)
  {
    FixedPoint.uq112x112 memory ethPrice = _getEthPrice(token, minTimeElapsed, maxTimeElapsed);
    return ethPrice.mul(wethAmount).decode144();
  }

/* ==========  Value Queries: Multiple  ========== */

  function computeAverageEthForTokens(
    address[] calldata tokens,
    uint256[] calldata tokenAmounts,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  )
    external
    view
    returns (uint144[] memory averageValuesInWETH)
  {
    uint256 len = tokens.length;
    require(
      tokenAmounts.length == len,
      "OracleFallthrough::computeAverageEthForTokens: Tokens and amounts have different lengths."
    );
    averageValuesInWETH = new uint144[](len);
    for (uint256 i = 0; i < len; i++) {
      averageValuesInWETH[i] = _getTokenPrice(
        tokens[i],
        minTimeElapsed,
        maxTimeElapsed
      ).mul(tokenAmounts[i]).decode144();
    }
  }

  function computeAverageTokensForEth(
    address[] calldata tokens,
    uint256[] calldata wethAmounts,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  )
    external
    view
    returns (uint144[] memory averageValuesInWETH)
  {
    uint256 len = tokens.length;
    require(
      wethAmounts.length == len,
      "OracleFallthrough::computeAverageTokensForEth: Tokens and amounts have different lengths."
    );
    averageValuesInWETH = new uint144[](len);
    for (uint256 i = 0; i < len; i++) {
      averageValuesInWETH[i] = _getEthPrice(
        tokens[i],
        minTimeElapsed,
        maxTimeElapsed
      ).mul(wethAmounts[i]).decode144();
    }
  }


/* ==========  Internal Functions  ========== */

  function _updateMaticPrice() internal {
    ethOracle.updatePrice(wmatic);
  }

  function _getTwoWayPrice(
    address token,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  )
    internal
    view
    returns (PriceLibrary.TwoWayAveragePrice memory)
  {
    if (token == weth) {
      return PriceLibrary.TwoWayAveragePrice(
        FixedPoint.encode(1)._x,
        FixedPoint.encode(1)._x
      );
    }
    if (useMatic[token]) {
      PriceLibrary.TwoWayAveragePrice memory tokenPrice = maticOracle.computeTwoWayAveragePrice(token, minTimeElapsed, maxTimeElapsed);
      PriceLibrary.TwoWayAveragePrice memory maticPrice = ethOracle.computeTwoWayAveragePrice(wmatic, minTimeElapsed, maxTimeElapsed);
      tokenPrice.priceAverage = FixedPoint.uq112x112(tokenPrice.priceAverage).mul(
        FixedPoint.uq112x112(maticPrice.priceAverage)
      )._x;
      tokenPrice.ethPriceAverage = FixedPoint.uq112x112(tokenPrice.ethPriceAverage).mul(
        FixedPoint.uq112x112(maticPrice.ethPriceAverage)
      )._x;
      return tokenPrice;
    } else {
      return ethOracle.computeTwoWayAveragePrice(token, minTimeElapsed, maxTimeElapsed);
    }
  }

  function _getTokenPrice(
    address token,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  )
    internal
    view
    returns (FixedPoint.uq112x112 memory)
  {
    if (token == weth) {
      return FixedPoint.fraction(1, 1);
    }
    if (useMatic[token]) {
      FixedPoint.uq112x112 memory tokenPrice = maticOracle.computeAverageTokenPrice(token, minTimeElapsed, maxTimeElapsed);
      FixedPoint.uq112x112 memory maticPrice = ethOracle.computeAverageTokenPrice(wmatic, minTimeElapsed, maxTimeElapsed);
      return tokenPrice.mul(maticPrice);
    } else {
      return ethOracle.computeAverageTokenPrice(token, minTimeElapsed, maxTimeElapsed);
    }
  }

  function _getEthPrice(
    address token,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  )
    internal
    view
    returns (FixedPoint.uq112x112 memory)
  {
    if (token == weth) {
      return FixedPoint.fraction(1, 1);
    }
    if (useMatic[token]) {
      FixedPoint.uq112x112 memory maticPriceToken = maticOracle.computeAverageEthPrice(token, minTimeElapsed, maxTimeElapsed);
      FixedPoint.uq112x112 memory ethPriceMatic = ethOracle.computeAverageEthPrice(wmatic, minTimeElapsed, maxTimeElapsed);
      return maticPriceToken.mul(ethPriceMatic);
    } else {
      return ethOracle.computeAverageEthPrice(token, minTimeElapsed, maxTimeElapsed);
    }
  }

  function _updatePrice(address token) internal returns (bool didUpdate, bool usedMatic) {
    usedMatic = useMatic[token];
    didUpdate = (usedMatic ? maticOracle : ethOracle).updatePrice(token);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}