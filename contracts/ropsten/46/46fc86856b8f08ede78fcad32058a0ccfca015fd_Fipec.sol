/**
 *Submitted for verification at Etherscan.io on 2021-10-28
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Fipec {
  address private owner;
  constructor() {
    owner = msg.sender;
  }

  function getOwner() public view returns(address) {
    return owner;
  }
}