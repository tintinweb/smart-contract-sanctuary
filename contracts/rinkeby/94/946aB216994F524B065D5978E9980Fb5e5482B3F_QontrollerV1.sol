//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract QontrollerV1 {

  address public admin;

  constructor() public {
    admin = msg.sender;
  }
  
}