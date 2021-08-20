/**
 *Submitted for verification at polygonscan.com on 2021-08-20
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.7.0;

contract SimpleStorage {
  uint storedData;
  uint storedData1;
  uint storedData2;

  function setX(uint x) public {
    storedData = x;
  }

  function setY(uint y) public {
    storedData1 = y;
  }

  function setSUM(uint x, uint y) public {
    storedData2 = x+y;
  }

  function getX() public view returns (uint) {
    return storedData;
  }

  function getY() public view returns (uint) {
     return storedData1;
  }

  function getSUM() public view returns (uint){
    return storedData2;
  }
}