/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.4;

contract Set {
  uint256 public one;
  uint256 public two;
  uint256 public three;

  address public owner;

  constructor() {
    owner = 0x47b77f91F441688492B7Da74152cDA0dD16f3564;
  }

  modifier authorised() {
    require(msg.sender == owner);
    _;
  }

  function setOne(uint256 number) public {
    one = number;
  }

  function setTwo(uint256 number) public authorised {
    two = number;
  }

  function setThree(uint256 number) public authorised {
    three = number;
  }

  function getNumbers()
    public
    view
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    return (one, two, three);
  }
}