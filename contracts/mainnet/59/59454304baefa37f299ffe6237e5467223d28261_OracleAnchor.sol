/**
 *Submitted for verification at Etherscan.io on 2021-03-08
*/

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

contract OracleAnchor {
  event AssetSourceUpdated(address indexed token, address indexed source);
  event OracleSystemMigrated();

  constructor(
    address[] memory assets, // token assets that are complex
    address[] memory sources // custom oracles for complex tokens
  ) public {
    require(assets.length == sources.length, 'INCONSISTENT_AAVEORACLE_PARAMS_LENGTH');
    emit OracleSystemMigrated();

    for (uint256 i = 0; i < assets.length; i++) {
      emit AssetSourceUpdated(assets[i], sources[i]);
    }
  }
}