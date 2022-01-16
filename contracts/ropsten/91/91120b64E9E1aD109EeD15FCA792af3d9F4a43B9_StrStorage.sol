/**
 *Submitted for verification at Etherscan.io on 2022-01-16
*/

pragma solidity >=0.4.21 <0.7.0;


// SPDX-License-Identifier: MIT
contract StrStorage {
  string storeStr;

  function set(string  memory x) public {
    storeStr = x;
  }

  function get() public view returns (string memory) {
    return storeStr;
  }
}