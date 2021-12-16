// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract MultiSender {
  function multiSendETH(address[] calldata addresses) public payable {
    for (uint256 i = 0; i < addresses.length; i++) {
      payable(addresses[i]).transfer(msg.value / addresses.length);
    }
    payable(msg.sender).transfer(address(this).balance);
  }
}