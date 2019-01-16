pragma solidity 0.4.25;

// File: contracts/Greeting.sol

contract Greeting {
  function greet() public pure returns (uint256);
}

// File: contracts/Hello.sol

contract Hello is Greeting {
  function greet() public pure returns (uint256) { return 1; }
}