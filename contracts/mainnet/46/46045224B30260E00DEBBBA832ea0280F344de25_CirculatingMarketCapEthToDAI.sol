// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@indexed-finance/uniswap-v2-oracle/contracts/lib/FixedPoint.sol";
import "./interfaces/ICirculatingMarketCapOracle.sol";


/**
 * @dev Temporary contract to convert market caps denominated in ETH
 * to market caps denominated in USD.
 */
contract CirculatingMarketCapEthToDAI {
  using FixedPoint for FixedPoint.uq112x112;
  using FixedPoint for FixedPoint.uq144x112;

  address public immutable uniswapOracle;
  address public immutable circulatingMarketCapOracle;
  address public immutable dai;

  uint32 internal constant SHORT_TWAP_MIN_TIME_ELAPSED = 20 minutes;
  uint32 internal constant SHORT_TWAP_MAX_TIME_ELAPSED = 2 days;

  constructor (
    address uniswapOracle_,
    address circulatingMarketCapOracle_,
    address dai_
  ) public {
    uniswapOracle = uniswapOracle_;
    circulatingMarketCapOracle = circulatingMarketCapOracle_;
    dai = dai_;
  }

  function getCirculatingMarketCaps(address[] calldata tokens) external view returns (uint256[] memory values) {
    uint256 len = tokens.length;
    FixedPoint.uq112x112 memory ethPriceForDai = IIndexedUniswapV2Oracle(uniswapOracle).computeAverageEthPrice(
      dai,
      SHORT_TWAP_MIN_TIME_ELAPSED,
      SHORT_TWAP_MAX_TIME_ELAPSED
    );
    values = ICirculatingMarketCapOracle(circulatingMarketCapOracle).getCirculatingMarketCaps(tokens);
    for (uint256 i = 0; i < len; i++) {
      values[i] = ethPriceForDai.mul(values[i]).decode144();
    }
  }
}


interface IIndexedUniswapV2Oracle {
  function computeAverageEthPrice(
    address token,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  )
    external
    view
    returns (FixedPoint.uq112x112 memory priceAverage);
}

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;


interface ICirculatingMarketCapOracle {
  function getCirculatingMarketCap(address) external view returns (uint256);

  function getCirculatingMarketCaps(address[] calldata) external view returns (uint256[] memory);

  function updateCirculatingMarketCaps(address[] calldata) external;
}