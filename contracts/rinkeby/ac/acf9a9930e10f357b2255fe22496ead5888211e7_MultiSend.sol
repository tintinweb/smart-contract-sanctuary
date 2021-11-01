/**
 *Submitted for verification at Etherscan.io on 2021-11-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract MultiSend {
  function multiSendEth(address payable[] calldata addresses, uint256[] calldata paymentAmount) public payable {
    for(uint i = 0; i < addresses.length; i++) {
      addresses[i].transfer(paymentAmount[i]);
    }
    payable(msg.sender).transfer(address(this).balance);
  }
}