/**
 *Submitted for verification at Etherscan.io on 2022-01-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

library ExtendLibrary {
  function delegatestaticcall(address ex, bytes memory data) external returns (bool, bytes memory) {
    return ex.delegatecall(data);
  }
}