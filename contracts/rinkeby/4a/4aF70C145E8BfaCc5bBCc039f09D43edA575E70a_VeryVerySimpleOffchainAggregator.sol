// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/**
  * @notice Onchain verification of reports from the offchain reporting protocol

  * @dev For details on its operation, see the offchain reporting protocol design
  * @dev doc, which refers to this contract as simply the "contract".
*/
contract VeryVerySimpleOffchainAggregator {

  // time timestamp
  struct Transmission {
    int192 answer; // 192 bits ought to be enough for anyone
    uint64 timestamp;
  }

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

  mapping (address /* transmitter address */ => Oracle) internal s_oracles;

  // s_transmitters contains the transmission address of each oracle,
  // i.e. the address the oracle actually sends transactions to the contract from
  address[] internal s_transmitters;

  uint256 latestEpochAndRound;
  int192  report;
  uint256 constant public version = 4;
  string internal s_description;

  /*
   * @param _description short human-readable description of observable this contract's answers pertain to
   * @param _transmitters addresses oracles use to transmit the reports
   */
  constructor(
    string memory _description,
    address[] memory _transmitters
  ) {
    s_description = _description;
    for (uint i = 0; i < _transmitters.length; i++) { // add new transmitter addresses
      require(
        s_oracles[_transmitters[i]].role == Role.Unset,
        "repeated transmitter address"
      );
      s_oracles[_transmitters[i]] = Oracle(uint8(i), Role.Transmitter);
      s_transmitters.push(_transmitters[i]);
    }
  }

  /*
   * Versioning
   */
  function typeAndVersion()
    external
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
   * @param answer median of the observations attached this report
   * @param transmitter address from which the report was transmitted
   */
  event NewTransmission(
    int192 answer,
    address transmitter
  );

  /**
   * @notice transmit is called to post a new report to the contract
   * @param _report serialized report. See parsing code below for format.
   */
  function transmit(
    int192 _report, uint256 epochAndRound
  )
    external
  {
      Oracle memory transmitter = s_oracles[msg.sender];
      require( transmitter.role == Role.Transmitter && msg.sender == s_transmitters[transmitter.index], "unauthorized transmitter");
      
      // record epochAndRound here, so that we don't have to carry the local
      // variable in transmit. The change is reverted if something fails later.
      latestEpochAndRound = epochAndRound;

      report = _report;
      emit NewTransmission(
        report,
        msg.sender
      );
  }


  /**
   * @notice median from the most recent report
   */
  function latestAnswer()
    public
    view
    virtual
    returns (int192)
  {
    require(msg.sender == tx.origin, "Only callable by EOA"); // audit msg.sender == tx.origin
    return report;
  }

  /**
   * @notice human-readable description of observable this contract is reporting on
   */
  function description()
    public
    view
    virtual
    returns (string memory)
  {
    return s_description;
  }

}