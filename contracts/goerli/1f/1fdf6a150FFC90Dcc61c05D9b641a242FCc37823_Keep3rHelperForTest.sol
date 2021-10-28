// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

library Math {
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

contract Keep3rHelperForTest {
  uint256 public constant MIN = 11;
  uint256 public constant MAX = 12;
  uint256 public constant BASE = 10;
  uint256 public constant SWAP = 300000;
  uint256 public constant TARGETBOND = 200e18;

  /* DOES NOT HAVE CONSTRUCTOR */

  /* TEST: uses a 1-10 KP3R/WETH quote */
  function quote(uint256 eth) public pure returns (uint256 amountOut) {
    amountOut = eth * 10;
  }

  /* TEST: uses always a gas price of 50GWei */
  uint256 public fastGas = 1_000_000_000_000 wei;

  function getFastGas() external view returns (uint256) {
    return fastGas;
  }

  /* TEST: can set fast gas calculation */
  function setFastGas(uint256 _fastGas) external {
    fastGas = _fastGas;
  }

  /* TEST: does not check for Keep3r bonds */
  function bonds(address) public pure returns (uint256) {
    return 0;
  }

  function getQuoteLimitFor(address origin, uint256 gasUsed) public view returns (uint256) {
    uint256 _quote = quote((gasUsed + SWAP) * fastGas);
    uint256 _min = (_quote * MIN) / BASE;
    uint256 _boost = (_quote * MAX) / BASE;
    uint256 _bond = Math.min(bonds(origin), TARGETBOND);
    return Math.max(_min, (_boost * _bond) / TARGETBOND);
  }

  function getQuoteLimit(uint256 gasUsed) external view returns (uint256) {
    return getQuoteLimitFor(tx.origin, gasUsed);
  }
}