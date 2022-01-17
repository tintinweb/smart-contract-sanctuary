/**
 *Submitted for verification at Etherscan.io on 2022-01-17
*/

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

contract MockRewardRate {
  struct RewardInfo {
    uint startTimestamp;
    uint endTimestamp;
    uint rewardPerSec; // 1e18
  }

  event AddRewardInfo(uint indexed rid, RewardInfo rewardInfo);
  event UpdateRewardInfo(uint indexed rid, RewardInfo rewardInfo);
  event DeleteRewardInfo(uint indexed rid, RewardInfo rewardInfo);
  event SetGovernor(address governor);
  event SetPendingGovernor(address pendingGovernor);

  address public governor;
  address public pendingGovernor;
  RewardInfo[] public rewardInfos;

  modifier onlyGov() {
    require(msg.sender == governor, 'RewardRate/onlyGov');
    _;
  }

  constructor() {
    governor = msg.sender;
    emit SetGovernor(msg.sender);
  }

  function setPendingGovernor(address _pendingGovernor) external onlyGov {
    pendingGovernor = _pendingGovernor;
    emit SetPendingGovernor(_pendingGovernor);
  }

  function acceptGovernor() external {
    require(msg.sender == pendingGovernor, 'acceptGovernor/not-pending-governor');
    pendingGovernor = address(0);
    governor = msg.sender;
    emit SetGovernor(msg.sender);
  }

  function addRewardInfos(RewardInfo[] calldata _rewardInfos) external onlyGov {}

  function updateRewardInfos(uint[] calldata _rids, RewardInfo[] calldata _rewardInfos)
    external
    onlyGov
  {}

  function deleteRewardInfo(uint _rid) external onlyGov {}

  function getCurrentRewardInfo() external view returns (RewardInfo memory) {}

  function getAllRewardInfos() external view returns (RewardInfo[] memory) {}

  function getRewardInfoLength() external view returns (uint) {}
}