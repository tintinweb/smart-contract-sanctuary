/**
 *Submitted for verification at snowtrace.io on 2022-01-07
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract VulcanPortal {
  uint256 totalSalutes;
  mapping (address => uint256) public vulcans;
  Salute[] salutes;

  event LogSalute(address indexed from, uint256 timestamp, string message);

  struct Salute {
    address vulcan;
    string message;
    uint256 timestamp;
  }

  function salute(string memory _message) public {
    totalSalutes++;
    vulcans[msg.sender]++;
    salutes.push(Salute(msg.sender, _message, block.timestamp));
    emit LogSalute(msg.sender, block.timestamp, _message);
  }

  function getSalutes(address addr) public view returns(uint256) {
    return vulcans[addr];
  }

  function getSalutesData() public view returns (Salute[] memory) {
    return salutes;
  }

  function getTotalSalutes() public view returns(uint256) {
    return totalSalutes;
  }
}