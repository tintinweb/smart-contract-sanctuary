/**
 *Submitted for verification at Etherscan.io on 2021-11-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;


contract Storage {

uint a;
uint b;
uint c;

function addSoliditypure(uint x, uint y) public pure returns (uint) {
     return x + y;
 }
 
 function addSolidityview(uint x, uint y) public view returns (uint) {
     return x + y;
 }
 
function addAssemblypure(uint x, uint y) public pure returns (uint) {
     assembly {
         // Add some code here
         let result := add(x, y)
         mstore(0x0, result)
         return(0x0, 32)
     }
 }
 
 function addAssemblyview(uint x, uint y) public view returns (uint) {
     assembly {
         // Add some code here
         let result := add(x, y)
         mstore(0x0, result)
         return(0x0, 32)
     }
 }
 
 function addSolidity(uint x, uint y) public returns (uint) {
     a = x + y;
     return a;
 }
 
  function addAssembly(uint x, uint y) public returns (uint b) {
         assembly {
         let result := add(x, y)
         b := result
     }
     c = b;
 }
 
  function readaddSolidity() public view returns (uint) {
     return a;
 }
 
  function readaddAssembly() public view returns (uint) {
     return c;
     }
 }