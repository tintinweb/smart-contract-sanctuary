/**
 *Submitted for verification at Etherscan.io on 2021-08-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract SimpleStorage{
uint storeddata;
function set(uint x) public{
storeddata = x;
}
function get() public view returns(uint){
return storeddata;
}
}