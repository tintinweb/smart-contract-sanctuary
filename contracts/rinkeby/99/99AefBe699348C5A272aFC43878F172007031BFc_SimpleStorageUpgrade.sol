// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract SimpleStorageUpgrade {

  uint storedData;

  event Change(string message, uint newVal);

  function set(uint x) public {
    require(x < 5000, "Should be less than 5000");
    storedData = x;
    emit Change("set", x);
  }

  function get() public view returns (uint) {
    return storedData;
  }
}

