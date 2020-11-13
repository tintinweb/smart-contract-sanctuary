/*
https://powerpool.finance/

          wrrrw r wrr
         ppwr rrr wppr0       prwwwrp                                 prwwwrp                   wr0
        rr 0rrrwrrprpwp0      pp   pr  prrrr0 pp   0r  prrrr0  0rwrrr pp   pr  prrrr0  prrrr0    r0
        rrp pr   wr00rrp      prwww0  pp   wr pp w00r prwwwpr  0rw    prwww0  pp   wr pp   wr    r0
        r0rprprwrrrp pr0      pp      wr   pr pp rwwr wr       0r     pp      wr   pr wr   pr    r0
         prwr wrr0wpwr        00        www0   0w0ww    www0   0w     00        www0    www0   0www0
          wrr ww0rrrr

*/

// File: powerpool-governance/contracts/interfaces/CvpInterface.sol

pragma solidity ^0.5.16;

interface CvpInterface {
  /// @notice EIP-20 token name for this token
  function name() external view returns (string memory);

  /// @notice EIP-20 token symbol for this token
  function symbol() external view returns (string memory);

  /// @notice EIP-20 token decimals for this token
  function decimals() external view returns (uint8);

  /// @notice Total number of tokens in circulation
  function totalSupply() external view returns (uint);

  /// @notice A record of each accounts delegate
  function delegates(address _addr) external view returns (address);

  /// @notice The number of checkpoints for each account
  function numCheckpoints(address _addr) external view returns (uint32);

  /// @notice The EIP-712 typehash for the contract's domain
  function DOMAIN_TYPEHASH() external view returns (bytes32);

  /// @notice The EIP-712 typehash for the delegation struct used by the contract
  function DELEGATION_TYPEHASH() external view returns (bytes32);

  /// @notice A record of states for signing / validating signatures
  function nonces(address _addr) external view returns (uint);

  /// @notice An event thats emitted when an account changes its delegate
  event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

  /// @notice An event thats emitted when a delegate account's vote balance changes
  event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

  /// @notice The standard EIP-20 transfer event
  event Transfer(address indexed from, address indexed to, uint256 amount);

  /// @notice The standard EIP-20 approval event
  event Approval(address indexed owner, address indexed spender, uint256 amount);

  /**
   * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
   * @param account The address of the account holding the funds
   * @param spender The address of the account spending the funds
   * @return The number of tokens approved
   */
  function allowance(address account, address spender) external view returns (uint);

  /**
   * @notice Approve `spender` to transfer up to `amount` from `src`
   * @dev This will overwrite the approval amount for `spender`
   *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
   * @param spender The address of the account which may transfer tokens
   * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
   * @return Whether or not the approval succeeded
   */
  function approve(address spender, uint rawAmount) external returns (bool);

  /**
   * @notice Get the number of tokens held by the `account`
   * @param account The address of the account to get the balance of
   * @return The number of tokens held
   */
  function balanceOf(address account) external view returns (uint);

  /**
   * @notice Transfer `amount` tokens from `msg.sender` to `dst`
   * @param dst The address of the destination account
   * @param rawAmount The number of tokens to transfer
   * @return Whether or not the transfer succeeded
   */
  function transfer(address dst, uint rawAmount) external returns (bool);

  /**
   * @notice Transfer `amount` tokens from `src` to `dst`
   * @param src The address of the source account
   * @param dst The address of the destination account
   * @param rawAmount The number of tokens to transfer
   * @return Whether or not the transfer succeeded
   */
  function transferFrom(address src, address dst, uint rawAmount) external returns (bool);

  /**
   * @notice Delegate votes from `msg.sender` to `delegatee`
   * @param delegatee The address to delegate votes to
   */
  function delegate(address delegatee) external;

  /**
   * @notice Delegates votes from signatory to `delegatee`
   * @param delegatee The address to delegate votes to
   * @param nonce The contract state required to match the signature
   * @param expiry The time at which to expire the signature
   * @param v The recovery byte of the signature
   * @param r Half of the ECDSA signature pair
   * @param s Half of the ECDSA signature pair
   */
  function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) external;

  /**
   * @notice Gets the current votes balance for `account`
   * @param account The address to get votes balance
   * @return The number of current votes for `account`
   */
  function getCurrentVotes(address account) external view returns (uint96);

  /**
   * @notice Determine the prior number of votes for an account as of a block number
   * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
   * @param account The address of the account to check
   * @param blockNumber The block number to get the vote balance at
   * @return The number of votes the account had as of the given block
   */
  function getPriorVotes(address account, uint blockNumber) external view returns (uint96);
}

// File: powerpool-governance/contracts/interfaces/GovernorAlphaInterface.sol

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;


