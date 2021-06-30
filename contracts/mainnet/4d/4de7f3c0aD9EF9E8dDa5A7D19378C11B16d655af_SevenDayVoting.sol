// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.6;

// Audit-1: ok
interface IModule {
  enum VotingStatus {
    UNKNOWN,
    OPEN,
    CLOSED,
    PASSED
  }

  function onCreateProposal (
    bytes32 communityId,
    uint256 totalMemberCount,
    uint256 totalValueLocked,
    address proposer,
    uint256 proposerBalance,
    uint256 startDate,
    bytes calldata internalActions,
    bytes calldata externalActions
  ) external view;

  function onProcessProposal (
    bytes32 proposalId,
    bytes32 communityId,
    uint256 totalMemberCount,
    uint256 totalVoteCount,
    uint256 totalVotingShares,
    uint256 totalVotingSignal,
    uint256 totalValueLocked,
    uint256 secondsPassed
  ) external view returns (VotingStatus, uint256 secondsTillClose, uint256 quorumPercent);
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.6;

import '../IModule.sol';

/// @notice Seven Day Voting - Simple Majority Voting.
/// Used for protocol upgrades and funding proposals.
/// * 7 day voting period.
/// * Quorum >= 10%.
/// * 0.1% of TVL needed to propose.
/// * A proposal passes if the total signal (average preference) is over 50% (YES).
// Audit-1: ok
contract SevenDayVoting is IModule {
  /// @notice Called on proposal creation.
  /// Checks if `proposerBalance` is at least TVL / 1000 (0.1%)
  function onCreateProposal (
    bytes32 /*communityId*/,
    uint256 /*totalMemberCount*/,
    uint256 totalValueLocked,
    address /*proposer*/,
    uint256 proposerBalance,
    uint256 /*startDate*/,
    bytes calldata /*internalActions*/,
    bytes calldata /*externalActions*/
  ) external pure override
  {
    uint256 minProposerBalance = totalValueLocked / 1000;
    require(
      proposerBalance >= minProposerBalance,
      'Not enough balance'
    );
  }

  /// @notice See requirements for this contract.
  function onProcessProposal (
    bytes32 /*proposalId*/,
    bytes32 /*communityId*/,
    uint256 /*totalMemberCount*/,
    uint256 totalVoteCount,
    uint256 totalVotingShares,
    uint256 totalVotingSignal,
    uint256 totalValueLocked,
    uint256 secondsPassed
  ) external pure override returns (VotingStatus, uint256, uint256) {
    // 7 days
    uint256 VOTING_DURATION = 604800;
    uint256 secondsTillClose = secondsPassed > VOTING_DURATION ? 0 : VOTING_DURATION - secondsPassed;
    uint256 minQuorum = totalValueLocked / 10;
    // both variables are used for frontend purposes
    // assuming `totalValueLocked` can not be over `totalVotingShares`
    uint256 onePercent = totalValueLocked / 100;
    uint256 q = onePercent == 0 ? 0 : totalVotingShares / onePercent;

    // Proposal stays open if VOTING_DURATION has not yet passed.
    if (secondsPassed < VOTING_DURATION) {
      return (VotingStatus.OPEN, secondsTillClose, q);
    }

    // Proposal is closed if less than 10% of TVL voted on this proposal.
    if (totalVotingShares < minQuorum || totalVoteCount == 0) {
      return (VotingStatus.CLOSED, secondsTillClose, q);
    }

    // at this point we reached the `minQuorum` requirement.
    // `totalVoteCount` can not be 0 here.
    uint256 averageSignal = totalVotingSignal / totalVoteCount;
    if (averageSignal > 50) {
      return (VotingStatus.PASSED, secondsTillClose, q);
    }

    // defaults to closed if `averageSignal` is not reached
    return (VotingStatus.CLOSED, secondsTillClose, q);
  }
}

{
  "evmVersion": "berlin",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "none"
  },
  "optimizer": {
    "details": {
      "constantOptimizer": true,
      "cse": true,
      "deduplicate": true,
      "jumpdestRemover": true,
      "orderLiterals": false,
      "peephole": true,
      "yul": false
    },
    "runs": 256
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}