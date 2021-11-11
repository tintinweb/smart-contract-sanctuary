/**
 *Submitted for verification at Etherscan.io on 2021-11-11
*/

// Specifies the version of Solidity, using semantic versioning.
// Learn more: https://solidity.readthedocs.io/en/v0.5.10/layout-of-source-files.html#pragma
pragma solidity ^0.7.0;

// Defines a contract named `HelloWorld`.
// A contract is a collection of functions and data (its state). Once deployed, a contract resides at a specific address on the Ethereum blockchain. Learn more: https://solidity.readthedocs.io/en/v0.5.10/structure-of-a-contract.html
contract Calculator{
   function add(uint x, uint y) public pure returns (uint) {
      return x + y;
   }

   function sub(uint x, uint y) public pure returns (uint) {
      return x - y;
   }
   
   function times(uint x, uint y) public pure returns (uint) {
      return x * y;
   }

   function div(uint x, uint y) public pure returns (uint) {
      return x / y;
   }
}