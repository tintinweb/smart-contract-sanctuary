//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./Rules2.sol";

contract InoToken is Rules2 {
  string public constant name = "Ino Game Token";
  string public constant symbol = "ING";
  uint8 public constant decimals = 10;


  function transferMultiple(address[] calldata addresses, uint256[] calldata sums) external {
    if (addresses.length != sums.length) {
      revert();
    }
    for (uint i = 0; i < addresses.length; ++i) {
      _transfer(msg.sender, addresses[i], sums[i]);
    }
  }

  function transferMultiple(address[] calldata addresses, uint256 sum) external {
    for (uint i = 0; i < addresses.length; ++i) {
      _transfer(msg.sender, addresses[i], sum);
    }
  }
}