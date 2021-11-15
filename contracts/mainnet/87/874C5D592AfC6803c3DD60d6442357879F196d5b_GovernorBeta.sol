// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

pragma experimental ABIEncoderV2;

contract GovernorBeta {
  /// @notice The name of this contract
  string public constant name = "Cryptex Governor Beta";

  /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
  function quorumVotes() public pure returns (uint256) {
    return 400_000e18;
  } // 4% of Ctx

  /// @notice The number of votes required in order for a voter to become a proposer
  function proposalThreshold() public pure returns (uint256) {
    return 100_000e18;
  } // 1% of Ctx

  /// @notice The maximum number of actions that can be included in a proposal
  function proposalMaxOperations() public pure returns (uint256) {
    return 10;
  } // 10 actions

  /// @notice The delay before voting on a proposal may take place, once proposed
  function votingDelay() public pure returns (uint256) {
    return 1;
  } // 1 block

  /// @notice The duration of voting on a proposal, in blocks
  function votingPeriod() public pure returns (uint256) {
    return 17_280;
  } // ~3 days in blocks (assuming 15s blocks)

  /// @notice The address of the Ctx Protocol Timelock
  TimelockInterface public timelock;

  /// @notice The address of the Ctx governance token
  CtxInterface public ctx;

  /// @notice The total number of proposals
  uint256 public proposalCount;

  /// @notice Guardian of the governor
  address public guardian;

  /// @param id Unique id for looking up a proposal
  /// @param proposer Creator of the proposal
  /// @param eta The timestamp that the proposal will be available for execution, set once the vote succeeds
  /// @param targets the ordered list of target addresses for calls to be made
  /// @param values The ordered list of values (i.e. msg.value) to be passed to the calls to be made
  /// @param signatures The ordered list of function signatures to be called
  /// @param calldatas The ordered list of calldata to be passed to each call
  /// @param startBlock The block at which voting begins: holders must delegate their votes prior to this block
  /// @param endBlock The block at which voting ends: votes must be cast prior to this block
  /// @param forVotes Current number of votes in favor of this proposal
  /// @param againstVotes Current number of votes in opposition to this proposal
  /// @param canceled Flag marking whether the proposal has been canceled
  /// @param executed Flag marking whether the proposal has been executed
  struct Proposal {
    uint256 id;
    address proposer;
    uint256 eta;
    address[] targets;
    uint256[] values;
    string[] signatures;
    bytes[] calldatas;
    uint256 startBlock;
    uint256 endBlock;
    uint256 forVotes;
    uint256 againstVotes;
    bool canceled;
    bool executed;
  }

  /// @notice Receipts of ballots for the entire set of voters
  mapping(uint256 => mapping(address => Receipt)) public receipts;

  /// @notice Ballot receipt record for a voter
  /// @param hasVoted or not a vote has been cast
  /// @param support or not the voter supports the proposal
  /// @param votes number of votes the voter had, which were cast
  struct Receipt {
    bool hasVoted;
    bool support;
    uint96 votes;
  }

  /// @notice Possible states that a proposal may be in
  enum ProposalState {
    Pending,
    Active,
    Canceled,
    Defeated,
    Succeeded,
    Queued,
    Expired,
    Executed
  }

  /// @notice The official record of all proposals ever proposed
  mapping(uint256 => Proposal) public proposals;

  /// @notice The latest proposal for each proposer
  mapping(address => uint256) public latestProposalIds;

  /// @notice The EIP-712 typehash for the contract's domain
  bytes32 public constant DOMAIN_TYPEHASH =
    keccak256(
      "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
    );

  /// @notice The EIP-712 typehash for the ballot struct used by the contract
  bytes32 public constant BALLOT_TYPEHASH =
    keccak256("Ballot(uint256 proposalId,bool support)");

  /// @notice An event emitted when a new proposal is created
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

  /// @notice An event emitted when a vote has been cast on a proposal
  event VoteCast(
    address voter,
    uint256 proposalId,
    bool support,
    uint256 votes
  );

  /// @notice An event emitted when a proposal has been canceled
  event ProposalCanceled(uint256 id);

  /// @notice An event emitted when a proposal has been queued in the Timelock
  event ProposalQueued(uint256 id, uint256 eta);

  /// @notice An event emitted when a proposal has been executed in the Timelock
  event ProposalExecuted(uint256 id);

  constructor(
    address timelock_,
    address ctx_,
    address guardian_
  ) {
    timelock = TimelockInterface(timelock_);
    ctx = CtxInterface(ctx_);
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
      ctx.getPriorVotes(msg.sender, sub256(block.number, 1)) >
        proposalThreshold(),
      "GovernorBeta::propose: proposer votes below proposal threshold"
    );
    require(
      targets.length == values.length &&
        targets.length == signatures.length &&
        targets.length == calldatas.length,
      "GovernorBeta::propose: proposal function information arity mismatch"
    );
    require(targets.length != 0, "GovernorBeta::propose: must provide actions");
    require(
      targets.length <= proposalMaxOperations(),
      "GovernorBeta::propose: too many actions"
    );

    uint256 latestProposalId = latestProposalIds[msg.sender];
    if (latestProposalId != 0) {
      ProposalState proposersLatestProposalState = state(latestProposalId);
      require(
        proposersLatestProposalState != ProposalState.Active,
        "GovernorBeta::propose: one live proposal per proposer, found an already active proposal"
      );
      require(
        proposersLatestProposalState != ProposalState.Pending,
        "GovernorBeta::propose: one live proposal per proposer, found an already pending proposal"
      );
    }

    uint256 startBlock = add256(block.number, votingDelay());
    uint256 endBlock = add256(startBlock, votingPeriod());

    proposalCount++;
    Proposal memory newProposal =
      Proposal({
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
      "GovernorBeta::queue: proposal can only be queued if it is succeeded"
    );
    Proposal storage proposal = proposals[proposalId];
    uint256 eta = add256(block.timestamp, timelock.delay());
    for (uint256 i = 0; i < proposal.targets.length; i++) {
      _queueOrRevert(
        proposal.targets[i],
        proposal.values[i],
        proposal.signatures[i],
        proposal.calldatas[i],
        eta
      );
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
      !timelock.queuedTransactions(
        keccak256(abi.encode(target, value, signature, data, eta))
      ),
      "GovernorBeta::_queueOrRevert: proposal action already queued at eta"
    );
    timelock.queueTransaction(target, value, signature, data, eta);
  }

  /// @notice executes the transaction, but uses the msg.value from the eth stored in the timelock
  function execute(uint256 proposalId) public {
    require(
      state(proposalId) == ProposalState.Queued,
      "GovernorBeta::execute: proposal can only be executed if it is queued"
    );
    Proposal storage proposal = proposals[proposalId];
    proposal.executed = true;
    for (uint256 i = 0; i < proposal.targets.length; i++) {
      timelock.executeTransaction{value: 0}(
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
    ProposalState currentState = state(proposalId);
    require(
      currentState != ProposalState.Executed,
      "GovernorBeta::cancel: cannot cancel executed proposal"
    );

    Proposal storage proposal = proposals[proposalId];
    require(
      ctx.getPriorVotes(proposal.proposer, sub256(block.number, 1)) <
        proposalThreshold(),
      "GovernorBeta::cancel: proposer above threshold"
    );

    proposal.canceled = true;
    for (uint256 i = 0; i < proposal.targets.length; i++) {
      timelock.cancelTransaction(
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

  function getReceipt(uint256 proposalId, address voter)
    public
    view
    returns (Receipt memory)
  {
    require(
      proposalCount >= proposalId && proposalId > 0,
      "GovernorBeta::getReceipt: invalid proposal id"
    );
    return receipts[proposalId][voter];
  }

  function state(uint256 proposalId) public view returns (ProposalState) {
    require(
      proposalCount >= proposalId && proposalId > 0,
      "GovernorBeta::state: invalid proposal id"
    );
    Proposal storage proposal = proposals[proposalId];
    if (proposal.canceled) {
      return ProposalState.Canceled;
    } else if (block.number <= proposal.startBlock) {
      return ProposalState.Pending;
    } else if (block.number <= proposal.endBlock) {
      return ProposalState.Active;
    } else if (
      proposal.forVotes <= proposal.againstVotes ||
      proposal.forVotes < quorumVotes()
    ) {
      return ProposalState.Defeated;
    } else if (proposal.eta == 0) {
      return ProposalState.Succeeded;
    } else if (proposal.executed) {
      return ProposalState.Executed;
    } else if (
      block.timestamp >= add256(proposal.eta, timelock.GRACE_PERIOD())
    ) {
      return ProposalState.Expired;
    } else {
      return ProposalState.Queued;
    }
  }

  function castVote(uint256 proposalId, bool support) public {
    return _castVote(msg.sender, proposalId, support);
  }

  function castVoteBySig(
    uint256 proposalId,
    bool support,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public {
    bytes32 domainSeparator =
      keccak256(
        abi.encode(
          DOMAIN_TYPEHASH,
          keccak256(bytes(name)),
          getChainId(),
          address(this)
        )
      );
    bytes32 structHash =
      keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support));
    bytes32 digest =
      keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    address signatory = ecrecover(digest, v, r, s);
    require(
      signatory != address(0),
      "GovernorBeta::castVoteBySig: invalid signature"
    );
    return _castVote(signatory, proposalId, support);
  }

  function _castVote(
    address voter,
    uint256 proposalId,
    bool support
  ) internal {
    require(
      state(proposalId) == ProposalState.Active,
      "GovernorBeta::_castVote: voting is closed"
    );
    Proposal storage proposal = proposals[proposalId];
    Receipt storage receipt = receipts[proposalId][voter];
    require(
      receipt.hasVoted == false,
      "GovernorBeta::_castVote: voter already voted"
    );
    uint96 votes = ctx.getPriorVotes(voter, proposal.startBlock);

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

  function acceptTimelockAdmin() external {
    require(
      msg.sender == guardian,
      "GovernorBeta::acceptTimelockAdmin: only guardian can call this function"
    );
    timelock.acceptAdmin();
  }

  function add256(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "addition overflow");
    return c;
  }

  function sub256(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "subtraction underflow");
    return a - b;
  }

  function getChainId() internal pure returns (uint256) {
    uint256 chainId;
    assembly {
      chainId := chainid()
    }
    return chainId;
  }
}

interface TimelockInterface {
  function delay() external view returns (uint256);

  function GRACE_PERIOD() external view returns (uint256);

  function acceptAdmin() external;

  function queuedTransactions(bytes32 hash) external view returns (bool);

  function queueTransaction(
    address target,
    uint256 value,
    string calldata signature,
    bytes calldata data,
    uint256 eta
  ) external returns (bytes32);

  function cancelTransaction(
    address target,
    uint256 value,
    string calldata signature,
    bytes calldata data,
    uint256 eta
  ) external;

  function executeTransaction(
    address target,
    uint256 value,
    string calldata signature,
    bytes calldata data,
    uint256 eta
  ) external payable returns (bytes memory);
}

interface CtxInterface {
  function getPriorVotes(address account, uint256 blockNumber)
    external
    view
    returns (uint96);
}

