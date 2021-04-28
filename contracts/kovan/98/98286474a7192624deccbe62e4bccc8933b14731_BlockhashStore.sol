/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

contract BlockhashStore {
  function getGasPrice() external view returns (uint256) {
    return tx.gasprice;
  }
}