contract GovernorAlphaInterface {
  /// @notice The name of this contract
  function name() external view returns (string memory);

  /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
  function quorumVotes() external pure returns (uint);

  /// @notice The number of votes required in order for a voter to become a proposer
  function proposalThreshold() external pure returns (uint);

  /// @notice The maximum number of actions that can be included in a proposal
  function proposalMaxOperations() external pure returns (uint);

  /// @notice The delay before voting on a proposal may take place, once proposed
  function votingDelay() external pure returns (uint);

  /// @notice The duration of voting on a proposal, in blocks
  function votingPeriod() external pure returns (uint);

  /// @notice The address of the PowerPool Protocol Timelock
  function timelock() external view returns (TimelockInterface);

  /// @notice The address of the Governor Guardian
  function guardian() external view returns (address);

  /// @notice The total number of proposals
  function proposalCount() external view returns (uint);

  /// @notice The official record of all proposals ever proposed
  function proposals(uint _id) external view returns (
    uint id,
    address proposer,
    uint eta,
    uint startBlock,
    uint endBlock,
    uint forVotes,
    uint againstVotes,
    bool canceled,
    bool executed
  );

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

  /// @notice Ballot receipt record for a voter
  struct Receipt {
    /// @notice Whether or not a vote has been cast
    bool hasVoted;

    /// @notice Whether or not the voter supports the proposal
    bool support;

    /// @notice The number of votes the voter had, which were cast
    uint256 votes;
  }

  /// @notice The latest proposal for each proposer
  function latestProposalIds(address _addr) external view returns (uint);

  /// @notice The EIP-712 typehash for the contract's domain
  function DOMAIN_TYPEHASH() external view returns (bytes32);

  /// @notice The EIP-712 typehash for the ballot struct used by the contract
  function BALLOT_TYPEHASH() external view returns (bytes32);

  /// @notice An event emitted when a new proposal is created
  event ProposalCreated(uint indexed id, address indexed proposer, address[] targets, uint[] values, string[] signatures, bytes[] calldatas, uint startBlock, uint endBlock, string description);

  /// @notice An event emitted when a vote has been cast on a proposal
  event VoteCast(address indexed voter, uint indexed proposalId, bool indexed support, uint votes);

  /// @notice An event emitted when a proposal has been canceled
  event ProposalCanceled(uint indexed id);

  /// @notice An event emitted when a proposal has been queued in the Timelock
  event ProposalQueued(uint indexed id, uint eta);

  /// @notice An event emitted when a proposal has been executed in the Timelock
  event ProposalExecuted(uint indexed id);

  function propose(address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas, string memory description) public returns (uint);

  function queue(uint proposalId) public;

  function execute(uint proposalId) public payable;

  function cancel(uint proposalId) public;

  function getActions(uint proposalId) public view returns (address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas);

  function getReceipt(uint proposalId, address voter) public view returns (Receipt memory);

  function getVoteSources() external view returns (address[] memory);

  function state(uint proposalId) public view returns (ProposalState);

  function castVote(uint proposalId, bool support) public;

  function castVoteBySig(uint proposalId, bool support, uint8 v, bytes32 r, bytes32 s) public;

  function __acceptAdmin() public;

  function __abdicate() public ;

  function __queueSetTimelockPendingAdmin(address newPendingAdmin, uint eta) public;

  function __executeSetTimelockPendingAdmin(address newPendingAdmin, uint eta) public;
}

interface TimelockInterface {
  function delay() external view returns (uint);
  function GRACE_PERIOD() external view returns (uint);
  function acceptAdmin() external;
  function queuedTransactions(bytes32 hash) external view returns (bool);
  function queueTransaction(address target, uint value, string calldata signature, bytes calldata data, uint eta) external returns (bytes32);
  function cancelTransaction(address target, uint value, string calldata signature, bytes calldata data, uint eta) external;
  function executeTransaction(address target, uint value, string calldata signature, bytes calldata data, uint eta) external payable returns (bytes memory);
}

// File: powerpool-governance/contracts/PPGovernorL1.sol

pragma solidity ^0.5.16;


