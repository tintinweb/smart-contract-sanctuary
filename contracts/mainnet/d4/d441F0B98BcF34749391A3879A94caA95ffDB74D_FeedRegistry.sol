// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "../interfaces/AccessControlledInterface.sol";
import "../vendor/AccessControllerInterface.sol";
import "../vendor/ConfirmedOwner.sol";

contract AccessControlled is AccessControlledInterface, ConfirmedOwner(msg.sender) {
  AccessControllerInterface internal s_accessController;

  function setAccessController(
    AccessControllerInterface _accessController
  )
    public
    override
    onlyOwner()
  {
    require(address(_accessController) != address(s_accessController), "Access controller is already set");
    s_accessController = _accessController;
    emit AccessControllerSet(address(_accessController), msg.sender);
  }

  function getAccessController()
    public
    view
    override
    returns (
      AccessControllerInterface
    )
  {
    return s_accessController;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "../vendor/AccessControllerInterface.sol";

interface AccessControlledInterface {
  event AccessControllerSet(
    address indexed accessController,
    address indexed sender
  );

  function setAccessController(
    AccessControllerInterface _accessController
  )
    external;

  function getAccessController()
    external
    view
    returns (
      AccessControllerInterface
    );
}

// SPDX-License-Identifier: MIT
pragma solidity >0.6.0 <0.8.0;

interface AccessControllerInterface {
  function hasAccess(address user, bytes calldata data) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {

  constructor(
    address newOwner
  )
    ConfirmedOwnerWithProposal(
      newOwner,
      address(0)
    )
  {
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "../interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {

  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(
    address indexed from,
    address indexed to
  );
  event OwnershipTransferred(
    address indexed from,
    address indexed to
  );

  constructor(
    address owner,
    address pendingOwner
  ) {
    require(owner != address(0), "Cannot set owner to zero");

    s_owner = owner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(
    address to
  )
    public
    override
    onlyOwner()
  {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership()
    external
    override
  {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner()
    public
    view
    override
    returns (
      address
    )
  {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(
    address to
  )
    private
  {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership()
    internal
  {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface OwnableInterface {
  function owner()
    external
    returns (
      address
    );

  function transferOwnership(
    address recipient
  )
    external;

  function acceptOwnership()
    external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2; // solhint-disable compiler-version

import "@chainlink/contracts/src/v0.7/interfaces/AggregatorV2V3Interface.sol";
import "./access/AccessControlled.sol";
import "./interfaces/FeedRegistryInterface.sol";

/**
  * @notice An on-chain registry of assets to aggregators.
  * @notice This contract provides a consistent address for consumers but delegates where it reads from to the owner, who is
  * trusted to update it. This registry contract works for multiple feeds, not just a single aggregator.
  * @notice Only access enabled addresses are allowed to access getters for answers and round data
  */
contract FeedRegistry is FeedRegistryInterface, AccessControlled {
  uint256 constant private PHASE_OFFSET = 64;
  uint256 constant private PHASE_SIZE = 16;
  uint256 constant private MAX_ID = 2**(PHASE_OFFSET+PHASE_SIZE) - 1;

  mapping(address => bool) private s_isAggregatorEnabled;
  mapping(address => mapping(address => AggregatorV2V3Interface)) private s_proposedAggregators;
  mapping(address => mapping(address => uint16)) private s_currentPhaseId;
  mapping(address => mapping(address => mapping(uint16 => AggregatorV2V3Interface))) private s_phaseAggregators;
  mapping(address => mapping(address => mapping(uint16 => Phase))) private s_phases;

  /*
   * @notice Versioning
   */
  function typeAndVersion()
    external
    override
    pure
    virtual
    returns (
      string memory
    )
  {
    return "FeedRegistry 1.0.0-alpha";
  }

  /**
   * @notice represents the number of decimals the aggregator responses represent.
   */
  function decimals(
    address asset,
    address denomination
  )
    external
    view
    override
    returns (
      uint8
    )
  {
    AggregatorV2V3Interface aggregator = _getFeed(asset, denomination);
    return aggregator.decimals();
  }

  /**
   * @notice returns the description of the aggregator the proxy points to.
   */
  function description(
    address asset,
    address denomination
  )
    external
    view
    override
    returns (
      string memory
    )
  {
    AggregatorV2V3Interface aggregator = _getFeed(asset, denomination);
    return aggregator.description();
  }

  /**
   * @notice the version number representing the type of aggregator the proxy
   * points to.
   */
  function version(
    address asset,
    address denomination
  )
    external
    view
    override
    returns (
      uint256
    )
  {
    AggregatorV2V3Interface aggregator = _getFeed(asset, denomination);
    return aggregator.version();
  }

  /**
   * @notice get data about the latest round. Consumers are encouraged to check
   * that they're receiving fresh data by inspecting the updatedAt and
   * answeredInRound return values.
   * Note that different underlying implementations of AggregatorV3Interface
   * have slightly different semantics for some of the return values. Consumers
   * should determine what implementations they expect to receive
   * data from and validate that they can properly handle return data from all
   * of them.
   * @param asset asset address
   * @param denomination denomination address
   * @return roundId is the round ID from the aggregator for which the data was
   * retrieved combined with a phase to ensure that round IDs get larger as
   * time moves forward.
   * @return answer is the answer for the given round
   * @return startedAt is the timestamp when the round was started.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @return updatedAt is the timestamp when the round last was updated (i.e.
   * answer was last computed)
   * @return answeredInRound is the round ID of the round in which the answer
   * was computed.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @dev Note that answer and updatedAt may change between queries.
   */
  function latestRoundData(
    address asset,
    address denomination
  )
    external
    view
    override
    checkPairAccess()
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    uint16 currentPhaseId = s_currentPhaseId[asset][denomination];
    AggregatorV2V3Interface currentPhaseAggregator = _getFeed(asset, denomination);
    (
      roundId,
      answer,
      startedAt,
      updatedAt,
      answeredInRound
    ) = currentPhaseAggregator.latestRoundData();
    return _addPhaseIds(roundId, answer, startedAt, updatedAt, answeredInRound, currentPhaseId);
  }

  /**
   * @notice get data about a round. Consumers are encouraged to check
   * that they're receiving fresh data by inspecting the updatedAt and
   * answeredInRound return values.
   * Note that different underlying implementations of AggregatorV3Interface
   * have slightly different semantics for some of the return values. Consumers
   * should determine what implementations they expect to receive
   * data from and validate that they can properly handle return data from all
   * of them.
   * @param asset asset address
   * @param denomination denomination address
   * @param _roundId the proxy round id number to retrieve the round data for
   * @return roundId is the round ID from the aggregator for which the data was
   * retrieved combined with a phase to ensure that round IDs get larger as
   * time moves forward.
   * @return answer is the answer for the given round
   * @return startedAt is the timestamp when the round was started.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @return updatedAt is the timestamp when the round last was updated (i.e.
   * answer was last computed)
   * @return answeredInRound is the round ID of the round in which the answer
   * was computed.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @dev Note that answer and updatedAt may change between queries.
   */
  function getRoundData(
    address asset,
    address denomination,
    uint80 _roundId
  )
    external
    view
    override
    checkPairAccess()
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    (uint16 phaseId, uint64 aggregatorRoundId) = _parseIds(_roundId);
    AggregatorV2V3Interface aggregator = _getPhaseFeed(asset, denomination, phaseId);
    (
      roundId,
      answer,
      startedAt,
      updatedAt,
      answeredInRound
    ) = aggregator.getRoundData(aggregatorRoundId);
    return _addPhaseIds(roundId, answer, startedAt, updatedAt, answeredInRound, phaseId);
  }


  /**
   * @notice Reads the current answer for an asset / denomination pair's aggregator.
   * @param asset asset address
   * @param denomination denomination address
   * @notice We advise to use latestRoundData() instead because it returns more in-depth information.
   * @dev This does not error if no answer has been reached, it will simply return 0. Either wait to point to
   * an already answered Aggregator or use the recommended latestRoundData
   * instead which includes better verification information.
   */
  function latestAnswer(
    address asset,
    address denomination
  )
    external
    view
    override
    checkPairAccess()
    returns (
      int256 answer
    )
  {
    AggregatorV2V3Interface aggregator = _getFeed(asset, denomination);
    return aggregator.latestAnswer();
  }

  /**
   * @notice get the latest completed timestamp where the answer was updated.
   * @param asset asset address
   * @param denomination denomination address
   *
   * @notice We advise to use latestRoundData() instead because it returns more in-depth information.
   * @dev This does not error if no answer has been reached, it will simply return 0. Either wait to point to
   * an already answered Aggregator or use the recommended latestRoundData
   * instead which includes better verification information.
   */
  function latestTimestamp(
    address asset,
    address denomination
  )
    external
    view
    override
    checkPairAccess()
    returns (
      uint256 timestamp
    )
  {
    AggregatorV2V3Interface aggregator = _getFeed(asset, denomination);
    return aggregator.latestTimestamp();
  }

  /**
   * @notice get the latest completed round where the answer was updated
   * @param asset asset address
   * @param denomination denomination address
   * @dev overridden function to add the checkAccess() modifier
   *
   * @notice We advise to use latestRoundData() instead because it returns more in-depth information.
   * @dev Use latestRoundData instead. This does not error if no
   * answer has been reached, it will simply return 0. Either wait to point to
   * an already answered Aggregator or use the recommended latestRoundData
   * instead which includes better verification information.
   */
  function latestRound(
    address asset,
    address denomination
  )
    external
    view
    override
    checkPairAccess()
    returns (
      uint256 roundId
    )
  {
    uint16 currentPhaseId = s_currentPhaseId[asset][denomination];
    AggregatorV2V3Interface currentPhaseAggregator = _getFeed(asset, denomination);
    return _addPhase(currentPhaseId, uint64(currentPhaseAggregator.latestRound()));
  }

  /**
   * @notice get past rounds answers
   * @param asset asset address
   * @param denomination denomination address
   * @param roundId the proxy round id number to retrieve the answer for
   * @dev overridden function to add the checkAccess() modifier
   *
   * @notice We advise to use getRoundData() instead because it returns more in-depth information.
   * @dev This does not error if no answer has been reached, it will simply return 0. Either wait to point to
   * an already answered Aggregator or use the recommended getRoundData
   * instead which includes better verification information.
   */
  function getAnswer(
    address asset,
    address denomination,
    uint256 roundId
  )
    external
    view
    override
    checkPairAccess()
    returns (
      int256 answer
    )
  {
    if (roundId > MAX_ID) return 0;
    (uint16 phaseId, uint64 aggregatorRoundId) = _parseIds(roundId);
    AggregatorV2V3Interface aggregator = _getPhaseFeed(asset, denomination, phaseId);
    if (address(aggregator) == address(0)) return 0;
    return aggregator.getAnswer(aggregatorRoundId);
  }

  /**
   * @notice get block timestamp when an answer was last updated
   * @param asset asset address
   * @param denomination denomination address
   * @param roundId the proxy round id number to retrieve the updated timestamp for
   * @dev overridden function to add the checkAccess() modifier
   *
   * @notice We advise to use getRoundData() instead because it returns more in-depth information.
   * @dev This does not error if no answer has been reached, it will simply return 0. Either wait to point to
   * an already answered Aggregator or use the recommended getRoundData
   * instead which includes better verification information.
   */
  function getTimestamp(
    address asset,
    address denomination,
    uint256 roundId
  )
    external
    view
    override
    checkPairAccess()
    returns (
      uint256 timestamp
    )
  {
    if (roundId > MAX_ID) return 0;
    (uint16 phaseId, uint64 aggregatorRoundId) = _parseIds(roundId);
    AggregatorV2V3Interface aggregator = _getPhaseFeed(asset, denomination, phaseId);
    if (address(aggregator) == address(0)) return 0;
    return aggregator.getTimestamp(aggregatorRoundId);
  }


  /**
   * @notice Retrieve the aggregator of an asset / denomination pair in the current phase
   * @param asset asset address
   * @param denomination denomination address
   * @return aggregator
   */
  function getFeed(
    address asset,
    address denomination
  )
    public
    view
    override
    returns (
      AggregatorV2V3Interface aggregator
    )
  {
    aggregator = _getFeed(asset, denomination);
    require(address(aggregator) != address(0), "Feed not found");
  }

  /**
   * @notice retrieve the aggregator of an asset / denomination pair at a specific phase
   * @param asset asset address
   * @param denomination denomination address
   * @param phaseId phase ID
   * @return aggregator
   */
  function getPhaseFeed(
    address asset,
    address denomination,
    uint16 phaseId
  )
    public
    view
    override
    returns (
      AggregatorV2V3Interface aggregator
    )
  {
    aggregator = _getPhaseFeed(asset, denomination, phaseId);
    require(address(aggregator) != address(0), "Feed not found for phase");
  }

  /**
   * @notice returns true if a aggregator is enabled for any pair
   * @param aggregator aggregator address
   */
  function isFeedEnabled(
    address aggregator
  )
    public
    view
    override
    returns (
      bool
    )
  {
    return s_isAggregatorEnabled[aggregator];
  }

  /**
   * @notice returns a phase by id. A Phase contains the starting and ending aggregator round ids.
   * endingAggregatorRoundId will be 0 if the phase is the current phase
   * @dev reverts if the phase does not exist
   * @param asset asset address
   * @param denomination denomination address
   * @param phaseId phase id
   * @return phase
   */
  function getPhase(
    address asset,
    address denomination,
    uint16 phaseId
  )
    public
    view
    override
    returns (
      Phase memory phase
    )
  {
    phase = _getPhase(asset, denomination, phaseId);
    require(_phaseExists(phase), "Phase does not exist");
  }

  /**
   * @notice retrieve the aggregator of an asset / denomination pair at a specific round id
   * @param asset asset address
   * @param denomination denomination address
   * @param roundId the proxy round id
   */
  function getRoundFeed(
    address asset,
    address denomination,
    uint80 roundId
  )
    public
    view
    override
    returns (
      AggregatorV2V3Interface aggregator
    )
  {
    uint16 phaseId = _getPhaseIdByRoundId(asset, denomination, roundId);
    aggregator = _getPhaseFeed(asset, denomination, phaseId);
    require(address(aggregator) != address(0), "Feed not found for round");
  }

  /**
   * @notice returns the range of proxy round ids of a phase
   * @param asset asset address
   * @param denomination denomination address
   * @param phaseId phase id
   * @return startingRoundId
   * @return endingRoundId
   */
  function getPhaseRange(
    address asset,
    address denomination,
    uint16 phaseId
  )
    public
    view
    override
    returns (
      uint80 startingRoundId,
      uint80 endingRoundId
    )
  {
    Phase memory phase = _getPhase(asset, denomination, phaseId);
    require(_phaseExists(phase), "Phase does not exist");

    uint16 currentPhaseId = s_currentPhaseId[asset][denomination];
    if (phaseId == currentPhaseId) return _getLatestRoundRange(asset, denomination, currentPhaseId);
    return _getPhaseRange(asset, denomination, phaseId);
  }

  /**
   * @notice return the previous round id of a given round
   * @param asset asset address
   * @param denomination denomination address
   * @param roundId the round id number to retrieve the updated timestamp for
   * @dev Note that this is not the aggregator round id, but the proxy round id
   * To get full ranges of round ids of different phases, use getPhaseRange()
   * @return previousRoundId
   */
  function getPreviousRoundId(
    address asset,
    address denomination,
    uint80 roundId
  ) external
    view
    override
    returns (
      uint80 previousRoundId
    )
  {
    uint16 phaseId = _getPhaseIdByRoundId(asset, denomination, roundId);
    return _getPreviousRoundId(asset, denomination, phaseId, roundId);
  }

  /**
   * @notice return the next round id of a given round
   * @param asset asset address
   * @param denomination denomination address
   * @param roundId the round id number to retrieve the updated timestamp for
   * @dev Note that this is not the aggregator round id, but the proxy round id
   * To get full ranges of round ids of different phases, use getPhaseRange()
   * @return nextRoundId
   */
  function getNextRoundId(
    address asset,
    address denomination,
    uint80 roundId
  ) external
    view
    override
    returns (
      uint80 nextRoundId
    )
  {
    uint16 phaseId = _getPhaseIdByRoundId(asset, denomination, roundId);
    return _getNextRoundId(asset, denomination, phaseId, roundId);
  }

  /**
   * @notice Allows the owner to propose a new address for the aggregator
   * @param asset asset address
   * @param denomination denomination address
   * @param aggregator The new aggregator contract address
   */
  function proposeFeed(
    address asset,
    address denomination,
    address aggregator
  )
    external
    override
    onlyOwner()
  {
    AggregatorV2V3Interface currentPhaseAggregator = _getFeed(asset, denomination);
    require(aggregator != address(currentPhaseAggregator), "Cannot propose current aggregator");
    address proposedAggregator = address(_getProposedFeed(asset, denomination));
    if (proposedAggregator != aggregator) {
      s_proposedAggregators[asset][denomination] = AggregatorV2V3Interface(aggregator);
      emit FeedProposed(asset, denomination, aggregator, address(currentPhaseAggregator), msg.sender);
    }
  }

  /**
   * @notice Allows the owner to confirm and change the address
   * to the proposed aggregator
   * @dev Reverts if the given address doesn't match what was previously
   * proposed
   * @param asset asset address
   * @param denomination denomination address
   * @param aggregator The new aggregator contract address
   */
  function confirmFeed(
    address asset,
    address denomination,
    address aggregator
  )
    external
    override
    onlyOwner()
  {
    (uint16 nextPhaseId, address previousAggregator) = _setFeed(asset, denomination, aggregator);
    s_isAggregatorEnabled[aggregator] = true;
    s_isAggregatorEnabled[previousAggregator] = false;
    emit FeedConfirmed(asset, denomination, aggregator, previousAggregator, nextPhaseId, msg.sender);
  }

  /**
   * @notice Returns the proposed aggregator for an asset / denomination pair
   * returns a zero address if there is no proposed aggregator for the pair
   * @param asset asset address
   * @param denomination denomination address
   * @return proposedAggregator
  */
  function getProposedFeed(
    address asset,
    address denomination
  )
    public
    view
    override
    returns (
      AggregatorV2V3Interface proposedAggregator
    )
  {
    return _getProposedFeed(asset, denomination);
  }

  /**
   * @notice Used if an aggregator contract has been proposed.
   * @param asset asset address
   * @param denomination denomination address
   * @param roundId the round ID to retrieve the round data for
   * @return id is the round ID for which data was retrieved
   * @return answer is the answer for the given round
   * @return startedAt is the timestamp when the round was started.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @return updatedAt is the timestamp when the round last was updated (i.e.
   * answer was last computed)
   * @return answeredInRound is the round ID of the round in which the answer
   * was computed.
  */
  function proposedGetRoundData(
    address asset,
    address denomination,
    uint80 roundId
  )
    external
    view
    virtual
    override
    hasProposal(asset, denomination)
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return s_proposedAggregators[asset][denomination].getRoundData(roundId);
  }

  /**
   * @notice Used if an aggregator contract has been proposed.
   * @param asset asset address
   * @param denomination denomination address
   * @return id is the round ID for which data was retrieved
   * @return answer is the answer for the given round
   * @return startedAt is the timestamp when the round was started.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @return updatedAt is the timestamp when the round last was updated (i.e.
   * answer was last computed)
   * @return answeredInRound is the round ID of the round in which the answer
   * was computed.
  */
  function proposedLatestRoundData(
    address asset,
    address denomination
  )
    external
    view
    virtual
    override
    hasProposal(asset, denomination)
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return s_proposedAggregators[asset][denomination].latestRoundData();
  }

  function getCurrentPhaseId(
    address asset,
    address denomination
  )
    public
    view
    override
    returns (
      uint16 currentPhaseId
    )
  {
    return s_currentPhaseId[asset][denomination];
  }

  function _addPhase(
    uint16 phase,
    uint64 originalId
  )
    internal
    pure
    returns (
      uint80
    )
  {
    return uint80(uint256(phase) << PHASE_OFFSET | originalId);
  }

  function _parseIds(
    uint256 roundId
  )
    internal
    pure
    returns (
      uint16,
      uint64
    )
  {
    uint16 phaseId = uint16(roundId >> PHASE_OFFSET);
    uint64 aggregatorRoundId = uint64(roundId);

    return (phaseId, aggregatorRoundId);
  }

  function _addPhaseIds(
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound,
      uint16 phaseId
  )
    internal
    pure
    returns (
      uint80,
      int256,
      uint256,
      uint256,
      uint80
    )
  {
    return (
      _addPhase(phaseId, uint64(roundId)),
      answer,
      startedAt,
      updatedAt,
      _addPhase(phaseId, uint64(answeredInRound))
    );
  }

  function _getPhase(
    address asset,
    address denomination,
    uint16 phaseId
  )
    internal
    view
    returns (
      Phase memory phase
    )
  {
    return s_phases[asset][denomination][phaseId];
  }

  function _phaseExists(
    Phase memory phase
  )
    internal
    pure
    returns (
      bool
    )
  {
    return phase.phaseId > 0;
  }

  function _getProposedFeed(
    address asset,
    address denomination
  )
    internal
    view
    returns (
      AggregatorV2V3Interface proposedAggregator
    )
  {
    return s_proposedAggregators[asset][denomination];
  }

  function _getPhaseFeed(
    address asset,
    address denomination,
    uint16 phaseId
  )
    internal
    view
    returns (
      AggregatorV2V3Interface aggregator
    )
  {
    return s_phaseAggregators[asset][denomination][phaseId];
  }

  function _getFeed(
    address asset,
    address denomination
  )
    internal
    view
    returns (
      AggregatorV2V3Interface aggregator
    )
  {
    uint16 currentPhaseId = s_currentPhaseId[asset][denomination];
    return _getPhaseFeed(asset, denomination, currentPhaseId);
  }

  function _setFeed(
    address asset,
    address denomination,
    address newAggregator
  )
    internal
    returns (
      uint16 nextPhaseId,
      address previousAggregator
    )
  {
    require(newAggregator == address(s_proposedAggregators[asset][denomination]), "Invalid proposed aggregator");
    delete s_proposedAggregators[asset][denomination];

    AggregatorV2V3Interface currentAggregator = _getFeed(asset, denomination);
    uint80 previousAggregatorEndingRoundId = _getLatestAggregatorRoundId(currentAggregator);
    uint16 currentPhaseId = s_currentPhaseId[asset][denomination];
    s_phases[asset][denomination][currentPhaseId].endingAggregatorRoundId = previousAggregatorEndingRoundId;

    nextPhaseId = currentPhaseId + 1;
    s_currentPhaseId[asset][denomination] = nextPhaseId;
    s_phaseAggregators[asset][denomination][nextPhaseId] = AggregatorV2V3Interface(newAggregator);
    uint80 startingRoundId = _getLatestAggregatorRoundId(AggregatorV2V3Interface(newAggregator));
    s_phases[asset][denomination][nextPhaseId] = Phase(nextPhaseId, startingRoundId, 0);

    return (nextPhaseId, address(currentAggregator));
  }

  function _getPreviousRoundId(
    address asset,
    address denomination,
    uint16 phaseId,
    uint80 roundId
  )
    internal
    view
    returns (
      uint80
    )
  {
    for (uint16 pid = phaseId; pid > 0; pid--) {
      AggregatorV2V3Interface phaseAggregator = _getPhaseFeed(asset, denomination, pid);
      (uint80 startingRoundId, uint80 endingRoundId) = _getPhaseRange(asset, denomination, pid);
      if (address(phaseAggregator) == address(0)) continue;
      if (roundId <= startingRoundId) continue;
      if (roundId > startingRoundId && roundId <= endingRoundId) return roundId - 1;
      if (roundId > endingRoundId) return endingRoundId;
    }
    return 0; // Round not found
  }

  function _getNextRoundId(
    address asset,
    address denomination,
    uint16 phaseId,
    uint80 roundId
  )
    internal
    view
    returns (
      uint80
    )
  {
    uint16 currentPhaseId = s_currentPhaseId[asset][denomination];
    for (uint16 pid = phaseId; pid <= currentPhaseId; pid++) {
      AggregatorV2V3Interface phaseAggregator = _getPhaseFeed(asset, denomination, pid);
      (uint80 startingRoundId, uint80 endingRoundId) =
        (pid == currentPhaseId) ? _getLatestRoundRange(asset, denomination, pid) : _getPhaseRange(asset, denomination, pid);
      if (address(phaseAggregator) == address(0)) continue;
      if (roundId >= endingRoundId) continue;
      if (roundId >= startingRoundId && roundId < endingRoundId) return roundId + 1;
      if (roundId < startingRoundId) return startingRoundId;
    }
    return 0; // Round not found
  }

  function _getPhaseRange(
    address asset,
    address denomination,
    uint16 phaseId
  )
    internal
    view
    returns (
      uint80 startingRoundId,
      uint80 endingRoundId
    )
  {
    Phase memory phase = _getPhase(asset, denomination, phaseId);
    return (
      _getStartingRoundId(phaseId, phase),
      _getEndingRoundId(phaseId, phase)
    );
  }

  function _getLatestRoundRange(
    address asset,
    address denomination,
    uint16 currentPhaseId
  )
    internal
    view
    returns (
      uint80 startingRoundId,
      uint80 endingRoundId
    )
  {
    Phase memory phase = s_phases[asset][denomination][currentPhaseId];
    return (
      _getStartingRoundId(currentPhaseId, phase),
      _getLatestRoundId(asset, denomination, currentPhaseId)
    );
  }

  function _getStartingRoundId(
    uint16 phaseId,
    Phase memory phase
  )
    internal
    pure
    returns (
      uint80 startingRoundId
    )
  {
    return _addPhase(phaseId, uint64(phase.startingAggregatorRoundId));
  }

  function _getEndingRoundId(
    uint16 phaseId,
    Phase memory phase
  )
    internal
    pure
    returns (
      uint80 startingRoundId
    )
  {
    return _addPhase(phaseId, uint64(phase.endingAggregatorRoundId));
  }

  function _getLatestRoundId(
    address asset,
    address denomination,
    uint16 currentPhaseId
  )
    internal
    view
    returns (
      uint80 startingRoundId
    )
  {
    AggregatorV2V3Interface currentPhaseAggregator = _getFeed(asset, denomination);
    uint80 latestAggregatorRoundId = _getLatestAggregatorRoundId(currentPhaseAggregator);
    return _addPhase(currentPhaseId, uint64(latestAggregatorRoundId));
  }

  function _getLatestAggregatorRoundId(
    AggregatorV2V3Interface aggregator
  )
    internal
    view
    returns (
      uint80 roundId
    )
  {
    if (address(aggregator) == address(0)) return uint80(0);
    return uint80(aggregator.latestRound());
  }

  function _getPhaseIdByRoundId(
    address asset,
    address denomination,
    uint80 roundId
  )
    internal
    view
    returns (
      uint16 phaseId
    )
  {
    // Handle case where the round is in current phase
    uint16 currentPhaseId = s_currentPhaseId[asset][denomination];
    (uint80 startingCurrentRoundId, uint80 endingCurrentRoundId) = _getLatestRoundRange(asset, denomination, currentPhaseId);
    if (roundId >= startingCurrentRoundId && roundId <= endingCurrentRoundId) return currentPhaseId;

    // Handle case where the round is in past phases
    for (uint16 pid = currentPhaseId - 1; pid > 0; pid--) {
      AggregatorV2V3Interface phaseAggregator = s_phaseAggregators[asset][denomination][pid];
      if (address(phaseAggregator) == address(0)) continue;
      (uint80 startingRoundId, uint80 endingRoundId) = _getPhaseRange(asset, denomination, pid);
      if (roundId >= startingRoundId && roundId <= endingRoundId) return pid;
      if (roundId > endingRoundId) break;
    }
    return 0;
  }

  /**
   * @dev reverts if the caller does not have access granted by the accessController contract
   * to the asset / denomination pair or is the contract itself.
   */
  modifier checkPairAccess() {
    require(address(s_accessController) == address(0) || s_accessController.hasAccess(msg.sender, msg.data), "No access");
    _;
  }

  /**
   * @dev reverts if no proposed aggregator was set
   */
  modifier hasProposal(
    address asset,
    address denomination
  ) {
    require(address(s_proposedAggregators[asset][denomination]) != address(0), "No proposed aggregator present");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface
{
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2; // solhint-disable compiler-version

import "@chainlink/contracts/src/v0.7/interfaces/AggregatorV2V3Interface.sol";
import "./AccessControlledInterface.sol";
import "./TypeAndVersionInterface.sol";

interface FeedRegistryInterface is AccessControlledInterface, TypeAndVersionInterface {
  struct Phase {
    uint16 phaseId;
    uint80 startingAggregatorRoundId; // The latest round id of `aggregator` at phase start
    uint80 endingAggregatorRoundId; // The latest round of the at phase end
  }

  event FeedProposed(
    address indexed asset,
    address indexed denomination,
    address indexed proposedAggregator,
    address currentAggregator,
    address sender
  );
  event FeedConfirmed(
    address indexed asset,
    address indexed denomination,
    address indexed latestAggregator,
    address previousAggregator,
    uint16 nextPhaseId,
    address sender
  );

  // V3 AggregatorV3Interface

  function decimals(
    address asset,
    address denomination
  )
    external
    view
    returns (
      uint8
    );

  function description(
    address asset,
    address denomination
  )
    external
    view
    returns (
      string memory
    );

  function version(
    address asset,
    address denomination
  )
    external
    view
    returns (
      uint256
    );

  function latestRoundData(
    address asset,
    address denomination
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function getRoundData(
    address asset,
    address denomination,
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  // V2 AggregatorInterface

  function latestAnswer(
    address asset,
    address denomination
  )
    external
    view
    returns (
      int256 answer
    );

  function latestTimestamp(
    address asset,
    address denomination
  )
    external
    view
    returns (
      uint256 timestamp
    );

  function latestRound(
    address asset,
    address denomination
  )
    external
    view
    returns (
      uint256 roundId
    );

  function getAnswer(
    address asset,
    address denomination,
    uint256 roundId
  )
    external
    view
    returns (
      int256 answer
    );

  function getTimestamp(
    address asset,
    address denomination,
    uint256 roundId
  )
    external
    view
    returns (
      uint256 timestamp
    );

  // Registry getters

  function getFeed(
    address asset,
    address denomination
  )
    external
    view
    returns (
      AggregatorV2V3Interface aggregator
    );

  function getPhaseFeed(
    address asset,
    address denomination,
    uint16 phaseId
  )
    external
    view
    returns (
      AggregatorV2V3Interface aggregator
    );

  function isFeedEnabled(
    address aggregator
  )
    external
    view
    returns (
      bool
    );

  function getPhase(
    address asset,
    address denomination,
    uint16 phaseId
  )
    external
    view
    returns (
      Phase memory phase
    );

  // Round helpers

  function getRoundFeed(
    address asset,
    address denomination,
    uint80 roundId
  )
    external
    view
    returns (
      AggregatorV2V3Interface aggregator
    );

  function getPhaseRange(
    address asset,
    address denomination,
    uint16 phaseId
  )
    external
    view
    returns (
      uint80 startingRoundId,
      uint80 endingRoundId
    );

  function getPreviousRoundId(
    address asset,
    address denomination,
    uint80 roundId
  ) external
    view
    returns (
      uint80 previousRoundId
    );

  function getNextRoundId(
    address asset,
    address denomination,
    uint80 roundId
  ) external
    view
    returns (
      uint80 nextRoundId
    );

  // Feed management

  function proposeFeed(
    address asset,
    address denomination,
    address aggregator
  ) external;

  function confirmFeed(
    address asset,
    address denomination,
    address aggregator
  ) external;

  // Proposed aggregator

  function getProposedFeed(
    address asset,
    address denomination
  )
    external
    view
    returns (
      AggregatorV2V3Interface proposedAggregator
    );

  function proposedGetRoundData(
    address asset,
    address denomination,
    uint80 roundId
  )
    external
    view
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function proposedLatestRoundData(
    address asset,
    address denomination
  )
    external
    view
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  // Phases
  function getCurrentPhaseId(
    address asset,
    address denomination
  )
    external
    view
    returns (
      uint16 currentPhaseId
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface AggregatorInterface {
  function latestAnswer()
    external
    view
    returns (
      int256
    );
  
  function latestTimestamp()
    external
    view
    returns (
      uint256
    );

  function latestRound()
    external
    view
    returns (
      uint256
    );

  function getAnswer(
    uint256 roundId
  )
    external
    view
    returns (
      int256
    );

  function getTimestamp(
    uint256 roundId
  )
    external
    view
    returns (
      uint256
    );

  event AnswerUpdated(
    int256 indexed current,
    uint256 indexed roundId,
    uint256 updatedAt
  );

  event NewRound(
    uint256 indexed roundId,
    address indexed startedBy,
    uint256 startedAt
  );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface TypeAndVersionInterface{
  function typeAndVersion()
    external
    pure
    returns (
      string memory
    );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "../interfaces/FeedRegistryInterface.sol";

contract MockConsumer {
  FeedRegistryInterface private s_FeedRegistry;

  constructor(
    FeedRegistryInterface FeedRegistry
  ) {
    s_FeedRegistry = FeedRegistry;
  }

  function getFeedRegistry()
    public
    view
    returns (
      FeedRegistryInterface
    )
  {
    return s_FeedRegistry;
  }

  function read(
    address asset,
    address denomination
  )
    public
    view
    returns (
      int256
    )
  {
    return s_FeedRegistry.latestAnswer(asset, denomination);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "../vendor/AccessControllerInterface.sol";
import "../vendor/ConfirmedOwner.sol";

/**
 * @title WriteAccessController
 * @notice Has two access lists: a global list and a data-specific list.
 * @dev does not make any special permissions for EOAs, see
 * ReadAccessController for that.
 */
contract WriteAccessController is AccessControllerInterface, ConfirmedOwner(msg.sender) {
  bool private s_checkEnabled = true;
  mapping(address => bool) internal s_globalAccessList;
  mapping(address => mapping(bytes => bool)) internal s_localAccessList;

  event AccessAdded(address user, bytes data, address sender);
  event AccessRemoved(address user, bytes data, address sender);
  event CheckAccessEnabled();
  event CheckAccessDisabled();

  function checkEnabled()
    public
    view
    returns (
      bool
    )
  {
    return s_checkEnabled;
  }

  /**
   * @notice Returns the access of an address
   * @param user The address to query
   * @param data The calldata to query
   */
  function hasAccess(
    address user,
    bytes memory data
  )
    public
    view
    virtual
    override
    returns (bool)
  {
    return !s_checkEnabled || s_globalAccessList[user] || s_localAccessList[user][data];
  }

/**
   * @notice Adds an address to the global access list
   * @param user The address to add
   */
  function addGlobalAccess(
    address user
  )
    external
    onlyOwner()
  {
    _addGlobalAccess(user);
  }

  /**
   * @notice Adds an address+data to the local access list
   * @param user The address to add
   * @param data The calldata to add
   */
  function addLocalAccess(
    address user,
    bytes memory data
  )
    external
    onlyOwner()
  {
    _addLocalAccess(user, data);
  }

  /**
   * @notice Removes an address from the global access list
   * @param user The address to remove
   */
  function removeGlobalAccess(
    address user
  )
    external
    onlyOwner()
  {
    _removeGlobalAccess(user);
  }

  /**
   * @notice Removes an address+data from the local access list
   * @param user The address to remove
   * @param data The calldata to remove
   */
  function removeLocalAccess(
    address user,
    bytes memory data
  )
    external
    onlyOwner()
  {
    _removeLocalAccess(user, data);
  }

  /**
   * @notice makes the access check enforced
   */
  function enableAccessCheck()
    external
    onlyOwner()
  {
    _enableAccessCheck();
  }

  /**
   * @notice makes the access check unenforced
   */
  function disableAccessCheck()
    external
    onlyOwner()
  {
    _disableAccessCheck();
  }

  /**
   * @dev reverts if the caller does not have access
   */
  modifier checkAccess() {
    if (s_checkEnabled) {
      require(hasAccess(msg.sender, msg.data), "No access");
    }
    _;
  }

  function _enableAccessCheck() internal {
    if (!s_checkEnabled) {
      s_checkEnabled = true;
      emit CheckAccessEnabled();
    }
  }

  function _disableAccessCheck() internal {
    if (s_checkEnabled) {
      s_checkEnabled = false;
      emit CheckAccessDisabled();
    }
  }

  function _addGlobalAccess(address user) internal {
    if (!s_globalAccessList[user]) {
      s_globalAccessList[user] = true;
      emit AccessAdded(user, "", msg.sender);
    }
  }

  function _removeGlobalAccess(address user) internal {
    if (s_globalAccessList[user]) {
      s_globalAccessList[user] = false;
      emit AccessRemoved(user, "", msg.sender);
    }
  }

  function _addLocalAccess(address user, bytes memory data) internal {
    if (!s_localAccessList[user][data]) {
      s_localAccessList[user][data] = true;
      emit AccessAdded(user, data, msg.sender);
    }
  }

  function _removeLocalAccess(address user, bytes memory data) internal {
    if (s_localAccessList[user][data]) {
      s_localAccessList[user][data] = false;
      emit AccessRemoved(user, data, msg.sender);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./WriteAccessController.sol";
import "../utils/EOAContext.sol";

/**
 * @title ReadAccessController
 * @notice Gives access to:
 * - any externally owned account (note that offchain actors can always read
 * any contract storage regardless of onchain access control measures, so this
 * does not weaken the access control while improving usability)
 * - accounts explicitly added to an access list
 * @dev ReadAccessController is not suitable for access controlling writes
 * since it grants any externally owned account access! See
 * WriteAccessController for that.
 */
contract ReadAccessController is WriteAccessController, EOAContext {
  /**
   * @notice Returns the access of an address
   * @param account The address to query
   * @param data The calldata to query
   */
  function hasAccess(
    address account,
    bytes memory data
  )
    public
    view
    virtual
    override
    returns (bool)
  {
    return super.hasAccess(account, data) || _isEOA(account);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

/*
 * @dev Provides information about the current execution context, specifically on if an account is an EOA on that chain.
 * Different chains have different account abstractions, so this contract helps to switch behaviour between chains.
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract EOAContext {
  function _isEOA(address account) internal view virtual returns (bool) {
      return account == tx.origin; // solhint-disable-line avoid-tx-origin
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./WriteAccessController.sol";
import "../utils/EOAContext.sol";

/**
 * @title PairReadAccessController
 * @notice Extends WriteAccessController. Decodes the (asset, denomination) pair values of msg.data.
 * @notice Gives access to:
 * - any externally owned account (note that offchain actors can always read
 * any contract storage regardless of onchain access control measures, so this
 * does not weaken the access control while improving usability)
 * - accounts explicitly added to an access list
 * @dev PairReadAccessController is not suitable for access controlling writes
 * since it grants any externally owned account access! See
 * WriteAccessController for that.
 */
contract PairReadAccessController is WriteAccessController, EOAContext {
  /**
   * @notice Returns the access of an address to an asset/denomination pair
   * @param account The address to query
   * @param data The calldata to query
   */
  function hasAccess(
    address account,
    bytes calldata data
  )
    public
    view
    virtual
    override
    returns (bool)
  {
    (
      address asset,
      address denomination
    ) = abi.decode(data[4:], (address, address));
    bytes memory pairData = abi.encode(asset, denomination); // Check access to pair (TKN / ETH)
    return super.hasAccess(account, pairData) || _isEOA(account);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./AggregatorV2V3Interface.sol";

interface AggregatorProxyInterface is AggregatorV2V3Interface {
  
	function phaseAggregators(
    uint16 phaseId
  )
    external
    view
    returns (
      address
    );

	function phaseId()
    external
    view
    returns (
      uint16
    );

	function proposedAggregator()
    external
    view
    returns (
      address
    );

	function proposedGetRoundData(
    uint80 roundId
  )
    external
    view
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

	function proposedLatestRoundData()
    external
    view
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

	function aggregator()
    external
    view
    returns (
      address
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./ConfirmedOwner.sol";
import "../interfaces/AggregatorProxyInterface.sol";

/**
 * @title A trusted proxy for updating where current answers are read from
 * @notice This contract provides a consistent address for the
 * CurrentAnwerInterface but delegates where it reads from to the owner, who is
 * trusted to update it.
 */
contract AggregatorProxy is AggregatorProxyInterface, ConfirmedOwner {

  struct Phase {
    uint16 id;
    AggregatorProxyInterface aggregator;
  }
  AggregatorProxyInterface private s_proposedAggregator;
  mapping(uint16 => AggregatorProxyInterface) private s_phaseAggregators;
  Phase private s_currentPhase;
  
  uint256 constant private PHASE_OFFSET = 64;
  uint256 constant private PHASE_SIZE = 16;
  uint256 constant private MAX_ID = 2**(PHASE_OFFSET+PHASE_SIZE) - 1;

  event AggregatorProposed(
    address indexed current,
    address indexed proposed
  );
  event AggregatorConfirmed(
    address indexed previous,
    address indexed latest
  );

  constructor(
    address aggregatorAddress
  )
    ConfirmedOwner(msg.sender)
  {
    setAggregator(aggregatorAddress);
  }

  /**
   * @notice Reads the current answer from aggregator delegated to.
   *
   * @dev #[deprecated] Use latestRoundData instead. This does not error if no
   * answer has been reached, it will simply return 0. Either wait to point to
   * an already answered Aggregator or use the recommended latestRoundData
   * instead which includes better verification information.
   */
  function latestAnswer()
    public
    view
    virtual
    override
    returns (
      int256 answer
    )
  {
    return s_currentPhase.aggregator.latestAnswer();
  }

  /**
   * @notice Reads the last updated height from aggregator delegated to.
   *
   * @dev #[deprecated] Use latestRoundData instead. This does not error if no
   * answer has been reached, it will simply return 0. Either wait to point to
   * an already answered Aggregator or use the recommended latestRoundData
   * instead which includes better verification information.
   */
  function latestTimestamp()
    public
    view
    virtual
    override
    returns (
      uint256 updatedAt
    )
  {
    return s_currentPhase.aggregator.latestTimestamp();
  }

  /**
   * @notice get past rounds answers
   * @param roundId the answer number to retrieve the answer for
   *
   * @dev #[deprecated] Use getRoundData instead. This does not error if no
   * answer has been reached, it will simply return 0. Either wait to point to
   * an already answered Aggregator or use the recommended getRoundData
   * instead which includes better verification information.
   */
  function getAnswer(
    uint256 roundId
  )
    public
    view
    virtual
    override
    returns (
      int256 answer
    )
  {
    if (roundId > MAX_ID) return 0;

    (uint16 phaseId, uint64 aggregatorRoundId) = parseIds(roundId);
    AggregatorProxyInterface aggregator = s_phaseAggregators[phaseId];
    if (address(aggregator) == address(0)) return 0;

    return aggregator.getAnswer(aggregatorRoundId);
  }

  /**
   * @notice get block timestamp when an answer was last updated
   * @param roundId the answer number to retrieve the updated timestamp for
   *
   * @dev #[deprecated] Use getRoundData instead. This does not error if no
   * answer has been reached, it will simply return 0. Either wait to point to
   * an already answered Aggregator or use the recommended getRoundData
   * instead which includes better verification information.
   */
  function getTimestamp(
    uint256 roundId
  )
    public
    view
    virtual
    override
    returns (
      uint256 updatedAt
    )
  {
    if (roundId > MAX_ID) return 0;

    (uint16 phaseId, uint64 aggregatorRoundId) = parseIds(roundId);
    AggregatorProxyInterface aggregator = s_phaseAggregators[phaseId];
    if (address(aggregator) == address(0)) return 0;

    return aggregator.getTimestamp(aggregatorRoundId);
  }

  /**
   * @notice get the latest completed round where the answer was updated. This
   * ID includes the proxy's phase, to make sure round IDs increase even when
   * switching to a newly deployed aggregator.
   *
   * @dev #[deprecated] Use latestRoundData instead. This does not error if no
   * answer has been reached, it will simply return 0. Either wait to point to
   * an already answered Aggregator or use the recommended latestRoundData
   * instead which includes better verification information.
   */
  function latestRound()
    public
    view
    virtual
    override
    returns (
      uint256 roundId
    )
  {
    Phase memory phase = s_currentPhase; // cache storage reads
    return addPhase(phase.id, uint64(phase.aggregator.latestRound()));
  }

  /**
   * @notice get data about a round. Consumers are encouraged to check
   * that they're receiving fresh data by inspecting the updatedAt and
   * answeredInRound return values.
   * Note that different underlying implementations of AggregatorV3Interface
   * have slightly different semantics for some of the return values. Consumers
   * should determine what implementations they expect to receive
   * data from and validate that they can properly handle return data from all
   * of them.
   * @param roundId the requested round ID as presented through the proxy, this
   * is made up of the aggregator's round ID with the phase ID encoded in the
   * two highest order bytes
   * @return id is the round ID from the aggregator for which the data was
   * retrieved combined with an phase to ensure that round IDs get larger as
   * time moves forward.
   * @return answer is the answer for the given round
   * @return startedAt is the timestamp when the round was started.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @return updatedAt is the timestamp when the round last was updated (i.e.
   * answer was last computed)
   * @return answeredInRound is the round ID of the round in which the answer
   * was computed.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @dev Note that answer and updatedAt may change between queries.
   */
  function getRoundData(
    uint80 roundId
  )
    public
    view
    virtual
    override
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    (uint16 phaseId, uint64 aggregatorRoundId) = parseIds(roundId);

    (
      id,
      answer,
      startedAt,
      updatedAt,
      answeredInRound
    ) = s_phaseAggregators[phaseId].getRoundData(aggregatorRoundId);

    return addPhaseIds(id, answer, startedAt, updatedAt, answeredInRound, phaseId);
  }

  /**
   * @notice get data about the latest round. Consumers are encouraged to check
   * that they're receiving fresh data by inspecting the updatedAt and
   * answeredInRound return values.
   * Note that different underlying implementations of AggregatorV3Interface
   * have slightly different semantics for some of the return values. Consumers
   * should determine what implementations they expect to receive
   * data from and validate that they can properly handle return data from all
   * of them.
   * @return id is the round ID from the aggregator for which the data was
   * retrieved combined with an phase to ensure that round IDs get larger as
   * time moves forward.
   * @return answer is the answer for the given round
   * @return startedAt is the timestamp when the round was started.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @return updatedAt is the timestamp when the round last was updated (i.e.
   * answer was last computed)
   * @return answeredInRound is the round ID of the round in which the answer
   * was computed.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @dev Note that answer and updatedAt may change between queries.
   */
  function latestRoundData()
    public
    view
    virtual
    override
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    Phase memory current = s_currentPhase; // cache storage reads

    (
      id,
      answer,
      startedAt,
      updatedAt,
      answeredInRound
    ) = current.aggregator.latestRoundData();

    return addPhaseIds(id, answer, startedAt, updatedAt, answeredInRound, current.id);
  }

  /**
   * @notice Used if an aggregator contract has been proposed.
   * @param roundId the round ID to retrieve the round data for
   * @return id is the round ID for which data was retrieved
   * @return answer is the answer for the given round
   * @return startedAt is the timestamp when the round was started.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @return updatedAt is the timestamp when the round last was updated (i.e.
   * answer was last computed)
   * @return answeredInRound is the round ID of the round in which the answer
   * was computed.
  */
  function proposedGetRoundData(
    uint80 roundId
  )
    external
    view
    virtual
    override
    hasProposal()
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return s_proposedAggregator.getRoundData(roundId);
  }

  /**
   * @notice Used if an aggregator contract has been proposed.
   * @return id is the round ID for which data was retrieved
   * @return answer is the answer for the given round
   * @return startedAt is the timestamp when the round was started.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @return updatedAt is the timestamp when the round last was updated (i.e.
   * answer was last computed)
   * @return answeredInRound is the round ID of the round in which the answer
   * was computed.
  */
  function proposedLatestRoundData()
    external
    view
    virtual
    override
    hasProposal()
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return s_proposedAggregator.latestRoundData();
  }

  /**
   * @notice returns the current phase's aggregator address.
   */
  function aggregator()
    external
    view
    override
    returns (
      address
    )
  {
    return address(s_currentPhase.aggregator);
  }

  /**
   * @notice returns the current phase's ID.
   */
  function phaseId()
    external
    view
    override
    returns (
      uint16
    )
  {
    return s_currentPhase.id;
  }

  /**
   * @notice represents the number of decimals the aggregator responses represent.
   */
  function decimals()
    external
    view
    override
    returns (
      uint8
    )
  {
    return s_currentPhase.aggregator.decimals();
  }

  /**
   * @notice the version number representing the type of aggregator the proxy
   * points to.
   */
  function version()
    external
    view
    override
    returns (
      uint256
    )
  {
    return s_currentPhase.aggregator.version();
  }

  /**
   * @notice returns the description of the aggregator the proxy points to.
   */
  function description()
    external
    view
    override
    returns (
      string memory
    )
  {
    return s_currentPhase.aggregator.description();
  }

  /**
   * @notice returns the current proposed aggregator
   */
  function proposedAggregator()
    external
    view
    override
    returns (
      address
    )
  {
    return address(s_proposedAggregator);
  }

  /**
   * @notice return a phase aggregator using the phaseId
   *
   * @param phaseId uint16
   */
  function phaseAggregators(
    uint16 phaseId
  )
    external
    view
    override
    returns (
      address
    )
  {
    return address(s_phaseAggregators[phaseId]);
  }

  /**
   * @notice Allows the owner to propose a new address for the aggregator
   * @param aggregatorAddress The new address for the aggregator contract
   */
  function proposeAggregator(
    address aggregatorAddress
  )
    external
    onlyOwner()
  {
    s_proposedAggregator = AggregatorProxyInterface(aggregatorAddress);
    emit AggregatorProposed(address(s_currentPhase.aggregator), aggregatorAddress);
  }

  /**
   * @notice Allows the owner to confirm and change the address
   * to the proposed aggregator
   * @dev Reverts if the given address doesn't match what was previously
   * proposed
   * @param aggregatorAddress The new address for the aggregator contract
   */
  function confirmAggregator(
    address aggregatorAddress
  )
    external
    onlyOwner()
  {
    require(aggregatorAddress == address(s_proposedAggregator), "Invalid proposed aggregator");
    address previousAggregator = address(s_currentPhase.aggregator);
    delete s_proposedAggregator;
    setAggregator(aggregatorAddress);
    emit AggregatorConfirmed(previousAggregator, aggregatorAddress);
  }


  /*
   * Internal
   */

  function setAggregator(
    address aggregatorAddress
  )
    internal
  {
    uint16 id = s_currentPhase.id + 1;
    s_currentPhase = Phase(id, AggregatorProxyInterface(aggregatorAddress));
    s_phaseAggregators[id] = AggregatorProxyInterface(aggregatorAddress);
  }

  function addPhase(
    uint16 phase,
    uint64 originalId
  )
    internal
    pure
    returns (
      uint80
    )
  {
    return uint80(uint256(phase) << PHASE_OFFSET | originalId);
  }

  function parseIds(
    uint256 roundId
  )
    internal
    pure
    returns (
      uint16,
      uint64
    )
  {
    uint16 phaseId = uint16(roundId >> PHASE_OFFSET);
    uint64 aggregatorRoundId = uint64(roundId);

    return (phaseId, aggregatorRoundId);
  }

  function addPhaseIds(
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound,
      uint16 phaseId
  )
    internal
    pure
    returns (
      uint80,
      int256,
      uint256,
      uint256,
      uint80
    )
  {
    return (
      addPhase(phaseId, uint64(roundId)),
      answer,
      startedAt,
      updatedAt,
      addPhase(phaseId, uint64(answeredInRound))
    );
  }

  /*
   * Modifiers
   */

  modifier hasProposal() {
    require(address(s_proposedAggregator) != address(0), "No proposed aggregator present");
    _;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner {

  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(
    address indexed from,
    address indexed to
  );
  event OwnershipTransferred(
    address indexed from,
    address indexed to
  );

  constructor(address newOwner) {
    s_owner = newOwner;
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(
    address to
  )
    external
    onlyOwner()
  {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership()
    external
  {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner()
    public
    view
    returns (
      address
    )
  {
    return s_owner;
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    require(msg.sender == s_owner, "Only callable by owner");
    _;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@chainlink/contracts/src/v0.7/dev/AggregatorProxy.sol";

contract MockAggregatorProxy is AggregatorProxy {
    constructor(
        address aggregatorAddress
    ) AggregatorProxy(aggregatorAddress) {} // solhint-disable-line
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
  "metadata": {
    "useLiteralContent": true
  }
}