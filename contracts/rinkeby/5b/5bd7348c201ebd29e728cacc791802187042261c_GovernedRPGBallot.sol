/**
 *Submitted for verification at Etherscan.io on 2021-09-04
*/

// contracts/GovernedRPGBallot.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GovernedRPGBallot {  
  struct Voter {
    uint weight; // weight is accumulated by delegation
    bool voted;  // if true, that person already voted
    address voter; // address of the voter
    uint vote;   // index of the voter's choice
  }

  struct Proposal {
    bytes32 name;   // proposal name
    uint totalVotesCount; // number of accumulated votes
    uint8 choiceCount; // number of choices in this proposal
  }

  struct Choice {
    bytes32 name;   // choice name
    uint voteCount; // number of votes for this choice
  }

  mapping(address => Voter) public voters;
  mapping(uint8 => Choice) public choices; // choice options

  Proposal private _proposal;

  constructor(bytes32 proposalName, bytes32[] memory choiceNames) {
    _proposal.name = proposalName;
    _proposal.totalVotesCount = 0;
    _proposal.choiceCount = uint8(choiceNames.length);

    for (uint8 i = 0; i < choiceNames.length; i++) {
      choices[i] = Choice({
        name: choiceNames[i],
        voteCount: 0
      });
    }
  }
  
  function name() public view returns (bytes32) {
    return _proposal.name;
  }

  function optionCount() public view returns (uint8) {
    return _proposal.choiceCount;
  }
}