/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

contract PocContract {

  string public constant RESERVED_NAME = "admin";

  event NonReservedName(string name);

  function checkName(string memory _name) external { 
    require(keccak256(abi.encodePacked(_name)) != keccak256(abi.encodePacked(RESERVED_NAME)), "Name is reserved");
    emit NonReservedName(_name);
  }

}