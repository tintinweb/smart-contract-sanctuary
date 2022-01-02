/**
 *Submitted for verification at Etherscan.io on 2022-01-02
*/

contract SafeCastLib {
  function to32(uint x) public pure returns(uint32 y) {
    require((x & ~uint(1<<32)) == 0);

    y = uint32(x);
  }
}