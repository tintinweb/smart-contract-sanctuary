/**
 *Submitted for verification at Etherscan.io on 2021-12-28
*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.7;

contract Test {
   function getResult() public pure returns(uint product, uint sum){
      uint a = 1;
      uint b = 2;
      product = a * b;
      sum = a + b; 
   }
}