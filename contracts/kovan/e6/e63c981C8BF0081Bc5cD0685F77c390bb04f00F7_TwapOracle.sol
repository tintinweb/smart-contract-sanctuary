/**
 *Submitted for verification at Etherscan.io on 2021-06-04
*/

// File: @uniswap/lib/contracts/libraries/FixedPoint.sol

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

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol

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

// File: @uniswap/v2-periphery/contracts/libraries/UniswapV2OracleLibrary.sol

pragma solidity >=0.5.0;



// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(
        address pair
    ) internal view returns (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            // counterfactual
            price1Cumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
    }
}

// File: contracts/modules/oracles/TwapOracle.sol

/* Copyright (C) 2020 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity ^0.5.0;



contract TwapOracle {
  using FixedPoint for *;

  struct Bucket {
    uint timestamp;
    uint price0Cumulative;
    uint price1Cumulative;
  }

  event Updated(address indexed pair, uint timestamp, uint price0Cumulative, uint price1Cumulative);

  uint constant public periodSize = 1800;
  uint constant public periodsPerWindow = 8;
  uint constant public windowSize = periodSize * periodsPerWindow;

  address public factory;

  // token pair => Bucket[8]
  mapping(address => Bucket[8]) public buckets;

  constructor (address _factory) public {
    factory = _factory;
  }

  /* utils */

  // https://uniswap.org/docs/v2/smart-contract-integration/getting-pair-addresses/
  function _pairFor(address _factory, address tokenA, address tokenB) internal pure returns (address pair) {

    // sort tokens
    (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

    require(token0 != token1, "TWAP: identical addresses");
    require(token0 != address(0), "TWAP: zero address");

    pair = address(uint(keccak256(abi.encodePacked(
        hex'ff',
        _factory,
        keccak256(abi.encodePacked(token0, token1)),
        hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f'
      ))));
  }

  function timestampToIndex(uint timestamp) internal pure returns (uint index) {
    uint epochPeriod = timestamp / periodSize;
    return epochPeriod % periodsPerWindow;
  }

  function pairFor(address tokenA, address tokenB) external view returns (address pair) {
    return _pairFor(factory, tokenA, tokenB);
  }

  function currentBucketIndex() external view returns (uint index) {
    return timestampToIndex(block.timestamp);
  }

  /* update */

  function update(address[] calldata pairs) external {

    for (uint i = 0; i < pairs.length; i++) {

      // note: not reusing canUpdate() because we need the bucket variable
      address pair = pairs[i];
      uint index = timestampToIndex(block.timestamp);
      Bucket storage bucket = buckets[pair][index];

      if (block.timestamp - bucket.timestamp < periodSize) {
        continue;
      }

      (uint price0Cumulative, uint price1Cumulative,) = UniswapV2OracleLibrary.currentCumulativePrices(pair);
      bucket.timestamp = block.timestamp;
      bucket.price0Cumulative = price0Cumulative;
      bucket.price1Cumulative = price1Cumulative;

      emit Updated(pair, block.timestamp, price0Cumulative, price1Cumulative);
    }
  }

  function canUpdate(address pair) external view returns (bool) {

    uint index = timestampToIndex(block.timestamp);
    Bucket storage bucket = buckets[pair][index];
    uint timeElapsed = block.timestamp - bucket.timestamp;

    return timeElapsed > periodSize;
  }

  /* consult */

  function _getCumulativePrices(
    address tokenIn,
    address tokenOut
  ) internal view returns (uint priceCumulativeStart, uint priceCumulativeEnd, uint timeElapsed) {

    uint currentIndex = timestampToIndex(block.timestamp);
    uint firstBucketIndex = (currentIndex + 1) % periodsPerWindow;

    address pair = _pairFor(factory, tokenIn, tokenOut);
    Bucket storage firstBucket = buckets[pair][firstBucketIndex];

    timeElapsed = block.timestamp - firstBucket.timestamp;
    require(timeElapsed <= windowSize, "TWAP: missing historical reading");
    require(timeElapsed >= windowSize - periodSize * 2, "TWAP: unexpected time elapsed");

    (uint price0Cumulative, uint price1Cumulative,) = UniswapV2OracleLibrary.currentCumulativePrices(pair);

    if (tokenIn < tokenOut) {
      return (firstBucket.price0Cumulative, price0Cumulative, timeElapsed);
    }

    return (firstBucket.price1Cumulative, price1Cumulative, timeElapsed);
  }

  function _computeAmountOut(
    uint priceCumulativeStart,
    uint priceCumulativeEnd,
    uint timeElapsed,
    uint amountIn
  ) internal pure returns (uint amountOut) {

    // overflow is desired.
    FixedPoint.uq112x112 memory priceAverage = FixedPoint.uq112x112(
      uint224((priceCumulativeEnd - priceCumulativeStart) / timeElapsed)
    );

    return priceAverage.mul(amountIn).decode144();
  }

  /**
   *  @dev Returns the amount out corresponding to the amount in for a given token using the
   *  @dev   moving average over the time range [now - [windowSize, windowSize - periodSize * 2], now]
   *  @dev   update must have been called for the bucket corresponding to timestamp `now - windowSize`
   */
  function consult(address tokenIn, uint amountIn, address tokenOut) external view returns (uint amountOut) {

    uint pastPriceCumulative;
    uint currentPriceCumulative;
    uint timeElapsed;

    (pastPriceCumulative, currentPriceCumulative, timeElapsed) = _getCumulativePrices(tokenIn, tokenOut);

    return _computeAmountOut(
      pastPriceCumulative,
      currentPriceCumulative,
      timeElapsed,
      amountIn
    );
  }

}