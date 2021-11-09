// SPDX-License-Identifier: MIT
// forked from https://github.com/smartcontractkit/libocr/blob/d12971936c1289ae0d512723a9e8535ce382ff6d/contract/OffchainAggregator.sol
pragma solidity ^0.7.0;

import "./AggregatorV2V3Interface.sol";
import "./TypeAndVersionInterface.sol";

/**
  * @notice Onchain verification of reports from the offchain reporting protocol

  * @dev For details on its operation, see the offchain reporting protocol design
  * @dev doc, which refers to this contract as simply the "contract".
*/
contract VerySimpleOffchainAggregator is AggregatorV2V3Interface, TypeAndVersionInterface {

  // Storing these fields used on the hot path in a HotVars variable reduces the
  // retrieval of all of them to a single SLOAD. If any further fields are
  // added, make sure that storage of the struct still takes at most 32 bytes.
  struct HotVars {
    // Provides 128 bits of security against 2nd pre-image attacks, but only
    // 64 bits against collisions. This is acceptable, since a malicious owner has
    // easier way of messing up the protocol than to find hash collisions.
    bytes16 latestConfigDigest;
    uint40 latestEpochAndRound; // 32 most sig bits for epoch, 8 least sig bits for round
    // Current bound assumed on number of faulty/dishonest oracles participating
    // in the protocol, this value is referred to as f in the design
    uint8 threshold;
    // Chainlink Aggregators expose a roundId to consumers. The offchain reporting
    // protocol does not use this id anywhere. We increment it whenever a new
    // transmission is made to provide callers with contiguous ids for successive
    // reports.
    uint32 latestAggregatorRoundId;
  }
  HotVars internal s_hotVars;

  // Transmission records the median answer from the transmit transaction at
  // time timestamp
  struct Transmission {
    int192 answer; // 192 bits ought to be enough for anyone
    uint64 timestamp;
  }
  mapping(uint32 /* aggregator round ID */ => Transmission) internal s_transmissions;

  // Lowest answer the system is allowed to report in response to transmissions
  int192 immutable public minAnswer;
  // Highest answer the system is allowed to report in response to transmissions
  int192 immutable public maxAnswer;

  // Used for s_oracles[a].role, where a is an address, to track the purpose
  // of the address, or to indicate that the address is unset.
  enum Role {
    // No oracle role has been set for address a
    Unset,
    // Transmission address for the s_oracles[a].index'th oracle. I.e., if a
    // report is received by OffchainAggregator.transmit in which msg.sender is
    // a, it is attributed to the s_oracles[a].index'th oracle.
    Transmitter
  }

  struct Oracle {
    uint8 index; // Index of oracle in s_transmitters
    Role role;   // Role of the address which mapped to this struct
  }

  mapping (address /* transmitter address */ => Oracle)
    internal s_oracles;

  // s_transmitters contains the transmission address of each oracle,
  // i.e. the address the oracle actually sends transactions to the contract from
  address[] internal s_transmitters;

  /*
   * @param _minAnswer lowest answer the median of a report is allowed to be
   * @param _maxAnswer highest answer the median of a report is allowed to be
   * @param _decimals answers are stored in fixed-point format, with this many digits of precision
   * @param _description short human-readable description of observable this contract's answers pertain to
   * @param _transmitters addresses oracles use to transmit the reports
   */
  constructor(
    int192 _minAnswer,
    int192 _maxAnswer,
    uint8 _decimals,
    string memory _description,
    address[] memory _transmitters
  ) {
    decimals = _decimals;
    s_description = _description;
    minAnswer = _minAnswer;
    maxAnswer = _maxAnswer;
    for (uint i = 0; i < _transmitters.length; i++) { // add new transmitter addresses
      require(
        s_oracles[_transmitters[i]].role == Role.Unset,
        "repeated transmitter address"
      );
      s_oracles[_transmitters[i]] = Oracle(uint8(i), Role.Transmitter);
      s_transmitters.push(_transmitters[i]);
    }
    s_hotVars.latestEpochAndRound = 0;
  }

  /*
   * Versioning
   */
  function typeAndVersion()
    external
    override
    pure
    virtual
    returns (string memory)
  {
    return "VerySimpleOffchainAggregator 0.0.1";
  }


  /**
   * @return list of addresses permitted to transmit reports to this contract

   * @dev The list will match the order used to specify the transmitter during construction
   */
  function transmitters()
    external
    view
    returns(address[] memory)
  {
    return s_transmitters;
  }

  /*
   * Transmission logic
   */

  /**
   * @notice indicates that a new report was transmitted
   * @param aggregatorRoundId the round to which this report was assigned
   * @param answer median of the observations attached this report
   * @param transmitter address from which the report was transmitted
   * @param rawReportContext signature-replay-prevention domain-separation tag
   */
  event NewTransmission(
    uint32 indexed aggregatorRoundId,
    int192 answer,
    address transmitter,
    bytes32 rawReportContext
  );

  // decodeReport is used to check that the solidity and go code are using the
  // same format. See TestOffchainAggregator.testDecodeReport and TestReportParsing
  function decodeReport(bytes memory _report)
    internal
    pure
    returns (
      bytes32 rawReportContext,
      int192 observation
    )
  {
    (rawReportContext, observation) = abi.decode(_report,
      (bytes32, int192));
  }

  // Used to relieve stack pressure in transmit
  struct ReportData {
    HotVars hotVars; // Only read from storage once
    int192 observation; // observation
    bytes32 rawReportContext;
  }

  /*
   * @notice details about the most recent report

   * @return configDigest domain separation tag for the latest report
   * @return epoch epoch in which the latest report was generated
   * @return round OCR round in which the latest report was generated
   * @return latestAnswer median value from latest report
   * @return latestTimestamp when the latest report was transmitted
   */
  function latestTransmissionDetails()
    external
    view
    returns (
      bytes16 configDigest,
      uint32 epoch,
      uint8 round,
      int192 latestAnswer,
      uint64 latestTimestamp
    )
  {
    require(msg.sender == tx.origin, "Only callable by EOA");
    return (
      s_hotVars.latestConfigDigest,
      uint32(s_hotVars.latestEpochAndRound >> 8),
      uint8(s_hotVars.latestEpochAndRound),
      s_transmissions[s_hotVars.latestAggregatorRoundId].answer,
      s_transmissions[s_hotVars.latestAggregatorRoundId].timestamp
    );
  }

  // The constant-length components of the msg.data sent to transmit.
  // See the "If we wanted to call sam" example on for example reasoning
  // https://solidity.readthedocs.io/en/v0.7.2/abi-spec.html
  uint16 private constant TRANSMIT_MSGDATA_CONSTANT_LENGTH_COMPONENT =
    4 + // function selector
    32 + // word containing start location of abiencoded _report value
    32 + // word containing length of _report
    0; // placeholder

  function expectedMsgDataLength(
    bytes calldata _report
  ) private pure returns (uint256 length)
  {
    // calldata will never be big enough to make this overflow
    return uint256(TRANSMIT_MSGDATA_CONSTANT_LENGTH_COMPONENT) +
      _report.length + // one byte pure entry in _report
      0; // placeholder
  }

  /**
   * @notice transmit is called to post a new report to the contract
   * @param _report serialized report. See parsing code below for format.
   */
  function transmit(
    // NOTE: If these parameters are changed, expectedMsgDataLength and/or
    // TRANSMIT_MSGDATA_CONSTANT_LENGTH_COMPONENT need to be changed accordingly
    bytes calldata _report
  )
    external
  {
    // Make sure the transmit message-length matches the inputs. Otherwise, the
    // transmitter could append an arbitrarily long (up to gas-block limit)
    // string of 0 bytes, which we would reimburse at a rate of 16 gas/byte, but
    // which would only cost the transmitter 4 gas/byte. (Appendix G of the
    // yellow paper, p. 25, for G_txdatazero and EIP 2028 for G_txdatanonzero.)
    // This could amount to reimbursement profit of 36 million gas, given a 3MB
    // zero tail.
    require(msg.data.length == expectedMsgDataLength(_report),
      "transmit message too long");
    ReportData memory r; // Relieves stack pressure
    {
      r.hotVars = s_hotVars; // cache read from storage

      (r.rawReportContext, r.observation) = abi.decode(
        _report, (bytes32, int192)
      );

      // rawReportContext consists of:
      // 11-byte zero padding
      // 16-byte configDigest
      // 4-byte epoch
      // 1-byte round

      bytes16 configDigest = bytes16(r.rawReportContext << 88);
      require(
        r.hotVars.latestConfigDigest == configDigest,
        "configDigest mismatch"
      );

      uint40 epochAndRound = uint40(uint256(r.rawReportContext));

      // direct numerical comparison works here, because
      //
      //   ((e,r) <= (e',r')) implies (epochAndRound <= epochAndRound')
      //
      // because alphabetic ordering implies e <= e', and if e = e', then r<=r',
      // so e*256+r <= e'*256+r', because r, r' < 256
      require(r.hotVars.latestEpochAndRound < epochAndRound, "stale report");

      Oracle memory transmitter = s_oracles[msg.sender];
      require( // Check that sender is authorized to report
        transmitter.role == Role.Transmitter &&
        msg.sender == s_transmitters[transmitter.index],
        "unauthorized transmitter"
      );
      // record epochAndRound here, so that we don't have to carry the local
      // variable in transmit. The change is reverted if something fails later.
      r.hotVars.latestEpochAndRound = epochAndRound;
    }

    { // Check the report contents, and record the result

      require(minAnswer <= r.observation && r.observation <= maxAnswer, "observation is out of min-max range");
      r.hotVars.latestAggregatorRoundId++;
      s_transmissions[r.hotVars.latestAggregatorRoundId] =
        Transmission(r.observation, uint64(block.timestamp));

      emit NewTransmission(
        r.hotVars.latestAggregatorRoundId,
        r.observation,
        msg.sender,
        r.rawReportContext
      );
      // Emit these for backwards compatability with offchain consumers
      // that only support legacy events
      emit NewRound(
        r.hotVars.latestAggregatorRoundId,
        address(0x0), // use zero address since we don't have anybody "starting" the round here
        block.timestamp
      );
      emit AnswerUpdated(
        r.observation,
        r.hotVars.latestAggregatorRoundId,
        block.timestamp
      );
    }
    s_hotVars = r.hotVars;
  }

  /*
   * v2 Aggregator interface
   */

  /**
   * @notice median from the most recent report
   */
  function latestAnswer()
    public
    override
    view
    virtual
    returns (int256)
  {
    return s_transmissions[s_hotVars.latestAggregatorRoundId].answer;
  }

  /**
   * @notice timestamp of block in which last report was transmitted
   */
  function latestTimestamp()
    public
    override
    view
    virtual
    returns (uint256)
  {
    return s_transmissions[s_hotVars.latestAggregatorRoundId].timestamp;
  }

  /**
   * @notice Aggregator round (NOT OCR round) in which last report was transmitted
   */
  function latestRound()
    public
    override
    view
    virtual
    returns (uint256)
  {
    return s_hotVars.latestAggregatorRoundId;
  }

  /**
   * @notice median of report from given aggregator round (NOT OCR round)
   * @param _roundId the aggregator round of the target report
   */
  function getAnswer(uint256 _roundId)
    public
    override
    view
    virtual
    returns (int256)
  {
    if (_roundId > 0xFFFFFFFF) { return 0; }
    return s_transmissions[uint32(_roundId)].answer;
  }

  /**
   * @notice timestamp of block in which report from given aggregator round was transmitted
   * @param _roundId aggregator round (NOT OCR round) of target report
   */
  function getTimestamp(uint256 _roundId)
    public
    override
    view
    virtual
    returns (uint256)
  {
    if (_roundId > 0xFFFFFFFF) { return 0; }
    return s_transmissions[uint32(_roundId)].timestamp;
  }

  /*
   * v3 Aggregator interface
   */

  string constant private V3_NO_DATA_ERROR = "No data present";

  /**
   * @return answers are stored in fixed-point format, with this many digits of precision
   */
  uint8 immutable public override decimals;

  /**
   * @notice aggregator contract version
   */
  uint256 constant public override version = 4;

  string internal s_description;

  /**
   * @notice human-readable description of observable this contract is reporting on
   */
  function description()
    public
    override
    view
    virtual
    returns (string memory)
  {
    return s_description;
  }

  /**
   * @notice details for the given aggregator round
   * @param _roundId target aggregator round (NOT OCR round). Must fit in uint32
   * @return roundId _roundId
   * @return answer median of report from given _roundId
   * @return startedAt timestamp of block in which report from given _roundId was transmitted
   * @return updatedAt timestamp of block in which report from given _roundId was transmitted
   * @return answeredInRound _roundId
   */
  function getRoundData(uint80 _roundId)
    public
    override
    view
    virtual
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    require(_roundId <= 0xFFFFFFFF, V3_NO_DATA_ERROR);
    Transmission memory transmission = s_transmissions[uint32(_roundId)];
    return (
      _roundId,
      transmission.answer,
      transmission.timestamp,
      transmission.timestamp,
      _roundId
    );
  }

  /**
   * @notice aggregator details for the most recently transmitted report
   * @return roundId aggregator round of latest report (NOT OCR round)
   * @return answer median of latest report
   * @return startedAt timestamp of block containing latest report
   * @return updatedAt timestamp of block containing latest report
   * @return answeredInRound aggregator round of latest report
   */
  function latestRoundData()
    public
    override
    view
    virtual
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    roundId = s_hotVars.latestAggregatorRoundId;

    // Skipped for compatability with existing FluxAggregator in which latestRoundData never reverts.
    // require(roundId != 0, V3_NO_DATA_ERROR);

    Transmission memory transmission = s_transmissions[uint32(roundId)];
    return (
      roundId,
      transmission.answer,
      transmission.timestamp,
      transmission.timestamp,
      roundId
    );
  }
}

// SPDX-License-Identifier: MIT
// https://github.com/smartcontractkit/libocr/blob/d12971936c1289ae0d512723a9e8535ce382ff6d/contract/AggregatorV2V3Interface.sol
pragma solidity ^0.7.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface
{
}

// SPDX-License-Identifier: MIT
// https://github.com/smartcontractkit/libocr/blob/d12971936c1289ae0d512723a9e8535ce382ff6d/contract/TypeAndVersionInterface.sol
pragma solidity ^0.7.0;

abstract contract TypeAndVersionInterface{
  function typeAndVersion()
    external
    pure
    virtual
    returns (string memory);
}

// SPDX-License-Identifier: MIT
// https://github.com/smartcontractkit/libocr/blob/d12971936c1289ae0d512723a9e8535ce382ff6d/contract/AggregatorInterface.sol
pragma solidity ^0.7.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
// https://github.com/smartcontractkit/libocr/blob/d12971936c1289ae0d512723a9e8535ce382ff6d/contract/AggregatorV3Interface.sol
pragma solidity ^0.7.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
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