contract PPGovernorL1 is GovernorAlphaInterface {
  /// @notice The name of this contract
  string public constant name = "PowerPool Governor L1";

  /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
  function quorumVotes() public pure returns (uint) { return 400000e18; } // 400,000 = 0.4% of Cvp

  /// @notice The number of votes required in order for a voter to become a proposer
  function proposalThreshold() public pure returns (uint) { return 10000e18; } // 10,000 = 0.01% of Cvp

  /// @notice The maximum number of actions that can be included in a proposal
  function proposalMaxOperations() public pure returns (uint) { return 10; } // 10 actions

  /// @notice The delay before voting on a proposal may take place, once proposed
  function votingDelay() public pure returns (uint) { return 1; } // 1 block

  /// @notice The duration of voting on a proposal, in blocks
  function votingPeriod() public pure returns (uint) { return 17280; } // ~3 days in blocks (assuming 15s blocks)

  /// @notice The address of the PowerPool Protocol Timelock
  TimelockInterface public timelock;

  /// @notice The addresses of the PowerPool-compatible vote sources
  address[] public voteSources;

  /// @notice The address of the Governor Guardian
  address public guardian;

  /// @notice The total number of proposals
  uint public proposalCount;

  struct Proposal {
    /// @notice Unique id for looking up a proposal
    uint id;

    /// @notice Creator of the proposal
    address proposer;

    /// @notice The timestamp that the proposal will be available for execution, set once the vote succeeds
    uint eta;

    /// @notice the ordered list of target addresses for calls to be made
    address[] targets;

    /// @notice The ordered list of values (i.e. msg.value) to be passed to the calls to be made
    uint[] values;

    /// @notice The ordered list of function signatures to be called
    string[] signatures;

    /// @notice The ordered list of calldata to be passed to each call
    bytes[] calldatas;

    /// @notice The block at which voting begins: holders must delegate their votes prior to this block
    uint startBlock;

    /// @notice The block at which voting ends: votes must be cast prior to this block
    uint endBlock;

    /// @notice Current number of votes in favor of this proposal
    uint forVotes;

    /// @notice Current number of votes in opposition to this proposal
    uint againstVotes;

    /// @notice Flag marking whether the proposal has been canceled
    bool canceled;

    /// @notice Flag marking whether the proposal has been executed
    bool executed;

    /// @notice Receipts of ballots for the entire set of voters
    mapping (address => Receipt) receipts;
  }

  /// @notice The official record of all proposals ever proposed
  mapping (uint => Proposal) public proposals;

  /// @notice The latest proposal for each proposer
  mapping (address => uint) public latestProposalIds;

  /// @notice The EIP-712 typehash for the contract's domain
  bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

  /// @notice The EIP-712 typehash for the ballot struct used by the contract
  bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,bool support)");

  /// @notice An event emitted when a new proposal is created
  event ProposalCreated(uint id, address proposer, address[] targets, uint[] values, string[] signatures, bytes[] calldatas, uint startBlock, uint endBlock, string description);

  /// @notice An event emitted when a vote has been cast on a proposal
  event VoteCast(address voter, uint proposalId, bool support, uint votes);

  /// @notice An event emitted when a proposal has been canceled
  event ProposalCanceled(uint id);

  /// @notice An event emitted when a proposal has been queued in the Timelock
  event ProposalQueued(uint id, uint eta);

  /// @notice An event emitted when a proposal has been executed in the Timelock
  event ProposalExecuted(uint id);

  constructor(address timelock_, address[] memory voteSources_, address guardian_) public {
    require(voteSources_.length > 0, "GovernorAlpha::constructor: voteSources can't be empty");

    timelock = TimelockInterface(timelock_);
    voteSources = voteSources_;
    guardian = guardian_;
  }

  function propose(address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas, string memory description) public returns (uint) {
    require(getPriorVotes(msg.sender, sub256(block.number, 1)) > proposalThreshold(), "GovernorAlpha::propose: proposer votes below proposal threshold");
    require(targets.length == values.length && targets.length == signatures.length && targets.length == calldatas.length, "GovernorAlpha::propose: proposal function information arity mismatch");
    require(targets.length != 0, "GovernorAlpha::propose: must provide actions");
    require(targets.length <= proposalMaxOperations(), "GovernorAlpha::propose: too many actions");

    uint latestProposalId = latestProposalIds[msg.sender];
    if (latestProposalId != 0) {
      ProposalState proposersLatestProposalState = state(latestProposalId);
      require(proposersLatestProposalState != ProposalState.Active, "GovernorAlpha::propose: one live proposal per proposer, found an already active proposal");
      require(proposersLatestProposalState != ProposalState.Pending, "GovernorAlpha::propose: one live proposal per proposer, found an already pending proposal");
    }

    uint startBlock = add256(block.number, votingDelay());
    uint endBlock = add256(startBlock, votingPeriod());

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

    emit ProposalCreated(newProposal.id, msg.sender, targets, values, signatures, calldatas, startBlock, endBlock, description);
    return newProposal.id;
  }

  function queue(uint proposalId) public {
    require(state(proposalId) == ProposalState.Succeeded, "GovernorAlpha::queue: proposal can only be queued if it is succeeded");
    Proposal storage proposal = proposals[proposalId];
    uint eta = add256(block.timestamp, timelock.delay());
    for (uint i = 0; i < proposal.targets.length; i++) {
      _queueOrRevert(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], eta);
    }
    proposal.eta = eta;
    emit ProposalQueued(proposalId, eta);
  }

  function _queueOrRevert(address target, uint value, string memory signature, bytes memory data, uint eta) internal {
    require(!timelock.queuedTransactions(keccak256(abi.encode(target, value, signature, data, eta))), "GovernorAlpha::_queueOrRevert: proposal action already queued at eta");
    timelock.queueTransaction(target, value, signature, data, eta);
  }

  function execute(uint proposalId) public payable {
    require(state(proposalId) == ProposalState.Queued, "GovernorAlpha::execute: proposal can only be executed if it is queued");
    Proposal storage proposal = proposals[proposalId];
    proposal.executed = true;
    for (uint i = 0; i < proposal.targets.length; i++) {
      timelock.executeTransaction.value(proposal.values[i])(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
    }
    emit ProposalExecuted(proposalId);
  }

  function cancel(uint proposalId) public {
    ProposalState state = state(proposalId);
    require(state != ProposalState.Executed, "GovernorAlpha::cancel: cannot cancel executed proposal");

    Proposal storage proposal = proposals[proposalId];
    require(msg.sender == guardian || getPriorVotes(proposal.proposer, sub256(block.number, 1)) < proposalThreshold(), "GovernorAlpha::cancel: proposer above threshold");

    proposal.canceled = true;
    for (uint i = 0; i < proposal.targets.length; i++) {
      timelock.cancelTransaction(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
    }

    emit ProposalCanceled(proposalId);
  }

  function getActions(uint proposalId) public view returns (address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas) {
    Proposal storage p = proposals[proposalId];
    return (p.targets, p.values, p.signatures, p.calldatas);
  }

  function getReceipt(uint proposalId, address voter) public view returns (Receipt memory) {
    return proposals[proposalId].receipts[voter];
  }

  function state(uint proposalId) public view returns (ProposalState) {
    require(proposalCount >= proposalId && proposalId > 0, "GovernorAlpha::state: invalid proposal id");
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
    } else if (block.timestamp >= add256(proposal.eta, timelock.GRACE_PERIOD())) {
      return ProposalState.Expired;
    } else {
      return ProposalState.Queued;
    }
  }

  function getPriorVotes(address account, uint256 blockNumber) public view returns (uint256) {
    uint256 total = 0;
    uint256 len = voteSources.length;

    for (uint256 i = 0; i < len; i++) {
      total = add256(total, CvpInterface(voteSources[i]).getPriorVotes(account, blockNumber));
    }

    return total;
  }

  function getVoteSources() external view returns (address[] memory) {
    return voteSources;
  }

  function castVote(uint proposalId, bool support) public {
    return _castVote(msg.sender, proposalId, support);
  }

  function castVoteBySig(uint proposalId, bool support, uint8 v, bytes32 r, bytes32 s) public {
    bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
    bytes32 structHash = keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support));
    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    address signatory = ecrecover(digest, v, r, s);
    require(signatory != address(0), "GovernorAlpha::castVoteBySig: invalid signature");
    return _castVote(signatory, proposalId, support);
  }

  function _castVote(address voter, uint proposalId, bool support) internal {
    require(state(proposalId) == ProposalState.Active, "GovernorAlpha::_castVote: voting is closed");
    Proposal storage proposal = proposals[proposalId];
    Receipt storage receipt = proposal.receipts[voter];
    require(receipt.hasVoted == false, "GovernorAlpha::_castVote: voter already voted");
    uint256 votes = getPriorVotes(voter, proposal.startBlock);

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
    require(msg.sender == guardian, "GovernorAlpha::__acceptAdmin: sender must be gov guardian");
    timelock.acceptAdmin();
  }

  function __abdicate() public {
    require(msg.sender == guardian, "GovernorAlpha::__abdicate: sender must be gov guardian");
    guardian = address(0);
  }

  function __queueSetTimelockPendingAdmin(address newPendingAdmin, uint eta) public {
    require(msg.sender == guardian, "GovernorAlpha::__queueSetTimelockPendingAdmin: sender must be gov guardian");
    timelock.queueTransaction(address(timelock), 0, "setPendingAdmin(address)", abi.encode(newPendingAdmin), eta);
  }

  function __executeSetTimelockPendingAdmin(address newPendingAdmin, uint eta) public {
    require(msg.sender == guardian, "GovernorAlpha::__executeSetTimelockPendingAdmin: sender must be gov guardian");
    timelock.executeTransaction(address(timelock), 0, "setPendingAdmin(address)", abi.encode(newPendingAdmin), eta);
  }

  function add256(uint256 a, uint256 b) internal pure returns (uint) {
    uint c = a + b;
    require(c >= a, "addition overflow");
    return c;
  }

  function sub256(uint256 a, uint256 b) internal pure returns (uint) {
    require(b <= a, "subtraction underflow");
    return a - b;
  }

  function getChainId() internal pure returns (uint) {
    uint chainId;
    assembly { chainId := chainid() }
    return chainId;
  }
}