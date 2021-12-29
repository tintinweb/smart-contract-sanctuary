/**
 *Submitted for verification at Etherscan.io on 2021-12-27
*/

pragma solidity ^0.8.11;

contract Name{
 
  string Names;

  function get() view public returns(string memory)
  {
    return Names;
  }
  function set(string memory newuserName) public{
    Names = newuserName;
  }
}