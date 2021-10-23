/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.4;

contract Delegator {
  function exec(address payable to, bytes memory transactionsData)
    public
    payable
    returns (bool success, bytes memory data)
  {
    (success, data) = to.delegatecall(
      abi.encodeWithSignature("multiSend(bytes)", transactionsData)
    );
  }
}