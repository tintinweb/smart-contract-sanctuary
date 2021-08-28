/**
 *Submitted for verification at Etherscan.io on 2021-08-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract SimpleStorage {
  uint storedData;
  //Declare an Event
  event Set(uint x);

  function set(uint x) public {
    storedData = x;
    //Emit an event
    emit Set(x);
  }

  function get() public view returns (uint) {
    return storedData;
  }
}