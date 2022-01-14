/**
 *Submitted for verification at BscScan.com on 2022-01-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract Dummy {
  string public secret = "secret";
  
  function setSecret(string memory s) public {
    secret = s;
  }
}