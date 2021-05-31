pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

// File: contracts/governance/GovernorAlpha.sol

// Original work from Compound: https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/GovernorAlpha.sol
// Modified to work in the YAM system

// all votes work on underlying _auscBalances[address], not balanceOf(address)

// Original audit: https://blog.openzeppelin.com/compound-alpha-governance-system-audit/
// Overview:
//    No Critical
//    High:
//      Issue:
//        Approved proposal may be impossible to queue, cancel or execute
//        Fixed with `proposalMaxOperations`
//      Issue:
//        Queued proposal with repeated actions cannot be executed
//        Fixed by explicitly disallow proposals with repeated actions to be queued in the Timelock contract.
//
// Changes made by YAM after audit:
//    Formatting, naming, & uint256 instead of uint
//    Since YAM supply changes, updated quorum & proposal requirements
//    If any uint96, changed to uint256 to match YAM as opposed to comp

contract GovernorStorage {
  /// @notice Ballot receipt record for a voter
  struct Receipt {
    /// @notice Whether or not a vote has been cast
    bool hasVoted;
    /// @notice Whether or not the voter supports the proposal
    bool support;
    /// @notice The number of votes the voter had, which were cast
    uint256 votes;
  }

  struct Proposal {
    /// @notice Unique id for looking up a proposal
    uint256 id;
    /// @notice Creator of the proposal
    address proposer;
    /// @notice Approver of the proposal
    address approver;
    /// @notice The block number the proposal is created on
    uint256 createBlock;
    /// @notice The timestamp that the proposal will be available for execution, set once the vote succeeds
    uint256 eta;
    /// @notice the ordered list of target addresses for calls to be made
    address[] targets;
    /// @notice The ordered list of values (i.e. msg.value) to be passed to the calls to be made
    uint256[] values;
    /// @notice The ordered list of function signatures to be called
    string[] signatures;
    /// @notice The ordered list of calldata to be passed to each call
    bytes[] calldatas;
    /// @notice The block at which voting begins: holders must delegate their votes prior to this block
    uint256 startBlock;
    /// @notice The block at which voting ends: votes must be cast prior to this block
    uint256 endBlock;
    /// @notice Current number of votes in favor of this proposal
    uint256 forVotes;
    /// @notice Current number of votes in opposition to this proposal
    uint256 againstVotes;
    /// @notice Flag marking whether the proposal has been canceled
    bool canceled;
    /// @notice Flag marking whether the proposal has been executed
    bool executed;
    /// @notice Receipts of ballots for the entire set of voters
    mapping(address => Receipt) receipts;
  }
  /// @notice Possible states that a proposal may be in
  enum ProposalState {
    Created,
    Pending,
    Active,
    Canceled,
    Defeated,
    Succeeded,
    Queued,
    Expired,
    Executed
  }
}

contract GovernorEvents {
  /// @notice An event emitted when a new proposal is created
  event ProposalCreated(
    uint256 id,
    address proposer,
    address[] targets,
    uint256[] values,
    string[] signatures,
    bytes[] calldatas,
    string description
  );

  /// @notice An event emitted when a proposal is added to pending
  event ProposalApproved(
    uint256 id,
    address approver,
    uint256 startBlock,
    uint256 endBlock
  );

  /// @notice An event emitted when a vote has been cast on a proposal
  event VoteCast(
    address voter,
    uint256 proposalId,
    bool support,
    uint256 votes
  );

  /// @notice An event emitted when a proposal has been canceled
  event ProposalCanceled(uint256 id, address callerAddress);

  /// @notice An event emitted when a proposal has been queued in the Timelock
  event ProposalQueued(uint256 id, uint256 eta, address callerAddress);

  /// @notice An event emitted when a proposal has been executed in the Timelock
  event ProposalExecuted(uint256 id, address callerAddress);

  event VotingDelaySet(uint256 oldVotingDelay, uint256 newVotingDelay);

  /// @notice An event emitted when the voting period is set
  event VotingPeriodSet(uint256 oldVotingPeriod, uint256 newVotingPeriod);

  /// @notice Emitted when approve Percent is set
  event ApprovePercentSet(
    uint256 oldProposalPercent,
    uint256 newProposalPercent
  );

  /// @notice Emitted when Quorum Percent is set
  event QuorumPercentSet(uint256 oldPercent, uint256 quorumPercent);

  /// @notice Emitted when pendingAdmin is changed
  event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

  /// @notice Emitted when pendingAdmin is accepted, which means admin is updated
  event NewAdmin(address oldAdmin, address newAdmin);
}

