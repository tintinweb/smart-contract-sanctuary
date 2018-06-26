library SafeMathLib {
  function times(uint a, uint b) returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function minus(uint a, uint b) returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function plus(uint a, uint b) returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
  
  function toUINT112(uint256 a) internal constant returns(uint112) {
    assert(uint112(a) == a);
    return uint112(a);
  }


  function toUINT128(uint256 a) internal constant returns(uint128) {
    assert(uint128(a) == a);
    return uint128(a);
  }
}