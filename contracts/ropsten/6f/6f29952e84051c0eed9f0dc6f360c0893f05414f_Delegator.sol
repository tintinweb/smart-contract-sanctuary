/**
 *Submitted for verification at Etherscan.io on 2021-10-11
*/

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.4;

contract Delegator {
  address public multiSend;

  constructor(address _multiSend) {
    multiSend = _multiSend;
  }

  function exec(bytes memory transactionsData)
    public
    payable
    returns (bool success, bytes memory data)
  {
    (success, data) = multiSend.delegatecall(
      abi.encodeWithSignature("multiSend(bytes)", transactionsData)
    );
  }
}