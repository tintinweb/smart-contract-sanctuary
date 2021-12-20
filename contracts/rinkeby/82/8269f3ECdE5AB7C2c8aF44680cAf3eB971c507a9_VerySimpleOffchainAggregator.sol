// SPDX-License-Identifier: MIT
// forked from https://github.com/smartcontractkit/libocr/blob/d12971936c1289ae0d512723a9e8535ce382ff6d/contract/OffchainAggregator.sol
pragma solidity ^0.8.0;

import "./AggregatorV2V3Interface.sol";
import "./TypeAndVersionInterface.sol";

/*
    * @notice Onchain verification of reports from the offchain reporting protocol
    * @dev For details on its operation, see the offchain reporting protocol design
    * @dev doc, which refers to this contract as simply the "contract".
*/
contract VerySimpleOffchainAggregator is AggregatorV2V3Interface, TypeAndVersionInterface {

  // Storing these fields used on the hot path in a HotVars variable reduces the
  // retrieval of all of them to a single SLOAD. If any further fields are
  // added, make sure that storage of the struct still takes at most 32 bytes.
  struct HotVars {
    uint32 latestEpoch; // 32 bits for epoch (unixtime)
    // Aggregators expose a roundId to consumers. The offchain reporting
    // protocol does not use this id anywhere. We increment it whenever a new
    // transmission is made to provide callers with contiguous ids for successive
    // reports.
    uint32 latestAggregatorRoundId;
    // strong compatible mode. if it is true that _report in the function transmit: min.int192 < _report < max.int192
    // details in test scrips
    bool scompatibleINT192;
    // ToDo: ++ payment logic
  }
  HotVars internal s_hotVars;

  // Transmission records the answer from the transmit transaction at
  // time timestamp
  struct Transmission {
    int256 answer; // int256 .. see orignal v3 Aggregator interface
    uint32 observationsTimestamp; // when were observations made offchain
    uint64 transmissionTimestamp; // when was report received onchain == block.timestamp
  }
  mapping(uint32 /* aggregator round ID */ => Transmission) internal s_transmissions;

  mapping (address /* transmitter address */ => bool) internal s_oracles; // access list

  // s_transmitters contains the transmission address of each oracle,
  // i.e. the address the oracle actually sends transactions to the contract from
  address[] internal s_transmitters;

   /*
   * @param _decimals answers are stored in fixed-point format, with this many digits of precision
   * @param _description short human-readable description of observable this contract's answers pertain to
   * @param _transmitters addresses oracles use to transmit the reports
   * @param _epoch local time of deployer. (unix time). lower limit for subsequent epoch.
   * @param _scompatibleINT192 strong compatible mode. if it is true that _report in the function transmit: min.int192 < _report < max.int192
   */
  constructor(
    uint8 _decimals,
    string memory _description,
    address[] memory _transmitters,
    uint32 _epoch,
    bool _scompatibleINT192
  ) {
    decimals = _decimals;
    s_description = _description;
    for (uint i = 0; i < _transmitters.length; i++) { // add new transmitter addresses
      s_oracles[_transmitters[i]] = true;
      s_transmitters.push(_transmitters[i]);
    }
    s_hotVars.latestEpoch = _epoch;
    s_hotVars.scompatibleINT192 = _scompatibleINT192;
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
    return "VerySimpleOffchainAggregator 0.0.2";
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

   /**
   * @return strong compatible mode. if it is true that _report in the function transmit must be: min.int192 <= _report <= max.int192
   * @dev strong compatible mode. if it is true that _report in the function transmit must be: min.int192 <= _report <= max.int192
   */
  function getSCompatibleINT192()
    external
    view
    returns(bool)
  {
    return s_hotVars.scompatibleINT192;
  }

  /*
  * Transmission logic
  */

  // compatible with ChainLink
  /**
   * @notice indicates that a new report was transmitted
   * @param aggregatorRoundId the round to which this report was assigned
   * @param answer median (agg) of the observations attached this report
   * @param transmitter address from which the report was transmitted
   * @param rawReportContext signature-replay-prevention domain-separation tag
   */
  event NewTransmission(
    uint32 indexed aggregatorRoundId,
    int192 answer,
    address transmitter,
    bytes32 rawReportContext
  );

  // optimized event
  /**
   * @notice indicates that a new report was transmitted
   * @param aggregatorRoundId the round to which this report was assigned
   * @param answer median (agg.) of the observations attached this report
   * @param transmitter address from which the report was transmitted
   */
  event NewTransmissionV2(
    uint32 indexed aggregatorRoundId,
    int256 answer,
    address transmitter
  );

  // event for store in Log _reportRaw = for each of answerRaw
  /**
   * @notice indicates that a new report was transmitted
   * @param aggregatorRoundId the round to which this report was assigned
   * @param answerRaw the observations attached this report
   * @param transmitter address from which the report was transmitted
   */
  event NewTransmissionV2Raw(
    uint32 indexed aggregatorRoundId,
    int256 answerRaw,
    address transmitter
  );

   // compatible with ChainLink
   /*
   * @notice details about the most recent report
   * @return configDigest domain separation tag for the latest report .. for compatible only
   * @return epoch epoch in which the latest report was generated
   * @return round OCR round in which the latest report was generated .. for compatible only
   * @return latestAnswer_ value from latest report
   * @return latestTimestamp_ when the latest report was transmitted
   */
  function latestTransmissionDetails()
    external
    view
    returns (
      bytes16 configDigest,
      uint32 epoch,
      uint8 round,
      int192 latestAnswer_,
      uint64 latestTimestamp_
    )
  {
    // require(msg.sender == tx.origin, "Only callable by EOA");
    return (
      bytes16(""),
      s_hotVars.latestEpoch,
      uint8(0),
      int192(s_transmissions[s_hotVars.latestAggregatorRoundId].answer),
      s_transmissions[s_hotVars.latestAggregatorRoundId].transmissionTimestamp
    );
  }

  /*
   * @notice details about the most recent report
   * @return epoch epoch in which the latest report was generated
   * @return latestAnswer value from latest report
   * @return latestTimestamp when the latest report was transmitted
   */
  function latestTransmissionDetailsV2()
    external
    view
    returns (
      uint32 epoch,
      int256 latestAnswer_,
      uint64 latestTimestamp_
    )
  {
    return (
      s_hotVars.latestEpoch,
      s_transmissions[s_hotVars.latestAggregatorRoundId].answer,
      s_transmissions[s_hotVars.latestAggregatorRoundId].transmissionTimestamp
    );
  }

  /**
   * @notice transmit is called to post a new report to the contract
   * @param _report agg report. stored
   * @param _reportRaw for submit the observation data on-chain and just store it as a junk (not used in compute anywhere). [] - ok
   * @param _epoch transmitter localtime (unix timestamp).  transmitter must have synchronized clock by NTP
   */
  function transmit(
    int256 _report,
    int256[] calldata _reportRaw, // low gas
    uint32 _epoch
  )
    external
  {
    require(s_oracles[msg.sender] == true, "unauthorized transmitter");
    uint8 threshold = 15; // 15s, possible mismatch between time of miner/block producer (important for hardhat node) and NTP time of transmitter
    // transmitter MUST have synchronized clock by NTP
    require(_epoch <= (block.timestamp + threshold), "report from the future");

    HotVars memory hotVars = s_hotVars;

    require(hotVars.latestEpoch <= _epoch, "stale report");

    if (hotVars.scompatibleINT192) {
      require(_report <= type(int192).max,"_report > max int192");
      require(_report >= type(int192).min,"_report < min int192");
    }

    hotVars.latestAggregatorRoundId++;
    hotVars.latestEpoch = _epoch;
    s_transmissions[hotVars.latestAggregatorRoundId] = Transmission(_report, _epoch, uint64(block.timestamp));

    // Emit these for backwards compatability with ChainLink
    // that only support legacy events
    emit NewTransmission(
      hotVars.latestAggregatorRoundId,
      int192(_report),
      msg.sender,
      bytes32("")
    );
    // New short version of event
    emit NewTransmissionV2(
      hotVars.latestAggregatorRoundId,
      _report,
      msg.sender
    );
    // We should optionally, in addition to the aggregate value,
    // be able to submit the observation data on-chain and just store it as a junk (not used in compute anywhere).
    for (uint i = 0; i < _reportRaw.length; i++) {
      emit NewTransmissionV2Raw(
      hotVars.latestAggregatorRoundId,
      _reportRaw[i],
      msg.sender
    );
    }
    // Emit these for backwards compatability with ChainLink
    // that only support legacy events
    emit NewRound(
      hotVars.latestAggregatorRoundId,
      address(0x0), // use zero address since we don't have anybody "starting" the round here
      block.timestamp
    );
    // backwards compatability with ChainLink
    emit AnswerUpdated(
      _report,
      hotVars.latestAggregatorRoundId,
      block.timestamp
    );
    // persist updates to hotVars
    s_hotVars = hotVars;
  }

  /*
   * v2 Aggregator interface
   */

  /**
   * @notice answer from the most recent report
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
    return s_transmissions[s_hotVars.latestAggregatorRoundId].transmissionTimestamp;
  }

  /**
   * @notice Aggregator round in which last report was transmitted
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
    if(_roundId > type(uint32).max) { return 0; }
    return s_transmissions[uint32(_roundId)].answer;
  }
  /**
   * @notice timestamp of block in which report from given aggregator round was transmitted
   * @param _roundId aggregator round of target report
   */
  function getTimestamp(uint256 _roundId)
    public
    override
    view
    virtual
    returns (uint256)
  {
    if(_roundId > type(uint32).max) { return 0; }
    return s_transmissions[uint32(_roundId)].transmissionTimestamp;
  }

  /*
   * v3 Aggregator interface
   */

  /**
   * @return answers are stored in fixed-point format, with this many digits of precision
   */
  uint8 immutable public override decimals;

  /**
   * @notice aggregator contract version
   */
  uint256 constant public override version = 1;

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
   * @param _roundId target aggregator round. Must fit in uint32
   * @return roundId _roundId
   * @return answer from given _roundId
   * @return startedAt offchain timestamp in which report from given _roundId was transmitted
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

    if(_roundId > type(uint32).max) { return (0, 0, 0, 0, 0); }
    Transmission memory transmission = s_transmissions[uint32(_roundId)];
    return (
      _roundId,
      transmission.answer,
      transmission.observationsTimestamp,
      transmission.transmissionTimestamp,
      _roundId
    );
  }

  /**
   * @notice aggregator details for the most recently transmitted report
   * @return roundId aggregator round of latest report
   * @return answer of latest report
   * @return startedAt offchain timestamp of block containing latest report
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
        // memory operation for safe gas
    uint32 latestAggregatorRoundId = s_hotVars.latestAggregatorRoundId;
        // memory operation for safe gas
    Transmission memory transmission = s_transmissions[latestAggregatorRoundId];
    return (
      latestAggregatorRoundId,
      transmission.answer,
      transmission.observationsTimestamp,
      transmission.transmissionTimestamp,
      latestAggregatorRoundId
    );
  }
}

// SPDX-License-Identifier: MIT
// https://github.com/smartcontractkit/libocr/blob/d12971936c1289ae0d512723a9e8535ce382ff6d/contract/AggregatorV2V3Interface.sol
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface
{
}

// SPDX-License-Identifier: MIT
// https://github.com/smartcontractkit/libocr/blob/d12971936c1289ae0d512723a9e8535ce382ff6d/contract/TypeAndVersionInterface.sol
pragma solidity ^0.8.0;

abstract contract TypeAndVersionInterface{
  function typeAndVersion()
    external
    pure
    virtual
    returns (string memory);
}

// SPDX-License-Identifier: MIT
// https://github.com/smartcontractkit/libocr/blob/d12971936c1289ae0d512723a9e8535ce382ff6d/contract/AggregatorInterface.sol
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);
//  function latestAnswerValory() external view returns (uint256);
//  function getAnswerValory(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
// https://github.com/smartcontractkit/libocr/blob/d12971936c1289ae0d512723a9e8535ce382ff6d/contract/AggregatorV3Interface.sol
pragma solidity ^0.8.0;

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