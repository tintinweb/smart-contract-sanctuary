// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

import {DefaultExecutorWithTimelock} from './DefaultExecutorWithTimelock.sol';
import {DefaultProposalValidator} from './DefaultProposalValidator.sol';

/**
 * @title Time Locked, Validator, Executor Contract
 * @dev Contract
 * - Validate Proposal creations/ cancellation
 * - Validate Vote Quorum and Vote success on proposal
 * - Queue, Execute, Cancel, successful proposals' transactions.
 **/
contract DefaultExecutor is DefaultExecutorWithTimelock, DefaultProposalValidator {
  constructor(
    address admin,
    uint256 delay,
    uint256 gracePeriod,
    uint256 minimumDelay,
    uint256 maximumDelay,
    uint256 minVoteDuration,
    uint256 maxVotingOptions,
    uint256 voteDifferential,
    uint256 minimumQuorum
  )
    DefaultExecutorWithTimelock(admin, delay, gracePeriod, minimumDelay, maximumDelay)
    DefaultProposalValidator(minVoteDuration, maxVotingOptions, voteDifferential, minimumQuorum)
  {}
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

import {IExecutorWithTimelock} from '../../interfaces/governance/IExecutorWithTimelock.sol';
import {IKyberGovernance} from '../../interfaces/governance/IKyberGovernance.sol';
import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';

/**
 * @title Time Locked Executor Contract, inherited by Aave Governance Executors
 * @dev Contract that can queue, execute, cancel transactions voted by Governance
 * Queued transactions can be executed after a delay and until
 * Grace period is not over.
 * @author Aave
 **/
contract DefaultExecutorWithTimelock is IExecutorWithTimelock {
  using SafeMath for uint256;

  uint256 public immutable override GRACE_PERIOD;
  uint256 public immutable override MINIMUM_DELAY;
  uint256 public immutable override MAXIMUM_DELAY;

  address private _admin;
  address private _pendingAdmin;
  uint256 private _delay;

  mapping(bytes32 => bool) private _queuedTransactions;

  /**
   * @dev Constructor
   * @param admin admin address, that can call the main functions, (Governance)
   * @param delay minimum time between queueing and execution of proposal
   * @param gracePeriod time after `delay` while a proposal can be executed
   * @param minimumDelay lower threshold of `delay`, in seconds
   * @param maximumDelay upper threhold of `delay`, in seconds
   **/
  constructor(
    address admin,
    uint256 delay,
    uint256 gracePeriod,
    uint256 minimumDelay,
    uint256 maximumDelay
  ) {
    require(delay >= minimumDelay, 'DELAY_SHORTER_THAN_MINIMUM');
    require(delay <= maximumDelay, 'DELAY_LONGER_THAN_MAXIMUM');
    _delay = delay;
    _admin = admin;

    GRACE_PERIOD = gracePeriod;
    MINIMUM_DELAY = minimumDelay;
    MAXIMUM_DELAY = maximumDelay;

    emit NewDelay(delay);
    emit NewAdmin(admin);
  }

  modifier onlyAdmin() {
    require(msg.sender == _admin, 'ONLY_BY_ADMIN');
    _;
  }

  modifier onlyTimelock() {
    require(msg.sender == address(this), 'ONLY_BY_THIS_TIMELOCK');
    _;
  }

  modifier onlyPendingAdmin() {
    require(msg.sender == _pendingAdmin, 'ONLY_BY_PENDING_ADMIN');
    _;
  }

  /**
   * @dev Set the delay
   * @param delay delay between queue and execution of proposal
   **/
  function setDelay(uint256 delay) public onlyTimelock {
    _validateDelay(delay);
    _delay = delay;

    emit NewDelay(delay);
  }

  /**
   * @dev Function enabling pending admin to become admin
   **/
  function acceptAdmin() public onlyPendingAdmin {
    _admin = msg.sender;
    _pendingAdmin = address(0);

    emit NewAdmin(msg.sender);
  }

  /**
   * @dev Setting a new pending admin (that can then become admin)
   * Can only be called by this executor (i.e via proposal)
   * @param newPendingAdmin address of the new admin
   **/
  function setPendingAdmin(address newPendingAdmin) public onlyTimelock {
    _pendingAdmin = newPendingAdmin;

    emit NewPendingAdmin(newPendingAdmin);
  }

  /**
   * @dev Function, called by Governance, that queue a transaction, returns action hash
   * @param target smart contract target
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   * @return the action Hash
   **/
  function queueTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 executionTime,
    bool withDelegatecall
  ) public override onlyAdmin returns (bytes32) {
    require(executionTime >= block.timestamp.add(_delay), 'EXECUTION_TIME_UNDERESTIMATED');

    bytes32 actionHash = keccak256(
      abi.encode(target, value, signature, data, executionTime, withDelegatecall)
    );
    _queuedTransactions[actionHash] = true;

    emit QueuedAction(actionHash, target, value, signature, data, executionTime, withDelegatecall);
    return actionHash;
  }

  /**
   * @dev Function, called by Governance, that cancels a transaction, returns action hash
   * @param target smart contract target
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   * @return the action Hash of the canceled tx
   **/
  function cancelTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 executionTime,
    bool withDelegatecall
  ) public override onlyAdmin returns (bytes32) {
    bytes32 actionHash = keccak256(
      abi.encode(target, value, signature, data, executionTime, withDelegatecall)
    );
    _queuedTransactions[actionHash] = false;

    emit CancelledAction(
      actionHash,
      target,
      value,
      signature,
      data,
      executionTime,
      withDelegatecall
    );
    return actionHash;
  }

  /**
   * @dev Function, called by Governance, that cancels a transaction, returns the callData executed
   * @param target smart contract target
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   * @return the callData executed as memory bytes
   **/
  function executeTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 executionTime,
    bool withDelegatecall
  ) public override payable onlyAdmin returns (bytes memory) {
    bytes32 actionHash = keccak256(
      abi.encode(target, value, signature, data, executionTime, withDelegatecall)
    );
    require(_queuedTransactions[actionHash], 'ACTION_NOT_QUEUED');
    require(block.timestamp >= executionTime, 'TIMELOCK_NOT_FINISHED');
    require(block.timestamp <= executionTime.add(GRACE_PERIOD), 'GRACE_PERIOD_FINISHED');

    _queuedTransactions[actionHash] = false;

    bytes memory callData;

    if (bytes(signature).length == 0) {
      callData = data;
    } else {
      callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
    }

    bool success;
    bytes memory resultData;
    if (withDelegatecall) {
      require(msg.value >= value, 'NOT_ENOUGH_MSG_VALUE');
      // solium-disable-next-line security/no-call-value
      (success, resultData) = target.delegatecall(callData);
    } else {
      // solium-disable-next-line security/no-call-value
      (success, resultData) = target.call{value: value}(callData);
    }

    require(success, 'FAILED_ACTION_EXECUTION');

    emit ExecutedAction(
      actionHash,
      target,
      value,
      signature,
      data,
      executionTime,
      withDelegatecall,
      resultData
    );

    return resultData;
  }

  /**
   * @dev Getter of the current admin address (should be governance)
   * @return The address of the current admin
   **/
  function getAdmin() external override view returns (address) {
    return _admin;
  }

  /**
   * @dev Getter of the current pending admin address
   * @return The address of the pending admin
   **/
  function getPendingAdmin() external override view returns (address) {
    return _pendingAdmin;
  }

  /**
   * @dev Getter of the delay between queuing and execution
   * @return The delay in seconds
   **/
  function getDelay() external override view returns (uint256) {
    return _delay;
  }

  /**
   * @dev Returns whether an action (via actionHash) is queued
   * @param actionHash hash of the action to be checked
   * keccak256(abi.encode(target, value, signature, data, executionTime, withDelegatecall))
   * @return true if underlying action of actionHash is queued
   **/
  function isActionQueued(bytes32 actionHash) external override view returns (bool) {
    return _queuedTransactions[actionHash];
  }

  /**
   * @dev Checks whether a proposal is over its grace period
   * @param governance Governance contract
   * @param proposalId Id of the proposal against which to test
   * @return true of proposal is over grace period
   **/
  function isProposalOverGracePeriod(IKyberGovernance governance, uint256 proposalId)
    external
    override
    view
    returns (bool)
  {
    IKyberGovernance.ProposalWithoutVote memory proposal = governance.getProposalById(proposalId);

    return (block.timestamp > proposal.executionTime.add(GRACE_PERIOD));
  }

  function _validateDelay(uint256 delay) internal view {
    require(delay >= MINIMUM_DELAY, 'DELAY_SHORTER_THAN_MINIMUM');
    require(delay <= MAXIMUM_DELAY, 'DELAY_LONGER_THAN_MAXIMUM');
  }

  receive() external payable {}
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

