/**
 *Submitted for verification at Etherscan.io on 2021-05-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;



// Part: IDenial

interface IDenial {
  function setWithdrawPartner(address _partner) external;
}

// File: SetPartner.sol

contract SetPartner {
  function setWithdrawPartner(address targetAddr) public {
    IDenial(targetAddr).setWithdrawPartner(address(this));
  }

  fallback() external payable {
    for (uint256 i = 0; i > 0; i += 1) {
      // do notthing.
    }
  }
}