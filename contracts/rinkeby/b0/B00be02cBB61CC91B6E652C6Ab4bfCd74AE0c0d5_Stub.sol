// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.2;

//for testing
contract Stub {
  mapping (address => uint256) public balanceOf;  

  function setBalance(address a, uint256 b) public {
    balanceOf[a] = b;
  }
  
  constructor() {
  }
}

