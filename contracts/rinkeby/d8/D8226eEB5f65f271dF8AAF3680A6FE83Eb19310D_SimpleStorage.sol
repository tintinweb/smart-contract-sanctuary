// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage   {
 uint favNum;

 function set(uint _favNum) public {
     favNum = _favNum;
 }

 function get() public view returns(uint) {
     return favNum;
 }
}