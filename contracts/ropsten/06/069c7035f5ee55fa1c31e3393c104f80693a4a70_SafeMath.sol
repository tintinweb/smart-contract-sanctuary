contract SafeMath {
  //internals

  function safeMul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b) internal pure returns (uint) {
    require(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    require(c>=a && c>=b);
    return c;
  }
}