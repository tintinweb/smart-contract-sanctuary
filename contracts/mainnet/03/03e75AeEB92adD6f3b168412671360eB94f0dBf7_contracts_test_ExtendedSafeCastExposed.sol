pragma solidity >=0.6.0 <0.7.0;

import "../utils/ExtendedSafeCast.sol";

contract ExtendedSafeCastExposed {
  function toUint112(uint256 value) external pure returns (uint112) {
    return ExtendedSafeCast.toUint112(value);
  }
  function toUint96(uint256 value) external pure returns (uint96) {
    return ExtendedSafeCast.toUint96(value);
  }
}