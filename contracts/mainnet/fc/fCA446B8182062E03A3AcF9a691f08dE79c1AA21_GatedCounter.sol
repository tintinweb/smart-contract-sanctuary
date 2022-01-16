/**
 *Submitted for verification at Etherscan.io on 2022-01-16
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

contract GatedCounter {
  bool public isOn;
  uint32 public value;

  constructor() {
    value = 0;
  }

  function toggleGate() external {
    isOn = !isOn;
  }

  function increment() public  {
    require(isOn, "Contract needs to be turned on.");
    value += 1;
  }
}