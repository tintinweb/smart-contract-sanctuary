/**
 *Submitted for verification at Etherscan.io on 2021-12-27
*/

pragma solidity ^0.8.11;

contract Name{
  string Name;

  function get() view public returns(string memory)
  {
    return Name;
  }
  function set(string memory newuserName) public{
    Name = newuserName;
  }
}