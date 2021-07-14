// SPDX-License-Identifier: MIT
pragma solidity =0.8.3;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IVotingStrategy.sol";

contract Voting is Initializable, ReentrancyGuardUpgradeable {
  // Because we aren't using short time durations for milestones it's safe to compare with block.timestamp in our case
  // solhint-disable not-rely-on-time

  struct InitializationSettings {
    IVotingStrategy votingStrategy;
    bytes ipfsVotingDetails;
    uint256 votingDuration;
    uint256 minConsensusVotingPower;
  }

  struct Option {
    address callTarget;
    bytes callData;
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

  uint256 public constant EXECUTION_DURATION = 7 days;

  IVotingStrategy public votingStrategy;
  bytes public ipfsVotingDetails;
  address public roadmap;
  uint256 public timeLockBeforeVoting;
  uint256 public votingDuration;
  uint256 public timeLockBeforeExecution;
  uint256 public minConsensusVotersCount;
  uint256 public minConsensusVotingPower;
  mapping(uint256 => Proposal) public proposals;
  uint256 public proposalsCount;

  event ProposalAdded(uint256 indexed id);
  event ProposalVoted(
    uint256 indexed proposalId,
    uint256 indexed optionId,
    address indexed voter,
    uint256 votingPower,
    bytes ipfsHash
  );
  event ProposalVoteCancelled(
    uint256 indexed proposalId,
    uint256 indexed optionId,
    address indexed voter,
    uint256 votingPower
  );
  event ProposalExecuted(uint256 indexed proposalId, uint256 indexed optionId);
  event ProposalExecutionFailed(
    uint256 indexed proposalId,
    uint256 indexed optionId,
    string reason
  );

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

  function initialize(address _roadmap, InitializationSettings memory settings)
    external
    initializer
  {
    __ReentrancyGuard_init();
    
    roadmap = _roadmap;
    votingStrategy = settings.votingStrategy;
    ipfsVotingDetails = settings.ipfsVotingDetails;
    timeLockBeforeVoting = 0;
    votingDuration = settings.votingDuration;
    timeLockBeforeExecution = 0;
    minConsensusVotersCount = 0;
    minConsensusVotingPower = settings.minConsensusVotingPower;
  }

  function addProposal(
    uint256 id,
    address[] calldata callTargets,
    bytes[] calldata callDataList
  ) external {
    require(!proposalExists(id), "Proposal already exists");
    require(
      callTargets.length == callDataList.length,
      "Array length missmatch"
    );
    uint256 optionsCount = callTargets.length;
    require(optionsCount > 0, "Options are empty");

    Proposal storage proposal = proposals[id];
    proposal.createdAt = block.timestamp;
    proposal.options.push(); // empty option

    for (uint256 i = 0; i < optionsCount; i++) {
      Option storage option = proposal.options.push();
      option.callTarget = callTargets[i];
      option.callData = callDataList[i];
    }

    proposalsCount += 1;

    emit ProposalAdded(id);
  }

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
          voter: msg.sender,
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
      (bool previousVoteExists, uint256 previousOptionId) =
        getSelectedOption(proposal);
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

  function cancelVote(uint256 proposalId)
    external
    inProposalTimeInterval(proposalId, ProposalTimeInterval.Voting)
  {
    Proposal storage proposal = proposals[proposalId];
    (bool exists, uint256 previousOptionId) = getSelectedOption(proposal);
    require(exists, "No vote exists");

    cancelPreviousVote(proposal, proposalId, previousOptionId);
  }

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

    bool success = true;
    bytes memory data;

    if (!isOptionEmpty(option)) {
      (success, data) = option.callTarget.call(option.callData); // solhint-disable-line avoid-low-level-calls
    }

    if (success) {
      proposal.executed = true;
      emit ProposalExecuted(proposalId, optionId);
    } else {
      emit ProposalExecutionFailed(proposalId, optionId, getRevertMsg(data));
    }
  }

  function getOptionCount(uint256 proposalId) external view returns (uint256) {
    require(proposalExists(proposalId), "Proposal does not exists");
    return proposals[proposalId].options.length;
  }

  function getOptions(uint256 proposalId)
    external
    view
    returns (
      address[] memory callTargets,
      bytes[] memory callDataList,
      uint256[] memory votingPowers
    )
  {
    require(proposalExists(proposalId), "Proposal does not exists");
    Proposal storage proposal = proposals[proposalId];
    uint256 optionsCount = proposal.options.length;
    callTargets = new address[](optionsCount);
    callDataList = new bytes[](optionsCount);
    votingPowers = new uint256[](optionsCount);

    for (uint256 i = 0; i < optionsCount; i++) {
      Option storage option = proposal.options[i];
      callTargets[i] = option.callTarget;
      callDataList[i] = option.callData;
      votingPowers[i] = option.votingPower;
    }
  }

  function proposalExists(uint256 id) public view returns (bool) {
    return proposals[id].createdAt != 0;
  }

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
    uint256 previousVotingPower =
      previousOption.votingPowerByAddress[msg.sender];
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

  function isOptionEmpty(Option storage option) internal view returns (bool) {
    return option.callTarget == address(0) && option.callData.length == 0;
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
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.3;

interface IVotingStrategy {
  struct Vote {
    address voter;
    address roadmap;
    uint256 proposalId;
    uint256 optionId;
    uint256 votingPower;
    bytes ipfsHash;
  }

  function url() external returns (string memory);

  function isValid(
    Vote calldata vote,
    uint256[] calldata argumentsU256,
    bytes32[] calldata argumentsB32
  ) external returns (bool);
}

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