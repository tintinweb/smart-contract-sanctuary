/**
 *Submitted for verification at Etherscan.io on 2021-07-03
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.8.2;



// File: EthSender.sol

contract EthSender {
  function sendEthAtTime(uint time, address payable recipient) external payable {
    require(block.timestamp >= time, "Too soon");
    recipient.transfer(msg.value);
  }
}