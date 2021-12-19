/**
 *Submitted for verification at snowtrace.io on 2021-12-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface BIFIBalanceToken {
  function balanceOf(address account) external view returns (uint256);
}

interface BIFIMaxi {
  function want() external view returns (BIFIBalanceToken);
  function balanceOf(address account) external view returns (uint256);
  function getPricePerFullShare() external view returns (uint256);
}

contract BIFIBalance {

  BIFIBalanceToken public bifi;
  BIFIMaxi public maxi;
  BIFIBalanceToken public gov;

  constructor(BIFIMaxi _bifiMaxiVault, BIFIBalanceToken _governancePool) {
    bifi = _bifiMaxiVault.want();
    maxi = _bifiMaxiVault;
    gov = _governancePool;
  }

  function balanceOf(address account) external view returns (uint256) {
    uint ppfs = maxi.getPricePerFullShare();
    return bifi.balanceOf(account) + maxi.balanceOf(account) * ppfs / 1e18 + gov.balanceOf(account);
  }

}