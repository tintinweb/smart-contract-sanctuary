/**
 *Submitted for verification at Etherscan.io on 2022-01-26
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

contract GatedCounter {
  bool isOn;
  uint32 public value;

  constructor() {
    value = 0;
  }

  function setIsOn(bool newIsOn) external {
    isOn = newIsOn;
  }

  function increment() public payable {
    require(isOn, "Contract needs to be turned on.");
    value += 1;
  }
}