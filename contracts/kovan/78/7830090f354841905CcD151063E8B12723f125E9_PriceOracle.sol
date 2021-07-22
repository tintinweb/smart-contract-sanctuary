// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;


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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

import "./FixedPoint.sol";
import "./UniswapV2Library.sol";
import "./UniswapV2OracleLibrary.sol";

contract PriceOracle {
    using FixedPoint for FixedPoint.uq112x112;
    using FixedPoint for FixedPoint.uq144x112;

    address internal immutable _uniswapFactory;
    address internal immutable _weth;

    struct PriceObservation {
        uint32 timestamp;
        uint224 priceCumulativeLast;
        uint224 ethPriceCumulativeLast;
    }

    mapping(address => PriceObservation) public lastUpdatedObservation;
    mapping(address => address) public feeds;

    constructor(address uniswapFactory, address weth) public {
        _uniswapFactory = uniswapFactory;
        _weth = weth;
    }

    modifier valueNotNullCoin(address tokenAddress) {
        require(feeds[tokenAddress] != address(0), "key not present");
        _;
    }

    function addInstancesOfCoin(address tokenAddress, address aggregatorAddress)
        public
    {
        require(
            aggregatorAddress != address(0),
            "Aggregator address shoudn't not be equal to null"
        );
        require(
            tokenAddress != address(0),
            "Token address shoudn't not be equal to null"
        );
        feeds[tokenAddress] = aggregatorAddress;
    }

    function removeInstanceOfCoin(address tokenAddress)
        public
        valueNotNullCoin(tokenAddress)
    {
        delete feeds[tokenAddress];
    }

    /**
     * @dev Attempts to update the price of `token` and returns a boolean
     * indicating whether it was updated.
     *
     * Note: The price can be updated if there is no observation for the current hour
     * and at least 30 minutes have passed since the last observation.
     */
    function updatePrice(address token)
        public
    {
        PriceObservation memory observation = observeTwoWayPrice(token);
        lastUpdatedObservation[token] = observation;
    }

    function getLatestPriceOfCoin(address token)
        public
        view
        returns (uint256)
    {
        FixedPoint.uq112x112 memory tokenPrice = _getTokenPrice(token);
        return tokenPrice.mul(1000000000000000000).decode144();
    }

    function computeAverageEthForTokens(address token, uint256 tokenAmount)
        external
        view
        returns (
            uint144 /* averageValueInWETH */
        )
    {
        FixedPoint.uq112x112 memory tokenPrice = _getTokenPrice(token);
        return tokenPrice.mul(tokenAmount).decode144();
    }

    function _getTokenPrice(address token)
        internal
        view
        returns (FixedPoint.uq112x112 memory)
    {
        if (token == _weth) {
            return FixedPoint.fraction(1, 1);
        }
        (uint32 timestamp, uint224 priceCumulativeEnd) = observePrice(
            token,
            _weth
        );
        PriceObservation storage previous = lastUpdatedObservation[token];
        return
            UniswapV2OracleLibrary.computeAveragePrice(
                previous.priceCumulativeLast,
                priceCumulativeEnd,
                uint32(timestamp - previous.timestamp)
            );
    }

    function observePrice(address tokenIn, address quoteToken)
        internal
        view
        returns (
            uint32, /* timestamp */
            uint224 /* priceCumulativeLast */
        )
    {
        (address token0, address token1) = UniswapV2Library.sortTokens(
            tokenIn,
            quoteToken
        );
        address pair = UniswapV2Library.calculatePair(
            _uniswapFactory,
            token0,
            token1
        );
        if (token0 == tokenIn) {
            (
                uint256 price0Cumulative,
                uint32 blockTimestamp
            ) = UniswapV2OracleLibrary.currentCumulativePrice0(pair);
            return (blockTimestamp, uint224(price0Cumulative));
        } else {
            (
                uint256 price1Cumulative,
                uint32 blockTimestamp
            ) = UniswapV2OracleLibrary.currentCumulativePrice1(pair);
            return (blockTimestamp, uint224(price1Cumulative));
        }
    }

    function observeTwoWayPrice(address token)
        internal
        view
        returns (PriceObservation memory)
    {
        (address token0, address token1) = UniswapV2Library.sortTokens(
            token,
            _weth
        );
        address pair = UniswapV2Library.calculatePair(
            _uniswapFactory,
            token0,
            token1
        );
        (
            uint256 price0Cumulative,
            uint256 price1Cumulative,
            uint32 blockTimestamp
        ) = UniswapV2OracleLibrary.currentCumulativePrices(pair);
        if (token0 == token) {
            return
                PriceObservation({
                    timestamp: blockTimestamp,
                    priceCumulativeLast: uint224(price0Cumulative),
                    ethPriceCumulativeLast: uint224(price1Cumulative)
                });
        } else {
            return
                PriceObservation({
                    timestamp: blockTimestamp,
                    priceCumulativeLast: uint224(price1Cumulative),
                    ethPriceCumulativeLast: uint224(price0Cumulative)
                });
        }
    }
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
import "./FixedPoint.sol";
// import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
interface IUniswapV2Pair {
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
  function price0CumulativeLast() external view returns (uint);
  function price1CumulativeLast() external view returns (uint);
}


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

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}