import {IKyberGovernance} from '../../interfaces/governance/IKyberGovernance.sol';
import {IVotingPowerStrategy} from '../../interfaces/governance/IVotingPowerStrategy.sol';
import {IProposalValidator} from '../../interfaces/governance/IProposalValidator.sol';
import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';
import {Utils} from '@kyber.network/utils-sc/contracts/Utils.sol';

/**
 * @title Proposal Validator Contract, inherited by Kyber Executors
 * @dev Validates/Invalidates propositions state modifications
 * Proposition Power functions: Validates proposition creations/ cancellation
 * Voting Power functions: Validates success of propositions.
 * @author Aave
 **/
contract DefaultProposalValidator is IProposalValidator, Utils {
  using SafeMath for uint256;

  uint256 public immutable override MIN_VOTING_DURATION;
  uint256 public immutable override MAX_VOTING_OPTIONS;
  uint256 public immutable override VOTE_DIFFERENTIAL;
  uint256 public immutable override MINIMUM_QUORUM;

  uint256 public constant YES_INDEX = 0;
  uint256 public constant NO_INDEX = 1;

  /**
   * @dev Constructor
   * @param minVotingDuration minimum duration in seconds of the voting period
   * @param maxVotingOptions maximum no. of vote options possible for a generic proposal
   * @param voteDifferential percentage of supply that `for` votes need to be over `against`
   *   in order for the proposal to pass
   * - In BPS
   * @param minimumQuorum minimum percentage of the supply in FOR-voting-power need for a proposal to pass
   * - In BPS
   **/
  constructor(
    uint256 minVotingDuration,
    uint256 maxVotingOptions,
    uint256 voteDifferential,
    uint256 minimumQuorum
  ) {
    MIN_VOTING_DURATION = minVotingDuration;
    MAX_VOTING_OPTIONS = maxVotingOptions;
    VOTE_DIFFERENTIAL = voteDifferential;
    MINIMUM_QUORUM = minimumQuorum;
  }

  /**
   * @dev Called to validate the cancellation of a proposal
   * @param governance governance contract to fetch proposals from
   * @param proposalId Id of the generic proposal
   * @param user entity initiating the cancellation
   * @return boolean, true if can be cancelled
   **/
  function validateProposalCancellation(
    IKyberGovernance governance,
    uint256 proposalId,
    address user
  ) external override pure returns (bool) {
    // silence compilation warnings
    governance;
    proposalId;
    user;
    return false;
  }

  /**
   * @dev Called to validate a binary proposal
   * @notice creator of proposals must be the daoOperator
   * @param strategy votingPowerStrategy contract to calculate voting power
   * @param creator address of the creator
   * @param startTime timestamp when vote starts
   * @param endTime timestamp when vote ends
   * @param daoOperator address of daoOperator
   * @return boolean, true if can be created
   **/
  function validateBinaryProposalCreation(
    IVotingPowerStrategy strategy,
    address creator,
    uint256 startTime,
    uint256 endTime,
    address daoOperator
  ) external override view returns (bool) {
    // check authorization
    if (creator != daoOperator) return false;
    // check vote duration
    if (endTime.sub(startTime) < MIN_VOTING_DURATION) return false;

    return strategy.validateProposalCreation(startTime, endTime);
  }

  /**
   * @dev Called to validate a generic proposal
   * @notice creator of proposals must be the daoOperator
   * @param strategy votingPowerStrategy contract to calculate voting power
   * @param creator address of the creator
   * @param startTime timestamp when vote starts
   * @param endTime timestamp when vote ends
   * @param options list of proposal vote options
   * @param daoOperator address of daoOperator
   * @return boolean, true if can be created
   **/
  function validateGenericProposalCreation(
    IVotingPowerStrategy strategy,
    address creator,
    uint256 startTime,
    uint256 endTime,
    string[] calldata options,
    address daoOperator
  ) external override view returns (bool) {
    // check authorization
    if (creator != daoOperator) return false;
    // check vote duration
    if (endTime.sub(startTime) < MIN_VOTING_DURATION) return false;
    // check options length
    if (options.length <= 1 || options.length > MAX_VOTING_OPTIONS) return false;

    return strategy.validateProposalCreation(startTime, endTime);
  }

  /**
   * @dev Returns whether a binary proposal passed or not
   * @param governance governance contract to fetch proposals from
   * @param proposalId Id of the proposal to set
   * @return true if proposal passed
   **/
  function isBinaryProposalPassed(IKyberGovernance governance, uint256 proposalId)
    public
    override
    view
    returns (bool)
  {
    return (isQuorumValid(governance, proposalId) &&
      isVoteDifferentialValid(governance, proposalId));
  }

  /**
   * @dev Check whether a binary proposal has reached quorum
   * Here quorum is not the number of votes reached, but number of YES_VOTES
   * @param governance governance contract to fetch proposals from
   * @param proposalId Id of the proposal to verify
   * @return true if minimum quorum is reached
   **/
  function isQuorumValid(IKyberGovernance governance, uint256 proposalId)
    public
    override
    view
    returns (bool)
  {
    IKyberGovernance.ProposalWithoutVote memory proposal = governance.getProposalById(proposalId);
    if (proposal.proposalType != IKyberGovernance.ProposalType.Binary) return false;
    return isMinimumQuorumReached(proposal.voteCounts[YES_INDEX], proposal.maxVotingPower);
  }

  /**
   * @dev Check whether a binary proposal has sufficient YES_VOTES
   * YES_VOTES - NO_VOTES > VOTE_DIFFERENTIAL * voting supply
   * @param governance Governance Contract
   * @param proposalId Id of the proposal to verify
   * @return true if enough YES_VOTES
   **/
  function isVoteDifferentialValid(IKyberGovernance governance, uint256 proposalId)
    public
    override
    view
    returns (bool)
  {
    IKyberGovernance.ProposalWithoutVote memory proposal = governance.getProposalById(proposalId);
    if (proposal.proposalType != IKyberGovernance.ProposalType.Binary) return false;
    return (
      proposal.voteCounts[YES_INDEX].mul(BPS).div(proposal.maxVotingPower) >
      proposal.voteCounts[NO_INDEX].mul(BPS).div(proposal.maxVotingPower).add(
      VOTE_DIFFERENTIAL
    ));
  }

  function isMinimumQuorumReached(uint256 votes, uint256 voteSupply) internal view returns (bool) {
    return votes >= voteSupply.mul(MINIMUM_QUORUM).div(BPS);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

import {IKyberGovernance} from './IKyberGovernance.sol';

interface IExecutorWithTimelock {
  /**
   * @dev emitted when a new pending admin is set
   * @param newPendingAdmin address of the new pending admin
   **/
  event NewPendingAdmin(address newPendingAdmin);

  /**
   * @dev emitted when a new admin is set
   * @param newAdmin address of the new admin
   **/
  event NewAdmin(address newAdmin);

  /**
   * @dev emitted when a new delay (between queueing and execution) is set
   * @param delay new delay
   **/
  event NewDelay(uint256 delay);

  /**
   * @dev emitted when a new (trans)action is Queued.
   * @param actionHash hash of the action
   * @param target address of the targeted contract
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   **/
  event QueuedAction(
    bytes32 actionHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 executionTime,
    bool withDelegatecall
  );

  /**
   * @dev emitted when an action is Cancelled
   * @param actionHash hash of the action
   * @param target address of the targeted contract
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   **/
  event CancelledAction(
    bytes32 actionHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 executionTime,
    bool withDelegatecall
  );

  /**
   * @dev emitted when an action is Cancelled
   * @param actionHash hash of the action
   * @param target address of the targeted contract
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   * @param resultData the actual callData used on the target
   **/
  event ExecutedAction(
    bytes32 actionHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 executionTime,
    bool withDelegatecall,
    bytes resultData
  );

  /**
   * @dev Function, called by Governance, that queue a transaction, returns action hash
   * @param target smart contract target
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   **/
  function queueTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 executionTime,
    bool withDelegatecall
  ) external returns (bytes32);

  /**
   * @dev Function, called by Governance, that cancels a transaction, returns the callData executed
   * @param target smart contract target
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   **/
  function executeTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 executionTime,
    bool withDelegatecall
  ) external payable returns (bytes memory);

  /**
   * @dev Function, called by Governance, that cancels a transaction, returns action hash
   * @param target smart contract target
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   **/
  function cancelTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 executionTime,
    bool withDelegatecall
  ) external returns (bytes32);

  /**
   * @dev Getter of the current admin address (should be governance)
   * @return The address of the current admin
   **/
  function getAdmin() external view returns (address);

  /**
   * @dev Getter of the current pending admin address
   * @return The address of the pending admin
   **/
  function getPendingAdmin() external view returns (address);

  /**
   * @dev Getter of the delay between queuing and execution
   * @return The delay in seconds
   **/
  function getDelay() external view returns (uint256);

  /**
   * @dev Returns whether an action (via actionHash) is queued
   * @param actionHash hash of the action to be checked
   * keccak256(abi.encode(target, value, signature, data, executionTime, withDelegatecall))
   * @return true if underlying action of actionHash is queued
   **/
  function isActionQueued(bytes32 actionHash) external view returns (bool);

  /**
   * @dev Checks whether a proposal is over its grace period
   * @param governance Governance contract
   * @param proposalId Id of the proposal against which to test
   * @return true of proposal is over grace period
   **/
  function isProposalOverGracePeriod(IKyberGovernance governance, uint256 proposalId)
    external
    view
    returns (bool);

  /**
   * @dev Getter of grace period constant
   * @return grace period in seconds
   **/
  function GRACE_PERIOD() external view returns (uint256);

  /**
   * @dev Getter of minimum delay constant
   * @return minimum delay in seconds
   **/
  function MINIMUM_DELAY() external view returns (uint256);

  /**
   * @dev Getter of maximum delay constant
   * @return maximum delay in seconds
   **/
  function MAXIMUM_DELAY() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

