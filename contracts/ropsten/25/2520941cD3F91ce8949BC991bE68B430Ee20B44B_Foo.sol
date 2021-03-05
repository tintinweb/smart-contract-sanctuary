/**
 *Submitted for verification at Etherscan.io on 2021-03-05
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

contract Foo {
  string [] private strings;

  function addString (string memory str) public {
    strings.push (str);
  }

  function getStrings () public view returns (string [] memory) {
    return strings;
  }
}