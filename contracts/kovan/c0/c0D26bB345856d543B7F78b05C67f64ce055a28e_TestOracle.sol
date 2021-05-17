// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;


interface IStandardOracle {
/* ==========  Mutative Functions  ========== */

  function updatePrice(address token) external returns (bool);

  function updatePrices(address[] calldata tokens) external returns (bool[] memory);

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

pragma solidity >=0.4.0;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library LowGasFixedPoint {
  // uq112x112
  // range: [0, 2**112 - 1]
  // resolution: 1 / 2**112

  // uq144x112
  // range: [0, 2**144 - 1]
  // resolution: 1 / 2**112

  uint8 internal constant RESOLUTION = 112;
  uint internal constant Q112 = uint(1) << RESOLUTION;
  uint internal constant Q224 = Q112 << RESOLUTION;

  // encode a uint112 as a UQ112x112
  function encode(uint112 x) internal pure returns (uint224) {
    return uint224(x) << RESOLUTION;
  }

  // encodes a uint144 as a UQ144x112
  function encode144(uint144 x) internal pure returns (uint256) {
    return uint256(x) << RESOLUTION;
  }

  // divide a UQ112x112 by a uint112, returning a UQ112x112
  function div(uint224 self, uint112 x) internal pure returns (uint224) {
    require(x != 0, "FixedPoint: DIV_BY_ZERO");
    return self / uint224(x);
  }

  // multiply a UQ112x112 by a uint, returning a UQ144x112
  // reverts on overflow
  function mul(uint224 self, uint y) internal pure returns (uint256) {
    uint z;
    require(y == 0 || (z = uint(self) * y) / y == uint(self), "FixedPoint: MULTIPLICATION_OVERFLOW");
    return z;
  }

  // returns a UQ112x112 which represents the ratio of the numerator to the denominator
  // equivalent to encode(numerator).div(denominator)
  function fraction(uint112 numerator, uint112 denominator) internal pure returns (uint224) {
    require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
    return (uint224(numerator) << RESOLUTION) / denominator;
  }

  // decode a UQ112x112 into a uint112 by truncating after the radix point
  function decode(uint224 self) internal pure returns (uint112) {
    return uint112(self >> RESOLUTION);
  }

  // decode a UQ144x112 into a uint144 by truncating after the radix point
  function decode144(uint256 self) internal pure returns (uint144) {
    return uint144(self >> RESOLUTION);
  }

  function mulDecode(uint224 self, uint y) internal pure returns (uint144) {
    uint z;
    require(y == 0 || (z = uint(self) * y) / y == uint(self), "FixedPoint: MULTIPLICATION_OVERFLOW");
    return uint144(z >> RESOLUTION);
  }

  // take the reciprocal of a UQ112x112
  function reciprocal(uint224 self) internal pure returns (uint224) {
    require(self != 0, "FixedPoint: ZERO_RECIPROCAL");
    return uint224(Q224 / self);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "../interfaces/IStandardOracle.sol";
import "../lib/LowGasFixedPoint.sol";


contract TestOracle is IStandardOracle {
  using LowGasFixedPoint for uint256;
  using LowGasFixedPoint for uint224;
  using LowGasFixedPoint for uint112;

  mapping(address => uint224) internal tokenEthPrice;

  function setTokenEthPrice(
    address token,
    uint112 tokenAmount,
    uint112 ethAmount
  ) external {
    tokenEthPrice[token] = tokenAmount.fraction(ethAmount);
  }

  function updatePrice(address token) public override returns (bool didUpdate) {
    didUpdate = true;
    tokenEthPrice[token] += uint224(1) << LowGasFixedPoint.RESOLUTION;
  }

  function updatePrices(address[] calldata tokens) external override returns (bool[] memory didUpdate) {
    uint256 len = tokens.length;
    didUpdate = new bool[](len);
    for (uint256 i = 0; i < len; i++) didUpdate[i] = updatePrice(tokens[i]);
  }

  function computeAverageEthForTokens(
    address token,
    uint256 tokenAmount,
    uint256,
    uint256
  ) public view override returns (uint144) {
    return tokenEthPrice[token].reciprocal().mul(tokenAmount).decode144();
  }

  function computeAverageTokensForEth(
    address token,
    uint256 wethAmount,
    uint256,
    uint256
  ) public view override returns (uint144) {
    return tokenEthPrice[token].mul(wethAmount).decode144();
  }

/* ==========  Value Queries: Multiple  ========== */

  function computeAverageEthForTokens(
    address[] calldata tokens,
    uint256[] calldata tokenAmounts,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) external view override returns (uint144[] memory wethAmounts) {
    uint256 len = tokens.length;
    wethAmounts = new uint144[](len);
    for (uint256 i = 0; i < len; i++) wethAmounts[i] = computeAverageEthForTokens(
      tokens[i],
      tokenAmounts[i],
      minTimeElapsed,
      maxTimeElapsed
    );
  }

  function computeAverageTokensForEth(
    address[] calldata tokens,
    uint256[] calldata wethAmounts,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) external view override returns (uint144[] memory tokenAmounts) {
    uint256 len = tokens.length;
    tokenAmounts = new uint144[](len);
    for (uint256 i = 0; i < len; i++) tokenAmounts[i] = computeAverageTokensForEth(
      tokens[i],
      wethAmounts[i],
      minTimeElapsed,
      maxTimeElapsed
    );
  }
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "none",
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