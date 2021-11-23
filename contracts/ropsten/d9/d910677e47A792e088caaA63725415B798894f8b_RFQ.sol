// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract RFQ {

  //TODO: add fields to determine product type and currency
  event Request(address from, uint endBlock, bool isPayer, uint notional);

  function createRequest(uint endBlock, bool isPayer, uint notional) public {
    emit Request(
                 msg.sender,
                 endBlock,
                 isPayer,
                 notional
                 );
  }
  
}