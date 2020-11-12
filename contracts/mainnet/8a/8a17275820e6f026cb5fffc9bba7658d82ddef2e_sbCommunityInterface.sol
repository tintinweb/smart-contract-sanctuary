// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface sbCommunityInterface {
  function getTokenData(address token, uint256 day)
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    );

  function receiveRewards(uint256 day, uint256 amount) external;

  function serviceAccepted(address service) external view returns (bool);

  function getMinerRewardPercentage() external view returns (uint256);
}
