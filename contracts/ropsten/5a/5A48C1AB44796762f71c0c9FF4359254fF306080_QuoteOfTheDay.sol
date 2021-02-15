/**
 *Submitted for verification at Etherscan.io on 2021-02-15
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

contract QuoteOfTheDay {

  string quote;
  uint lastSet;

  function setQuoteOfToday(string calldata _quote) public {
    require(
       !isQuoteSetToday(),
       "Wait for at least 24 hours after the last quote to set a new quote."
    );
    quote = _quote;
    lastSet = block.timestamp;
  }
  
  function getQuoteOfToday() public view returns (string memory) {
    return quote;
  }

  function getLastSet() public view returns (uint) {
    return lastSet;
  }

  function isQuoteSetToday() public view returns (bool) {
    return block.timestamp < lastSet + 1 days;
  }
}