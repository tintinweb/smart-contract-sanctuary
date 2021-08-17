/**
 *Submitted for verification at Etherscan.io on 2021-08-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract RecordDeal {
  address public owner;

  address[] public bandMembers;
  uint public totalBandMembers;

  mapping (address => uint) public sales;

  constructor() {
    owner = msg.sender;
    bandMembers.push(msg.sender);
    totalBandMembers = 1;
  }

  function addMember (address newMember) public {
    require(msg.sender == owner);
    bandMembers.push(newMember);
    totalBandMembers += 1;
  }

  function buy() public payable {
    require(sales[msg.sender] == 0, "already bought this");
    require(msg.value > 0, "need to pay something for this");
    
    sales[msg.sender] = msg.value;
    
    for (uint i = 0; i < totalBandMembers; i++) {
      payable(bandMembers[i]).transfer(msg.value / totalBandMembers);
    }
  }
}