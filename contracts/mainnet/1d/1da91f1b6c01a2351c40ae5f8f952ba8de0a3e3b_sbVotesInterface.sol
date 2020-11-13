// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface sbVotesInterface {
  function getCommunityData(address community, uint256 day)
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    );

  function getPriorProposalVotes(address account, uint256 blockNumber) external view returns (uint96);

  function receiveServiceRewards(uint256 day, uint256 amount) external;

  function receiveVoterRewards(uint256 day, uint256 amount) external;

  function updateVotes(
    address staker,
    uint256 rawAmount,
    bool adding
  ) external;
}
