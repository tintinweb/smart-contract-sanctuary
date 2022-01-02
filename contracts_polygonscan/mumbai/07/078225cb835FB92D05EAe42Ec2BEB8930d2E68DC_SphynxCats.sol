/**
 *Submitted for verification at polygonscan.com on 2022-01-01
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract SphynxCats  {
  uint256 public aNumber;
  uint256 public secondNumber;
  
  constructor() {
    aNumber = 123456789;
    secondNumber = 0;
  }
 
  function setANumber(uint number) public {    
    aNumber = number;
  }
  function setSecondNumber(uint number) public {    
    secondNumber = number;
  }
}