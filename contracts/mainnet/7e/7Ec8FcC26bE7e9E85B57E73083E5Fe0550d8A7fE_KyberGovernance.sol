// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';
import {PermissionAdmin} from '@kyber.network/utils-sc/contracts/PermissionAdmin.sol';
import {IKyberGovernance} from '../interfaces/governance/IKyberGovernance.sol';
import {IExecutorWithTimelock} from '../interfaces/governance/IExecutorWithTimelock.sol';
import {IVotingPowerStrategy} from '../interfaces/governance/IVotingPowerStrategy.sol';
import {IProposalValidator} from '../interfaces/governance/IProposalValidator.sol';
import {getChainId} from '../misc/Helpers.sol';

/**
 * @title Kyber Governance contract for Kyber 3.0
 * - Create a Proposal
 * - Cancel a Proposal
 * - Queue a Proposal
 * - Execute a Proposal
 * - Submit Vote to a Proposal
 * Proposal States : Pending => Active => Succeeded(/Failed/Finalized)
 *                   => Queued => Executed(/Expired)
 *                   The transition to "Canceled" can appear in multiple states
 **/
contract KyberGovernance is IKyberGovernance, PermissionAdmin {
  using SafeMath for uint256;

  bytes32 public constant DOMAIN_TYPEHASH = keccak256(
    'EIP712Domain(string name,uint256 chainId,address verifyingContract)'
  );
  bytes32 public constant VOTE_EMITTED_TYPEHASH = keccak256(
    'VoteEmitted(uint256 id,uint256 optionBitMask)'
  );
  string public constant NAME = 'Kyber Governance';

  address private _daoOperator;
  uint256 private _proposalsCount;
  mapping(uint256 => Proposal) private _proposals;
  mapping(address => bool) private _authorizedExecutors;
  mapping(address => bool) private _authorizedVotingPowerStrategies;

  constructor(
    address admin,
    address daoOperator,
    address[] memory executors,
    address[] memory votingPowerStrategies
  ) PermissionAdmin(admin) {
    require(daoOperator != address(0), 'invalid dao operator');
    _daoOperator = daoOperator;

    _authorizeExecutors(executors);
    _authorizeVotingPowerStrategies(votingPowerStrategies);
  }

  /**
   * @dev Creates a Binary Proposal (needs to be validated by the Proposal Validator)
   * @param executor The ExecutorWithTimelock contract that will execute the proposal
   * @param strategy voting power strategy of the proposal
   * @param executionParams data for execution, includes
   *   targets list of contracts called by proposal's associated transactions
   *   weiValues list of value in wei for each proposal's associated transaction
   *   signatures list of function signatures (can be empty) to be used when created the callData
   *   calldatas list of calldatas: if associated signature empty,
   *        calldata ready, else calldata is arguments
   *   withDelegatecalls boolean, true = transaction delegatecalls the taget,
   *         else calls the target
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
  ) external override returns (uint256 proposalId) {
    require(executionParams.targets.length != 0, 'create binary invalid empty targets');
    require(
      executionParams.targets.length == executionParams.weiValues.length &&
        executionParams.targets.length == executionParams.signatures.length &&
        executionParams.targets.length == executionParams.calldatas.length &&
        executionParams.targets.length == executionParams.withDelegatecalls.length,
      'create binary inconsistent params length'
    );

    require(isExecutorAuthorized(address(executor)), 'create binary executor not authorized');
    require(
      isVotingPowerStrategyAuthorized(address(strategy)),
      'create binary strategy not authorized'
    );

    proposalId = _proposalsCount;
    require(
      IProposalValidator(address(executor)).validateBinaryProposalCreation(
        strategy,
        msg.sender,
        startTime,
        endTime,
        _daoOperator
      ),
      'validate proposal creation invalid'
    );

    ProposalWithoutVote storage newProposalData = _proposals[proposalId].proposalData;
    newProposalData.id = proposalId;
    newProposalData.proposalType = ProposalType.Binary;
    newProposalData.creator = msg.sender;
    newProposalData.executor = executor;
    newProposalData.targets = executionParams.targets;
    newProposalData.weiValues = executionParams.weiValues;
    newProposalData.signatures = executionParams.signatures;
    newProposalData.calldatas = executionParams.calldatas;
    newProposalData.withDelegatecalls = executionParams.withDelegatecalls;
    newProposalData.startTime = startTime;
    newProposalData.endTime = endTime;
    newProposalData.strategy = strategy;
    newProposalData.link = link;

    // only 2 options, YES and NO
    newProposalData.options.push('YES');
    newProposalData.options.push('NO');
    newProposalData.voteCounts.push(0);
    newProposalData.voteCounts.push(0);
    // use max voting power to finalise the proposal
    newProposalData.maxVotingPower = strategy.getMaxVotingPower();

    _proposalsCount++;
    // call strategy to record data if needed
    strategy.handleProposalCreation(proposalId, startTime, endTime);

    emit BinaryProposalCreated(
      proposalId,
      msg.sender,
      executor,
      strategy,
      executionParams.targets,
      executionParams.weiValues,
      executionParams.signatures,
      executionParams.calldatas,
      executionParams.withDelegatecalls,
      startTime,
      endTime,
      link,
      newProposalData.maxVotingPower
    );
  }

  /**
   * @dev Creates a Generic Proposal (needs to be validated by the Proposal Validator)
   *    It only gets the winning option without any executions
   * @param executor The ExecutorWithTimelock contract that will execute the proposal
   * @param strategy voting power strategy of the proposal
   * @param options list of options to vote for
   * @param startTime start timestamp to allow vote
   * @param endTime end timestamp of the proposal
   * @param link link to the proposal description
   **/
  function createGenericProposal(
    IExecutorWithTimelock executor,
    IVotingPowerStrategy strategy,
    string[] memory options,
    uint256 startTime,
    uint256 endTime,
    string memory link
  )
    external override returns (uint256 proposalId)
  {
    require(
      isExecutorAuthorized(address(executor)),
      'create generic executor not authorized'
    );
    require(
      isVotingPowerStrategyAuthorized(address(strategy)),
      'create generic strategy not authorized'
    );
    proposalId = _proposalsCount;
    require(
      IProposalValidator(address(executor)).validateGenericProposalCreation(
        strategy,
        msg.sender,
        startTime,
        endTime,
        options,
        _daoOperator
      ),
      'validate proposal creation invalid'
    );
    Proposal storage newProposal = _proposals[proposalId];
    ProposalWithoutVote storage newProposalData = newProposal.proposalData;
    newProposalData.id = proposalId;
    newProposalData.proposalType = ProposalType.Generic;
    newProposalData.creator = msg.sender;
    newProposalData.executor = executor;
    newProposalData.startTime = startTime;
    newProposalData.endTime = endTime;
    newProposalData.strategy = strategy;
    newProposalData.link = link;
    newProposalData.options = options;
    newProposalData.voteCounts = new uint256[](options.length);
    // use max voting power to finalise the proposal
    newProposalData.maxVotingPower = strategy.getMaxVotingPower();

    _proposalsCount++;
    // call strategy to record data if needed
    strategy.handleProposalCreation(proposalId, startTime, endTime);

    emit GenericProposalCreated(
      proposalId,
      msg.sender,
      executor,
      strategy,
      options,
      startTime,
      endTime,
      link,
      newProposalData.maxVotingPower
    );
  }

  /**
   * @dev Cancels a Proposal.
   * - Callable by the _daoOperator with relaxed conditions,
   *   or by anybody if the conditions of cancellation on the executor are fulfilled
   * @param proposalId id of the proposal
   **/
  function cancel(uint256 proposalId) external override {
    require(proposalId < _proposalsCount, 'invalid proposal id');
    ProposalState state = getProposalState(proposalId);
    require(
      state != ProposalState.Executed &&
        state != ProposalState.Canceled &&
        state != ProposalState.Expired &&
        state != ProposalState.Finalized,
      'invalid state to cancel'
    );

    ProposalWithoutVote storage proposal = _proposals[proposalId].proposalData;
    require(
      msg.sender == _daoOperator ||
        IProposalValidator(address(proposal.executor)).validateProposalCancellation(
          IKyberGovernance(this),
          proposalId,
          proposal.creator
        ),
      'validate proposal cancellation failed'
    );
    proposal.canceled = true;
    if (proposal.proposalType == ProposalType.Binary) {
      for (uint256 i = 0; i < proposal.targets.length; i++) {
        proposal.executor.cancelTransaction(
          proposal.targets[i],
          proposal.weiValues[i],
          proposal.signatures[i],
          proposal.calldatas[i],
          proposal.executionTime,
          proposal.withDelegatecalls[i]
        );
      }
    }
    // notify voting power strategy about the cancellation
    proposal.strategy.handleProposalCancellation(proposalId);

    emit ProposalCanceled(proposalId);
  }

  /**
   * @dev Queue the proposal (If Proposal Succeeded), only for Binary proposals
   * @param proposalId id of the proposal to queue
   **/
  function queue(uint256 proposalId) external override {
    require(proposalId < _proposalsCount, 'invalid proposal id');
    require(
      getProposalState(proposalId) == ProposalState.Succeeded,
      'invalid state to queue'
    );
    ProposalWithoutVote storage proposal = _proposals[proposalId].proposalData;
    // generic proposal does not have Succeeded state
    assert(proposal.proposalType == ProposalType.Binary);
    uint256 executionTime = block.timestamp.add(proposal.executor.getDelay());
    for (uint256 i = 0; i < proposal.targets.length; i++) {
      _queueOrRevert(
        proposal.executor,
        proposal.targets[i],
        proposal.weiValues[i],
        proposal.signatures[i],
        proposal.calldatas[i],
        executionTime,
        proposal.withDelegatecalls[i]
      );
    }
    proposal.executionTime = executionTime;

    emit ProposalQueued(proposalId, executionTime, msg.sender);
  }

  /**
   * @dev Execute the proposal (If Proposal Queued), only for Binary proposals
   * @param proposalId id of the proposal to execute
   **/
  function execute(uint256 proposalId) external override payable {
    require(proposalId < _proposalsCount, 'invalid proposal id');
    require(getProposalState(proposalId) == ProposalState.Queued, 'only queued proposals');
    ProposalWithoutVote storage proposal = _proposals[proposalId].proposalData;
    // generic proposal does not have Queued state
    assert(proposal.proposalType == ProposalType.Binary);
    proposal.executed = true;
    for (uint256 i = 0; i < proposal.targets.length; i++) {
      proposal.executor.executeTransaction{value: proposal.weiValues[i]}(
        proposal.targets[i],
        proposal.weiValues[i],
        proposal.signatures[i],
        proposal.calldatas[i],
        proposal.executionTime,
        proposal.withDelegatecalls[i]
      );
    }
    emit ProposalExecuted(proposalId, msg.sender);
  }

  /**
   * @dev Function allowing msg.sender to vote for/against a proposal
   * @param proposalId id of the proposal
   * @param optionBitMask bitmask optionBitMask of voter
   *  for Binary Proposal, optionBitMask should be either 1 or 2 (Accept/Reject)
   *  for Generic Proposal, optionBitMask is the bitmask of voted options
   **/
  function submitVote(uint256 proposalId, uint256 optionBitMask) external override {
    return _submitVote(msg.sender, proposalId, optionBitMask);
  }

  /**
   * @dev Function to register the vote of user that has voted offchain via signature
   * @param proposalId id of the proposal
   * @param optionBitMask the bit mask of voted options
   * @param v v part of the voter signature
   * @param r r part of the voter signature
   * @param s s part of the voter signature
   **/
  function submitVoteBySignature(
    uint256 proposalId,
    uint256 optionBitMask,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external override {
    bytes32 digest = keccak256(
      abi.encodePacked(
        '\x19\x01',
        keccak256(
          abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(NAME)), getChainId(), address(this))
        ),
        keccak256(abi.encode(VOTE_EMITTED_TYPEHASH, proposalId, optionBitMask))
      )
    );
    address signer = ecrecover(digest, v, r, s);
    require(signer != address(0), 'invalid signature');
    return _submitVote(signer, proposalId, optionBitMask);
  }

  /**
   * @dev Function to handle voting power changed for a voter
   *  caller must be the voting power strategy of the proposal
   * @param voter address that has changed the voting power
   * @param newVotingPower new voting power of that address,
   *   old voting power can be taken from records
   * @param proposalIds list proposal ids that belongs to this voting power strategy
   *   should update the voteCound of the active proposals in the list
   **/
  function handleVotingPowerChanged(
    address voter,
    uint256 newVotingPower,
    uint256[] calldata proposalIds
  ) external override {
    uint224 safeNewVotingPower = _safeUint224(newVotingPower);
    for (uint256 i = 0; i < proposalIds.length; i++) {
      // only update for active proposals
      if (getProposalState(proposalIds[i]) != ProposalState.Active) continue;
      ProposalWithoutVote storage proposal = _proposals[proposalIds[i]].proposalData;
      require(address(proposal.strategy) == msg.sender, 'invalid voting power strategy');
      Vote memory vote = _proposals[proposalIds[i]].votes[voter];
      if (vote.optionBitMask == 0) continue; // not voted yet
      uint256 oldVotingPower = uint256(vote.votingPower);
      // update totalVotes of the proposal
      proposal.totalVotes = proposal.totalVotes.add(newVotingPower).sub(oldVotingPower);
      for (uint256 j = 0; j < proposal.options.length; j++) {
        if (vote.optionBitMask & (2**j) == 2**j) {
          // update voteCounts for each voted option
          proposal.voteCounts[j] = proposal.voteCounts[j].add(newVotingPower).sub(oldVotingPower);
        }
      }
      // update voting power of the voter
      _proposals[proposalIds[i]].votes[voter].votingPower = safeNewVotingPower;
      emit VotingPowerChanged(
        proposalIds[i],
        voter,
        vote.optionBitMask,
        vote.votingPower,
        safeNewVotingPower
      );
    }
  }

  /**
  * @dev Transfer dao operator
  * @param newDaoOperator new dao operator
  **/
  function transferDaoOperator(address newDaoOperator) external {
    require(msg.sender == _daoOperator, 'only dao operator');
    require(newDaoOperator != address(0), 'invalid dao operator');
    _daoOperator = newDaoOperator;
    emit DaoOperatorTransferred(newDaoOperator);
  }

  /**
   * @dev Add new addresses to the list of authorized executors
   * @param executors list of new addresses to be authorized executors
   **/
  function authorizeExecutors(address[] memory executors)
    public override onlyAdmin
  {
    _authorizeExecutors(executors);
  }

  /**
   * @dev Remove addresses to the list of authorized executors
   * @param executors list of addresses to be removed as authorized executors
   **/
  function unauthorizeExecutors(address[] memory executors)
    public override onlyAdmin
  {
    _unauthorizeExecutors(executors);
  }

  /**
   * @dev Add new addresses to the list of authorized strategies
   * @param strategies list of new addresses to be authorized strategies
   **/
  function authorizeVotingPowerStrategies(address[] memory strategies)
    public override onlyAdmin
  {
    _authorizeVotingPowerStrategies(strategies);
  }

  /**
   * @dev Remove addresses to the list of authorized strategies
   * @param strategies list of addresses to be removed as authorized strategies
   **/
  function unauthorizeVotingPowerStrategies(address[] memory strategies)
    public
    override
    onlyAdmin
  {
    _unauthorizedVotingPowerStrategies(strategies);
  }

  /**
   * @dev Returns whether an address is an authorized executor
   * @param executor address to evaluate as authorized executor
   * @return true if authorized
   **/
  function isExecutorAuthorized(address executor) public override view returns (bool) {
    return _authorizedExecutors[executor];
  }

  /**
   * @dev Returns whether an address is an authorized strategy
   * @param strategy address to evaluate as authorized strategy
   * @return true if authorized
   **/
  function isVotingPowerStrategyAuthorized(address strategy) public override view returns (bool) {
    return _authorizedVotingPowerStrategies[strategy];
  }

  /**
   * @dev Getter the address of the daoOperator, that can mainly cancel proposals
   * @return The address of the daoOperator
   **/
  function getDaoOperator() external override view returns (address) {
    return _daoOperator;
  }

  /**
   * @dev Getter of the proposal count (the current number of proposals ever created)
   * @return the proposal count
   **/
  function getProposalsCount() external override view returns (uint256) {
    return _proposalsCount;
  }

  /**
   * @dev Getter of a proposal by id
   * @param proposalId id of the proposal to get
   * @return the proposal as ProposalWithoutVote memory object
   **/
  function getProposalById(uint256 proposalId)
    external
    override
    view
    returns (ProposalWithoutVote memory)
  {
    return _proposals[proposalId].proposalData;
  }

  /**
   * @dev Getter of the vote data of a proposal by id
   * including totalVotes, voteCounts and options
   * @param proposalId id of the proposal
   * @return (totalVotes, voteCounts, options)
   **/
  function getProposalVoteDataById(uint256 proposalId)
    external
    override
    view
    returns (
      uint256,
      uint256[] memory,
      string[] memory
    )
  {
    ProposalWithoutVote storage proposal = _proposals[proposalId].proposalData;
    return (proposal.totalVotes, proposal.voteCounts, proposal.options);
  }

  /**
   * @dev Getter of the Vote of a voter about a proposal
   * Note: Vote is a struct: ({uint32 bitOptionMask, uint224 votingPower})
   * @param proposalId id of the proposal
   * @param voter address of the voter
   * @return The associated Vote memory object
   **/
  function getVoteOnProposal(uint256 proposalId, address voter)
    external
    override
    view
    returns (Vote memory)
  {
    return _proposals[proposalId].votes[voter];
  }

  /**
   * @dev Get the current state of a proposal
   * @param proposalId id of the proposal
   * @return The current state if the proposal
   **/
  function getProposalState(uint256 proposalId) public override view returns (ProposalState) {
    require(proposalId < _proposalsCount, 'invalid proposal id');
    ProposalWithoutVote storage proposal = _proposals[proposalId].proposalData;
    if (proposal.canceled) {
      return ProposalState.Canceled;
    } else if (block.timestamp < proposal.startTime) {
      return ProposalState.Pending;
    } else if (block.timestamp <= proposal.endTime) {
      return ProposalState.Active;
    } else if (proposal.proposalType == ProposalType.Generic) {
      return ProposalState.Finalized;
    } else if (
      !IProposalValidator(address(proposal.executor)).isBinaryProposalPassed(
        IKyberGovernance(this),
        proposalId
      )
    ) {
      return ProposalState.Failed;
    } else if (proposal.executionTime == 0) {
      return ProposalState.Succeeded;
    } else if (proposal.executed) {
      return ProposalState.Executed;
    } else if (proposal.executor.isProposalOverGracePeriod(this, proposalId)) {
      return ProposalState.Expired;
    } else {
      return ProposalState.Queued;
    }
  }

  function _queueOrRevert(
    IExecutorWithTimelock executor,
    address target,
    uint256 value,
    string memory signature,
    bytes memory callData,
    uint256 executionTime,
    bool withDelegatecall
  ) internal {
    require(
      !executor.isActionQueued(
        keccak256(abi.encode(target, value, signature, callData, executionTime, withDelegatecall))
      ),
      'duplicated action'
    );
    executor.queueTransaction(target, value, signature, callData, executionTime, withDelegatecall);
  }

  function _submitVote(
    address voter,
    uint256 proposalId,
    uint256 optionBitMask
  ) internal {
    require(proposalId < _proposalsCount, 'invalid proposal id');
    require(getProposalState(proposalId) == ProposalState.Active, 'voting closed');
    ProposalWithoutVote storage proposal = _proposals[proposalId].proposalData;
    uint256 numOptions = proposal.options.length;
    if (proposal.proposalType == ProposalType.Binary) {
      // either Yes (1) or No (2)
      require(optionBitMask == 1 || optionBitMask == 2, 'wrong vote for binary proposal');
    } else {
      require(
        optionBitMask > 0 && optionBitMask < 2**numOptions,
        'invalid options for generic proposal'
      );
    }

    Vote memory vote = _proposals[proposalId].votes[voter];
    uint256 votingPower = proposal.strategy.handleVote(voter, proposalId, optionBitMask);
    if (vote.optionBitMask == 0) {
      // first time vote, increase the totalVotes of the proposal
      proposal.totalVotes = proposal.totalVotes.add(votingPower);
    }
    for (uint256 i = 0; i < proposal.options.length; i++) {
      bool hasVoted = (vote.optionBitMask & (2**i)) == 2**i;
      bool isVoting = (optionBitMask & (2**i)) == 2**i;
      if (hasVoted && !isVoting) {
        proposal.voteCounts[i] = proposal.voteCounts[i].sub(votingPower);
      } else if (!hasVoted && isVoting) {
        proposal.voteCounts[i] = proposal.voteCounts[i].add(votingPower);
      }
    }

    _proposals[proposalId].votes[voter] = Vote({
      optionBitMask: _safeUint32(optionBitMask),
      votingPower: _safeUint224(votingPower)
    });
    emit VoteEmitted(proposalId, voter, _safeUint32(optionBitMask), _safeUint224(votingPower));
  }

  function _authorizeExecutors(address[] memory executors) internal {
    for(uint256 i = 0; i < executors.length; i++) {
      _authorizedExecutors[executors[i]] = true;
      emit ExecutorAuthorized(executors[i]);
    }
  }

  function _unauthorizeExecutors(address[] memory executors) internal {
    for(uint256 i = 0; i < executors.length; i++) {
      _authorizedExecutors[executors[i]] = false;
      emit ExecutorUnauthorized(executors[i]);
    }
  }

  function _authorizeVotingPowerStrategies(address[] memory strategies) internal {
    for(uint256 i = 0; i < strategies.length; i++) {
      _authorizedVotingPowerStrategies[strategies[i]] = true;
      emit VotingPowerStrategyAuthorized(strategies[i]);
    }
  }

  function _unauthorizedVotingPowerStrategies(address[] memory strategies) internal {
    for(uint256 i = 0; i < strategies.length; i++) {
      _authorizedVotingPowerStrategies[strategies[i]] = false;
      emit VotingPowerStrategyUnauthorized(strategies[i]);
    }
  }

  function _safeUint224(uint256 value) internal pure returns (uint224) {
    require(value < 2**224 - 1, 'value is too big (uint224)');
    return uint224(value);
  }

  function _safeUint32(uint256 value) internal pure returns (uint32) {
    require(value < 2**32 - 1, 'value is too big (uint32)');
    return uint32(value);
  }
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

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;


