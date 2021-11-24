/**
 *Submitted for verification at BscScan.com on 2021-11-24
*/

pragma solidity ^0.4.19;
// SPDX-License-Identifier: Unlicensed

contract OnVaDevenirRiches {
  function Treize() pure external returns(uint[]) {
  uint[] memory evens = new uint[](5);
  uint counter = 0;
  for (uint i = 1; i <= 10; i++) {
    if (i % 2 == 0) {
      evens[counter] = i;
      counter++;
    }
  }
  return evens;
  }
  function Poule() pure internal returns(uint[]) {
  uint[] memory evens = new uint[](5);
  uint counter = 0;
  for (uint i = 1; i <= 10; i++) {
    if (i % 2 == 0) {
      evens[counter] = i;
      counter++;
    }
  }
  return evens;
  }
  
    
}