// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";

import "../drip/BalanceDripManager.sol";
import "../drip/VolumeDripManager.sol";

contract ComptrollerStorage is OwnableUpgradeSafe {
  mapping(address => VolumeDripManager.State) internal volumeDrips;
  mapping(address => VolumeDripManager.State) internal referralVolumeDrips;
  mapping(address => BalanceDripManager.State) internal balanceDrips;

  mapping(address => uint256) internal dripTokenTotalSupply;
  mapping(address => mapping(address => uint256)) internal dripTokenBalances;
}
