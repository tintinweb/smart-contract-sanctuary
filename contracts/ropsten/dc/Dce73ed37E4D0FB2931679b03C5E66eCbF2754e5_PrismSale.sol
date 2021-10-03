/**
 *Submitted for verification at Etherscan.io on 2021-10-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract PrismSale {

  uint public totalSales;
  uint public maxSales;
  address public owner;
  address public charity;
  mapping (address => bool) sales;

  // runs once when the contract is initially deployed
  constructor() {

    totalSales = 0;
    maxSales = 100;
    owner = msg.sender;
    charity = 0xA0a74FA4d1ABBA9F37F4950D0A88144DCb9C2DB3;

  }

  // this function does not change anything, only views data
  function canBuy() public view returns (bool) {

    // check if there is stock, if there is return true
    return totalSales < maxSales;

  }

  // this function does not change anything, only views data
  function hasAccess() public view returns (bool) {

    // check if this address has already purchased this
    return sales[msg.sender];

  }

  function buy() public payable returns (bool) {

    // will only run rest of the code if returns true
    // if false, show error message
    require(canBuy() == true, "Cant buy this.");
    require(msg.value == 0.01 ether, "You didnt send the correct amount.");
    require(hasAccess() == false, "You have already purchased this.");

    // send 80% to owner, 20% to charity
    payable(owner).transfer(msg.value / 100 * 80);
    payable(charity).transfer(msg.value / 100 * 20);

    // increase totalSales by 1
    totalSales = totalSales + 1;

    // store buyers address
    sales[msg.sender] = true;

    return true;

  }

}