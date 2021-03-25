/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

contract Test {

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

  // Used to relieve stack pressure in transmit
  struct ReportData {
    HotVars hotVars; // Only read from storage once
    bytes observers; // ith element is the index of the ith observer
    int192[] observations; // ith element is the ith observation
    bytes vs; // jth element is the v component of the jth signature
    bytes32 rawReportContext;
  }
  
struct HotVars {
    bytes16 latestConfigDigest;
    // 32 most sig bits for epoch, 8 least sig bits for round
    // Current bound assumed on number of faulty/dishonest oracles participating
    // in the protocol, this value is referred to as f in the design
    uint40 latestEpochAndRound; 
    uint8 threshold;
    uint32 latestAggregatorRoundId;
  }

HotVars public s_hotVars;

constructor(){
    s_hotVars = HotVars({
      latestConfigDigest: bytes16(uint128(0x1234)),
      latestEpochAndRound: 1,
      threshold: 32,
      latestAggregatorRoundId: 100
    });
}

function expectedMsgDataLength(
    bytes calldata _report, bytes32[] calldata _rs, bytes32[] calldata _ss
  ) private pure returns (uint256 length)
  {
    // calldata will never be big enough to make this overflow
    return uint256(TRANSMIT_MSGDATA_CONSTANT_LENGTH_COMPONENT) +
      _report.length + // one byte pure entry in _report
      _rs.length * 32 + // 32 bytes per entry in _rs
      _ss.length * 32 + // 32 bytes per entry in _ss
      0; // placeholder d
  }

  bytes ay;

  function generate(bytes32 a, bytes32 b, int192[] memory c) public returns (bytes memory){
    ay = abi.encode("bytes32,bytes32,int192[]", a,b,c);
    return ay;
  }

  function generateBytes32(bytes32 a) public returns (bytes memory){
    bytes memory y = abi.encode("bytes32", a);
    return y;
  }

  function generateint192(int192[] memory c) public returns (bytes memory){
    bytes memory y = abi.encode("int192[]", c);
    return y;
  }

  function getHotVar() public view returns(bytes memory _h){
    _h = new bytes(100);
  }

  // function transmit(
  //   // NOTE: If these parameters are changed, expectedMsgDataLength and/or
  //   // TRANSMIT_MSGDATA_CONSTANT_LENGTH_COMPONENT need to be changed accordingly
  //   bytes calldata _report,
  //   bytes32[] calldata _rs, bytes32[] calldata _ss, bytes32 _rawVs // signatures
  // )
  //   external
  // {
  //   require(msg.data.length == expectedMsgDataLength(_report, _rs, _ss),
  //     "transmit message too long");


    
  //   ReportData memory r; // Relieves stack pressure
  //   {
  //     r.hotVars = s_hotVars; // cache read from storage

  //     bytes32 rawObservers;
  //     (r.rawReportContext, rawObservers, r.observations) = abi.decode(
  //       _report, (bytes32, bytes32, int192[])
  //     );

  //     // rawReportContext consists of:
  //     // 11-byte zero padding
  //     // 16-byte configDigest
  //     // 4-byte epoch
  //     // 1-byte round

  //     bytes16 configDigest = bytes16(r.rawReportContext << 88);
  //     require(
  //       r.hotVars.latestConfigDigest == configDigest,
  //       "configDigest mismatch"
  //     );

  //     uint40 epochAndRound = uint40(uint256(r.rawReportContext));

  //     // direct numerical comparison works here, because
  //     //
  //     //   ((e,r) <= (e',r')) implies (epochAndRound <= epochAndRound')
  //     //
  //     // because alphabetic ordering implies e <= e', and if e = e', then r<=r',
  //     // so e*256+r <= e'*256+r', because r, r' < 256
  //     require(r.hotVars.latestEpochAndRound < epochAndRound, "stale report");

  //     require(_rs.length > r.hotVars.threshold, "not enough signatures");
  //     require(_rs.length <= maxNumOracles, "too many signatures");
  //     require(_ss.length == _rs.length, "signatures out of registration");
  //     require(r.observations.length <= maxNumOracles,
  //             "num observations out of bounds");
  //     require(r.observations.length > 2 * r.hotVars.threshold,
  //             "too few values to trust median");

  //     // Copy signature parities in bytes32 _rawVs to bytes r.v
  //     r.vs = new bytes(_rs.length);
  //     for (uint8 i = 0; i < _rs.length; i++) {
  //       r.vs[i] = _rawVs[i];
  //     }

  //     // Copy observer identities in bytes32 rawObservers to bytes r.observers
  //     r.observers = new bytes(r.observations.length);
  //     bool[maxNumOracles] memory seen;
  //     for (uint8 i = 0; i < r.observations.length; i++) {
  //       uint8 observerIdx = uint8(rawObservers[i]);
  //       require(!seen[observerIdx], "observer index repeated");
  //       seen[observerIdx] = true;
  //       r.observers[i] = rawObservers[i];
  //     }

  //     Oracle memory transmitter = s_oracles[msg.sender];
  //     require( // Check that sender is authorized to report
  //       transmitter.role == Role.Transmitter &&
  //       msg.sender == s_transmitters[transmitter.index],
  //       "unauthorized transmitter"
  //     );
  //     // record epochAndRound here, so that we don't have to carry the local
  //     // variable in transmit. The change is reverted if something fails later.
  //     r.hotVars.latestEpochAndRound = epochAndRound;
  //   }

  //   { // Verify signatures attached to report
  //     bytes32 h = keccak256(_report);
  //     bool[maxNumOracles] memory signed;

  //     Oracle memory o;
  //     for (uint i = 0; i < _rs.length; i++) {
  //       address signer = ecrecover(h, uint8(r.vs[i])+27, _rs[i], _ss[i]);
  //       o = s_oracles[signer];
  //       require(o.role == Role.Signer, "address not authorized to sign");
  //       require(!signed[o.index], "non-unique signature");
  //       signed[o.index] = true;
  //     }
  //   }

  //   { // Check the report contents, and record the result
  //     for (uint i = 0; i < r.observations.length - 1; i++) {
  //       bool inOrder = r.observations[i] <= r.observations[i+1];
  //       require(inOrder, "observations not sorted");
  //     }

  //     int192 median = r.observations[r.observations.length/2];
  //     require(minAnswer <= median && median <= maxAnswer, "median is out of min-max range");
  //     r.hotVars.latestAggregatorRoundId++;
  //     s_transmissions[r.hotVars.latestAggregatorRoundId] =
  //       Transmission(median, uint64(block.timestamp));

  //     emit NewTransmission(
  //       r.hotVars.latestAggregatorRoundId,
  //       median,
  //       msg.sender,
  //       r.observations,
  //       r.observers,
  //       r.rawReportContext
  //     );
  //     // Emit these for backwards compatability with offchain consumers
  //     // that only support legacy events
  //     emit NewRound(
  //       r.hotVars.latestAggregatorRoundId,
  //       address(0x0), // use zero address since we don't have anybody "starting" the round here
  //       block.timestamp
  //     );
  //     emit AnswerUpdated(
  //       median,
  //       r.hotVars.latestAggregatorRoundId,
  //       block.timestamp
  //     );

  //     validateAnswer(r.hotVars.latestAggregatorRoundId, median);
  //   }
  //   s_hotVars = r.hotVars;
  //   assert(initialGas < maxUint32);
  //   reimburseAndRewardOracles(uint32(initialGas), r.observers);
  // }
}