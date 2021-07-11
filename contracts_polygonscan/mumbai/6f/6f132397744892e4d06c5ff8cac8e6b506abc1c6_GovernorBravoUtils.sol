// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.3;

import "./GovernorBravoInterfaces.sol";

library GovernorBravoUtils {
  function add256(uint256 a, uint256 b) public pure returns (uint) {
    uint c = a + b;
    require(c >= a, "addition overflow");
    return c;
  }

  function sub256(uint256 a, uint256 b) public pure returns (uint) {
    require(b <= a, "subtraction underflow");
    return a - b;
  }

  function getChainIdInternal() public view returns (uint) {
    uint chainId;
    assembly { chainId := chainid() }
    return chainId;
  }
}

library GovernorBravoProposalUtils {
  function cancel(
    GovernorBravoDelegateStorageV1.Proposal storage self,
    CompInterface comp,
    TimelockInterface timelock,
    uint proposalThreshold
  ) external {
    require(msg.sender == self.proposer || comp.getPriorVotes(self.proposer, GovernorBravoUtils.sub256(block.number, 1)) < proposalThreshold, "GovernorBravo::cancel: proposer above threshold");

    self.canceled = true;
    for (uint i = 0; i < self.targets.length; i++) {
      timelock.cancelTransaction(self.targets[i], self.values[i], self.signatures[i], self.calldatas[i], self.eta);
    }
  }

  function castVote(
    GovernorBravoDelegateStorageV1.Proposal storage self,
    CompInterface comp,
    address voter,
    uint8 support
  ) external returns (uint96) {
    GovernorBravoDelegateStorageV1.Receipt storage receipt = self.receipts[voter];
    require(receipt.hasVoted == false, "GovernorBravo::castVoteInternal: voter already voted");
    uint96 votes = comp.getPriorVotes(voter, self.startBlock);

    if (support == 0) {
      self.againstVotes = GovernorBravoUtils.add256(self.againstVotes, votes);
    } else if (support == 1) {
      self.forVotes = GovernorBravoUtils.add256(self.forVotes, votes);
    } else if (support == 2) {
      self.abstainVotes = GovernorBravoUtils.add256(self.abstainVotes, votes);
    }

    receipt.hasVoted = true;
    receipt.support = support;
    receipt.votes = votes;

    return votes;
  }

  function execute(
    GovernorBravoDelegateStorageV1.Proposal storage self,
    TimelockInterface timelock
  ) external {
    self.executed = true;
    for (uint i = 0; i < self.targets.length; i++) {
      timelock.executeTransaction{value:self.values[i]}(self.targets[i], self.values[i], self.signatures[i], self.calldatas[i], self.eta);
    }
  }

  function getState(
    GovernorBravoDelegateStorageV1.Proposal storage self,
    uint gracePeriod,
    uint quorumVotes
  ) public view returns (GovernorBravoDelegateStorageV1.ProposalState) {
    if (self.canceled) {
      return GovernorBravoDelegateStorageV1.ProposalState.Canceled;
    } else if (block.number <= self.startBlock) {
      return GovernorBravoDelegateStorageV1.ProposalState.Pending;
    } else if (block.number <= self.endBlock) {
      return GovernorBravoDelegateStorageV1.ProposalState.Active;
    } else if (self.forVotes <= self.againstVotes || self.forVotes < quorumVotes) {
      return GovernorBravoDelegateStorageV1.ProposalState.Defeated;
    } else if (self.eta == 0) {
      return GovernorBravoDelegateStorageV1.ProposalState.Succeeded;
    } else if (self.executed) {
      return GovernorBravoDelegateStorageV1.ProposalState.Executed;
    } else if (
      block.timestamp >= GovernorBravoUtils.add256(self.eta, gracePeriod)
    ) {
      return GovernorBravoDelegateStorageV1.ProposalState.Expired;
    } else {
      return GovernorBravoDelegateStorageV1.ProposalState.Queued;
    }
  }

  function queue(
    GovernorBravoDelegateStorageV1.Proposal storage self,
    TimelockInterface timelock
  ) external returns (uint) {
    uint eta = GovernorBravoUtils.add256(block.timestamp, timelock.delay());
    for (uint i = 0; i < self.targets.length; i++) {
      queueOrRevertInternal(timelock, self.targets[i], self.values[i], self.signatures[i], self.calldatas[i], eta);
    }
    self.eta = eta;
    return eta;
  }

  function queueOrRevertInternal(
    TimelockInterface timelock,
    address target,
    uint value,
    string memory signature,
    bytes memory data,
    uint eta
  ) internal {
    require(!timelock.queuedTransactions(keccak256(abi.encode(target, value, signature, data, eta))), "GovernorBravo::queueOrRevertInternal: identical proposal action already queued at eta");
    timelock.queueTransaction(target, value, signature, data, eta);
  }
}