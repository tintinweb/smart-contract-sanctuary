// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Ballot {
  struct Voter {
    uint weight; // permission to vote
    bool voted;  // if true, that person already voted
  }

  struct Proposal {
    bytes32 name;   // short name (up to 32 bytes)
    uint voteCount; // number of accumulated votes
  }

address public chairperson;

  mapping(address => Voter) public voters; // Voter struct for each possible address.

  Proposal[] public proposals; // array of Proposal structs.

  constructor(bytes32[] memory proposalNames, address[] memory voter_addresses) {
    chairperson = msg.sender;
    voters[chairperson] = Voter({
      voted: false,
      weight: 1
    });

    for (uint i = 0; i < proposalNames.length; i++) {
      proposals.push(Proposal({
        name: proposalNames[i],
        voteCount: 0
      }));
    }

    for (uint i = 0; i < voter_addresses.length; i++) {
      voters[voter_addresses[i]] = Voter({voted: false, weight: 1});
    }
  }

  function vote(uint proposal) public {
    Voter storage sender = voters[msg.sender];
    require(sender.weight != 0, "Has no right to vote");
    require(!sender.voted, "Already voted.");
    sender.voted = true;

    // If `proposal` is out of the range of the array,
    // this will throw automatically and revert all
    // changes.
    proposals[proposal].voteCount += sender.weight;
  }

  function winningProposal() public view
            returns (uint winningProposal_)
  {
    uint winningVoteCount = 0;
    for (uint p = 0; p < proposals.length; p++) {
      if (proposals[p].voteCount > winningVoteCount) {
        winningVoteCount = proposals[p].voteCount;
        winningProposal_ = p;
      }
    }
  }

  function winnerName() public view
            returns (bytes32 winnerName_)
  {
    winnerName_ = proposals[winningProposal()].name;
  }
  
}

{
  "optimizer": {
    "enabled": false,
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
  "libraries": {}
}