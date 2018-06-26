pragma solidity ^0.4.24;

contract Test {
  mapping(string=>uint256[]) gg;

  function getLen(string email) public
  constant
  returns(uint256) {
    return gg[email].length;
  }

  function addLen(string email) public
  {
    gg[email].push(100);
  }
}