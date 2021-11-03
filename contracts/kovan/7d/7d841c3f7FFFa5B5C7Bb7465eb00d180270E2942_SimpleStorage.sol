// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract SimpleStorage {
  uint favoriteNumber;
  
  function store(uint _number) public {
    favoriteNumber = _number;
  }

  function retrieve() public view returns (uint256) {
    return favoriteNumber;
  }
    
}