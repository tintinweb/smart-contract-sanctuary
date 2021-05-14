// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/lib/contracts/libraries/FixedPoint.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../external-lib/UniswapV2Library.sol";
import "../external-lib/UniswapV2OracleLibrary.sol";

import "./interfaces/ITwap.sol";

// As these are "Time"-Weighted Average Price contracts, they necessarily rely on time.
// solhint-disable not-rely-on-time

/**
 * @title A sliding window for AMMs
 * @notice Uses observations collected over a window to provide moving price averages in the past
 * @dev This is a singleton TWAP that only needs to be deployed once per desired parameters. `windowSize` has a precision of `windowSize / granularity`
 * Errors:
 * MissingPastObsr   - We do not have suffient past observations.
 * UnexpectedElapsed - We have an unexpected time elapsed.
 * EarlyUpdate       - Tried to update the TWAP before the period has elapsed.
 * InvalidToken      - Cannot consult an invalid token pair.
 */
contract Twap is ITwap {
  using FixedPoint for *;
  using SafeMath for uint256;

  struct Observation {
    uint256 timestamp;
    uint256 price0Cumulative;
    uint256 price1Cumulative;
  }

  /* ========== IMMUTABLE VARIABLES ========== */

  /// @notice the Uniswap Factory contract for tracking exchanges
  address public immutable factory;

  /// @notice The desired amount of time over which the moving average should be computed, e.g. 24 hours
  uint256 public immutable windowSize;

  /// @notice The number of observations stored for each pair, i.e. how many price observations are stored for the window
  /// @dev As granularity increases from, more frequent updates are needed; but precision increases [`windowSize - (windowSize / granularity) * 2`, `windowSize`]
  uint8 public immutable granularity;

  /// @dev Redundant with `granularity` and `windowSize`, but has gas savings & easy read
  uint256 public immutable periodSize;

  /* ========== STATE VARIABLES ========== */

  /// @notice Mapping from pair address to a list of price observations of that pair
  mapping(address => Observation[]) public pairObservations;

  /* ========== EVENTS ========== */

  event NewObservation(
    uint256 timestamp,
    uint256 price0Cumulative,
    uint256 price1Cumulative
  );

  /* ========== CONSTRUCTOR ========== */

  /**
   * @notice Construct a new Sliding Window TWAP
   * @param factory_ The AMM factory
   * @param windowSize_ The window size for this TWAP
   * @param granularity_ The granularity required for the TWAP
   */
  constructor(
    address factory_,
    uint256 windowSize_,
    uint8 granularity_
  ) {
    require(factory_ != address(0), "Twap/InvalidFactory");
    require(granularity_ > 1, "Twap/Granularity");
    require(
      (periodSize = windowSize_ / granularity_) * granularity_ == windowSize_,
      "Twap/WindowSize"
    );
    factory = factory_;
    windowSize = windowSize_;
    granularity = granularity_;
  }

  /* ========== PURE ========== */

  /**
   * @notice Given the cumulative prices of the start and end of a period, and the length of the period, compute the average price in terms of the amount in
   * @param priceCumulativeStart the cumulative price for the start of the period
   * @param priceCumulativeEnd the cumulative price for the end of the period
   * @param timeElapsed the time from now to the first observation
   * @param amountIn the amount of tokens in
   * @return amountOut amount out received for the amount in
   */
  function _computeAmountOut(
    uint256 priceCumulativeStart,
    uint256 priceCumulativeEnd,
    uint256 timeElapsed,
    uint256 amountIn
  ) private pure returns (uint256 amountOut) {
    // overflow is desired.
    FixedPoint.uq112x112 memory priceAverage =
      FixedPoint.uq112x112(
        uint224((priceCumulativeEnd - priceCumulativeStart) / timeElapsed)
      );
    amountOut = priceAverage.mul(amountIn).decode144();
  }

  /* ========== VIEWS ========== */

  /**
   * @notice Calculates the index of the observation for the given `timestamp`
   * @param timestamp the observation for the timestamp
   * @return index The index of the observation
   */
  function observationIndexOf(uint256 timestamp)
    public
    view
    returns (uint8 index)
  {
    uint256 epochPeriod = timestamp / periodSize;
    return uint8(epochPeriod % granularity);
  }

  /// @inheritdoc ITwap
  function updateable(address tokenA, address tokenB)
    external
    view
    override(ITwap)
    returns (bool)
  {
    address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);

    uint8 observationIndex = observationIndexOf(block.timestamp);
    Observation storage observation = pairObservations[pair][observationIndex];

    // We only want to commit updates once per period (i.e. windowSize / granularity).
    uint256 timeElapsed = block.timestamp - observation.timestamp;

    return timeElapsed > periodSize;
  }

  /// @inheritdoc ITwap
  function consult(
    address tokenIn,
    uint256 amountIn,
    address tokenOut
  ) external view override(ITwap) returns (uint256 amountOut) {
    address pair = UniswapV2Library.pairFor(factory, tokenIn, tokenOut);
    Observation storage firstObservation = _getFirstObservationInWindow(pair);

    uint256 timeElapsed = block.timestamp - firstObservation.timestamp;
    require(timeElapsed <= windowSize, "Twap/MissingPastObsr");
    require(
      timeElapsed >= windowSize - periodSize * 2,
      "Twap/UnexpectedElapsed"
    );

    (uint256 price0Cumulative, uint256 price1Cumulative, ) =
      UniswapV2OracleLibrary.currentCumulativePrices(pair);
    (address token0, address token1) =
      UniswapV2Library.sortTokens(tokenIn, tokenOut);

    if (token0 == tokenIn) {
      return
        _computeAmountOut(
          firstObservation.price0Cumulative,
          price0Cumulative,
          timeElapsed,
          amountIn
        );
    }

    require(token1 == tokenIn, "Twap/InvalidToken");

    return
      _computeAmountOut(
        firstObservation.price1Cumulative,
        price1Cumulative,
        timeElapsed,
        amountIn
      );
  }

  /**
   * @notice Observation from the oldest epoch (at the beginning of the window) relative to the current time
   * @param pair the Uniswap pair address
   * @return firstObservation The observation from the oldest epoch relative to current time.
   */
  function _getFirstObservationInWindow(address pair)
    private
    view
    returns (Observation storage firstObservation)
  {
    uint8 observationIndex = observationIndexOf(block.timestamp);
    // No overflow issues; if observationIndex + 1 overflows, result is still zero.
    uint8 firstObservationIndex = (observationIndex + 1) % granularity;
    firstObservation = pairObservations[pair][firstObservationIndex];
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  /// @inheritdoc ITwap
  function update(address tokenA, address tokenB)
    external
    override(ITwap)
    returns (bool)
  {
    address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);

    // Populate the array with empty observations for the first call.
    for (uint256 i = pairObservations[pair].length; i < granularity; i++) {
      pairObservations[pair].push();
    }

    // Get the observation for the current period.
    uint8 observationIndex = observationIndexOf(block.timestamp);
    Observation storage observation = pairObservations[pair][observationIndex];

    // We only want to commit updates once per period (i.e. windowSize / granularity).
    uint256 timeElapsed = block.timestamp - observation.timestamp;

    if (timeElapsed <= periodSize) {
      // Skip update as we're in the same observation slot.
      return false;
    }

    (uint256 price0Cumulative, uint256 price1Cumulative, ) =
      UniswapV2OracleLibrary.currentCumulativePrices(pair);
    observation.timestamp = block.timestamp;
    observation.price0Cumulative = price0Cumulative;
    observation.price1Cumulative = price1Cumulative;

    emit NewObservation(
      observation.timestamp,
      observation.price0Cumulative,
      observation.price1Cumulative
    );

    return true;
  }
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
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

