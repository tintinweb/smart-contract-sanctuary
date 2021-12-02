// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./AggregatorProxy.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AccessControllerInterface.sol";

contract EACAggregatorProxy is AggregatorProxy {
    AccessControllerInterface public accessController;

    constructor(address _aggregator, address _accessController) AggregatorProxy(_aggregator) {
        setController(_accessController);
    }

    /**
     * @notice Allows the owner to update the accessController contract address.
     * @param _accessController The new address for the accessController contract
     */
    function setController(address _accessController) public onlyOwner {
        accessController = AccessControllerInterface(_accessController);
    }

    /**
     * @notice Reads the current answer from aggregator delegated to.
     * @dev overridden function to add the checkAccess() modifier
     *
     * @dev #[deprecated] Use latestRoundData instead. This does not error if no
     * answer has been reached, it will simply return 0. Either wait to point to
     * an already answered Aggregator or use the recommended latestRoundData
     * instead which includes better verification information.
     */
    function latestAnswer() public view override checkAccess returns (int256) {
        return super.latestAnswer();
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
    function latestTimestamp() public view override checkAccess returns (uint256) {
        return super.latestTimestamp();
    }

    /**
     * @notice get past rounds answers
     * @param _roundId the answer number to retrieve the answer for
     * @dev overridden function to add the checkAccess() modifier
     *
     * @dev #[deprecated] Use getRoundData instead. This does not error if no
     * answer has been reached, it will simply return 0. Either wait to point to
     * an already answered Aggregator or use the recommended getRoundData
     * instead which includes better verification information.
     */
    function getAnswer(uint256 _roundId) public view override checkAccess returns (int256) {
        return super.getAnswer(_roundId);
    }

    /**
     * @notice get block timestamp when an answer was last updated
     * @param _roundId the answer number to retrieve the updated timestamp for
     * @dev overridden function to add the checkAccess() modifier
     *
     * @dev #[deprecated] Use getRoundData instead. This does not error if no
     * answer has been reached, it will simply return 0. Either wait to point to
     * an already answered Aggregator or use the recommended getRoundData
     * instead which includes better verification information.
     */
    function getTimestamp(uint256 _roundId) public view override checkAccess returns (uint256) {
        return super.getTimestamp(_roundId);
    }

    /**
     * @notice get the latest completed round where the answer was updated
     * @dev overridden function to add the checkAccess() modifier
     *
     * @dev #[deprecated] Use latestRoundData instead. This does not error if no
     * answer has been reached, it will simply return 0. Either wait to point to
     * an already answered Aggregator or use the recommended latestRoundData
     * instead which includes better verification information.
     */
    function latestRound() public view override checkAccess returns (uint256) {
        return super.latestRound();
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
     * @param _roundId the round ID to retrieve the round data for
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
    function getRoundData(uint80 _roundId)
        public
        view
        override
        checkAccess
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return super.getRoundData(_roundId);
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
    function latestRoundData()
        public
        view
        override
        checkAccess
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return super.latestRoundData();
    }

    /**
     * @notice Used if an aggregator contract has been proposed.
     * @param _roundId the round ID to retrieve the round data for
     * @return roundId is the round ID for which data was retrieved
     * @return answer is the answer for the given round
     * @return startedAt is the timestamp when the round was started.
     * (Only some AggregatorV3Interface implementations return meaningful values)
     * @return updatedAt is the timestamp when the round last was updated (i.e.
     * answer was last computed)
     * @return answeredInRound is the round ID of the round in which the answer
     * was computed.
     */
    function proposedGetRoundData(uint80 _roundId)
        public
        view
        override
        checkAccess
        hasProposal
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return super.proposedGetRoundData(_roundId);
    }

    /**
     * @notice Used if an aggregator contract has been proposed.
     * @return roundId is the round ID for which data was retrieved
     * @return answer is the answer for the given round
     * @return startedAt is the timestamp when the round was started.
     * (Only some AggregatorV3Interface implementations return meaningful values)
     * @return updatedAt is the timestamp when the round last was updated (i.e.
     * answer was last computed)
     * @return answeredInRound is the round ID of the round in which the answer
     * was computed.
     */
    function proposedLatestRoundData()
        public
        view
        override
        checkAccess
        hasProposal
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return super.proposedLatestRoundData();
    }

    /**
     * @dev reverts if the caller does not have access by the accessController
     * contract or is the contract itself.
     */
    modifier checkAccess() {
        AccessControllerInterface ac = accessController;
        require(address(ac) == address(0) || ac.hasAccess(msg.sender, msg.data), "No access");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@chainlink/contracts/src/v0.7/ConfirmedOwner.sol";
import "@chainlink/contracts/src/v0.7/interfaces/AggregatorProxyInterface.sol";

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

    uint256 private constant PHASE_OFFSET = 64;
    uint256 private constant PHASE_SIZE = 16;
    uint256 private constant MAX_ID = 2**(PHASE_OFFSET + PHASE_SIZE) - 1;

    event AggregatorProposed(address indexed current, address indexed proposed);
    event AggregatorConfirmed(address indexed previous, address indexed latest);

    constructor(address aggregatorAddress) ConfirmedOwner(msg.sender) {
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
    function latestAnswer() public view virtual override returns (int256 answer) {
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
    function latestTimestamp() public view virtual override returns (uint256 updatedAt) {
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
    function getAnswer(uint256 roundId) public view virtual override returns (int256 answer) {
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
    function getTimestamp(uint256 roundId) public view virtual override returns (uint256 updatedAt) {
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
    function latestRound() public view virtual override returns (uint256 roundId) {
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
    function getRoundData(uint80 roundId)
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

        (id, answer, startedAt, updatedAt, answeredInRound) = s_phaseAggregators[phaseId].getRoundData(
            aggregatorRoundId
        );

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

        (id, answer, startedAt, updatedAt, answeredInRound) = current.aggregator.latestRoundData();

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
    function proposedGetRoundData(uint80 roundId)
        public
        view
        virtual
        override
        hasProposal
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
        public
        view
        virtual
        override
        hasProposal
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
    function aggregator() external view override returns (address) {
        return address(s_currentPhase.aggregator);
    }

    /**
     * @notice returns the current phase's ID.
     */
    function phaseId() external view override returns (uint16) {
        return s_currentPhase.id;
    }

    /**
     * @notice represents the number of decimals the aggregator responses represent.
     */
    function decimals() external view override returns (uint8) {
        return s_currentPhase.aggregator.decimals();
    }

    /**
     * @notice the version number representing the type of aggregator the proxy
     * points to.
     */
    function version() external view override returns (uint256) {
        return s_currentPhase.aggregator.version();
    }

    /**
     * @notice returns the description of the aggregator the proxy points to.
     */
    function description() external view override returns (string memory) {
        return s_currentPhase.aggregator.description();
    }

    /**
     * @notice returns the current proposed aggregator
     */
    function proposedAggregator() external view override returns (address) {
        return address(s_proposedAggregator);
    }

    /**
     * @notice return a phase aggregator using the phaseId
     *
     * @param phaseId uint16
     */
    function phaseAggregators(uint16 phaseId) external view override returns (address) {
        return address(s_phaseAggregators[phaseId]);
    }

    /**
     * @notice Allows the owner to propose a new address for the aggregator
     * @param aggregatorAddress The new address for the aggregator contract
     */
    function proposeAggregator(address aggregatorAddress) external onlyOwner {
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
    function confirmAggregator(address aggregatorAddress) external onlyOwner {
        require(aggregatorAddress == address(s_proposedAggregator), "Invalid proposed aggregator");
        address previousAggregator = address(s_currentPhase.aggregator);
        delete s_proposedAggregator;
        setAggregator(aggregatorAddress);
        emit AggregatorConfirmed(previousAggregator, aggregatorAddress);
    }

    /*
     * Internal
     */

    function setAggregator(address aggregatorAddress) internal {
        uint16 id = s_currentPhase.id + 1;
        s_currentPhase = Phase(id, AggregatorProxyInterface(aggregatorAddress));
        s_phaseAggregators[id] = AggregatorProxyInterface(aggregatorAddress);
    }

    function addPhase(uint16 phase, uint64 originalId) internal pure returns (uint80) {
        return uint80((uint256(phase) << PHASE_OFFSET) | originalId);
    }

    function parseIds(uint256 roundId) internal pure returns (uint16, uint64) {
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

import "./interfaces/OwnableInterface.sol";

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
    address newOwner,
    address pendingOwner
  ) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
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
    view
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
pragma solidity ^0.7.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface
{
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