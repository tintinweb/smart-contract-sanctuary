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

/// @notice This Module has a 1/3 participation threshold with at least 1% of TVL required to create proposals.
/// This is useful for acting as relaxed multisigs.
// Audit-1: ok
contract OneThirdParticipationThreshold is IModule {
  /// @notice Called if a proposal gets created.
  /// Requirements:
  /// - proposerBalance needs to be at least 1% of TVL.
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
    uint256 minProposerBalance = totalValueLocked / 100;
    require(
      proposerBalance >= minProposerBalance,
      'Not enough balance'
    );
  }

  /// @notice A proposal is open until at least 1/3 from `totalMemberCount` cast a vote.
  /// Depending on the average voting signal, the proposal passes if `averageSignal` > 50.
  function onProcessProposal (
    bytes32 /*proposalId*/,
    bytes32 /*communityId*/,
    uint256 totalMemberCount,
    uint256 totalVoteCount,
    uint256 /*totalVotingShares*/,
    uint256 totalVotingSignal,
    uint256 /*totalValueLocked*/,
    uint256 secondsPassed
  ) external pure override returns (VotingStatus, uint256, uint256) {

    if (totalVoteCount == 0 || secondsPassed < 1) {
      return (VotingStatus.OPEN, uint256(-1), 0);
    }

    uint256 oneThird = totalMemberCount / 3;
    // assuming totalVoteCount does not overflow here
    uint256 quorum = (totalVoteCount * 100) / (oneThird == 0 ? 1 : oneThird);

    if (quorum > 99) {
      uint256 averageSignal = totalVotingSignal / totalVoteCount;
      if (averageSignal > 50) {
        return (VotingStatus.PASSED, 0, quorum);
      } else {
        return (VotingStatus.CLOSED, 0, quorum);
      }
    }

    return (VotingStatus.OPEN, 0, quorum);
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