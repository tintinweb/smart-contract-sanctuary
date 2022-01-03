/**
 *Submitted for verification at BscScan.com on 2022-01-02
*/

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT


contract Donate {

  address payable owner; 
  uint256 value = 200000000000000000;
  uint256 donationValue = 0;
  address userAddress;
  address[] donator;
 
  //contract settings
  constructor() {
    owner = payable(msg.sender); 
  }

  //public function to make donate
  function donate() public payable {
  
    require (msg.value == value);
    require (donationValue < 200000000000000000000, "Donation Over");
    (bool success,) = owner.call{value: msg.value}("");
    require(success, "Failed to send money");
    donationValue += msg.value;
    userAddress = msg.sender;
    donator.push(userAddress);
  }

  function Donators() public view returns(address [] memory){
    return donator;
  }

  function DonatorsLengt() public view returns (uint256){
    return donator.length;
  }

  // public function to return total of donations
  function getTotalDonations() view public returns(uint256) {
    return donationValue;
  }

  function getvalue() view public returns(uint256){
    return value;
  }
}