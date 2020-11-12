// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import './sbVotesInterface.sol';
import './sbTimelockInterface.sol';

contract sbGovernor {
  // The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
  function quorumVotes() public pure returns (uint256) {
    return 400000e18;
  } // 400,000 = 4% of STRONG

  // The number of votes required in order for a voter to become a proposer
  function proposalThreshold() public pure returns (uint256) {
    return 100000e18;
  } // 100,000 = 1% of STRONG

  // The maximum number of actions that can be included in a proposal
  function proposalMaxOperations() public pure returns (uint256) {
    return 10;
  } // 10 actions

  // The delay before voting on a proposal may take place, once proposed
  function votingDelay() public pure returns (uint256) {
    return 1;
  } // 1 block

  // The duration of voting on a proposal, in blocks
  function votingPeriod() public pure returns (uint256) {
    return 17280;
  } // ~3 days in blocks (assuming 15s blocks)

  // The address of the StrongBlock Protocol Timelock
  sbTimelockInterface public sbTimelock;

  // The address of the sbVotes contract
  sbVotesInterface public sbVotes;

  // The address of the Governor Guardian
  address public guardian;

  // The total number of proposals
  uint256 public proposalCount;

  struct Proposal {
    // Unique id for looking up a proposal
    uint256 id;
    // Creator of the proposal
    address proposer;
    // The timestamp that the proposal will be available for execution, set once the vote succeeds
    uint256 eta;
    // the ordered list of target addresses for calls to be made
    address[] targets;
    // The ordered list of values (i.e. msg.value) to be passed to the calls to be made
    uint256[] values;
    // The ordered list of function signatures to be called
    string[] signatures;
    // The ordered list of calldata to be passed to each call
    bytes[] calldatas;
    // The block at which voting begins: holders must delegate their votes prior to this block
    uint256 startBlock;
    // The block at which voting ends: votes must be cast prior to this block
    uint256 endBlock;
    // Current number of votes in favor of this proposal
    uint256 forVotes;
    // Current number of votes in opposition to this proposal
    uint256 againstVotes;
    // Flag marking whether the proposal has been canceled
    bool canceled;
    // Flag marking whether the proposal has been executed
    bool executed;
    // Receipts of ballots for the entire set of voters
    mapping(address => Receipt) receipts;
  }

  // Ballot receipt record for a voter
  struct Receipt {
    // Whether or not a vote has been cast
    bool hasVoted;
    // Whether or not the voter supports the proposal
    bool support;
    // The number of votes the voter had, which were cast
    uint96 votes;
  }

  // Possible states that a proposal may be in
  enum ProposalState { Pending, Active, Canceled, Defeated, Succeeded, Queued, Expired, Executed }

  // The official record of all proposals ever proposed
  mapping(uint256 => Proposal) public proposals;

  // The latest proposal for each proposer
  mapping(address => uint256) public latestProposalIds;

  // An event emitted when a new proposal is created
  event ProposalCreated(
    uint256 id,
    address proposer,
    address[] targets,
    uint256[] values,
    string[] signatures,
    bytes[] calldatas,
    uint256 startBlock,
    uint256 endBlock,
    string description
  );

  // An event emitted when a vote has been cast on a proposal
  event VoteCast(address voter, uint256 proposalId, bool support, uint256 votes);

  // An event emitted when a proposal has been canceled
  event ProposalCanceled(uint256 id);

  // An event emitted when a proposal has been queued in the Timelock
  event ProposalQueued(uint256 id, uint256 eta);

  // An event emitted when a proposal has been executed in the Timelock
  event ProposalExecuted(uint256 id);

  constructor(
    address sbTimelockAddress,
    address sbVotesAddress,
    address guardian_
  ) public {
    sbTimelock = sbTimelockInterface(sbTimelockAddress);
    sbVotes = sbVotesInterface(sbVotesAddress);
    guardian = guardian_;
  }

  function propose(
    address[] memory targets,
    uint256[] memory values,
    string[] memory signatures,
    bytes[] memory calldatas,
    string memory description
  ) public returns (uint256) {
    require(
      sbVotes.getPriorProposalVotes(msg.sender, sub256(block.number, 1)) > proposalThreshold(),
      'sbGovernor::propose: proposer votes below proposal threshold'
    );
    require(
      targets.length == values.length && targets.length == signatures.length && targets.length == calldatas.length,
      'sbGovernor::propose: proposal function information arity mismatch'
    );
    require(targets.length != 0, 'sbGovernor::propose: must provide actions');
    require(targets.length <= proposalMaxOperations(), 'sbGovernor::propose: too many actions');

    uint256 latestProposalId = latestProposalIds[msg.sender];
    if (latestProposalId != 0) {
      ProposalState proposersLatestProposalState = state(latestProposalId);
      require(
        proposersLatestProposalState != ProposalState.Active,
        'sbGovernor::propose: one live proposal per proposer, found an already active proposal'
      );
      require(
        proposersLatestProposalState != ProposalState.Pending,
        'sbGovernor::propose: one live proposal per proposer, found an already pending proposal'
      );
    }

    uint256 startBlock = add256(block.number, votingDelay());
    uint256 endBlock = add256(startBlock, votingPeriod());

    proposalCount++;
    Proposal memory newProposal = Proposal({
      id: proposalCount,
      proposer: msg.sender,
      eta: 0,
      targets: targets,
      values: values,
      signatures: signatures,
      calldatas: calldatas,
      startBlock: startBlock,
      endBlock: endBlock,
      forVotes: 0,
      againstVotes: 0,
      canceled: false,
      executed: false
    });

    proposals[newProposal.id] = newProposal;
    latestProposalIds[newProposal.proposer] = newProposal.id;

    emit ProposalCreated(
      newProposal.id,
      msg.sender,
      targets,
      values,
      signatures,
      calldatas,
      startBlock,
      endBlock,
      description
    );
    return newProposal.id;
  }

  function queue(uint256 proposalId) public {
    require(
      state(proposalId) == ProposalState.Succeeded,
      'sbGovernor::queue: proposal can only be queued if it is succeeded'
    );
    Proposal storage proposal = proposals[proposalId];
    uint256 eta = add256(block.timestamp, sbTimelock.delay());
    for (uint256 i = 0; i < proposal.targets.length; i++) {
      _queueOrRevert(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], eta);
    }
    proposal.eta = eta;
    emit ProposalQueued(proposalId, eta);
  }

  function _queueOrRevert(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 eta
  ) internal {
    require(
      !sbTimelock.queuedTransactions(keccak256(abi.encode(target, value, signature, data, eta))),
      'sbGovernor::_queueOrRevert: proposal action already queued at eta'
    );
    sbTimelock.queueTransaction(target, value, signature, data, eta);
  }

  function execute(uint256 proposalId) public payable {
    require(
      state(proposalId) == ProposalState.Queued,
      'sbGovernor::execute: proposal can only be executed if it is queued'
    );
    Proposal storage proposal = proposals[proposalId];
    proposal.executed = true;
    for (uint256 i = 0; i < proposal.targets.length; i++) {
      sbTimelock.executeTransaction{ value: proposal.values[i] }(
        proposal.targets[i],
        proposal.values[i],
        proposal.signatures[i],
        proposal.calldatas[i],
        proposal.eta
      );
    }
    emit ProposalExecuted(proposalId);
  }

  function cancel(uint256 proposalId) public {
    ProposalState state = state(proposalId);
    require(state != ProposalState.Executed, 'sbGovernor::cancel: cannot cancel executed proposal');

    Proposal storage proposal = proposals[proposalId];
    require(
      msg.sender == guardian ||
        sbVotes.getPriorProposalVotes(proposal.proposer, sub256(block.number, 1)) < proposalThreshold(),
      'sbGovernor::cancel: proposer above threshold'
    );

    proposal.canceled = true;
    for (uint256 i = 0; i < proposal.targets.length; i++) {
      sbTimelock.cancelTransaction(
        proposal.targets[i],
        proposal.values[i],
        proposal.signatures[i],
        proposal.calldatas[i],
        proposal.eta
      );
    }

    emit ProposalCanceled(proposalId);
  }

  function getActions(uint256 proposalId)
    public
    view
    returns (
      address[] memory targets,
      uint256[] memory values,
      string[] memory signatures,
      bytes[] memory calldatas
    )
  {
    Proposal storage p = proposals[proposalId];
    return (p.targets, p.values, p.signatures, p.calldatas);
  }

  function getReceipt(uint256 proposalId, address voter) public view returns (Receipt memory) {
    return proposals[proposalId].receipts[voter];
  }

  function state(uint256 proposalId) public view returns (ProposalState) {
    require(proposalCount >= proposalId && proposalId > 0, 'sbGovernor::state: invalid proposal id');
    Proposal storage proposal = proposals[proposalId];
    if (proposal.canceled) {
      return ProposalState.Canceled;
    } else if (block.number <= proposal.startBlock) {
      return ProposalState.Pending;
    } else if (block.number <= proposal.endBlock) {
      return ProposalState.Active;
    } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < quorumVotes()) {
      return ProposalState.Defeated;
    } else if (proposal.eta == 0) {
      return ProposalState.Succeeded;
    } else if (proposal.executed) {
      return ProposalState.Executed;
    } else if (block.timestamp >= add256(proposal.eta, sbTimelock.GRACE_PERIOD())) {
      return ProposalState.Expired;
    } else {
      return ProposalState.Queued;
    }
  }

  function castVote(uint256 proposalId, bool support) public {
    return _castVote(msg.sender, proposalId, support);
  }

  function _castVote(
    address voter,
    uint256 proposalId,
    bool support
  ) internal {
    require(state(proposalId) == ProposalState.Active, 'sbGovernor::_castVote: voting is closed');
    Proposal storage proposal = proposals[proposalId];
    Receipt storage receipt = proposal.receipts[voter];
    require(receipt.hasVoted == false, 'sbGovernor::_castVote: voter already voted');
    uint96 votes = sbVotes.getPriorProposalVotes(voter, proposal.startBlock);

    if (support) {
      proposal.forVotes = add256(proposal.forVotes, votes);
    } else {
      proposal.againstVotes = add256(proposal.againstVotes, votes);
    }

    receipt.hasVoted = true;
    receipt.support = support;
    receipt.votes = votes;

    emit VoteCast(voter, proposalId, support, votes);
  }

  function __acceptAdmin() public {
    require(msg.sender == guardian, 'sbGovernor::__acceptAdmin: sender must be gov guardian');
    sbTimelock.acceptAdmin();
  }

  function __abdicate() public {
    require(msg.sender == guardian, 'sbGovernor::__abdicate: sender must be gov guardian');
    guardian = address(0);
  }

  function __queueSetTimelockPendingAdmin(address newPendingAdmin, uint256 eta) public {
    require(msg.sender == guardian, 'sbGovernor::__queueSetTimelockPendingAdmin: sender must be gov guardian');
    sbTimelock.queueTransaction(address(sbTimelock), 0, 'setPendingAdmin(address)', abi.encode(newPendingAdmin), eta);
  }

  function __executeSetTimelockPendingAdmin(address newPendingAdmin, uint256 eta) public {
    require(msg.sender == guardian, 'sbGovernor::__executeSetTimelockPendingAdmin: sender must be gov guardian');
    sbTimelock.executeTransaction(address(sbTimelock), 0, 'setPendingAdmin(address)', abi.encode(newPendingAdmin), eta);
  }

  function add256(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'addition overflow');
    return c;
  }

  function sub256(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, 'subtraction underflow');
    return a - b;
  }
}
