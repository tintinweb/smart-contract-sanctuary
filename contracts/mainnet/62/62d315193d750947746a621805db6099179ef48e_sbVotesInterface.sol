// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface sbVotesInterface {
  function getPriorProposalVotes(address account, uint256 blockNumber) external view returns (uint96);

  function updateVotes(
    address staker,
    uint256 rawAmount,
    bool adding
  ) external;
}