import {IExecutorWithTimelock} from './IExecutorWithTimelock.sol';
import {IVotingPowerStrategy} from './IVotingPowerStrategy.sol';

interface IKyberGovernance {
  enum ProposalState {
    Pending,
    Canceled,
    Active,
    Failed,
    Succeeded,
    Queued,
    Expired,
    Executed,
    Finalized
  }
  enum ProposalType {Generic, Binary}

  /// For Binary proposal, optionBitMask is 0/1/2
  /// For Generic proposal, optionBitMask is bitmask of voted options
  struct Vote {
    uint32 optionBitMask;
    uint224 votingPower;
  }

  struct ProposalWithoutVote {
    uint256 id;
    ProposalType proposalType;
    address creator;
    IExecutorWithTimelock executor;
    IVotingPowerStrategy strategy;
    address[] targets;
    uint256[] weiValues;
    string[] signatures;
    bytes[] calldatas;
    bool[] withDelegatecalls;
    string[] options;
    uint256[] voteCounts;
    uint256 totalVotes;
    uint256 maxVotingPower;
    uint256 startTime;
    uint256 endTime;
    uint256 executionTime;
    string link;
    bool executed;
    bool canceled;
  }

  struct Proposal {
    ProposalWithoutVote proposalData;
    mapping(address => Vote) votes;
  }

