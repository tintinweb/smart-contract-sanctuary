/**
 *Submitted for verification at polygonscan.com on 2021-08-11
*/

pragma solidity ^0.8.0; contract SimpleStorage { uint x; function set(uint newValue) public { x = newValue; } function get() public returns (uint) { return x; } }