/**
 *Submitted for verification at polygonscan.com on 2021-11-09
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;  

contract First {
  uint public count;

  function Increment() public {
    count++;
  }

   function Dncrement() public {
    count--;
  }

  function getValue() public view returns(uint) {
      return count;
  }

  function writenBy() public pure returns(string memory) {
      return 'Surya Kant Sharma';
  } 
}