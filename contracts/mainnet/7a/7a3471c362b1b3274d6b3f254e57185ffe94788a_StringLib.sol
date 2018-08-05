pragma solidity ^0.4.24;

library StringLib {
  function generateName(bytes16 _s, uint256 _len, uint256 _n)
    public
    pure
    returns (bytes16 ret)
  {
    uint256 v = _n;
    bytes16 num = 0;
    while (v > 0) {
      num = bytes16(uint(num) / (2 ** 8));
      num |= bytes16(((v % 10) + 48) * 2 ** (8 * 15));
      v /= 10;
    }
    ret = _s | bytes16(uint(num) / (2 ** (8 * _len)));
    return ret;
  }
}