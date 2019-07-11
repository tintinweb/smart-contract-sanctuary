/**
 *Submitted for verification at Etherscan.io on 2019-07-07
*/

pragma solidity ^0.5.10;

contract Simple {
  function arithmetics(uint _a, uint _b) public returns (uint o_sum, uint o_product) {
    o_sum = _a + _b;
    o_product = _a * _b;
  }

  function multiply(uint _a, uint _b) public returns (uint) {
    return _a * _b;
  }
}