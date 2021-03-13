/**
 *Submitted for verification at Etherscan.io on 2021-03-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >0.6.0;contract BC0101_000_Storage {
 address payable private owner;
 uint256 number; constructor() {
  owner = msg.sender;
 } function store(uint256 num) public {
  number = num;
 } function retrieve() public view returns (uint256){
  return number;
 }
 
 function close() public { 
  selfdestruct(owner); 
 }
}