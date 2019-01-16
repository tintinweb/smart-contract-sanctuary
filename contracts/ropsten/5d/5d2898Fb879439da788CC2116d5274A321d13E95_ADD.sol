pragma solidity ^0.4.21;

contract ADD{

 function addone (uint256 _a, uint _b) constant returns (uint256)
 {
  uint256 sum = _a + _b;
  return sum;
 }
}