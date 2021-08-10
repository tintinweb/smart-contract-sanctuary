/**
 *Submitted for verification at Etherscan.io on 2021-08-09
*/

//  for L2's naive rollups
//  https://azimuth.network

pragma solidity 0.4.24;

contract Naive
{
  event Batch();

  // This function is called for all messages sent to
  // this contract (there is no other function).
  // Sending Ether to this contract will cause an exception,
  // because the fallback function does not have the `payable`
  // modifier.
  //
  function() external
  {
    emit Batch();
  }
}