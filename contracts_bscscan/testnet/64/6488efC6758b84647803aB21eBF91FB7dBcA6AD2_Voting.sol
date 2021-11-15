// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.3;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IVotingStrategy.sol";

/// @title Contract for storing proposals, voting and executing them
contract Voting is Initializable, ReentrancyGuardUpgradeable {
  // Because we aren't using short time durations for milestones it's safe to compare with block.timestamp in our case
  // solhint-disable not-rely-on-time

  struct Option {
    address[] callTargets;
    bytes[] callDataList;
    uint256 votingPower;
    mapping(address => uint256) votingPowerByAddress;
  }

  struct Proposal {
    uint256 createdAt;
    uint256 overallVotingPower;
    uint256 overallVoters;
    Option[] options;
    mapping(address => uint256) selectedOptions;
    bool executed;
  }

  enum ProposalTimeInterval {
    LockBeforeVoting,
    Voting,
    LockBeforeExecution,
    Execution,
    AfterExecution
  }

  /// @notice Stores the duration of an execution stage
  /// @return Seconds that are the duration of an execution stage
  uint256 public constant EXECUTION_DURATION = 7 days;

  /// @notice Stores a voting strategy used to check vote validity
  /// @return Address of a voting strategy used to check vote validity
  IVotingStrategy public votingStrategy;
  /// @notice Stores a ipfs hash containing additional information about this voting
  /// @return Bytes representing the ipfs hash containing additional information about this voting
  bytes public ipfsVotingDetails;
  /// @notice Stores a roadmap this voting is related to
  /// @return Address of a roadmap this voting is related to
  address public roadmap;
  /// @notice Stores duration of a window after the proposal is created before the voting stage starts
  /// @return Seconds that are the duration of a window after the proposal is created before the voting stage starts
  uint64 public timeLockBeforeVoting;
  /// @notice Stores duration of a voting stage
  /// @return Seconds that are the duration of a voting stage
  uint64 public votingDuration;
  /// @notice Stores duration of a window after the voting stage before the execution stage starts
  /// @return Seconds that are the duration of a window after the voting stage before the execution stage starts
  uint64 public timeLockBeforeExecution;
  /// @notice Stores minimal amount of voters in a proposal for it to be executable
  /// @return Minimal amount of voters in a proposal for it to be executable
  uint64 public minConsensusVotersCount;
  /// @notice Stores minimal amount of voting power in a proposal for it to be executable
  /// @return Minimal voting power of voters in a proposal for it to be executable
  uint256 public minConsensusVotingPower;
  /// @notice Stores proposal information by a proposal id
  /// @return Proposal information:
  /// uint256 createdAt - timestamp of a proposal creation time
  /// uint256 overallVotingPower - total voting power in this proposal
  /// uint256 overallVoters - total voters in this proposal
  /// bool executed - if this proposal was already executed
  Proposal[] public proposals;

  /// @notice Emits on each proposal creation
  /// @param id Id of a created proposal
  event ProposalAdded(uint256 indexed id);
  /// @notice Emits on each vote
  /// @param proposalId Id of a voted proposal
  /// @param optionId Id of a voted option
  /// @param voter Address of a voter
  /// @param votingPower Voting power of a vote
  /// @param ipfsHash Ipfs hash with additional information about the vote
  event ProposalVoted(
    uint256 indexed proposalId,
    uint256 indexed optionId,
    address indexed voter,
    uint256 votingPower,
    bytes ipfsHash
  );
  /// @notice Emits on a cancel of the vote
  /// @param proposalId Id of a proposal for the cancelled vote
  /// @param optionId Id of an option for the cancelled vote
  /// @param voter Address of a voter for the cancelled vote
  /// @param votingPower Voting power of a cancelled vote
  event ProposalVoteCancelled(
    uint256 indexed proposalId,
    uint256 indexed optionId,
    address indexed voter,
    uint256 votingPower
  );
  /// @notice Emits on a successful execution of the proposal
  /// @param proposalId Id of an executed proposal
  /// @param optionId Id of an executed option
  event ProposalExecuted(uint256 indexed proposalId, uint256 indexed optionId);

  modifier inProposalTimeInterval(
    uint256 proposalId,
    ProposalTimeInterval timeInterval
  ) {
    require(proposalExists(proposalId), "Proposal does not exists");
    require(
      proposalTimeInterval(proposalId) == timeInterval,
      "Wrong time period"
    );
    _;
  }

  function initialize(
    address _roadmap,
    IVotingStrategy _votingStrategy,
    bytes calldata _ipfsVotingDetails,
    uint64 _timeLockBeforeVoting,
    uint64 _votingDuration,
    uint64 _timeLockBeforeExecution,
    uint64 _minConsensusVotersCount,
    uint256 _minConsensusVotingPower
  ) external initializer {
    __ReentrancyGuard_init();

    roadmap = _roadmap;
    votingStrategy = _votingStrategy;
    ipfsVotingDetails = _ipfsVotingDetails;
    timeLockBeforeVoting = _timeLockBeforeVoting;
    votingDuration = _votingDuration;
    timeLockBeforeExecution = _timeLockBeforeExecution;
    minConsensusVotersCount = _minConsensusVotersCount;
    minConsensusVotingPower = _minConsensusVotingPower;
  }

  /// @notice Creates a proposal
  /// @dev Creates an empty option with id 0, options passed in callTargets and callDataList get indecies equal
  /// to their index in corresponding arrays + 1
  /// @param callTargets List of options each containing addresses which would be used for a call on execution
  /// @param callDataList List of options each containing call data lists which would be used for a call on execution
  function addProposal(
    address[][] calldata callTargets,
    bytes[][] calldata callDataList
  ) external {
    require(
      callTargets.length == callDataList.length,
      "Options array length missmatch"
    );
    uint256 optionsCount = callTargets.length;
    require(optionsCount > 0, "Options are empty");

    Proposal storage proposal = proposals.push();
    proposal.createdAt = block.timestamp;
    proposal.options.push(); // empty option

    for (uint256 i = 0; i < optionsCount; i++) {
      Option storage option = proposal.options.push();
      require(
        callTargets[i].length == callDataList[i].length,
        "Concrete option array length missmatch"
      );
      option.callTargets = callTargets[i];
      for (uint256 j = 0; j < callDataList[i].length; j++) {
        option.callDataList.push(callDataList[i][j]);
      }
    }

    emit ProposalAdded(proposals.length - 1);
  }

  /// @notice Votes for an option in the proposal. Supports revoting if a vote already have been submitted by a caller address
  /// @param proposalId Id of a voted proposal
  /// @param optionId Id of a voted option
  /// @param votingPower Voting power of a vote
  /// @param ipfsHash Ipfs hash with additional information about the vote
  /// @param argumentsU256 Array of uint256 which should be used to pass signature information
  /// @param argumentsB32 Array of bytes32 which should be used to pass signature information
  function vote(
    uint256 proposalId,
    uint256 optionId,
    uint256 votingPower,
    bytes calldata ipfsHash,
    uint256[] calldata argumentsU256,
    bytes32[] calldata argumentsB32
  ) external inProposalTimeInterval(proposalId, ProposalTimeInterval.Voting) {
    require(
      votingStrategy.isValid(
        IVotingStrategy.Vote({
          voter: msg.sender, // shouldn't be removed as it prevents votes reusage by other actors
          roadmap: roadmap,
          proposalId: proposalId,
          optionId: optionId,
          votingPower: votingPower,
          ipfsHash: ipfsHash
        }),
        argumentsU256,
        argumentsB32
      ),
      "Signature is not valid"
    );

    Proposal storage proposal = proposals[proposalId];
    require(optionId < proposal.options.length, "Invalid option id");

    {
      (bool previousVoteExists, uint256 previousOptionId) = getSelectedOption(
        proposal
      );
      require(
        !previousVoteExists || previousOptionId != optionId,
        "Already voted for this option"
      );
      if (previousVoteExists) {
        cancelPreviousVote(proposal, proposalId, previousOptionId);
      }
    }

    setSelectedOption(proposal, optionId);
    proposal.overallVotingPower += votingPower;
    proposal.overallVoters += 1;

    {
      Option storage option = proposal.options[optionId];
      option.votingPower += votingPower;
      option.votingPowerByAddress[msg.sender] = votingPower;
    }

    emit ProposalVoted(proposalId, optionId, msg.sender, votingPower, ipfsHash);
  }

  /// @notice Cancels a vote previously submitted by a caller adress
  /// @param proposalId Id of a proposal to cancel vote for
  function cancelVote(uint256 proposalId)
    external
    inProposalTimeInterval(proposalId, ProposalTimeInterval.Voting)
  {
    Proposal storage proposal = proposals[proposalId];
    (bool exists, uint256 previousOptionId) = getSelectedOption(proposal);
    require(exists, "No vote exists");

    cancelPreviousVote(proposal, proposalId, previousOptionId);
  }

  /// @notice Execute an option in a proposal. Would fail if this option doesn't have a maximum voting power in this proposal
  /// @param proposalId Id of an executed proposal
  /// @param optionId Id of an executed option
  function execute(uint256 proposalId, uint256 optionId)
    external
    nonReentrant
    inProposalTimeInterval(proposalId, ProposalTimeInterval.Execution)
  {
    (bool haveMax, uint256 maxOptionId) = maxVotingPowerOption(proposalId);
    require(
      haveMax && optionId == maxOptionId,
      "Option does not have maximum voting power"
    );

    Proposal storage proposal = proposals[proposalId];
    require(!proposal.executed, "Already executed");
    require(
      proposal.overallVotingPower >= minConsensusVotingPower,
      "Not enough voting power for consensus"
    );
    require(
      proposal.overallVoters >= minConsensusVotersCount,
      "Not enough voters for consensus"
    );
    Option storage option = proposal.options[optionId];

    proposal.executed = true;

    uint256 calls = option.callTargets.length;
    for (uint256 i = 0; i < calls; i++) {
      address callTarget = option.callTargets[i];
      bytes storage callData = option.callDataList[i];
      (bool success, bytes memory data) = callTarget.call(callData); // solhint-disable-line avoid-low-level-calls
      require(success, concatenate("Error in a call: ", getRevertMsg(data)));
    }

    emit ProposalExecuted(proposalId, optionId);
  }

  /// @notice Returns options count for a particular proposal
  /// @param proposalId Id of a proposal
  /// @return Options count
  function getOptionCount(uint256 proposalId) external view returns (uint256) {
    require(proposalExists(proposalId), "Proposal does not exists");
    return proposals[proposalId].options.length;
  }

  /// @notice Returns information about options for a particular proposal
  /// @param proposalId Id of a proposal
  /// @return callTargets List of options addresses which would be used for a call on execution. Option id is index.
  /// @return callDataList List of options call data which would be used for a call on execution. Option id is index.
  /// @return votingPowers List of voting power for options. Option id is index.
  function getOptions(uint256 proposalId)
    external
    view
    returns (
      address[][] memory callTargets,
      bytes[][] memory callDataList,
      uint256[] memory votingPowers
    )
  {
    require(proposalExists(proposalId), "Proposal does not exists");
    Proposal storage proposal = proposals[proposalId];
    uint256 optionsCount = proposal.options.length;
    callTargets = new address[][](optionsCount);
    callDataList = new bytes[][](optionsCount);
    votingPowers = new uint256[](optionsCount);

    for (uint256 i = 0; i < optionsCount; i++) {
      Option storage option = proposal.options[i];
      callTargets[i] = option.callTargets;
      callDataList[i] = option.callDataList;
      votingPowers[i] = option.votingPower;
    }
  }

  /// @notice Returns total count of created proposals
  /// @return Total count of proposals
  function proposalsCount() external view returns (uint256) {
    return proposals.length;
  }

  /// @notice Returns if a particular proposal exists
  /// @param id Id of a proposal
  /// @return True if a proposal exists
  function proposalExists(uint256 id) public view returns (bool) {
    return id < proposals.length;
  }

  /// @notice Returns current time interval for a particular proposal
  /// @param id Id of a proposal
  /// @return Current time interval for a proposal
  function proposalTimeInterval(uint256 id)
    public
    view
    returns (ProposalTimeInterval)
  {
    uint256 timeElapsed = block.timestamp - proposals[id].createdAt;
    if (timeElapsed < timeLockBeforeVoting) {
      return ProposalTimeInterval.LockBeforeVoting;
    }

    timeElapsed -= timeLockBeforeVoting;
    if (timeElapsed < votingDuration) {
      return ProposalTimeInterval.Voting;
    }

    timeElapsed -= votingDuration;
    if (timeElapsed < timeLockBeforeExecution) {
      return ProposalTimeInterval.LockBeforeExecution;
    }

    timeElapsed -= timeLockBeforeExecution;
    if (timeElapsed < EXECUTION_DURATION) {
      return ProposalTimeInterval.Execution;
    } else {
      return ProposalTimeInterval.AfterExecution;
    }
  }

  /// @notice Returns information about option with a maximum voting power for a particular proposal
  /// @param proposalId Id of a proposal
  /// @return haveMax Does such option exists
  /// @return maxOptionId Id of a such option
  function maxVotingPowerOption(uint256 proposalId)
    public
    view
    returns (bool haveMax, uint256 maxOptionId)
  {
    Proposal storage proposal = proposals[proposalId];
    uint256 optionsCount = proposal.options.length;
    uint256 maxVotingPower = 0;
    for (uint256 i = 0; i < optionsCount; i++) {
      Option storage option = proposal.options[i];
      if (option.votingPower > maxVotingPower) {
        maxVotingPower = option.votingPower;
        maxOptionId = i;
        haveMax = true;
      } else if (option.votingPower == maxVotingPower) {
        haveMax = false;
      }
    }
  }

  function getSelectedOption(Proposal storage proposal)
    private
    view
    returns (bool exists, uint256 optionId)
  {
    uint256 stored = proposal.selectedOptions[msg.sender];
    if (stored > 0) {
      return (true, stored - 1);
    } else {
      return (false, 0);
    }
  }

  function setSelectedOption(Proposal storage proposal, uint256 optionId)
    private
  {
    proposal.selectedOptions[msg.sender] = optionId + 1;
  }

  function cancelPreviousVote(
    Proposal storage proposal,
    uint256 proposalId,
    uint256 previousOptionId
  ) private {
    Option storage previousOption = proposal.options[previousOptionId];
    uint256 previousVotingPower = previousOption.votingPowerByAddress[
      msg.sender
    ];
    previousOption.votingPower -= previousVotingPower;
    delete previousOption.votingPowerByAddress[msg.sender];
    delete proposal.selectedOptions[msg.sender];

    proposal.overallVotingPower -= previousVotingPower;
    proposal.overallVoters -= 1;

    emit ProposalVoteCancelled(
      proposalId,
      previousOptionId,
      msg.sender,
      previousVotingPower
    );
  }

  function getRevertMsg(bytes memory returnData)
    internal
    pure
    returns (string memory)
  {
    if (returnData.length < 68) return "Transaction reverted silently";

    // solhint-disable-next-line no-inline-assembly
    assembly {
      returnData := add(returnData, 0x04)
    }
    return abi.decode(returnData, (string));
  }

  function concatenate(string memory a, string memory b)
    internal
    pure
    returns (string memory)
  {
    return string(abi.encodePacked(a, b));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.3;

/// @title Interface for a generic voting strategy contract
interface IVotingStrategy {
  struct Vote {
    address voter;
    address roadmap;
    uint256 proposalId;
    uint256 optionId;
    uint256 votingPower;
    bytes ipfsHash;
  }

  /// @notice Used to get url of signature generation resource
  /// @return String representing signature generation resource url
  function url() external returns (string memory);

  /// @notice Checks validity of a vote signature
  /// @param vote Structure containing vote data which is being signed. Fields:
  /// address voter - address of a voter for this vote
  /// address roadmap - address of a roadmap voting is related to
  /// uint256 proposalId - id of a proposal for this vote
  /// uint256 optionId - id of a option being voted
  /// uint256 votingPower - voting power of this vote
  /// bytes ipfsHash - bytes representing ipfs hash which contains additional information about this vote
  /// @param argumentsU256 Array of uint256 which should be used to pass signature information
  /// @param argumentsB32 Array of bytes32 which should be used to pass signature information
  /// @return True if a signature is valid, false otherwise
  function isValid(
    Vote calldata vote,
    uint256[] calldata argumentsU256,
    bytes32[] calldata argumentsB32
  ) external returns (bool);
}

