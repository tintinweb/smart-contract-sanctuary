// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

library Math {
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

interface IKeep3rV1 {
  function totalBonded() external view returns (uint256);

  function bonds(address keeper, address credit) external view returns (uint256);

  function votes(address keeper) external view returns (uint256);
}

contract Keep3rV3HelperForTest {
  uint256 public constant MIN = 11;
  uint256 public constant MAX = 12;
  uint256 public constant BASE = 10;
  uint256 public constant SWAP = 300_000;
  uint256 public constant ORACLE_QUOTE = 25_000;
  uint256 public constant TARGETBOND = 200e18;
  /* solhint-disable var-name-mixedcase */
  IKeep3rV1 public immutable KP3R;
  /* solhint-disable var-name-mixedcase */

  constructor(
    IKeep3rV1 _KP3R
  ) {
    KP3R = _KP3R;
  }

  // setters

  uint256 public quote = 10;
  uint256 public baseFee = 50_000_000_000 wei;

  function setQuote(uint256 _quote) public {
    quote = _quote;
  }

  function setBaseFee(uint256 _baseFee) public {
    baseFee = _baseFee;
  }

  // views

  function getQuote(uint128 _amountIn) public view returns (uint256 _amountOut) {
    _amountOut = quote * _amountIn;
  }

  function bonds(address keeper) public view returns (uint256) {
    return KP3R.bonds(keeper, address(KP3R)) + (KP3R.votes(keeper));
  }

  function _getBasefee() internal view virtual returns (uint256) {
    return baseFee;
  }

  function getQuoteLimitFor(address _origin, uint256 _gasUsed) public view returns (uint256) {
    uint256 quote = getQuote(uint128((_gasUsed + SWAP + ORACLE_QUOTE) * _getBasefee()));
    uint256 min = (quote * MIN) / BASE;
    uint256 boost = (quote * MAX) / BASE;
    uint256 bond = Math.min(bonds(_origin), TARGETBOND);
    return Math.max(min, (boost * bond) / TARGETBOND);
  }

  function getQuoteLimit(uint256 gasUsed) external view returns (uint256) {
    // solhint-disable-next-line avoid-tx-origin
    return getQuoteLimitFor(tx.origin, gasUsed);
  }
}