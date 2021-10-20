/**
 *Submitted for verification at Etherscan.io on 2021-10-20
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
contract EventCheck
{   
  event Names(address Account, string Name);
  function add(string memory _name) public
  {
    emit Names(msg.sender,_name);
  }
}