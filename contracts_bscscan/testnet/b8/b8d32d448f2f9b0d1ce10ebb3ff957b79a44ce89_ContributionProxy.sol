/**
 *Submitted for verification at BscScan.com on 2022-01-18
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract ContributionProxy {
  address public account;
  address public contributionCollector;
  uint256 public amount;
  uint256 public tier;
  uint256 public maximumAmount;
  bytes32[] public proof;

   function flashContribute(
        address _contributionCollector,
        address _account,
        uint256 _amount,
        uint256 _tier,
        uint256 _maximumAmount,
        bytes32[] calldata _proof
    ) external {
      account = _account;
      contributionCollector = _contributionCollector;
      amount = _amount;
      tier = _tier;
      maximumAmount = _maximumAmount;
      proof = _proof;
    }
}