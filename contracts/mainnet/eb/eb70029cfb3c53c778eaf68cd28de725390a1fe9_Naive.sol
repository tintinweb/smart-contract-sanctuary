/**
 *Submitted for verification at Etherscan.io on 2021-10-07
*/

pragma solidity 0.8.9;

contract Naive
{
  event Batch();

  // This function is called for all messages sent to
  // this contract (there is no other function).
  // Sending Ether to this contract will cause an exception,
  // because the fallback function does not have the `payable`
  // modifier.
  //
  fallback() external
  {
    emit Batch();
  }
}