// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../interfaces/ITimelock.sol";


contract GovernorAlpha {
  /// @dev The name of this contract
  string public constant name = "BiShares Governor Alpha";
  
  /// @dev The voting period which will be set after setVotingPeriodAfter has passed.
  uint256 public constant permanentVotingPeriod = 17_280; // ~3 days in blocks (assuming 15s blocks)

  /**
   * @dev The number of votes in support of a proposal required in order for a
   * quorum to be reached and for a vote to succeed
   */ 
  function quorumVotes() public pure returns (uint256) {
    return 400_000e18; // 4% of BISON
  }

  /**
   * @dev The number of votes required in order for a voter to become a proposer
   */
  function proposalThreshold() public pure returns (uint256) {
    return 100_000e18; // 1% of BISON
  }

  /**
   * @dev The maximum number of actions that can be included in a proposal
   */
  function proposalMaxOperations() public pure returns (uint256) {
    return 10;
  }

  /**
   * @dev The delay before voting on a proposal may take place, once proposed
   */
  function votingDelay() public pure returns (uint256) {
    return 1;
  }

  /**
   * @dev The duration of voting on a proposal, in blocks
   */
  uint256 public votingPeriod = 2_880; // ~12 hours in blocks (assuming 15s blocks)

  /**
   * @dev The timestamp after which votingPeriod can be set to the permanent value.
   */
  uint256 public immutable setVotingPeriodAfter;

  /**
   * @dev The address of the Bishares Protocol Timelock
   */
  ITimelock public immutable timelock;

  /**
   * @dev The address of the Bishares governance token
   */
  BisonInterface public immutable bison;

  /**
   * @dev The total number of proposals
   */
  uint256 public proposalCount;

  /**
   * @param id Unique id for looking up a proposal
   * @param proposer Creator of the proposal
   * @param eta The timestamp that the proposal will be available for execution, set once the vote succeeds
   * @param targets The ordered list of target addresses for calls to be made
   * @param values The ordered list of values (i.e. msg.value) to be passed to the calls to be made
   * @param signatures The ordered list of function signatures to be called
   * @param calldatas The ordered list of calldata to be passed to each call
   * @param startBlock The block at which voting begins: holders must delegate their votes prior to this block
   * @param endBlock The block at which voting ends: votes must be cast prior to this block
   * @param forVotes Current number of votes in favor of this proposal
   * @param againstVotes Current number of votes in opposition to this proposal
   * @param canceled Flag marking whether the proposal has been canceled
   * @param executed Flag marking whether the proposal has been executed
   * @param receipts Receipts of ballots for the entire set of voters
   */
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
    mapping(address => Receipt) receipts;
  }

  /**
   * @dev Ballot receipt record for a voter
   * @param hasVoted Whether or not a vote has been cast
   * @param support Whether or not the voter supports the proposal
   * @param votes The number of votes the voter had, which were cast
   */
  struct Receipt {
    bool hasVoted;
    bool support;
    uint96 votes;
  }

  /**
   * @dev Possible states that a proposal may be in
   */
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

  /**
   * @dev The official record of all proposals ever proposed
   */
  mapping(uint256 => Proposal) public proposals;

  /**
   * @dev The latest proposal for each proposer
   */
  mapping(address => uint256) public latestProposalIds;

  /**
   * @dev The EIP-712 typehash for the contract's domain
   */
  bytes32 public constant DOMAIN_TYPEHASH = keccak256(
    "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
  );

  /**
   * @dev The EIP-712 typehash for the ballot struct used by the contract
   */
  bytes32 public constant BALLOT_TYPEHASH = keccak256(
    "Ballot(uint256 proposalId,bool support)"
  );

  /**
   * @dev An event emitted when a new proposal is created
   */
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

  /**
   * @dev An event emitted when a vote has been cast on a proposal
   */
  event VoteCast(
    address voter,
    uint256 proposalId,
    bool support,
    uint256 votes
  );

  /**
   * @dev An event emitted when a proposal has been canceled
   */
  event ProposalCanceled(uint256 id);

  /**
   * @dev An event emitted when a proposal has been queued in the Timelock
   */
  event ProposalQueued(uint256 id, uint256 eta);

  /**
   * @dev An event emitted when a proposal has been executed in the Timelock
   */
  event ProposalExecuted(uint256 id);

  constructor(address timelock_, address bison_, uint256 setVotingPeriodAfter_) public {
    timelock = ITimelock(timelock_);
    bison = BisonInterface(bison_);
    setVotingPeriodAfter = setVotingPeriodAfter_;
  }

  /**
   * @dev Sets votingPeriod to the permanent value.
   * Can only be called after setVotingPeriodAfter
   */
  function setPermanentVotingPeriod() external {
    require(
      block.timestamp >= setVotingPeriodAfter,
      "GovernorAlpha::setPermanentVotingPeriod: setting permanent voting period not allowed yet"
    );
    votingPeriod = permanentVotingPeriod;
  }

  function propose(
    address[] memory targets,
    uint256[] memory values,
    string[] memory signatures,
    bytes[] memory calldatas,
    string memory description
  ) public returns (uint256) {
    require(
      bison.getPriorVotes(msg.sender, sub256(block.number, 1)) >
        proposalThreshold(),
      "GovernorAlpha::propose: proposer votes below proposal threshold"
    );
    require(
      targets.length == values.length &&
        targets.length == signatures.length &&
        targets.length == calldatas.length,
      "GovernorAlpha::propose: proposal function information arity mismatch"
    );
    require(
      targets.length != 0,
      "GovernorAlpha::propose: must provide actions"
    );
    require(
      targets.length <= proposalMaxOperations(),
      "GovernorAlpha::propose: too many actions"
    );

    uint256 latestProposalId = latestProposalIds[msg.sender];
    if (latestProposalId != 0) {
      ProposalState proposersLatestProposalState = state(latestProposalId);
      require(
        proposersLatestProposalState != ProposalState.Active,
        "GovernorAlpha::propose: one live proposal per proposer, found an already active proposal"
      );
      require(
        proposersLatestProposalState != ProposalState.Pending,
        "GovernorAlpha::propose: one live proposal per proposer, found an already pending proposal"
      );
    }

    uint256 startBlock = add256(block.number, votingDelay());
    uint256 endBlock = add256(startBlock, votingPeriod);

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
      "GovernorAlpha::queue: proposal can only be queued if it is succeeded"
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
      "GovernorAlpha::_queueOrRevert: proposal action already queued at eta"
    );
    timelock.queueTransaction(target, value, signature, data, eta);
  }

  function execute(uint256 proposalId) public payable {
    require(
      state(proposalId) == ProposalState.Queued,
      "GovernorAlpha::execute: proposal can only be executed if it is queued"
    );
    Proposal storage proposal = proposals[proposalId];
    proposal.executed = true;
    for (uint256 i = 0; i < proposal.targets.length; i++) {
      timelock.executeTransaction.value(proposal.values[i])(
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
    require(
      state != ProposalState.Executed,
      "GovernorAlpha::cancel: cannot cancel executed proposal"
    );

    Proposal storage proposal = proposals[proposalId];
    require(
      bison.getPriorVotes(proposal.proposer, sub256(block.number, 1)) <
        proposalThreshold(),
      "GovernorAlpha::cancel: proposer above threshold"
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
    return proposals[proposalId].receipts[voter];
  }

  function state(uint256 proposalId) public view returns (ProposalState) {
    require(
      proposalCount >= proposalId && proposalId > 0,
      "GovernorAlpha::state: invalid proposal id"
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
    bytes32 domainSeparator = keccak256(
      abi.encode(
        DOMAIN_TYPEHASH,
        keccak256(bytes(name)),
        getChainId(),
        address(this)
      )
    );
    bytes32 structHash = keccak256(
      abi.encode(BALLOT_TYPEHASH, proposalId, support)
    );
    bytes32 digest = keccak256(
      abi.encodePacked("\x19\x01", domainSeparator, structHash)
    );
    address signatory = ecrecover(digest, v, r, s);
    require(
      signatory != address(0),
      "GovernorAlpha::castVoteBySig: invalid signature"
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
      "GovernorAlpha::_castVote: voting is closed"
    );
    Proposal storage proposal = proposals[proposalId];
    Receipt storage receipt = proposal.receipts[voter];
    require(
      receipt.hasVoted == false,
      "GovernorAlpha::_castVote: voter already voted"
    );
    uint96 votes = bison.getPriorVotes(voter, proposal.startBlock);

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

interface BisonInterface {
  function getPriorVotes(address account, uint256 blockNumber)
    external
    view
    returns (uint96);
}

pragma solidity ^0.6.0;


interface ITimelock {
  event NewAdmin(address indexed newAdmin);
  event NewDelay(uint256 indexed newDelay);
  event CancelTransaction(
    bytes32 indexed txHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 eta
  );
  event ExecuteTransaction(
    bytes32 indexed txHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 eta
  );
  event QueueTransaction(
    bytes32 indexed txHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 eta
  );

  function GRACE_PERIOD() external pure returns (uint256);
  
  function MINIMUM_DELAY() external pure returns (uint256);
  
  function MAXIMUM_DELAY() external pure returns (uint256);

  function admin() external view returns (address);

  function pendingAdmin() external view returns (address);

  function delay() external view returns (uint256);

  function queuedTransactions(bytes32) external view returns (bool);

  function setDelay(uint256 delay_) external;

  function setAdmin(address admin_) external;

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