  struct BinaryProposalParams {
    address[] targets;
    uint256[] weiValues;
    string[] signatures;
    bytes[] calldatas;
    bool[] withDelegatecalls;
  }

  /**
   * @dev emitted when a new binary proposal is created
   * @param proposalId id of the binary proposal
   * @param creator address of the creator
   * @param executor ExecutorWithTimelock contract that will execute the proposal
   * @param strategy votingPowerStrategy contract to calculate voting power
   * @param targets list of contracts called by proposal's associated transactions
   * @param weiValues list of value in wei for each propoposal's associated transaction
   * @param signatures list of function signatures (can be empty) to be used
   *     when created the callData
   * @param calldatas list of calldatas: if associated signature empty,
   *     calldata ready, else calldata is arguments
   * @param withDelegatecalls boolean, true = transaction delegatecalls the taget,
   *    else calls the target
   * @param startTime timestamp when vote starts
   * @param endTime timestamp when vote ends
   * @param link URL link of the proposal
   * @param maxVotingPower max voting power for this proposal
   **/
  event BinaryProposalCreated(
    uint256 proposalId,
    address indexed creator,
    IExecutorWithTimelock indexed executor,
    IVotingPowerStrategy indexed strategy,
    address[] targets,
    uint256[] weiValues,
    string[] signatures,
    bytes[] calldatas,
    bool[] withDelegatecalls,
    uint256 startTime,
    uint256 endTime,
    string link,
    uint256 maxVotingPower
  );

