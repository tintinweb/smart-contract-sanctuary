/**
 *Submitted for verification at polygonscan.com on 2021-12-23
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

contract SimpleLottery {

  address partner = 0xac2092182df762Db0df97E9C298a4dA22B652506;
  uint256 entryFee = 1000;

  constructor() {

  }

  receive() external payable {
    require(msg.value >= entryFee, "You must supply enough entry fee");
    uint change = msg.value - entryFee;
    uint256 half = entryFee / 2;
    payable(partner).transfer(half);
    if ( change > 0 ) {
      payable(msg.sender).transfer(change);
    }
  }

  function getBalance() public view returns (uint256 balance) {
    return address(this).balance;
  }

}