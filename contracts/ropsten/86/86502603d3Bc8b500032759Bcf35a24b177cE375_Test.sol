/**
 *Submitted for verification at Etherscan.io on 2021-12-28
*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.7;

contract Test {
   function getResult(uint a,uint b) public pure returns(uint)
   {
  
      uint divide = a/b;
      return divide;
   }
}