contract GovernorAlpha is GovernorStorage, GovernorEvents {
  /// @notice The name of this contract
  string public constant NAME = "AUSCM Governor";

  /// @notice The minimum setable approve threshold
  uint256 public constant MIN_APPROVE_THRESHOLD = 50; // 0.5% voting power

  /// @notice The maximum setable approve threshold
  uint256 public constant MAX_APPROVE_THRESHOLD = 500; // 5% voting power

  /// @notice The minimum setable quorum threshold
  uint256 public constant MIN_QUORUM_THRESHOLD = 50; // 0.5% voting power

  /// @notice The maximum setable quorum threshold
  uint256 public constant MAX_QUORUM_THRESHOLD = 1000; // 10% voting power

  /// @notice The minimum setable voting period
  uint256 public constant MIN_VOTING_PERIOD = 5760; // About 24 hours

  /// @notice The max setable voting period
  uint256 public constant MAX_VOTING_PERIOD = 80640; // About 2 weeks

  /// @notice The min setable voting delay
  uint256 public constant MIN_VOTING_DELAY = 1; // 1 block

  /// @notice The max setable voting delay
  uint256 public constant MAX_VOTING_DELAY = 40320; // About 1 week

  /// @notice Percentage of votes needed for a proposal to pass multiplied by 100 (to accomodate 2 decimal point) i.e. 125 = 1.25%
  uint256 public quorumPercent = 400; // 4% by default

  /// @notice Percentage of votes needed for a proposal to be approved
  uint256 public approvePercent = 100; // 1% voting power

  /// @notice The delay before voting on a proposal may take place, once proposed, in blocks
  uint256 public votingDelay = 1; // 1 block

  /// @notice The duration of voting on a proposal, in blocks
  uint256 public votingPeriod = 20; // ~3 days in blocks (assuming 15s blocks)

  /// @notice The duration of the approval phase of a proposal
  uint256 public approvalPeriod = 20; // ~1 day in blocks (assuming 15s blocks)

  /// @notice The maximum number of actions that can be included in a proposal
  function proposalMaxOperations() public pure returns (uint256) {
    return 10;
  } // 10 actions

  /// @notice The address of the Timelock
  TimelockInterface public timelock;

  /// @notice The address of the governance token
  AUSCInterface public ausc;

  /// @notice The address of the Governor Guardian
  address public guardian;

  /// @notice The address of the Governor Admin
  address public admin;

  /// @notice The address of the pending Admin
  address public pendingAdmin;

  /// @notice The total number of proposals
  uint256 public proposalCount;

  /// @notice The official record of all proposals ever proposed
  mapping(uint256 => Proposal) public proposals;

  /// @notice The latest proposal for each proposer
  mapping(address => uint256) public latestProposalIds;

  /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
  function quorumVotes() public view returns (uint256) {
    uint256 minimumVotes = SafeMath.div(ausc.initSupply(), 10000); // Quorum requirement is always a multiple of 0.01% of AUSC supply
    return SafeMath.mul(minimumVotes, quorumPercent);
  }

  /// @notice The number of votes required in order for a voter to approve a proposal
  function approveVotes() public view returns (uint256) {
    uint256 minimumVotes = SafeMath.div(ausc.initSupply(), 10000); // Approval requirement is always a multiple of 0.01% of AUSC supply
    return SafeMath.mul(minimumVotes, approvePercent);
  }

  /// @notice The number of Tokens required in order for a voter to create a proposal
  function createVotes() public pure returns (uint256) {
    return 9000;
  }

  /// @notice The EIP-712 typehash for the contract's domain
  bytes32 public constant DOMAIN_TYPEHASH =
    keccak256(
      "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
    );

  /// @notice The EIP-712 typehash for the ballot struct used by the contract
  bytes32 public constant BALLOT_TYPEHASH =
    keccak256("Ballot(uint256 proposalId,bool support)");

  constructor(address timelock_, address ausc_) public {
    timelock = TimelockInterface(timelock_);
    ausc = AUSCInterface(ausc_);
    guardian = msg.sender;
    admin = msg.sender;
  }

  function propose(
    address[] memory targets,
    uint256[] memory values,
    string[] memory signatures,
    bytes[] memory calldatas,
    string memory description
  ) public returns (uint256) {
    require(
      ausc.balanceOf(msg.sender) >= createVotes(),
      "POWERLEVEL UNDER 9000!!! Proposer balance below create threshold"
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
        proposersLatestProposalState != ProposalState.Pending,
        "GovernorAlpha::propose: one live proposal per proposer, found an already unapproved proposal"
      );
      require(
        proposersLatestProposalState != ProposalState.Active,
        "GovernorAlpha::propose: one live proposal per proposer, found an already active proposal"
      );
      require(
        proposersLatestProposalState != ProposalState.Created,
        "GovernorAlpha::propose: one live proposal per proposer, found an already created proposal"
      );
    }

    uint256 startBlock = SafeMath.add(block.number, votingDelay);
    uint256 endBlock = SafeMath.add(startBlock, votingPeriod);

    proposalCount++;
    Proposal memory newProposal =
      Proposal({
        id: proposalCount,
        proposer: msg.sender,
        approver: address(0),
        createBlock: block.number,
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
      description
    );
    return newProposal.id;
  }

  function approve(uint256 proposalId) public {
    require(
      state(proposalId) == ProposalState.Created,
      "GovernorAlpha::approve: proposal already approved"
    );
    require(
      ausc.getPriorVotes(msg.sender, SafeMath.sub(block.number, 1)) >=
        approveVotes(),
      "GovernorAlpha::approve: approver votes below approval threshold"
    );
    Proposal storage proposal = proposals[proposalId];
    uint256 startBlock = SafeMath.add(block.number, votingDelay);
    uint256 endBlock = SafeMath.add(startBlock, votingPeriod);
    proposal.approver = msg.sender;
    proposal.startBlock = startBlock;
    proposal.endBlock = endBlock;

    emit ProposalApproved(proposal.id, msg.sender, startBlock, endBlock);
  }

  function queue(uint256 proposalId) public {
    require(
      state(proposalId) == ProposalState.Succeeded,
      "GovernorAlpha::queue: proposal can only be queued if it is succeeded"
    );
    Proposal storage proposal = proposals[proposalId];
    uint256 eta = SafeMath.add(block.timestamp, timelock.delay());
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
    emit ProposalQueued(proposalId, eta, msg.sender);
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
    emit ProposalExecuted(proposalId, msg.sender);
  }

  function cancel(uint256 proposalId) public {
    ProposalState state = state(proposalId);
    require(
      state != ProposalState.Executed,
      "GovernorAlpha::cancel: cannot cancel executed proposal"
    );

    Proposal storage proposal = proposals[proposalId];
    require(
      msg.sender == guardian ||
        msg.sender == proposal.proposer ||
        ausc.balanceOf(proposal.approver) < approveVotes(),
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

    emit ProposalCanceled(proposalId, msg.sender);
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
    } else if (
      proposal.approver == address(0) &&
      block.number >= SafeMath.add(proposal.createBlock, approvalPeriod)
    ) {
      return ProposalState.Expired;
    } else if (proposal.approver == address(0)) {
      return ProposalState.Created;
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
      block.timestamp >= SafeMath.add(proposal.eta, timelock.GRACE_PERIOD())
    ) {
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
    uint256 votes = ausc.getPriorVotes(voter, proposal.startBlock);

    if (support) {
      proposal.forVotes = SafeMath.add(proposal.forVotes, votes);
    } else {
      proposal.againstVotes = SafeMath.add(proposal.againstVotes, votes);
    }

    receipt.hasVoted = true;
    receipt.support = support;
    receipt.votes = votes;

    emit VoteCast(voter, proposalId, support, votes);
  }

  /**
   * @notice Admin function for setting the voting delay
   * @param newVotingDelay new voting delay, in blocks
   */
  function _setVotingDelay(uint256 newVotingDelay) external {
    require(msg.sender == admin, "GovernorAlpha::_setVotingDelay: admin only");
    require(
      newVotingDelay >= MIN_VOTING_DELAY && newVotingDelay <= MAX_VOTING_DELAY,
      "GovernorAlpha::_setVotingDelay: invalid voting delay"
    );
    uint256 oldVotingDelay = votingDelay;
    votingDelay = newVotingDelay;

    emit VotingDelaySet(oldVotingDelay, votingDelay);
  }

  /**
   * @notice Admin function for setting the voting period
   * @param newVotingPeriod new voting period, in blocks
   */
  function _setVotingPeriod(uint256 newVotingPeriod) external {
    require(msg.sender == admin, "GovernorAlpha::_setVotingPeriod: admin only");
    require(
      newVotingPeriod >= MIN_VOTING_PERIOD &&
        newVotingPeriod <= MAX_VOTING_PERIOD,
      "GovernorAlpha::_setVotingPeriod: invalid voting period"
    );
    uint256 oldVotingPeriod = votingPeriod;
    votingPeriod = newVotingPeriod;

    emit VotingPeriodSet(oldVotingPeriod, votingPeriod);
  }

  /**
   * @notice Admin function for setting the approve threshold
   * @dev newApprovePercent must be greater than the hardcoded min
   * @param newApprovePercent new approve threshold
   */
  function _setApprovePercent(uint256 newApprovePercent) external {
    require(
      msg.sender == admin,
      "GovernorAlpha::_setProposalThreshold: admin only"
    );
    require(
      newApprovePercent >= MIN_APPROVE_THRESHOLD &&
        newApprovePercent <= MAX_APPROVE_THRESHOLD,
      "GovernorAlpha::_setProposalThreshold: invalid approve threshold"
    );
    uint256 oldApprovePercent = approvePercent;
    approvePercent = newApprovePercent;

    emit ApprovePercentSet(oldApprovePercent, approvePercent);
  }

  /**
   * @notice Admin function for setting the Quorum Percent
   * @dev newQuorum must be greater than the hardcoded min
   * @param newQuorum new quorum threshold
   */
  function _setQuorumPercent(uint256 newQuorum) public {
    require(msg.sender == admin, "GovernorAlpha::_setQuorumPercent admin only");
    require(
      newQuorum >= MIN_QUORUM_THRESHOLD && newQuorum <= MAX_QUORUM_THRESHOLD,
      "GovernorAlpha::_setQuorumPercent: invalid quorum percent"
    );
    uint256 oldQuorumPercent = quorumPercent;
    quorumPercent = newQuorum;

    emit QuorumPercentSet(oldQuorumPercent, quorumPercent);
  }

  /**
   * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
   * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
   * @param newPendingAdmin New pending admin.
   */
  function _setPendingAdmin(address newPendingAdmin) external {
    // Check caller = admin
    require(msg.sender == admin, "GovernorAlpha:_setPendingAdmin: admin only");

    // Save current value, if any, for inclusion in log
    address oldPendingAdmin = pendingAdmin;

    // Store pendingAdmin with value newPendingAdmin
    pendingAdmin = newPendingAdmin;

    // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
    emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
  }

  /**
   * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
   * @dev Admin function for pending admin to accept role and update admin
   */
  function _acceptAdmin() external {
    // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
    require(
      msg.sender == pendingAdmin && msg.sender != address(0),
      "GovernorAlpha:_acceptAdmin: pending admin only"
    );

    // Save current values for inclusion in log
    address oldAdmin = admin;
    address oldPendingAdmin = pendingAdmin;

    // Store admin with value pendingAdmin
    admin = pendingAdmin;

    // Clear the pending value
    pendingAdmin = address(0);

    emit NewAdmin(oldAdmin, admin);
    emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
  }

  function _acceptTimelockAdmin() public {
    require(
      msg.sender == guardian,
      "GovernorAlpha::_acceptTimelockAdmin: sender must be gov guardian"
    );
    timelock.acceptAdmin();
  }

  function __abdicate() public {
    require(
      msg.sender == guardian,
      "GovernorAlpha::__abdicate: sender must be gov guardian"
    );
    guardian = address(0);
  }

  function __queueSetTimelockPendingAdmin(address newPendingAdmin, uint256 eta)
    public
  {
    require(
      msg.sender == guardian,
      "GovernorAlpha::__queueSetTimelockPendingAdmin: sender must be gov guardian"
    );
    timelock.queueTransaction(
      address(timelock),
      0,
      "setPendingAdmin(address)",
      abi.encode(newPendingAdmin),
      eta
    );
  }

  function __executeSetTimelockPendingAdmin(
    address newPendingAdmin,
    uint256 eta
  ) public {
    require(
      msg.sender == guardian,
      "GovernorAlpha::__executeSetTimelockPendingAdmin: sender must be gov guardian"
    );
    timelock.executeTransaction(
      address(timelock),
      0,
      "setPendingAdmin(address)",
      abi.encode(newPendingAdmin),
      eta
    );
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

interface AUSCInterface {
  function getPriorVotes(address account, uint256 blockNumber)
    external
    view
    returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function initSupply() external view returns (uint256);
}

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}