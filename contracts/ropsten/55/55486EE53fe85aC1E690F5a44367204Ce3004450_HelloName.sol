/**
 *Submitted for verification at Etherscan.io on 2021-08-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract HelloName{

 string name;

function set(string memory _name) public {
  name = _name;
 }

function get() view public returns (string memory) {
        return string(abi.encodePacked("hello ", name));
    }
}