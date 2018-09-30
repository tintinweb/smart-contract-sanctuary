pragma solidity ^0.4.24;

contract Voting {
  address public admin;

  constructor(address _admin) public {
    admin = _admin;
  }
}