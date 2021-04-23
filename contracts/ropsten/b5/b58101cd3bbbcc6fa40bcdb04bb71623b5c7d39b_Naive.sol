/**
 *Submitted for verification at Etherscan.io on 2021-04-23
*/

pragma solidity 0.4.24;

contract Naive
{
  event Batch();

  function batch(bytes data) external
  {
    emit Batch();
  }
}