/**
 *Submitted for verification at Etherscan.io on 2021-12-21
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

contract GatedCounter {
  bool isOn;
  uint32 value;

  constructor() {
    value = 0;
  }

  function turnOn() public {
    require(!isOn, "Contract is already on.");
    isOn = true;
  }

  function turnOff() public {
    require(isOn, "Contract is already off.");
    isOn = false;
  }

  function increment() public returns(uint32) {
    require(isOn, "Contract needs to be turned on.");
    value += 1;
    return value;
  }
}