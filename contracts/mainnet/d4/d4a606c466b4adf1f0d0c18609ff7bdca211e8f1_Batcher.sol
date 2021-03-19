/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

contract Batcher {
  function batchSend(
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory datas
  )
  public payable
  {
    for (uint i = 0; i < targets.length; i++) {
      (bool success,) = targets[i].call.value(values[i])(datas[i]);
      if (!success) revert('transaction failed');
    }
  }
    function batchSendUltimate(
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory datas
  )
  public payable
  {
    for (uint i = 0; i < targets.length; i++) {
        targets[i].call.value(values[i])(datas[i]);
     
    }
  }
}