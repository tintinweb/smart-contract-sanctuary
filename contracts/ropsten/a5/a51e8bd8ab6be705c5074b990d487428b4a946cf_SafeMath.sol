pragma solidity ^0.4.16;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function toUINT112(uint256 a) internal constant returns(uint112) {
    assert(uint112(a) == a);
    return uint112(a);
  }

  function toUINT120(uint256 a) internal constant returns(uint120) {
    assert(uint120(a) == a);
    return uint120(a);
  }

  function toUINT128(uint256 a) internal constant returns(uint128) {
    assert(uint128(a) == a);
    return uint128(a);
  }
}