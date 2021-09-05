// contracts/GovernedRPGBallot.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract GovernedRPGBallot {  
  struct Voter {
    uint weight; // weight is accumulated by delegation
    bool voted;  // if true, that person already voted
    uint vote;   // index of the voter's choice
  }

  struct Proposal {
    bytes32 name;   // proposal name
    uint256 totalVotesCount; // number of accumulated votes
    uint256 choiceCount; // number of options on this proposal
  }

  struct Choice {
    bytes32 name;   // choice name
    uint256 voteCount; // number of votes for this choice
  }

  mapping(address => Voter) public voters;
  mapping(uint8 => Choice) public choices; // choice options

  Proposal private _proposal;

  address public game;

  constructor(bytes32 proposalName, bytes32[] memory choiceNames, address gameAddress) {
    _proposal.name = proposalName;
    _proposal.totalVotesCount = 0;
    _proposal.choiceCount = uint8(choiceNames.length);

    game = gameAddress;

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

  function choiceCount() public view returns (uint256) {
    return _proposal.choiceCount;
  }
  
  function leadingChoice() public view returns (bytes32 _leadingChoice) {
    uint topVotes = 0;
    for (uint8 i = 0; i < _proposal.choiceCount; i++) {
      if (choices[i].voteCount > topVotes) {
        topVotes = choices[i].voteCount;
        _leadingChoice = choices[i].name;
      }
    }
  }

  /**
   * @param choice option which the sender is voting for
   * @param weight number of GRPG tokens the user is dedicating for this vote
  */
  function vote(uint8 choice, uint256 weight) public {
    Voter storage sender = voters[msg.sender];

    if (sender.voted) {
      require(sender.vote == choice, "You can not change your vote.");
    }

    uint256 senderBalance = IERC20(game).balanceOf(msg.sender);
    require(senderBalance > weight * 10**18, "You don't have enough GRPG for this vote.");

    IERC20(game).transfer(game, weight * 10**18);

    choices[choice].voteCount += weight;
    if (sender.voted) {
      sender.weight += weight;
    } else {
      sender.voted = true;
      sender.vote = choice;
      sender.weight = weight;
    }
  }
}