// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

/* ==========  Internal Libraries  ========== */
import "../lib/PriceLibrary.sol";
import "../lib/FixedPoint.sol";
import "../lib/BisharesPriceMapLibrary.sol";

/* ==========  Internal Inheritance  ========== */
import "../interfaces/IBisharesUniswapV2Oracle.sol";


contract BisharesUniswapV2Oracle is IBisharesUniswapV2Oracle {
  
  using PriceLibrary for address;
  using PriceLibrary for PriceLibrary.PriceObservation;
  using PriceLibrary for PriceLibrary.TwoWayAveragePrice;
  using FixedPoint for FixedPoint.uq112x112;
  using FixedPoint for FixedPoint.uq144x112;
  using BisharesPriceMapLibrary for BisharesPriceMapLibrary.BisharesPriceMap;


/* ==========  Immutables  ========== */

  address internal immutable _uniswapFactory;
  address internal immutable _weth;

/* ==========  Storage  ========== */

  // Price observations for tokens indexed by hour.
  mapping(address => BisharesPriceMapLibrary.BisharesPriceMap) internal _tokenPriceMaps;

/* ==========  Modifiers  ========== */

  modifier validMinMax(uint256 minTimeElapsed, uint256 maxTimeElapsed) {
    require(
      maxTimeElapsed >= minTimeElapsed,
      "BisharesUniswapV2Oracle::validMinMax: Minimum age can not be higher than maximum."
    );
    _;
  }

/* ==========  Constructor  ========== */

  constructor(address uniswapFactory, address weth) public {
    _uniswapFactory = uniswapFactory;
    _weth = weth;
  }

/* ==========  Mutative Functions  ========== */

  /**
   * @dev Attempts to update the price of `token` and returns a boolean
   * indicating whether it was updated.
   *
   * Note: The price can be updated if there is no observation for the current hour
   * and at least 30 minutes have passed since the last observation.
   */
  function updatePrice(address token) public override returns (bool/* didUpdatePrice */) {
    if (token == _weth) return true;
    PriceLibrary.PriceObservation memory observation = _uniswapFactory.observeTwoWayPrice(token, _weth);
    return _tokenPriceMaps[token].writePriceObservation(observation);
  }

  /**
   * @dev Attempts to update the price of each token in `tokens` and returns a boolean
   * array indicating which tokens had their prices updated.
   *
   * Note: The price can be updated if there is no observation for the current hour
   * and at least 30 minutes have passed since the last observation.
   */
  function updatePrices(address[] calldata tokens)
    external
    override
    returns (bool[] memory pricesUpdated)
  {
    uint256 len = tokens.length;
    pricesUpdated = new bool[](len);
    for (uint256 i = 0; i < len; i++) {
      pricesUpdated[i] = updatePrice(tokens[i]);
    }
  }

/* ==========  Meta Price Queries  ========== */

  /**
   * @dev Returns a boolean indicating whether a price was recorded for `token` at `priceKey`.
   *
   * @param token Token to check if the oracle has a price for
   * @param priceKey Index of the hour to check
   */
  function hasPriceObservationInWindow(address token, uint256 priceKey)
    external view override returns (bool)
  {
    return _tokenPriceMaps[token].hasPriceInWindow(priceKey);
  }


  /**
   * @dev Returns the price observation for `token` recorded in `priceKey`.
   * Reverts if no prices have been recorded for that key.
   *
   * @param token Token to retrieve a price for
   * @param priceKey Index of the hour to query
   */
  function getPriceObservationInWindow(address token, uint256 priceKey)
    external
    view
    override
    returns (PriceLibrary.PriceObservation memory observation)
  {
    observation = _tokenPriceMaps[token].getPriceInWindow(priceKey);
    require(
      observation.timestamp != 0,
      "BisharesUniswapV2Oracle::getPriceObservationInWindow: No price observed in given hour."
    );
  }

  /**
   * @dev Returns all price observations for `token` recorded between `timeFrom` and `timeTo`.
   */
  function getPriceObservationsInRange(address token, uint256 timeFrom, uint256 timeTo)
    external
    view
    override
    returns (PriceLibrary.PriceObservation[] memory prices)
  {
    prices = _tokenPriceMaps[token].getPriceObservationsInRange(timeFrom, timeTo);
  }

/* ==========  Price Update Queries  ========== */

  /**
   * @dev Returns a boolean indicating whether the price of `token` can be updated.
   *
   * Note: The price can be updated if there is no observation for the current hour
   * and at least 30 minutes have passed since the last observation.
   */
  function canUpdatePrice(address token) external view override returns (bool/* canUpdatePrice */) {
    if (!_uniswapFactory.pairInitialized(token, _weth)) return false;
    return _tokenPriceMaps[token].canUpdatePrice(uint32(block.timestamp));
  }

  /**
   * @dev Returns a boolean array indicating whether the price of each token in
   * `tokens` can be updated.
   *
   * Note: The price can be updated if there is no observation for the current hour
   * and at least 30 minutes have passed since the last observation.
   */
  function canUpdatePrices(address[] calldata tokens) external view override returns (bool[] memory canUpdateArr) {
    uint256 len = tokens.length;
    canUpdateArr = new bool[](len);
    for (uint256 i = 0; i < len; i++) {
      address token = tokens[i];
      bool timeAllowed = _tokenPriceMaps[token].canUpdatePrice(uint32(block.timestamp));
      canUpdateArr[i] = timeAllowed && _uniswapFactory.pairInitialized(token, _weth);
    }
  }

/* ==========  Price Queries: Singular  ========== */

  /**
   * @dev Returns the TwoWayAveragePrice struct representing the average price of
   * weth in terms of `token` and the average price of `token` in terms of weth.
   *
   * Computes the time-weighted average price of weth in terms of `token` and the price
   * of `token` in terms of weth by getting the current prices from Uniswap and searching
   * for a historical price which is between `minTimeElapsed` and `maxTimeElapsed` seconds old.
   *
   * Note: `maxTimeElapsed` is only accurate to the nearest hour (rounded down) unless
   * it is less than one hour.
   * Note: `minTimeElapsed` is only accurate to the nearest hour (rounded up) unless
   * it is less than one hour.
   */
  function computeTwoWayAveragePrice(
    address token,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  )
    external
    view
    override
    validMinMax(minTimeElapsed, maxTimeElapsed)
    returns (PriceLibrary.TwoWayAveragePrice memory)
  {
    return _getTwoWayPrice(token, minTimeElapsed, maxTimeElapsed);
  }

  /**
   * @dev Returns the UQ112x112 struct representing the average price of
   * `token` in terms of weth.
   *
   * Computes the time-weighted average price of `token` in terms of weth by getting the
   * current price from Uniswap and searching for a historical price which is between
   * `minTimeElapsed` and `maxTimeElapsed` seconds old.
   *
   * Note: `maxTimeElapsed` is only accurate to the nearest hour (rounded down) unless
   * it is less than one hour.
   * Note: `minTimeElapsed` is only accurate to the nearest hour (rounded up) unless
   * it is less than one hour.
   */
  function computeAverageTokenPrice(
    address token,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  )
    external
    view
    override
    validMinMax(minTimeElapsed, maxTimeElapsed)
    returns (FixedPoint.uq112x112 memory priceAverage)
  {
    return _getTokenPrice(token, minTimeElapsed, maxTimeElapsed);
  }

  /**
   * @dev Returns the UQ112x112 struct representing the average price of
   * weth in terms of `token`.
   *
   * Computes the time-weighted average price of weth in terms of `token` by getting the
   * current price from Uniswap and searching for a historical price which is between
   * `minTimeElapsed` and `maxTimeElapsed` seconds old.
   *
   * Note: `maxTimeElapsed` is only accurate to the nearest hour (rounded down) unless
   * it is less than one hour.
   * Note: `minTimeElapsed` is only accurate to the nearest hour (rounded up) unless
   * it is less than one hour.
   */
  function computeAverageEthPrice(
    address token,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  )
    external
    view
    override
    validMinMax(minTimeElapsed, maxTimeElapsed)
    returns (FixedPoint.uq112x112 memory priceAverage)
  {
    return _getEthPrice(token, minTimeElapsed, maxTimeElapsed);
  }

/* ==========  Price Queries: Multiple  ========== */

  /**
   * @dev Returns the TwoWayAveragePrice structs representing the average price of
   * weth in terms of each token in `tokens` and the average price of each token
   * in terms of weth.
   *
   * Computes the time-weighted average price of weth in terms of each token and the price
   * of each token in terms of weth by getting the current prices from Uniswap and searching
   * for a historical price which is between `minTimeElapsed` and `maxTimeElapsed` seconds old.
   *
   * Note: `maxTimeElapsed` is only accurate to the nearest hour (rounded down) unless
   * it is less than one hour.
   * Note: `minTimeElapsed` is only accurate to the nearest hour (rounded up) unless
   * it is less than one hour.
   */
  function computeTwoWayAveragePrices(
    address[] calldata tokens,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  )
    external
    view
    override
    validMinMax(minTimeElapsed, maxTimeElapsed)
    returns (PriceLibrary.TwoWayAveragePrice[] memory prices)
  {
    uint256 len = tokens.length;
    prices = new PriceLibrary.TwoWayAveragePrice[](len);
    for (uint256 i = 0; i < len; i++) {
      prices[i] = _getTwoWayPrice(tokens[i], minTimeElapsed, maxTimeElapsed);
    }
  }

  /**
   * @dev Returns the UQ112x112 structs representing the average price of
   * each token in `tokens` in terms of weth.
   *
   * Computes the time-weighted average price of each token in terms of weth by getting
   * the current price from Uniswap and searching for a historical price which is between
   * `minTimeElapsed` and `maxTimeElapsed` seconds old.
   *
   * Note: `maxTimeElapsed` is only accurate to the nearest hour (rounded down) unless
   * it is less than one hour.
   * Note: `minTimeElapsed` is only accurate to the nearest hour (rounded up) unless
   * it is less than one hour.
   */
  function computeAverageTokenPrices(
    address[] calldata tokens,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  )
    external
    view
    override
    validMinMax(minTimeElapsed, maxTimeElapsed)
    returns (FixedPoint.uq112x112[] memory averagePrices)
  {
    uint256 len = tokens.length;
    averagePrices = new FixedPoint.uq112x112[](len);
    for (uint256 i = 0; i < len; i++) {
      averagePrices[i] = _getTokenPrice(tokens[i], minTimeElapsed, maxTimeElapsed);
    }
  }

  /**
   * @dev Returns the UQ112x112 structs representing the average price of
   * weth in terms of each token in `tokens`.
   *
   * Computes the time-weighted average price of weth in terms of each token by getting
   * the current price from Uniswap and searching for a historical price which is between
   * `minTimeElapsed` and `maxTimeElapsed` seconds old.
   *
   * Note: `maxTimeElapsed` is only accurate to the nearest hour (rounded down) unless
   * it is less than one hour.
   * Note: `minTimeElapsed` is only accurate to the nearest hour (rounded up) unless
   * it is less than one hour.
   */
  function computeAverageEthPrices(
    address[] calldata tokens,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  )
    external
    view
    override
    validMinMax(minTimeElapsed, maxTimeElapsed)
    returns (FixedPoint.uq112x112[] memory averagePrices)
  {
    uint256 len = tokens.length;
    averagePrices = new FixedPoint.uq112x112[](len);
    for (uint256 i = 0; i < len; i++) {
      averagePrices[i] = _getEthPrice(tokens[i], minTimeElapsed, maxTimeElapsed);
    }
  }

/* ==========  Value Queries: Singular  ========== */

  /**
   * @dev Compute the average value of `tokenAmount` ether in terms of weth.
   *
   * Computes the time-weighted average price of `token` in terms of weth by getting
   * the current price from Uniswap and searching for a historical price which is between
   * `minTimeElapsed` and `maxTimeElapsed` seconds old, then multiplies by `wethAmount`.
   *
   * Note: `maxTimeElapsed` is only accurate to the nearest hour (rounded down) unless
   * it is less than one hour.
   * Note: `minTimeElapsed` is only accurate to the nearest hour (rounded up) unless
   * it is less than one hour.
   */
  function computeAverageEthForTokens(
    address token,
    uint256 tokenAmount,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  )
    external
    view
    override
    validMinMax(minTimeElapsed, maxTimeElapsed)
    returns (uint144 /* averageValueInWETH */)
  {
    FixedPoint.uq112x112 memory tokenPrice = _getTokenPrice(token, minTimeElapsed, maxTimeElapsed);
    return tokenPrice.mul(tokenAmount).decode144();
  }

  /**
   * @dev Compute the average value of `wethAmount` ether in terms of `token`.
   *
   * Computes the time-weighted average price of weth in terms of the token by getting
   * the current price from Uniswap and searching for a historical price which is between
   * `minTimeElapsed` and `maxTimeElapsed` seconds old, then multiplies by `wethAmount`.
   *
   * Note: `maxTimeElapsed` is only accurate to the nearest hour (rounded down) unless
   * it is less than one hour.
   * Note: `minTimeElapsed` is only accurate to the nearest hour (rounded up) unless
   * it is less than one hour.
   */
  function computeAverageTokensForEth(
    address token,
    uint256 wethAmount,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  )
    external
    view
    override
    validMinMax(minTimeElapsed, maxTimeElapsed)
    returns (uint144 /* averageValueInToken */)
  {
    FixedPoint.uq112x112 memory ethPrice = _getEthPrice(token, minTimeElapsed, maxTimeElapsed);
    return ethPrice.mul(wethAmount).decode144();
  }

/* ==========  Value Queries: Multiple  ========== */

  /**
   * @dev Compute the average value of each amount of tokens in `tokenAmounts` in terms
   * of the corresponding token in `tokens`.
   *
   * Computes the time-weighted average price of each token in terms of weth by getting
   * the current price from Uniswap and searching for a historical price which is between
   * `minTimeElapsed` and `maxTimeElapsed` seconds old, then multiplies by the corresponding
   * amount in `tokenAmounts`.
   *
   * Note: `maxTimeElapsed` is only accurate to the nearest hour (rounded down) unless
   * it is less than one hour.
   * Note: `minTimeElapsed` is only accurate to the nearest hour (rounded up) unless
   * it is less than one hour.
   */
  function computeAverageEthForTokens(
    address[] calldata tokens,
    uint256[] calldata tokenAmounts,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  )
    external
    view
    override
    validMinMax(minTimeElapsed, maxTimeElapsed)
    returns (uint144[] memory averageValuesInWETH)
  {
    uint256 len = tokens.length;
    require(
      tokenAmounts.length == len,
      "BisharesUniswapV2Oracle::computeAverageEthForTokens: Tokens and amounts have different lengths."
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

  /**
   * @dev Compute the average value of each amount of ether in `wethAmounts` in terms
   * of the corresponding token in `tokens`.
   *
   * Computes the time-weighted average price of weth in terms of each token by getting
   * the current price from Uniswap and searching for a historical price which is between
   * `minTimeElapsed` and `maxTimeElapsed` seconds old, then multiplies by the corresponding
   * amount in `wethAmounts`.
   *
   * Note: `maxTimeElapsed` is only accurate to the nearest hour (rounded down) unless
   * it is less than one hour.
   * Note: `minTimeElapsed` is only accurate to the nearest hour (rounded up) unless
   * it is less than one hour.
   */
  function computeAverageTokensForEth(
    address[] calldata tokens,
    uint256[] calldata wethAmounts,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  )
    external
    view
    override
    validMinMax(minTimeElapsed, maxTimeElapsed)
    returns (uint144[] memory averageValuesInWETH)
  {
    uint256 len = tokens.length;
    require(
      wethAmounts.length == len,
      "BisharesUniswapV2Oracle::computeAverageTokensForEth: Tokens and amounts have different lengths."
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
  function _getTwoWayPrice(
    address token,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  )
    internal
    view
    returns (PriceLibrary.TwoWayAveragePrice memory)
  {
    if (token == _weth) {
      return PriceLibrary.TwoWayAveragePrice(
        FixedPoint.encode(1)._x,
        FixedPoint.encode(1)._x
      );
    }
    // Get the current cumulative price
    PriceLibrary.PriceObservation memory current = _uniswapFactory.observeTwoWayPrice(token, _weth);
    // Get the latest usable price
    (bool foundPrice, uint256 lastPriceKey) = _tokenPriceMaps[token].getLastPriceObservation(
      current.timestamp,
      minTimeElapsed,
      maxTimeElapsed
    );
    require(foundPrice, "BisharesUniswapV2Oracle::_getTwoWayPrice: No price found in provided range.");
    PriceLibrary.PriceObservation memory previous = _tokenPriceMaps[token].priceMap[lastPriceKey];
    return previous.computeTwoWayAveragePrice(current);
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
    if (token == _weth) {
      return FixedPoint.fraction(1, 1);
    }
    (uint32 timestamp, uint224 priceCumulativeEnd) = _uniswapFactory.observePrice(token, _weth);
    (bool foundPrice, uint256 lastPriceKey) = _tokenPriceMaps[token].getLastPriceObservation(
      timestamp,
      minTimeElapsed,
      maxTimeElapsed
    );
    require(foundPrice, "BisharesUniswapV2Oracle::_getTokenPrice: No price found in provided range.");
    PriceLibrary.PriceObservation storage previous = _tokenPriceMaps[token].priceMap[lastPriceKey];
    return PriceLibrary.computeAveragePrice(
      previous.timestamp,
      previous.priceCumulativeLast,
      timestamp,
      priceCumulativeEnd
    );
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
    if (token == _weth) {
      return FixedPoint.fraction(1, 1);
    }
    (uint32 timestamp, uint224 priceCumulativeEnd) = _uniswapFactory.observePrice(_weth, token);
    (bool foundPrice, uint256 lastPriceKey) = _tokenPriceMaps[token].getLastPriceObservation(
      timestamp,
      minTimeElapsed,
      maxTimeElapsed
    );
    require(foundPrice, "BisharesUniswapV2Oracle::_getEthPrice: No price found in provided range.");
    PriceLibrary.PriceObservation storage previous = _tokenPriceMaps[token].priceMap[lastPriceKey];
    return PriceLibrary.computeAveragePrice(
      previous.timestamp,
      previous.ethPriceCumulativeLast,
      timestamp,
      priceCumulativeEnd
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/* ==========  Internal Interfaces  ========== */
import "../interfaces/IUniswapV2Pair.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IUniswapV2Pair.sol";

/************************************************************************************************
Originally from https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol

This source code has been modified from the original, which was copied from the github repository
at commit hash 87edfdcaf49ccc52591502993db4c8c08ea9eec0.

Subject to the GPL-3.0 license
*************************************************************************************************/

interface IUniswapFactory {
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

  function calculatePair(
    address factory,
    address token0,
    address token1
  ) internal view returns (address pair) {
    IUniswapFactory _factory = IUniswapFactory(factory);
    pair = _factory.getPair(token0, token1);
  }

  // calculates the CREATE2 address for a pair without making any external calls
  function pairFor(
    address factory,
    address tokenA,
    address tokenB
  ) internal view returns (address pair) {
    (address token0, address token1) = sortTokens(tokenA, tokenB);
    pair = calculatePair(factory, token0, token1);
  }

  function getReserves(
    address factory,
    address tokenA,
    address tokenB
  ) internal view returns (uint256 reserveA, uint256 reserveB) {
    (address token0, ) = sortTokens(tokenA, tokenB);
    (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
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
      (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i], path[i + 1]);
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
      (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i - 1], path[i]);
      amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
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
    IUniswapFactory factory = IUniswapFactory(uniswapFactory);
    address pair = factory.getPair(token, weth);
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
    IUniswapFactory factory = IUniswapFactory(uniswapFactory);
    address pair = factory.getPair(token0, token1);
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
    IUniswapFactory factory = IUniswapFactory(uniswapFactory);
    address pair = factory.getPair(token0, token1);
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/* ==========  Internal Libraries  ========== */
import "./Bits.sol";


/**
 * @dev Library for indexing keys stored in a sequential mapping for easier
 * queries.
 *
 * Every set of 256 keys in the value map is assigned a single index which
 * records set values as bits, where 1 indicates the map has a value at a given
 * key and 0 indicates it does not.
 *
 * The 'value map' is the map which stores the values with sequential keys.
 * The 'key index' is the map which records the indices for every 256 keys
 * in the value map.
 *
 * The 'key index' is the mapping which stores the indices for each 256 values
 * in the map. For example, the key '256' in the value map would have a key
 * in the key index of `1`, where the 0th bit in the index records whether a
 * value is set in the value map .
 */
library KeyIndex {
  using Bits for uint256;
  using Bits for bytes;

/* ========= Utility Functions ========= */

  /**
   * @dev Compute the map key for a given index key and position.
   * Multiplies indexKey by 256 and adds indexPosition.
   */
  function toMapKey(uint256 indexKey, uint256 indexPosition) internal pure returns (uint256) {
    return (indexKey * 256) + indexPosition;
  }

  /**
   * @dev Returns the key in the key index which stores the index for the 256-bit
   * index which includes `mapKey` and the position in the index for that key.
   */
  function indexKeyAndPosition(uint256 mapKey)
    internal
    pure
    returns (uint256 indexKey, uint256 indexPosition)
  {
    indexKey = mapKey / 256;
    indexPosition = mapKey % 256;
  }

/* ========= Mutative Functions ========= */

  /**
   * @dev Sets a bit at the position in `indexMap` corresponding to `mapKey` if the
   * bit is not already set.
   *
   * @param keyIndex Mapping with indices of set keys in the value map
   * @param mapKey Position in the value map to mark as set
   */
  function markSetKey(
    mapping(uint256 => uint256) storage keyIndex,
    uint256 mapKey
  ) internal returns (bool /* didSetKey */) {
    (uint256 indexKey, uint256 indexPosition) = indexKeyAndPosition(mapKey);
    // console.log("IPOS", indexPosition);
    uint256 localIndex = keyIndex[indexKey];
    bool canSetKey = !localIndex.bitSet(indexPosition);
    if (canSetKey) {
      keyIndex[indexKey] = localIndex.setBit(indexPosition);
    }
    return canSetKey;
  }

/* ========= View Functions ========= */

  /**
   * @dev Returns a boolean indicating whether a value is stored for `mapKey` in the map index.
   */
  function hasKey(
    mapping(uint256 => uint256) storage keyIndex,
    uint256 mapKey
  ) internal view returns (bool) {
    (uint256 indexKey, uint256 indexPosition) = indexKeyAndPosition(mapKey);
    uint256 localIndex = keyIndex[indexKey];
    if (localIndex == 0) return false;
    return localIndex.bitSet(indexPosition);
  }

  /**
   * @dev Returns a packed uint16 array with the offsets of all set keys
   * between `mapKeyFrom` and `mapKeyTo`. Offsets are relative to `mapKeyFrom`
   */
  function getEncodedSetKeysInRange(
    mapping(uint256 => uint256) storage keyIndex,
    uint256 mapKeyFrom,
    uint256 mapKeyTo
  ) internal view returns (bytes memory bitPositions) {
    uint256 rangeSize = mapKeyTo - mapKeyFrom;
    (uint256 indexKeyStart, uint256 indexPositionStart) = indexKeyAndPosition(mapKeyFrom);
    (uint256 indexKeyEnd, uint256 indexPositionEnd) = indexKeyAndPosition(mapKeyTo);
    // Expand memory too accomodate the maximum number of bits that could be found
    // Length is 2*range because values are stored as uint16s
    // 30 is added because 32 bytes are stored at a time and this would go past rangeSize*2
    // if most bits are set
    bitPositions = new bytes((2 * rangeSize) + 30);
    // Set the length to 0, as it is used by the `writeSetBits` fn
    assembly { mstore(bitPositions, 0) }
    uint256 indexKey = indexKeyStart;
    // Clear the bits before `indexPositionStart` so they are not included in the search result
    uint256 localIndex = keyIndex[indexKey].clearBitsBefore(indexPositionStart);
    uint16 offset = 0;
    // Check each index until the last one is reached
    while (indexKey < indexKeyEnd) {
      // Relative index is set by adding provided `offset` to the bit index
      bitPositions.writeSetBits(localIndex, offset);
      indexKey += 1;
      localIndex = keyIndex[indexKey];
      offset += 256;
    }
    // Clear the bits after `indexPositionEnd` before searching for set bits
    localIndex = localIndex.clearBitsAfter(indexPositionEnd);
    bitPositions.writeSetBits(localIndex, offset);
  }

  /**
   * @dev Find the most recent position before `mapKey` which the index map records
   * as having a set value. Returns the key in the value map for that position.
   *
   * @param keyIndex Mapping with indices of set keys in the value map
   * @param mapKey Position in the value map to look behind
   * @param maxDistance Maximum distance between the found value and `mapKey`
   */
  function findLastSetKey(
    mapping(uint256 => uint256) storage keyIndex,
    uint256 mapKey,
    uint256 maxDistance
  )
    internal
    view
    returns (bool/* found */, uint256/* mapKey */)
  {
    (uint256 indexKey, uint256 indexPosition) = indexKeyAndPosition(mapKey);
    uint256 distance = 0;
    bool found;
    uint256 position;
    uint256 localIndex;
    // If the position is 0, we must go to the previous index
    if (indexPosition == 0) {
      require(indexKey != 0, "KeyIndex::findLastSetKey:Can not query value prior to 0.");
      indexKey -= 1;
      distance = 1;
    } else {
      localIndex = keyIndex[indexKey];
      (found, position) = localIndex.nextLowestBitSet(indexPosition);
      if (found) {
        distance += indexPosition - position;
      } else {
        distance += indexPosition + 1;
        indexKey -= 1;
      }
    }

    while (!found && distance <= maxDistance) {
      localIndex = keyIndex[indexKey];
      if (localIndex == 0) {
        if (indexKey == 0) return (false, 0);
        distance += 256;
        indexKey -= 1;
      } else {
        position = localIndex.highestBitSet();
        distance += 255 - position;
        found = true;
      }
    }
    if (distance > maxDistance) {
      return (false, 0);
    }
    return (true, toMapKey(indexKey, position));
  }

  /**
   * @dev Find the next position after `mapKey` which the index map records as
   * having a set value. Returns the key in the value map for that position.
   *
   * @param keyIndex Mapping with indices of set values in the value map
   * @param mapKey Position in the value map to look ahead
   * @param maxDistance Maximum distance between the found value and `mapKey`
   */
  function findNextSetKey(
    mapping(uint256 => uint256) storage keyIndex,
    uint256 mapKey,
    uint256 maxDistance
  )
    internal
    view
    returns (bool/* found */, uint256/* mapKey */)
  {
    (uint256 indexKey, uint256 indexPosition) = indexKeyAndPosition(mapKey);
    uint256 distance = 0;
    bool found;
    uint256 position;
    uint256 localIndex;
    if (indexPosition == 255) {
      indexKey += 1;
      position = indexPosition;
      distance = 1;
    } else {
      localIndex = keyIndex[indexKey];
      (found, position) = localIndex.nextHighestBitSet(indexPosition);
      if (found) {
        distance += position - indexPosition;
      } else {
        distance += 256 - indexPosition;
        indexKey += 1;
      }
    }
    while (!found && distance <= maxDistance) {
      localIndex = keyIndex[indexKey];
      if (localIndex == 0) {
        distance += 256;
        indexKey += 1;
      } else {
        position = localIndex.lowestBitSet();
        distance += position;
        found = true;
      }
    }
    if (distance > maxDistance) {
      return (false, 0);
    }
    return (true, toMapKey(indexKey, position));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;


/************************************************************************************************
From https://github.com/Uniswap/uniswap-lib/blob/master/contracts/libraries/FixedPoint.sol

Copied from the github repository at commit hash 9642a0705fdaf36b477354a4167a8cd765250860.

Modifications:
- Removed `sqrt` function

Subject to the GPL-3.0 license
*************************************************************************************************/


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
pragma solidity >=0.6.0;


library Bits {
  uint256 internal constant ONE = uint256(1);
  uint256 internal constant ONES = uint256(~0);

  /**
   * @dev Sets the bit at the given 'index' in 'self' to '1'.
   * Returns the modified value.
   */
  function setBit(uint256 self, uint256 index) internal pure returns (uint256) {
    return self | (ONE << index);
  }

  /**
   * @dev Returns a boolean indicating whether the bit at the given `index` in `self` is set.
   */
  function bitSet(uint256 self, uint256 index) internal pure returns (bool) {
    return (self >> index) & 1 == 1;
  }

  /**
    * @dev Clears all bits in the exclusive range [index:255]
    */
  function clearBitsAfter(uint256 self, uint256 index) internal pure returns (uint256) {
    return self & (ONES >> (255 - index));
  }

  /**
    * @dev Clears bits in the exclusive range [0:index]
    */
  function clearBitsBefore(uint256 self, uint256 index) internal pure returns (uint256) {
    return self & (ONES << (index));
  }

  /**
   * @dev Writes the index of every set bit in `val` as a uint16 in `bitPositions`.
   * Adds `offset` to the stored bit index.
   *
   * `bitPositions` must have a length equal to twice the maximum number of bits that
   * could be found plus 31. Each index is stored as a uint16 to accomodate `offset`
   *  because this is used in functions which would otherwise need expensive methods
   * to handle relative indices in multi-integer searches.
   * The specified length ensures that solc will handle memory allocation, and the
   * addition of 31 allows us to store whole words at a time.
   * After being declared, the actual length stored in memory must be set to 0 with:
   * `assembly { mstore(bitPositions, 0) }` because the length is used to count found bits.
   *
   * @param bitPositions Packed uint16 array for positions of set bits
   * @param val Value to search set bits in
   * @param offset Value added to the stored position, used to simplify large searches.
   */
  function writeSetBits(bytes memory bitPositions, uint256 val, uint16 offset) internal pure {
    if (val == 0) return;

    assembly {
      // Read the current length, which is the number of stored bytes
      let len := mload(bitPositions)
      // Set the starting pointer by adding the length to the bytes data pointer
      // This does not change and is later used to compute the new length
      let startPtr := add(add(bitPositions, 32), len)
      // Set the variable pointer which is used to track where to write memory values
      let ptr := startPtr
      // Increment the number of bits to shift until the shifted integer is 0
      // Add 3 to the index each loop because that is the number of bits being checked
      // at a time.
      for {let i := 0} gt(shr(i, val), 0) {i := add(i, 3)} {
        // Loop until the last 8 bits are not all 0
        for {} eq(and(shr(i, val), 255), 0) {i := add(i, 8)} {}
        // Take only the last 3  bits
        let x := and(shr(i, val), 7)
        // Use a switch statement as a lookup table with every possible combination of 3 bits.
        switch x
          case 0 {}// no bits set
          case 1 {// bit 0 set
            // shift left 240 bits to write uint16, increment ptr by 2 bytes
            mstore(ptr, shl(0xf0, add(i, offset)))
            ptr := add(ptr, 2)
          }
          case 2 {// bit 1 set
            // shift left 240 bits to write uint16, increment ptr by 2 bytes
            mstore(ptr, shl(0xf0, add(add(i, 1), offset)))
            ptr := add(ptr, 2)
          }
          case 3 {// bits 0,1 set
            // shift first left 240 bits and second 224 to write two uint16s
            // increment ptr by 4 bytes
            mstore(
              ptr,
              or(// use OR to avoid multiple memory writes
                shl(0xf0, add(i, offset)),
                shl(0xe0, add(add(i, 1), offset))
              )
            )
            ptr := add(ptr, 4)
          }
          case 4 {// bit 2 set
            // shift left 240 bits to write uint16, increment ptr by 2 bytes
            mstore(ptr, shl(0xf0, add(add(i, 2), offset)))
            ptr := add(ptr, 2)
          }
          case 5 {// 5: bits 0,2 set
            // shift first left 240 bits and second 224 bits to write two uint16s
            mstore(
              ptr,
              or(// use OR to avoid multiple memory writes
                shl(0xf0, add(i, offset)),
                shl(0xe0, add(add(i, 2), offset))
              )
            )

            ptr := add(ptr, 4)// increment ptr by 4 bytes
          }
          case 6 {// bits 1,2 set
            // shift first left 240 bits and second 224 to write two uint16s
            mstore(
              ptr,
              or(// use OR to avoid multiple memory writes
                shl(0xf0, add(add(i, 1), offset)),
                shl(0xe0, add(add(i, 2), offset))
              )
            )
            ptr := add(ptr, 4)// increment ptr by 4 bytes
          }
          case 7 {//bits 0,1,2 set
            // shift first left 240 bits, second 224, third 208 to write three uint16s
            mstore(
              ptr,
              or(// use OR to avoid multiple memory writes
                shl(0xf0, add(i, offset)),
                or(
                  shl(0xe0, add(add(i, 1), offset)),
                  shl(0xd0, add(add(i, 2), offset))
                )
              )
            )
            ptr := add(ptr, 6)// increment ptr by 6 bytes
          }
      }
      // subtract current pointer from initial to get byte length
      let newLen := sub(ptr, startPtr)
      // write byte length
      mstore(bitPositions, add(len, newLen))
    }
  }

  /**
   * @dev Returns the index of the highest bit set in `self`.
   * Note: Requires that `self != 0`
   */
  function highestBitSet(uint256 self) internal pure returns (uint256 r) {
    uint256 x = self;
    require (x > 0, "Bits::highestBitSet: Value 0 has no bits set");
    if (x >= 0x100000000000000000000000000000000) {x >>= 128; r += 128;}
    if (x >= 0x10000000000000000) {x >>= 64; r += 64;}
    if (x >= 0x100000000) {x >>= 32; r += 32;}
    if (x >= 0x10000) {x >>= 16; r += 16;}
    if (x >= 0x100) {x >>= 8; r += 8;}
    if (x >= 0x10) {x >>= 4; r += 4;}
    if (x >= 0x4) {x >>= 2; r += 2;}
    if (x >= 0x2) r += 1; // No need to shift x anymore
  }

  /**
   * @dev Returns the index of the lowest bit set in `self`.
   * Note: Requires that `self != 0`
   */
  function lowestBitSet(uint256 self) internal pure returns (uint256 _z) {
    require (self > 0, "Bits::lowestBitSet: Value 0 has no bits set");
    uint256 _magic = 0x00818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff;
    uint256 val = (self & -self) * _magic >> 248;
    uint256 _y = val >> 5;
    _z = (
      _y < 4
        ? _y < 2
          ? _y == 0
            ? 0x753a6d1b65325d0c552a4d1345224105391a310b29122104190a110309020100
            : 0xc976c13bb96e881cb166a933a55e490d9d56952b8d4e801485467d2362422606
          : _y == 2
            ? 0xe39ed557db96902cd38ed14fad815115c786af479b7e83247363534337271707
            : 0xf7cae577eec2a03cf3bad76fb589591debb2dd67e0aa9834bea6925f6a4a2e0e
        : _y < 6
          ? _y == 4
            ? 0xc8c0b887b0a8a4489c948c7f847c6125746c645c544c444038302820181008ff
            : 0xf6e4ed9ff2d6b458eadcdf97bd91692de2d4da8fd2d0ac50c6ae9a8272523616
          : _y == 6
            ? 0xf5ecf1b3e9debc68e1d9cfabc5997135bfb7a7a3938b7b606b5b4b3f2f1f0ffe
            : 0xf8f9cbfae6cc78fbefe7cdc3a1793dfcf4f0e8bbd8cec470b6a28a7a5a3e1efd
    );
    _z >>= (val & 0x1f) << 3;
    return _z & 0xff;
  }

  /**
   * @dev Returns a boolean indicating whether `bit` is the highest set bit
   * in the integer and the index of the next lowest set bit if it is not.
   */
  function nextLowestBitSet(uint256 self, uint256 bit)
    internal
    pure
    returns (bool haveValueBefore, uint256 previousBit)
  {
    uint256 val = self << (256 - bit);
    if (val == 0) {
      return (false, 0);
    }
    return (true, (highestBitSet(val) - (256 - bit)));
  }

  /**
   * @dev Returns a boolean indicating whether `bit` is the lowest set bit
   * in the integer and the index of the next highest set bit if it is not.
   */
  function nextHighestBitSet(uint256 self, uint256 bit)
    internal
    pure
    returns (bool haveValueAfter, uint256 nextBit)
  {
    uint256 val = self >> (bit + 1);
    if (val == 0) {
      return (false, 0);
    }
    return (true, lowestBitSet(val) + (bit + 1));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/* ==========  Internal Libraries  ========== */
import "./PriceLibrary.sol";
import "./KeyIndex.sol";


library BisharesPriceMapLibrary {
  using PriceLibrary for address;
  using KeyIndex for mapping(uint256 => uint256);

/* ==========  Constants  ========== */

  // Period over which prices are observed, each period should have 1 price observation.
  uint256 public constant OBSERVATION_PERIOD = 1 hours;

  // Minimum time elapsed between stored price observations
  uint256 public constant MINIMUM_OBSERVATION_DELAY = 0.5 hours;

/* ==========  Struct  ========== */

  struct BisharesPriceMap {
    mapping(uint256 => uint256) keyIndex;
    mapping(uint256 => PriceLibrary.PriceObservation) priceMap;
  }

/* ========= Utility Functions ========= */

  /**
   * @dev Returns the price key for `timestamp`, which is the hour index.
   */
  function toPriceKey(uint256 timestamp) internal pure returns (uint256/* priceKey */) {
    return timestamp / OBSERVATION_PERIOD;
  }

  /**
   * @dev Returns the number of seconds that have passed since the beginning of the hour.
   */
  function timeElapsedSinceWindowStart(uint256 timestamp) internal pure returns (uint256/* timeElapsed */) {
    return timestamp % OBSERVATION_PERIOD;
  }

/* ========= Mutative Functions ========= */

  /**
   * @dev Writes `observation` to storage if the price can be updated. If it is
   * updated, also marks the price key for the observation as having a value in
   * the key index.
   *
   * Note: The price can be updated if there is none recorded for the current
   * hour 30 minutes have passed since the last price update.
   * Returns a boolean indicating whether the price was updated.
   */
  function writePriceObservation(
    BisharesPriceMap storage indexedPriceMap,
    PriceLibrary.PriceObservation memory observation
  ) internal returns (bool/* didUpdatePrice */) {
    bool canUpdate = sufficientDelaySinceLastPrice(indexedPriceMap, observation.timestamp);
    if (canUpdate) {
      uint256 priceKey = toPriceKey(observation.timestamp);
      canUpdate = indexedPriceMap.keyIndex.markSetKey(priceKey);
      if (canUpdate) {
        indexedPriceMap.priceMap[priceKey] = observation;
      }
    }
    return canUpdate;
  }

/* ========= Price Update View Functions ========= */

  /**
   * @dev Checks whether sufficient time has passed since the beginning of the observation
   * window or since the price recorded in the previous window (if any) for a new price
   * to be recorded.
   */
  function sufficientDelaySinceLastPrice(
    BisharesPriceMap storage indexedPriceMap,
    uint32 newTimestamp
  ) internal view returns (bool/* hasSufficientDelay */) {
    uint256 priceKey = toPriceKey(newTimestamp);
    // If half the observation period has already passed since the beginning of the
    // current window, we can write the price without checking the previous window.
    if (timeElapsedSinceWindowStart(newTimestamp) >= MINIMUM_OBSERVATION_DELAY) {
      return true;
    } else {
      // Verify that at least half the observation period has passed since the last price observation.
      PriceLibrary.PriceObservation storage lastObservation = indexedPriceMap.priceMap[priceKey - 1];
      if (
        lastObservation.timestamp == 0 ||
        newTimestamp - lastObservation.timestamp >= MINIMUM_OBSERVATION_DELAY
      ) {
        return true;
      }
    }
    return false;
  }

  /**
   * @dev Checks if a price can be updated. PriceLibrary can be updated if there is no price
   * observation for the current hour and at least 30 minutes have passed since the
   * observation in the previous hour (if there is one).
   */
  function canUpdatePrice(
    BisharesPriceMap storage indexedPriceMap,
    uint32 newTimestamp
  ) internal view returns (bool/* canUpdatePrice */) {
    uint256 priceKey = toPriceKey(newTimestamp);
    // Verify there is not already a price for the same observation window
    if (indexedPriceMap.keyIndex.hasKey(priceKey)) return false;
    return sufficientDelaySinceLastPrice(indexedPriceMap, newTimestamp);
  }

/* =========  Price View Functions  ========= */

  /**
   * @dev Checks the key index to see if a price is recorded for `priceKey`
   */
  function hasPriceInWindow(
    BisharesPriceMap storage indexedPriceMap,
    uint256 priceKey
  ) internal view returns (bool) {
    return indexedPriceMap.keyIndex.hasKey(priceKey);
  }

  /**
   * @dev Returns the price observation for `priceKey`
   */
  function getPriceInWindow(
    BisharesPriceMap storage indexedPriceMap,
    uint256 priceKey
  ) internal view returns (PriceLibrary.PriceObservation memory) {
    return indexedPriceMap.priceMap[priceKey];
  }

  function getPriceObservationsInRange(
    BisharesPriceMap storage indexedPriceMap,
    uint256 timeFrom,
    uint256 timeTo
  )
    internal
    view
    returns (PriceLibrary.PriceObservation[] memory prices)
  {
    uint256 priceKeyFrom = toPriceKey(timeFrom);
    uint256 priceKeyTo = toPriceKey(timeTo);
    require(priceKeyTo > priceKeyFrom, "BisharesPriceMapLibrary::getPriceObservationsInRange: Invalid time range");
    bytes memory bitPositions = indexedPriceMap.keyIndex.getEncodedSetKeysInRange(priceKeyFrom, priceKeyTo);
    // Divide by 2 because length is in bytes and relative indices are stored as uint16
    uint256 len = bitPositions.length / 2;
    prices = new PriceLibrary.PriceObservation[](len);
    uint256 ptr;
    assembly { ptr := add(bitPositions, 32) }
    for (uint256 i = 0; i < len; i++) {
      uint256 relativeIndex;
      assembly {
        relativeIndex := shr(0xf0, mload(ptr))
        ptr := add(ptr, 2)
      }
      uint256 key = priceKeyFrom + relativeIndex;
      prices[i] = indexedPriceMap.priceMap[key];
    }
  }

  /**
   * @dev Finds the most recent price observation before `timestamp` with a minimum
   * difference in observation times of `minTimeElapsed` and a maximum difference in
   * observation times of `maxTimeElapsed`.
   *
   * Note: `maxTimeElapsed` is only accurate to the nearest hour (rounded down) unless
   * it is below one hour.
   *
   * @param indexedPriceMap Struct with the indexed price mapping for the token.
   * @param timestamp Timestamp to search backwards from.
   * @param minTimeElapsed Minimum time elapsed between price observations.
   * @param maxTimeElapsed Maximum time elapsed between price observations.
   * Only accurate to the nearest hour (rounded down) unless it is below 1 hour.
   */
  function getLastPriceObservation(
    BisharesPriceMap storage indexedPriceMap,
    uint256 timestamp,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  )
    internal
    view
    returns (bool /* foundPrice */, uint256 /* lastPriceKey */)
  {
    uint256 priceKey = toPriceKey(timestamp);
    uint256 windowTimeElapsed = timeElapsedSinceWindowStart(timestamp);
    bool canBeThisWindow = minTimeElapsed <= windowTimeElapsed;
    bool mustBeThisWindow = maxTimeElapsed <= windowTimeElapsed;
    // If the observation window for `timestamp` could include a price observation less than `maxTimeElapsed`
    // older than `timestamp` and the time elapsed since the beginning of the hour for `timestamp` is not higher
    // than `maxTimeElapsed`,  any allowed price must exist in the observation window for `timestamp`.
    if (canBeThisWindow || mustBeThisWindow) {
      PriceLibrary.PriceObservation storage observation = indexedPriceMap.priceMap[priceKey];
      uint32 obsTimestamp = observation.timestamp;
      if (
        obsTimestamp != 0 &&
        timestamp > obsTimestamp &&
        timestamp - obsTimestamp <= maxTimeElapsed &&
        timestamp - obsTimestamp >= minTimeElapsed
      ) {
        return (true, priceKey);
      }
      if (mustBeThisWindow) {
        return (false, 0);
      }
    }

    uint256 beginSearchTime = timestamp - minTimeElapsed;
    priceKey = toPriceKey(beginSearchTime);
    uint256 maxDistance = toPriceKey(maxTimeElapsed);
    return indexedPriceMap.keyIndex.findLastSetKey(priceKey, maxDistance);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

/* ==========  Libraries  ========== */
import "../lib/PriceLibrary.sol";
import "../lib/FixedPoint.sol";


interface IBisharesUniswapV2Oracle {
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