  /**
   * @dev emitted when a new generic proposal is created
   * @param proposalId id of the generic proposal
   * @param creator address of the creator
   * @param executor ExecutorWithTimelock contract that will execute the proposal
   * @param strategy votingPowerStrategy contract to calculate voting power
   * @param options list of proposal vote options
   * @param startTime timestamp when vote starts
   * @param endTime timestamp when vote ends
   * @param link URL link of the proposal
   * @param maxVotingPower max voting power for this proposal
   **/
  event GenericProposalCreated(
    uint256 proposalId,
    address indexed creator,
    IExecutorWithTimelock indexed executor,
    IVotingPowerStrategy indexed strategy,
    string[] options,
    uint256 startTime,
    uint256 endTime,
    string link,
    uint256 maxVotingPower
  );

  /**
   * @dev emitted when a proposal is canceled
   * @param proposalId id of the proposal
   **/
  event ProposalCanceled(uint256 proposalId);

  /**
   * @dev emitted when a proposal is queued
   * @param proposalId id of the proposal
   * @param executionTime time when proposal underlying transactions can be executed
   * @param initiatorQueueing address of the initiator of the queuing transaction
   **/
  event ProposalQueued(
    uint256 indexed proposalId,
    uint256 executionTime,
    address indexed initiatorQueueing
  );
  /**
   * @dev emitted when a proposal is executed
   * @param proposalId id of the proposal
   * @param initiatorExecution address of the initiator of the execution transaction
   **/
  event ProposalExecuted(uint256 proposalId, address indexed initiatorExecution);
  /**
   * @dev emitted when a vote is registered
   * @param proposalId id of the proposal
   * @param voter address of the voter
   * @param voteOptions vote options selected by voter
   * @param votingPower Power of the voter/vote
   **/
  event VoteEmitted(
    uint256 indexed proposalId,
    address indexed voter,
    uint32 indexed voteOptions,
    uint224 votingPower
  );

  /**
   * @dev emitted when a vote is registered
   * @param proposalId id of the proposal
   * @param voter address of the voter
   * @param voteOptions vote options selected by voter
   * @param oldVotingPower Old power of the voter/vote
   * @param newVotingPower New power of the voter/vote
   **/
  event VotingPowerChanged(
    uint256 indexed proposalId,
    address indexed voter,
    uint32 indexed voteOptions,
    uint224 oldVotingPower,
    uint224 newVotingPower
  );

  event DaoOperatorTransferred(address indexed newDaoOperator);

  event ExecutorAuthorized(address indexed executor);

  event ExecutorUnauthorized(address indexed executor);

  event VotingPowerStrategyAuthorized(address indexed strategy);

  event VotingPowerStrategyUnauthorized(address indexed strategy);

  /**
   * @dev Function is triggered when users withdraw from staking and change voting power
   */
  function handleVotingPowerChanged(
    address staker,
    uint256 newVotingPower,
    uint256[] calldata proposalIds
  ) external;

  /**
   * @dev Creates a Binary Proposal (needs to be validated by the Proposal Validator)
   * @param executor The ExecutorWithTimelock contract that will execute the proposal
   * @param strategy voting power strategy of the proposal
   * @param executionParams data for execution, includes
   *   targets list of contracts called by proposal's associated transactions
   *   weiValues list of value in wei for each proposal's associated transaction
   *   signatures list of function signatures (can be empty)
   *        to be used when created the callData
   *   calldatas list of calldatas: if associated signature empty,
   *        calldata ready, else calldata is arguments
   *   withDelegatecalls boolean, true = transaction delegatecalls the taget,
   *        else calls the target
   * @param startTime start timestamp to allow vote
   * @param endTime end timestamp of the proposal
   * @param link link to the proposal description
   **/
  function createBinaryProposal(
    IExecutorWithTimelock executor,
    IVotingPowerStrategy strategy,
    BinaryProposalParams memory executionParams,
    uint256 startTime,
    uint256 endTime,
    string memory link
  ) external returns (uint256 proposalId);

  /**
   * @dev Creates a Generic Proposal
   * @param executor ExecutorWithTimelock contract that will execute the proposal
   * @param strategy votingPowerStrategy contract to calculate voting power
   * @param options list of proposal vote options
   * @param startTime timestamp when vote starts
   * @param endTime timestamp when vote ends
   * @param link URL link of the proposal
   **/
  function createGenericProposal(
    IExecutorWithTimelock executor,
    IVotingPowerStrategy strategy,
    string[] memory options,
    uint256 startTime,
    uint256 endTime,
    string memory link
  ) external returns (uint256 proposalId);

  /**
   * @dev Cancels a Proposal,
   * either at anytime by guardian
   * or when proposal is Pending/Active and threshold no longer reached
   * @param proposalId id of the proposal
   **/
  function cancel(uint256 proposalId) external;

  /**
   * @dev Queue the proposal (If Proposal Succeeded)
   * @param proposalId id of the proposal to queue
   **/
  function queue(uint256 proposalId) external;

  /**
   * @dev Execute the proposal (If Proposal Queued)
   * @param proposalId id of the proposal to execute
   **/
  function execute(uint256 proposalId) external payable;

  /**
   * @dev Function allowing msg.sender to vote for/against a proposal
   * @param proposalId id of the proposal
   * @param optionBitMask vote option(s) selected
   **/
  function submitVote(uint256 proposalId, uint256 optionBitMask) external;