abstract contract PermissionAdmin {
    address public admin;
    address public pendingAdmin;

    event AdminClaimed(address newAdmin, address previousAdmin);

    event TransferAdminPending(address pendingAdmin);

    constructor(address _admin) {
        require(_admin != address(0), "admin 0");
        admin = _admin;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    /**
     * @dev Allows the current admin to set the pendingAdmin address.
     * @param newAdmin The address to transfer ownership to.
     */
    function transferAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "new admin 0");
        emit TransferAdminPending(newAdmin);
        pendingAdmin = newAdmin;
    }

    /**
     * @dev Allows the current admin to set the admin in one tx. Useful initial deployment.
     * @param newAdmin The address to transfer ownership to.
     */
    function transferAdminQuickly(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "admin 0");
        emit TransferAdminPending(newAdmin);
        emit AdminClaimed(newAdmin, admin);
        admin = newAdmin;
    }

    /**
     * @dev Allows the pendingAdmin address to finalize the change admin process.
     */
    function claimAdmin() public {
        require(pendingAdmin == msg.sender, "not pending");
        emit AdminClaimed(pendingAdmin, admin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

function getChainId() pure returns (uint256) {
  uint256 chainId;
  assembly {
    chainId := chainid()
  }
  return chainId;
}

function isContract(address account) view returns (bool) {
  // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
  // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
  // for accounts without code, i.e. `keccak256('')`
  bytes32 codehash;
  bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
  // solhint-disable-next-line no-inline-assembly
  assembly {
    codehash := extcodehash(account)
  }
  return (codehash != accountHash && codehash != 0x0);
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

