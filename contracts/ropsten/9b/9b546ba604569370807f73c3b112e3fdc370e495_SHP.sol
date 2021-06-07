/**
 *Submitted for verification at Etherscan.io on 2021-06-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

contract SHP {

  function balanceOfAt(
    address owner,
    uint256 blockNumber
  ) public pure returns (uint256) {
    require(owner != address(0x0), "invalid address");
    require(blockNumber > 0, "invalid block");
    return 100000 ether;
  }

  function totalSupplyAt(
    uint256 blockNumber
  ) public pure returns (uint256) {
    require(blockNumber > 0, "invalid block");
    return 32000000 ether;
  }
}