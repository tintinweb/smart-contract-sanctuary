/**
 *Submitted for verification at polygonscan.com on 2022-01-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.4.24;

contract AmazingDapp {
  mapping (string => bool) private names;

  function checkIfExists(string name) constant returns (bool) {
    return names[name];
  }

  function registerName(string name) {
    names[name] = true;
  }

}