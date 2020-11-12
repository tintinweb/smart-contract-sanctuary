// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface sbControllerInterface {
  function getDayMineSecondsUSDTotal(uint256 day) external view returns (uint256);

  function getCommunityDayMineSecondsUSD(address community, uint256 day) external view returns (uint256);

  function getCommunityDayRewards(address community, uint256 day) external view returns (uint256);

  function getStartDay() external view returns (uint256);

  function getMaxYears() external view returns (uint256);

  function getStrongPoolDailyRewards(uint256 day) external view returns (uint256);

  function communityAccepted(address community) external view returns (bool);

  function getCommunities() external view returns (address[] memory);

  function upToDate() external view returns (bool);
}