  /**
   * @dev Function to register the vote of user that has voted offchain via signature
   * @param proposalId id of the proposal
   * @param choice the bit mask of voted options
   * @param v v part of the voter signature
   * @param r r part of the voter signature
   * @param s s part of the voter signature
   **/
  function submitVoteBySignature(
    uint256 proposalId,
    uint256 choice,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  /**
   * @dev Add new addresses to the list of authorized executors
   * @param executors list of new addresses to be authorized executors
   **/
  function authorizeExecutors(address[] calldata executors) external;

  /**
   * @dev Remove addresses to the list of authorized executors
   * @param executors list of addresses to be removed as authorized executors
   **/
  function unauthorizeExecutors(address[] calldata executors) external;

  /**
   * @dev Add new addresses to the list of authorized strategies
   * @param strategies list of new addresses to be authorized strategies
   **/
  function authorizeVotingPowerStrategies(address[] calldata strategies) external;

  /**
   * @dev Remove addresses to the list of authorized strategies
   * @param strategies list of addresses to be removed as authorized strategies
   **/
  function unauthorizeVotingPowerStrategies(address[] calldata strategies) external;

  /**
   * @dev Returns whether an address is an authorized executor
   * @param executor address to evaluate as authorized executor
   * @return true if authorized
   **/
  function isExecutorAuthorized(address executor) external view returns (bool);

  /**
   * @dev Returns whether an address is an authorized strategy
   * @param strategy address to evaluate as authorized strategy
   * @return true if authorized
   **/
  function isVotingPowerStrategyAuthorized(address strategy) external view returns (bool);

  /**
   * @dev Getter the address of the guardian, that can mainly cancel proposals
   * @return The address of the guardian
   **/
  function getDaoOperator() external view returns (address);

  /**
   * @dev Getter of the proposal count (the current number of proposals ever created)
   * @return the proposal count
   **/
  function getProposalsCount() external view returns (uint256);

  /**
   * @dev Getter of a proposal by id
   * @param proposalId id of the proposal to get
   * @return the proposal as ProposalWithoutVote memory object
   **/
  function getProposalById(uint256 proposalId) external view returns (ProposalWithoutVote memory);

  /**
   * @dev Getter of the vote data of a proposal by id
   * including totalVotes, voteCounts and options
   * @param proposalId id of the proposal
   * @return (totalVotes, voteCounts, options)
   **/
  function getProposalVoteDataById(uint256 proposalId)
    external
    view
    returns (
      uint256,
      uint256[] memory,
      string[] memory
    );

  /**
   * @dev Getter of the Vote of a voter about a proposal
   * Note: Vote is a struct: ({uint32 bitOptionMask, uint224 votingPower})
   * @param proposalId id of the proposal
   * @param voter address of the voter
   * @return The associated Vote memory object
   **/
  function getVoteOnProposal(uint256 proposalId, address voter)
    external
    view
    returns (Vote memory);

  /**
   * @dev Get the current state of a proposal
   * @param proposalId id of the proposal
   * @return The current state if the proposal
   **/
  function getProposalState(uint256 proposalId) external view returns (ProposalState);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

import {IWithdrawHandler} from '../staking/IWithdrawHandler.sol';

interface IVotingPowerStrategy is IWithdrawHandler {
  /**
   * @dev call by governance when create a proposal
   */
  function handleProposalCreation(
    uint256 proposalId,
    uint256 startTime,
    uint256 endTime
  ) external;

  /**
   * @dev call by governance when cancel a proposal
   */
  function handleProposalCancellation(uint256 proposalId) external;

  /**
   * @dev call by governance when submitting a vote
   * @param choice: unused param for future usage
   * @return votingPower of voter
   */
  function handleVote(
    address voter,
    uint256 proposalId,
    uint256 choice
  ) external returns (uint256 votingPower);

  /**
   * @dev get voter's voting power given timestamp
   * @dev for reading purposes and validating voting power for creating/canceling proposal in the furture
   * @dev when submitVote, should call 'handleVote' instead
   */
  function getVotingPower(address voter, uint256 timestamp)
    external
    view
    returns (uint256 votingPower);

  /**
   * @dev validate that startTime and endTime are suitable for calculating voting power
   * @dev with current version, startTime and endTime must be in the sameEpcoh
   */
  function validateProposalCreation(uint256 startTime, uint256 endTime)
    external
    view
    returns (bool);

  /**
   * @dev getMaxVotingPower at current time
   * @dev call by governance when creating a proposal
   */
  function getMaxVotingPower() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

/**
 * @title Interface for callbacks hooks when user withdraws from staking contract
 */
interface IWithdrawHandler {
  function handleWithdrawal(address staker, uint256 reduceAmount) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

import {IKyberGovernance} from './IKyberGovernance.sol';
import {IVotingPowerStrategy} from './IVotingPowerStrategy.sol';

interface IProposalValidator {
  /**
   * @dev Called to validate a binary proposal
   * @param strategy votingPowerStrategy contract to calculate voting power
   * @param creator address of the creator
   * @param startTime timestamp when vote starts
   * @param endTime timestamp when vote ends
   * @param daoOperator address of daoOperator
   * @return boolean, true if can be created
   **/
  function validateBinaryProposalCreation(
    IVotingPowerStrategy strategy,
    address creator,
    uint256 startTime,
    uint256 endTime,
    address daoOperator
  ) external view returns (bool);

  /**
   * @dev Called to validate a generic proposal
   * @param strategy votingPowerStrategy contract to calculate voting power
   * @param creator address of the creator
   * @param startTime timestamp when vote starts
   * @param endTime timestamp when vote ends
   * @param options list of proposal vote options
   * @param daoOperator address of daoOperator
   * @return boolean, true if can be created
   **/
  function validateGenericProposalCreation(
    IVotingPowerStrategy strategy,
    address creator,
    uint256 startTime,
    uint256 endTime,
    string[] calldata options,
    address daoOperator
  ) external view returns (bool);

  /**
   * @dev Called to validate the cancellation of a proposal
   * @param governance governance contract to fetch proposals from
   * @param proposalId Id of the generic proposal
   * @param user entity initiating the cancellation
   * @return boolean, true if can be cancelled
   **/
  function validateProposalCancellation(
    IKyberGovernance governance,
    uint256 proposalId,
    address user
  ) external view returns (bool);

  /**
   * @dev Returns whether a binary proposal passed or not
   * @param governance governance contract to fetch proposals from
   * @param proposalId Id of the proposal to set
   * @return true if proposal passed
   **/
  function isBinaryProposalPassed(IKyberGovernance governance, uint256 proposalId)
    external
    view
    returns (bool);

  /**
   * @dev Check whether a proposal has reached quorum
   * @param governance governance contract to fetch proposals from
   * @param proposalId Id of the proposal to verify
   * @return voting power needed for a proposal to pass
   **/
  function isQuorumValid(IKyberGovernance governance, uint256 proposalId)
    external
    view
    returns (bool);

  /**
   * @dev Check whether a proposal has enough extra FOR-votes than AGAINST-votes
   * @param governance governance contract to fetch proposals from
   * @param proposalId Id of the proposal to verify
   * @return true if enough For-Votes
   **/
  function isVoteDifferentialValid(IKyberGovernance governance, uint256 proposalId)
    external
    view
    returns (bool);

  /**
   * @dev Get maximum vote options for a generic proposal
   * @return the maximum no. of vote options possible for a generic proposal
   **/
  function MAX_VOTING_OPTIONS() external view returns (uint256);

  /**
   * @dev Get minimum voting duration constant value
   * @return the minimum voting duration value in seconds
   **/
  function MIN_VOTING_DURATION() external view returns (uint256);

  /**
   * @dev Get the vote differential threshold constant value
   * to compare with % of for votes/total supply - % of against votes/total supply
   * @return the vote differential threshold value (100 <=> 1%)
   **/
  function VOTE_DIFFERENTIAL() external view returns (uint256);

  /**
   * @dev Get quorum threshold constant value
   * to compare with % of for votes/total supply
   * @return the quorum threshold value (100 <=> 1%)
   **/
  function MINIMUM_QUORUM() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./IERC20Ext.sol";


/**
 * @title Kyber utility file
 * mostly shared constants and rate calculation helpers
 * inherited by most of kyber contracts.
 * previous utils implementations are for previous solidity versions.
 */
abstract contract Utils {
    // Declared constants below to be used in tandem with
    // getDecimalsConstant(), for gas optimization purposes
    // which return decimals from a constant list of popular
    // tokens.
    IERC20Ext internal constant ETH_TOKEN_ADDRESS = IERC20Ext(
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
    );
    IERC20Ext internal constant USDT_TOKEN_ADDRESS = IERC20Ext(
        0xdAC17F958D2ee523a2206206994597C13D831ec7
    );
    IERC20Ext internal constant DAI_TOKEN_ADDRESS = IERC20Ext(
        0x6B175474E89094C44Da98b954EedeAC495271d0F
    );
    IERC20Ext internal constant USDC_TOKEN_ADDRESS = IERC20Ext(
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
    );
    IERC20Ext internal constant WBTC_TOKEN_ADDRESS = IERC20Ext(
        0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599
    );
    IERC20Ext internal constant KNC_TOKEN_ADDRESS = IERC20Ext(
        0xdd974D5C2e2928deA5F71b9825b8b646686BD200
    );
    uint256 public constant BPS = 10000; // Basic Price Steps. 1 step = 0.01%
    uint256 internal constant PRECISION = (10**18);
    uint256 internal constant MAX_QTY = (10**28); // 10B tokens
    uint256 internal constant MAX_RATE = (PRECISION * 10**7); // up to 10M tokens per eth
    uint256 internal constant MAX_DECIMALS = 18;
    uint256 internal constant ETH_DECIMALS = 18;
    uint256 internal constant MAX_ALLOWANCE = uint256(-1); // token.approve inifinite

    mapping(IERC20Ext => uint256) internal decimals;

    /// @dev Sets the decimals of a token to storage if not already set, and returns
    ///      the decimals value of the token. Prefer using this function over
    ///      getDecimals(), to avoid forgetting to set decimals in local storage.
    /// @param token The token type
    /// @return tokenDecimals The decimals of the token
    function getSetDecimals(IERC20Ext token) internal returns (uint256 tokenDecimals) {
        tokenDecimals = getDecimalsConstant(token);
        if (tokenDecimals > 0) return tokenDecimals;

        tokenDecimals = decimals[token];
        if (tokenDecimals == 0) {
            tokenDecimals = token.decimals();
            decimals[token] = tokenDecimals;
        }
    }

    /// @dev Get the balance of a user
    /// @param token The token type
    /// @param user The user's address
    /// @return The balance
    function getBalance(IERC20Ext token, address user) internal view returns (uint256) {
        if (token == ETH_TOKEN_ADDRESS) {
            return user.balance;
        } else {
            return token.balanceOf(user);
        }
    }

    /// @dev Get the decimals of a token, read from the constant list, storage,
    ///      or from token.decimals(). Prefer using getSetDecimals when possible.
    /// @param token The token type
    /// @return tokenDecimals The decimals of the token
    function getDecimals(IERC20Ext token) internal view returns (uint256 tokenDecimals) {
        // return token decimals if has constant value
        tokenDecimals = getDecimalsConstant(token);
        if (tokenDecimals > 0) return tokenDecimals;

        // handle case where token decimals is not a declared decimal constant
        tokenDecimals = decimals[token];
        // moreover, very possible that old tokens have decimals 0
        // these tokens will just have higher gas fees.
        return (tokenDecimals > 0) ? tokenDecimals : token.decimals();
    }

    function calcDestAmount(
        IERC20Ext src,
        IERC20Ext dest,
        uint256 srcAmount,
        uint256 rate
    ) internal view returns (uint256) {
        return calcDstQty(srcAmount, getDecimals(src), getDecimals(dest), rate);
    }

    function calcSrcAmount(
        IERC20Ext src,
        IERC20Ext dest,
        uint256 destAmount,
        uint256 rate
    ) internal view returns (uint256) {
        return calcSrcQty(destAmount, getDecimals(src), getDecimals(dest), rate);
    }

    function calcDstQty(
        uint256 srcQty,
        uint256 srcDecimals,
        uint256 dstDecimals,
        uint256 rate
    ) internal pure returns (uint256) {
        require(srcQty <= MAX_QTY, "srcQty > MAX_QTY");
        require(rate <= MAX_RATE, "rate > MAX_RATE");

        if (dstDecimals >= srcDecimals) {
            require((dstDecimals - srcDecimals) <= MAX_DECIMALS, "dst - src > MAX_DECIMALS");
            return (srcQty * rate * (10**(dstDecimals - srcDecimals))) / PRECISION;
        } else {
            require((srcDecimals - dstDecimals) <= MAX_DECIMALS, "src - dst > MAX_DECIMALS");
            return (srcQty * rate) / (PRECISION * (10**(srcDecimals - dstDecimals)));
        }
    }

    function calcSrcQty(
        uint256 dstQty,
        uint256 srcDecimals,
        uint256 dstDecimals,
        uint256 rate
    ) internal pure returns (uint256) {
        require(dstQty <= MAX_QTY, "dstQty > MAX_QTY");
        require(rate <= MAX_RATE, "rate > MAX_RATE");

        //source quantity is rounded up. to avoid dest quantity being too low.
        uint256 numerator;
        uint256 denominator;
        if (srcDecimals >= dstDecimals) {
            require((srcDecimals - dstDecimals) <= MAX_DECIMALS, "src - dst > MAX_DECIMALS");
            numerator = (PRECISION * dstQty * (10**(srcDecimals - dstDecimals)));
            denominator = rate;
        } else {
            require((dstDecimals - srcDecimals) <= MAX_DECIMALS, "dst - src > MAX_DECIMALS");
            numerator = (PRECISION * dstQty);
            denominator = (rate * (10**(dstDecimals - srcDecimals)));
        }
        return (numerator + denominator - 1) / denominator; //avoid rounding down errors
    }

    function calcRateFromQty(
        uint256 srcAmount,
        uint256 destAmount,
        uint256 srcDecimals,
        uint256 dstDecimals
    ) internal pure returns (uint256) {
        require(srcAmount <= MAX_QTY, "srcAmount > MAX_QTY");
        require(destAmount <= MAX_QTY, "destAmount > MAX_QTY");

        if (dstDecimals >= srcDecimals) {
            require((dstDecimals - srcDecimals) <= MAX_DECIMALS, "dst - src > MAX_DECIMALS");
            return ((destAmount * PRECISION) / ((10**(dstDecimals - srcDecimals)) * srcAmount));
        } else {
            require((srcDecimals - dstDecimals) <= MAX_DECIMALS, "src - dst > MAX_DECIMALS");
            return ((destAmount * PRECISION * (10**(srcDecimals - dstDecimals))) / srcAmount);
        }
    }

    /// @dev save storage access by declaring token decimal constants
    /// @param token The token type
    /// @return token decimals
    function getDecimalsConstant(IERC20Ext token) internal pure returns (uint256) {
        if (token == ETH_TOKEN_ADDRESS) {
            return ETH_DECIMALS;
        } else if (token == USDT_TOKEN_ADDRESS) {
            return 6;
        } else if (token == DAI_TOKEN_ADDRESS) {
            return 18;
        } else if (token == USDC_TOKEN_ADDRESS) {
            return 6;
        } else if (token == WBTC_TOKEN_ADDRESS) {
            return 8;
        } else if (token == KNC_TOKEN_ADDRESS) {
            return 18;
        } else {
            return 0;
        }
    }

    function minOf(uint256 x, uint256 y) internal pure returns (uint256) {
        return x > y ? y : x;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/**
 * @dev Interface extending ERC20 standard to include decimals() as
 *      it is optional in the OpenZeppelin IERC20 interface.
 */
interface IERC20Ext is IERC20 {
    /**
     * @dev This function is required as Kyber requires to interact
     *      with token.decimals() with many of its operations.
     */
    function decimals() external view returns (uint8 digits);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
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