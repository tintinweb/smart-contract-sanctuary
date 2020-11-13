// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface sbControllerInterface {
  function requestRewards(address miner, uint256 amount) external;

  function isValuePoolAccepted(address valuePool) external view returns (bool);

  function getValuePoolRewards(address valuePool, uint256 day) external view returns (uint256);

  function getValuePoolMiningFee(address valuePool) external returns (uint256, uint256);

  function getValuePoolUnminingFee(address valuePool) external returns (uint256, uint256);

  function getValuePoolClaimingFee(address valuePool) external returns (uint256, uint256);

  function isServicePoolAccepted(address servicePool) external view returns (bool);

  function getServicePoolRewards(address servicePool, uint256 day) external view returns (uint256);

  function getServicePoolClaimingFee(address servicePool) external returns (uint256, uint256);

  function getServicePoolRequestFeeInWei(address servicePool) external returns (uint256);

  function getVoteForServicePoolsCount() external view returns (uint256);

  function getVoteForServicesCount() external view returns (uint256);

  function getVoteCastersRewards(uint256 dayNumber) external view returns (uint256);

  function getVoteReceiversRewards(uint256 dayNumber) external view returns (uint256);

  function getMinerMinMineDays() external view returns (uint256);

  function getServiceMinMineDays() external view returns (uint256);

  function getMinerMinMineAmountInWei() external view returns (uint256);

  function getServiceMinMineAmountInWei() external view returns (uint256);

  function getValuePoolVestingDays(address valuePool) external view returns (uint256);

  function getServicePoolVestingDays(address poservicePoolol) external view returns (uint256);

  function getVoteCasterVestingDays() external view returns (uint256);

  function getVoteReceiverVestingDays() external view returns (uint256);
}
