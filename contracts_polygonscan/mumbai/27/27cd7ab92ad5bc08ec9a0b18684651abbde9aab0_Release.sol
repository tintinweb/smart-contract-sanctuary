/**
 *Submitted for verification at polygonscan.com on 2022-01-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
A standard ERC20 token using openzeppelin
*/
contract Release {
  string public zeroMeOut = "Here I am, at whatever time of day. But then you come and delete me. Its rude. And no one will know";
  string public hitMe = "Where you at";

  uint256 public numb = 2**256 - 1;
  mapping (address => uint256) public grouping;
  uint256[] public array;

  function zeroOut() public {
    zeroMeOut = "";
  }

  function hit() public {
    hitMe = "";
  }

  function fixNumber(uint256 newNumber) public {
    numb = newNumber;
  }

  function pushArray(uint256 next) public {
    array.push(next);
  }

  function arrayReset() public {
    delete array;
  }

  function mapMe(address newAddress, uint256 newNumber) public {
    grouping[newAddress] = newNumber;
  }
}