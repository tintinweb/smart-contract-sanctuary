pragma solidity ^0.4.24;

library CCC {
  function addCCC(uint256 a, uint256 b) pure returns (uint256) {
    uint256 c = a - b;
    return c;
  }
}

contract AAA {
    function aa() constant returns (uint256) {
        uint256 x = 50;
        return CCC.addCCC(50, x);
    }
}

