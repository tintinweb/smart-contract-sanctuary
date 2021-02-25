// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

import "./OffchainAggregator.sol";
import "./SimpleReadAccessController.sol";

/**
 * @notice Wrapper of OffchainAggregator which checks read access on Aggregator-interface methods
 */
contract AccessControlledOffchainAggregator is OffchainAggregator, SimpleReadAccessController {

  constructor(
    uint32 _maximumGasPrice,
    uint32 _reasonableGasPrice,
    uint32 _microLinkPerEth,
    uint32 _linkGweiPerObservation,
    uint32 _linkGweiPerTransmission,
    address _link,
    address _validator,
    int192 _minAnswer,
    int192 _maxAnswer,
    AccessControllerInterface _billingAccessController,
    AccessControllerInterface _requesterAccessController,
    uint8 _decimals,
    string memory description
  )
    OffchainAggregator(
      _maximumGasPrice,
      _reasonableGasPrice,
      _microLinkPerEth,
      _linkGweiPerObservation,
      _linkGweiPerTransmission,
      _link,
      _validator,
      _minAnswer,
      _maxAnswer,
      _billingAccessController,
      _requesterAccessController,
      _decimals,
      description
    ) {
    }

  /*
   * v2 Aggregator interface
   */

  /// @inheritdoc OffchainAggregator
  function latestAnswer()
    public
    override
    view
    checkAccess()
    returns (int256)
  {
    return super.latestAnswer();
  }

  /// @inheritdoc OffchainAggregator
  function latestTimestamp()
    public
    override
    view
    checkAccess()
    returns (uint256)
  {
    return super.latestTimestamp();
  }

  /// @inheritdoc OffchainAggregator
  function latestRound()
    public
    override
    view
    checkAccess()
    returns (uint256)
  {
    return super.latestRound();
  }

  /// @inheritdoc OffchainAggregator
  function getAnswer(uint256 _roundId)
    public
    override
    view
    checkAccess()
    returns (int256)
  {
    return super.getAnswer(_roundId);
  }

  /// @inheritdoc OffchainAggregator
  function getTimestamp(uint256 _roundId)
    public
    override
    view
    checkAccess()
    returns (uint256)
  {
    return super.getTimestamp(_roundId);
  }

  /*
   * v3 Aggregator interface
   */

  /// @inheritdoc OffchainAggregator
  function description()
    public
    override
    view
    checkAccess()
    returns (string memory)
  {
    return super.description();
  }

  /// @inheritdoc OffchainAggregator
  function getRoundData(uint80 _roundId)
    public
    override
    view
    checkAccess()
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

  /// @inheritdoc OffchainAggregator
  function latestRoundData()
    public
    override
    view
    checkAccess()
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

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./AccessControllerInterface.sol";
import "./AggregatorV2V3Interface.sol";
import "./AggregatorValidatorInterface.sol";
import "./LinkTokenInterface.sol";
import "./Owned.sol";
import "./OffchainAggregatorBilling.sol";

/**
  * @notice Onchain verification of reports from the offchain reporting protocol

  * @dev For details on its operation, see the offchain reporting protocol design
  * @dev doc, which refers to this contract as simply the "contract".
*/
contract OffchainAggregator is Owned, OffchainAggregatorBilling, AggregatorV2V3Interface {

  uint256 constant private maxUint32 = (1 << 32) - 1;

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

  // incremented each time a new config is posted. This count is incorporated
  // into the config digest, to prevent replay attacks.
  uint32 internal s_configCount;
  uint32 internal s_latestConfigBlockNumber; // makes it easier for offchain systems
                                             // to extract config from logs.

  // Lowest answer the system is allowed to report in response to transmissions
  int192 immutable public minAnswer;
  // Highest answer the system is allowed to report in response to transmissions
  int192 immutable public maxAnswer;

  /*
   * @param _maximumGasPrice highest gas price for which transmitter will be compensated
   * @param _reasonableGasPrice transmitter will receive reward for gas prices under this value
   * @param _microLinkPerEth reimbursement per ETH of gas cost, in 1e-6LINK units
   * @param _linkGweiPerObservation reward to oracle for contributing an observation to a successfully transmitted report, in 1e-9LINK units
   * @param _linkGweiPerTransmission reward to transmitter of a successful report, in 1e-9LINK units
   * @param _link address of the LINK contract
   * @param _validator address of validator contract (must satisfy AggregatorValidatorInterface)
   * @param _minAnswer lowest answer the median of a report is allowed to be
   * @param _maxAnswer highest answer the median of a report is allowed to be
   * @param _billingAccessController access controller for billing admin functions
   * @param _requesterAccessController access controller for requesting new rounds
   * @param _decimals answers are stored in fixed-point format, with this many digits of precision
   * @param _description short human-readable description of observable this contract's answers pertain to
   */
  constructor(
    uint32 _maximumGasPrice,
    uint32 _reasonableGasPrice,
    uint32 _microLinkPerEth,
    uint32 _linkGweiPerObservation,
    uint32 _linkGweiPerTransmission,
    address _link,
    address _validator,
    int192 _minAnswer,
    int192 _maxAnswer,
    AccessControllerInterface _billingAccessController,
    AccessControllerInterface _requesterAccessController,
    uint8 _decimals,
    string memory _description
  )
    OffchainAggregatorBilling(_maximumGasPrice, _reasonableGasPrice, _microLinkPerEth,
      _linkGweiPerObservation, _linkGweiPerTransmission, _link,
      _billingAccessController
    )
  {
    decimals = _decimals;
    s_description = _description;
    setRequesterAccessController(_requesterAccessController);
    setValidator(_validator);
    minAnswer = _minAnswer;
    maxAnswer = _maxAnswer;
  }

  /*
   * Config logic
   */

  /**
   * @notice triggers a new run of the offchain reporting protocol
   * @param previousConfigBlockNumber block in which the previous config was set, to simplify historic analysis
   * @param configCount ordinal number of this config setting among all config settings over the life of this contract
   * @param signers ith element is address ith oracle uses to sign a report
   * @param transmitters ith element is address ith oracle uses to transmit a report via the transmit method
   * @param threshold maximum number of faulty/dishonest oracles the protocol can tolerate while still working correctly
   * @param encodedConfigVersion version of the serialization format used for "encoded" parameter
   * @param encoded serialized data used by oracles to configure their offchain operation
   */
  event ConfigSet(
    uint32 previousConfigBlockNumber,
    uint64 configCount,
    address[] signers,
    address[] transmitters,
    uint8 threshold,
    uint64 encodedConfigVersion,
    bytes encoded
  );

  // Reverts transaction if config args are invalid
  modifier checkConfigValid (
    uint256 _numSigners, uint256 _numTransmitters, uint256 _threshold
  ) {
    require(_numSigners <= maxNumOracles, "too many signers");
    require(_threshold > 0, "threshold must be positive");
    require(
      _numSigners == _numTransmitters,
      "oracle addresses out of registration"
    );
    require(_numSigners > 3*_threshold, "faulty-oracle threshold too high");
    _;
  }

  /**
   * @notice sets offchain reporting protocol configuration incl. participating oracles
   * @param _signers addresses with which oracles sign the reports
   * @param _transmitters addresses oracles use to transmit the reports
   * @param _threshold number of faulty oracles the system can tolerate
   * @param _encodedConfigVersion version number for offchainEncoding schema
   * @param _encoded encoded off-chain oracle configuration
   */
  function setConfig(
    address[] calldata _signers,
    address[] calldata _transmitters,
    uint8 _threshold,
    uint64 _encodedConfigVersion,
    bytes calldata _encoded
  )
    external
    checkConfigValid(_signers.length, _transmitters.length, _threshold)
    onlyOwner()
  {
    while (s_signers.length != 0) { // remove any old signer/transmitter addresses
      uint lastIdx = s_signers.length - 1;
      address signer = s_signers[lastIdx];
      address transmitter = s_transmitters[lastIdx];
      payOracle(transmitter);
      delete s_oracles[signer];
      delete s_oracles[transmitter];
      s_signers.pop();
      s_transmitters.pop();
    }

    for (uint i = 0; i < _signers.length; i++) { // add new signer/transmitter addresses
      require(
        s_oracles[_signers[i]].role == Role.Unset,
        "repeated signer address"
      );
      s_oracles[_signers[i]] = Oracle(uint8(i), Role.Signer);
      require(s_payees[_transmitters[i]] != address(0), "payee must be set");
      require(
        s_oracles[_transmitters[i]].role == Role.Unset,
        "repeated transmitter address"
      );
      s_oracles[_transmitters[i]] = Oracle(uint8(i), Role.Transmitter);
      s_signers.push(_signers[i]);
      s_transmitters.push(_transmitters[i]);
    }
    s_hotVars.threshold = _threshold;
    uint32 previousConfigBlockNumber = s_latestConfigBlockNumber;
    s_latestConfigBlockNumber = uint32(block.number);
    s_configCount += 1;
    uint64 configCount = s_configCount;
    {
      s_hotVars.latestConfigDigest = configDigestFromConfigData(
        address(this),
        configCount,
        _signers,
        _transmitters,
        _threshold,
        _encodedConfigVersion,
        _encoded
      );
      s_hotVars.latestEpochAndRound = 0;
    }
    emit ConfigSet(
      previousConfigBlockNumber,
      configCount,
      _signers,
      _transmitters,
      _threshold,
      _encodedConfigVersion,
      _encoded
    );
  }

  function configDigestFromConfigData(
    address _contractAddress,
    uint64 _configCount,
    address[] calldata _signers,
    address[] calldata _transmitters,
    uint8 _threshold,
    uint64 _encodedConfigVersion,
    bytes calldata _encodedConfig
  ) internal pure returns (bytes16) {
    return bytes16(keccak256(abi.encode(_contractAddress, _configCount,
      _signers, _transmitters, _threshold, _encodedConfigVersion, _encodedConfig
    )));
  }

  /**
   * @notice information about current offchain reporting protocol configuration

   * @return configCount ordinal number of current config, out of all configs applied to this contract so far
   * @return blockNumber block at which this config was set
   * @return configDigest domain-separation tag for current config (see configDigestFromConfigData)
   */
  function latestConfigDetails()
    external
    view
    returns (
      uint32 configCount,
      uint32 blockNumber,
      bytes16 configDigest
    )
  {
    return (s_configCount, s_latestConfigBlockNumber, s_hotVars.latestConfigDigest);
  }

  /**
   * @return list of addresses permitted to transmit reports to this contract

   * @dev The list will match the order used to specify the transmitter during setConfig
   */
  function transmitters()
    external
    view
    returns(address[] memory)
  {
      return s_transmitters;
  }

  /*
   * On-chain validation logc
   */

  // Maximum gas the validation logic can use
  uint256 private constant VALIDATOR_GAS_LIMIT = 100000;

  // Contract containing the validation logic
  AggregatorValidatorInterface private s_validator;

  /**
   * @notice indicates that the address of the validator contract has been set
   * @param previous setting of the address prior to this event
   * @param current the new value for the address
   */
  event ValidatorUpdated(
    address indexed previous,
    address indexed current
  );

  /**
   * @notice address of the contract which does external data validation
   * @return validator address
   */
  function validator()
    external
    view
    returns (AggregatorValidatorInterface)
  {
    return s_validator;
  }

  /**
   * @notice sets the address which does external data validation
   * @param _newValidator designates the address of the new validation contract
   */
  function setValidator(address _newValidator)
    public
    onlyOwner()
  {
    address previous = address(s_validator);

    if (previous != _newValidator) {
      s_validator = AggregatorValidatorInterface(_newValidator);

      emit ValidatorUpdated(previous, _newValidator);
    }
  }

  function validateAnswer(
    uint32 _aggregatorRoundId,
    int256 _answer
  )
    private
  {
    AggregatorValidatorInterface av = s_validator; // cache storage reads
    if (address(av) == address(0)) return;

    uint32 prevAggregatorRoundId = _aggregatorRoundId - 1;
    int256 prevAggregatorRoundAnswer = s_transmissions[prevAggregatorRoundId].answer;
    // We do not want the validator to ever prevent reporting, so we limit its
    // gas usage and catch any errors that may arise.
    try av.validate{gas: VALIDATOR_GAS_LIMIT}(
      prevAggregatorRoundId,
      prevAggregatorRoundAnswer,
      _aggregatorRoundId,
      _answer
    ) {} catch {}
  }

  /*
   * requestNewRound logic
   */

  AccessControllerInterface internal s_requesterAccessController;

  /**
   * @notice emitted when a new requester access controller contract is set
   * @param old the address prior to the current setting
   * @param current the address of the new access controller contract
   */
  event RequesterAccessControllerSet(AccessControllerInterface old, AccessControllerInterface current);

  /**
   * @notice emitted to immediately request a new round
   * @param requester the address of the requester
   * @param configDigest the latest transmission's configDigest
   * @param epoch the latest transmission's epoch
   * @param round the latest transmission's round
   */
  event RoundRequested(address indexed requester, bytes16 configDigest, uint32 epoch, uint8 round);

  /**
   * @notice address of the requester access controller contract
   * @return requester access controller address
   */
  function requesterAccessController()
    external
    view
    returns (AccessControllerInterface)
  {
    return s_requesterAccessController;
  }

  /**
   * @notice sets the requester access controller
   * @param _requesterAccessController designates the address of the new requester access controller
   */
  function setRequesterAccessController(AccessControllerInterface _requesterAccessController)
    public
    onlyOwner()
  {
    AccessControllerInterface oldController = s_requesterAccessController;
    if (_requesterAccessController != oldController) {
      s_requesterAccessController = AccessControllerInterface(_requesterAccessController);
      emit RequesterAccessControllerSet(oldController, _requesterAccessController);
    }
  }

  /**
   * @notice immediately requests a new round
   * @return the aggregatorRoundId of the next round. Note: The report for this round may have been
   * transmitted (but not yet mined) *before* requestNewRound() was even called. There is *no*
   * guarantee of causality between the request and the report at aggregatorRoundId.
   */
  function requestNewRound() external returns (uint80) {
    require(msg.sender == owner || s_requesterAccessController.hasAccess(msg.sender, msg.data),
      "Only owner&requester can call");

    HotVars memory hotVars = s_hotVars;

    emit RoundRequested(
      msg.sender,
      hotVars.latestConfigDigest,
      uint32(s_hotVars.latestEpochAndRound >> 8),
      uint8(s_hotVars.latestEpochAndRound)
    );
    return hotVars.latestAggregatorRoundId + 1;
  }

  /*
   * Transmission logic
   */

  /**
   * @notice indicates that a new report was transmitted
   * @param aggregatorRoundId the round to which this report was assigned
   * @param answer median of the observations attached this report
   * @param transmitter address from which the report was transmitted
   * @param observations observations transmitted with this report
   * @param rawReportContext signature-replay-prevention domain-separation tag
   */
  event NewTransmission(
    uint32 indexed aggregatorRoundId,
    int192 answer,
    address transmitter,
    int192[] observations,
    bytes observers,
    bytes32 rawReportContext
  );

  // decodeReport is used to check that the solidity and go code are using the
  // same format. See TestOffchainAggregator.testDecodeReport and TestReportParsing
  function decodeReport(bytes memory _report)
    internal
    pure
    returns (
      bytes32 rawReportContext,
      bytes32 rawObservers,
      int192[] memory observations
    )
  {
    (rawReportContext, rawObservers, observations) = abi.decode(_report,
      (bytes32, bytes32, int192[]));
  }

  // Used to relieve stack pressure in transmit
  struct ReportData {
    HotVars hotVars; // Only read from storage once
    bytes observers; // ith element is the index of the ith observer
    int192[] observations; // ith element is the ith observation
    bytes vs; // jth element is the v component of the jth signature
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
    32 + // word containing location start of abiencoded  _rs value
    32 + // word containing start location of abiencoded _ss value
    32 + // _rawVs value
    32 + // word containing length of _report
    32 + // word containing length _rs
    32 + // word containing length of _ss
    0; // placeholder

  function expectedMsgDataLength(
    bytes calldata _report, bytes32[] calldata _rs, bytes32[] calldata _ss
  ) private pure returns (uint256 length)
  {
    // calldata will never be big enough to make this overflow
    return uint256(TRANSMIT_MSGDATA_CONSTANT_LENGTH_COMPONENT) +
      _report.length + // one byte pure entry in _report
      _rs.length * 32 + // 32 bytes per entry in _rs
      _ss.length * 32 + // 32 bytes per entry in _ss
      0; // placeholder
  }

  /**
   * @notice transmit is called to post a new report to the contract
   * @param _report serialized report, which the signatures are signing. See parsing code below for format. The ith element of the observers component must be the index in s_signers of the address for the ith signature
   * @param _rs ith element is the R components of the ith signature on report. Must have at most maxNumOracles entries
   * @param _ss ith element is the S components of the ith signature on report. Must have at most maxNumOracles entries
   * @param _rawVs ith element is the the V component of the ith signature
   */
  function transmit(
    // NOTE: If these parameters are changed, expectedMsgDataLength and/or
    // TRANSMIT_MSGDATA_CONSTANT_LENGTH_COMPONENT need to be changed accordingly
    bytes calldata _report,
    bytes32[] calldata _rs, bytes32[] calldata _ss, bytes32 _rawVs // signatures
  )
    external
  {
    uint256 initialGas = gasleft(); // This line must come first
    // Make sure the transmit message-length matches the inputs. Otherwise, the
    // transmitter could append an arbitrarily long (up to gas-block limit)
    // string of 0 bytes, which we would reimburse at a rate of 16 gas/byte, but
    // which would only cost the transmitter 4 gas/byte. (Appendix G of the
    // yellow paper, p. 25, for G_txdatazero and EIP 2028 for G_txdatanonzero.)
    // This could amount to reimbursement profit of 36 million gas, given a 3MB
    // zero tail.
    require(msg.data.length == expectedMsgDataLength(_report, _rs, _ss),
      "transmit message too long");
    ReportData memory r; // Relieves stack pressure
    {
      r.hotVars = s_hotVars; // cache read from storage

      bytes32 rawObservers;
      (r.rawReportContext, rawObservers, r.observations) = abi.decode(
        _report, (bytes32, bytes32, int192[])
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

      require(_rs.length > r.hotVars.threshold, "not enough signatures");
      require(_rs.length <= maxNumOracles, "too many signatures");
      require(_ss.length == _rs.length, "signatures out of registration");
      require(r.observations.length <= maxNumOracles,
              "num observations out of bounds");
      require(r.observations.length > 2 * r.hotVars.threshold,
              "too few values to trust median");

      // Copy signature parities in bytes32 _rawVs to bytes r.v
      r.vs = new bytes(_rs.length);
      for (uint8 i = 0; i < _rs.length; i++) {
        r.vs[i] = _rawVs[i];
      }

      // Copy observer identities in bytes32 rawObservers to bytes r.observers
      r.observers = new bytes(r.observations.length);
      bool[maxNumOracles] memory seen;
      for (uint8 i = 0; i < r.observations.length; i++) {
        uint8 observerIdx = uint8(rawObservers[i]);
        require(!seen[observerIdx], "observer index repeated");
        seen[observerIdx] = true;
        r.observers[i] = rawObservers[i];
      }

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

    { // Verify signatures attached to report
      bytes32 h = keccak256(_report);
      bool[maxNumOracles] memory signed;

      Oracle memory o;
      for (uint i = 0; i < _rs.length; i++) {
        address signer = ecrecover(h, uint8(r.vs[i])+27, _rs[i], _ss[i]);
        o = s_oracles[signer];
        require(o.role == Role.Signer, "address not authorized to sign");
        require(!signed[o.index], "non-unique signature");
        signed[o.index] = true;
      }
    }

    { // Check the report contents, and record the result
      for (uint i = 0; i < r.observations.length - 1; i++) {
        bool inOrder = r.observations[i] <= r.observations[i+1];
        require(inOrder, "observations not sorted");
      }

      int192 median = r.observations[r.observations.length/2];
      require(minAnswer <= median && median <= maxAnswer, "median is out of min-max range");
      r.hotVars.latestAggregatorRoundId++;
      s_transmissions[r.hotVars.latestAggregatorRoundId] =
        Transmission(median, uint64(block.timestamp));

      emit NewTransmission(
        r.hotVars.latestAggregatorRoundId,
        median,
        msg.sender,
        r.observations,
        r.observers,
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
        median,
        r.hotVars.latestAggregatorRoundId,
        block.timestamp
      );

      validateAnswer(r.hotVars.latestAggregatorRoundId, median);
    }
    s_hotVars = r.hotVars;
    assert(initialGas < maxUint32);
    reimburseAndRewardOracles(uint32(initialGas), r.observers);
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
pragma solidity ^0.7.0;

interface AccessControllerInterface {
  function hasAccess(address user, bytes calldata data) external view returns (bool);
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
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface AggregatorValidatorInterface {
  function validate(
    uint256 previousRoundId,
    int256 previousAnswer,
    uint256 currentRoundId,
    int256 currentAnswer
  ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external view returns (uint256 balance);
  function decimals() external view returns (uint8 decimalPlaces);
  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
  function increaseApproval(address spender, uint256 subtractedValue) external;
  function name() external view returns (string memory tokenName);
  function symbol() external view returns (string memory tokenSymbol);
  function totalSupply() external view returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/**
 * @title The Owned contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract Owned {

  address payable public owner;
  address private pendingOwner;

  event OwnershipTransferRequested(
    address indexed from,
    address indexed to
  );
  event OwnershipTransferred(
    address indexed from,
    address indexed to
  );

  constructor() {
    owner = msg.sender;
  }

  /**
   * @dev Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address _to)
    external
    onlyOwner()
  {
    pendingOwner = _to;

    emit OwnershipTransferRequested(owner, _to);
  }

  /**
   * @dev Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership()
    external
  {
    require(msg.sender == pendingOwner, "Must be proposed owner");

    address oldOwner = owner;
    owner = msg.sender;
    pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @dev Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner, "Only callable by owner");
    _;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./AccessControllerInterface.sol";
import "./LinkTokenInterface.sol";
import "./Owned.sol";

/**
 * @notice tracks administration of oracle-reward and gas-reimbursement parameters.

 * @dev
 * If you read or change this, be sure to read or adjust the comments. They
 * track the units of the values under consideration, and are crucial to
 * the readability of the operations it specifies.

 * @notice
 * Trust Model:

 * Nothing in this contract prevents a billing admin from setting insane
 * values for the billing parameters in setBilling. Oracles
 * participating in this contract should regularly check that the
 * parameters make sense. Similarly, the outstanding obligations of this
 * contract to the oracles can exceed the funds held by the contract.
 * Oracles participating in this contract should regularly check that it
 * holds sufficient funds and stop interacting with it if funding runs
 * out.

 * This still leaves oracles with some risk due to TOCTOU issues.
 * However, since the sums involved are pretty small (Ethereum
 * transactions aren't that expensive in the end) and an oracle would
 * likely stop participating in a contract it repeatedly lost money on,
 * this risk is deemed acceptable. Oracles should also regularly
 * withdraw any funds in the contract to prevent issues where the
 * contract becomes underfunded at a later time, and different oracles
 * are competing for the left-over funds.

 * Finally, note that any change to the set of oracles or to the billing
 * parameters will trigger payout of all oracles first (using the old
 * parameters), a billing admin cannot take away funds that are already
 * marked for payment.
*/
contract OffchainAggregatorBilling is Owned {

  // Maximum number of oracles the offchain reporting protocol is designed for
  uint256 constant internal maxNumOracles = 31;

  // Parameters for oracle payments
  struct Billing {

    // Highest compensated gas price, in ETH-gwei uints
    uint32 maximumGasPrice;

    // If gas price is less (in ETH-gwei units), transmitter gets half the savings
    uint32 reasonableGasPrice;

    // Pay transmitter back this much LINK per unit eth spent on gas
    // (1e-6LINK/ETH units)
    uint32 microLinkPerEth;

    // Fixed LINK reward for each observer, in LINK-gwei units
    uint32 linkGweiPerObservation;

    // Fixed reward for transmitter, in linkGweiPerObservation units
    uint32 linkGweiPerTransmission;
  }
  Billing internal s_billing;

  /**
  * @return LINK token contract used for billing
  */
  LinkTokenInterface immutable public LINK;

  AccessControllerInterface internal s_billingAccessController;

  // ith element is number of observation rewards due to ith process, plus one.
  // This is expected to saturate after an oracle has submitted 65,535
  // observations, or about 65535/(3*24*20) = 45 days, given a transmission
  // every 3 minutes.
  //
  // This is always one greater than the actual value, so that when the value is
  // reset to zero, we don't end up with a zero value in storage (which would
  // result in a higher gas cost, the next time the value is incremented.)
  // Calculations using this variable need to take that offset into account.
  uint16[maxNumOracles] internal s_oracleObservationsCounts;

  // Addresses at which oracles want to receive payments, by transmitter address
  mapping (address /* transmitter */ => address /* payment address */)
    internal
    s_payees;

  // Payee addresses which must be approved by the owner
  mapping (address /* transmitter */ => address /* payment address */)
    internal
    s_proposedPayees;

  // LINK-wei-denominated reimbursements for gas used by transmitters.
  //
  // This is always one greater than the actual value, so that when the value is
  // reset to zero, we don't end up with a zero value in storage (which would
  // result in a higher gas cost, the next time the value is incremented.)
  // Calculations using this variable need to take that offset into account.
  //
  // Argument for overflow safety:
  // We have the following maximum intermediate values:
  // - 2**40 additions to this variable (epochAndRound is a uint40)
  // - 2**32 gas price in ethgwei/gas
  // - 1e9 ethwei/ethgwei
  // - 2**32 gas since the block gas limit is at ~20 million
  // - 2**32 (microlink/eth)
  // And we have 2**40 * 2**32 * 1e9 * 2**32 * 2**32 < 2**166
  // (we also divide in some places, but that only makes the value smaller)
  // We can thus safely use uint256 intermediate values for the computation
  // updating this variable.
  uint256[maxNumOracles] internal s_gasReimbursementsLinkWei;

  // Used for s_oracles[a].role, where a is an address, to track the purpose
  // of the address, or to indicate that the address is unset.
  enum Role {
    // No oracle role has been set for address a
    Unset,
    // Signing address for the s_oracles[a].index'th oracle. I.e., report
    // signatures from this oracle should ecrecover back to address a.
    Signer,
    // Transmission address for the s_oracles[a].index'th oracle. I.e., if a
    // report is received by OffchainAggregator.transmit in which msg.sender is
    // a, it is attributed to the s_oracles[a].index'th oracle.
    Transmitter
  }

  struct Oracle {
    uint8 index; // Index of oracle in s_signers/s_transmitters
    Role role;   // Role of the address which mapped to this struct
  }

  mapping (address /* signer OR transmitter address */ => Oracle)
    internal s_oracles;

  // s_signers contains the signing address of each oracle
  address[] internal s_signers;

  // s_transmitters contains the transmission address of each oracle,
  // i.e. the address the oracle actually sends transactions to the contract from
  address[] internal s_transmitters;

  uint256 constant private  maxUint16 = (1 << 16) - 1;
  uint256 constant internal maxUint128 = (1 << 128) - 1;

  constructor(
    uint32 _maximumGasPrice,
    uint32 _reasonableGasPrice,
    uint32 _microLinkPerEth,
    uint32 _linkGweiPerObservation,
    uint32 _linkGweiPerTransmission,
    address _link,
    AccessControllerInterface _billingAccessController
  )
  {
    setBillingInternal(_maximumGasPrice, _reasonableGasPrice, _microLinkPerEth,
      _linkGweiPerObservation, _linkGweiPerTransmission);
    setBillingAccessControllerInternal(_billingAccessController);
    LINK = LinkTokenInterface(_link);
    uint16[maxNumOracles] memory counts; // See s_oracleObservationsCounts docstring
    uint256[maxNumOracles] memory gas; // see s_gasReimbursementsLinkWei docstring
    for (uint8 i = 0; i < maxNumOracles; i++) {
      counts[i] = 1;
      gas[i] = 1;
    }
    s_oracleObservationsCounts = counts;
    s_gasReimbursementsLinkWei = gas;

  }

  /**
   * @notice emitted when billing parameters are set
   * @param maximumGasPrice highest gas price for which transmitter will be compensated
   * @param reasonableGasPrice transmitter will receive reward for gas prices under this value
   * @param microLinkPerEth reimbursement per ETH of gas cost, in 1e-6LINK units
   * @param linkGweiPerObservation reward to oracle for contributing an observation to a successfully transmitted report, in 1e-9LINK units
   * @param linkGweiPerTransmission reward to transmitter of a successful report, in 1e-9LINK units
   */
  event BillingSet(
    uint32 maximumGasPrice,
    uint32 reasonableGasPrice,
    uint32 microLinkPerEth,
    uint32 linkGweiPerObservation,
    uint32 linkGweiPerTransmission
  );

  function setBillingInternal(
    uint32 _maximumGasPrice,
    uint32 _reasonableGasPrice,
    uint32 _microLinkPerEth,
    uint32 _linkGweiPerObservation,
    uint32 _linkGweiPerTransmission
  )
    internal
  {
    s_billing = Billing(_maximumGasPrice, _reasonableGasPrice, _microLinkPerEth,
      _linkGweiPerObservation, _linkGweiPerTransmission);
    emit BillingSet(_maximumGasPrice, _reasonableGasPrice, _microLinkPerEth,
      _linkGweiPerObservation, _linkGweiPerTransmission);
  }

  /**
   * @notice sets billing parameters
   * @param _maximumGasPrice highest gas price for which transmitter will be compensated
   * @param _reasonableGasPrice transmitter will receive reward for gas prices under this value
   * @param _microLinkPerEth reimbursement per ETH of gas cost, in 1e-6LINK units
   * @param _linkGweiPerObservation reward to oracle for contributing an observation to a successfully transmitted report, in 1e-9LINK units
   * @param _linkGweiPerTransmission reward to transmitter of a successful report, in 1e-9LINK units
   * @dev access control provided by billingAccessController
   */
  function setBilling(
    uint32 _maximumGasPrice,
    uint32 _reasonableGasPrice,
    uint32 _microLinkPerEth,
    uint32 _linkGweiPerObservation,
    uint32 _linkGweiPerTransmission
  )
    external
  {
    AccessControllerInterface access = s_billingAccessController;
    require(msg.sender == owner || access.hasAccess(msg.sender, msg.data),
      "Only owner&billingAdmin can call");
    payOracles();
    setBillingInternal(_maximumGasPrice, _reasonableGasPrice, _microLinkPerEth,
      _linkGweiPerObservation, _linkGweiPerTransmission);
  }

  /**
   * @notice gets billing parameters
   * @param maximumGasPrice highest gas price for which transmitter will be compensated
   * @param reasonableGasPrice transmitter will receive reward for gas prices under this value
   * @param microLinkPerEth reimbursement per ETH of gas cost, in 1e-6LINK units
   * @param linkGweiPerObservation reward to oracle for contributing an observation to a successfully transmitted report, in 1e-9LINK units
   * @param linkGweiPerTransmission reward to transmitter of a successful report, in 1e-9LINK units
   */
  function getBilling()
    external
    view
    returns (
      uint32 maximumGasPrice,
      uint32 reasonableGasPrice,
      uint32 microLinkPerEth,
      uint32 linkGweiPerObservation,
      uint32 linkGweiPerTransmission
    )
  {
    Billing memory billing = s_billing;
    return (
      billing.maximumGasPrice,
      billing.reasonableGasPrice,
      billing.microLinkPerEth,
      billing.linkGweiPerObservation,
      billing.linkGweiPerTransmission
    );
  }

  /**
   * @notice emitted when a new access-control contract is set
   * @param old the address prior to the current setting
   * @param current the address of the new access-control contract
   */
  event BillingAccessControllerSet(AccessControllerInterface old, AccessControllerInterface current);

  function setBillingAccessControllerInternal(AccessControllerInterface _billingAccessController)
    internal
  {
    AccessControllerInterface oldController = s_billingAccessController;
    if (_billingAccessController != oldController) {
      s_billingAccessController = _billingAccessController;
      emit BillingAccessControllerSet(
        oldController,
        _billingAccessController
      );
    }
  }

  /**
   * @notice sets billingAccessController
   * @param _billingAccessController new billingAccessController contract address
   * @dev only owner can call this
   */
  function setBillingAccessController(AccessControllerInterface _billingAccessController)
    external
    onlyOwner
  {
    setBillingAccessControllerInternal(_billingAccessController);
  }

  /**
   * @notice gets billingAccessController
   * @return address of billingAccessController contract
   */
  function billingAccessController()
    external
    view
    returns (AccessControllerInterface)
  {
    return s_billingAccessController;
  }

  /**
   * @notice withdraws an oracle's payment from the contract
   * @param _transmitter the transmitter address of the oracle
   * @dev must be called by oracle's payee address
   */
  function withdrawPayment(address _transmitter)
    external
  {
    require(msg.sender == s_payees[_transmitter], "Only payee can withdraw");
    payOracle(_transmitter);
  }

  /**
   * @notice query an oracle's payment amount
   * @param _transmitter the transmitter address of the oracle
   */
  function owedPayment(address _transmitter)
    public
    view
    returns (uint256)
  {
    Oracle memory oracle = s_oracles[_transmitter];
    if (oracle.role == Role.Unset) { return 0; }
    Billing memory billing = s_billing;
    uint256 linkWeiAmount =
      uint256(s_oracleObservationsCounts[oracle.index] - 1) *
      uint256(billing.linkGweiPerObservation) *
      (1 gwei);
    linkWeiAmount += s_gasReimbursementsLinkWei[oracle.index] - 1;
    return linkWeiAmount;
  }

  /**
   * @notice emitted when an oracle has been paid LINK
   * @param transmitter address from which the oracle sends reports to the transmit method
   * @param payee address to which the payment is sent
   * @param amount amount of LINK sent
   */
  event OraclePaid(address transmitter, address payee, uint256 amount);

  // payOracle pays out _transmitter's balance to the corresponding payee, and zeros it out
  function payOracle(address _transmitter)
    internal
  {
    Oracle memory oracle = s_oracles[_transmitter];
    uint256 linkWeiAmount = owedPayment(_transmitter);
    if (linkWeiAmount > 0) {
      address payee = s_payees[_transmitter];
      // Poses no re-entrancy issues, because LINK.transfer does not yield
      // control flow.
      require(LINK.transfer(payee, linkWeiAmount), "insufficient funds");
      s_oracleObservationsCounts[oracle.index] = 1; // "zero" the counts. see var's docstring
      s_gasReimbursementsLinkWei[oracle.index] = 1; // "zero" the counts. see var's docstring
      emit OraclePaid(_transmitter, payee, linkWeiAmount);
    }
  }

  // payOracles pays out all transmitters, and zeros out their balances.
  //
  // It's much more gas-efficient to do this as a single operation, to avoid
  // hitting storage too much.
  function payOracles()
    internal
  {
    Billing memory billing = s_billing;
    uint16[maxNumOracles] memory observationsCounts = s_oracleObservationsCounts;
    uint256[maxNumOracles] memory gasReimbursementsLinkWei =
      s_gasReimbursementsLinkWei;
    address[] memory transmitters = s_transmitters;
    for (uint transmitteridx = 0; transmitteridx < transmitters.length; transmitteridx++) {
      uint256 reimbursementAmountLinkWei = gasReimbursementsLinkWei[transmitteridx] - 1;
      uint256 obsCount = observationsCounts[transmitteridx] - 1;
      uint256 linkWeiAmount =
        obsCount * uint256(billing.linkGweiPerObservation) * (1 gwei) + reimbursementAmountLinkWei;
      if (linkWeiAmount > 0) {
          address payee = s_payees[transmitters[transmitteridx]];
          // Poses no re-entrancy issues, because LINK.transfer does not yield
          // control flow.
          require(LINK.transfer(payee, linkWeiAmount), "insufficient funds");
          observationsCounts[transmitteridx] = 1;       // "zero" the counts.
          gasReimbursementsLinkWei[transmitteridx] = 1; // "zero" the counts.
          emit OraclePaid(transmitters[transmitteridx], payee, linkWeiAmount);
        }
    }
    // "Zero" the accounting storage variables
    s_oracleObservationsCounts = observationsCounts;
    s_gasReimbursementsLinkWei = gasReimbursementsLinkWei;
  }

  function oracleRewards(
    bytes memory observers,
    uint16[maxNumOracles] memory observations
  )
    internal
    pure
    returns (uint16[maxNumOracles] memory)
  {
    // reward each observer-participant with the observer reward
    for (uint obsIdx = 0; obsIdx < observers.length; obsIdx++) {
      uint8 observer = uint8(observers[obsIdx]);
      observations[observer] = saturatingAddUint16(observations[observer], 1);
    }
    return observations;
  }

  // This value needs to change if maxNumOracles is increased, or the accounting
  // calculations at the bottom of reimburseAndRewardOracles change.
  //
  // To recalculate it, run the profiler as described in
  // ../../profile/README.md, and add up the gas-usage values reported for the
  // lines in reimburseAndRewardOracles following the "gasLeft = gasleft()"
  // line. E.g., you will see output like this:
  //
  //      7        uint256 gasLeft = gasleft();
  //     29        uint256 gasCostEthWei = transmitterGasCostEthWei(
  //      9          uint256(initialGas),
  //      3          gasPrice,
  //      3          callDataGasCost,
  //      3          gasLeft
  //      .
  //      .
  //      .
  //     59        uint256 gasCostLinkWei = (gasCostEthWei * billing.microLinkPerEth)/ 1e6;
  //      .
  //      .
  //      .
  //   5047        s_gasReimbursementsLinkWei[txOracle.index] =
  //    856          s_gasReimbursementsLinkWei[txOracle.index] + gasCostLinkWei +
  //     26          uint256(billing.linkGweiPerTransmission) * (1 gwei);
  //
  // If those were the only lines to be accounted for, you would add up
  // 29+9+3+3+3+59+5047+856+26=6035.
  uint256 internal constant accountingGasCost = 6035;

  // Uncomment the following declaration to compute the remaining gas cost after
  // above gasleft(). (This must exist in a base class to OffchainAggregator, so
  // it can't go in TestOffchainAggregator.)
  //
  // uint256 public gasUsedInAccounting;

  // Gas price at which the transmitter should be reimbursed, in ETH-gwei/gas
  function impliedGasPrice(
    uint256 txGasPrice,         // ETH-gwei/gas units
    uint256 reasonableGasPrice, // ETH-gwei/gas units
    uint256 maximumGasPrice     // ETH-gwei/gas units
  )
    internal
    pure
    returns (uint256)
  {
    // Reward the transmitter for choosing an efficient gas price: if they manage
    // to come in lower than considered reasonable, give them half the savings.
    //
    // The following calculations are all in units of gwei/gas, i.e. 1e-9ETH/gas
    uint256 gasPrice = txGasPrice;
    if (txGasPrice < reasonableGasPrice) {
      // Give transmitter half the savings for coming in under the reasonable gas price
      gasPrice += (reasonableGasPrice - txGasPrice) / 2;
    }
    // Don't reimburse a gas price higher than maximumGasPrice
    return min(gasPrice, maximumGasPrice);
  }

  // gas reimbursement due the transmitter, in ETH-wei
  //
  // If this function is changed, accountingGasCost needs to change, too. See
  // its docstring
  function transmitterGasCostEthWei(
    uint256 initialGas,
    uint256 gasPrice, // ETH-gwei/gas units
    uint256 callDataCost, // gas units
    uint256 gasLeft
  )
    internal
    pure
    returns (uint128 gasCostEthWei)
  {
    require(initialGas >= gasLeft, "gasLeft cannot exceed initialGas");
    uint256 gasUsed = // gas units
      initialGas - gasLeft + // observed gas usage
      callDataCost + accountingGasCost; // estimated gas usage
    // gasUsed is in gas units, gasPrice is in ETH-gwei/gas units; convert to ETH-wei
    uint256 fullGasCostEthWei = gasUsed * gasPrice * (1 gwei);
    assert(fullGasCostEthWei < maxUint128); // the entire ETH supply fits in a uint128...
    return uint128(fullGasCostEthWei);
  }

  /**
   * @notice withdraw any available funds left in the contract, up to _amount, after accounting for the funds due to participants in past reports
   * @param _recipient address to send funds to
   * @param _amount maximum amount to withdraw, denominated in LINK-wei.
   * @dev access control provided by billingAccessController
   */
  function withdrawFunds(address _recipient, uint256 _amount)
    external
  {
    require(msg.sender == owner || s_billingAccessController.hasAccess(msg.sender, msg.data),
      "Only owner&billingAdmin can call");
    uint256 linkDue = totalLINKDue();
    uint256 linkBalance = LINK.balanceOf(address(this));
    require(linkBalance >= linkDue, "insufficient balance");
    require(LINK.transfer(_recipient, min(linkBalance - linkDue, _amount)), "insufficient funds");
  }

  // Total LINK due to participants in past reports.
  function totalLINKDue()
    internal
    view
    returns (uint256 linkDue)
  {
    // Argument for overflow safety: We do all computations in
    // uint256s. The inputs to linkDue are:
    // - the <= 31 observation rewards each of which has less than
    //   64 bits (32 bits for billing.linkGweiPerObservation, 32 bits
    //   for wei/gwei conversion). Hence 69 bits are sufficient for this part.
    // - the <= 31 gas reimbursements, each of which consists of at most 166
    //   bits (see s_gasReimbursementsLinkWei docstring). Hence 171 bits are
    //   sufficient for this part
    // In total, 172 bits are enough.
    uint16[maxNumOracles] memory observationCounts = s_oracleObservationsCounts;
    for (uint i = 0; i < maxNumOracles; i++) {
      linkDue += observationCounts[i] - 1; // Stored value is one greater than actual value
    }
    Billing memory billing = s_billing;
    // Convert linkGweiPerObservation to uint256, or this overflows!
    linkDue *= uint256(billing.linkGweiPerObservation) * (1 gwei);
    address[] memory transmitters = s_transmitters;
    uint256[maxNumOracles] memory gasReimbursementsLinkWei =
      s_gasReimbursementsLinkWei;
    for (uint i = 0; i < transmitters.length; i++) {
      linkDue += uint256(gasReimbursementsLinkWei[i]-1); // Stored value is one greater than actual value
    }
  }

  /**
   * @notice allows oracles to check that sufficient LINK balance is available
   * @return availableBalance LINK available on this contract, after accounting for outstanding obligations. can become negative
   */
  function linkAvailableForPayment()
    external
    view
    returns (int256 availableBalance)
  {
    // there are at most one billion LINK, so this cast is safe
    int256 balance = int256(LINK.balanceOf(address(this)));
    // according to the argument in the definition of totalLINKDue,
    // totalLINKDue is never greater than 2**172, so this cast is safe
    int256 due = int256(totalLINKDue());
    // safe from overflow according to above sizes
    return int256(balance) - int256(due);
  }

  /**
   * @notice number of observations oracle is due to be reimbursed for
   * @param _signerOrTransmitter address used by oracle for signing or transmitting reports
   */
  function oracleObservationCount(address _signerOrTransmitter)
    external
    view
    returns (uint16)
  {
    Oracle memory oracle = s_oracles[_signerOrTransmitter];
    if (oracle.role == Role.Unset) { return 0; }
    return s_oracleObservationsCounts[oracle.index] - 1;
  }


  function reimburseAndRewardOracles(
    uint32 initialGas,
    bytes memory observers
  )
    internal
  {
    Oracle memory txOracle = s_oracles[msg.sender];
    Billing memory billing = s_billing;
    // Reward oracles for providing observations. Oracles are not rewarded
    // for providing signatures, because signing is essentially free.
    s_oracleObservationsCounts =
      oracleRewards(observers, s_oracleObservationsCounts);
    // Reimburse transmitter of the report for gas usage
    require(txOracle.role == Role.Transmitter,
      "sent by undesignated transmitter"
    );
    uint256 gasPrice = impliedGasPrice(
      tx.gasprice / (1 gwei), // convert to ETH-gwei units
      billing.reasonableGasPrice,
      billing.maximumGasPrice
    );
    // The following is only an upper bound, as it ignores the cheaper cost for
    // 0 bytes. Safe from overflow, because calldata just isn't that long.
    uint256 callDataGasCost = 16 * msg.data.length;
    // If any changes are made to subsequent calculations, accountingGasCost
    // needs to change, too.
    uint256 gasLeft = gasleft();
    uint256 gasCostEthWei = transmitterGasCostEthWei(
      uint256(initialGas),
      gasPrice,
      callDataGasCost,
      gasLeft
    );

    // microLinkPerEth is 1e-6LINK/ETH units, gasCostEthWei is 1e-18ETH units
    // (ETH-wei), product is 1e-24LINK-wei units, dividing by 1e6 gives
    // 1e-18LINK units, i.e. LINK-wei units
    // Safe from over/underflow, since all components are non-negative,
    // gasCostEthWei will always fit into uint128 and microLinkPerEth is a
    // uint32 (128+32 < 256!).
    uint256 gasCostLinkWei = (gasCostEthWei * billing.microLinkPerEth)/ 1e6;

    // Safe from overflow, because gasCostLinkWei < 2**160 and
    // billing.linkGweiPerTransmission * (1 gwei) < 2**64 and we increment
    // s_gasReimbursementsLinkWei[txOracle.index] at most 2**40 times.
    s_gasReimbursementsLinkWei[txOracle.index] =
      s_gasReimbursementsLinkWei[txOracle.index] + gasCostLinkWei +
      uint256(billing.linkGweiPerTransmission) * (1 gwei); // convert from linkGwei to linkWei

    // Uncomment next line to compute the remaining gas cost after above gasleft().
    // See OffchainAggregatorBilling.accountingGasCost docstring for more information.
    //
    // gasUsedInAccounting = gasLeft - gasleft();
  }

  /*
   * Payee management
   */

  /**
   * @notice emitted when a transfer of an oracle's payee address has been initiated
   * @param transmitter address from which the oracle sends reports to the transmit method
   * @param current the payeee address for the oracle, prior to this setting
   * @param proposed the proposed new payee address for the oracle
   */
  event PayeeshipTransferRequested(
    address indexed transmitter,
    address indexed current,
    address indexed proposed
  );

  /**
   * @notice emitted when a transfer of an oracle's payee address has been completed
   * @param transmitter address from which the oracle sends reports to the transmit method
   * @param current the payeee address for the oracle, prior to this setting
   */
  event PayeeshipTransferred(
    address indexed transmitter,
    address indexed previous,
    address indexed current
  );

  /**
   * @notice sets the payees for transmitting addresses
   * @param _transmitters addresses oracles use to transmit the reports
   * @param _payees addresses of payees corresponding to list of transmitters
   * @dev must be called by owner
   * @dev cannot be used to change payee addresses, only to initially populate them
   */
  function setPayees(
    address[] calldata _transmitters,
    address[] calldata _payees
  )
    external
    onlyOwner()
  {
    require(_transmitters.length == _payees.length, "transmitters.size != payees.size");

    for (uint i = 0; i < _transmitters.length; i++) {
      address transmitter = _transmitters[i];
      address payee = _payees[i];
      address currentPayee = s_payees[transmitter];
      bool zeroedOut = currentPayee == address(0);
      require(zeroedOut || currentPayee == payee, "payee already set");
      s_payees[transmitter] = payee;

      if (currentPayee != payee) {
        emit PayeeshipTransferred(transmitter, currentPayee, payee);
      }
    }
  }

  /**
   * @notice first step of payeeship transfer (safe transfer pattern)
   * @param _transmitter transmitter address of oracle whose payee is changing
   * @param _proposed new payee address
   * @dev can only be called by payee address
   */
  function transferPayeeship(
    address _transmitter,
    address _proposed
  )
    external
  {
      require(msg.sender == s_payees[_transmitter], "only current payee can update");
      require(msg.sender != _proposed, "cannot transfer to self");

      address previousProposed = s_proposedPayees[_transmitter];
      s_proposedPayees[_transmitter] = _proposed;

      if (previousProposed != _proposed) {
        emit PayeeshipTransferRequested(_transmitter, msg.sender, _proposed);
      }
  }

  /**
   * @notice second step of payeeship transfer (safe transfer pattern)
   * @param _transmitter transmitter address of oracle whose payee is changing
   * @dev can only be called by proposed new payee address
   */
  function acceptPayeeship(
    address _transmitter
  )
    external
  {
    require(msg.sender == s_proposedPayees[_transmitter], "only proposed payees can accept");

    address currentPayee = s_payees[_transmitter];
    s_payees[_transmitter] = msg.sender;
    s_proposedPayees[_transmitter] = address(0);

    emit PayeeshipTransferred(_transmitter, currentPayee, msg.sender);
  }

  /*
   * Helper functions
   */

  function saturatingAddUint16(uint16 _x, uint16 _y)
    internal
    pure
    returns (uint16)
  {
    return uint16(min(uint256(_x)+uint256(_y), maxUint16));
  }

  function min(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
  {
    if (a < b) { return a; }
    return b;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

import "./SimpleWriteAccessController.sol";

/**
 * @title SimpleReadAccessController
 * @notice Gives access to:
 * - any externally owned account (note that offchain actors can always read
 * any contract storage regardless of onchain access control measures, so this
 * does not weaken the access control while improving usability)
 * - accounts explicitly added to an access list
 * @dev SimpleReadAccessController is not suitable for access controlling writes
 * since it grants any externally owned account access! See
 * SimpleWriteAccessController for that.
 */
contract SimpleReadAccessController is SimpleWriteAccessController {

  /**
   * @notice Returns the access of an address
   * @param _user The address to query
   */
  function hasAccess(
    address _user,
    bytes memory _calldata
  )
    public
    view
    virtual
    override
    returns (bool)
  {
    return super.hasAccess(_user, _calldata) || _user == tx.origin;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./Owned.sol";
import "./AccessControllerInterface.sol";

/**
 * @title SimpleWriteAccessController
 * @notice Gives access to accounts explicitly added to an access list by the
 * controller's owner.
 * @dev does not make any special permissions for externally, see
 * SimpleReadAccessController for that.
 */
contract SimpleWriteAccessController is AccessControllerInterface, Owned {

  bool public checkEnabled;
  mapping(address => bool) internal accessList;

  event AddedAccess(address user);
  event RemovedAccess(address user);
  event CheckAccessEnabled();
  event CheckAccessDisabled();

  constructor()
  {
    checkEnabled = true;
  }

  /**
   * @notice Returns the access of an address
   * @param _user The address to query
   */
  function hasAccess(
    address _user,
    bytes memory
  )
    public
    view
    virtual
    override
    returns (bool)
  {
    return accessList[_user] || !checkEnabled;
  }

  /**
   * @notice Adds an address to the access list
   * @param _user The address to add
   */
  function addAccess(address _user) external onlyOwner() {
    addAccessInternal(_user);
  }

  function addAccessInternal(address _user) internal {
    if (!accessList[_user]) {
      accessList[_user] = true;
      emit AddedAccess(_user);
    }
  }

  /**
   * @notice Removes an address from the access list
   * @param _user The address to remove
   */
  function removeAccess(address _user)
    external
    onlyOwner()
  {
    if (accessList[_user]) {
      accessList[_user] = false;

      emit RemovedAccess(_user);
    }
  }

  /**
   * @notice makes the access check enforced
   */
  function enableAccessCheck()
    external
    onlyOwner()
  {
    if (!checkEnabled) {
      checkEnabled = true;

      emit CheckAccessEnabled();
    }
  }

  /**
   * @notice makes the access check unenforced
   */
  function disableAccessCheck()
    external
    onlyOwner()
  {
    if (checkEnabled) {
      checkEnabled = false;

      emit CheckAccessDisabled();
    }
  }

  /**
   * @dev reverts if the caller does not have access
   */
  modifier checkAccess() {
    require(hasAccess(msg.sender, msg.data), "No access");
    _;
  }
}