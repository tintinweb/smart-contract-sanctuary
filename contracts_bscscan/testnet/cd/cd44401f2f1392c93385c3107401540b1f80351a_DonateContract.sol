/**
 *Submitted for verification at BscScan.com on 2022-01-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract DonateContract {

  uint totalDonations; // the amount of donations
  address payable owner; // contract creator's address

  //contract settings
  constructor() {
    owner = payable(msg.sender); // setting the contract creator
  }

  //public function to make donate
  function donate() public payable {
    (bool success,) = owner.call{value: msg.value}("");
    require(success, "Failed to send money");
  }

  // public function to return total of donations
  function getTotalDonations() view public returns(uint) {
    return totalDonations;
  }
}