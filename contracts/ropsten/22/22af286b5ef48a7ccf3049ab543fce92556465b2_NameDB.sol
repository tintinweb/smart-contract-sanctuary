/**
 *Submitted for verification at Etherscan.io on 2022-01-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract NameDB {
   mapping(uint => string) public name;
   uint index;

   function updateName(uint _index, string memory _name) public {
      name[_index] = _name;
   }

}