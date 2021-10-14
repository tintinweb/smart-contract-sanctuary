/**
 *Submitted for verification at Etherscan.io on 2021-10-14
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
contract EventCheck
{   
    struct User
    {
        string Name;
        uint Time;
    }
    User[]user;
    
  event Names(User[] user);
  function add(string memory name) public
  {
     user.push(User({Name:name,Time:block.timestamp})) ;
    emit Names(user);
  }
}