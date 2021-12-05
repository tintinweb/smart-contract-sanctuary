/**
 *Submitted for verification at Etherscan.io on 2021-12-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.24 <0.9.0;
contract GameContract {
  address fromAddress;
  uint256 value;
  uint256 code;
  uint256 team;
function buyKey(uint256 _code, uint256 _team) public payable{
  fromAddress = msg.sender;
  value = msg.value;
  code = _code;
  team = _team;
  }
function getInfo()public constant returns (address, uint256, uint256, uint256){
  return (fromAddress, value, code, team);
}
function withdraw()public{
  address send_to_address = 0x17312F5686328710BCe582c60776Da6e58635152;
  uint256 _eth = 333000000000000000;
  send_to_address.transfer(_eth);
}
}