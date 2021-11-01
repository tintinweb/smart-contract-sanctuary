/**
 *Submitted for verification at Etherscan.io on 2021-11-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;


contract Storage {

function addSolidity(uint x, uint y) public pure returns (uint) {
     return x + y;
 }
 
function addAssembly(uint x, uint y) public pure returns (uint) {
     assembly {
         // Add some code here
         let result := add(x, y)
         mstore(0x0, result)
         return(0x0, 32)
     }
 }
 
}