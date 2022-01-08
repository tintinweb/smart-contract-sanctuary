/**
 *Submitted for verification at FtmScan.com on 2022-01-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface BIFIBalanceToken {
  function balanceOf(address account) external view returns (uint256);
}

interface BIFIMaxi {
  function getPricePerFullShare() external view returns (uint256);
}

interface MAIVault {
  function balanceOf(address account) external view returns (uint256);
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
  function vaultCollateral(uint256 index) external view returns (uint256);
}

contract QiDaoMooBIFIBalance {

  BIFIMaxi public maxi;
  MAIVault public vault;

  constructor(BIFIMaxi _bifiMaxiVault, MAIVault _vault) {
    maxi = _bifiMaxiVault;
    vault = _vault;
  }

  function getSuppliedMooBifiAmount(address account) internal view returns (uint256) {
    uint256 amount = 0;
    uint256 userVaultCount = vault.balanceOf(account);

    for (uint index = 0; index < userVaultCount; index++) {
      uint256 vaultID = vault.tokenOfOwnerByIndex(account, index);
      uint256 vaultCollateralBalance = vault.vaultCollateral(vaultID);
      amount += vaultCollateralBalance;
    }

    return amount;
  }

  function balanceOf(address account) external view returns (uint256) {
    uint256 ppfs = maxi.getPricePerFullShare();
    uint256 userBalance = getSuppliedMooBifiAmount(account);
    return userBalance * ppfs / 1e18;
  }

  function balanceOfMoo(address account) external view returns (uint256) {
    return getSuppliedMooBifiAmount(account);
  }

}