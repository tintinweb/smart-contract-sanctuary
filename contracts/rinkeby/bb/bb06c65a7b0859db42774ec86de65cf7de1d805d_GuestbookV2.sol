/**
 *Submitted for verification at Etherscan.io on 2022-01-21
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

contract GuestbookV2 {
  event Entry(address sender, uint256 donation, string name, string message);

  address public owner;

  constructor() {
    owner = msg.sender;
  }

  function enter(string calldata name, string calldata message) external payable {
    emit Entry(msg.sender, msg.value, name, message);
  }

  function withdraw() external {
    payable(owner).transfer(address(this).balance);
  }
}