pragma solidity ^0.8.0;

contract BlockNumber {

  function getblocknumber() public view returns (uint256) {
    return block.number;
  }
}