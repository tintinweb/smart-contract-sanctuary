/**
 *Submitted for verification at Etherscan.io on 2022-01-21
*/

pragma solidity >=0.4.22 <0.9.0;

contract MamaUuu {
  int public count = 0; // state variable

  function inc() public returns (int) {
    count += 1;
    return count;
  }

  function dec() public returns (int) {
    count -= 1;
    return count;
  }
}