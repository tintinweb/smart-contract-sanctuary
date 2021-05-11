/**
 *Submitted for verification at Etherscan.io on 2021-05-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;



// Part: Shop

interface Shop {
  function isSold() external view returns (bool);

  function buy() external;
}

// File: Buyer.sol

contract Buyer {
  function price() public view returns (uint256) {
    return Shop(msg.sender).isSold() ? 101 : 0;
  }

  function buyFromShop(address shopAddr) public {
    Shop(shopAddr).buy();
  }
}