pragma solidity >=0.4.0;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
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
        require(x != 0, 'FixedPoint: DIV_BY_ZERO');
        return uq112x112(self._x / uint224(x));
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint y) internal pure returns (uq144x112 memory) {
        uint z;
        require(y == 0 || (z = uint(self._x) * y) / y == uint(self._x), "FixedPoint: MULTIPLICATION_OVERFLOW");
        return uq144x112(z);
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

pragma solidity >=0.6.0 <0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

library UniswapV2Library {
  using SafeMath for uint256;

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

  // calculates the CREATE2 address for a pair without making any external calls
  function pairFor(
    address factory,
    address tokenA,
    address tokenB
  ) internal pure returns (address pair) {
    (address token0, address token1) = sortTokens(tokenA, tokenB);
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

  // fetches and sorts the reserves for a pair
  function getReserves(
    address factory,
    address tokenA,
    address tokenB
  ) internal view returns (uint256 reserveA, uint256 reserveB) {
    (address token0, ) = sortTokens(tokenA, tokenB);
    (uint256 reserve0, uint256 reserve1, ) =
      IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
    (reserveA, reserveB) = tokenA == token0
      ? (reserve0, reserve1)
      : (reserve1, reserve0);
  }

  // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) internal pure returns (uint256 amountB) {
    require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
    require(
      reserveA > 0 && reserveB > 0,
      "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
    );
    amountB = amountA.mul(reserveB) / reserveA;
  }

  // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) internal pure returns (uint256 amountOut) {
    require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
    require(
      reserveIn > 0 && reserveOut > 0,
      "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
    );
    uint256 amountInWithFee = amountIn.mul(997);
    uint256 numerator = amountInWithFee.mul(reserveOut);
    uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
    amountOut = numerator / denominator;
  }

  // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) internal pure returns (uint256 amountIn) {
    require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
    require(
      reserveIn > 0 && reserveOut > 0,
      "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
    );
    uint256 numerator = reserveIn.mul(amountOut).mul(1000);
    uint256 denominator = reserveOut.sub(amountOut).mul(997);
    amountIn = (numerator / denominator).add(1);
  }

  // performs chained getAmountOut calculations on any number of pairs
  function getAmountsOut(
    address factory,
    uint256 amountIn,
    address[] memory path
  ) internal view returns (uint256[] memory amounts) {
    require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
    amounts = new uint256[](path.length);
    amounts[0] = amountIn;
    for (uint256 i; i < path.length - 1; i++) {
      (uint256 reserveIn, uint256 reserveOut) =
        getReserves(factory, path[i], path[i + 1]);
      amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
    }
  }

  // performs chained getAmountIn calculations on any number of pairs
  function getAmountsIn(
    address factory,
    uint256 amountOut,
    address[] memory path
  ) internal view returns (uint256[] memory amounts) {
    require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
    amounts = new uint256[](path.length);
    amounts[amounts.length - 1] = amountOut;
    for (uint256 i = path.length - 1; i > 0; i--) {
      (uint256 reserveIn, uint256 reserveOut) =
        getReserves(factory, path[i - 1], path[i]);
      amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/lib/contracts/libraries/FixedPoint.sol";

// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
  using FixedPoint for *;

  // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
  function currentBlockTimestamp() internal view returns (uint32) {
    return uint32(block.timestamp % 2**32);
  }

  // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
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
    (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) =
      IUniswapV2Pair(pair).getReserves();
    if (blockTimestampLast != blockTimestamp) {
      // subtraction overflow is desired
      uint32 timeElapsed = blockTimestamp - blockTimestampLast;
      // addition overflow is desired
      // counterfactual
      price0Cumulative +=
        uint256(FixedPoint.fraction(reserve1, reserve0)._x) *
        timeElapsed;
      // counterfactual
      price1Cumulative +=
        uint256(FixedPoint.fraction(reserve0, reserve1)._x) *
        timeElapsed;
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

interface ITwap {
  /**
   * @notice Returns the amount out corresponding to the amount in for a given token using the moving average over time range [`block.timestamp` - [`windowSize`, `windowSize - periodSize * 2`], `block.timestamp`].
   * E.g. with a windowSize = 24hrs, periodSize = 6hrs.
   * [24hrs ago to 12hrs ago, now]
   * @dev Update must have been called for the bucket corresponding to the timestamp `now - windowSize`
   * @param tokenIn the address of the token we are offering
   * @param amountIn the quantity of tokens we are pricing
   * @param tokenOut the address of the token we want
   * @return amountOut the `tokenOut` amount corresponding to the `amountIn` for `tokenIn` over the time range
   */
  function consult(
    address tokenIn,
    uint256 amountIn,
    address tokenOut
  ) external view returns (uint256 amountOut);

  /**
   * @notice Checks if a particular pair can be updated
   * @param tokenA Token A of pair (any order)
   * @param tokenB Token B of pair (any order)
   * @return If an update call will succeed
   */
  function updateable(address tokenA, address tokenB)
    external
    view
    returns (bool);

  /**
   * @notice Update the cumulative price for the observation at the current timestamp. Each observation is updated at most once per epoch period.
   * @param tokenA the first token to create pair from
   * @param tokenB the second token to create pair from
   * @return if the observation was updated or not.
   */
  function update(address tokenA, address tokenB) external returns (bool);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 999999
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
  "metadata": {
    "bytecodeHash": "none",
    "useLiteralContent": true
  },
  "libraries": {}
}